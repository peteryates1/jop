package test;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import com.jopdesign.io.LedSwitch;
import com.jopdesign.io.LedSwitchFactory;
import com.jopdesign.sys.GC;

import test.cmd.Halt;
import test.cmd.Hello;
import test.cmd.Test;

import util.Timer;

public class MyApp {
	

	public static int[] leds = {
		0x18,
		0x24,
		0x42,
		0x81,
		0x42,
		0x24
	};
	
	public static final int WD_PERIOD = 100;
	public static final int PATTERN_PERIOD = 80;
	
	private boolean halt = false;
	
	public boolean isHalt() {
		return halt;
	}

	public void setHalt(boolean halt) {
		this.halt = halt;
	}

	public static interface Command {
		boolean matches(String commandLine);
		void run(MyApp context, String commandLine);
	}
	
	public static abstract class AbstractCommand implements Command {
		private final String commandName;
		public AbstractCommand(String commandName) {
			this.commandName = commandName;
		}
		public boolean matches(String commandLine) {
			int space = commandLine.indexOf(' ');
			String command = space==-1? commandLine: commandLine.substring(0, space);
			return command.trim().toLowerCase().equals(commandName);
		}
		public void run(MyApp context, String commandLine) {
			List<String> l = new ArrayList<String>();
			String s = commandLine;
			int i = s.indexOf(' ');
			while(i!=-1) {
//				System.out.println("s: "+s);
//				System.out.println("i: "+i);
				l.add(s.substring(0,  i));
//				System.out.println(l);
				s = s.substring(i).trim();
				i = s.indexOf(' ');
			}
//			System.out.println("s: "+s);
//			System.out.println("i: "+i);
			l.add(s);
//			System.out.println(l);
			String[] args = new String[l.size()-1];
			for(i=1; i<=args.length; i++) {
				System.out.println(l.get(i));
				args[i-1] = l.get(i);
			}
//			System.out.println("run");
			run(context, args);
		}
		public abstract void run(MyApp context, String ... args);
		public String toString() {
			return "commandName = " + commandName;
		}
	}
	
	public static Command freeMemory = new AbstractCommand("fm") {
		public void run(MyApp context, String ... args) {
			System.out.println("total memory: "+GC.totalMemory()+", free memory: "+GC.freeMemory());
		}
	};
	
	private static Command[] commands = { Halt.INSTANCE, Test.INSTANCE, Hello.INSTANCE, freeMemory };
	
	public void doCommand(String commandLine) {
		if(commandLine!=null && commandLine.length()>0) {
			boolean matched = false;
			for(Command command : commands)
				if(matched |= command.matches(commandLine)) {
					System.out.println(command.toString());
					command.run(this, commandLine);
					break;
				}
			if(!matched)
				System.out.println("Unknown command: "+commandLine);
		}
	}
	
	public void run() {
		LedSwitch LS = LedSwitchFactory.getLedSwitchFactory().getLedSwitch();
		int led_index = 0, old_val=2;
		int last_wd = Timer.getTimeoutMs(WD_PERIOD);
		int last_pattern = Timer.getTimeoutMs(PATTERN_PERIOD);
		StringBuilder sb = new StringBuilder();
		System.out.println("READY:");
		while(!halt) {
			if(Timer.timeout(last_pattern)) {
				last_pattern = Timer.getTimeoutMs(PATTERN_PERIOD);
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
			if(Timer.timeout(last_wd)) {
				last_wd = Timer.getTimeoutMs(WD_PERIOD);
				Timer.wd();
			}
			try {
				if(System.in.available()==1) {
					int c = System.in.read();
					if(c=='\r') {
						System.out.write('\r');
						System.out.write('\n');
						if(sb.length()>0) {
							try {
								String commandLine = sb.toString().trim();
								doCommand(commandLine);
							} catch (Throwable e) {
								System.out.println("Throwable: "+e);
								e.printStackTrace();
							}
							sb.setLength(0);
							System.out.println("Ready");
						}
					} else if(c>=' ' && c<=127) {
						System.out.write(c);
						sb.append((char) c);
					}
				}
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
	}
	
	public static void main(String[] args) {
		new MyApp().run();
	}
}
