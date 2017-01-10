# register access
rd_addr 0
wr_reg regmodel.IntMask 0
wr_regfld regmodel.TxStatus.TxEn 0

# stop running sequences
seqr_stop_sequences env.vip.sqr                 

# send a sequence item
seq_item_create vip_tr tr
seq_item_rand tr
seq_item_set_fields tr chr='hff
seqr_execute_item env.vip.sqr tr

# start a new sequence
seq_create vip_idle_esc_seq idle_seq
seq_rand idle_seq
seq_start -priority 200 idle_seq env.vip.sqr
