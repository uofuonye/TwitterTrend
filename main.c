
#include "client.h"
#include "database.h"



sem_t served;
int num_served = 0;

sem_t queue_access;
sem_t empty;
sem_t full;


/* buildQueue: reads lines from the input file, where each
 * line contains a different client.
 * TODO: work with a limited shared queue size for extra credit
 */
int buildQueue(char * filename)
{
	int num_clients = 0;
	FILE *fp;
	char line[FILENAME_SIZE];

	
	//Get the file name
	fp = fopen(filename, "r");// read mode only
	if(fp == NULL)
	{
		perror("Error while opening the file.\n");
		exit(EXIT_FAILURE);
	}

	//read a line 
	while(fgets(line, FILENAME_SIZE, fp) != NULL) 
	{
		strtok(line, "\n"); // get rid of newline

		if(sem_trywait(&full)) {
			printf("Waiting to add clients to the full queue\n");
			sem_wait(&full);
		}

 		sem_wait(&queue_access);
		enqueue(line);
 		sem_post(&queue_access);

		sem_post(&empty);

		num_clients += 1;
	}
	fclose(fp);

	return num_clients;
}

/* serveClients: function for threads which are meant to handle clients.
 * TODO: currently does busy waiting in the queue. Need to change to 
 * use semaphore to suspend threads when the queue is empty.
 */
static void *serveClients(void *arg)
{
	//FILE *fp = NULL;
	long ID = ((long)arg);
	char buffer[FILENAME_SIZE];
	int deq_ret = 0;

	while(1)
	{	
		sem_wait(&empty);

		sem_wait(&queue_access);
		deq_ret = dequeue(buffer, FILENAME_SIZE);
		sem_post(&queue_access);

		if(deq_ret) continue;


		printf("Thread %li is handling client %s \n",
				ID, buffer);

		// handle client request
		if(write_file(buffer)) {
			fprintf(stderr, "serveClients: write_file failed\n");
		} else {
			printf("Thread %li has finished handling client %s\n",
					ID, buffer);
			sem_wait(&served);
			num_served += 1;
			sem_post(&served);
		}
		sem_post(&full);

	}

#ifdef DEBUG
	printf("serveClients: leaving thread %d\n",
			pthread_self());
#endif

	return NULL;
}


/* main: this is supposedly required for a C program
 * 1. Create threads to handle clients
 * 2. Add clients from the file
 * 3. Join threads and leave
 * Returns 0 if everything was done correctly.
 */
int main(int argc, char** argv)
{	
	int num_queries, num_threads;
	long i;
	pthread_t * tids;

	if(argc != 3)
	{	
		fprintf(stderr,
			"USAGE: %s [input_file_path] [num_threads]\n",
			argv[0]);
		exit(1);
	}	

	// do preliminary work (database, queue, etc.)
	setup_queue();
	populate_database("TwitterDB.txt");

	num_threads = atoi(argv[2]);

	sem_init(&queue_access, 0, 1);
	sem_init(&empty, 0, 0);
	sem_init(&served, 0, 1);
	sem_init(&full, 0, num_threads);


	// create threads to handle clients
	tids = calloc(num_threads, sizeof(pthread_t));
	for(i = 0; i < num_threads; i++)
	{
	 	if(pthread_create(&tids[i], NULL, serveClients, (void *)(i + 1)))
		{
			perror("main: could not create create thread");
		    exit(1);
		}
	}	

	// populate queue
	num_queries = buildQueue(argv[1]);

	while(num_served != num_queries);
	

   	// cancel threads
	for (i = 0; i < num_threads; i++) 
	{
		if(pthread_cancel(tids[i])) 
		{
			perror("main: could not join thread");
		    exit(1);
		}
	}

	// clean up
	destroy_database();
	destroy_queue();

	free(tids);

	printf("Finished handling all clients\n");
	return 0;
}

