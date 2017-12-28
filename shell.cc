#include "command.hh"
#include <signal.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/wait.h>

int yyparse(void);

extern "C" void disp( int sig )
{
	fprintf(stderr, "\n");
    Command::_currentCommand.clear();
    Command::_currentCommand.prompt();
}

extern "C" void disp2( int sig )
{
	wait3(0,0,NULL);
    while(waitpid((pid_t)(-1), NULL, WNOHANG) > 0); 
}


int main() {
     
	Command::_currentCommand.prompt();
    struct sigaction sa;
    sa.sa_handler = disp;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = SA_RESTART;

    if(sigaction(SIGINT, &sa, NULL)){
        perror("sigaction");
        exit(2);
    }

    struct sigaction sa2;
    sa2.sa_handler = disp2;
    sigemptyset(&sa2.sa_mask);
    sa2.sa_flags = SA_RESTART;

    if(sigaction(SIGCHLD, &sa2, NULL)){
        perror("sigactions");
        exit(2);
    }
	yyparse();
}
