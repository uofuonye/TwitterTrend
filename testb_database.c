#include "database.h"

int main(int argc, char ** argv)
{
	populate_database("TwitterDB.txt");
	int i;
	for(i = 0; i < NUM_BUCKETS; i++) 
		print_bucket(i);

	char ** keywords;

	if(find_keywords("Minneapolis", &keywords)) {
		perror("could not find keywords for Minneapolis");
		exit(1);
	} else {
		printf("\n\nKeywords for Minneapolis:\n");
		for(i = 0; i < NUM_KEYWORDS; i++) {
			printf("%s\n", keywords[i]);
		}
	}

	write_file("client1.txt");


	return 0;
}
