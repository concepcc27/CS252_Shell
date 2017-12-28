
/*
 * CS-252
 * shell.y: parser for shell
 *
 * This parser compiles the following grammar:
 *
 *	cmd [arg]* [> filename]
 *
 * you must extend it to understand the complete shell grammar
 *
 */

%code requires 
{
#include <string>

#if __cplusplus > 199711L
#define register      // Deprecated in C++11 so remove the keyword
#endif
}

%union
{
  char        *string_val;
  // Example of using a c++ type in yacc
  std::string *cpp_string;
}

%token <string_val> WORD
%token NOTOKEN GREAT NEWLINE GREATAMPERSAND AMPERSAND GREATGREATAMPERSAND PIPE LESS GREATGREAT TWOGREAT

%{
//#define yylex yylex
#include <cstdio>
#include <string.h>
#include <dirent.h>
#include <regex.h>
#include <assert.h>
#include "command.hh"

#define MAXFILENAME 1024

int numE = 0;
int maxE = 20;
char **arr = NULL;

void yyerror(const char * s);
int yylex();
void expandWildcardsIfNecessary(char * arg);
void expandWildcard(char * prefix, char * suffix);
int compare(const void * str1, const void * str2);

%}

%%

goal:
  commands
  ;

commands:
  command
  | commands command
  ;

command: simple_command
       ;

simple_command:	
  pipe_list iomodifier_list NEWLINE {
    //printf("   Yacc: Execute command\n");
    Command::_currentCommand.execute();
  }
  | NEWLINE {
        Command::_currentCommand.clear();
        Command::_currentCommand.prompt();
    } 
  | error NEWLINE { yyerrok; }
  ;

pipe_list:
    pipe_list PIPE command_and_args
    | command_and_args
    ;

command_and_args:
  command_word argument_list {
    Command::_currentCommand.insertSimpleCommand( Command::_currentSimpleCommand );
  }
  ;

argument_list:
  argument_list argument
  | /* can be empty */
  ;

argument:
  WORD {
    //Command::_currentSimpleCommand->insertArgument($1);
    expandWildcardsIfNecessary($1);
  }
  ;

command_word:
  WORD {
    //printf("   Yacc: insert command \"%s\"\n", $1);
    Command::_currentSimpleCommand = new SimpleCommand();
    Command::_currentSimpleCommand->insertArgument( $1 );
  }
  ;

iomodifier_list:
    iomodifier_list iomodifier_opt
    |
    ;

iomodifier_opt:
  GREAT WORD {
    //printf("   Yacc: insert output \"%s\"\n", $2);
    if(Command::_currentCommand._outFile) {
        yyerror("Ambiguous output redirect.\n");
    }
    Command::_currentCommand._outFile = $2;
  }
    | GREATGREAT WORD {
    //printf("   Yacc: insert output \"%s\"\n", $2);
    if(Command::_currentCommand._outFile) {
        yyerror("Ambiguous output redirect.\n");
    }
    Command::_currentCommand._outFile = $2;
    Command::_currentCommand._append = 1;
  }

    | GREATAMPERSAND WORD {
    //printf("   Yacc: insert output \"%s\"\n", $2);
    if(Command::_currentCommand._outFile) {
        yyerror("Ambiguous output redirect.\n");
    }
    Command::_currentCommand._outFile = $2;
    Command::_currentCommand._errFile = $2;
    //Command::_currentCommand._background = 1;
  }

    | GREATGREATAMPERSAND WORD {
    //printf("   Yacc: insert output \"%s\"\n", $2);
    if(Command::_currentCommand._outFile) {
        yyerror("Ambiguous output redirect.\n");
    }
    Command::_currentCommand._outFile = $2;
    Command::_currentCommand._errFile = $2;
    Command::_currentCommand._append = 1;
    //Command::_currentCommand._background = 1;
  }
    | TWOGREAT WORD {
    if(Command::_currentCommand._outFile) {
        yyerror("Ambiguous output redirect.\n");
    }
    Command::_currentCommand._errFile = $2;
    
    }
    | LESS WORD {
    //printf("   Yacc: insert output \"%s\"\n", $2);
    Command::_currentCommand._inFile = $2;
  }

  | /* can be empty */ 
  ;

background_optional:
    AMPERSAND
    |
    ;

%%

void
yyerror(const char * s)
{
  fprintf(stderr,"%s", s);
}

void expandWildcard(char * prefix, char * suffix) {
    

    //CHECK IF SUFFIX IS EMPTY
    if(suffix[0] == 0) {
        //Command::_currentSimpleCommand->insertArgument(strdup(prefix));
        /*
          RESIZE ARRAY
        */
        if (numE == maxE) {
            maxE *= 2;
            arr = (char**)realloc(arr, maxE*sizeof(char*));
            assert(arr != NULL);
        }
        arr[numE] = strdup(prefix);
        numE++;
        return;
    }

    char *str = strchr(suffix, '/');
    char comp[MAXFILENAME];
    
    //INITIALIZE COMP
    int j = 0;
    for (j = 0; j < MAXFILENAME; j++) {
        comp[j] = 0;
    }    
    if(suffix[0] == '/') {
        comp[0] = '/';
    }
    //printf("prefix = %s \nsuffix = %s \n", prefix, suffix);
    
    /*
      IF STR NOT NULL, COPY TO FIRST '/'
      ELSE, COPY ENTIRE STRING
    */
    if(str != NULL) {
        strncpy(comp, suffix, str - suffix);
        suffix = str + 1;    
        
        /*
          IF '/' IS FOUND, BREAK UP STRING
          ELSE, COPY STRING
        */
        //if(prefix[0] == 0 && suffix[0] == '/') {
            /*str = strchr(suffix, '/');*/
            /*
              CHECK FOR NEXT DIRECTORY TO SEARCH FOR
              IF NOT NULL, COPY BEFORE /
              IF NULL, COPY STRING
            */
            /*if(str != NULL) {
                strncpy(comp, suffix, str - suffix);
                suffix = str + 1;
                prefix = (char*)"/";
            }else {
                strcpy(comp, suffix);
                suffix = str + strlen(suffix);
                prefix = (char*)"/";
            }*/
        //}
    }else {
        strcpy(comp, suffix);
        suffix += strlen(suffix);   
    }
    //printf("comp = %s \nstr = %s \n\n", comp, str);
    
    /*
      INITIALIZE NEW PREFIX VARIABLE
    */
    char _prefix[MAXFILENAME];
    int k = 0;
    for(k = 0; k < MAXFILENAME; k++) {
        _prefix[k] = 0;
    }

    /*
      IF NO WILDCARDS, BEGIN RECURSIVE PROCESS
    */
    if(strchr(comp, '*') == NULL && strchr(comp, '?') == NULL) {
        /*
          IF FIRST DIR, PRINT WORD TO PREFIX
          ELSE IF, PRINT '/' AND WORD TO PREFIX
          ELSE, PRINT PREFIX + '/' + WORD TO PREFIX
        */
        if(prefix[0] == 0 /*&& !(suffix[0] == '/')*/) {
            sprintf(_prefix, "%s", comp);
        }else if (prefix[0] == '/' && prefix[1] == 0) {
            sprintf(_prefix, "%s%s", prefix, comp);
        }else {
            sprintf(_prefix, "%s/%s", prefix, comp);
        }
        expandWildcard(_prefix, suffix);    
        return;
    }
    
    char *reg = (char*)malloc(2*strlen(comp)+10);
    char *argC = comp;
    char *regC = reg;
    
    //At beginning of line
    *regC = '^';
    regC++;
    
    while(*argC) {
        if (*argC == '*') {
            *regC = '.';
            regC++;
            *regC = '*';
            regC++;
        }else if (*argC == '?') {
            *regC = '.';
            regC++;
        }else if (*argC == '.') {
            *regC = '\\';
            regC++;
            *regC = '.';
            regC++;
        }else {
            *regC = *argC;
            regC++;
        }
        argC++;
    }
        
    //Go to end of line and add NULL char
    *regC = '$';
    regC++;
    *regC = 0;

    regex_t re;
    regmatch_t regmatch;

    int buff = regcomp(&re, reg, REG_EXTENDED|REG_NOSUB);
    if(buff) {
        perror("regcomp");
        exit(1);
    }    
    
    char *syntax = NULL;
    if (prefix[0] == 0) {
        syntax = strdup(".");
    }else {
        syntax = strdup(prefix);
    }    
        
    DIR *dir = opendir(syntax);
    if(dir == NULL) {
        //perror("oopendir");
        return;
    }
    
    struct dirent * ent = readdir(dir);
    if (arr == NULL) {
        arr = (char**)(malloc(sizeof(char*)*maxE));
    }
    while (ent != NULL) {
        /*
          IF THERE IS A NAME MATCH, SEARCH FOR FILES
        */
        if (!regexec(&re, ent->d_name, 1, &regmatch, 0)) {
            
            /*
              IF BEGINS WITH '.', START SEARCH FOR HIDDEN FILES
            */
            if(ent->d_name[0] == '.') { 
                if(comp[0] == '.') {
                    /*
                        IF PREFIX IS EMPTY, PRINT CURR PREFIX AND NAME TO NEW PREFIX
                        ELSE, PRINT PREFIX + '/' + NAME TO NEW PREFIX
                    */
                    if(prefix[0] == 0 || strlen(prefix) == 1) {
                        sprintf(_prefix, "%s%s", prefix, ent->d_name);
                    }else {
                        sprintf(_prefix, "%s/%s", prefix, ent->d_name);
                    }
                    expandWildcard(_prefix, suffix);
                }
            }else {
                if(prefix[0] == 0 || strlen(prefix) == 1) {
                    sprintf(_prefix, "%s%s", prefix, ent->d_name);
                 }else {
                    sprintf(_prefix, "%s/%s", prefix, ent->d_name);
                }
                expandWildcard(_prefix, suffix);
            }
            
        }

        /*qsort(arr, numE, sizeof(char*), compare);*/
        ent = readdir(dir); 
    }
    closedir(dir);
    return;
}

void expandWildcardsIfNecessary(char *arg) {
   
    /*
        IF NOT WILDCARD, RUN AS NORMAL
    */ 
    if(strchr(arg, '*') == NULL && strchr(arg, '?') == NULL) {
        Command::_currentSimpleCommand->insertArgument(arg);
        return;
    }
    expandWildcard("", arg);
    qsort(arr, numE, sizeof(char*), compare);
    
    int i = 0;
    for (i = 0; i < numE; i++) {
        Command::_currentSimpleCommand->insertArgument(arr[i]);
    }
    if(arr == NULL) { 
        free(arr);
    }
    arr = NULL;
    numE = 0;

    return;
}

int compare(const void *str1, const void *str2) {
    return strcmp(*(char *const*)str1, *(char *const*)str2);
}


#if 0
main()
{
  yyparse();
}
#endif
