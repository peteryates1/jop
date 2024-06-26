--
--
--  This file is a part of JOP, the Java Optimized Processor
--
--  Copyright (C) 2001-2008, Martin Schoeberl (martin@jopdesign.com)
--
--  This program is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General blic License
--  along with this program.  If not, see <http://www.gnu.org/licenses/>.
--

--
-- jop_max1000 based on jop_dram.vhd
--
-- top level for a max1000 with sdram
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.jop_types.all;
use work.sc_pack.all;
use work.dram_pack.all;
use work.jop_config_global.all;
use work.jop_config.all;

entity jop is

  generic (
    jpc_width  : integer := 12;  -- address bits of java bytecode pc = cache size
    block_bits : integer := 4;   -- 2*block_bits is number of cache blocks
    spm_width  : integer := 0    -- size of scratchpad RAM (in number of address bits for 32-bit words)
  );

  port (
    clk_in          :   in  std_logic;
    --
    -- serial interface
    --
    ser_rxd         :   in  std_logic;
    ser_ncts        :   in std_logic;
    ser_txd         :   out std_logic;
    ser_nrts        :   out std_logic;
    --
    -- sdram
    --
    dram_ctrl       :   out   dram_ctrl_type;
    dram_data       :   inout dram_data_type;
	--
	-- leds
	--
	leds            :   out std_logic_vector(7 downto 0);
	--
	-- button
	--
	buttons         :   in std_logic_vector(1 downto 0);
    --
    -- watchdog
    --
    wd              :   out std_logic;
	--
	-- qspi flash
	--
	flash_select : out std_logic;
	flash_sclk : out std_logic;
	flash_miso : in std_logic;
	flash_mosi : out std_logic;
	--
	-- spi accelerometer
	--
	accelerometer_select : out std_logic;
	accelerometer_sclk : out std_logic;
	accelerometer_miso : in std_logic;
	accelerometer_mosi : out std_logic;
	--
	-- sdcard (external spi)
	-- 
	spi_select : out std_logic;
	spi_sclk : out std_logic;
	spi_mosi : out std_logic;
	spi_miso : in std_logic

);

end jop;

architecture rtl of jop is

    --
    -- components:
    --

    component dram_pll
    generic (multiply_by : natural; divide_by : natural);
    port (
        inclk0 : in  std_logic;
        c0     : out std_logic;
        c1     : out std_logic;
        c2     : out std_logic;
        locked : out std_logic);
    end component;

    --
    -- Signals
    --
    signal internal_clk : std_logic;

    signal int_res : std_logic;
    signal res_cnt : unsigned(2 downto 0) := "000";  -- for the simulation

    attribute altera_attribute            : string;
    attribute altera_attribute of res_cnt : signal is "POWER_UP_LEVEL=LOW";

    --
    -- jopcpu connections
    --
    signal sc_mem_out : sc_out_type;
    signal sc_mem_in  : sc_in_type;
    signal sc_io_out  : sc_out_type;
    signal sc_io_in   : sc_in_type;
    signal irq_in     : irq_bcf_type;
    signal irq_out    : irq_ack_type;
    signal exc_req    : exception_type;

    signal dpll : dram_pll_type;

begin
    --
    -- intern reset
    -- no extern reset, epm7064 has too less pins
    --
    process(internal_clk)
    begin
    if rising_edge(internal_clk) then
        if (res_cnt /= "111") then
        res_cnt <= res_cnt+1;
        end if;

        int_res <= not res_cnt(0) or not res_cnt(1) or not res_cnt(2);
    end if;
    end process;

    --
    -- components of jop
    --
    my_dram_pll : dram_pll
        generic map(
            multiply_by => pll_mult,
            divide_by => pll_div
        ) port map (
            inclk0 => clk_in,              -- [in]
            c0     => internal_clk,        -- [out]      
            c1     => dpll.clk,            -- [out]
            c2     => dpll.clk_skew,       -- [out]      
            locked => dpll.locked          -- [out]
        );

    cpu : entity work.jopcpu
        generic map (
            jpc_width  => jpc_width,
            block_bits => block_bits,
            spm_width  => spm_width
        ) port map (
            internal_clk, int_res,
            sc_mem_out, sc_mem_in,
            sc_io_out, sc_io_in,
            irq_in, irq_out, exc_req
        );

    io : entity work.scio
        port map (
            internal_clk,
            int_res,
            sc_io_out,
            sc_io_in,
            irq_in,
            irq_out,
            exc_req,
            txd                    => ser_txd,
            rxd                    => ser_rxd,
            ncts                   => ser_ncts,
            nrts                   => ser_nrts,
            wd                     => wd,
            leds                   => leds,
            buttons                => buttons,
            flash_select           => flash_select,
            flash_sclk             => flash_sclk,
            flash_mosi             => flash_mosi,
            flash_miso             => flash_miso,
            accelerometer_select   => accelerometer_select,
            accelerometer_sclk     => accelerometer_sclk,
            accelerometer_mosi     => accelerometer_mosi,
            accelerometer_miso     => accelerometer_miso,
            spi_select             => spi_select,
            spi_sclk               => spi_sclk,
            spi_mosi               => spi_mosi,
            spi_miso               => spi_miso
        );

    scm: entity work.sc_mem_if
        port map (
            clk        => internal_clk,      -- [in]
            reset      => int_res,           -- [in]
            sc_mem_out => sc_mem_out,        -- [in]
            sc_mem_in  => sc_mem_in,         -- [out]
            dram_pll   => dpll,              -- [in]
            dram_ctrl  => dram_ctrl,         -- [out]
            dram_data  => dram_data          -- [inout]
        );

end rtl;
