library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity sc_spi_tb is
    Generic (
        clock_frequency      : natural := 50e6; -- system clock frequency in Hz
        spi_clock_frequency  : natural := 1e6;  -- spi clock frequency in Hz
        addr_bits            : natural := 4
    );
end entity;

architecture sim of sc_spi_tb is

    constant clock_period : time := 1 ns * integer(real(1e9)/real(clock_frequency));
    constant spi_clock_period : time := 1 ns * integer(real(1e9)/real(spi_clock_frequency));

    signal sim_done       : std_logic := '0';


    signal clock          : std_logic := '0';
    signal reset          : std_logic := '1';

    signal address        : std_logic_vector(addr_bits-1 downto 0);
	signal wr_data        : std_logic_vector(31 downto 0);
	signal rd             : std_logic := '0';
    signal wr             : std_logic := '0';
	signal rd_data        : std_logic_vector(31 downto 0);
	signal rdy_cnt        : unsigned(1 downto 0);

    signal sclk           : std_logic;
    signal cs_n           : std_logic;
    -- signal mosi           : std_logic;
    -- signal miso           : std_logic;
    signal loop_back      : std_logic;

    procedure write(
        signal address      : out std_logic_vector(addr_bits-1 downto 0);
        signal wr_data      : out std_logic_vector(31 downto 0);
        signal wr           : out std_logic;
        constant p_address  : in integer;
        constant p_data     : in integer
    ) is begin
        wait until rising_edge(clock);
        address <= std_logic_vector(to_unsigned(p_address, address'length));
        wr_data <= std_logic_vector(to_unsigned(p_data, wr_data'length));
        wr <= '1';
        wait until rising_edge(clock);
        wr <= '0';
    end procedure;

    procedure read(
        signal address      : out std_logic_vector(addr_bits-1 downto 0);
        signal rd           : out std_logic;
        constant p_address  : in integer
    ) is begin
        wait until rising_edge(clock);
        address <= std_logic_vector(to_unsigned(p_address, address'length));
        rd <= '1';
        wait until rising_edge(clock);
        rd <= '0';
    end procedure;

begin

    sc_spi_dut : entity work.sc_spi
    generic map (
        clock_frequency     => clock_frequency,
        spi_clock_frequency => spi_clock_frequency,
        addr_bits           => addr_bits
    )
    port map (
        clock      => clock,
        reset      => reset,
        -- simpcon interface
        sc_address    => address,
        sc_wr_data    => wr_data,
        sc_rd         => rd,
        sc_wr         => wr,
        sc_rd_data    => rd_data,
        sc_rdy_cnt    => rdy_cnt,
        -- SPI SLAVE INTERFACE
        SCLK       => sclk,
        CS_N(0)    => cs_n,
        MOSI_IO0   => loop_back,
        MISO_IO1   => loop_back
    );

    clock_gen_p : process
    begin
        clock <= not clock;
        wait for clock_period/2;
        if (sim_done = '1') then
            wait;
        end if;
    end process;

    rst_gen_p : process
    begin
        report "======== SIMULATION START! ========";
        -- report "Total transactions for master to slave direction: " & integer'image(TRANS_COUNT);
        -- report "Total transactions for slave to master direction: " & integer'image(TRANS_COUNT);
        reset <= '1';
        wait for clock_period*3;
        reset <= '0';
        wait;
    end process;

    sc_test_p : process
    begin
        wait until reset = '0';
        
        write(address, wr_data, wr, 1, 16#AA#);
        wait for 2 * clock_period;
        write(address, wr_data, wr, 1, 16#55#);
        wait for 2 * clock_period;
        write(address, wr_data, wr, 1, 16#00#);
        wait for 2 * clock_period;
        write(address, wr_data, wr, 1, 16#00#);

        wait for 9 * spi_clock_period;
        read(address, rd, 1);

        wait for 9 * spi_clock_period;
        read(address, rd, 1);

        wait for 9 * spi_clock_period;
        read(address, rd, 1);

        wait for 14 * spi_clock_period;
        sim_done <= '1';

        report "======== SIMULATION SUCCESSFULLY COMPLETED! ========";
    end process;

end architecture;
