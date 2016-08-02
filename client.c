#include "client.h"


/* setup_queue: initializes queue and front/end pointers
 * This should be done in the beginning of main.
 */
int setup_queue()
{
	front = malloc(sizeof(CLIENT));
	if(front == NULL) {
		perror("could not initialize queue");
		exit(1);
	}

	strncpy(front->filename, "head", FILENAME_SIZE);
	front->next = NULL;
	end = front;
	return 0;
}


/* destoy_queue: deallocate the nodes within the queue.
 * Doesn't need to return anything because it just calls
 * free a bunch of times.
 * In theory, we should only be doing one free since the
 * queue should be empty anyway when all clients are served.
 */
void destroy_queue()
{
	CLIENT * tmp = front;
	while(front != NULL) {
		front = front->next;
		free(tmp);
		tmp = front;
	}
}


/* enqueue: add a new client to the end of the queue
 * (pointed to by the end pointer).
 * Returns 0 on success, -1 if couldn't create new client
 * node.
 */
int enqueue(char* name)
{
	CLIENT * temp = malloc(sizeof(CLIENT));
	if(temp == NULL) {
		perror("enqueue: malloc failed");
		return -1;
	}

	strncpy(temp->filename, name, FILENAME_SIZE - 1);
	end->next = temp;
	temp->next = NULL;
	end = temp;

	return 0;
}


/* dequeue: remove a client from the front of the queue,
 * placing its file name in the buffer (of size "size")
 * pointed to by name.
 * Returns 0 on success, -1 if the queue is empty.
 */
int dequeue(char * name, int size)
{
	if(isEmpty()) {
		fprintf(stderr, "dequeue: queue is empty\n");
		return -1;
	}

	CLIENT * tmp = front->next;
	strncpy(name, tmp->filename, size);
	front->next = tmp->next;
	if(end == tmp) end = front;
	free(tmp);

	return 0;
}


/* isEmpty: checks to see if the queue is empty (i.e. front
 * points to a pointer which has a value of NULL)
 */
int isEmpty()
{
	return front->next == NULL;
}


void print_queue()
{
	CLIENT * it = front->next;
	while(it != NULL) {
		printf("filename: %s\n", it->filename);
		it = it->next;
	}
}
