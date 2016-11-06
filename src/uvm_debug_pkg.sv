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
//  uvm_debug package file 
// 
// -----------------------------------------------------------------------------

`ifndef UVM_DEBUG_PKG
`define UVM_DEBUG_PKG

`timescale 1ns/1ps
`include "uvm_macros.svh"

package uvm_debug_pkg;
  
    // UVM class library compiled in a package
    import uvm_pkg::*;

    // cluelib text package
    `include "cl_types.svh"
    `include "cl_util.svh"
    `include "cl_text.svh"
   
    `include "uvm_debug_core_util.sv"
    `include "uvm_debug_prompt.sv"
    `include "uvm_debug_reg_util.sv"
    `include "uvm_debug_seq_util.sv"

endpackage : uvm_debug_pkg
  
`include "uvm_debug_module.sv"
`endif
