CC=gcc
CFLAGS=-Wall
CDEBUG=-Wall -g

all: client.c database.c main.c
	$(CC) $(CDEBUG) -lpthread client.c database.c main.c -o twitterTrend

clean: twitterTrend
	rm twitterTrend

test_database: database.c testb_database.c
	$(CC) $(CFLAGS) database.c testb_database.c -o dbtest

clean_dbtest: dbtest
	rm dbtest
