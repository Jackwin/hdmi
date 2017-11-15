#ifndef _MCU_H_
#define _MCU_H_
#include "../terasic_lib/terasic_includes.h"
#include "alt_types.h"  // alt_u32
#include "system.h"


typedef int bit;

#ifndef NULL
    #define NULL    0
#endif    

void ErrorF(char *fmt,...);
//void EnableDebugMessage(BOOL bEnable);
void DelayMS(unsigned short ms);
void OS_PRINTF(char *fmt,...);
void OS_DelayMS(unsigned short ms);

void HDMITX_Reset(void);
void HDMIRX_Reset(void);
void HDMIRX_DumpAllReg(void);
void HDMIRX_DumpReg(int RegIndex);
void HDMITX_DumpAllReg(void);
void HDMITX_DumpReg(int RegIndex);



bool ReadRXIntPin(void);

//#define HDMI_TX_I2C_CLOCK   HDMI_TX_I2C_SCL_BASE
//#define HDMI_TX_I2C_DATA    HDMI_TX_I2C_SDA_BASE
//#define HDMI_RX_I2C_CLOCK   HDMI_RX_I2C_SCL_BASE
//#define HDMI_RX_I2C_DATA    HDMI_RX_I2C_SDA_BASE

bool HDMIRX_EEPROM0_WriteI2C_Byte(alt_u8 RegAddr,alt_u8 Data);
bool HDMIRX_EEPROM1_WriteI2C_Byte(alt_u8 RegAddr,alt_u8 Data);
bool HDMIRX_EEPROM0_ReadI2C_Byte(alt_u8 RegAddr, alt_u8 *pData);
bool HDMIRX_EEPROM1_ReadI2C_Byte(alt_u8 RegAddr, alt_u8 *pData);

// OS Tick API
typedef unsigned int OS_TICK;
OS_TICK OS_GetTicks(void);
OS_TICK OS_TicksPerSecond(void);


#endif /*_MCU_H_*/
