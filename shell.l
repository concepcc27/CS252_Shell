
/*
 *
 * CS-252 Fall 2017
 * shell.l: lexical analyzer for shell
 * You have to extend it.
 *
 */

%{

#include <cstring>
#include "y.tab.hh"
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <errno.h>
#include <wait.h>

static  void yyunput (int c,char *buf_ptr  );
extern "C" char * read_line();

void myunputc(int c) {
  unput(c);
}
/*
int mygetc(FILE *file) {
    char *p;
    char c;

    if(!isatty(0)) {
        return getc(file);
    }
    
    if(p == NULL || *p == 0) {
        //char *s = read_line();
        //p = s;
        char *line = NULL;
        size_t len;
        while(getline(&line, &len, file) >= 0) {
            p = line;
        }
    }
    c = *p;
    p++;
    return c;
}
*/
#undef getc
//#define getc(file) mygetc(file)

%}

%%

\n {
  return NEWLINE;
}

[ \t] {
  /* Discard spaces and tabs */
}




">" {
  return GREAT;
}

">>" {
    return GREATGREAT;
}

">&" {
    return GREATAMPERSAND;
}

">>&" {
    return GREATGREATAMPERSAND;
}

"2>" {
    return TWOGREAT;
}

"<" {
  return LESS;
}

"&" {
    return AMPERSAND;
}

"|" {
    return PIPE;
}

`[^\n`]*` {
    int len = strlen(yytext);
    char* str = strndup(yytext + 1, len - 2);
    int strLen = strlen(str);
    str[strLen] = '\0';

    int tmpin = dup(0);
    int tmpout = dup(1);
    int fdin[2];
    int fdout[2];
    pipe(fdin);
    pipe(fdout);
    
    write(fdin[1], str, strLen);
    write(fdin[1], "\n", 1);
    write(fdin[1], "exit", 4);
    write(fdin[1], "\n", 1);
    close(fdin[1]);
    dup2(fdin[0], 0);
    close(fdin[0]);
    dup2(fdout[1],1);
    close(fdout[1]);

    int child = fork();
    if(!child) {
        execvp("/proc/self/exe", NULL);
        exit(1);
    }else if(child < 0) {
        perror("subshell fork");
        exit(1);
    }

    dup2(tmpin, 0);
    dup2(tmpout, 1);
    close(tmpin);
    close(tmpout);
    
    char c;
    char *result = (char*)malloc(1000);
    int i = 0;
    while(read(fdout[0], &c, 1)) {
        if (c == '\n') {
            result[i++] = ' ';
        }else {
            result[i++] = c;
        }
    }
    result[i] = '\0';
    for(i = i - 12; i >= 0; i--) {
        myunputc(result[i]);
    }
}

\"[^\n\"]*\" {
    int i = 0;
    int j = 0;
    int len = strlen(yytext);
    
    for(i = 0; i < len; i++) {
        if(yytext[i] != '\"') {
            yytext[j] = yytext[i];
            j++;
        }else if(yytext[i] == '\"') {
            yytext[j] = yytext[i + 1];
            i++;
            j++; 
        }
    }

    if(j > 0) {
        yytext[j] = '\0';
    }
    yylval.string_val = strdup(yytext);
    return WORD;
}

(([^ \"\t\n\|\>\<\&\[\]])|(\\.))+  {
  /* Assume that file names have only alpha chars */
    int i = 0;
    int j = 0;
    int len = strlen(yytext);
    for(i = 0; i < len; i++) {
        if(yytext[i] != '\\') {
            yytext[j] = yytext[i];
            j++;
        }else if(yytext[i] == '\\') {
            yytext[j] = yytext[i + 1];
            i++;
            j++; 
        }
    }
    if(j > 0) {
        yytext[j] = '\0';
    }
    

    yylval.string_val = strdup(yytext);
    return WORD;
}

. {
    return NOTOKEN;
}
