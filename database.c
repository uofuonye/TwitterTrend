#include "database.h"

Node db[NUM_BUCKETS];


#if 0
/* compare_nodes: compares the city entity of
 * two node structures. This line is equivalent to
 * lhs > rhs ?
 */
int compare_nodes(Node * lhs, Node * rhs)
{
	int i;
	char * name1 = lhs->city;
	char * name2 = rhs->city;
	while(name1[i] && name2[i]) {
		if(name1[i] < name2[i])
			return 0;
		else if(name1[i] > name2[i])
			return 1;
		else
			i += 1;
	}
	if(name2[i] == '\0' && name1[i] != '\0')
		return 1;
	else
		return 0;
}
#endif


/* create_node: creates a node given a line from the
 * database file.
 * Returns the created node if successful, otherwise 
 * returns NULL (because we want to be robust!)
 * Uses goto for pseudo-exception-handling. Sue me.
 */
Node * create_node(char * line, Node * p_next)
{
	char * ptr;
	int i;
	Node * tmp = malloc(sizeof(Node));
	if(tmp == NULL) goto error;

	ptr = strtok(line, ",\n");
	tmp->city = calloc(strlen(ptr), sizeof(char));
	if(tmp->city == NULL) goto error;
	strcpy(tmp->city, ptr);

	for(i = 0; i < NUM_KEYWORDS; i++) {
		ptr = strtok(NULL, ",\n");
		tmp->keywords[i] = calloc(strlen(ptr),
				sizeof(char));
		if(tmp->keywords[i] == NULL) goto error;
		strcpy(tmp->keywords[i], ptr);
	}
	tmp->next = p_next;

	return tmp;

error:
	perror("create_node: could not create node");
	return NULL;
}


/* populate_database: given a file name with the database
 * file name, populate the database.
 * Returns number of items added to the database.
 */
int populate_database(char * file)
{
	int items = 0;
	int i;
	char buf[LINE_SIZE];
	for(i = 0; i < NUM_BUCKETS; i++)
		db[i].next = NULL;

	FILE * fp = fopen(file, "r");
	if(fp == NULL) {
		perror("pop_db: could not open database file");
		exit(1);
	}

	// find index into database (based on city name),
	// then add the node to the front of the linked list
	while(fgets(buf, LINE_SIZE, fp) != NULL) {
		i = tolower(buf[0]) - 'a';
		Node * tmp = create_node(buf, db[i].next);
		if(tmp != NULL) {
			db[i].next = tmp;
			items += 1;
		}
	}

	fclose(fp);
	return items;
}


/* find_keywords: given a city name, find the keywords
 * associated with that city and store them in the location
 * pointed to by r_kws.
 * Returns 0 if the city was found, -1 otherwise.
 */
int find_keywords(char * name, char *** r_kws)
{
	if(name == NULL) return NULL;
	int index = tolower(name[0]) - 'a';
	Node * ptr = db[index].next;
	while(ptr != NULL) {
		if(!strcmp(name, ptr->city)) {
			*r_kws = ptr->keywords;
			return 0;
		} else {
			ptr = ptr->next;
		}
	}

	return -1;
}


/* print_bucket: prints the contents of a database given
 * an index (i.e. letter). This is mainly used for
 * debugging.
 */
void print_bucket(int bucket)
{
	if(bucket > NUM_BUCKETS) {
		bucket = tolower(bucket) - 'a';
		if(bucket > NUM_BUCKETS) return;
	}

	int i;
	Node * tmp = db[bucket].next;
	if(tmp == NULL) return;

	while(tmp != NULL) {
		printf("City: %s\nKeywords:\n", tmp->city);
		for(i = 0; i < NUM_KEYWORDS; i++) {
			printf("\t%s\n", tmp->keywords[i]);
		}

		tmp = tmp->next;
	}
	printf("\n");
}


/* destroy_database: frees the database.
 */
void destroy_database()
{
	int i;
	Node * tmp;
	for(i = 0; i < NUM_BUCKETS; i++) {
		tmp = db[i].next;
		while(tmp != NULL) {
			Node * tmp2 = tmp; 
			tmp = tmp->next;
			free(tmp2);
		}
	}
}


/* db_lookup: given a filename (from the queue), find the
 * city and handle the request. This does most of the
 * lookup work.
 * Returns 0 if successful, -1 if something bad happened
 */
int write_file(char * filename)
{
	FILE * fp = fopen(filename, "r");
	char buffer[LINE_SIZE];
	char ** keywords;
	char * outfile;
	int i;
	if(fp == NULL) {
		perror("write_file: could not open client file");
		return -1;
	}

	// get city name from client
	fgets(buffer, LINE_SIZE, fp);
	strtok(buffer, "\n"); // get rid of the newline
	fclose(fp);

	// find city in database, returning the keywords
	if(find_keywords(buffer, &keywords)) {
		fprintf(stderr, "write_file: lookup of \'%s\' failed\n", buffer);
		return -1;
	}
	
	// prepare output file name, open output file
	outfile = calloc(strlen(filename) + 8, sizeof(char));
	if(outfile == NULL) {
		perror("write_file: malloc failed");
		return -1;
	}
	strcpy(outfile, filename);
	strcat(outfile, ".result");

	fp = fopen(outfile, "w");
	if(fp == NULL) {
		fprintf(stderr, "write_file: could not open client file %s\n", outfile);
		free(outfile);
		return -1;
	}

	// write keywords to file
	fprintf(fp, "%s : ", buffer);
	for(i = 0; i < NUM_KEYWORDS - 1; i++) {
		fprintf(fp, "%s,", keywords[i]);
	}
	fprintf(fp, "%s\n", keywords[NUM_KEYWORDS - 1]);

	fclose(fp);
	free(outfile);
	return 0;
}
