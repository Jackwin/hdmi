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

#ifndef I2C_H_
#define I2C_H_
#include "terasic_includes.h"
#define SDA_DIR_IN(data_base)   IOWR_ALTERA_AVALON_PIO_DIRECTION(data_base,0)
#define SDA_DIR_OUT(data_base)  IOWR_ALTERA_AVALON_PIO_DIRECTION(data_base,1)
#define SDA_HIGH(data_base)     IOWR_ALTERA_AVALON_PIO_DATA(data_base, 1)
#define SDA_LOW(data_base)      IOWR_ALTERA_AVALON_PIO_DATA(data_base, 0)
#define SDA_READ(data_base)     IORD_ALTERA_AVALON_PIO_DATA(data_base)
#define SCL_DIR_IN(clk_base)    IOWR_ALTERA_AVALON_PIO_DIRECTION(clk_base,0)
#define SCL_DIR_OUT(clk_base)   IOWR_ALTERA_AVALON_PIO_DIRECTION(clk_base,1)
#define SCL_HIGH(clk_base)      IOWR_ALTERA_AVALON_PIO_DATA(clk_base, 1)
#define SCL_LOW(clk_base)       IOWR_ALTERA_AVALON_PIO_DATA(clk_base, 0)

#define SCL_DELAY    usleep(10)

void I2C_Open(alt_u32 clk_base, alt_u32 data_base);
void I2C_Close(alt_u32 clk_base, alt_u32 data_base);

bool I2C_Write(alt_u32 clk_base, alt_u32 data_base, alt_8 DeviceAddr, alt_u8 ControlAddr, alt_u8 ControlData);
bool I2C_Read(alt_u32 clk_base, alt_u32 data_base, alt_8 DeviceAddr, alt_u8 ControlAddr, alt_u8 *pControlData);
bool I2C_MultipleRead(alt_u32 clk_base, alt_u32 data_base, alt_u8 DeviceAddr, alt_u8 RegAddr, alt_u8 szData[], alt_u16 len);


#endif /*I2C_H_*/
