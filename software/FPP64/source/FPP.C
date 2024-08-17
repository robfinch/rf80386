#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <ctype.h>
#include <string.h>
#include <malloc.h>
#include <time.h>
#include <dos.h>
#include <ht.h>
#include <direct.h>
#include <inttypes.h>

#define ALLOC
#include "fpp.h"

SDef rpt_stack[20];
rep_t rept_array[2000];
int rpt_sp = 0;
//SDef rep_stack[20];
char* cov_stack[20];
int rep_st;
int rep_nd;
SDef* rep_stack[2000];
int rep_inst = 0;


/* ---------------------------------------------------------------------------
   (C) 1992-2024 Robert T Finch

   fpp - PreProcessor for Assembler / Compiler
   This file contains processing for main and most of the directives.
--------------------------------------------------------------------------- */

void ShellSort(void *, int, int, int (*)());   // Does a shellsort - like bsort()
SHashVal HashFnc(void *def);
int icmp (const void *n1, const void *n2);

char* prpt;
int errors;
int InLineNo = 1;
char SourceName[250];
char OutputName[250];
char BaseSourceName[250];
char *SymSpace, *SymSpacePtr;
SHashTbl HashInfo = { HashFnc, icmp, 0, sizeof(SDef), NULL };
int MacroCount;
FILE *ofp;
int banner = 1;

// Storage for standard #defines

SDef
bbstdc = { "__STDC__", NULL, -1, 0, 0, 0, "<fpp>" },
   bbline = { "__LINE__", NULL, -1, 0, 0, 0, "<fpp>" },
   bbdate = { "__DATE__", NULL, -1, 0, 0, 0, "<fpp>" },
   bbfile = { "__FILE__", NULL, -1, 0, 0, 0, "<fpp>" },
  bbbasefile = { "__BASEFILE__", NULL, -1, 0, 0, 0, "<fpp>" },
  bbtime = { "__TIME__", NULL, -1, 0, 0, 0, "<fpp>" },
   bbpp   = { "__PP__", NULL, -1, 0, 0, 0, "<fpp>" };

void PrintDefines(void);

size_t SymSpaceLeft()
{
  return (STRAREA - (SymSpacePtr - SymSpace));
}

/*****************************************************************************
   Functions for parser (RR(0)).
*****************************************************************************/

SHashVal HashFnc(void *d)
{
   SDef *def = (SDef *)d;
   return htSymHash(&HashInfo, def->name);
}



/* ----------------------------------------------------------------------------
      Comparison routines.
---------------------------------------------------------------------------- */

int icmp (const void *m1, const void *m2)
{
    SDef *n1; SDef *n2;
    n1 = (SDef *)m1;
    n2 = (SDef *)m2;
	if (n1->name==NULL) return 1;
	if (n2->name==NULL) return -1;
  return (strcmp(n1->name, n2->name));
}

int fcmp(char *key, SDef *n2)
{
   printf("Key:%s, Entry:%s|\n", key, n2->name);
   return (strncmp(key, n2->name, strlen(n2->name)));
}

int ecmp(SDef *aa)
{
   return (aa->name ? 1 : 0);
}

buf_t* new_buf()
{
  buf_t* b;

  b = malloc(sizeof(buf_t));
  if (b == NULL)
    exit(0);
  b->pos = 0;
  b->size = 0;
  b->buf = NULL;
  return (b);
}

rep_t* new_rept()
{
  rep_t* p;

  if (rep_inst > 1999)
    exit(0);
  p = &rept_array[rep_inst];
  memset(p, 0, sizeof(rep_t));
  p->ino = rep_inst;
  p->def = new_def();
  rep_inst++;
  return (p);
}

SDef* new_def()
{
  SDef* p;

  p = malloc(sizeof(SDef));
  if (p == NULL)
    exit(0);
  memset(p, 0, sizeof(SDef));
  return (p);
}

/* ---------------------------------------------------------------------------
   Description :
      Define a macro.
---------------------------------------------------------------------------- */

void* ddefine(int opt)
{
  int c, n = 0;
  SDef *dp, *p;
  arg_t *parms[100];
  char *ptr, *st;
  int stndx;

  // Record the start position of the directive, the directive needs to be
  // overwritten in the output.
  for (st = inptr; *st != '#' && st > inbuf; st--)
    ;
  stndx = inptr - inbuf->buf;
  memset(parms, 0, 100 * sizeof(char*));
  dp = new_def();
  dp->nArgs = -1;          // no arguments or round brackets
  dp->line = InLineNo;     // line number macro defined on
  dp->file = bbfile.body->buf;  // file macro defined in
  SkipSpaces();
  ptr = GetIdentifier();
  if (ptr == NULL) {
    err(19);    // nothing to define
    return (NULL);
  }
  dp->name = _strdup(ptr);

  inptr = SearchAndSub(inbuf, inptr);

  // Check for macro parameters. There must be no space between the
  // macro name and ')'.
  if (opt == 1) {
    dp->varg = 0;
    dp->nArgs = GetMacroParmList(parms, opt);
    if (dp->nArgs < 0) {
      dp->nArgs = -dp->nArgs;
      dp->varg = 1;
    }
    c = PeekCh();
    while (c != '\n' && c > 0)
      c = NextCh();
    if (c < 0) {
      err(26);
      return (NULL);
    }
  }
  else if (PeekCh() == '(') {
    NextCh();
  dp->varg = 0;
  dp->nArgs = GetMacroParmList(parms, opt);
  if (dp->nArgs < 0) {
    dp->nArgs = -dp->nArgs;
    dp->varg = 1;
  }
    c = NextNonSpace(0);
    if (c != ')' && opt==0) {
        err(16);
        unNextCh();
    }
  }
  GetMacroBody(dp, 1, opt ? 2 : 0);
  dp->parms = malloc(sizeof(arg_t*) * dp->nArgs);
  if (dp->parms == NULL)
    exit(0);
  for (n = 0; n < dp->nArgs; n++)
    if (parms[n]) {
      dp->parms[n] = malloc(sizeof(arg_t));
      if (dp->parms[n])
        memcpy(dp->parms[n], parms[n], sizeof(arg_t));
    }
    else {
      dp->parms[n] = NULL;
    }

  // Do pasteing
  //DoPastes(ptr);

  // See if the macro is already defined. If it is then if the definition
  // is not the same spit out an error, otherwise spit out warning.
  p = (SDef *)htFind(&HashInfo, dp);
  if (p) {
		if (strcmp(p->body->buf, dp->body->buf))
			err(6, dp->name);
    //err((strcmp(p->body, dp.body) ? 6 : 23), dp.name);
    free(dp->name);
    return(NULL);
  }
  // Cover up the '.rept'
  st = inbuf->buf + stndx;
  memmove(st, inptr, strlen(inptr) + 1);
  inptr = st;

  ptr = dp->name;
  dp->name = StorePlainStr(ptr);
  free(ptr);
  dp->body->buf = StorePlainStr(dp->body->buf);
  htInsert(&HashInfo, dp);
  return ((void*) dp);
}

/* ---------------------------------------------------------------------------
   Description :
      Define a macro.
---------------------------------------------------------------------------- */

static void* dset(int opt)
{
  int c, n = 0;
  SDef *dp, * p;
  arg_t pary[100];
  arg_t* parms[100];
  char* ptr, * st;
  int need_cb = 0;
  int need_pl = 0;
  int got_sp = 0;
  char* nd;
  int stndx;

  dp = new_def();

  // Record the start position of the directive, the directive needs to be
  // overwritten in the output.
  for (st = inptr; *st != '.' && st > inbuf; st--)
    ;
  // Record the index into the buffer. The index is needed rather than a
  // pointer as the buffer address may change.
  stndx = inptr - inbuf->buf;
  memset(pary, 0, sizeof(pary));
  for (n = 0; n < 100; n++)
    parms[n] = &pary[n];
  dp->nArgs = -1;          // no arguments or round brackets
  dp->line = InLineNo;     // line number macro defined on
  dp->file = bbfile.body->buf;  // file macro defined in

  ptr = GetIdentifier();
  if (ptr == NULL) {
    err(19);    // nothing to define
    return (NULL);
  }
  dp->name = _strdup(ptr);

  inptr = SearchAndSub(inbuf, inptr);

  // Check for macro parameters. There must be no space between the
  // macro name and ')'.
  got_sp = SkipSpaces() > 0;
  if (PeekCh() == '(') {
    need_cb = 1;
    NextCh();
  }
  if (PeekCh() == ',') {
    need_pl = 0;
    got_sp = 0;
    NextCh();
  }
  dp->varg = 0;
  dp->nArgs = 0;
  dp->parms = 0;
  if (need_cb || got_sp) {
    dp->nArgs = GetMacroParmList(parms, opt);
    if (dp->nArgs < 0) {
      dp->nArgs = -dp->nArgs;
      dp->varg = 1;
    }
  }
  if (dp->nArgs > 0) {
    dp->parms = malloc(sizeof(arg_t*) * dp->nArgs);
    if (dp->parms == NULL)
      exit(0);
    for (n = 0; n < dp->nArgs; n++)
    {
      dp->parms[n] = malloc(sizeof(arg_t));
      if (dp->parms[n] == NULL)
        exit(0);
      memcpy(dp->parms[n], parms[n], sizeof(arg_t));
    }
  }

  c = NextNonSpace(0);
  if (need_cb && c != ')' && opt==0) {
    err(16);
    unNextCh();
  }
  if (c == ')') {
    c = NextCh();
    SkipSpaces();
    NextCh();
  }
  if (c == ',') {
    NextCh();
    SkipSpaces();
    NextCh();
  }
  unNextCh();
  GetMacroBody(dp, 0, 0);
  nd = inptr;

  // Do pasteing
  //DoPastes(ptr);

  // See if the macro is already defined. If it is then if the definition
  // is not the same spit out an error, otherwise spit out warning.
  p = (SDef*)htFind(&HashInfo, dp);
  if (p) {
    if (strcmp(p->body->buf, dp->body->buf))
      err(6, dp->name);
    //err((strcmp(p->body, dp.body) ? 6 : 23), dp.name);
    free_def(dp);
    return (NULL);
  }
  // Cover up the '.set'
  st = inbuf->buf + stndx;
  for (n = 0; st < nd; st++)
    *st = ' ';

  ptr = dp->name;
  dp->name = StorePlainStr(ptr);
  free(ptr);
  dp->body->buf = StorePlainStr(dp->body->buf);
  htInsert(&HashInfo, dp);
  return (dp);
}

/* ----------------------------------------------------------------------------
   Description :
      Cause preprocessor to stop and display a message on stderr.
---------------------------------------------------------------------------- */

void* derror(int opt)
{
  int c;

  inptr = SearchAndSub(inbuf, inptr);
  DoPastes(inbuf);
  SkipSpaces();
  do
  {
    c = NextCh();
    if (c > 0)
        fputc(c, stderr);
    if (c == '\n')
        break;
  } while (1);
//   exit(0);
  return (NULL);
}


/* ---------------------------------------------------------------------------
   Description :
      Include another file within the current one.
----------------------------------------------------------------------------- */

void* dinclude(int opt)
{
  char *tname;
  char *f;
  char path[250];
  char name[250];
  char wpath[250];
	char buf[260];
  int ch;
  SDef *p = NULL;

  memset(path, 0, sizeof(path));
  inptr = SearchAndSub(inbuf, inptr);
  DoPastes(inbuf);
  tname = bbfile.body->buf;
  name[0] = 0;

  ch = NextNonSpace(0);
  if (ch == '"')  // search the path specified
  {
    f = name;
    do
    {
        ch = NextCh();
        if (ch <= 1 || ch == '"' || ch == '\n')
          break;
        *f = ch;
        f++;
    } while(1);
    *f = 0;
    strcpy_s(path, sizeof(path), name);
    if (_access(path, 0) < 0) {
		_getcwd(wpath, sizeof(wpath) - 1);
          strcpy_s(path, sizeof(path), SourceName);
          f = strrchr(path,'\\');
          if (!f)
              f = strrchr(path, '/');
          if (f) {
              strcpy_s(f+1,sizeof(path-1),name);
          }
			// Can't find the file in the given path, try the include paths.
		  if (!f || _access(path, 0) < 0) {
				searchenv((char *)name, (char *)"FPPINC", (char *)path, sizeof(path));
				if (path[0] == '\0')
					searchenv((char *)name, (char *)"INCLUDE", (char *)path, sizeof(path));
				if (path[0] == '\0') {
					err(9, name);
					return (NULL);
				}
		  }
    }
  }
  else if (ch == '<')
  {
    f = name;
    do
    {
        ch = NextCh();
        if (ch <= 1 || ch == '>' || ch == '\n')
          break;
        *f = ch;
        f++;
    } while(1);
    *f = 0;
    searchenv((char *)name, (char *)"FPPINC", (char *)path, sizeof(path));
	if (path[0]=='\0')
	searchenv((char *)name, (char *)"INCLUDE", (char *)path, sizeof(path));
  }
  if (ch != '\n')
	  ScanPastEOL();

  if (path[0])
  {
		sprintf_s(buf, sizeof(buf), "%c%s%c", 0x22, path, 0x22);
  bbfile.body->buf = StorePlainStr(buf);
  p = (SDef *)htFind(&HashInfo, &bbfile);
  if (p)
      p->body->buf = bbfile.body->buf;
  ProcFile(bbfile.body->buf);
  bbfile.body = tname;
  p = (SDef *)htFind(&HashInfo, &bbfile);
  if (p)
      p->body->buf = bbfile.body->buf;
  }
  else
    err(9, name);
  return ((void*)p);
}

/* -----------------------------------------------------------------------------
   Description :
      Undefines a macro by removing its definition from the table.

----------------------------------------------------------------------------- */

void* dundef(int opt)
{
	SDef dp;

	dp.name = GetIdentifier();
	if (dp.name)
		htDelete(&HashInfo, &dp);
  return (NULL);
}


/* ----------------------------------------------------------------------------
   Description :
      Sets line number equal to line number specified and file name to
   name specified.
---------------------------------------------------------------------------- */

void* dline(int opt)
{
  char *ptr;
  char name[MAXLINE];
  SDef *p = NULL;

  inptr = SearchAndSub(inbuf, inptr);
  DoPastes(inbuf);
  InLineNo = atoi(inptr);
  sprintf_s(bbline.body, sizeof(bbline.body), "%5d", InLineNo-2);
  if ((ptr = strchr(inptr, '"')) != NULL)
  {
    inptr = ptr;
    memset(name, 0, sizeof(name));
    strncpy_s(name, sizeof(name), ptr, strcspn(ptr+1, " \t\n\r\x22"));
		strcat_s(name, sizeof(name), "\"");
    bbfile.body = StorePlainStr(name);
    p = (SDef *)htFind(&HashInfo, &bbfile);
    if (p)
      p->body = bbfile.body;
  }
  return ((void*)p);
}


/* ----------------------------------------------------------------------------
---------------------------------------------------------------------------- */

void* dpragma(int opt)
{
  inptr = SearchAndSub(inbuf, inptr);
  DoPastes(inbuf);
  return (NULL);
}

/* ----------------------------------------------------------------------------
---------------------------------------------------------------------------- */

void* dendm(int opt)
{
  return (NULL);
}

/* ----------------------------------------------------------------------------
---------------------------------------------------------------------------- */

/* ---------------------------------------------------------------------------
   Description :
      Define a repeat block.
---------------------------------------------------------------------------- */

void* drept_helper(rep_t* dr, int opt)
{
  int c, n = 0;
  SDef* dp1;
  arg_t pary[100];
  arg_t* parms[100];
  char* op, * qp, * st;
  int64_t stndx, qpndx;
  int count = 0;
  int ii;
  int ml, wd;
  static int rep_dep = 0;
  int ri;
  SDef* dp;

  if (dr == NULL)
    return (NULL);
  dp = dr->def;
  if (dp == NULL)
    return (NULL);

  dp->varg = 0;
  dp->nArgs = -1;          // no arguments or round brackets
  dp->line = InLineNo;     // line number macro defined on
  dp->file = bbfile.body;  // file macro defined in
  dp->name = NULL;

  // Record the start position of the directive, the directive needs to be
  // overwritten in the output.
//  for (st = inptr; *st != '.' && st > inbuf; st--)
//    ;
  memset(pary, 0, sizeof(pary));
  for (ii = 0; ii < 100; ii++)
    parms[ii] = &pary[ii];

  inptr = SearchAndSub(inbuf, inptr+5);

  // expeval() will eat a newline char
  dr->orcnt = dr->rcnt = expeval();
  st = inptr;
  if (dr->rcnt) {
    dp->inst = malloc(sizeof(SDef*) * dr->rcnt);
    if (dp->inst == NULL) {
      exit(0);
    }
    memset(dp->inst, 0, sizeof(SDef*) * dr->rcnt);
  }

  // Check for repeat parameters. There must be no space between the
  // macro name and ')'.
  SkipSpaces();
  c = PeekCh();
  if (c == ',') {
    NextCh();
    dp->varg = 0;
    dp->nArgs = GetReptArgList(parms, opt);
    if (dp->nArgs < 0) {
      dp->nArgs = -dp->nArgs;
      dp->varg = 1;
    }
    if (dp->nArgs) {
      dp->parms = malloc(sizeof(arg_t*) * dp->nArgs);
      if (dp->parms == NULL)
        exit(0);
      for (ii = 0; ii < dp->nArgs; ii++) {
        dp->parms[ii] = malloc(sizeof(arg_t));
        dp->parms[ii]->num = ii;
        dp->parms[ii]->name = NULL;
        dp->parms[ii]->def = _strdup(parms[ii]->def);
      }
    }
    ScanPastEOL();
  }
  c = PeekCh();
  /*
  while (c != '\n' && c > 0)
    c = NextCh();
  */
  if (c < 0) {
    err(26);
    return (NULL);
  }
  st = inptr;
  stndx = st - inbuf->buf;
  GetMacroBody(dp, 1, 1);
  /*
  memset(dp.parms, 0, sizeof(dp.parms));
  for (n = 0; n < dp.nArgs; n++)
    dp.parms[n] = parms[n];
  dp.body = ptr;
  */

  // Cover up the '.rept'
//  memmove(st, inptr, strlen(inptr) + 1);
  inptr = inbuf->buf + stndx;

  // Dump the repeat body to the input repeat count number of times.
  op = inptr;
  ri = rep_inst;
  for (ii = 0; ii < dr->rcnt && ii < 100; ii++) {

    dp1 = dp->inst[ii] = new_def();
    dp1->body = dp->body;
    dp1->abody = clone_buf(dp1->body);
    dp1->st = inptr;
    dp1->varg = dp->varg;
    dp1->file = dp->file;
    dp1->inst = NULL;
    dp1->line = dp->line;
    dp1->name = NULL;
    dp1->nArgs = dp->nArgs;
    dp1->parms = dp->parms;

    rep_stack[rep_inst] = dp1;
    qp = inptr;
    qpndx = qp - inbuf->buf;
    // Substitute args into macro body
    wd = SubParmMacro(dp1, 1);
    if (dp1->abody->buf)
      ml = strlen(dp1->abody->buf);
    else
      ml = 0;
    // Substitute macro into input stream.
//    if (rep_dep==1)
    inptr = inbuf->buf + qpndx + ml;
  }

  // Set the input point back to the start of the dump.
  inptr = op;
  return ((void*)dr);
}

static void free_def(SDef* dp)
{
  int ii, ix;
  return;

  /*
  for (ii = 0; ii < dp->orcnt; ii++) {
    for (ix = 0; ix < dp->incnt; ix++)
      if (dp->inner[ix]) {
        free_def(dp->inner[ix]);
        dp->inner[ix] = NULL;
      }
    if (dp->inst[ii]->abody) {
      free(dp->inst[ii]->abody);
      dp->inst[ii]->abody = NULL;
    }
    if (dp->inst[ii])
      free_def(dp->inst[ii]);
    dp->inst[ii] = NULL;
  }
  */
  if (dp->inst) {
    free(dp->inst);
    dp->inst = NULL;
  }
  if (dp->abody) {
    free(dp->abody);
    dp->abody = NULL;
  }
  if (dp->nArgs > 0) {
    for (ii = 0; ii < dp->nArgs; ii++) {
      if (dp->parms[ii]) {
        free(dp->parms[ii]);
        dp->parms[ii] = NULL;
      }
    }
    free(dp->parms);
    dp->parms = NULL;
  }
  free(dp);
}

void *drept(int opt)
{
  rep_t *dp;
  char* st, *nd;
  char buf[24];

  // Record the start position of the directive, the directive needs to be
  // overwritten in the output.
  for (st = inptr; *st != '.' && *st != 0 && st > inbuf; st--)
    ;
  // Find the end of the repeat declaration.
  for (nd = st; *nd != '\n' && *nd != 0; nd++)
    ;
  // Check for already processed rept.
  if (strncmp(st, ".rept[", 6) == 0)
    return (NULL);
  sprintf_s(buf, sizeof(buf), ".rept[%.5d]", rep_inst);
  memmove(st+12, st, inbuf->size - ((st+12) - inbuf->buf));
  memcpy_s(st, inbuf->size - ((st + 12) - inbuf->buf), buf, 12);
  inptr = st+12;
  dp = new_rept();
  drept_helper(dp, opt);
  SubMacro(dp->def, nd - st);
  return (NULL);
}

void* dendr(int opt)
{
  char* p1, * np;
  SDef* d1;
  int inst = -1;
  int xx;

  p1 = NULL;
  if (strncmp(inptr, ".endr[.minst]", 13) == 0) {
    p1 = inptr;
    for (xx = 0; p1[xx] != ']' && p1[xx]; xx++)
      p1[xx] = ' ';
    p1[xx] = ' ';
    return (NULL);
  }
  if (strncmp(inptr, ".endr[", 6) == 0) {
    inst = strtoul(inptr + 6, &np, 10);
    if (inst > 2000)
      return (NULL);
    p1 = inptr;
  }
  else if (strncmp(inptr, ".endr", 5) == 0) {
    p1 = inptr;
    for (xx = 0; xx < 5; xx++)
      p1[xx] = ' ';
    p1[xx] = ' ';
    return (NULL);
  }
  if (p1) {
//    d1 = rep_stack[inst];
//    if (0 && d1->rcnt < d1->orcnt) {
//      inptr = d1->st;
//      d1->rcnt += 1;
//      rep_stack[inst] = d1;
//    }
//    else
  {
//      d1->rcnt += 1;
//      rep_stack[inst] = d1;
      for (xx = 0; p1[xx] != ']' && p1[xx]; xx++)
        p1[xx] = ' ';
      p1[xx] = ' ';
//      inptr = &p1[xx];
    }
  }
  //ScanPastEOL();
  return (NULL);
}

/* -----------------------------------------------------------------------------
   Description :
      Looks at line and determines if it is a preprocessor directive. If it
   is then processing for the directive is executed.
      Macro substitutions are optionally performed on the line before
   processing the directive. Several directives such as else/endif can have
   nothing else on the line so we save time by not performing susbtitutions.

   Returns :
      TRUE if preprocessor directive, otherwise FALSE.

----------------------------------------------------------------------------- */

static int directive(int* isdef)
{
   int i;
   static SDirective dir[] =
   {
      1, "#define",  6, ddefine, 0, 0,
      0, "#error",   5, derror,  0, 0,
      0, "#include", 7, dinclude,0, 0,
      0, "#else",    4, delse,   0, 0,
      0, "#endif",   5, dendif,  0, 0,
      0, "#elif",    4, delif,   0, 0,
      0, "#ifdef",   5, difdef,  0, 0,
      0, "#ifndef",  6, difndef, 0, 0,
      0, "#if",      2, dif,     0, 0,// must come after ifdef/ifndef
      0, "#undef",   5, dundef,  0, 0,
      0, "#line",    4, dline,   0, 0,
      0, "#pragma",  6, dpragma, 0, 0,
      1, ".set",    4, dset,    1, 1,
      1, ".equ",    4, dset,    1, 1,
      0, ".include",8, dinclude, 1, 0,
      0, ".else", 5, delse, 1, 0,
      0, ".endif", 6, dendif, 1, 0,
      0, ".ifdef",   6, difdef,  0, 0,
      0, ".ifndef",  7, difndef, 0, 0,
//      ".elif", 5, delif, 1, 0,
      0, ".if", 3, dif, 1, 0,
      0, ".ifne", 5, dif, 1, 0,
      0, ".ifeq", 5, dif, 1, 1,
      0, ".ifgt", 5, dif, 1, 2,
      0, ".ifge", 5, dif, 1, 3,
      0, ".iflt", 5, dif, 1, 4,
      0, ".ifle", 5, dif, 1, 5,
      0, ".ifb", 4, dif, 1, 6,
      0, ".ifnb", 5, dif, 1, 7,
      1, ".macro",  6, ddefine, 1, 1,
      0, ".endm", 5, dendm, 1, 0,
      2, ".rept",  5, drept, 1, 1,
      3, ".endr", 5, dendr, 1, 0
   };

   *isdef = 0;
   // Skip any whitespace following '#'
   prpt = inptr - 1;
   NextNonSpace(0);
   unNextCh();
   for(i = 0; i < sizeof(dir)/sizeof(SDirective); i++)
   {
      if (!strncmp(inptr, &dir[i].name[1], dir[i].len-1) && 
        dir[i].syntax == syntax &&
        syntax ? *prpt=='.' : *prpt=='#')
      {
        if (dir[i].isdef != 3)
          inptr += dir[i].len;
        else
          inptr--;
         (*dir[i].func)(dir[i].opt);
		 // Including this causes #define to fail because it already
		 // scans to the end of the line
		 //ScanPastEOL();
         //for (; *inptr != 0; inptr++); // skip to eol
         *isdef = dir[i].isdef;
         return (1);
      }
   }
//   err(28);   // Bad directive
   ScanPastEOL();
   return (0);
}

static int pl_line_testdir(char ch, char** ptr)
{
  int dir = 0;
  int def = 0;
  int ret = 0;

  *ptr = NULL;
  if ((syntax ? ch == '.' : ch == '#') && in_comment == 0) {
    if (ShowLines)
      fprintf(stdout, "#line %5d\n", InLineNo);
    ret = directive(&dir);
    if (ret && dir == 3) {  // .endr?
//      ScanPastEOL();
      return (1);
    }
    def = dir == 1 || dir == 2;
    if (def)
      *ptr = inptr;
    return (ret);
  }
  return (0);
}

static int pl_line_text()
{
  char* ptr2;
  char* ptr3;

  unNextCh();
  ptr2 = SkipComments();
  inptr = ptr2;
  if (fdbg) fprintf(fdbg, "bef sub  :%s", ptr2);
  inptr = SearchAndSub(inbuf, inptr);
  if (fdbg) fprintf(fdbg, "aft sub  :%s", ptr2);
  DoPastes(ptr2);
  // write out the current input buffer
  if (fdbg) fprintf(fdbg, "aft paste:%s", ptr2);
  // Insert a line terminator
  ptr3 = NULL;
  ptr3 = strchr(ptr2, '\n');
  if (ptr3 != NULL)
    *ptr3 = 0;
  /*
  if (dir == 2 && 0) {
    ptr3 = strrchr(ptr2, '\n');
    if (ptr3) {
      while (ptr3[-1] == '\n' || ptr3[-1] == '\r') ptr3--;
      *ptr3 = 0;
    }
  }
  */
  // Skip leading line feeds.
  do ptr2++; while (ptr2[0] == '\n' || ptr2[0] == '\r');
  ptr2--;
  if (fputs(ptr2, ofp) == EOF)
  printf("fputs failed.\n");
  fputs("\n", ofp);
  // Restore the line feed.
  // advance the input
  if (ptr3) {
    *ptr3 = '\n';
    inptr = ptr3 + 1;
  }
  /*
  if (ptr3) {
    *ptr3 = ' ';
    memmove(lp, ptr3 + 1, inbufsz - (ptr3 - inbuf + 1));
    //         strcat_s(lp, inbufsz - (lp - inbuf), " ");
    inptr = lp;
    while (PeekCh() == '\n' || PeekCh() == '\r') ch = NextCh();
    if (ch == 0)
      return (0);
    memmove(lp, inptr, strlen(inptr) + 1);
    inptr = lp;
    prpt = lp;
    break;
  }
  */
}

/* -----------------------------------------------------------------------------
   Description :
      Process files. Loops reading lines from input, performing macro
   substitutions and processing preprocessor commands. Macro substitution
   is done first to allow a macro to be defined in terms of another macro.

----------------------------------------------------------------------------- */

int ProcLine()
{
   int ch;
   int def = 0;
   char* ptr, *ptr2;
   int dir = 0;
   char* lp;

  // Substitions can create additional lines in the input. Loop processing
  // all lines from the input.
   //printf("Processing line: %d\r", InLineNo);
  lp = inptr;
  //inptr = inbuf;
  ptr = inptr;
  ptr2 = inptr;
  while (1) {
    //   ch = NextCh();          // get first character
    inptr = SkipComments();
    ch = NextNonSpace(0);
    dir = pl_line_testdir(ch, &ptr);
    if (!dir)
      pl_line_text();
    lasttk = 0;
    InLineNo++;          // Update line number (including __LINE__).
    sprintf_s(bbline.body, sizeof(bbline.body), "%5d", InLineNo-1);
    if (*inptr == 0)
      break;
  }
  return (0);
}

/* -----------------------------------------------------------------------------
   Description :
      Process files. Loops reading lines from input, performing macro
   substitutions and processing preprocessor commands. Macro substitution
   is done first to allow a macro to be defined in terms of another macro.

----------------------------------------------------------------------------- */

void ProcFile(char *fname)
{
   FILE *fp;
	 char buf[500];
   char* p;

	 // Strip leading/trailing quotes from filename.
	 if (fname[0] == '"')
		 strcpy_s(buf, sizeof(buf), fname + 1);
	 else
		 strcpy_s(buf, sizeof(buf), fname);
	 if (buf[strlen(buf) - 1] == '"')
		 buf[strlen(buf) - 1] = '\0';

	 if((fopen_s(&fp, buf,"r")) != NULL) {
      err(9, buf);
      return;
   }

   rep_st = 0;
   rep_nd = 0;
  fin = fp;
  NextCh();
  unNextCh();
  while(!feof(fp)) {
    p = inptr;
    ProcLine();
    fin = fp;
    // If nothing was processed on the line, must be done, or an error.
    if (inptr == p) {
      break;
    }
  }
  fclose(fp);
}

/* ----------------------------------------------------------------------------
   Description:
 	   Parse command line switches.
---------------------------------------------------------------------------- */

void parsesw(char *s)
{
   SDef tdef;
   char buf[MAXLINE];
   char buf2[500];
   int ii, jj;

   switch(s[1])
   {
   case 'd':
	   debug = 1;
	   break;
   case 'b':
	   banner = 0;
	   break;

    case 'D':
        strcpy_s(buf2, sizeof(buf2), &s[2]);
        for(ii = 0; buf2[ii] && IsIdentChar(buf2[ii]); ii++)
          buf[ii] = buf2[ii];
        buf[ii] = 0;
        if (buf[0]) {
          tdef.nArgs = -1;
          tdef.name = StorePlainStr(buf);
          if (buf2[ii++] == '=') {
              for(jj = 0; buf2[ii];)
                buf[jj++] = buf2[ii++];
              buf[jj] = 0;
              tdef.body = (char *)(buf[0] ? StorePlainStr(buf) : "");
          }
          else
              tdef.body = "";
          tdef.line = 0;
          tdef.file = "<cmd line>";
          htInsert(&HashInfo, &tdef);
        }
        break;

    case 'V':
        verbose = 1;
        break;

    case 'L':
        ShowLines = 1;
        break;

    case 'S':
      if (strncmp(&s[2], "astd", 4) == 0) {
        syntax = 1;
        break;
      }
   }
}


/* -----------------------------------------------------------------------------
   Description :
      Prints a table of macros defined.
----------------------------------------------------------------------------- */

void PrintDefines()
{
   int ii, count, blnk;
   SDef *dp, *pt;
   char buf[8];

   pt = (SDef *)HashInfo.table;

   // Pack any 'holes' in the table
   for(blnk= ii = count = 0; count < HashInfo.size; count++, ii++) {
      dp = &pt[ii];
      if (dp->name) {
         if (blnk > 0)
            memmove(&pt[ii-blnk], &pt[ii], (HashInfo.size - count) * sizeof(SDef));
         ii -= blnk;
         blnk = 0;
      }
      else
         blnk++;
   }

   // Sort the table
   qsort(pt, ii, sizeof(SDef), icmp);

   printf("\n\nMacro Table:\n");
   printf("Name         Args Body                                     Line  File\n");
   for (MacroCount = 0; --ii >= 0;) {
      dp = &pt[MacroCount];
      if (dp->name) {
         MacroCount++;
         if (dp->nArgs >= 0)
            sprintf_s(buf, sizeof(buf), " %2d ", dp->nArgs);
         else 
            sprintf_s(buf, sizeof(buf), " -- ");
         printf("%-12.12s %4.4s %-40.40s %5d %-12.12s\n", dp->name, buf, dp->body, dp->line, dp->file);
      }
   }
   getchar();
}

void FreeDefines()
{
  int ii, jj;
  SDef* dp, * pt;
  arg_t *arg;

  pt = (SDef*)HashInfo.table;

  // Pack any 'holes' in the table
  for (ii = 0; ii < HashInfo.size; ii++) {
    dp = &pt[ii];
    if (dp) {
      if (dp->parms) {
        for (jj = 0; jj < dp->nArgs; jj++) {
          arg = dp->parms[jj];
          if (arg->def)
            free(arg->def);
          if (arg->name)
            free(arg->name);
          free(arg);
        }
      }
    }
  }
}

/* -----------------------------------------------------------------------------
   Description :
      Stores a string.

   Returns :
      (char *) pointer to area where string is stored.

----------------------------------------------------------------------------- */

char *StoreStr(char *body, ...)
{
   char *ptr;
   va_list argptr;

   if (strlen(body) > SymSpaceLeft() - 2000) {
      err(5);
      exit(3);
   }
   ptr = SymSpacePtr;
   va_start(argptr, body);
   SymSpacePtr += vsprintf_s(SymSpacePtr, SymSpaceLeft()-1, body, argptr) + 1;
   va_end(argptr);
   return (ptr);
}


/* -----------------------------------------------------------------------------
   Description :
      Stores actual string without calling vsprintf().

   Returns :
      (char *) pointer to area where string is stored.

----------------------------------------------------------------------------- */

char *StorePlainStr(char *str)
{
   char *ptr = SymSpacePtr;

   if (strlen(str) > SymSpaceLeft() - 2000) {
      err(5);
      exit(3);
   }
   strcpy_s(SymSpacePtr, SymSpaceLeft()-1, str);
   SymSpacePtr += strlen(str) + 1;
   return (ptr);
}


/* -----------------------------------------------------------------------------
   Description :
      Creates predefined preprocessor symbols __LINE__, __FILE__, __DATE__,
   __TIME__

----------------------------------------------------------------------------- */

void SetStandardDefines(void)
{
   time_t ltm;
   struct tm LocalTime;
	 char buf[260];

   time(&ltm);
   localtime_s(&LocalTime, &ltm);
   bbstdc.body = new_buf();
   bbline.body = new_buf();
   bbfile.body = new_buf();
   bbbasefile.body = new_buf();
   bbdate.body = new_buf();
   bbtime.body = new_buf();
   bbpp.body = new_buf();
   bbstdc.body->buf = StoreStr("1");
   bbline.body->buf = StoreStr("%5d", 1);
	 sprintf_s(buf, sizeof(buf), "%c%s%c", 0x22, SourceName, 0x22);
   bbfile.body->buf = StoreStr(buf);
   sprintf_s(buf, sizeof(buf), "%s", BaseSourceName);
   bbbasefile.body->buf = StoreStr(buf);
   bbdate.body->buf = StoreStr("%02d/%02d/%02d", LocalTime.tm_year, LocalTime.tm_mon+1, LocalTime.tm_mday);
   bbtime.body->buf = StoreStr("%02d:%02d:%02d", LocalTime.tm_hour, LocalTime.tm_min, LocalTime.tm_sec);
   bbpp.body->buf = StoreStr("fpp");

   htInsert(&HashInfo, &bbstdc);
   htInsert(&HashInfo, &bbline);
   htInsert(&HashInfo, &bbfile);
   htInsert(&HashInfo, &bbbasefile);
   htInsert(&HashInfo, &bbtime);
   htInsert(&HashInfo, &bbdate);
   htInsert(&HashInfo, &bbpp);
}


/* ----------------------------------------------------------------------------
   Description :
---------------------------------------------------------------------------- */

main(int argc, char *argv[]) {
   int
      xx;
   SDef *p;
	 char buf[260];
   char* p1;
   
   minst = 0;
   HashInfo.size = MAXMACROS;
   HashInfo.width = sizeof(SDef);
   if (argc < 2)
   {
		fprintf(stderr, "FPP version 3.00  (C) 1998-2024 Robert T Finch  \n");
		fprintf(stderr, "\nfpp64 [options] <filename> [<output filename>]\n\n");
		fprintf(stderr, "Options:\n");
		fprintf(stderr, "/D<macro name>[=<definition>] - define a macro\n");
		fprintf(stderr, "/L                            - output #lines\n");
		fprintf(stderr, "/V                            - verbose, outputs macro table\n");
    fprintf(stderr, "/S<syntax>                    - syntax to use\n");
    fprintf(stderr, "   Supported Syntax\n");
    fprintf(stderr, "   cstd - C standard\n");
    fprintf(stderr, "   astd - Assembler standard\n\n");
    exit(0);
   }
   /* ----------------------------------------------
         Allocate storage for macro information.
   ---------------------------------------------  */
   if ((HashInfo.table = calloc(HashInfo.size, sizeof(SDef))) == NULL) {
      err(5);
      return (1);
   }
   if ((SymSpace = (char *)calloc(1, STRAREA)) == NULL) {
      free(HashInfo.table);
      err(5);
      return(2);
   }
   SymSpacePtr = SymSpace;
   bbfile.body = StorePlainStr("<cmdln>");
   for(xx = 1; strchr("-/+", argv[xx][0]) && (xx < argc); xx++)
      parsesw(argv[xx]);

	if (banner)
		fprintf(stderr, "FPP version 3.00  (C) 1998-2024 Robert T Finch  \n");

   /* ---------------------------
         Get source file name.
   --------------------------- */
   if(xx >= argc) {
      fprintf(stderr, "\nSource filename[.c]: ");
      fgets(SourceName, sizeof(SourceName)-3, stdin);
   }
   else {
      strncpy_s(SourceName, sizeof(SourceName), argv[xx], sizeof(SourceName)-3);
      xx++;
   }
   /* -----------------------------------------------------
          Check for extension and add one if neccessary.
   ----------------------------------------------------- */
   if (!strchr(SourceName, '.'))
      strcat_s(SourceName, sizeof(SourceName)-1, ".c");

   OutputName[0] = '\0';
   if (xx < argc) {
      strncpy_s(OutputName, sizeof(OutputName), argv[xx], sizeof(OutputName));
      if (!strchr(OutputName, '.'))
         strcat_s(OutputName, sizeof(OutputName)-1,".pp");
   }
   strncpy_s(BaseSourceName, sizeof(BaseSourceName), OutputName, sizeof(OutputName));
   p1 = strrchr(BaseSourceName, '.');
   if (p1)
    p1[0] = '\0';

   /* ------------------------------
         Define standard defines.
   ------------------------------ */
   SetStandardDefines();
   /* -----------------------
         Process file. 
   ----------------------- */
   if (debug)
	   fopen_s(&fdbg, "fpp_debug_log","w");
   else
	   fdbg = NULL;
   if (OutputName[0]) {
      if (fopen_s(&ofp, OutputName, "w") != 0)
      if (ofp == NULL) {
         err(9, OutputName);
         exit(0);
      }
   }
   else
      ofp = stdout;
   errors = warnings = 0;
	 sprintf_s(buf, sizeof(buf), "%c%s%c", 0x22, SourceName, 0x22);
	 bbfile.body = StorePlainStr(buf);
   p = (SDef *)htFind(&HashInfo, &bbfile);
   if (p)
      p->body = bbfile.body;
   ProcFile(SourceName);
   if (ofp != stdout) {
	   fflush(ofp);
      fclose(ofp);
   }
   if (fdbg)
	   fclose(fdbg);

   if(errors > 0)
      fprintf(stderr, "\nPreProcessor Errors: %d\n",errors);
   if(warnings > 0)
      fprintf(stderr, "\nPreProcessor Warnings: %d\n",warnings);
   if (verbose) {
      PrintDefines();
      printf("\n%d/%d macros\n", MacroCount, MAXMACROS);
      printf("%u/%u macro space used\n", SymSpacePtr - SymSpace, STRAREA);
   }
   if (SymSpace)
      free(SymSpace);
   if (HashInfo.table) {
     FreeDefines();
     free(HashInfo.table);
   }
   //getchar();
   exit(0);
}
