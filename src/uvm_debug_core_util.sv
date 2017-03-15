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
//  Core util functions to parse user inputs
//
// -----------------------------------------------------------------------------

import "DPI-C" function void dpi_tcl_exec_cmd(string cmd);
import "DPI-C" function void dpi_read_line(string prompt, inout string line);
import "DPI-C" function void dpi_get_sbuffer(inout string line);

// data type
typedef int qint[$];

// -------------------------------------------------------------- 
//  util functions for debug prompt argument parsing
// -------------------------------------------------------------- 

// extract options in the arguments
//  store the options and value pair  into an associate array
//  support both "-<option> <value>" and "+<option>=<value>" format
//  if the option has no value, it is a flag, set value = 1
//  all option-value pairs must in the front of the argument list
//  this function removes the option-value pair the from the args dynamic array
function automatic void extract_options(ref string args[$], ref string options[string]);
    // pop the first argument, the command itself
    void'(args.pop_front());
    while (args.size() > 0) begin
        if (args[0][0] == "-") begin
            string option = args.pop_front();
            string key = option.substr(1,(option.len()-1));
            if (args[0][0] == "-" || args.size() == 0) begin
                // the argument is an option flag
                options[key] = "1";
            end else begin
                string value = args.pop_front();
                options[key] = value;
            end
        end else if (args[0][0] == "+") begin
            string option = args.pop_front();
            int index = text::index(option, "=");
            if (index == -1) begin
                // the argument is an option flag
                string key = option.substr(1,(option.len()-1));
                options[key] = "1";
            end else begin
                string key = option.substr(1,(index - 1));
                string value = option.substr((index+1),(option.len()-1));
                options[key] = value;
            end
        end else begin
            // first non option argument, stop extraction
            break;
        end
    end
endfunction

// check whether the option list has the specified flag
// this function does not modify the argument list
function automatic bit has_option_flag(string args[$], string flag);
    foreach (args[i]) begin
        if (uvm_is_match(flag, args[i])) begin
            return 1;
        end
    end
    return 0;
endfunction

// extract key-value pair in the arguments
//  store the "<key>=<value>" into an associate array
//  this function does not modify the argument list
function automatic void extract_keyvals(string args[$], ref string vals[string]);
    foreach(args[i]) begin
        int index = text::index(args[i], "=");
        if (index > 0) begin
            string key = args[i].substr(0,(index-1));
            string value = args[i].substr((index+1),(args[i].len()-1));
            vals[key] = value;
        end
    end
endfunction

// convert hex('h)/bin('d)/dec string to int
function automatic int str_to_int(string s);
    string s1;
    if (uvm_is_match("'h*", s)) begin
        // hex
        s1 = text::slice(s, 2);
        str_to_int = s1.atohex();
    end else if (uvm_is_match("'b*", s)) begin
        // bin
        s1 = text::slice(s, 2);
        str_to_int = s1.atobin();
    end else begin
        // dec
        str_to_int = s.atoi();
    end
endfunction

// covert string to list of integer
function automatic qint str_to_qint(string s);
    string value_list[$];
    str_to_qint.delete();
    uvm_split_string(s, ",", value_list);
    foreach (value_list[i]) begin
        string value_range[$];
        uvm_split_string(value_list[i], "..", value_range);
        if (value_range.size() == 1) begin
            str_to_qint.push_back(str_to_int(value_list[i]));
        end else begin
            int left_range = str_to_int(value_range[0]);
            int right_range = str_to_int(value_range[1]);
            int step = (left_range < right_range) ? 1 : -1;
            for (int j = left_range; j <= right_range; j = j + step) begin
                str_to_qint.push_back(j);
            end
        end
    end
endfunction

// covert integer to string
function automatic string itoa(int val);
    itoa.itoa(val);
endfunction

function automatic string hextoa(int val);
    hextoa.hextoa(val);
endfunction

function automatic string octtoa(int val);
    octtoa.octtoa(val);
endfunction

function automatic string bintoa(int val);
    bintoa.bintoa(val);
endfunction

function automatic string realtoa(real val);
    realtoa.realtoa(val);
endfunction

// covert queue of integer to string
function automatic string qitoa(int val[$]);
    qitoa = "";
    foreach (val[i]) begin
        qitoa = {qitoa, ((i>0)?",":""), itoa(val[i])};
    end
endfunction

// -------------------------------------------------------------- 
// util function for option and command line plus argument parsing
// --------------------------------------------------------------

// return an string value form the option list
function automatic string get_option_string(string options[string], string key, string default_value="");
    if (options.exists(key)) begin
        return options[key];
    end else begin
        return default_value;
    end
endfunction

// return an integer value from the option list
function automatic int get_option_int(string options[string], string key, int default_value=0);
    if (options.exists(key)) begin
        return str_to_int(options[key]);
    end else begin
        return default_value;
    end
endfunction

// return an integer list from the option list
function automatic qint get_option_int_list(string options[string], string key, qint default_value={});
    if (options.exists(key)) begin
        return str_to_qint(options[key]);
    end else begin
        return default_value;
    end
endfunction

// return an string value form the +arg
function automatic string get_arg_value_string(string match, string default_value="");
    string value;
    int num_match = uvm_cmdline_proc.get_arg_value(match, value);
    if (num_match > 0) begin
        return value;
    end else begin
        return default_value;
    end
endfunction

// return an integer value from the +arg
function automatic int get_arg_value_int(string match, int default_value=0);
    string value;
    int num_match = uvm_cmdline_proc.get_arg_value(match, value);
    if (num_match > 0) begin
        return value.atoi();
    end else begin
        return default_value;
    end
endfunction

// return an integer list from the +arg
// e.g. +channels=1,2,3,56,80
// note: no space between = and ,
function automatic qint get_arg_value_int_list(string match, qint default_value={});
    string value;
    int num_match = uvm_cmdline_proc.get_arg_value(match, value);
    if (num_match > 0) begin 
        return str_to_qint(value);
    end else begin
        return default_value;
    end
endfunction
