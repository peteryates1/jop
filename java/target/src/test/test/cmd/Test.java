package test.cmd;

import test.MyApp;
import test.MyApp.AbstractCommand;

public class Test extends AbstractCommand {
	
	public static final Test INSTANCE = new Test();
	
	public Test() {
		super("test");
	}

	public void run(MyApp context, String ... args) {
		if(args.length>0) {
			if(args[0].equals("jvm"))
				
				jvm.DoAll.main(new String[] {});
			else if(args[0].equals("jdk"))
				jdk.DoAll.main(new String[] {});
			else if(args[0].equals("jvmtest"))
				jvmtest.JopTestSuite.main(new String[] {});
			else if(args[0].equals("jbe"))
				jbe.DoAll.main(new String[] {});
		} else {
			test.DoAll.main(new String[] {});
		}
	}
}
