/*
 * login:	ofuon001
 * date:	11/9/15
 */

#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <semaphore.h>
#include <string.h>
#include <pthread.h>


#ifndef CLIENT_H_
#define CLIENT_H_

#define FILENAME_SIZE 128


typedef struct client {
	char filename[FILENAME_SIZE];
	struct client* next;
} CLIENT;

CLIENT * front;
CLIENT * end;


int setup_queue();
void destroy_queue();
int enqueue(char* name);
int dequeue(char * name, int size);
int isEmpty();
void print_queue();

#endif
