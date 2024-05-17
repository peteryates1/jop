library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.MATH_REAL.ALL;

entity sc_spi is
	generic (
		clock_frequency : integer;
		addr_bits : integer;
		spi_clock_frequency : integer := 1e6;
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
		SCLK              : out std_logic; -- SPI clock
		CS_N              : out std_logic_vector(SPI_SLAVE_COUNT-1 downto 0); -- SPI chip select, active in low
		MOSI_IO0          : out std_logic; -- SPI serial data from master to slave
		MISO_IO1          : in std_logic
	);

end sc_spi;

architecture rtl of sc_spi is

	component fifo is
		generic (
			width : integer;
			depth : integer;
			thres : integer
		);
		port (
			clk		: in std_logic;
			reset	: in std_logic;
			din		: in std_logic_vector(width-1 downto 0);
			dout	: out std_logic_vector(width-1 downto 0);
			rd		: in std_logic;
			wr		: in std_logic;
			empty	: out std_logic;
			full	: out std_logic;
			half	: out std_logic
		);
	end component;

	signal tf_dout		: std_logic_vector(7 downto 0);
	signal tf_rd		: std_logic;
	signal tf_wr		: std_logic;
	signal tf_empty		: std_logic;
	signal tf_full		: std_logic;
	signal tf_half		: std_logic;
	
	signal spi_din        : std_logic_vector(7 downto 0);
	signal spi_din_last   : std_logic;
	signal spi_din_valid  : std_logic;
	signal spi_din_ready  : std_logic;

	signal spi_dout       : std_logic_vector(7 downto 0);
	signal spi_dout_valid : std_logic;

	signal rf_din       : std_logic_vector(7 downto 0);
	signal rf_dout		: std_logic_vector(7 downto 0);
	signal rf_rd		: std_logic;
	signal rf_wr		: std_logic;
	signal rf_empty		: std_logic;
	signal rf_full		: std_logic;
	signal rf_half		: std_logic;

begin

	--
	--	transmit fifo
	--
	tf: fifo generic map (8, txf_depth, txf_thres)
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

	SPI_MASTER : entity work.SPI_MASTER
		generic map (
			CLK_FREQ => clock_frequency,
			SLAVE_COUNT => SPI_SLAVE_COUNT,
			SCLK_FREQ => spi_clock_frequency,
			WORD_SIZE => 8
		) port map (
			CLK         => clock,
			RST         => reset,
			SCLK        => SCLK,
			CS_N        => CS_N,
			MOSI        => MOSI_IO0,
			MISO        => MISO_IO1,
			DIN         => spi_din,
			DIN_ADDR    => sc_address(natural(ceil(log2(real(SPI_SLAVE_COUNT))))-1 downto 0),
			DIN_LAST    => spi_din_last,
			DIN_VLD     => spi_din_valid,
			DIN_RDY     => spi_din_ready,
			DOUT        => spi_dout,
			DOUT_VLD    => spi_dout_valid
		);

	--
	--	receive fifo
	--
	rf: fifo generic map (8, rxf_depth, rxf_thres)
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

	tf_wr <= sc_wr and sc_address(0);
	tf_rd <= not tf_empty and spi_din_ready;

	spi_din <= tf_dout;
	spi_din_valid <= tf_rd;
	
	spi_din_last <= not tf_half;

	rf_wr <= spi_dout_valid;
	rf_din <= spi_dout;
	
	sc_rdy_cnt <= "00";	-- no wait states
	
	sc_rd_data(31 downto 8) <= std_logic_vector(to_unsigned(0, 24));

	process(clock, reset)
	begin
		if (reset='1') then
			sc_rd_data(7 downto 0) <= (others => '0');
		elsif rising_edge(clock) then
			rf_rd <= '0';
			if sc_rd='1' then
				if sc_address(0)='0' then
					sc_rd_data(7 downto 0) <= "00" & rf_full & rf_half & rf_empty & tf_full & tf_half & tf_empty; -- TO DO STATUS
				else
					sc_rd_data(7 downto 0) <= rf_dout;
					rf_rd <= sc_rd;
				end if;
			end if;
		end if;
	end process;

end rtl;
