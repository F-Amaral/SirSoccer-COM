/*
 *		SIR Lab - Laboratório de Sistemas Inteligentes e Robótica
 *		SirSoccer - Sistema dedicado a categoria IEEE Very Small Size Soccer
 *
 *		Orientadores: Alberto Angonese e Eduardo Krempser
 *		Membros (2014): Johnathan Fercher, Oscar Neiva, Lucas Borsatto, Lucas Marques e Hebert Luiz.
 *		Membros (2015): Johnathan Fercher, Oscar Neiva, Lucas Borsatto, Hebert Luiz, Felipe Amaral, Manoel Stilpen e Samantha Vilaça.
 */

#ifndef COMMUNICATION_H_
#define COMMUNICATION_H_

#include <errno.h>
#include <termios.h>
#include <fcntl.h>
#include <sys/stat.h>
#include "ctime"
#include "ctype.h"
#include "unistd.h"
#include "../common.h"
#include <string.h>
#include "sstream"

#define BROADCAST true

using namespace std;
using namespace common;

class Communication{
private:
	string serialPort;
	int socketPort;
	string socketIP;
	int delay;
	int shouldBlock;
	int fd;
	int speed;
	int parity;
	long long int command;
	Command vecCommand[3];

	void setBlocking();
	void setInterfaceAttribs();
	void protocolsCommand();
	

public:
	Communication();
	void init(string serialPort, int socketPort, string socketIP, int delay);
	bool sendSerialData(Command *cmd);

	void setSerialPort(string serialPort);
	void setSocketPort(int socketPort);
	void setSocketIP(string socketIP);
	void setDelay(int delay);

	string getSerialPort();
	int getSocketPort();
	string getSocketIP();
	int getDelay();
};

#endif
