# house keeping functions
help
run 10ns
run 20ns
pause
call debug_prompt
history
repeat 1
history clear
history

# register access
rd_addr 0
rd_addr 4 

# load command file
history save demo1
read demo1

wr_addr 4 1
rd_addr 4 
rd_reg regmodel.IntMask 
wr_reg regmodel.IntMask 0
rd_reg regmodel.IntMask 
rd_regfld regmodel.TxStatus.TxEn
wr_regfld regmodel.TxStatus.TxEn 0
rd_regfld regmodel.TxStatus.TxEn

#rewind

# continue to demo sequence commands
continue
run 20000ns

# send a sequence item
seq_item_create vip_tr tr
seq_item_set_fields tr chr='hff
seqr_execute_item env.vip.sqr tr

run 20000ns

# start a new sequence
seq_create vip_my01_seq my01_seq
seq_rand my01_seq
seq_start -priority 200 -new_thread 1 my01_seq env.vip.sqr

run 20000ns

# set seqr arbitration
seqr_set_arbitration env.vip.sqr UVM_SEQ_ARB_STRICT_FIFO

run 20000ns

# kill the sequence
seq_kill my01_seq

run 20000ns

# stop all running sequences
seqr_stop_sequences env.vip.sqr                 

run 20000ns

# start another new sequence
seq_create vip_my55_seq my55_seq
seq_rand my55_seq
seq_start -priority 300 -new_thread 1 my55_seq env.vip.sqr

run 20000ns
