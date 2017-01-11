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
// - debug command to create a new sequence / sequence item
// - debug command to randomize a new sequence / sequence item
// - debug command to set fields in sequence / sequence item
// - debug command to start/kill a sequence / execute an sequence item
// - debug command to stop all the sequences in a sequencer
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
    uvm_sequence_base seqs[string];

    // sequence item list
    uvm_sequence_item seq_items[string];

    // -------------------------------------------------------------- 
    // helper functions
    // -------------------------------------------------------------- 

    // list the created sequences
    virtual function void seq_list();
        foreach (seqs[seq_name]) begin
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
            seqs[seq_name] = seq;
            `uvm_info("UVM_DBG/SEQ_UTIL", {"new sequence created: ", seq_name}, UVM_LOW);
        end
    endfunction : seq_create

    // randomize a sequence
    virtual function void seq_rand(string seq_name);
        int rand_ok;
        uvm_sequence_base seq = seqs[seq_name];
        if (seq == null) begin
            `uvm_warning("UVM_DBG/SEQ_UTIL", {"sequence not found: ", seq_name});
        end else begin
            rand_ok = seq.randomize();
        end
    endfunction : seq_rand

    // set fields in the sequence
    virtual function void seq_set_fields(string seq_name, string vals[string]);
        uvm_sequence_base seq = seqs[seq_name];
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
        uvm_sequence_base seq = seqs[seq_name];
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
        uvm_sequence_base seq = seqs[seq_name];
        if (seq == null) begin
            `uvm_warning("UVM_DBG/SEQ_UTIL", {"sequence not found: ", seq_name});
        end else begin
            seq.kill();
        end
    endfunction : seq_kill
    
    // list the created sequence items
    virtual function void seq_item_list();
        foreach (seq_items[seq_item_name]) begin
            $display(" ", seq_item_name);
        end
    endfunction : seq_item_list

    // create a sequence 
    virtual function void seq_item_create(string seq_item_type, string seq_item_name);
        uvm_sequence_item seq_item;
        $cast(seq_item, factory.create_object_by_name(seq_item_type, get_full_name(), seq_item_name));
        if (seq_item == null) begin
            `uvm_warning("UVM_DBG/SEQ_UTIL", {"cannot create sequence item type: ", seq_item_type});
        end else begin
            seq_items[seq_item_name] = seq_item;
            `uvm_info("UVM_DBG/SEQ_UTIL", {"new sequence item created: ", seq_item_name}, UVM_LOW);
        end
    endfunction : seq_item_create

    // randomize a sequence item
    virtual function void seq_item_rand(string seq_item_name);
        int rand_ok;
        uvm_sequence_item seq_item = seq_items[seq_item_name];
        if (seq_item == null) begin
            `uvm_warning("UVM_DBG/SEQ_UTIL", {"sequence item not found: ", seq_item_name});
        end else begin
            rand_ok = seq_item.randomize();
        end
    endfunction : seq_item_rand

    // set fields in the sequence item
    virtual function void seq_item_set_fields(string seq_item_name, string vals[string]);
        uvm_sequence_item seq_item = seq_items[seq_item_name];
        if (seq_item == null) begin
            `uvm_warning("UVM_DBG/SEQ_UTIL", {"sequence item not found: ", seq_item_name});
        end else begin
            // set fields in the sequence item using tcl deposit
            foreach (vals[field]) begin
                string cmd;
                $sformat(cmd, "deposit @%0d.%s %s", seq_item, field, vals[field]);
                uvm_debug.exec_cmd(cmd); 
            end
        end
    endfunction : seq_item_set_fields

    // stop all sequences in the sequencer
    virtual function void seqr_stop_sequences(string seqr_path);
        uvm_sequencer_base seqr = uvm_sequencer_base'(uvm_top.find(seqr_path));
        if (seqr == null) begin
            `uvm_warning("UVM_DBG/SEQ_UTIL", {"sequencer not found: ", seqr_path});
        end else begin
            seqr.stop_sequences();
        end
    endfunction : seqr_stop_sequences

    // execute a sequence item in the sequencer
    virtual task seqr_execute_item(string seqr_path, string seq_item_name, bit new_thread = 0);
        uvm_sequence_item seq_item = seq_items[seq_item_name];
        if (seq_item == null) begin
            `uvm_warning("UVM_DBG/SEQ_UTIL", {"sequence item not found: ", seq_item_name});
        end else begin
            uvm_sequencer_base seqr = uvm_sequencer_base'(uvm_top.find(seqr_path));
            if (seqr == null) begin
                `uvm_warning("UVM_DBG/SEQ_UTIL", {"sequencer not found: ", seqr_path})
            end else begin
                if (new_thread == 0) begin
                    seqr.execute_item(seq_item);
                end else begin
                    fork
                        seqr.execute_item(seq_item);
                    join_none
                end
            end
        end
    endtask : seqr_execute_item

    // set sequence arbitration in the sequencer
    virtual function void seqr_set_arbitration(string seqr_path, uvm_sequencer_arb_mode arb_mode);
        uvm_sequencer_base seqr = uvm_sequencer_base'(uvm_top.find(seqr_path));
        if (seqr == null) begin
            `uvm_warning("UVM_DBG/SEQ_UTIL", {"sequencer not found: ", seqr_path});
        end else begin
            seqr.set_arbitration(arb_mode);
        end
    endfunction : seqr_set_arbitration

    // -------------------------------------------------------------- 
    // add debug commands
    // -------------------------------------------------------------- 
    extern function void add_debug_commands();

endclass : uvm_debug_seq_util

// -------------------------------------------------------------- 
// uvm_reg debug commands
// -------------------------------------------------------------- 

class debug_command_seq_list extends debug_command_seq_util_cb;
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

class debug_command_seq_item_list extends debug_command_seq_util_cb;
    `uvm_object_utils(debug_command_seq_item_list)
    function new(string name = "debug_command_seq_item_list");
        super.new(name);
        // -------------------------------------------------------------- 
        command =       "seq_item_list";
        usage =         "";
        description =   "list the created sequence items";
        // -------------------------------------------------------------- 
    endfunction

    task parse_args(string args[$]);
        seq_util.seq_item_list();
    endtask
endclass: debug_command_seq_item_list

class debug_command_seq_item_create extends debug_command_seq_util_cb;
    `uvm_object_utils(debug_command_seq_item_create)
    function new(string name = "debug_command_seq_item_create");
        super.new(name);
        // -------------------------------------------------------------- 
        command =       "seq_item_create";
        usage =         "<seq_item_type> <seq_item_name>";
        description =   "create a new sequence item";
        // -------------------------------------------------------------- 
    endfunction

    task parse_args(string args[$]);
        seq_util.seq_item_create(args[1], args[2]);
    endtask
endclass: debug_command_seq_item_create

class debug_command_seq_item_rand extends debug_command_seq_util_cb;
    `uvm_object_utils(debug_command_seq_item_rand)
    function new(string name = "debug_command_seq_item_rand");
        super.new(name);
        // -------------------------------------------------------------- 
        command =       "seq_item_rand";
        usage =         "<seq_item_name>";
        description =   "randomize the specified sequence item";
        // -------------------------------------------------------------- 
    endfunction

    task parse_args(string args[$]);
        seq_util.seq_item_rand(args[1]);
    endtask
endclass: debug_command_seq_item_rand

class debug_command_seq_item_set_fields extends debug_command_seq_util_cb;
    `uvm_object_utils(debug_command_seq_item_set_fields)
    function new(string name = "debug_command_seq_item_set_fields");
        super.new(name);
        // -------------------------------------------------------------- 
        command =       "seq_item_set_fields";
        usage =         "<seq_item_name> [<field>=<value>...]";
        description =   "set fields in the specified sequence item";
        // -------------------------------------------------------------- 
    endfunction

    task parse_args(string args[$]);
        string vals[string];        
        extract_keyvals(args, vals);
        seq_util.seq_item_set_fields(args[1], vals);
    endtask
endclass: debug_command_seq_item_set_fields

class debug_command_seqr_stop_sequences extends debug_command_seq_util_cb;
    `uvm_object_utils(debug_command_seqr_stop_sequences)
    function new(string name = "debug_command_seqr_stop_sequences");
        super.new(name);
        // -------------------------------------------------------------- 
        command =       "seqr_stop_sequences";
        usage =         "<seqr_path>";
        description =   "stop all sequences in the sequencer";
        // -------------------------------------------------------------- 
    endfunction

    task parse_args(string args[$]);
        seq_util.seqr_stop_sequences(args[1]);
    endtask
endclass: debug_command_seqr_stop_sequences

class debug_command_seqr_execute_item extends debug_command_seq_util_cb;
    `uvm_object_utils(debug_command_seqr_execute_item)
    function new(string name = "debug_command_seqr_execute_item");
        super.new(name);
        // -------------------------------------------------------------- 
        command =       "seqr_execute_item";
        usage =         "[-new_thread <0|1>] <seqr_path> <seq_item_name>";
        description =   "execute the sequence item in a sequencer";
        // -------------------------------------------------------------- 
    endfunction

    task parse_args(string args[$]);
        string options[string];
        int arg_priority;
        bit arg_new_thread;

        extract_options(args, options);
        arg_new_thread = get_option_int(options, "new_thread");
        seq_util.seqr_execute_item(args[0], args[1], arg_new_thread);
    endtask
endclass: debug_command_seqr_execute_item

class debug_command_seqr_set_arbitration extends debug_command_seq_util_cb;
    `uvm_object_utils(debug_command_seqr_set_arbitration)
    function new(string name = "debug_command_seqr_set_arbitration");
        super.new(name);
        // -------------------------------------------------------------- 
        command =       "seqr_set_arbitration";
        usage =         "<seqr_path> <seq_arb_type>";
        description =   "set sequence arbitration of the sequencer";
        // -------------------------------------------------------------- 
    endfunction

    task parse_args(string args[$]);
        string options[string];
        uvm_sequencer_arb_mode seq_arb_type;
        void'(uvm_enum_wrapper#(uvm_sequencer_arb_mode)::from_name(args[2], seq_arb_type));
        seq_util.seqr_set_arbitration(args[1], seq_arb_type);
    endtask
endclass: debug_command_seqr_set_arbitration

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
    new_dbg_cmd = debug_command_seq_item_list::type_id::create("seq_item_list");
    dbg_cmd.push_back(new_dbg_cmd);
    new_dbg_cmd = debug_command_seq_item_create::type_id::create("seq_item_create");
    dbg_cmd.push_back(new_dbg_cmd);
    new_dbg_cmd = debug_command_seq_item_rand::type_id::create("seq_item_rand");
    dbg_cmd.push_back(new_dbg_cmd);
    new_dbg_cmd = debug_command_seq_item_set_fields::type_id::create("seq_item_set_fields");
    dbg_cmd.push_back(new_dbg_cmd);
    new_dbg_cmd = debug_command_seqr_stop_sequences::type_id::create("seqr_stop_sequences");
    dbg_cmd.push_back(new_dbg_cmd);
    new_dbg_cmd = debug_command_seqr_execute_item::type_id::create("seqr_execute_item");
    dbg_cmd.push_back(new_dbg_cmd);
    new_dbg_cmd = debug_command_seqr_set_arbitration::type_id::create("seqr_set_arbitration");
    dbg_cmd.push_back(new_dbg_cmd);

    foreach (dbg_cmd[i]) begin
        dbg_cmd[i].seq_util = this;
    end

endfunction

