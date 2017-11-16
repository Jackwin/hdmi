// megafunction wizard: %LPM_MUX%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: lpm_mux 

// ============================================================
// File Name: source_selector.v
// Megafunction Name(s):
// 			lpm_mux
//
// Simulation Library Files(s):
// 			lpm
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 9.1 Build 350 03/24/2010 SP 2 SJ Full Version
// ************************************************************


//Copyright (C) 1991-2010 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions 
//and other software and tools, and its AMPP partner logic 
//functions, and any output files from any of the foregoing 
//(including device programming or simulation files), and any 
//associated documentation or information are expressly subject 
//to the terms and conditions of the Altera Program License 
//Subscription Agreement, Altera MegaCore Function License 
//Agreement, or other applicable license agreement, including, 
//without limitation, that your use is for the sole purpose of 
//programming logic devices manufactured by Altera and sold by 
//Altera or its authorized distributors.  Please refer to the 
//applicable agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module source_selector (
	data0x,
	data1x,
	sel,
	result);

	input	[38:0]  data0x;
	input	[38:0]  data1x;
	input	  sel;
	output	[38:0]  result;

	wire [38:0] sub_wire0;
	wire [38:0] sub_wire5 = data1x[38:0];
	wire [38:0] result = sub_wire0[38:0];
	wire  sub_wire1 = sel;
	wire  sub_wire2 = sub_wire1;
	wire [38:0] sub_wire3 = data0x[38:0];
	wire [77:0] sub_wire4 = {sub_wire5, sub_wire3};

	lpm_mux	lpm_mux_component (
				.sel (sub_wire2),
				.data (sub_wire4),
				.result (sub_wire0)
				// synopsys translate_off
				,
				.aclr (),
				.clken (),
				.clock ()
				// synopsys translate_on
				);
	defparam
		lpm_mux_component.lpm_size = 2,
		lpm_mux_component.lpm_type = "LPM_MUX",
		lpm_mux_component.lpm_width = 39,
		lpm_mux_component.lpm_widths = 1;


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix IV"
// Retrieval info: PRIVATE: SYNTH_WRAPPER_GEN_POSTFIX STRING "0"
// Retrieval info: CONSTANT: LPM_SIZE NUMERIC "2"
// Retrieval info: CONSTANT: LPM_TYPE STRING "LPM_MUX"
// Retrieval info: CONSTANT: LPM_WIDTH NUMERIC "39"
// Retrieval info: CONSTANT: LPM_WIDTHS NUMERIC "1"
// Retrieval info: USED_PORT: data0x 0 0 39 0 INPUT NODEFVAL data0x[38..0]
// Retrieval info: USED_PORT: data1x 0 0 39 0 INPUT NODEFVAL data1x[38..0]
// Retrieval info: USED_PORT: result 0 0 39 0 OUTPUT NODEFVAL result[38..0]
// Retrieval info: USED_PORT: sel 0 0 0 0 INPUT NODEFVAL sel
// Retrieval info: CONNECT: result 0 0 39 0 @result 0 0 39 0
// Retrieval info: CONNECT: @data 0 0 39 39 data1x 0 0 39 0
// Retrieval info: CONNECT: @data 0 0 39 0 data0x 0 0 39 0
// Retrieval info: CONNECT: @sel 0 0 1 0 sel 0 0 0 0
// Retrieval info: LIBRARY: lpm lpm.lpm_components.all
// Retrieval info: GEN_FILE: TYPE_NORMAL source_selector.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL source_selector.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL source_selector.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL source_selector.bsf TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL source_selector_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL source_selector_bb.v TRUE
// Retrieval info: LIB_FILE: lpm
