library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.MATH_REAL.ALL;

entity sc_spi is
	generic (
		clock_frequency : integer;
		spi_clock_frequency : integer := 1e6;
		addr_bits : integer;
		spi_slave_count : integer := 1;
		word_size : integer := 8;
		txf_depth : integer := 4;
		txf_thres : integer := 2;
		rxf_depth : integer := 2;
		rxf_thres : integer := 1
	);
	port (
		clock             : in std_logic;
		reset             : in std_logic;
		-- SimpCon interface
		sc_address        : in std_logic_vector(addr_bits-1 downto 0);
		sc_wr_data        : in std_logic_vector(31 downto 0);
		sc_rd             : in std_logic;
		sc_wr             : in std_logic;
		sc_rd_data        : out std_logic_vector(31 downto 0);
		sc_rdy_cnt        : out unsigned(1 downto 0);
		-- SPI Con
		SCLK              : buffer std_logic; -- SPI clock
		CS_N              : buffer std_logic_vector(SPI_SLAVE_COUNT-1 downto 0); -- SPI chip select, active in low
		MOSI_IO0          : out std_logic; -- SPI serial data from master to slave
		MISO_IO1          : in std_logic
	);

end sc_spi;

architecture rtl of sc_spi is

	constant clk_div		: integer := (clock_frequency/spi_clock_frequency)/2;

	signal tf_dout			: std_logic_vector(7 downto 0);
	signal tf_rd			: std_logic;
	signal tf_wr			: std_logic;
	signal tf_empty			: std_logic;
	signal tf_full			: std_logic;
	signal tf_half			: std_logic;
	
	signal rf_din			: std_logic_vector(7 downto 0);
	signal rf_dout			: std_logic_vector(7 downto 0);
	signal rf_rd			: std_logic;
	signal rf_wr			: std_logic;
	signal rf_empty			: std_logic;
	signal rf_full			: std_logic;
	signal rf_half			: std_logic;

	signal cpol				: std_logic;
	signal cpha				: std_logic;

	signal spi_ena			: std_logic;
	signal spi_cont			: std_logic;
	signal spi_addr			: integer;
	signal spi_dout			: std_logic_vector(7 downto 0);
	signal spi_dout_valid	: std_logic;
	signal spi_busy			: std_logic;

begin

	sc_rdy_cnt <= "00";	-- no wait states
	sc_rd_data(31 downto 8) <= std_logic_vector(to_unsigned(0, 24));

	--
	--	transmit fifo
	--
	txfifo: entity work.fifo 
		generic map (8, txf_depth, txf_thres)
		port map (
			clock,
			reset,
			sc_wr_data(word_size-1 downto 0),
			tf_dout,
			tf_rd,
			tf_wr,
			tf_empty,
			tf_full,
			tf_half
		);

	--
	--	receive fifo
	--
	rxfifo: entity work.fifo
		generic map (8, rxf_depth, rxf_thres)
		port map (
			clock,
			reset,
			rf_din,
			rf_dout,
			rf_rd,
			rf_wr,
			rf_empty,
			rf_full,
			rf_half
		);
	
  spi_master_0: entity work.spi_master
    GENERIC MAP (
		slaves => SPI_SLAVE_COUNT,
		d_width => word_size
	) PORT MAP(
		clock => clock,
		reset => reset,
		enable => spi_ena,
		cpol => cpol,
		cpha => cpha,
		cont => spi_cont,
		clk_div => clk_div,
		addr => spi_addr,
		tx_data => tf_dout,
        sclk => SCLK,
		ss_n => CS_N,
		mosi => MOSI_IO0,
		miso => MISO_IO1,
		busy => spi_busy,
		rx_data_valid => spi_dout_valid,
		rx_data => spi_dout
	);

	tf_rd   <= not tf_empty and not spi_busy;
	spi_ena <= tf_rd;
	spi_cont <= not tf_empty;
	rf_din  <= spi_dout;
	rf_wr   <= spi_dout_valid;

	process(clock, reset)
	begin
		if (reset='1') then
			sc_rd_data(7 downto 0) <= (others => '0');
			cpol <= '1';
			cpha <= '1';
			spi_addr <= 0;
		elsif rising_edge(clock) then
			rf_rd <= '0';
			tf_wr <= '0';
			if sc_rd='1' then
				if sc_address="0000" then  -- read status reg
					sc_rd_data(7 downto 0) <= cpol & cpha & rf_full & rf_half & rf_empty & tf_full & tf_half & tf_empty; -- TO DO STATUS
				elsif sc_address="0001" then  -- read rx fifo
					sc_rd_data(7 downto 0) <= rf_dout;
					rf_rd <= sc_rd;
				elsif sc_address=x"2" then  -- read peripheral address reg
					sc_rd_data(7 downto 0) <= std_logic_vector(to_unsigned(spi_addr, word_size));
				end if;
			elsif sc_wr='1' then
				if sc_address=x"0" then  -- write control reg
					cpol <= sc_wr_data(0);
					cpha <= sc_wr_data(1);
				elsif sc_address=x"1" then  -- write tx fifo
					tf_wr <= '1';
				elsif sc_address=x"2" then  -- write peripheral address reg
					spi_addr <= to_integer(unsigned(sc_wr_data));
				end if;
			end if;
		end if;
	end process;

end rtl;
