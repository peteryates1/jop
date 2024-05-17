package test;

public class SPI {
	public static class TimeoutException extends Exception {
		public TimeoutException(String message) {
			super(message);
		}
	}
	
	public static final int RECEIVE_FULL   = 0x20;
	public static final int RECEIVE_HALF   = 0x10;
	public static final int RECEIVE_EMPTY  = 0x08;
	public static final int TRANSMIT_FULL  = 0x04;
	public static final int TRANSMIT_HALF  = 0x02;
	public static final int TRANSMIT_EMPTY = 0x01;
	
	public static final String[] STATUS_BIT_NAMES = { "RECEIVE_FULL", "RECEIVE_HALF", "RECEIVE_EMPTY", "TRANSMIT_FULL", "TRANSMIT_HALF", "TRANSMIT_EMPTY" };
	public static final int[]    STATUS_BIT_MASK  = {  RECEIVE_FULL,   RECEIVE_HALF,   RECEIVE_EMPTY,   TRANSMIT_FULL,   TRANSMIT_HALF,   TRANSMIT_EMPTY  };
	
	public static final String statusToString(int c) {
		StringBuilder b = new StringBuilder();
		for(int i=0; i<STATUS_BIT_MASK.length; i++)
			if (STATUS_BIT_MASK[i] == ( c & STATUS_BIT_MASK[i] )) {
				if(b.length()>0) b.append(", ");
				b.append(STATUS_BIT_NAMES[i]);
			}
		return b.toString();
	}

	public volatile int control;  // cpol | cpha | Rx Full | Rx Half | Rx Empty | Tx Full | Tx Half | Tx Empty
	public volatile int fifo;
	public volatile int address;  // peripheral address

	public void fifo_write(int data, int timeout) throws TimeoutException {
		int c=0;
		while(++c<timeout)
			if(TRANSMIT_FULL != (control & TRANSMIT_FULL))
				break;
		if(c==timeout)
			throw new TimeoutException("tx fifo timeout");
		fifo = data;
	}
	
	public int fifo_read(int timeout) throws TimeoutException {
		int i=0;
		while(i++<timeout)
			if(RECEIVE_EMPTY != (control & RECEIVE_EMPTY))
				break;
		if(i==timeout) 
			throw new TimeoutException("rx fifo timeout");
		return fifo;
	}
}
