#include "client.h"


sem_t getMutex, printMutex;


/* buildQueue: reads lines from the input file, where each
 * line contains a different client.
 * TODO: work with a limited shared queue size for extra credit
 */
void buildQueue(char* filename, int *num_clients)
{
	FILE *fp;
	char line[FILENAME_SIZE];

	
	//Get the file name
	fp = fopen(filename, "r");// read mode only
	if (fp==NULL)
	{
		perror("Error while opening the file.\n");
		exit(EXIT_FAILURE);
	}

	*num_clients = 0;
	//read a line 
	while(fgets(line, MAX_LINE_SIZE, fp) != NULL) 
	{
		enqueue(line);
		(*num_clients)++;
	}
	fclose(fp);

	sem_wait(&getMutex);
	end_queries = 1;
	sem_post(&getMutex);
}


/* serveClients: function for threads which are meant to handle clients.
 * TODO: currently does busy waiting in the queue. Need to change to 
 * use semaphore to suspend threads when the queue is empty.
 */
static void *serveClients(void *arg)
{
	FILE *fp = NULL;
	int ID = *((int*)arg);
	char buffer[FILENAME_SIZE];

	while(!isEmpty())
	{	
		//get a client from List
		sem_wait(&getMutex);

		if(isEmpty() && end_queries) break;

		if(!isEmpty()) {
			dequeue(buffer, FILENAME_SIZE);
		}

		sem_post(&getMutex);
		
		sem_wait(&printMutex);
		printf("Thread %i is handling client %s \n",
				pthread_self(), clientname);
		sem_post(&printMutex);


		//produce result files
		//
		//

		char *result = malloc(strlen(clientName)+strlen(".result")+1);//1 for the zero-terminator
		if(result ==NULL) 
		{
		 	perror("call to malloc failed");
			exit(EXIT_FAILURE);
		}
	    	strcpy(result, clientName);
	    	strcat(result, ".result");

		//write to dataset
		//
		//
	}

	sem_post(&getMutex);
#ifdef DEBUG
	printf("serveClients: leaving thread %d\n",
			pthread_self());
#endif
}


/* main: this is supposedly required for a C program
 * 1. Create threads to handle clients
 * 2. Add clients from the file
 * 3. Join threads and leave
 * Returns 0 if everything was done correctly.
 */
int main(int argc, char** argv)
{	
	if(argc != 3)
	{	
		fprintf(stderr,
			"USAGE: %s [input_file_path] [num_threads]\n",
			argv[0]);
		exit(1);
	}	
	int num_clients, num_threads;
	num_threads = atoi(argv[2]);
	setup_queue();
	
	// intialize semaphores
	sem_init(&getMutex, 0, 1);
	sem_init(&printMutex, 0, 1);
	sem_init(&empty, 0, 0);

	// create threads to handle clients
	pthread_t tids[num_threads];	
	int i;
	for(i = 0; i < num_threads; i++)
	{
	 	if(pthread_create(&tids[i], NULL, serveClients, i))
		{
			perror("main: could not create create thread");
		    exit(1);
		}
	}	

	// populate queue
	buldQueue(argv[1], &num_clients);

   	// wait for threads
	for (i = 0; i < num_threads; i++) 
	{
		if(pthread_join(tids[i], NULL)) 
		{
			perror("main: could not join thread");
		    exit(1);
		}
	}

	printf("Finished handling all clients\n");
	return 0;
}

