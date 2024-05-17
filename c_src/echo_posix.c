#include <stdlib.h>
#include <limits.h>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>
#include <string.h>
#include <stdint.h>

#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/stat.h>

// // maximum of 1MB
// #define MAX_MEM	(1048576/4)

// static int prog_cnt = 0;
// static char prog_char[] = {'|','/','-','\\','|','/','-','\\'};
static char *exitString = "JVM exit!";

// static int echo = 0;
// static int usb = 0;
// static int cont = 0;

int serial_open(char *fname) {
	struct termios opts;
	int fd;
	
	fd = open(fname, O_RDWR);
	if (fd < 0) {
		perror("Error opening serial port");
		exit(1);
	}
	
	// get current port options
	if (tcgetattr(fd, &opts)) {
		perror("Error getting serial options");
		exit(1);
	}
	
	// set baud rate
	cfsetispeed(&opts, B460800);
	cfsetospeed(&opts, B460800);
	
	// local port, enable receiver
	opts.c_cflag |= (CLOCAL | CREAD);
	
	// set to 8-bit mode
	opts.c_cflag &= ~CSIZE;
	opts.c_cflag |= CS8;
	
	// no parity, 1 stop bit
	opts.c_cflag &= ~(PARENB | CSTOPB);
	
	// disable hardware flow control if available
#ifdef CNEW_RTSCTS
	opts.c_cflag &= ~CNEW_RTSCTS;
#endif

	// disable any processing; full raw mode
	opts.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG);
	opts.c_oflag &= ~OPOST;
	
	// no software flow control either
	opts.c_iflag &= ~(IXON | IXOFF | IXANY);
	
	if (tcsetattr(fd, TCSANOW, &opts)) {
		perror("Error setting serial options");
		exit(1);
	}
	
	return fd;
}

int main(int argc, char *argv[])
{
	unsigned char c;
	int i, j;
	// int64_t l;
	
	int fdSerial;
	// int fdFile;

	// int64_t *ram;
	// int64_t len;

	// uint8_t *byt_buf;
	uint8_t *buf;

    buf = calloc(10000, sizeof(char));

	// char *ptr;
	// struct stat statbuf;
	
	// open serial port
	fdSerial = serial_open(argv[argc-1]);
    //
    // read serial output of Jop
    //
	for (j=0; j<strlen(exitString)+1; ++j) {
		buf[j] = 0;
	}
    long rdCnt;
    for (;;) {
            if(read(fdSerial, &c, 1)<=0) continue;
        printf("%c", c); fflush(stdout);
        for (j=0; j<strlen(exitString)-1; ++j) {
            buf[j] = buf[j+1];
        }
        buf[strlen(exitString)-1] = c;
        if (strcmp(buf, exitString)==0) {
			printf("\n");
			fflush(stdout);
            break;
        }
        //printf("'%c' %d\n", c, c); fflush(stdout);
    }

	close(fdSerial);

	return 0;
}
