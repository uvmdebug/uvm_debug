#!/bin/tcsh -f

irun \
-access rw \
-linedebug \
-uvmlinedebug \
-uvmhome CDNS-1.2 \
+UVM_VERBOSITY=UVM_LOW \
-gui \
-incdir ../apb \
-incdir vip \
-incdir ../../../src/ \
../../../src/uvm_debug_pkg.sv \
-Wcxx -fPIC \
../../../src/uvm_debug_dpi.c \
tb_top.sv test.sv \
+debug_level=1
