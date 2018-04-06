onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group recv_data_buffer_tb /recv_data_buffer_tb/*

add wave -noupdate -group -hex tx_data_gen /recv_data_buffer_tb/tx_data_gen_i/*
add wave -noupdate -group -hex rx_data_gen /recv_data_buffer_tb/rx_data_gen_i/*
add wave -noupdate -group -hex recv_data_buffer /recv_data_buffer_tb/recv_data_buffer_i/*
add wave -noupdate -group -hex data_source_gen /recv_data_buffer_tb/data_source_gen_i/*
add wave -noupdate -group -hex avl_data_gen /recv_data_buffer_tb/avl_data_gen_i/*
add wave -noupdate -group -hex send_data_buffer /recv_data_buffer_tb/send_data_buffer_i/*

add wave -noupdate -group -hex emif_buffer /recv_data_buffer_tb/emif_buffer_i/*
add wave -noupdate -group -hex ddr3_emif_buffer /recv_data_buffer_tb/ddr3_emif_buffer_i/*
add wave -noupdate -group -hex data_pool_inst /recv_data_buffer_tb/data_pool_inst/*
add wave -noupdate -group -hex pattern_fetch_send_tb /recv_data_buffer_tb/pattern_fetch_send_tb_inst/*
add wave -noupdate -group -hex pattern_fetch_send /recv_data_buffer_tb/pattern_fetch_send_tb_inst/pattern_fetch_send_inst/*

add wave -noupdate -group -hex recv_data_buffer_128in_32out /recv_data_buffer_tb/recv_data_buffer_128in_32out_inst/*

add wave -noupdate -group -hex avalon_bridge_32bit_to_128bit /recv_data_buffer_tb/avalon_bridge_32bit_to_128bit_inst/*

add wave -noupdate -group -hex mac_frame_construct /recv_data_buffer_tb/mac_frame_construct_inst/*

add wave -noupdate -group -hex fast_pat_fetch /recv_data_buffer_tb/fast_pat_tb_inst/fast_pat_fetch_inst/*
add wave -position insertpoint  \
sim:/recv_data_buffer_tb/fast_pat_tb_inst/fast_pat_fetch_inst/pixel_out_data_r

add wave -noupdate -group -hex display_vedio_generate_DMD_specific_faster /recv_data_buffer_tb/fast_pat_tb_inst/display_vedio_generate_DMD_specific_faster_inst/*

add wave -noupdate -group -hex fast_pat_tb_inst /recv_data_buffer_tb/fast_pat_tb_inst/*

add wave -noupdate -group -hex avalon_frame_convert_inst /recv_data_buffer_tb/avalon_frame_convert_inst/*

##add wave -noupdate -group -hex display_vedio_generate_DMD_specific_faster /recv_data_buffer_tb/display_vedio_generate_DMD_specific_faster_inst/*

#wps_top_tb
add wave -noupdate -group -hex wps_top_tb /recv_data_buffer_tb/wps_top_tb_inst/*
add wave -noupdate -group -hex ddr3_usr_logic /recv_data_buffer_tb/wps_top_tb_inst/ddr3_usr_logic_inst/*

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {822400 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 397
configure wave -valuecolwidth 204
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {1648736 ps}
