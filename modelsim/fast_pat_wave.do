onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group fast_pat_tb /fast_pat_tb/clk
add wave -noupdate -expand -group fast_pat_tb /fast_pat_tb/rst_n
add wave -noupdate -expand -group fast_pat_tb /fast_pat_tb/hsync_o_with_camera_format
add wave -noupdate -expand -group fast_pat_tb /fast_pat_tb/vsync_o_with_camera_format
add wave -noupdate -expand -group fast_pat_tb /fast_pat_tb/de_o
add wave -noupdate -expand -group fast_pat_tb /fast_pat_tb/hsync_o_with_hdmi_format
add wave -noupdate -expand -group fast_pat_tb /fast_pat_tb/vsync_o_with_hdmi_format
add wave -noupdate -expand -group fast_pat_tb /fast_pat_tb/de_o_with_hdmi_format
add wave -noupdate -expand -group fast_pat_tb /fast_pat_tb/de_o_first_offset_line
add wave -noupdate -expand -group fast_pat_tb /fast_pat_tb/display_vedio_left_offset
add wave -noupdate -expand -group fast_pat_tb /fast_pat_tb/frame_start_trig
add wave -noupdate -expand -group fast_pat_tb /fast_pat_tb/frame_busy
add wave -noupdate -expand -group fast_pat_tb /fast_pat_tb/frame_all_zeros
add wave -noupdate -expand -group fast_pat_tb /fast_pat_tb/de_with_all_zeros
add wave -noupdate -expand -group fast_pat_tb /fast_pat_tb/dmd_correct_15_pixles_slope
add wave -noupdate -expand -group fast_pat_tb /fast_pat_tb/dmd_flip_left_and_right
add wave -noupdate -expand -group fast_pat_tb /fast_pat_tb/frame_count
add wave -noupdate -expand -group fast_pat_tb /fast_pat_tb/h_sync
add wave -noupdate -expand -group fast_pat_tb /fast_pat_tb/v_sync
add wave -noupdate -expand -group fast_pat_tb /fast_pat_tb/de
add wave -noupdate -expand -group fast_pat_tb /fast_pat_tb/onchip_mem
add wave -noupdate -expand -group fast_pat_tb /fast_pat_tb/onchip_mem_select
add wave -noupdate -expand -group fast_pat_tb /fast_pat_tb/onchip_mem_read
add wave -noupdate -expand -group fast_pat_tb /fast_pat_tb/onchip_mem_addr
add wave -noupdate -expand -group fast_pat_tb /fast_pat_tb/onchip_mem_byte_enable
add wave -noupdate -expand -group fast_pat_tb /fast_pat_tb/onchip_mem_write_data
add wave -noupdate -expand -group fast_pat_tb /fast_pat_tb/onchip_mem_write
add wave -noupdate -expand -group fast_pat_tb /fast_pat_tb/onchip_mem_read_data
add wave -noupdate -expand -group fast_pat_tb /fast_pat_tb/pix_data_out
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/IDLE
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/INIT_READ_ONCHIP_MEM
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/READ_ONCHIP_MEM
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/HALT
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/clk
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/rst_n
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/onchip_mem_chip_select
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/onchip_mem_chip_read
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/onchip_mem_addr
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/onchip_mem_byte_enable
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/onchip_mem_write_data
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/onchip_mem_write
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/onchip_mem_read_data
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/frame_trig
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/frame_busy
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/h_sync_in
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/v_sync_in
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/de_in
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/pix_data_out
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/timer_ena
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/timer_out
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/timer_rst
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/state
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/mem_rd_cnt
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/mem_rd
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/mem_rd_valid
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/mem_sel
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/mem_addr
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/mem_data
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/cnt
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/line_cnt
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/h_sync_r
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/h_sync_p
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/v_sync_r
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/v_sync_p
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/de_r
add wave -noupdate -expand -group fast_pat_fetch /fast_pat_tb/fast_pat_fetch_inst/de_p
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/clk_i
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/rst_ni
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/hsync_o_with_camera_format
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/vsync_o_with_camera_format
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/de_o
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/hsync_o_with_hdmi_format
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/vsync_o_with_hdmi_format
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/de_o_with_hdmi_format
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/de_o_first_offset_line
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/display_vedio_left_offset
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/frame_start_trig
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/frame_busy
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/frame_all_zeros
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/de_with_all_zeros
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/dmd_correct_15_pixles_slope
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/dmd_flip_left_and_right
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/frame_count
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/r_pixel_cnt
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/r_line_cnt
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/s_hsync
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/s_vsync
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/s_de_phase
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/pixel_number
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/s_hsync_hdmi
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/s_vsync_hdmi
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/s_de
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/tmp1
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/tmp2
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/tmp3
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/tmp4
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/s_de_first_line
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/display_busy
add wave -noupdate -expand -group display_video /fast_pat_tb/display_vedio_generate_DMD_specific_faster_inst/s_vsync_dl
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 126
configure wave -valuecolwidth 40
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
WaveRestoreZoom {0 ps} {38773 ps}
