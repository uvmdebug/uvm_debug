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
// UVM sequence utilities
// - debug command to create a new sequence
// - debug command to randomize a new sequence
// - debug command to set fields in sequence
// - debug command to start a sequence
// -----------------------------------------------------------------------------

// base class for all seq_util debug commands
virtual class debug_command_seq_util_cb extends uvm_debug_command_cb;
    uvm_debug_seq_util seq_util;
    function new(string name = "debug_command_seq_util_cb");
       super.new(name);
    endfunction
endclass : debug_command_seq_util_cb

class uvm_debug_seq_util extends uvm_object;
    
    // boiler plate uvm code
    `uvm_object_utils(uvm_debug_seq_util)
    function new (string name = "uvm_debug_seq_util");
        super.new(name);
        add_debug_commands();
    endfunction : new

    // get uvm_top
    uvm_root uvm_top = uvm_root::get();
    uvm_factory factory = uvm_factory::get();
    
    // get uvm_debug singleton class
    uvm_debug_util uvm_debug = uvm_debug_util::get();
    debug_command_seq_util_cb dbg_cmd[$];

    // sequence list
    uvm_sequence_base dynamic_seqs[string];

    // -------------------------------------------------------------- 
    // helper functions
    // -------------------------------------------------------------- 

    // list the dynamic sequences
    virtual function void seq_list();
        foreach (dynamic_seqs[seq_name]) begin
            $display(" ", seq_name);
        end
    endfunction : seq_list

    // create a sequence 
    virtual function void seq_create(string seq_type, string seq_name);
        uvm_sequence_base seq;
        $cast(seq, factory.create_object_by_name(seq_type, get_full_name(), seq_name));
        if (seq == null) begin
            `uvm_warning("UVM_DBG/SEQ_UTIL", {"cannot create sequence type: ", seq_type});
        end else begin
            dynamic_seqs[seq_name] = seq;
            `uvm_info("UVM_DBG/SEQ_UTIL", {"new sequence created: ", seq_name}, UVM_LOW);
        end
    endfunction : seq_create

    // randomize a sequence
    virtual function void seq_rand(string seq_name);
        int rand_ok;
        uvm_sequence_base seq = dynamic_seqs[seq_name];
        if (seq == null) begin
            `uvm_warning("UVM_DBG/SEQ_UTIL", {"sequence not found: ", seq_name});
        end else begin
            rand_ok = seq.randomize();
        end
    endfunction : seq_rand

    // set fields in the sequence
    virtual function void seq_set_fields(string seq_name, string vals[string]);
        uvm_sequence_base seq = dynamic_seqs[seq_name];
        if (seq == null) begin
            `uvm_warning("UVM_DBG/SEQ_UTIL", {"sequence not found: ", seq_name});
        end else begin
            // set fields in the sequence using tcl deposit
            foreach (vals[field]) begin
                string cmd;
                $sformat(cmd, "deposit @%0d.%s %s", seq, field, vals[field]);
                uvm_debug.exec_cmd(cmd); 
            end
        end
    endfunction : seq_set_fields

    // start the sequence
    virtual task seq_start(string seq_name, string seqr_path, int this_priority = -1, bit new_thread = 0);
        uvm_sequence_base seq = dynamic_seqs[seq_name];
        if (seq == null) begin
            `uvm_warning("UVM_DBG/SEQ_UTIL", {"sequence not found: ", seq_name});
        end else begin
            uvm_sequencer_base seqr = uvm_sequencer_base'(uvm_top.find(seqr_path));
            if (seqr == null) begin
                `uvm_warning("UVM_DBG/SEQ_UTIL", {"sequencer not found: ", seqr_path})
            end else begin
                if (new_thread == 0) begin
                    seq.start(seqr, null, this_priority);
                end else begin
                    fork
                        seq.start(seqr, null, this_priority);
                    join_none
                end
            end
        end
    endtask : seq_start

    // kill the sequence
    virtual function void seq_kill(string seq_name);
        uvm_sequence_base seq = dynamic_seqs[seq_name];
        if (seq == null) begin
            `uvm_warning("UVM_DBG/SEQ_UTIL", {"sequence not found: ", seq_name});
        end else begin
            seq.kill();
        end
    endfunction : seq_kill

    // -------------------------------------------------------------- 
    // add debug commands
    // -------------------------------------------------------------- 
    extern function void add_debug_commands();

endclass : uvm_debug_seq_util

// -------------------------------------------------------------- 
// uvm_reg debug commands
// -------------------------------------------------------------- 

class debug_command_seq_list extends debug_command_seq_util_cb;
    uvm_debug_seq_util seq_util;

    `uvm_object_utils(debug_command_seq_list)
    function new(string name = "debug_command_seq_list");
        super.new(name);
        // -------------------------------------------------------------- 
        command =       "seq_list";
        usage =         "";
        description =   "list the dynamic created sequences";
        // -------------------------------------------------------------- 
    endfunction

    task parse_args(string args[$]);
        seq_util.seq_list();
    endtask
endclass: debug_command_seq_list

class debug_command_seq_create extends debug_command_seq_util_cb;
    uvm_debug_seq_util seq_util;

    `uvm_object_utils(debug_command_seq_create)
    function new(string name = "debug_command_seq_create");
        super.new(name);
        // -------------------------------------------------------------- 
        command =       "seq_create";
        usage =         "<seq_type> <seq_name>";
        description =   "create a new sequence";
        // -------------------------------------------------------------- 
    endfunction

    task parse_args(string args[$]);
        seq_util.seq_create(args[1], args[2]);
    endtask
endclass: debug_command_seq_create

class debug_command_seq_rand extends debug_command_seq_util_cb;
    uvm_debug_seq_util seq_util;

    `uvm_object_utils(debug_command_seq_rand)
    function new(string name = "debug_command_seq_rand");
        super.new(name);
        // -------------------------------------------------------------- 
        command =       "seq_rand";
        usage =         "<seq_name>";
        description =   "randomize the specified sequence";
        // -------------------------------------------------------------- 
    endfunction

    task parse_args(string args[$]);
        seq_util.seq_rand(args[1]);
    endtask
endclass: debug_command_seq_rand

class debug_command_seq_set_fields extends debug_command_seq_util_cb;
    uvm_debug_seq_util seq_util;

    `uvm_object_utils(debug_command_seq_set_fields)
    function new(string name = "debug_command_seq_set_fields");
        super.new(name);
        // -------------------------------------------------------------- 
        command =       "seq_set_fields";
        usage =         "<seq_name> [<field>=<value>...]";
        description =   "set fields in the specified sequence";
        // -------------------------------------------------------------- 
    endfunction

    task parse_args(string args[$]);
        string vals[string];        
        extract_keyvals(args, vals);
        seq_util.seq_set_fields(args[1], vals);
    endtask
endclass: debug_command_seq_set_fields

class debug_command_seq_start extends debug_command_seq_util_cb;
    uvm_debug_seq_util seq_util;

    `uvm_object_utils(debug_command_seq_start)
    function new(string name = "debug_command_seq_start");
        super.new(name);
        // -------------------------------------------------------------- 
        command =       "seq_start";
        usage =         "[-priority <priority>] [-new_thread <0|1>] <seq_name> <seqr_path>";
        description =   "start the sequence in a sequencer";
        // -------------------------------------------------------------- 
    endfunction

    task parse_args(string args[$]);
        string options[string];
        int arg_priority;
        bit arg_new_thread;

        extract_options(args, options);
        arg_priority = get_option_int(options, "priority", -1);
        arg_new_thread = get_option_int(options, "new_thread");
        seq_util.seq_start(args[0], args[1], arg_priority, arg_new_thread);
    endtask
endclass: debug_command_seq_start

class debug_command_seq_kill extends debug_command_seq_util_cb;
    uvm_debug_seq_util seq_util;

    `uvm_object_utils(debug_command_seq_kill)
    function new(string name = "debug_command_seq_kill");
        super.new(name);
        // -------------------------------------------------------------- 
        command =       "seq_kill";
        usage =         "<seq_name>";
        description =   "kill the specified sequence";
        // -------------------------------------------------------------- 
    endfunction

    task parse_args(string args[$]);
        seq_util.seq_kill(args[1]);
    endtask
endclass: debug_command_seq_kill

// -------------------------------------------------------------- 
// add debug commands
// -------------------------------------------------------------- 
function void uvm_debug_seq_util::add_debug_commands();
    debug_command_seq_util_cb new_dbg_cmd;

    new_dbg_cmd = debug_command_seq_list::type_id::create("seq_list");
    dbg_cmd.push_back(new_dbg_cmd);
    new_dbg_cmd = debug_command_seq_create::type_id::create("seq_create");
    dbg_cmd.push_back(new_dbg_cmd);
    new_dbg_cmd = debug_command_seq_rand::type_id::create("seq_rand");
    dbg_cmd.push_back(new_dbg_cmd);
    new_dbg_cmd = debug_command_seq_set_fields::type_id::create("seq_set_fields");
    dbg_cmd.push_back(new_dbg_cmd);
    new_dbg_cmd = debug_command_seq_start::type_id::create("seq_start");
    dbg_cmd.push_back(new_dbg_cmd);
    new_dbg_cmd = debug_command_seq_kill::type_id::create("seq_kill");
    dbg_cmd.push_back(new_dbg_cmd);

    foreach (dbg_cmd[i]) begin
        dbg_cmd[i].seq_util = this;
    end

endfunction

