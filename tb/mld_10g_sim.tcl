# Start of template
# # If the copied and modified template file is "mentor.do", run it
# # as: vsim -c -do mentor.do
# #
# Create a library
vlib fifo_170
#vlib altera_fpdsp_block_161
#vlib fp_dsp
#vlib fp_add
#vlib fifo_161
#vlib fifo_35x128
#vlib SR_35x69
#vlib altshift_taps_161
#vlib altera_iopll_161
#vlib iopll
# Set path
set PRO_DIR "/home/chunjie/workspace/mld/a10_soc/mld_10G_ethernet/mld_10g"
set PRO_CORE "/home/chunjie/workspace/mld/a10_soc/mld_10G_ethernet"
#set IP_DIR "/home/chunjie/*/altera_project/FAccel/IP/fp_dsp/sim"
set QSYS_SIMDIR "/home/chunjie/workspace/mld/a10_soc/*/IP"
# # Source the generated sim script
source msim_setup.tcl
##source $QSYS_SIMDIR/fp_add/sim/mentor/msim_setup.tcl
##source $QSYS_SIMDIR/fp_dsp/sim/mentor/msim_setup.tcl

# source msim_setup.tcl
# # Compile eda/sim_lib contents first
 dev_com
# # Override the top-level name (so that elab is useful)

# # Compile the standalone IP.
 com
# # Compile the user top-level
vlog -sv $PRO_DIR/rtl/tx_data_gen.sv
vlog -sv $PRO_DIR/rtl/rx_data_gen.sv
vlog -sv $PRO_DIR/rtl/data_source_gen.sv
vlog -sv $PRO_DIR/rtl/recv_data_buffer.sv
vlog -sv $PRO_DIR/rtl/send_data_buffer.sv
vlog -sv $PRO_DIR/rtl/emif_buffer.sv
vlog -sv $PRO_DIR/rtl/ddr3_emif_buffer.sv
vlog -sv $PRO_DIR/rtl/data_pool.sv
vlog -sv $PRO_DIR/tb/recv_data_buffer_tb.sv
vlog -sv $PRO_DIR/rtl/pattern_fetch_send.v
vlog -sv $PRO_DIR/rtl/display_vedio_generate_DMD_specific_faster.v
vlog -sv $PRO_DIR/tb/pattern_fetch_send_tb.sv
vlog -sv $PRO_DIR/tb/fast_pat_tb.sv
vlog -sv $PRO_DIR/rtl/fast_pat_fetch.v
vlog -sv $PRO_DIR/rtl/avl_data_gen.v
vlog -sv $PRO_DIR/rtl/recv_data_buffer_128in_32out.sv
vlog -sv $PRO_DIR/rtl/avalon_bridge_32bit_to_128bit.sv
vlog -sv $PRO_DIR/rtl/mac_frame_construct.sv
#vlog -sv $PRO_DIR/rtl/avalon_st_gen.v

vlog -v $PRO_CORE/core/eth_traffic_controller/*.v
vlog -v $PRO_CORE/core/eth_traffic_controller/crc32/*.v
vlog -v $PRO_CORE/core/eth_traffic_controller/crc32/crc32_lib/*.v


 set TOP_LEVEL_NAME recv_data_buffer_tb

# # Elaborate the design.
 elab
#run -a
#exit -code 0
do $PRO_DIR/modelsim/data_gen_wave.do
#ls radix hex
run 10 us
