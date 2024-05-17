package test;

import com.jopdesign.sys.Const;
import com.jopdesign.sys.JVMHelp;
import com.jopdesign.sys.Native;

public class SPIAccelerometerLIS3DH extends SPI {
	public static final int SPI_ACCELEROMETER_BASE = Const.IO_BASE+0x60;

	public final static SPIAccelerometerLIS3DH instance = 
			(SPIAccelerometerLIS3DH) JVMHelp.makeHWObject(new SPIAccelerometerLIS3DH(), SPI_ACCELEROMETER_BASE, 0, Native.rdIntMem(Const.RAM_CP));

	public static final int STATUS_REG_AUX = 0x07;
	public static final int OUT_ADC1_L = 0x08;
	public static final int OUT_ADC1_H = 0x09;
	public static final int OUT_ADC2_L = 0x0A;
	public static final int OUT_ADC2_H = 0x0B;
	public static final int OUT_ADC3_L = 0x0C;
	public static final int OUT_ADC3_H = 0x0D;
	public static final int WHO_AM_I = 0x0F;
	public static final int CTRL_REG0 = 0x1E;
	public static final int TEMP_CFG_REG = 0x1F;
	public static final int CTRL_REG1 = 0x20;
	public static final int CTRL_REG2 = 0x21;
	public static final int CTRL_REG3 = 0x22;
	public static final int CTRL_REG4 = 0x23;
	public static final int CTRL_REG5 = 0x24;
	public static final int CTRL_REG6 = 0x25;
	public static final int REFERENCE = 0x26;
	public static final int STATUS_REG = 0x27;
	public static final int OUT_X_L = 0x28;
	public static final int OUT_X_H = 0x29;
	public static final int OUT_Y_L = 0x2A;
	public static final int OUT_Y_H = 0x2B;
	public static final int OUT_Z_L = 0x2C;
	public static final int OUT_Z_H = 0x2D;
	public static final int FIFO_CTRL_REG = 0x2E;
	public static final int FIFO_SRC_REG = 0x2F;
	public static final int INT1_CFG = 0x30;
	public static final int INT1_SRC = 0x31;
	public static final int INT1_THS = 0x32;
	public static final int INT1_DURATION = 0x33;
	public static final int INT2_CFG = 0x34;
	public static final int INT2_SRC = 0x35;
	public static final int INT2_THS = 0x36;
	public static final int INT2_DURATION = 0x37;
	public static final int CLICK_CFG = 0x38;
	public static final int CLICK_SRC = 0x39;
	public static final int CLICK_THS = 0x3A;
	public static final int TIME_LIMIT = 0x3B;
	public static final int TIME_LATENCY = 0x3C;
	public static final int TIME_WINDOW = 0x3D;
	public static final int ACT_THS = 0x3E;
	public static final int ACT_DUR = 0x3F;
	
	public void write(int addr, int... data) throws TimeoutException {
		fifo_write((data.length>1? 0x40 : 0x00) | addr, 10);
		for(int d : data) fifo_write(d, 10);
		for(int i=-1; i<data.length; i++) fifo_read(10);
	}
	
	public int read(int addr) throws TimeoutException {
		fifo_write(0x80 | addr, 10);
		fifo_write(0x00, 10);
		fifo_read(10);
		return fifo_read(10);
	}
	
	public int[] read(int addr, int[] buf) throws TimeoutException {
		fifo_write(0x80 | ( buf.length>1 ? 0x40 : 0x00) | addr, 10);
		for(int i=0; i<buf.length; i++) fifo_write(0x00, 10);
		fifo_read(10);
		for(int i=0; i<buf.length; i++) buf[i] = fifo_read(10);
		return buf;
	}
}
