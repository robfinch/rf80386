#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <inttypes.h>
#include "fpp.h"

//#include "fwstr.h"

char *rtrim(char *str);

/* ---------------------------------------------------------------------------
   char *SubArg(bdy, n, sub);
   char *bdy;  - pointer to macro body
   int n;      - parameter number to substitute
   char *sub;  - substitution string

      Searches the macro body a substitutes the passed parameter for the
   placeholders in the macro body.
--------------------------------------------------------------------------- */

char *SubMacroArg(char *bdy, int n, char *sub)
{
	static char buf[160000];
	char *s = sub, *o = buf;
	int stringize = 0;

   memset(buf, 0, sizeof(buf));
   for (o = buf; *bdy; bdy++, o++)
   {
		 stringize = 0;
      if (*bdy == '' && bdy[1] == (char)n + '0') {  // we have found parameter to sub
				if (bdy[-1] == '#') {
					stringize = 1;
					o[-1] = '\x15';
				}
         // Copy substitution to output buffer
				for (s = sub; *s;) {
					if (stringize) {
						if (*s=='"')
							*o++ = '\\';
					}
					*o++ = *s++;
				}
				if (stringize)
					*o++ = '\x15';
         --o;
         bdy++;
         continue;
      }
      else if (*bdy == '' && bdy[1] == '@') {
        bdy++;
        sprintf_s(o, o-buf-1, "%d", minst);
        continue;
      }
      *o = *bdy;
   }
   return buf;
}


/* ---------------------------------------------------------------------------
   Description :
      Gets the body of a macro. All macro bodies must be < 2k in size. Macro
   parameters are matched up with their positions in the macro. A $<number>
   (as in $1, $2, etc) is substituted in the macro body in place of the
   parameter name (we don't actually care what the parameter name is).
      Macros continued on the next line with '\' are also processed. The
   newline is removed from the macro.
---------------------------------------------------------------------------- */
  
static void proc_instvar(buf_t *buf)
{
  char mk[3];

  inptr += 2;
  mk[0] = '';
  mk[1] = '@';
  mk[2] = 0;
  insert_into_buf(buf, mk, 0);
}

static int proc_parm(buf_t* buf, int nparm)
{
  char c;
  char* p1, * p2;
  char mk[3];

  p1 = inptr;
  c = NextCh();
  if (isdigit(p1[1])) {
    while (isdigit(c = NextCh()));
    c = (char)strtoul(&p1[1], &inptr, 10);
    if (c <= nparm) {
      p1++;
      p2 = inptr;
      mk[0] = '';
      mk[1] = '0' + c;
      mk[2] = 0;
      insert_into_buf(buf, mk, 0);
      return (1);
    }
  }
  return (0);
}

// Process a repeat directive.
// A marker for the repeat is placed in the repeat text buffer. The marker
// records which instance of a repeat is in use.

static void proc_rept(rep_t* rpt, buf_t* buf, int is_multiline)
{
  char buff[24];
  int ln;
  rep_t* sd, *pd;

  pd = new_rept();
  inptr += 5;
  sd = drept_helper(pd, is_multiline);
  ln = sprintf_s(buff, sizeof(buff), ".rept[%.5d]", pd->ino);
  insert_into_buf(buf, buff, 0);
}

/*
static int proc_arg(char **b, int* count, char** p1, char **p2, int nparm, char **id)
{
  char c;

  if (id == NULL)
    return;

  *p1 = NULL;
  *p2 = NULL;
  *id = NULL;
  if (PeekCh() == '\\') {
    *p1 = inptr;
    c = NextCh();
    if (isdigit(c)) {
      while (isdigit(c = NextCh()));
      c = strtoul(&p1[1], inptr, 10);
      if (c < nparm) {
        *p1++;
        *p2 = inptr;
        **b = '';
        *b++;
        *count--;
        if (count < 0)
          goto jmp1;
        *b = '0' + (char)ii;
      }
    }
    else {
      *id = GetIdentifier();
      *p2 = inptr;
    }
  }
}
*/

static int sub_id(SDef* def, char* id, buf_t *buf, char* p1, char* p2)
{
  int ii;
  char mk[3];
  char idbuf[500];

  for (ii = 0; ii < def->nArgs; ii++)
    if (def->parms[ii]->name)
      if (strcmp(def->parms[ii]->name, id) == 0) {
        mk[0] = '';
        mk[1] = '0' + (char)ii;
        mk[2] = 0;
        insert_into_buf(buf, mk, 0);
        return (1);
      }
  // if the identifier was not a parameter then just copy it to
  // the macro body
  if (p2 - p1 > sizeof(id))
    exit(0);
  strncpy_s(idbuf, sizeof(idbuf), p1, p2 - p1);
  id[p2 - p1] = 0;
  insert_into_buf(buf, idbuf, 0);
  return (0);
}

// Returns
//  1 = continue
//  2 = jmp1
//  3 = break

static int proc_literal(int* InQuote, buf_t* buf, int is_multiline)
{
  char c;
  char ch[3];

  c = NextCh();
  if (c < 1)
    return (1);
  if (c == '"') {
    *InQuote = !*InQuote;
    if (*InQuote) {
      c = NextCh();
    }
    else
      c = NextCh();
  }
  if (!*InQuote) {
    if (syntax == 1) {
      if (c == '#') {
        while (c != '\n' && c > 0) c = NextCh();
        return (c < 1);
      }
    }
    if (syntax == 0) {
      if (c == '/') {
        c = NextCh();
        // Block comment ?
        if (c == '*') {
          while (c > 0) {
            c = NextCh();
            if (c == '*') {
              c = NextCh();
              if (c == '/')
                break;
              unNextCh();
            }
          }
          if (c > 0) {
            return(0);
          }
          else {
            err(24);
            return(1);
          }
        }
        // Comment to EOL ?
        else if (c == '/') {
          while (c != '\n' && c > 0) c = NextCh();
          if (c > 0) {
            return (0);
          }
          return (1);
        }
        else {
          c = '/';
          unNextCh();
        }
      }
    }
    if (c == '\\')  // check for continuation onto next line
    {
      while (c != '\n' && c > 0) c = NextCh();
      if (c > 0) {
        SkipSpaces();  // Skip leading spaces on next line
        return(0);
      }
    }
    if (is_multiline == 1 && c == '\n') {
      ch[0] = c;
      ch[1] = 0;
      insert_into_buf(buf, ch, 0);
      SkipSpaces();  // Skip leading spaces on next line
      return(0);
    }
  }
  if ((c == '\n' && is_multiline == 0) || c < 1) {
    if (*InQuote)
      err(25);
    return(1);
  }
  ch[0] = c;
  ch[1] = 0;
  insert_into_buf(buf, ch, 0);
  return (0);
}

buf_t* clone_buf(buf_t* buf)
{
  buf_t* b;

  b = new_buf();
  b->pos = buf->pos;
  b->buf = _strdup(buf->buf);
  b->size = strlen(b->buf) + 1;
  return (b);
}

char *GetMacroBody(SDef *def, int is_multiline, int rpt)
{
  char *id = NULL, *p1, *p2, *p3;
  buf_t* buf;
  char ch[2];
  char mk[3];
  int ii, c;
  int InQuote = 0;
  int count;
  int nparm = 0;
  static int depth = 0;


  buf = new_buf();
  buf->buf = NULL;
  buf->pos = 0;
  buf->size = 0;

  if (def->nArgs <= 0)
    nparm = 0;
  else
    nparm = def->nArgs;
  SkipSpaces();
  p1 = p2 = inptr;
  while(1)
  {
    p3 = inptr;
    if (!InQuote) {
      if (syntax == 0) {
        if (rpt == 2 && strncmp(inptr, "#endm", 5) == 0 && !IsIdentChar(inptr[5])) {
          if (InQuote)
            err(25);
          inptr += 5;
          ScanPastEOL();
          break;
        }
      }
      else if (syntax == 1) {
        if (PeekCh() == '\\' && inptr[1] == '@') {
          proc_instvar(&buf);
        }
        else if (PeekCh() == '\\') {
          if (proc_parm(&buf, nparm))
            continue;
        }
        //      if (strncmp(inptr, ".endr", 5)==0)
        //      b += sprintf_s(b, 20, ".endr\n\n") - 1;
        if (rpt == 1 && strncmp(inptr, ".rept", 5) == 0) {
          if (inptr[5] != '[') {
            depth++;
            proc_rept(NULL, &buf, is_multiline);
            depth--;
          }
          else {
            char rp[20];
            sprintf_s(rp, sizeof(rp), "%.12s", inptr);
            rp[12] = 0;
            insert_into_buf(&buf, rp, 0);
            inptr += 12;
          }
        }
        else if (rpt == 1 && strncmp(inptr, ".endr", 5) == 0) {
          inptr += 5;
          if (depth == 0) {
            if (InQuote)
              err(25);
            break;
          }
        }
        if (rpt == 2 && strncmp(inptr, ".endm", 5) == 0) {
          if (InQuote)
            err(25);
          break;
        }
      }
      // First search for an identifier to substitute with parameter.
      // If there are no args to the macro definition, then there is nothing to
      // substitute.
      id = NULL;
      if (def->nArgs > 0 && def->parms) {
        // Copy leadings spaces to definition.
        while (PeekCh() == ' ' || PeekCh() == '\t') {
          ch[0] = NextCh();
          ch[1] = 0;
          insert_into_buf(&buf, ch, 0);
        }

        if (is_multiline == 0) {
          if (PeekCh() == '\\') {
            p1 = inptr;
            c = NextCh();
            if (isdigit(c)) {
              while (isdigit(c = NextCh()));
              c = strtoul(&p1[1], &inptr, 10);
              if (c < nparm) {
                mk[0] = '';
                mk[1] = '0' + (char)c;
                mk[2] = 0;
                p1++;
                p2 = inptr;
                insert_into_buf(&buf, mk, 0);
              }
            }
            else {
              id = GetIdentifier();
              p2 = inptr;
            }
          }
        }
        else {
          p1 = inptr;
          id = GetIdentifier();
          p2 = inptr;
        }

        if (id)
          sub_id(def, id, &buf, p1, p2);
        else {
          inptr = p1;    // reset inptr if no identifier found
        }
      }
    } // !InQuote
    if (id == NULL) {
      int pl;

      if (proc_literal(&InQuote, &buf, is_multiline))
        break;
    }
    if (inptr == p3)
      if (NextCh() < 1)
        break;
  }
  // Trim off all but one trailing spaces.
  for (ii = 0; ii < buf->size; ii++) {
    if (buf->buf[ii] == 0) {
      ii--;
      while (isspace(buf->buf[ii]) && ii > 0)
        --ii;
      ii += 1;
      buf->buf[ii] = 0;
      break;
    }
  }
//   strcat_s(buf, sizeof(buf), "\n");
  def->body = clone_buf(buf);
  def->abody = clone_buf(buf);
  free(buf->buf);
  free(buf);
  return (def->body);
}


/* ---------------------------------------------------------------------------
   Description :
      Gets an argument to be substituted into a macro body. Note that the
   round bracket nesting level is kept track of so that a comma in the
   middle of an argument isn't inadvertently picked up as an argument
   separator.
--------------------------------------------------------------------------- */

char *GetMacroArg()
{
   int Depth = 0;
   int c;
   static char argbuf[40000];
   char *argstr = argbuf;
   int InQuote = 0;

   SkipSpaces();
   memset(argbuf,0,sizeof(argbuf));
   while (1)
   {
     c = NextCh();
     if (c == '"') {
       InQuote = !InQuote;
       continue;
     }
     if (c < 1) {
       if (Depth > 0)
         err(16);
       break;
     }
     if (InQuote && c == '\\') {
       if (PeekCh() == '"') {
         c = '"';
         NextCh();
       }
     }
      if (c == '(')
         Depth++;
      else if (c == ')') {
         if (Depth < 1) {  // check if we hit the end of the arg list
            unNextCh();
            break;
         }
         Depth--;
      }
      else if (Depth == 0 && c == ',') {   // comma at outermost level means
         unNextCh();
         break;                           // end of argument has been found
      }
      if (c == '\n') {
        unNextCh();
        break;
      }
      *argstr++ = c;       // copy input argument to argstr.
   }
   *argstr = '\0';         // NULL terminate buffer.
   if (argbuf[0])
	   if (fdbg) fprintf(fdbg,"    macro arg<%s>\r\n",argbuf);
   return (argbuf);
   //return argbuf[0] ? argbuf : NULL;
}


/* ---------------------------------------------------------------------------
   Description :
      Used during the definition of a macro to get the associated parameter
   list.

   Returns
      pointer to first parameter in list.
---------------------------------------------------------------------------- */

int GetMacroParmList(arg_t *parmlist[], int opt)
{
   char *id;
   int Depth = 0, c, count;
   int vargs = 0;
   char buf2[10000];
   int nn;

   count = 0;
   while(count < MAX_MACRO_ARGS)
   {
     if (opt == 1) {
       if (PeekCh() == '+') {
         NextCh();
         vargs = 1;
       }
     }
     if (PeekCh() == '"') {
       memset(buf2, 0, sizeof(buf2));
       NextCh();
       // Copy parameter string to buffer.
       for (nn = 0; nn < sizeof(buf2)-1; nn++) {
         if (PeekCh() == 0)
           goto errxit;
         if (PeekCh() == '"') {
           NextCh();
           parmlist[count]->num = count;
           parmlist[count]->name = _strdup(buf2);
           count++;
           break;
         }
         buf2[nn] = PeekCh();
         NextCh();
       }
       continue;
     }
     id = GetIdentifier();
      if (id) {
        if (strncmp(id, "...", 3) == 0) {
          vargs = 1;
        }
         if (count >= MAX_MACRO_ARGS) {
            err(15);
            goto errxit;
         }
         parmlist[count]->num = count;
         parmlist[count]->name = _strdup(id);
//         if (parmlist[count] == NULL)
//            err(5);
         count++;
      }
	  do {
		c = NextNonSpace(0);
		if (c=='\\')
			ScanPastEOL();
	  }
		while (c=='\\');
    if (opt == 1 && c == '\n')
      break;
    if (c == ')') {   // we've gotten our last parameter
        unNextCh();
        break;
    }
    if (c == '=') {
      parmlist[count]->def = _strdup(GetMacroArg());
    }
    if (c != ',') {
        err(16);
        goto errxit;
    }
  }
//   if (count < 1)
//      err(17);
//   if (count < MAX_MACRO_ARGS)
//      parmlist[count] = NULL;
errxit:;
   return vargs ? -count : count;
}


/* ---------------------------------------------------------------------------
   Description :
      Used during the definition of a macro to get the associated parameter
   list.

   Returns
      pointer to first parameter in list.
---------------------------------------------------------------------------- */

int GetReptArgList(arg_t* arglist[], int opt)
{
  int Depth = 0, c, count;
  int vargs = 0;

  count = 0;
  while (1)
  {
    do {
      c = NextNonSpace(0);
      if (c == '\\')
        ScanPastEOL();
    } while (c == '\\');
    if (opt == 1 && c == '\n')
      break;
    if (c == ')') {   // we've gotten our last parameter
      unNextCh();
      break;
    }
    unNextCh();
    arglist[count]->def = _strdup(GetMacroArg());
    count++;
    c = PeekCh();
    if (c == '\n')
      break;
    if (c != ',') {
      err(16);
      goto errxit;
    }
  }
errxit:;
  return (count);
}

/* -----------------------------------------------------------------------------
   Description :
      Copies a macro into the input buffer. Resets the input buffer pointer
   to the start of the macro.

   slen; - the number of characters being substituted
----------------------------------------------------------------------------- */

// Uses the first eight bytes of the buffer to store an  index.

void insert_into_buf(buf_t** buf, char* p, int pos)
{
  int nn = strlen(p);
  int mm;
  char* q = NULL;
  int lastpos = 0;

  if (buf == NULL)
    return;
  if (p == NULL)
    return;

  if (*buf == NULL)
    *buf = new_buf();
  if ((*buf)->buf == NULL) {
    mm = (nn + 4095 + 8) & 0xfffff000;
    if (mm > 1000000)
      exit(0);
    q = malloc(mm);
    if (q == NULL)
      exit(0);
    memset(q, 0, mm);
    (*buf)->size = mm;
    (*buf)->buf = q;
    (*buf)->pos = 0;
  }
  if ((*buf)->buf == NULL) {
    exit(0);
  }
  lastpos = (*buf)->pos;
  if (lastpos + nn + pos > (*buf)->size) {
    mm = ((*buf)->size + nn + pos + 4095) & 0xfffff000;
    q = malloc(mm);
    if (mm > 1000000)
      exit(0);
    if (q == NULL)
      exit(0);
    memset(q, 0, mm);
    memcpy_s(q, (*buf)->size, (*buf)->buf, lastpos);
    free((*buf)->buf);
    (*buf)->size = mm;
    (*buf)->buf = q;
  }
  if ((*buf)->buf == NULL) {
    exit(0);
  }
  if (pos == 0) {
    memcpy_s(&(*buf)->buf[lastpos], (*buf)->size - lastpos, p, nn);
    lastpos += nn;
    (*buf)->buf[lastpos] = 0;
    (*buf)->pos = lastpos;
  }
  else {
    memmove_s(&(*buf)->buf[pos + nn], (*buf)->size - pos - nn, &(*buf)->buf[pos], nn);
    memcpy_s(&(*buf)->buf[pos], (*buf)->size - pos, p, nn);
    lastpos += nn;
    (*buf)->buf[lastpos] = 0;
    (*buf)->pos = lastpos;
  }
}

static char* expand(SDef* dp, buf_t** buf)
{
  int ii, cn;
  char* ex, *nd, *q, * bdy;
  char ch[4];
  int jj, mm, nn;
  buf_t* bp;

  bp = new_buf();
  nn = strlen(dp->abody->buf);
  if (*buf == NULL)
    *buf = new_buf();
  if ((*buf)->buf == NULL) {
    mm = (nn + 4095) & 0xfffff000;
    if (mm > 1000000)
      exit(0);
    q = malloc(mm);
    if (q == NULL)
      exit(0);
    memset(q, 0, mm);
    (*buf)->size = mm;
    (*buf)->buf = q;
    (*buf)->pos = 0;
  }
  if ((*buf)->buf == NULL) {
    exit(0);
  }

  // Substitute any macro arguments
  bdy = dp->abody->buf;
  for (ii = 0; ii < dp->nArgs; ii++) {
    if (dp->parms[ii]->name)
      bdy = SubMacroArg(dp->abody->buf, dp->parms[ii]->num+1, dp->parms[ii]->name);
    else
      bdy = SubMacroArg(dp->abody->buf, dp->parms[ii]->num+1, dp->parms[ii]->def);
  }

  inptr = SearchAndSub(dp->abody, bdy);
  // SearchAndSub() may rellocate the input buffer, so reset the bdy pointer.
  bdy = dp->abody->buf;
  //  SearchAndSub((*buf)->buf);

  for (ii = 0; ii < nn; ii++) {
    if (strncmp(&bdy[ii], ".rept[", 6) == 0) {
      jj = strtoul(&bdy[ii+6], &nd, 10);
      if (jj < rep_inst) {
        for (cn = 0; cn < rept_array[jj].orcnt; cn++) {
          ex = expand(rept_array[jj].def, buf);
        }
        ii = nd - &bdy[0] + 1;
      }
    }
    else {
      ch[0] = bdy[ii];
      ch[1] = 0;
      insert_into_buf(&bp, ch, 0);
    }
  }

//  SearchAndSub(*buf);

  nn = strlen((*buf)->buf);
  for (ii = 0; ii < nn; ii++) {
    if (strncmp(&(*buf)->buf[ii], ".rept[", 6) == 0) {
      jj = strtoul(&(*buf)->buf[ii+6], & nd, 10);
      if (jj < rep_inst) {
        for (cn = 0; cn < rept_array[jj].orcnt; cn++) {
          ex = expand(rept_array[jj].def, buf);
        }
        ii = nd - &(*buf)->buf[0] + 1;
      }
    }
    else {
      ch[0] = (*buf)->buf[ii];
      ch[1] = 0;
      insert_into_buf(&bp, ch, 0);
    }
  }
  free((*buf)->buf);
  free((*buf));
  *buf = bp;
//  SearchAndSub(*buf);
  return (*buf);
}

void SubMacro(SDef* dp, int slen)
{
   int mlen, dif;
   int64_t nchars;
   int psz = 0;
   buf_t* buf;
   int64_t indx;

   if (dp == NULL)
     return;
   buf = NULL;
   indx = inptr - inbuf->buf;
   buf = expand(dp, &buf);
   inptr = inbuf->buf + indx;
   if (buf == NULL)
     return;

   minst++;
   mlen = strlen(buf->buf);          // macro length
   dif = mlen - slen;
   nchars = inbuf->size-(inptr-inbuf->buf);         // calculate number of characters that could be remaining
   //p = inptr + dif;
   //if (dif==0)
	  // ;
   //else if (dif > 0) {
	  // for (nn = sizeof(inbuf)-500-nchars-dif; nn >= 0; nn--)
		 //  p[nn] = inptr[nn];
   //}
   //else {
	  // for (nn = 0; nn < sizeof(inbuf)-500-nchars-dif; nn++)
		 //  p[nn] = inptr[nn];
   //}
    // If the text is not changing, we want to advance the text pointer.
    // Prevents the substitution from getting stuck in a loop.
   if (strncmp(inptr-slen, buf->buf, mlen) == 0) {
     inptr -= slen;           // reset input pointer to start of replaced text
     inptr++;                 // and advance by one
     return;
   }

   if (dif > 0) {
     if (inptr + mlen > inbuf->buf + inbuf->size - 10) {
       char* p = malloc(inbuf->size + 4096);
       if (p == NULL) {
         exit(0);
       }
       memset(p + inbuf->size, 0, 4096);
       inbuf->size += 4096;
       strcpy_s(p, inbuf->size, inbuf->buf);
       inptr = p + (inptr - inbuf->buf);
       free(inbuf->buf);
       inbuf->buf = p;
     }
     memmove(inptr + dif, inptr, nchars - dif);  // shift open space in input buffer
   }
   inptr -= slen;                // reset input pointer to start of replaced text
//   SearchAndSub(buf);
   memcpy(inptr, buf->buf, mlen);    // copy macro body in place over identifier
   if (dif < 0) {
     if (inptr + mlen > inbuf->buf + inbuf->size - 10) {
       char* p = malloc(inbuf->size + 4096);
       if (p == NULL) {
         exit(0);
       }
       memset(p + inbuf->size, 0, 4096);
       inbuf->size += 4096;
       strcpy_s(p, inbuf->size, inbuf->buf);
       inptr = p + (inptr - inbuf->buf);
       free(inbuf->buf);
       inbuf->buf = p;
     }
     memmove(inptr + mlen, inptr - dif + mlen, nchars - dif);
   }
   //for (nn = 0; nn < mlen; nn++)
	  // inptr[nn] = body[nn];
   //printf("inptr:%.60s\r\n", inptr);
   //getchar();
}
