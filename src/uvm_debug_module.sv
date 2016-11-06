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
//  uvm_debug module 
// 
// -----------------------------------------------------------------------------

module uvm_debug;

    import uvm_debug_pkg::*;

    // --------------------------------------------------------------
    // debug prompt 
    // -------------------------------------------------------------- 
    bit trigger_prompt = 0;
    uvm_debug_util m_uvm_debug;

    initial begin
        m_uvm_debug = uvm_debug_util::get();
        // add tcl wrapper
        m_uvm_debug.exec_cmd({
            "proc debug_prompt args {\n",
            "    call debug_prompt $args\n",
            "    return [value uvm_debug.m_uvm_debug.rv]\n",
            "}"});
    end

    always @(posedge trigger_prompt) begin
        string cmd;
        dpi_get_sbuffer(cmd);
        m_uvm_debug.prompt(0, cmd);
        trigger_prompt = 0;
    end

endmodule: uvm_debug

