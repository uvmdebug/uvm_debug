#UVM interactive debug library (uvm_debug)
**Horace Chan (horace.chan@microsemi.com)**

uvm_debug library is a free, open-source library writter in SystemVerilog and C (SV-DPI).  uvm_debug is provided under MIT license and it available on GitHub.

##Documents:
The PDF of the DVCON2017 titled "UVM Interactive Debug Library: Shortening the Debug Turnaround Time" is availabled at `doc/dvcon2017_uvm_debug_lib_final.pdf`

##Installation:
1. `git clone https://github.com/uvmdebug/uvm_debug`
2. Compile the .sv and .c files with the testbench
3. Instantiate the uvm_debug_module as a top level module

##Testbench Setup:
- See Section B of the PDF 

##Demo (ncsim only):
Run `>./demo.sh`
