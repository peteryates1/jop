package test.cmd;

import test.MyApp;
import test.MyApp.AbstractCommand;

public class Halt extends AbstractCommand {
	
	public static final Halt INSTANCE = new Halt();
	
	public Halt() {
		super("halt");
	}

	public void run(MyApp context, String ... args) {
		context.setHalt(true);
	}
}
