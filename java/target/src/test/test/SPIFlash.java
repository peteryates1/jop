package test;

import com.jopdesign.sys.Const;
import com.jopdesign.sys.JVMHelp;
import com.jopdesign.sys.Native;

public class SPIFlash extends SPI {
	public static final int SPI_FLASH_BASE = Const.IO_BASE+0x50;
	
	public final static SPIFlash spiFlash = 
			(SPIFlash) JVMHelp.makeHWObject(new SPIFlash(), SPI_FLASH_BASE, 0, Native.rdIntMem(Const.RAM_CP));
	
	public int[] readJEDECID(int[] idInfo) throws TimeoutException {
		spiFlash.fifo_write(0x9F, 10);
		spiFlash.fifo_write(0x00, 10);
		spiFlash.fifo_write(0x00, 10);
		spiFlash.fifo_write(0x00, 10);
		spiFlash.fifo_read(10);
		idInfo[0] = spiFlash.fifo_read(10);
		idInfo[1] = spiFlash.fifo_read(10);
		idInfo[2] = spiFlash.fifo_read(10);
		return idInfo;
	}
	
	public int read(int address) throws TimeoutException {
		spiFlash.fifo_write(0x03,10);
		spiFlash.fifo_write((address>>16) & 0xFF,10);
		spiFlash.fifo_write((address>>8)  & 0xFF,10);
		spiFlash.fifo_write(address      & 0xFF,10);
		spiFlash.fifo_write(0x00, 10);
		spiFlash.fifo_read(10);
		spiFlash.fifo_read(10);
		spiFlash.fifo_read(10);
		spiFlash.fifo_read(10);
		return spiFlash.fifo_read(10);
	}
	
	public static void main(String[] args) {
		try {
			int[] info = spiFlash.readJEDECID(new int[3]);
			System.out.println("Manufacturer ID: "+info[0]);
			System.out.println("Memory Type: "+info[1]);
			System.out.println("Capacity: "+info[2]);
//			for(int address = 0 ; address < 0x1000; address++) {
//				System.out.println(spiFlash.read(address));
//			}
		} catch (TimeoutException e) {
			System.out.println(e.getMessage());
		}
	}
}
