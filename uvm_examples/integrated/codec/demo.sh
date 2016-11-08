#!/bin/tcsh -f

irun \
-access rw \
-uvmhome CDNS-1.2 \
+UVM_VERBOSITY=UVM_LOW \
-gui \
-incdir ../apb \
-incdir vip \
tb_top.sv test.sv
