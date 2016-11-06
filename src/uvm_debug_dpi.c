// MIT License
// 
// Copyright (c) 2016 Microsemi
// http://www.microsemi.com
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// -----------------------------------------------------------------------------
// Description: 
//
//  Interact with the simulator tcl prompt or STDIN via DPI
//
// -----------------------------------------------------------------------------
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#if defined(NCSC)
    // Cadence
    #include <cfclib.h>         
#elif defined(MENTOR)
    // Mentor
    #include <mti.h>            
#endif

char sbuffer[1000];          // input string buffer

// execute a tcl comamnd in simulator
void dpi_tcl_exec_cmd(char* cmd) {
    #if defined(NCSC)
        cfcExecuteCommand(cmd);
    #elif defined(MENTOR)
        mti_Cmd(cmd);
    #else
        // not supported
        printf("tcl intregation is not support in this simulator\n");
    #endif
};

// read a line from tcl prompt or stdin
void dpi_read_line(char* prompt, char** line) {
    #if defined(NCSC)
        *line = cfcReadline(prompt);
    #elif defined(MENTOR)
        mti_AskStdin(*line, prompt);
    #else
        printf(prompt);
        fflush(stdout);
        *line = &buffer;
        int bufsize = size(buffer) / sizeof(char);
        getline(&sbuffer, &bufsize, stdin);
    #endif
};

// get the string buffer
void dpi_get_sbuffer(char **line) {
    *line = (char *)&sbuffer;
};

#if defined(NCSC)
    // trigger debug prompt from tcl
    void debug_prompt(char **args) {
        strcpy(sbuffer, "");
        while (*args) {
            strcat(sbuffer, *args);
            strcat(sbuffer, " ");
            args++;
        };
        dpi_tcl_exec_cmd("run -delta 1; deposit uvm_debug.trigger_prompt 1; stop -delbreak 1 -object uvm_debug.trigger_prompt; run");
    };

    // setup cfc function table
    cfcTableT cfcTable = {
        {"debug_prompt", debug_prompt},
        {0, 0}
    };
#elif defined(MENTOR)
    // TODO
#else
    // TODO
#endif
