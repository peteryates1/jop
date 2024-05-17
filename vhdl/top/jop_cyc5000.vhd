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
-- top level for a cyc5000 with sdram
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.jop_types.all;
use work.sc_pack.all;
use work.sc_arbiter_pack.all;
use work.dram_pack.all;
use work.jop_config_global.all;
use work.jop_config.all;

entity jop is

  generic (
    jpc_width  : integer := 12;  -- address bits of java bytecode pc = cache size
    block_bits : integer := 4;   -- 2*block_bits is number of cache blocks
    spm_width  : integer := 0;   -- size of scratchpad RAM (in number of address bits for 32-bit words)
    cpu_cnt    : integer := 3    -- number of cpus
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
	flash_mosi : out std_logic
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

    -- jopcpu connections
	signal sc_arb_out		: arb_out_type(0 to cpu_cnt-1);
	signal sc_arb_in		: arb_in_type(0 to cpu_cnt-1);
	
	signal sc_mem_out		: sc_out_type;
	signal sc_mem_in		: sc_in_type;
	
	signal sc_io_out		: sc_out_array_type(0 to cpu_cnt-1);
	signal sc_io_in			: sc_in_array_type(0 to cpu_cnt-1);
	signal irq_in			  : irq_in_array_type(0 to cpu_cnt-1);
	signal irq_out			: irq_out_array_type(0 to cpu_cnt-1);
	signal exc_req			: exception_array_type(0 to cpu_cnt-1);

    signal dpll : dram_pll_type;

    -- cmpsync
	signal sync_in_array	: sync_in_array_type(0 to cpu_cnt-1);
	signal sync_out_array	: sync_out_array_type(0 to cpu_cnt-1);

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

	gen_cpu: for i in 0 to cpu_cnt-1 generate
		cpu: entity work.jopcpu generic map (
				jpc_width => jpc_width,
				block_bits => block_bits,
				spm_width => spm_width
			) port map(
                internal_clk,
                int_res,
				sc_arb_out(i),
                sc_arb_in(i),
				sc_io_out(i),
                sc_io_in(i),
                irq_in(i), 
				irq_out(i),
                exc_req(i)
            );
	end generate;

	arbiter: entity work.arbiter generic map(
			addr_bits => SC_ADDR_SIZE,
			cpu_cnt => cpu_cnt,
			write_gap => 2,
			read_gap => 1,
			slot_length => 3
		) port map (
            internal_clk,
            int_res,
			sc_arb_out,
            sc_arb_in,
			sc_mem_out,
            sc_mem_in
			-- Enable for use with Round Robin Arbiter
			-- sync_out_array(1)
        );
        
    scm: entity work.sc_mem_if port map (
            clk        => internal_clk,      -- [in]
            reset      => int_res,           -- [in]
            sc_mem_out => sc_mem_out,        -- [in]
            sc_mem_in  => sc_mem_in,         -- [out]
            dram_pll   => dpll,              -- [in]
            dram_ctrl  => dram_ctrl,         -- [out]
            dram_data  => dram_data          -- [inout]
        );

	-- synchronization of processors
	sync: entity work.ihlu generic map (
			cpu_cnt => cpu_cnt
        ) port map (
			clock => internal_clk,
			reset => int_res,
			sync_in => sync_in_array,
			sync_out => sync_out_array
		);
    
    -- io for processor 0
    io : entity work.scio generic map (
			cpu_id => 0,
			cpu_cnt => cpu_cnt
		) port map (
            internal_clk,
            int_res,
            sc_io_out(0),
            sc_io_in(0),
			irq_in(0),
            irq_out(0),
            exc_req(0),
			sync_out              => sync_out_array(0),
			sync_in               => sync_in_array(0),
            txd                   => ser_txd,
            rxd                   => ser_rxd,
            ncts                  => ser_ncts,
            nrts                  => ser_nrts,
            wd                    => wd,
            leds                  => leds,
            buttons               => buttons,
            flash_select          => flash_select,
            flash_sclk            => flash_sclk,
            flash_mosi            => flash_mosi,
            flash_miso            => flash_miso
        );

	-- io for processors with only sc_sys
	gen_io: for i in 1 to cpu_cnt-1 generate
		io2: entity work.sc_sys generic map (
			addr_bits => 4,
			clk_freq => clk_freq,
			cpu_id => i,
			cpu_cnt => cpu_cnt
		) port map(
			clk => internal_clk,
			reset => int_res,
			address => sc_io_out(i).address(3 downto 0),
			wr_data => sc_io_out(i).wr_data,
			rd => sc_io_out(i).rd,
			wr => sc_io_out(i).wr,
			rd_data => sc_io_in(i).rd_data,
			rdy_cnt => sc_io_in(i).rdy_cnt,
			irq_in => irq_in(i),
			irq_out => irq_out(i),
			exc_req => exc_req(i),
			sync_out => sync_out_array(i),
			sync_in => sync_in_array(i) --,
			-- wd => wd_out(i)
			-- remove the comment for RAM access counting
			-- ram_count => ram_count
		);

	end generate;

end rtl;
