#include <cstdlib>
#include<string.h>
#include "simpleCommand.hh"

SimpleCommand::SimpleCommand() {
	// Create available space for 5 arguments
	_numOfAvailableArguments = 5;
	_numOfArguments = 0;
	_arguments = (char **) malloc( _numOfAvailableArguments * sizeof( char * ) );
}

void SimpleCommand::insertArgument( char * argument ) {
	if ( _numOfAvailableArguments == _numOfArguments  + 1 ) {
		// Double the available space
		_numOfAvailableArguments *= 2;
		_arguments = (char **) realloc( _arguments,
				  _numOfAvailableArguments * sizeof( char * ) );
	}
    
    /*
        INITIALIZE POINTER TO '$'
        INITIALIZE RETURN ARGUMENT
    */
    char * str = strchr(argument, '$');
    char * arg = (char*)malloc(200*sizeof(char));
    
    if (str != NULL) {
        int i = 0;
        /*
            ITERATE THROUGH ARGUMENT
            IF NOT '$', CONTINUE
            ELSE, INCREMENT TWICE, CONCAT BODY OF TEXT INTO ARG
        */
        for (i = 0; argument[i] != '\0'; i++) {
            int argLen = strlen(arg);
            if(argument[i] != '$' && argument[i] != '\0') {
                arg[argLen] = argument[i];
            } else if (argument[i] == '$') {
                i = i + 2;
                int j = 0;
                char * env = (char*)malloc(200*sizeof(char));
                for (j = 0; argument[i] != '}'; j++) {
                    env[j] = argument[i];
                    i++;
                }
                env[j] = '\0';
                strcat(arg, getenv(env));
                free(env);
            }
        }
        argument = strdup(arg);
    }

    if (argument[0] == '~') {
        int argumentLen = strlen(argument);

        /*
            IF ARGUMENT IS ONLY ~, DIRECT TO HOME DIRECTORY
            ELSE, CONCATENATE REST OF ARGUMENT STRING TO 'getenv(HOME)' 
            --> ARGUMENT = CONCATENATION ABOVE
        */
        if(argumentLen == 1) {
            argument = strdup(getenv("HOME"));
        } else {
            char * beginning = strdup(getenv("HOME"));
            char * end = (char*)malloc(200*sizeof(char));
            int i = 0;
            for (i = 1; i < argumentLen; i++) {
                end[i - 1] = argument[i];
            }
            end[argumentLen - 1] = '\0';
            if (argument[1] != '/') {
                char * search = strrchr(beginning, '/');
                int index = search - beginning + 1;
                beginning[index] = '\0'; 
            }
            strcat(beginning, end);
            argument = strdup(beginning);
            free(beginning);
            free(end);
        }
    } 
    free(arg); 
	
	_arguments[ _numOfArguments ] = argument;

	// Add NULL argument at the end
	_arguments[ _numOfArguments + 1] = NULL;
	
	_numOfArguments++;
}
