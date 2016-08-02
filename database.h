#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define LINE_SIZE 100
#define NUM_KEYWORDS 3
#define NUM_BUCKETS 26

/* database.h: header for the database.
 * Each entry in the database contains the city and its
 * associated keywords. Entries are placed alphabetically
 * into buckets (all the cities starting with a certain
 * letter). Each bucket is a linked list.
 *
 * Populating the database takes O(n) time. If the number of
 * items in each bucket is relatively small, then finding an
 * item in a bucket is relatively small (i.e. nearly
 * constant). Thus, looking up a city's keywords takes
 * nearly O(1) time.
 */

typedef struct node {
	char * city;
	char * keywords[NUM_KEYWORDS];
	struct node * next;
} Node;


// int compare_nodes(Node * lhs, Node * rhs);
void print_bucket(int bucket);
Node * create_node(char * line, Node * p_next);
int populate_database(char * file);
void destroy_database();
int find_keywords(char * name, char *** r_kws);
int write_file(char * filename);


