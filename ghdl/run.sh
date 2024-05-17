#!/bin/bash -x

rm -f work-obj93.cf

ghdl -a ../vhdl/simpcon/sc_pack.vhd
ghdl -a ../vhdl/top/jop_config_global.vhd
ghdl -a ../vhdl/core/jop_types.vhd
ghdl -a ../vhdl/simulation/sim_jop_config_100.vhd
ghdl -a ../vhdl/simulation/sim_pll.vhd
ghdl -a ../vhdl/simulation/sim_memory.vhd
ghdl -a ../vhdl/scio/fifo.vhd
ghdl -a ../vhdl/simulation/sim_sc_uart.vhd
ghdl -a ../vhdl/scio/sc_sys.vhd
ghdl -a ../vhdl/scio/led_switch.vhd
#ghdl -a -fsynopsys ../vhdl/scio/spi/digikey_spi_master.vhd
#ghdl -a -fsynopsys ../vhdl/scio/sc_spi_using_digikey_spi_master.vhd
#ghdl -a ../vhdl/scio/scio_max1000.vhd
ghdl -a ../vhdl/scio/scio_min.vhd
ghdl -a -fsynopsys ../vhdl/jtbl.vhd
ghdl -a -fsynopsys ../vhdl/rom.vhd
ghdl -a ../vhdl/simulation/sim_ram.vhd
ghdl -a ../vhdl/simulation/bytecode.vhd
ghdl -a ../vhdl/core/bcfetch.vhd
ghdl -a ../vhdl/core/core.vhd
ghdl -a ../vhdl/core/decode.vhd
ghdl -a ../vhdl/simulation/microcode.vhd
ghdl -a ../vhdl/core/fetch.vhd
ghdl -a ../vhdl/simulation/sim_jbc.vhd
ghdl -a ../vhdl/core/cache.vhd
ghdl -a ../vhdl/cache/ocache.vhd
ghdl -a ../vhdl/memory/mem_sc.vhd
ghdl -a ../vhdl/memory/sdpram.vhd
ghdl -a -fsynopsys ../vhdl/core/mul.vhd
ghdl -a ../vhdl/core/shift.vhd
ghdl -a ../vhdl/core/stack.vhd
ghdl -a ../vhdl/memory/sc_sram16.vhd
ghdl -a ../vhdl/core/jopcpu.vhd
ghdl -a ../vhdl/top/jop_256x16.vhd
#ghdl -a ../vhdl/top/jop_256x16_max1000.vhd
ghdl -a ../vhdl/simulation/tb_jop_sram16.vhd
#ghdl -a ../vhdl/simulation/tb_jop_sram16_max1000.vhd

echo elaborating...
ghdl -e -v -fsynopsys tb_jop

echo running simulation...
ghdl -r -fsynopsys tb_jop --stop-time=1ms --wave=sim.ghw --ieee-asserts=disable

#ghdl -r -v -fsynopsys tb_jop --stop-time=20ms --vcd=sim.vcd
