package test;

import com.jopdesign.io.IOFactory;
import com.jopdesign.io.LedSwitch;
import com.jopdesign.io.LedSwitchFactory;
import com.jopdesign.io.SysDevice;

import test.SPI.TimeoutException;
import util.Timer;

public class SpiritLevel {
	
	private static final int n = 10;
	private static final int[] y = new int[n]; 
	private static int y_index = 0, y_sum = 0, y_average = 0;
	
	private static SPIAccelerometerLIS3DH accelerometer = SPIAccelerometerLIS3DH.instance;
	private static SysDevice sysDevice = IOFactory.getFactory().getSysDevice();
	
	public static void main(String[] args) {
		try {
			LedSwitchFactory LSF;
			LSF = LedSwitchFactory.getLedSwitchFactory();
			LedSwitch LS = LSF.getLedSwitch();
			accelerometer.write(SPIAccelerometerLIS3DH.CTRL_REG1, 0x32, 0x00, 0x00, 0x00);
			for(int i=0; i<n; i++) y[i] = 0;
			int t = Timer.getTimeoutMs(10);
			int wd_count = 0;
			int wd_value = 0;
			int buf[] = new int[2];
			while(true) {
				if(Timer.timeout(t)) {
					if(wd_count++>10) {
						wd_count = 0;
						sysDevice.wd = ++wd_value;
					}
					t = Timer.getTimeoutMs(10);
					y_sum -= y[y_index];
					accelerometer.read(SPIAccelerometerLIS3DH.OUT_Y_L, buf);
					y[y_index] = ((buf[0] << 16) | (buf[1] << 24)) >> 24;
					y_sum += y[y_index];
					y_average = y_sum / n;
					y_index++;
					if (y_index >= n) y_index = 0;
					if (y_average > -4 && y_average < 4)          LS.ledSwitch = 0x18;
					else if (y_average >= 4 && y_average < 8)     LS.ledSwitch = 0x08;
					else if (y_average >= 8 && y_average < 12)    LS.ledSwitch = 0x04;
					else if (y_average >= 12 && y_average < 16)   LS.ledSwitch = 0x02;
					else if (y_average >= 16)                     LS.ledSwitch = 0x01;
					else if (y_average > -8 && y_average <= -4)   LS.ledSwitch = 0x10;
					else if (y_average > -12 && y_average <= -8)  LS.ledSwitch = 0x20;
					else if (y_average > -16 && y_average <= -12) LS.ledSwitch = 0x40;
					else if (y_average <= -16)                    LS.ledSwitch = 0x80;
				}
			}
		} catch (TimeoutException e) {
			System.out.println("Timeout "+e.getMessage());
		}
	}
}
