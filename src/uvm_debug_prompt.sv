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
//  Interactive debug prompt
//  Base class for debug command call back 
//  Basic debug commands
// 
// -----------------------------------------------------------------------------

// forward declaration
typedef class uvm_debug_command_cb;
typedef class uvm_debug_reg_util;
typedef class uvm_debug_seq_util;

// -------------------------------------------------------------- 
// ncsim cfc util 
// -------------------------------------------------------------- 
class uvm_debug_util extends uvm_object;

    // boiler plate uvm code
    `uvm_object_utils(uvm_debug_util)
    function new (string name = "");
        super.new(name);
    endfunction: new
 
    // -------------------------------------------------------------- 
    // singleton
    // -------------------------------------------------------------- 

    // static self reference pointer
    static uvm_debug_util m_inst;
    uvm_debug_reg_util reg_util;
    uvm_debug_seq_util seq_util;

    // get singleton instance 
    static function uvm_debug_util get();
        if (uvm_debug_util::m_inst == null) begin
            uvm_debug_util::m_inst = uvm_debug_util::type_id::create("uvm_debug");
            uvm_debug_util::m_inst.init_sbuffer();
            uvm_debug_util::m_inst.add_core_debug_commands();
            uvm_debug_util::m_inst.reg_util = uvm_debug_reg_util::type_id::create("reg_util");
            uvm_debug_util::m_inst.seq_util = uvm_debug_seq_util::type_id::create("seq_util");
        end
        return uvm_debug_util::m_inst;
    endfunction

    // -------------------------------------------------------------- 
    // DPI interface function
    // -------------------------------------------------------------- 

    // string buffer
    string sbuffer;     

    // initialize the string buffer
    function void init_sbuffer();
        // allocate 1000 characters for the string buffer
        for (int i=0; i<100; i++) begin
            sbuffer = {sbuffer, "           "};
        end
    endfunction: init_sbuffer
    
    // execute a tcl command
    function void exec_cmd(string cmd);
        dpi_tcl_exec_cmd(cmd);
    endfunction: exec_cmd

    // read a line from ncsim prompt
    function string read_line(string prompt);
        dpi_read_line(prompt, sbuffer);
        read_line = sbuffer;
    endfunction: read_line

    // return value
    string rv;

    // -------------------------------------------------------------- 
    // debug commands
    // -------------------------------------------------------------- 
    uvm_queue#(uvm_debug_command_cb) debug_commands = new;

    // command history
    string cmd_history[$];

    // search and launch the debug commands
    virtual task run_debug_command(string cmd);
        bit dbg_cmd_found = 0;
        string args[$];

        // clear return value
        rv = "";

        // search matching debug commands from registered callback list
        uvm_split_string(cmd, " ", args);
        if (args.size() > 0) begin
            for (int i=0; i < debug_commands.size(); i++) begin
                uvm_debug_command_cb dbg_cmd = debug_commands.get(i);
                if (uvm_is_match(dbg_cmd.command, args[0])) begin
                    dbg_cmd.parse_args(args);
                    dbg_cmd_found = 1;
                    break;
                end 
            end 

            if (dbg_cmd_found == 0) begin
                $display("command '%s' not found", args[0]);
            end
        end
    endtask

    // ---------------------------------------------------------------
    // debug prompt
    //  level   - debug level; 
    //      0: always enable, 
    //      >0: enable when match the +debug_level cmdline argument
    //  cmd     - inline command input
    // -------------------------------------------------------------- 
    bit is_break_prompt = 0;
    virtual task prompt(int level = 0, string cmd = "");
        string line;

        // check debug level cmdline argument
        if (level > 0) begin
            if (level != get_arg_value_int("+debug_level=")) begin
                return;
            end
        end

        if (cmd.len() == 0) begin
            // interactive command
            $display("debug prompt (help for all commands)");
            is_break_prompt = 0;

            forever begin
                string prompt;
                line = "";
                $sformat(prompt, "%t: %s", $time, "debug > ");
                line = read_line(prompt);
                if (line.len() > 0) begin 
                    cmd_history.push_back(line);
                end

                // search the debug command list and run the command
                run_debug_command(line);

                if (is_break_prompt) begin
                    break;
                end
            end
        end else begin
            // inline command
            run_debug_command(cmd);
        end
    endtask: prompt

    // -------------------------------------------------------------- 
    // save checkpoint
    // -------------------------------------------------------------- 
    function void save_checkpoint(string snapshot, string path ="");
        string cmd;
        `uvm_info("UVM_DBG", {"Saving simulation checkpoint to ", snapshot}, UVM_LOW);
        cmd = {"stop -delta 1 -delbreak 1 -execute {save -overwrite ", 
                ((path.len() == 0)?"":{" -path ", path}), snapshot, 
                "} -silent -continue"};
        exec_cmd(cmd);
    endfunction: save_checkpoint

    // -------------------------------------------------------------- 
    // add core debug commands
    // --------------------------------------------------------------
    extern function void add_core_debug_commands();

endclass: uvm_debug_util

// -------------------------------------------------------------- 
// debug command callback base class 
// -------------------------------------------------------------- 
virtual class automatic uvm_debug_command_cb extends uvm_object;

    // get uvm_debug singleton class
    uvm_debug_util uvm_debug = uvm_debug_util::get();

    string command;         // the debug command name
    string usage;           // usage, list of arguments
    string description;     // detail description of the command 

    function new(string name = "uvm_debug_command_cb");
        super.new(name);
        uvm_debug.debug_commands.push_back(this);
    endfunction

    // args - argument list, the first argument is the command itself
    pure virtual task parse_args(string args[$]);
endclass: uvm_debug_command_cb

// -------------------------------------------------------------- 
// define build-in core debug commands
// -------------------------------------------------------------- 

class debug_command_help extends uvm_debug_command_cb;
    function new(string name = "debug_command_help");
        super.new(name);
        // -------------------------------------------------------------- 
        command =       "help";
        usage =         "[command]";
        description =   {
            "debug prompt help\n",
            "list all the avaiable commands\n",
            "type 'help' followed by the command name for detail info\n"
        };
        // -------------------------------------------------------------- 
    endfunction

    task parse_args(string args[$]);
        if (args.size() == 1) begin
            // list all commands
            $display("Avaiable debug commands:");
            for (int i=0; i < uvm_debug.debug_commands.size(); i++) begin
                uvm_debug_command_cb dbg_cmd = uvm_debug.debug_commands.get(i);
                $display("  %s %s", dbg_cmd.command, dbg_cmd.usage);
            end 
            $display("Type 'help <command>' for help on a specify command");
        end else begin
            for (int i=0; i < uvm_debug.debug_commands.size(); i++) begin
                uvm_debug_command_cb dbg_cmd = uvm_debug.debug_commands.get(i);
                if (uvm_is_match(dbg_cmd.command, args[1])) begin
                    $display("Usage: %s %s", dbg_cmd.command, dbg_cmd.usage);
                    $display(dbg_cmd.description);
                    return;
                end 
            end
            $display("command %s not found", args[1]);
        end
    endtask
endclass: debug_command_help

class debug_command_continue extends uvm_debug_command_cb;
    function new(string name = "debug_command_cotinue");
        super.new(name);
        // -------------------------------------------------------------- 
        command =       "continue";
        usage =         "";
        description =   "exit debug prompt, continue the simulation";
        // -------------------------------------------------------------- 
    endfunction

    task parse_args(string args[$]);
        uvm_debug.is_break_prompt = 1;
    endtask
endclass: debug_command_continue

class debug_command_pause extends uvm_debug_command_cb;
    function new(string name = "debug_command_pause");
        super.new(name);
        // -------------------------------------------------------------- 
        command =       "pause";
        usage =         "";
        description =   "pause the simulation, back to tcl prompt";
        // -------------------------------------------------------------- 
    endfunction

    task parse_args(string args[$]);
        uvm_debug.exec_cmd("stop -delta 1 -delbreak 1");
        uvm_debug.is_break_prompt = 1;
    endtask
endclass: debug_command_pause

class debug_command_run extends uvm_debug_command_cb;
    function new(string name = "debug_command_run");
        super.new(name);
        // -------------------------------------------------------------- 
        command =       "run";
        usage =         "<runtime>";
        description =   "run the simulation for the time specfied (in timescale unit)";
        // -------------------------------------------------------------- 
    endfunction

    task parse_args(string args[$]);
        int runtime = args[1].atoi();
        #runtime;
    endtask
endclass: debug_command_run

class debug_command_puts extends uvm_debug_command_cb;
    function new(string name = "debug_command_puts");
        super.new(name);
        // -------------------------------------------------------------- 
        command =       "puts";
        usage =         "<message>";
        description =   "print a string";
        // -------------------------------------------------------------- 
    endfunction

    task parse_args(string args[$]);
        `uvm_info("UVM_DBG", text::join_str(args[1:$], " "), UVM_LOW);
    endtask
endclass: debug_command_puts

class debug_command_history extends uvm_debug_command_cb;
    function new(string name = "debug_command_history");
        super.new(name);
        // -------------------------------------------------------------- 
        command =       "history";
        usage =         "[list]|clear|save <file>";
        description =   "command history utils, list/clear previous commands, save to a file";
        // -------------------------------------------------------------- 
    endfunction

    task parse_args(string args[$]);
        void'(uvm_debug.cmd_history.pop_back());
        if (args.size() == 1 || args[1] == "list") begin
            // list all commands in the history
            foreach (uvm_debug.cmd_history[i]) begin
                $display("%0d. %s", i, uvm_debug.cmd_history[i]);
            end
        end else if (args[1] == "clear") begin
            // clear all commands in the history
            uvm_debug.cmd_history.delete();
        end else if (args[1] == "save") begin
            // save to file
            UVM_FILE fh = $fopen(args[2], "w");
            foreach (uvm_debug.cmd_history[i]) begin
                // don't export history commands or it will create infinite loop in the command file
                if (!uvm_is_match("history*", uvm_debug.cmd_history[i])) begin
                    $fdisplay(fh, "%s", uvm_debug.cmd_history[i]);
                end
            end
            $fclose(fh);
            $display("history saved to file: %s", args[2]);
        end
    endtask
endclass: debug_command_history

class debug_command_repeat extends uvm_debug_command_cb;
    function new(string name = "debug_command_repeat");
        super.new(name);
        // -------------------------------------------------------------- 
        command =       "repeat";
        usage =         "#";
        description =   "repeat history #";
        // -------------------------------------------------------------- 
    endfunction

    task parse_args(string args[$]);
        int history_num = args[1].atoi();
        uvm_debug.cmd_history[$] = uvm_debug.cmd_history[history_num];
        uvm_debug.run_debug_command(uvm_debug.cmd_history[history_num]);
    endtask
endclass: debug_command_repeat

class debug_command_read extends uvm_debug_command_cb;
    function new(string name = "debug_command_read");
        super.new(name);
        // -------------------------------------------------------------- 
        command =       "read";
        usage =         "<file>";
        description =   "read and execute commands from a file";
        // -------------------------------------------------------------- 
    endfunction

    task parse_args(string args[$]);
        UVM_FILE fh = $fopen(args[1], "r");
        string cmd;

        if (!fh) begin
            `uvm_warning("UVM_DBG", {"Cannot open file ", args[1]});
            return;
        end
        while ($fgets(cmd, fh) > 0) begin
            // line start with # are comments
            // skip empty lines
            string strip_cmd = text::lstrip(text::rstrip(cmd," \t\n"), " ");
            if (!uvm_is_match("#*", strip_cmd) && strip_cmd.len() > 0) begin
                uvm_debug.run_debug_command(strip_cmd);
            end
        end
        $fclose(fh);
    endtask
endclass: debug_command_read

class debug_command_save_checkpoint extends uvm_debug_command_cb;
    function new(string name = "debug_command_save_checkpoint");
        super.new(name);
        // -------------------------------------------------------------- 
        command =       "save_checkpoint";
        usage =         "[-path <path>] <snapshot>";
        description =   "save a simulation checkpoint";
        // -------------------------------------------------------------- 
    endfunction

    task parse_args(string args[$]);
        string options[string];
        string path = "";
        string snapshot;
        string cmd;

        extract_options(args, options);
        snapshot = args[0];
        if (options.exists("path")) begin
            path = options["path"];
        end
        uvm_debug.save_checkpoint(snapshot, path);
        #0;
    endtask
endclass: debug_command_save_checkpoint

// -------------------------------------------------------------- 
// add built-in core debug commands
// -------------------------------------------------------------- 
function void uvm_debug_util::add_core_debug_commands();
    debug_command_help              dbg_cmd_help = new;
    debug_command_continue          dbg_cmd_continue = new;
    debug_command_pause             dbg_cmd_pause = new;
    debug_command_run               dbg_cmd_run = new;
    debug_command_history           dbg_cmd_history = new;
    debug_command_repeat            dbg_cmd_repeat = new;
    debug_command_read              dbg_cmd_read = new;
    debug_command_save_checkpoint   dbg_cmd_save_checkpoint = new;
endfunction

