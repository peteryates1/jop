clear && \
rm -f work-obj93.cf && \
ghdl -a ../fifo.vhd && \

# ghdl -a ../../../../spi-fpga/rtl/spi_master.vhd && \
# ghdl -a -fsynopsys ../sc_spi_using_spi_fpga.vhd && \

ghdl -a -fsynopsys digikey_spi_master.vhd && \
ghdl -a -fsynopsys ../sc_spi_using_digikey_spi_master.vhd && \

#ghdl -a -fsynopsys ../sc_spi_fifo_loopback.vhd && \

ghdl -a sc_spi_tb.vhd && \
ghdl -e -fsynopsys sc_spi_tb  && \
ghdl -r -fsynopsys sc_spi_tb --wave=sim.ghw
# ghdl -r sc_spi_tb --wave=sim.ghw && \
# gtkwave sim.ghw &
