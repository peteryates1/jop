package test.cmd;

import test.MyApp;
import test.MyApp.AbstractCommand;

public class Hello extends AbstractCommand {
	
	public static final Hello INSTANCE = new Hello();
	
	public Hello() {
		super("hello");
	}

	public void run(MyApp context, String ... args) {
		test.HelloWorld.main(new String[] {});
	}
}
