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
// uvm_reg debug utilities
//  - unique reg name and unique field name lookup within the block
//  - debug command to write/read reg
//  - debug command to write/read reg field
//  - debug command to write/read address 
// -----------------------------------------------------------------------------


// base class for all reg_util debug commands
virtual class debug_command_reg_util_cb extends uvm_debug_command_cb;
    uvm_debug_reg_util reg_util;
    function new(string name = "debug_command_reg_util_cb");
       super.new(name);
    endfunction
endclass : debug_command_reg_util_cb

class uvm_debug_reg_util extends uvm_object;

    // boiler plate uvm code
    `uvm_object_utils(uvm_debug_reg_util)
    function new (string name = "uvm_debg_reg_util");
        super.new(name);
        add_debug_commands();
    endfunction : new

    // get uvm_debug singleton class
    uvm_debug_util uvm_debug = uvm_debug_util::get();
    debug_command_reg_util_cb dbg_cmd[$];

    // -------------------------------------------------------------- 
    // uvm_reg lookup table 
    // -------------------------------------------------------------- 
    uvm_reg_block   regmap;
    uvm_reg         regs[$];
    uvm_reg_field   fields[$];
    string          regs_path[];
    string          fields_path[];
    uvm_reg         regs_lut[string];
    uvm_reg_field   fields_lut[string];

    // setup the uvm_reg util with the top reg_block
    virtual function void set_top(uvm_reg_block top_regmap);
        int regs_size, fields_size;

        regmap = top_regmap;
        regmap.get_registers(regs);
        regmap.get_fields(fields);

        regs_path = new[regs.size()];
        fields_path = new[fields.size()];
        
        foreach (regs[i]) begin
            string short_name = regs[i].get_name();
            string full_name = regs[i].get_full_name();

            regs_lut[short_name] = regs[i];
            regs_lut[full_name] = regs[i];
            regs_path[i] = full_name;
        end

        foreach (fields[i]) begin
            string short_name = fields[i].get_name();
            string full_name = fields[i].get_full_name();
            string reg_name = fields[i].get_parent().get_name();

            int pos = text::index( reg_name, "[");
            short_name = {short_name, reg_name.substr(pos, reg_name.len() - 1 )};

            fields_lut[short_name] = fields[i];
            fields_lut[full_name] = fields[i];
            fields_path[i] = full_name;
        end
    endfunction: set_top

    // lookup reg from address offset
    function uvm_reg get_reg_by_offset(uvm_reg_addr_t addr);
        get_reg_by_offset = regmap.default_map.get_reg_by_offset(addr);
        if (get_reg_by_offset == null) begin
            `uvm_warning("UVM_DBG/REG_UTIL", {"addr: ", addr, " has no register"});
        end
    endfunction: get_reg_by_offset
 
    // lookup reg from short name
    function uvm_reg get_reg(string name, int range_m = -1, int range_n = -1);
        string key = name;
        if (range_m >= 0) begin
            key = {key, "[", itoa(range_m), "]"};
        end
        if (range_n >= 0) begin
            key = {key, "[", (range_m), "]"};
        end
        get_reg = regs_lut[key];
        if (get_reg == null) begin
            `uvm_warning("UVM_DBG/REG_UTIL", {"reg name: ", key, " not found"});
        end
    endfunction: get_reg

    // lookup field from name
    function uvm_reg_field get_field(string name, int range_m = -1, int range_n = -1);
        string key = name;
        if (range_m >= 0) begin
            key = {key, "[", itoa(range_m), "]"};
        end
        if (range_n >= 0) begin
            key = {key, "[", itoa(range_n), "]"};
        end
        get_field = fields_lut[key];
        if (get_field == null) begin
            `uvm_warning("UVM_DBG/REG_UTIL", {"reg_field name: ", key, " not found"});
        end
    endfunction: get_field

    // TODO: search reg from regex
    // TODO: search field from regex

    // -------------------------------------------------------------- 
    // register access function
    // -------------------------------------------------------------- 
    uvm_status_e    status;

    // write reg
    virtual task write_reg(uvm_reg target_reg, uvm_reg_data_t data);
        if (target_reg != null) begin
            `uvm_info("UVM_DBG/REG_UTIL", {"write ", target_reg.get_full_name(), " = 'h", hextoa(data)}, UVM_LOW);
            target_reg.write(status, data);
        end
    endtask : write_reg

    // read reg
    virtual task read_reg(uvm_reg target_reg);
        uvm_reg_data_t data;
        if (target_reg != null) begin
            target_reg.read(status, data);
            `uvm_info("UVM_DBG/REG_UTIL", {"read ", target_reg.get_full_name(), " = 'h", hextoa(data)}, UVM_LOW);
            uvm_debug.rv = itoa(data);
        end
    endtask : read_reg

    // write reg field
    virtual task write_regfld(uvm_reg_field target_field, uvm_reg_data_t data);
        if (target_field != null) begin
            `uvm_info("UVM_DBG/REG_UTIL", {"write ", target_field.get_full_name(), " = 'h", hextoa(data)}, UVM_LOW);
            target_field.write(status, data);
        end
    endtask
    
    // read reg field
    virtual task read_regfld(uvm_reg_field target_field);
        uvm_reg_data_t data;
        if (target_field != null) begin
            target_field.read(status, data);
            `uvm_info("UVM_DBG/REG_UTIL", {"read ", target_field.get_full_name(), " = 'h", hextoa(data)}, UVM_LOW);
            uvm_debug.rv = itoa(data);
        end
    endtask

    // -------------------------------------------------------------- 
    // add debug commands
    // -------------------------------------------------------------- 
    extern function void add_debug_commands();

endclass : uvm_debug_reg_util
 
// -------------------------------------------------------------- 
// uvm_reg debug commands
// -------------------------------------------------------------- 

class debug_command_wr_addr extends debug_command_reg_util_cb;
    uvm_debug_reg_util reg_util;

    `uvm_object_utils(debug_command_wr_addr)
    function new(string name = "debug_command_wr_addr");
        super.new(name);
        // -------------------------------------------------------------- 
        command =       "wr_addr";
        usage =         "<addr> <value>";
        description =   "write to the specify address";
        // -------------------------------------------------------------- 
    endfunction

    task parse_args(string args[$]);
        uvm_reg         target_reg = null;
        uvm_reg_addr_t  addr;
        uvm_reg_data_t  data;

        // resolve address
        addr = str_to_int(args[1]);
        data = str_to_int(args[2]);
        target_reg = reg_util.get_reg_by_offset(addr);
        reg_util.write_reg(target_reg, data);
    endtask
endclass: debug_command_wr_addr

class debug_command_rd_addr extends debug_command_reg_util_cb;
    uvm_debug_reg_util reg_util;

    `uvm_object_utils(debug_command_wr_addr)
    function new(string name = "debug_command_rd_addr");
        super.new(name);
        // -------------------------------------------------------------- 
        command =       "rd_addr";
        usage =         "<addr>";
        description =   "read from the specify address";
        // -------------------------------------------------------------- 
    endfunction

    task parse_args(string args[$]);
        uvm_reg         target_reg = null;
        uvm_reg_addr_t  addr;

        // resolve address
        addr = str_to_int(args[1]);
        target_reg = reg_util.get_reg_by_offset(addr);
        reg_util.read_reg(target_reg);
    endtask
endclass: debug_command_rd_addr

class debug_command_wr_reg extends debug_command_reg_util_cb;
    uvm_debug_reg_util reg_util;

    `uvm_object_utils(debug_command_wr_reg)
    function new(string name = "debug_command_wr_reg");
        super.new(name);
        // -------------------------------------------------------------- 
        command =       "wr_reg";
        usage =         "<reg> <value>";
        description =   "write to the specify register";
        // -------------------------------------------------------------- 
    endfunction

    task parse_args(string args[$]);
        uvm_reg         target_reg = null;
        uvm_reg_data_t  data;

        // resolve address
        data = str_to_int(args[2]);
        target_reg = reg_util.get_reg(args[1]);
        reg_util.write_reg(target_reg, data);
    endtask
endclass: debug_command_wr_reg

class debug_command_rd_reg extends debug_command_reg_util_cb;
    uvm_debug_reg_util reg_util;

    `uvm_object_utils(debug_command_rd_reg)
    function new(string name = "debug_command_rd_reg");
        super.new(name);
        // -------------------------------------------------------------- 
        command =       "rd_reg";
        usage =         "<reg>";
        description =   "read from the specify register";
        // -------------------------------------------------------------- 
    endfunction

    task parse_args(string args[$]);
        uvm_reg         target_reg = null;

        // resolve address
        target_reg = reg_util.get_reg(args[1]);
        reg_util.read_reg(target_reg);
    endtask
endclass: debug_command_rd_reg

class debug_command_wr_regfld extends debug_command_reg_util_cb;
    uvm_debug_reg_util reg_util;

    `uvm_object_utils(debug_command_wr_regfld)
    function new(string name = "debug_command_wr_regfld");
        super.new(name);
        // -------------------------------------------------------------- 
        command =       "wr_regfld";
        usage =         "<field> <value>";
        description =   "write to the specify register field";
        // -------------------------------------------------------------- 
    endfunction

    task parse_args(string args[$]);
        uvm_reg_field   target_field = null;
        uvm_reg_data_t  data;

        // resolve address
        data = str_to_int(args[2]);
        target_field = reg_util.get_field(args[1]);
        reg_util.write_regfld(target_field, data);
    endtask
endclass: debug_command_wr_regfld

class debug_command_rd_regfld extends debug_command_reg_util_cb;
    uvm_debug_reg_util reg_util;

    `uvm_object_utils(debug_command_rd_regfld)
    function new(string name = "debug_command_rd_regfld");
        super.new(name);
        // -------------------------------------------------------------- 
        command =       "rd_regfld";
        usage =         "<field>";
        description =   "read from the specify register field";
        // -------------------------------------------------------------- 
    endfunction

    task parse_args(string args[$]);
        uvm_reg_field   target_field = null;

        // resolve address
        target_field = reg_util.get_field(args[1]);
        reg_util.read_regfld(target_field);
    endtask
endclass: debug_command_rd_regfld

// -------------------------------------------------------------- 
// add debug commands
// -------------------------------------------------------------- 
function void uvm_debug_reg_util::add_debug_commands();
    debug_command_reg_util_cb new_dbg_cmd;

    new_dbg_cmd = debug_command_wr_addr::type_id::create("wr_addr");
    dbg_cmd.push_back(new_dbg_cmd);
    new_dbg_cmd = debug_command_rd_addr::type_id::create("rd_addr");
    dbg_cmd.push_back(new_dbg_cmd);
    new_dbg_cmd = debug_command_wr_reg::type_id::create("wr_reg");
    dbg_cmd.push_back(new_dbg_cmd);
    new_dbg_cmd = debug_command_rd_reg::type_id::create("rd_reg");
    dbg_cmd.push_back(new_dbg_cmd);
    new_dbg_cmd = debug_command_wr_regfld::type_id::create("wr_regfld");
    dbg_cmd.push_back(new_dbg_cmd);
    new_dbg_cmd = debug_command_rd_regfld::type_id::create("rd_regfld");
    dbg_cmd.push_back(new_dbg_cmd);

    foreach (dbg_cmd[i]) begin
        dbg_cmd[i].reg_util = this;
    end
endfunction

