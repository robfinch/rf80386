#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
#include <string.h>
#include <ctype.h>
#include "fpp.h"

char *SkipComments()
{
	if (in_comment == 0)
		return (inptr);
	do {
		if (in_comment == 1 && inptr[0] == '\n') {
			in_comment = 0;
			return (&inptr[1]);
		}
		if (in_comment==2 && inptr[0] == '*' && inptr[1] == '/' && syntax==0) {
			in_comment = 0;
			return (&inptr[2]);
		}
		inptr++;
	} while (in_comment != 0);
	inptr--;
	return (inptr);
}

// Gets characters from the input stream. Single character pushback.
int NextCh()
{
	unsigned int ch = ' ';
	static int first = 1;
	char* p;

	if (first) {
		inbuf = new_buf();
		inptr = NULL;
		ch = ' ';
	}
	do {
			if (first || inptr - inbuf->buf > inbuf->size - 10) {
				inbuf->size += 4096;
				p = malloc(inbuf->size);
				if (p == NULL) {
					exit(0);
				}
				if (!first)
					memcpy(p, inbuf->buf, inbuf->size - 4096);
				memset(p + inbuf->size - 4096, 0, 4096);
				if (first)
					inptr = p;
				else
					inptr = p + (inptr - inbuf->buf);
				if (inbuf->buf)
					free(inbuf->buf);
				inbuf->buf = p;
			}
			if (*inptr == 0) {
				if (feof(fin))
					return (0);
				fgets(inptr, MAXLINE, fin);
				/*
				if (inptr > inbuf->buf && inptr[-1] != '\n' && inptr[-1] != '\r') {
					memmove(inptr + 1, inptr, inbuf->size - (inptr - inbuf->buf + 1));
					*inptr = '\n';
				}
				*/
				if (fdbg) fprintf(fdbg, "Fetched:%s", inptr);
			}
			first = 0;
			/*
			else
			{
				inptr = inbuf;
				memset(inbuf, 0, sizeof(inbuf));
				fgets(inbuf, MAXLINE, fin);
				if (fdbg) fprintf(fdbg, "Fetched:%s", inbuf);
				inptr = inbuf;
			}
			*/
		ch = *inptr++;

		if (syntax == 00) {
			if (in_comment == 0 && ch == '/' && inptr[0] == '/') {
				in_comment = 1;
				inptr += 1;
			}
			if (in_comment == 1 && (ch == '\n' || ch == '\r'))
				in_comment = 0;
			if (in_comment == 0 && ch == '/' && inptr[0] == '*') {
				in_comment = 2;
				inptr++;
			}
			if (in_comment == 2 && ch == '*' && inptr[0] == '/') {
				ch = inptr[1];
				inptr += 2;
				in_comment = 0;
			}
		}
		if (syntax == 1) {
			if (in_comment == 0 && ch == '#') {
				in_comment = 1;
			}
			if (in_comment == 1 && (ch == '\n' || ch == '\r'))
				in_comment = 0;
		}
	} while (ch && in_comment != 0 && inptr - inbuf->buf < 3000000);
	return (ch & 0xff);
}

// Put characters back into input buffer.
void unNextCh()
{
	if (inptr > inbuf->buf) {
      inptr--;
	  CharCount--;
	}
}

// Skips spaces in input
int SkipSpaces()
{
   int c;
	 char* p1 = inptr;

   do {
      c = NextCh();
   } while(c != '\n' && isspace(c) && c != 0);
   unNextCh();
	 return (inptr - p1);
}

// Gets the next non space character
int NextNonSpace(int skipnl)
{
   int ch;

   do {
      ch = NextCh();
   } while((ch != '\n' || skipnl) && isspace(ch) && ch!=0);
   return (ch);
}

void ScanPastEOL()
{
	int ch;

	do {
		ch = NextCh();
	} while (ch != '\n' && ch != 0);
}

