/*
 *  Rig file logger: Reads UDP packets from the xPC and writes them to the drive. When closed,
 *		    	     uploads resulting files/folders to the lab server
 *
 *  Threads: 
 *			(1) Read in UDP packets, write them to buffer
 *	        (2) Read packets from buffer, write them to file(s)
 *
 *  Directory Structure: 
 *			(1) monkey folder (each monkey gets its own folder)
 *			  	(a) day folders (all experiments on a given day go in that day's folder)
 *				    (i) run folders (each run gets its own folder)
 *					 	Files: (1) Trial parameters
 *					  	  	   (2) Measured behavioral data
 *					  	       (3) Decoded behavioral data
 *					  	  	   (4) Neural data
 *
 *	Written by Zach Irwin for the Chestek Lab, 2012
 * *********************************************************************************************
 */


/*****************/
/*** Includes: ***/
/*****************/

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h> 
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <netdb.h>
#include <pthread.h>
#include <signal.h>
#include <time.h>
#include <unistd.h>
#include <sys/stat.h>
#include <errno.h>
#include <dirent.h>

/****************************/
/*** Macros and Typedefs: ***/
/****************************/

#define BASE_DIR "/home/chestek/Data"   //Root directory for all generated data folders
#define PORT 11114	              		//local port to listen on
#define MAX_PACKET_SIZE 500          	//this will probably change
#define PACKET_BUFFER_SIZE 10000		//number of packets the buffer can hold

#define INIT_PACKET 0					//Packet type 0: Initialize directory/files
#define Z_PACKET 1						//Packet type 1: MATLAB Z struct translator data
#define M_DATA_PACKET 2					//Packet type 2: Measured behavior data
#define D_DATA_PACKET 3					//Packet type 3: Decoded behavior data
#define N_DATA_PACKET 4					//Packet type 4: Neural data
#define T_START_PACKET 5				//Packet type 5: Trial parameter data (Beginning)
#define T_END_PACKET 6					//Packet type 6: Trial parameter data (End)
#define T_DATA_PACKET 7					//Packet type 7: Trial parameter data
#define EXIT_PACKET 8					//Packet type 8: Close the file logger/directory/files/etc.

typedef struct
{
	uint8_t packetType;					//Packet type identifier: (e.g. 2 for measured behavior, 3 for decoded, etc.)
	uint8_t data[MAX_PACKET_SIZE];		//Packet data: array of received bytes
	int datalength;						//Packet data size: number of received bytes

} Packet;

/****************/
/*** Globals: ***/
/****************/

int sockFD; 								//Socket file descriptor

Packet packetBuffer[PACKET_BUFFER_SIZE];	//Buffer for incoming packets, before they are written to disk
volatile int packetBufferSize = 0;			//Current number of packets on the buffer
volatile int packetBufferStart = 0;			//Current starting index for the packet buffer

uint32_t packetCount = 0;					//Total number of packets received so far

uint8_t writingToFile = 0;					//Boolean value: is the FileWriter thread doing anything right now??
uint8_t dropFlag = 0;						//Flag set when we drop a packet -> wait for next trial

char pathName[100];

char fileNames[5][100];						//Matrix of file names

pthread_t fileWriterThread;
pthread_mutex_t packetBufferMutex = PTHREAD_MUTEX_INITIALIZER;

FILE *measBehavFP, *decBehavFP, *neuralFP, *tParamFP, *zScriptFP; //File pointers

/*************************/
/*** Helper Functions: ***/
/*************************/

//Creates a folder if it doesn't already exist, with the specified path
void createFolder(char *path, mode_t permissions){

	struct stat dirTest;

	//If the folder doesn't already exist, create it:
	if (!(stat(path, &dirTest) != -1 && S_ISDIR(dirTest.st_mode))){

		printf("\nDirectory doesn't exist: Creating %s\n", path);
		
		
		if (mkdir(path, permissions) == -1){
			printf("Directory creation failed (%s)\n", path);
			exit(1);
		}
		chmod(path,permissions);
		
	}

}

//Copies incoming packet to buffer
void bufferPacket(uint8_t *packet, int length){
	
	//Test to see if we've dropped a packet:
	if (*((uint32_t *) packet) != packetCount++){								//1st 4 bytes of packet are the index (uint32)
		printf("Dropped packet (my count = %d, their count = %d)\n", packetCount-1, *((uint32_t *) packet));
		dropFlag = 1;
	}

	pthread_mutex_lock(&packetBufferMutex);										//Block other threads
	
	//Calculate next available space on the buffer:
	int nextIdx = (packetBufferStart + packetBufferSize) % PACKET_BUFFER_SIZE;	//Wrap index back to 0

	pthread_mutex_unlock(&packetBufferMutex);									//Unblock other threads

	//Put data into packet structure on the buffer:
	packetBuffer[nextIdx].packetType = packet[4];								//5th byte of packet is the type (uint8)
	memcpy(packetBuffer[nextIdx].data, &packet[5], length-5);					//Remaining bytes are data
	packetBuffer[nextIdx].datalength = length - 5;								//Size of packet - index/type headers


	pthread_mutex_lock(&packetBufferMutex);										//Block other threads

	//Test to see if we've overloaded the packet buffer:
	if (++packetBufferSize > PACKET_BUFFER_SIZE){
		printf("Overloaded packet buffer\n");
		exit(1);
	}

	pthread_mutex_unlock(&packetBufferMutex);									//Unblock other threads
}

//fileWriter thread cancellation handler
void closeFiles(void *in){
	
	if (measBehavFP != NULL) { fclose(measBehavFP); measBehavFP = NULL; }
	if (decBehavFP != NULL)  { fclose(decBehavFP);  decBehavFP = NULL; }
	if (neuralFP != NULL)    { fclose(neuralFP);    neuralFP = NULL; }
	if (tParamFP != NULL)    { fclose(tParamFP);    tParamFP = NULL; }
	if (zScriptFP != NULL)   { fclose(zScriptFP);   zScriptFP = NULL; }

}

//Initializes directory based on the monkey name in packet + the date/time
void initDirectory(uint8_t *packet, int length){

	char monkeyName[packet[5]];
	char datestr[11] = "YYYY-MM-DD";				//Date string: YYYY-MM-DD
	char runstr[9] = "Run-000";						//Run Number string: Run-NNN

	//Close previous files, if any:
	closeFiles(0);

	//Clear the fileName matrix:
	int i;
	for (i = 0; i < 5; i++)
		memset(fileNames[i], 0, 100);

	//Test if this isn't the 1st packet:
	if (*((uint32_t *) packet) != 0){
		printf("Initializing on the wrong packet\n");
		exit(1);
	}

	//Create date string:
	time_t tm = time(NULL);								//Get current time
	strftime(datestr, 11, "F", localtime(&tm));			//Convert to local time str: YYYY-MM-DD

	//Create monkeyName string:
	memcpy(monkeyName, &packet[6], packet[5]);			//copy all the data bytes into monkeyName
	monkeyName[packet[5]] = '\0';						//add the null terminator to the end

	//Create monkey directory:
	sprintf(pathName, "%s/%s", BASE_DIR, monkeyName);
	createFolder(pathName, S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);

	//Create date directory:
	sprintf(pathName, "%s/%s/%s", BASE_DIR, monkeyName, datestr);
	createFolder(pathName, S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);

	//Create run number string:
	uint8_t run = 1;
	DIR *dp = opendir(pathName);
	struct dirent *ep;
	while ((dp != NULL) && (ep = readdir(dp)))
		if (!strncmp(ep->d_name, "Run-000", 3)) run++;
	sprintf(runstr, "Run-%03d", run);

	//Create run directory:
	sprintf(pathName, "%s/%s/%s/%s", BASE_DIR, monkeyName, datestr, runstr);
	createFolder(pathName, S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);

	//Create Z script file:
	sprintf(fileNames[4], "%s/zScript.txt.tmp", pathName);
	zScriptFP = fopen(fileNames[4], "w");					//MATLAB Z struct translator -> plain text file

	packetCount = 0;
	
	//Strip packet of monkeyName, and buffer:
	uint8_t newPacket[length - packet[5] - 1];
	memcpy(newPacket, packet, 5);					//Copy 5 header bytes
	memcpy(newPacket + 5, packet + 6 + packet[5], length - packet[5] - 1 - 5); //Copy non-Monkey-Name Data
	newPacket[4] = (uint8_t) Z_PACKET;
	bufferPacket(newPacket, length - packet[5] - 1);
}


//Creates new files for a new trial, or closes the current files:
void initFiles(uint8_t *packet, int length, int isStart){

	uint16_t tcount;

	if (isStart == 1){		//Create and open new set of files

 		packetCount = *((uint32_t *) packet);
		dropFlag = 0;
		memcpy(&tcount, packet+5, 2);						//Trial count
	 	printf("Trial %d start...\n", tcount);

		sprintf(fileNames[0], "%s/mBehavior%d.bin.tmp", pathName, tcount);
		measBehavFP = fopen(fileNames[0], "wb");				//Measured behavior -> binary file
		sprintf(fileNames[1], "%s/dBehavior%d.bin.tmp", pathName, tcount);
		decBehavFP = fopen(fileNames[1], "wb");					//Decoded behavior -> binary file
		sprintf(fileNames[2], "%s/neural%d.bin.tmp", pathName, tcount);
		neuralFP = fopen(fileNames[2], "wb");					//Neural data -> binary file
		sprintf(fileNames[3], "%s/tParams%d.bin.tmp", pathName, tcount);
		tParamFP = fopen(fileNames[3], "wb");					//Trial parameters -> binary file

		packet[4] = (uint8_t) T_DATA_PACKET;
		bufferPacket(packet, length);					//Buffer the packet
	}
	else{					//Close current files

		memcpy(&tcount, packet+5, 2);						//Trial count
		printf("Trial %d stop... \n", tcount);

		if (dropFlag == 0){
			//Create new packet -> strip out trialCount:
			packet[4] = (uint8_t) T_DATA_PACKET;
			uint8_t newPacket[length - 2];
			memcpy(newPacket, packet, 5);					//Copy 5 header bytes
			memcpy(newPacket + 5, packet + 7, length - 2); //Copy non-trialCount Data

			//Buffer the packet and wait until the buffer is cleared:
			bufferPacket(newPacket, length-2);				//Buffer the packet
			while (packetBufferSize || writingToFile)		//Wait until buffer cleared
				usleep(10);

			//Remove the "*.tmp" from file names, so Rsync can transfer them to the server:
			char newname[100]; int i;
			for (i = 0; i < 5; i++)
				if (i != 4 || zScriptFP != NULL)
					if (rename(fileNames[i],strndup(fileNames[i],strlen(fileNames[i])-4)) == -1) 
						printf("\n\nFile rename failed... please manually rename Trial %d files\n\n", tcount);
		}
		else if (zScriptFP != NULL)
			if (rename(fileNames[4],strndup(fileNames[4],strlen(fileNames[4])-4)) == -1) 
						printf("\n\nFile rename failed... please manually rename Trial %d files\n\n", tcount);

		//Close the files:
		closeFiles(0);
	}


}

//Writes packet to its relevant file:
void writePacket(Packet *p){
	writingToFile = 1;
	switch (p->packetType){
		case M_DATA_PACKET:									//Write measured behavior data
			fwrite(p->data, 1, p->datalength, measBehavFP);
			break;
		case D_DATA_PACKET:									//Write decoded behavior data
			fwrite(p->data, 1, p->datalength, decBehavFP);
			break;
		case N_DATA_PACKET:									//Write neural data
			fwrite(p->data, 1, p->datalength, neuralFP);
			break;
		case T_DATA_PACKET:									//Write trial parameter data
			fwrite(p->data, 1, p->datalength, tParamFP);
			break;
		case Z_PACKET:										//Write MATLAB Z struct translator data
			fwrite(p->data, 1, p->datalength, zScriptFP);
			break;
		default:
			printf("Tried to write a non-data packet\n");
			exit(1);
			break;
	}
	writingToFile = 0;
}

//Ctrl-c handler -> cancels fileWriter thread
void finishMain(int sig){
	printf("\nFile Logger exiting now. Peace. \n");
	pthread_cancel(fileWriterThread);
	pthread_join(fileWriterThread, NULL);
	close(sockFD);
	exit(0);
}

/*********************/
/*** Thread Mains: ***/
/*********************/

// Writes all packets on the buffer to their respective files
void * fileWriterMain(void * in){

	Packet p;

	pthread_setcancelstate(PTHREAD_CANCEL_ENABLE, NULL);	//Enables cancellation of this thread
	pthread_setcanceltype(PTHREAD_CANCEL_DEFERRED, NULL);	//Thread won't cancel until it reaches a cancellation point
	pthread_cleanup_push(closeFiles, NULL);					//Set up thread cancellation handler

	//Watch for buffered packets, and write them to the necessary files:
	while(1){
		
		//Do we have buffered packets? If so, deal with them. If not, sleep:
		if (packetBufferSize){
			
			//Grab the oldest packet off the buffer:
			memcpy(&p, &packetBuffer[packetBufferStart], sizeof p);

			pthread_mutex_lock(&packetBufferMutex);			//Block other threads

			//Update packetBufferStart index and packBufferSize:
			packetBufferStart = (packetBufferStart + 1) % PACKET_BUFFER_SIZE;
			packetBufferSize--;

			pthread_mutex_unlock(&packetBufferMutex);		//Unblock other threads

			//Deal with current packet:
			writePacket(&p);
		}
		else{
			
			pthread_testcancel();							//Set thread cancellation point
			usleep(10);										//Sleep a bit, so we can yield to the main thread
		}
	}

	pthread_cleanup_pop(0);									//Matched call to pthread_cleanup_push -> Noop

}


// Initializes FileLogger, creates fileWriter thread, listens for & buffers incoming UDP packets
void main(){

	struct sockaddr_in my_addr, recv_addr;
	int addr_len = sizeof recv_addr;
	uint8_t recvbuf[MAX_PACKET_SIZE]; 						//UDP receive buffer

	//Set up local socket address struct (my_addr):
	memset(&my_addr, 0, sizeof my_addr); 					//zero out all fields
	my_addr.sin_family = AF_INET; 							//IPv4
	my_addr.sin_port = htons(PORT); 						//set port for this socket
	my_addr.sin_addr.s_addr = inet_addr("192.168.1.2"); 	//IP address for this socket

	//Set up socket, and bind to address:
	if ((sockFD = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP)) == -1){
		printf("Socket setup failed\n");
		exit(1);
	}

	if (bind(sockFD, (struct sockaddr *) &my_addr, addr_len) == -1){
		printf("Socket binding failed\n");
		exit(1);
	}
	
	//Create FileWriter thread:
	if (pthread_create(&fileWriterThread, NULL, fileWriterMain, NULL)){
		printf("File Writer thread creation failed\n");
		exit(1);
	}

	//Set up ctrl-c handler (called when user types ctrl-c on the terminal):
	signal(SIGINT, finishMain);
	
	//Listen for incoming packets, and place on buffer:
	while(1){
		
		int bytesread = recvfrom(sockFD, recvbuf, MAX_PACKET_SIZE, 0, (struct sockaddr *)&recv_addr, (socklen_t *)&addr_len);
		
		if (bytesread == -1){
			printf("Receiving UDP data failed\n");
			exit(1);
		}
		else if (bytesread == 0){
			printf("Zero bytes read -> remote computer closed connection?\n");
		}

		//Test packet type:
		switch (recvbuf[4]){

			case INIT_PACKET:
				initDirectory(recvbuf, bytesread);	//Init packet -> initialize directory
				break;
			case T_START_PACKET:
				initFiles(recvbuf, bytesread, 1);	//T_Start packet -> initialize files
				break;
			case T_END_PACKET:
				initFiles(recvbuf, bytesread, 0);	//T_End packet -> close current files
				break;
			case EXIT_PACKET:
				finishMain(0);						//Exit packet -> close program
				break;
			default:
				if (dropFlag == 1) break;
				bufferPacket(recvbuf, bytesread);	//Data packet -> write to buffer
				break;

		}

	}
	
	return;
}









