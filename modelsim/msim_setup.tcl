
# (C) 2001-2017 Altera Corporation. All rights reserved.
# Your use of Altera Corporation's design tools, logic functions and
# other software and tools, and its AMPP partner logic functions, and
# any output files any of the foregoing (including device programming
# or simulation files), and any associated documentation or information
# are expressly subject to the terms and conditions of the Altera
# Program License Subscription Agreement, Altera MegaCore Function
# License Agreement, or other applicable license agreement, including,
# without limitation, that your use is for the sole purpose of
# programming logic devices manufactured by Altera and sold by Altera
# or its authorized distributors. Please refer to the applicable
# agreement for further details.

# ----------------------------------------
# Auto-generated simulation script msim_setup.tcl
# ----------------------------------------
# This script provides commands to simulate the following IP detected in
# your Quartus project:
#     fp_dsp.fp_dsp
#
# Altera recommends that you source this Quartus-generated IP simulation
# script from your own customized top-level script, and avoid editing this
# generated script.
#
# To write a top-level script that compiles Altera simulation libraries and
# the Quartus-generated IP in your project, along with your design and
# testbench files, copy the text from the TOP-LEVEL TEMPLATE section below
# into a new file, e.g. named "mentor.do", and modify the text as directed.
#
# ----------------------------------------
# # TOP-LEVEL TEMPLATE - BEGIN
# #
# # QSYS_SIMDIR is used in the Quartus-generated IP simulation script to
# # construct paths to the files required to simulate the IP in your Quartus
# # project. By default, the IP script assumes that you are launching the
# # simulator from the IP script location. If launching from another
# # location, set QSYS_SIMDIR to the output directory you specified when you
# # generated the IP script, relative to the directory from which you launch
# # the simulator.
# #
# set QSYS_SIMDIR <script generation output directory>
# #
# # Source the generated IP simulation script.
# source $QSYS_SIMDIR/mentor/msim_setup.tcl
# #
# # Set any compilation options you require (this is unusual).
# set USER_DEFINED_COMPILE_OPTIONS <compilation options>
# #
# # Call command to compile the Quartus EDA simulation library.
# dev_com
# #
# # Call command to compile the Quartus-generated IP simulation files.
# com
# #
# # Add commands to compile all design files and testbench files, including
# # the top level. (These are all the files required for simulation other
# # than the files compiled by the Quartus-generated IP simulation script)
# #
# vlog <compilation options> <design and testbench files>
# #
# # Set the top-level simulation or testbench module/entity name, which is
# # used by the elab command to elaborate the top level.
# #
# set TOP_LEVEL_NAME <simulation top>
# #
# # Set any elaboration options you require.
# set USER_DEFINED_ELAB_OPTIONS <elaboration options>
# #
# # Call command to elaborate your design and testbench.
# elab
# #
# # Run the simulation.
# run -a
# #
# # Report success to the shell.
# exit -code 0
# #
# # TOP-LEVEL TEMPLATE - END
# ----------------------------------------
#
# IP SIMULATION SCRIPT
# ----------------------------------------
# If fp_dsp.fp_dsp is one of several IP cores in your
# Quartus project, you can generate a simulation script
# suitable for inclusion in your top-level simulation
# script by running the following command line:
#
# ip-setup-simulation --quartus-project=<quartus project>
#
# ip-setup-simulation will discover the Altera IP
# within the Quartus project, and generate a unified
# script which supports all the Altera IP within the design.
# ----------------------------------------
# ACDS 17.0 196 linux 2017.03.23.14:45:07

# ----------------------------------------
# Initialize variables
if ![info exists SYSTEM_INSTANCE_NAME] {
  set SYSTEM_INSTANCE_NAME ""
} elseif { ![ string match "" $SYSTEM_INSTANCE_NAME ] } {
  set SYSTEM_INSTANCE_NAME "/$SYSTEM_INSTANCE_NAME"
}

if ![info exists TOP_LEVEL_NAME] {
  set TOP_LEVEL_NAME "fp_dsp.fp_dsp"
}

if ![info exists QSYS_SIMDIR] {
set QSYS_SIMDIR "/home/chunjie/workspace/mld/a10_soc/*/IP"
}

if ![info exists QUARTUS_INSTALL_DIR] {
  set QUARTUS_INSTALL_DIR "/home/share/tools/altera-pro/17.0/quartus/"
}

if ![info exists USER_DEFINED_COMPILE_OPTIONS] {
  set USER_DEFINED_COMPILE_OPTIONS ""
}
if ![info exists USER_DEFINED_VHDL_COMPILE_OPTIONS] {
  set USER_DEFINED_VHDL_COMPILE_OPTIONS ""
}
if ![info exists USER_DEFINED_VERILOG_COMPILE_OPTIONS] {
  set USER_DEFINED_VERILOG_COMPILE_OPTIONS ""
}
if ![info exists USER_DEFINED_ELAB_OPTIONS] {
  set USER_DEFINED_ELAB_OPTIONS ""
}

# ----------------------------------------
# Initialize simulation properties - DO NOT MODIFY!
set ELAB_OPTIONS ""
set SIM_OPTIONS ""
if ![ string match "*-64 vsim*" [ vsim -version ] ] {
} else {
}

# ----------------------------------------
# Copy ROM/RAM files to simulation directory
alias file_copy {
  echo "\[exec\] file_copy"
}

# ----------------------------------------
# Create compilation libraries
proc ensure_lib { lib } { if ![file isdirectory $lib] { vlib $lib } }
ensure_lib          ./libraries/
ensure_lib          ./libraries/work/
vmap       work     ./libraries/work/
vmap       work_lib ./libraries/work/
if ![ string match "*ModelSim ALTERA*" [ vsim -version ] ] {
  ensure_lib                   ./libraries/altera_ver/
  vmap       altera_ver        ./libraries/altera_ver/
  ensure_lib                   ./libraries/lpm_ver/
  vmap       lpm_ver           ./libraries/lpm_ver/
  ensure_lib                   ./libraries/sgate_ver/
  vmap       sgate_ver         ./libraries/sgate_ver/
  ensure_lib                   ./libraries/altera_mf_ver/
  vmap       altera_mf_ver     ./libraries/altera_mf_ver/
  ensure_lib                   ./libraries/altera_lnsim_ver/
  vmap       altera_lnsim_ver  ./libraries/altera_lnsim_ver/
  ensure_lib                   ./libraries/twentynm_ver/
  vmap       twentynm_ver      ./libraries/twentynm_ver/
  ensure_lib                   ./libraries/twentynm_hssi_ver/
  vmap       twentynm_hssi_ver ./libraries/twentynm_hssi_ver/
  ensure_lib                   ./libraries/twentynm_hip_ver/
  vmap       twentynm_hip_ver  ./libraries/twentynm_hip_ver/
}
#ensure_lib                        ./libraries/fifo_170/
#vmap       fifo_170 ./libraries/fifo_170/

#ensure_lib                        ./libraries/ram_2port_170/
#vmap       ram_2port_170 ./libraries/ram_2port_170/

#ensure_lib                   ./libraries/altshift_taps_170/
#vmap       altshift_taps_170 ./libraries/altshift_taps_170/

#ensure_lib              ./libraries/fifo_69x8192/
#vmap       fifo_69x8192 ./libraries/fifo_69x8192/
#ensure_lib              ./libraries/fifo_74in_37out/
#vmap       fifo_74in_37out ./libraries/fifo_74in_37out/
#ensure_lib                  ./libraries/fifo_512inx64out/
#vmap       fifo_512inx64out ./libraries/fifo_512inx64out/
#ensure_lib                  ./libraries/fifo_34inx64/
#vmap       fifo_34inx64 ./libraries/fifo_34inx64/
#ensure_lib                  ./libraries/dcfifo_33inx256/
#vmap       dcfifo_33inx256 ./libraries/dcfifo_33inx256/
#ensure_lib                  ./libraries/fifo_256in_32out/
#vmap       fifo_256in_32out ./libraries/fifo_256in_32out/
#ensure_lib                  ./libraries/fifo_256inx512/
#vmap       fifo_256inx512 ./libraries/fifo_256inx512/
#ensure_lib                  ./libraries/fifo_148in_37out/
#vmap       fifo_148in_37out ./libraries/fifo_148in_37out/
#ensure_lib                  ./libraries/fifo_135inx512/
#vmap       fifo_135inx512 ./libraries/fifo_135inx512/
#ensure_lib                  ./libraries/scfifo_37inx512/
#vmap       scfifo_37inx512 ./libraries/scfifo_37inx512/

#ensure_lib                  ./libraries/scfifo_32inx512/
#vmap       scfifo_32inx512 ./libraries/scfifo_32inx512/

#ensure_lib                  ./libraries/dpram_32inx64/
#vmap       dpram_32inx64 ./libraries/dpram_32inx64/
#ensure_lib                  ./libraries/dpram_135inx512/
#vmap       dpram_135inx512 ./libraries/dpram_135inx512/

#ensure_lib                  ./libraries/dpram_16inx16/
#vmap       dpram_16inx16 ./libraries/dpram_16inx16/
#ensure_lib                  ./libraries/shift_reg/
#vmap       shift_reg ./libraries/shift_reg/

#wps_top_tb
ensure_lib                  ./libraries/fifo_170/
#vmap       scfifo_288inx128 ./libraries/fifo_170/
#vmap       dcfifo_288inx128_9out ./libraries/fifo_170/
#vmap       dcfifo_8inx4096_16out ./libraries/fifo_170/

# ----------------------------------------
# Compile device library files
alias dev_com {
  echo "\[exec\] dev_com"
  if ![ string match "*ModelSim ALTERA*" [ vsim -version ] ] {
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_primitives.v"                 -work altera_ver
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/220model.v"                          -work lpm_ver
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/sgate.v"                             -work sgate_ver
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_mf.v"                         -work altera_mf_ver
    eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_lnsim.sv"                     -work altera_lnsim_ver
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/twentynm_atoms.v"                    -work twentynm_ver
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/mentor/twentynm_atoms_ncrypt.v"      -work twentynm_ver
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/mentor/twentynm_hssi_atoms_ncrypt.v" -work twentynm_hssi_ver
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/twentynm_hssi_atoms.v"               -work twentynm_hssi_ver
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/mentor/twentynm_hip_atoms_ncrypt.v"  -work tBwentynm_hip_ver
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/twentynm_hip_atoms.v"                -work twentynm_hip_ver
  }
}

# ----------------------------------------
# Compile the design files in correct order
alias com {
  echo "\[exec\] com"
    #eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/fifo_69x8192/fifo_170/sim/fifo_69x8192_fifo_170_cr3w5xa.v" -work fifo_170
    #eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/fifo_74in_37out/fifo_170/sim/fifo_74in_37out_fifo_170_xdsjzha.v" -work fifo_170
    #eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/fifo_512inx64out/fifo_170/sim/fifo_512inx64out_fifo_170_emnhebq.v" -work fifo_170
    #eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/fifo_34inx64/fifo_170/sim/fifo_34inx64_fifo_170_dfco2oy.v" -work fifo_170
    #eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/dcfifo_33inx256/fifo_170/sim/dcfifo_33inx256_fifo_170_dw7rzgi.v" -work fifo_170
   # eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/fifo_256in_32out/fifo_170/sim/fifo_256in_32out_fifo_170_66gptgq.v" -work fifo_170
    #eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/dcfifo_256inx512/fifo_170/sim/dcfifo_256inx512_fifo_170_3qhqjri.v" -work fifo_170
   # eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/fifo_148in_37out/fifo_170/sim/fifo_148in_37out_fifo_170_jb4i4ua.v" -work fifo_170
   # eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/dcfifo_135inx512/fifo_170/sim/dcfifo_135inx512_fifo_170_zzjchoy.v" -work fifo_170
   # eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/scfifo_37inx512/fifo_170/sim/scfifo_37inx512_fifo_170_rmas5za.v" -work fifo_170
   # eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/scfifo_32inx512/fifo_170/sim/scfifo_32inx512_fifo_170_b7ottha.v" -work fifo_170

    # wps_top_tb
   # eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/scfifo_288inx128/fifo_170/sim/scfifo_288inx128_fifo_170_i6fkd6y.v" -work fifo_170
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/scfifo_288inx128.v" -work fifo_170
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/dcfifo_288inx128_18out.v" -work fifo_170
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/scfifo_16inx8192.v" -work fifo_170
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/dcfifo_24inx512.v" -work fifo_170
   # eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/dpram_32inx64/ram_2port_170/sim/dpram_32inx64_ram_2port_170_polr63i.v" -work ram_2port_170
   # eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/dpram_135inx512/ram_2port_170/sim/dpram_135inx512_ram_2port_170_xj5kcoy.v" -work ram_2port_170
   # eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/dpram_16inx16/ram_2port_170/sim/dpram_16inx16_ram_2port_170_iols3si.v" -work ram_2port_170
   # eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/shift_reg/altshift_taps_170/sim/shift_reg_altshift_taps_170_yr7u2ry.v" -work altshift_taps_170

   # eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/fifo_69x8192/sim/fifo_69x8192.v" -work fifo_69x8192
   # eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/fifo_74in_37out/sim/fifo_74in_37out.v" -work fifo_74in_37out
   # eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/fifo_512inx64out/sim/fifo_512inx64out.v" -work fifo_512inx64out
   # eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/fifo_34inx64/sim/fifo_34inx64.v" -work fifo_34inx64
   # eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/dcfifo_33inx256/sim/dcfifo_33inx256.v" -work dcfifo_33inx256
   # eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/fifo_256in_32out/sim/fifo_256in_32out.v" -work fifo_256in_32out
   # eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/dcfifo_256inx512/sim/dcfifo_256inx512.v" -work fifo_256inx512
   # eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/fifo_148in_37out/sim/fifo_148in_37out.v" -work fifo_148in_37out
   # eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/dcfifo_135inx512/sim/dcfifo_135inx512.v" -work fifo_135inx512
   # eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/scfifo_37inx512/sim/scfifo_37inx512.v" -work scfifo_37inx512
   # eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/scfifo_32inx512/sim/scfifo_32inx512.v" -work scfifo_32inx512
   # eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/dpram_135inx512/sim/dpram_135inx512.v" -work dpram_135inx512
   # eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/dpram_16inx16/sim/dpram_16inx16.v" -work dpram_16inx16
  #  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/shift_reg/sim/shift_reg.v" -work shift_reg

    # wps_top_tb

}

# ----------------------------------------
# Elaborate top level design
alias elab {
  echo "\[exec\] elab"
  eval vsim -t ps $ELAB_OPTIONS $USER_DEFINED_ELAB_OPTIONS -L work -L work_lib -L fifo_170 -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L twentynm_ver -L twentynm_hssi_ver -L twentynm_hip_ver $TOP_LEVEL_NAME
}

# ----------------------------------------
# Elaborate the top level design with novopt option
alias elab_debug {
  echo "\[exec\] elab_debug"
  eval vsim -novopt -t ps $ELAB_OPTIONS $USER_DEFINED_ELAB_OPTIONS -L work -L work_lib -L altera_fpdsp_block_170 -L fp_dsp -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L twentynm_ver -L twentynm_hssi_ver -L twentynm_hip_ver $TOP_LEVEL_NAME
}

# ----------------------------------------
# Compile all the design files and elaborate the top level design
alias ld "
  dev_com
  com
  elab
"

# ----------------------------------------
# Compile all the design files and elaborate the top level design with -novopt
alias ld_debug "
  dev_com
  com
  elab_debug
"

# ----------------------------------------
# Print out user commmand line aliases
alias h {
  echo "List Of Command Line Aliases"
  echo
  echo "file_copy                     -- Copy ROM/RAM files to simulation directory"
  echo
  echo "dev_com                       -- Compile device library files"
  echo
  echo "com                           -- Compile the design files in correct order"
  echo
  echo "elab                          -- Elaborate top level design"
  echo
  echo "elab_debug                    -- Elaborate the top level design with novopt option"
  echo
  echo "ld                            -- Compile all the design files and elaborate the top level design"
  echo
  echo "ld_debug                      -- Compile all the design files and elaborate the top level design with -novopt"
  echo
  echo
  echo
  echo "List Of Variables"
  echo
  echo "TOP_LEVEL_NAME                -- Top level module name."
  echo "                                 For most designs, this should be overridden"
  echo "                                 to enable the elab/elab_debug aliases."
  echo
  echo "SYSTEM_INSTANCE_NAME          -- Instantiated system module name inside top level module."
  echo
  echo "QSYS_SIMDIR                   -- Qsys base simulation directory."
  echo
  echo "QUARTUS_INSTALL_DIR           -- Quartus installation directory."
  echo
  echo "USER_DEFINED_COMPILE_OPTIONS  -- User-defined compile options, added to com/dev_com aliases."
  echo
  echo "USER_DEFINED_VHDL_COMPILE_OPTIONS                 -- User-defined vhdl compile options, added to com/dev_com aliases."
  echo
  echo "USER_DEFINED_VERILOG_COMPILE_OPTIONS              -- User-defined verilog compile options, added to com/dev_com aliases."
  echo
  echo "USER_DEFINED_ELAB_OPTIONS     -- User-defined elaboration options, added to elab/elab_debug aliases."
}
file_copy
h
