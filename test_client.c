#include "client.h"

int main(int argc, char ** argv)
{
	int tmp;

	setup_queue();

	tmp = isEmpty();
	printf("isEmpty? %d\n", tmp);

	char * string = calloc(FILENAME_SIZE, sizeof(char));

	bzero(string, FILENAME_SIZE);
	strcpy(string, "item 1");
	enqueue(string);
	printf("Here is the queue:\n");
	print_queue();

	bzero(string, FILENAME_SIZE);
	strcpy(string, "item 2");
	enqueue(string);
	printf("\nHere is the queue:\n");
	print_queue();

	bzero(string, FILENAME_SIZE);
	dequeue(string, FILENAME_SIZE);
	printf("\nHere is the queue:\n");
	print_queue();

	bzero(string, FILENAME_SIZE);
	strcpy(string, "item 3");
	printf("\nHere is the queue:\n");
	enqueue(string);


	tmp = isEmpty();
	printf("isEmpty? %d\n", tmp);

	destroy_queue();
	free(string);

	return 0;
}
