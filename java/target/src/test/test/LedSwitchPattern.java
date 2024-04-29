package test;

import com.jopdesign.io.LedSwitch;
import com.jopdesign.io.LedSwitchFactory;

import util.Timer;

public class LedSwitchPattern {
	public static int[] leds = {
			0x18,
			0x24,
			0x42,
			0x81,
			0x42,
			0x24
	};
	
	public static void main(String[] args)
	{
		LedSwitchFactory LSF;
		LSF = LedSwitchFactory.getLedSwitchFactory();
		
		LedSwitch LS = LSF.getLedSwitch();
		int led_index = 0, old_val=2;
		while(true)
		{
			// Wait 5 sek
			Timer.wd();
			int i = Timer.getTimeoutMs(100);
			while (!Timer.timeout(i));
			
			// IO
			int val = LS.ledSwitch;
			if(old_val!=val) {
				System.out.println("Switches = '" + val + "'");
				old_val = val;
			}
			if(val!=0) {
				led_index++;
				if(led_index==leds.length) led_index=0;
				LS.ledSwitch = leds[led_index];
			}
		}
	}
}
