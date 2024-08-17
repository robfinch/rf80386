/* ---------------------------------------------------------------------------
   
   (C) 1992 FinchWare

   fpp.h

   Description :   Header file for cpp.

   Changes
           Author      : R. Finch
           Date        : /90
           Release     :
           Description : new module

--------------------------------------------------------------------------- */

#ifndef HT_H
#  include <ht.h>
#endif

#ifdef ALLOC
#  define E
#  define I(x) x
#else
#  define E extern
#  define I(x)
#endif

#define IsIdentChar(ch)       strchr(identchars, (ch))
#define IsFirstIdentChar(ch)  (isalpha((ch)) || (ch) == '_')
#define PeekCh()              (*inptr)

#define FALSE     0
#define TRUE      1
#define MAXLINE   4000
#define STRAREA   640000
#define MAXMACROS 4001
#define MAX_MACRO_ARGS  100

#define DIGITS "0123456789abcdefghijklmnopqrstuvwxyz"

typedef struct
{
  int num;        // parameter number
  char* name;     // parameter name
  char* def;      // default value
} arg_t;

typedef struct
{
  int size;
  int pos;
  char* buf;
} buf_t;

typedef struct _tagSDef
{
   char *name;    // name of the macro
   buf_t *body;    // test to substitute when macro name is encountered
   int nArgs;     // Number of arguments passed to this macro
   arg_t** parms;
   int varg;      // variable argument list indicator
   int line;      // line number macro is defined on
   char *file;    // file macro is defined in
   char *st;		// start of definiton
   char *nd;		// end of definition
   struct _tagSDef** inst;
   struct _tagSDef* inner[100];
   int sndx;
   int incnt;
   buf_t* abody;
} SDef;

typedef struct _tagRep_t
{
  int ino;      // repeat instance number
  SDef* def;    // associated def
  int rcnt;      // repeat count (.rept)
  int orcnt;
  char* st;
  char* nd;
} rep_t;

typedef struct
{
  int isdef;
  char *name;
  int len;
  void* (*func)(int o);
  int syntax;
  int opt;
}  SDirective;

size_t SymSpaceLeft();
int ProcLine();
void ProcFile(char *);

int icmp(const void *, const void *);
int fcmp(char *, SDef *);
int ecmp(SDef *);
char *StoreBody(char *,...);
char *StorePlainStr(char *);
char *StoreStr(char *, ...);



void err(int, ...);
long expeval(void);
void insert_into_buf(buf_t* buf, char* p, int pos);

buf_t* new_buf();
SDef* new_def();
rep_t* new_rept();
buf_t* clone_buf(buf_t*);
void free_def(SDef*);
void repskip();
int ProcLine(void);
int NextCh(void);
int NextNonSpace(int);
int SkipSpaces(void);
void unNextCh(void);
char *GetIdentifier(void);
void ScanPastEOL();

char *GetMacroBody(SDef*, int opt, int rpt);
char *GetMacroArg(void);
int GetMacroParmList(arg_t *[], int opt);
void SubMacro(SDef *, int);
char *SubMacroArg(char *, int, char *);
int GetReptArgList(arg_t* [], int opt);

int SubParmMacro(SDef* p, int opt);
char* SearchAndSub(buf_t*, char *);
void SearchForDefined(void);
void DoPastes(char *);

void* drept_helper(SDef* dp, int opt);

void* ddefine(int);
void* derror(int);
void* dinclude(int);
void* delse(int);
void* delif(int);
void* dendif(int);
void* difdef(int);
void* difndef(int);
void* dif(int);
void* dundef(int);
void* dline(int);
void* dpragma(int);
void* drept(int);
void* dendr(int);

void searchenv(char *filename, char *envname, char *pathname, int pathsize);

SHashVal HashFnc(SDef *);

E char *identchars I(= "_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ@?0123456789");
extern SHashTbl HashInfo;
E char *inptr;       // pointer to current character in input buffer
E buf_t *inbuf;  // input buffer
extern int errors;
E int warnings;
E FILE *fin, *fout;
E FILE *fdbg;
E int verbose I(=0);
E int ShowLines I(=0);
E int CharCount I(=0);
E char *cmdStart I(=0);
E char *cmdEnd I(=0);
E int collect I(=0);
E int debug I(=0);
E int lasttk I(= 0);
E int in_comment I(= 0);
E int minst I(= 0);
E int syntax I(= 0);
extern int rep_inst;
extern rep_t rept_array[2000];

extern char *SkipComments();
