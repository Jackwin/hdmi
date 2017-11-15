// --------------------------------------------------------------------
// Copyright (c) 2007 by Terasic Technologies Inc. 
// --------------------------------------------------------------------
//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altera Development 
//   Kits made by Terasic.  Other use of this code, including the selling 
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL/Verilog or C/C++ source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Terasic provides no warranty regarding the use 
//   or functionality of this code.
//
// --------------------------------------------------------------------
//           
//                     Terasic Technologies Inc
//                     356 Fu-Shin E. Rd Sec. 1. JhuBei City,
//                     HsinChu County, Taiwan
//                     302
//
//                     web: http://www.terasic.com/
//                     email: support@terasic.com
//
// --------------------------------------------------------------------

// mode define
`define MODE_720x480    	0	// 480p,  	27		MHZ	   VIC=3
`define MODE_1024x768		1	// XGA,   	65		MHZ	 
`define MODE_1280x720p50    2   // 720p50 	74.25 	MHZ	   VIC=19
`define MODE_1280x720   	3	// 720p,  	74.25	MHZ	   VIC=4 
`define MODE_1280x1024		4	// SXGA,  	108		MHZ
`define MODE_1920x1080i		5	// 1080i, 	74.25	MHZ    VIC=5 
`define MODE_1920x1080i50	6	// 1080i, 	74.25	MHZ    VIC=20 
`define MODE_1920x1080		7	// 1080p, 	148.5	MHZ    VIC=16  
`define MODE_1920x1080p50	8	// 1080p50, 148.5	MHZ    VIC=31  
`define MODE_1600x1200		9	// UXGA,  	162		MHZ  
`define MODE_1920x1080i120	10	// 1080i120,148.5	MHZ    VIC=46


`define COLOR_RGB444	0
`define COLOR_YUV422	1
`define COLOR_YUV444	2
