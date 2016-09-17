/*
 *		SIR Lab - Laboratório de Sistemas Inteligentes e Robótica
 *		SirSoccer - Sistema dedicado a categoria IEEE Very Small Size Soccer
 *
 *		Orientadores: Alberto Angonese e Eduardo Krempser
 *		Membros (2014): Johnathan Fercher, Oscar Neiva, Lucas Borsatto, Lucas Marques e Hebert Luiz.
 *		Membros (2015): Johnathan Fercher, Oscar Neiva, Lucas Borsatto, Hebert Luiz, Felipe Amaral, Manoel Stilpen e Samantha Vilaça.
 */
 
#include "Communication.h"

Communication::Communication(){
	shouldBlock = 0;
	serialPort = "/dev/ttyUSB0";
	socketPort = 8080;
	socketIP = "127.0.0.1";

	#ifdef OLD_TRANSMISSION
		speed = B9600;
	#else
		speed = B57600;
	#endif

	parity = 0;
}

void Communication::init(string serialPort, int socketPort, string socketIP, int delay){
	this->serialPort = serialPort;
	this->socketPort = socketPort;
	this->socketIP = socketIP;
	this->delay = delay;
}

void Communication::setBlocking(){
	struct termios tty;

	memset (&tty, 0, sizeof(tty));
	if (tcgetattr (fd, &tty) != 0) {
		printf ("error %d from tggetattr", errno);
		return;
	}

	tty.c_cc[VMIN]  = shouldBlock ? 1 : 0;
	tty.c_cc[VTIME] = 5;            // 0.5 seconds read timeout

	if (tcsetattr (fd, TCSANOW, &tty) != 0)
		printf ("error %d setting term attributes", errno);
}

void Communication::setInterfaceAttribs(){
	struct termios tty;

	memset(&tty, 0, sizeof tty);
	if (tcgetattr (fd, &tty) != 0) {
		printf ("error %d from tcgetattr", errno);
	}	

	cfsetospeed(&tty, speed);
	cfsetispeed(&tty, speed);

	tty.c_cflag = (tty.c_cflag & ~CSIZE) | CS8;  // 8-bit chars
	// disable IGNBRK for mismatched speed tests; otherwise receive break
	// as \000 chars
	tty.c_iflag &= ~IGNBRK;         // ignore break signal
	tty.c_lflag = 0;                // no signaling chars, no echo,
	// no canonical processing
	tty.c_oflag = 0;                // no remapping, no delays
	tty.c_cc[VMIN]  = 0;            // read doesn't block
	tty.c_cc[VTIME] = 5;            // 0.5 seconds read timeout

	tty.c_iflag &= ~(IXON | IXOFF | IXANY); // shut off xon/xoff ctrl

	tty.c_cflag |= (CLOCAL | CREAD);// ignore modem controls,
	// enable reading
	tty.c_cflag &= ~(PARENB | PARODD);      // shut off parity
	tty.c_cflag |= parity;
	tty.c_cflag &= ~CSTOPB;
	tty.c_cflag &= ~CRTSCTS;

	if (tcsetattr(fd, TCSANOW, &tty) != 0) {
		printf ("error %d from tcsetattr", errno);
	}
}

void Communication::protocolsCommand(){
	stringstream ss;
	for(int i = 0 ; i < 3 ; i++){

		if(vecCommand[i].left < 100){
			ss << 0 << vecCommand[i].left;
		} else {
			ss << vecCommand[i].left;
		}

		if(vecCommand[i].right < 100){
			ss << 0 << vecCommand[i].right;
		} else {
			ss << vecCommand[i].right;
		}

	}

	ss >> command;
}

bool Communication::sendSerialData(Command *cmd){
	
	#ifdef OLD_TRANSMISSION
	
		for(int i = 0 ; i < 3 ; i++)
			vecCommand[i] = cmd[i];

		protocolsCommand();
		bool ok = true;

		fd = open(serialPort.c_str(), O_RDWR | O_NOCTTY | O_SYNC);
		char str[2];

		if (fd < 0) {
			//printf ("Transmissor desconectado \n");
	        ok = false;
		}else{
	    	setInterfaceAttribs();
	    	setBlocking();
	        write(fd, (char*)(&command), 8);
	    }
	    close(fd);
	
	#else

	    stringstream ss;
		string s;
		string comando;
		bool ok = true;

		#ifdef BROADCAST
		for(int i = 0 ; i < 1 ; i++){
		#else
		for(int i = 0 ; i < 3 ; i++){
		#endif
			int count = 0; 
			vecCommand[i] = cmd[i];
			unsigned char convComando[20];
			protocolsCommand();
		#ifdef BROADCAST
			ss << "./src/SirSoccer-COM/convertBroadcast.sh";
			ss << " " << (int) vecCommand[0].left << " " << (int) vecCommand[0].right;
			ss << " " << (int) vecCommand[1].left << " " << (int) vecCommand[1].right;
			ss << " " << (int) vecCommand[2].left << " " << (int) vecCommand[2].right;
		#else
			ss << "./src/SirSocer-COM/convert.sh";
			ss << i;
			ss << " " << (int) vecCOmmand[i].left << " " << (int) vecCOmmand[i].right;
		#endif	
			s = ss.str();
			comando = cmdTerminal(s.c_str());
			
			if (i == 0){
				cout << comando << endl;
			}
			
			for(int j = 0 ; j < 41; j++){ //36
				char a = 0;
				char b = 0;
				stringstream cmdConv;
				a = comando[j];
				j++;
				b = comando[j]; 
				cmdConv << "0x" << a << b;
				convComando[count]  = stoi(cmdConv.str().c_str(), 0, 16);
				clearSS(cmdConv);		
				count++;		
				usleep(100);
			}
		
			fd = open(serialPort.c_str(), O_RDWR | O_NOCTTY | O_SYNC);
			if (fd < 0) {
	        	ok = false;
			}else{
	    			setInterfaceAttribs();
	    			setBlocking();
	        		write(fd, convComando, sizeof(convComando));    		
	    		}	
			usleep(5000);
	    	close(fd);
			clearSS(ss);
		}
	#endif

    return ok;
}
	
void Communication::setSerialPort(string serialPort){
	this->serialPort = serialPort;
}

string Communication::getSerialPort(){
	return serialPort;
}
	
void Communication::setSocketPort(int socketPort){
	this->socketPort = socketPort;
}

int Communication::getSocketPort(){
	return socketPort;
}

void Communication::setSocketIP(string socketIP){
	this->socketIP = socketIP;
}

string Communication::getSocketIP(){
	return socketIP;
}

int Communication::getDelay(){
	return delay;
}

void Communication::setDelay(int delay){
	this->delay = delay;
}
