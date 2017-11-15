#include "../terasic_lib/terasic_includes.h"
#include "mcu.h"
#include "typedef.h"
#include "../terasic_lib/i2c.h"
#include "./HDMI_TX/it6613_drv.h"
//#include "it6605.h"
//chunjie add
#define HDMI_TX_I2C_CLOCK PIO_I2C_SCL_BASE
#define HDMI_TX_I2C_DATA PIO_I2C_SDA_BASE

#define Switch_HDMITX_Bank(x)   HDMITX_WriteI2C_Byte(0x0f,(x)&1)


static BOOL bEnableErrorF =  FALSE; //TRUE;

void OS_DelayMS(unsigned short ms){
    DelayMS(ms);
}

OS_TICK OS_GetTicks(void){
    return alt_nticks();
}

OS_TICK OS_TicksPerSecond(void){
    return alt_ticks_per_second();
}


void
DelayMS(unsigned short ms) 
{
#if 1
    usleep(ms*1000);  
#else        
    LARGE_INTEGER Freq ;
    LARGE_INTEGER Counter ;
    LARGE_INTEGER count,limit ;

    QueryPerformanceFrequency(&Freq) ;
    count.QuadPart = (ULONGLONG)ms * Freq.QuadPart / (ULONGLONG)1000 ;
    QueryPerformanceCounter(&Counter) ;
    limit.QuadPart = Counter.QuadPart + count.QuadPart ;

    while(limit.QuadPart > Counter.QuadPart)
    {
        QueryPerformanceCounter(&Counter) ;
    }
#endif    

    return ;
}

void
EnableDebugMessage(BOOL bEnable)
{
	bEnableErrorF = bEnable ;
}


void
ErrorF(char *fmt,...)
{
    va_list argp ;
	if(bEnableErrorF == 1)
	{
	    va_start(argp,fmt) ;
	    vfprintf(stdout,fmt,argp) ;
	    // vprintf(fmt,argp) ;
	    va_end(argp) ;
    }
}

void OS_PRINTF(char *fmt,...){
    static alt_u32 BootTime = 0;
    alt_u32 TimeStamp;
    va_list argp ;
  //  if(bEnableErrorF == 1)
    {
        va_start(argp,fmt) ;
        TimeStamp = alt_nticks() - BootTime;
        printf("[TERASIC-%05d.%03d]", (int)(TimeStamp/alt_ticks_per_second()), (int)(TimeStamp%alt_ticks_per_second()));
        vfprintf(stdout,fmt,argp) ;
        // vprintf(fmt,argp) ;
        va_end(argp) ;
    }    
}


void HDMITX_Reset(void){
    OS_PRINTF("TX hardware Reset\n");
    IOWR(HDMI_TX_RST_N_BASE, 0, 1);
    usleep(20*1000);
    IOWR(HDMI_TX_RST_N_BASE, 0, 0);
    usleep(20*1000);
    IOWR(HDMI_TX_RST_N_BASE, 0, 1);
    usleep(20*1000);
}


void HDMITX_DumpAllReg(void){
    
    alt_u8 data;
    int i;
//    for(i=0x10;i<=0x19;i++){
    for(i=0;i< 256;i++){
        data = HDMITX_ReadI2C_Byte(i);
        OS_PRINTF("TX Reg[%02Xh] = %02Xh\n", i, data);
        usleep(20*1000);  // wait uart dump finish
    }        
}

void HDMITX_DumpReg(int RegIndex){
    alt_u8 data;
    if (RegIndex >= 0x130){
        alt_u8 MappedReg = RegIndex;
        Switch_HDMITX_Bank(1);
        data = HDMITX_ReadI2C_Byte(MappedReg);
        Switch_HDMITX_Bank(0);
        OS_PRINTF("TX Reg[%03Xh] = %02Xh\n", RegIndex, data);
    }else{
        data = HDMITX_ReadI2C_Byte(RegIndex);
        OS_PRINTF("TX Reg[%02Xh] = %02Xh\n", RegIndex, data);
    }        
}


BYTE
HDMITX_ReadI2C_Byte(BYTE RegAddr)
{
	//return I2C_Read_Byte(HDMI_TX_I2C_SLAVE_ADDR,RegAddr) ;
    BYTE Value;
    HDMITX_ReadI2C_ByteN(RegAddr, &Value, 1);
    return Value;    
}

SYS_STATUS
HDMITX_WriteI2C_Byte(BYTE RegAddr,BYTE Data)
{
   // if ((RegAddr >= 0xE0 && RegAddr <= 0xE6) || (RegAddr >= 0x191 && RegAddr <= 0x199)){
    //    OS_PRINTF("audio ------------------ Write Reg[%02Xh]=%02Xh\n", RegAddr, Data);
    //}        
	//return I2C_Write_Byte(HDMI_TX_I2C_SLAVE_ADDR,RegAddr,Data) ;
    return HDMITX_WriteI2C_ByteN(RegAddr, &Data, 1);
}

SYS_STATUS
HDMITX_ReadI2C_ByteN(BYTE RegAddr,BYTE *pData,int N)
{
	//return I2C_Read_ByteN(HDMI_TX_I2C_SLAVE_ADDR,RegAddr,pData,N) ;
    bool bSuccess = TRUE;
    int i;
    for(i=0;i<N && bSuccess;i++){
        bSuccess = I2C_Read(HDMI_TX_I2C_CLOCK, HDMI_TX_I2C_DATA, HDMI_TX_I2C_SLAVE_ADDR, RegAddr+i, (alt_u8 *)(pData+i));
        //usleep(50); // wait
    }      
    return bSuccess?ER_SUCCESS:ER_FAIL;    
}

SYS_STATUS
HDMITX_WriteI2C_ByteN(BYTE RegAddr,BYTE *pData,int N)
{
	//return I2C_Write_ByteN(HDMI_TX_I2C_SLAVE_ADDR,RegAddr,pData,N) ;
    BOOL bSuccess = TRUE;
    int i;
    for(i=0;i<N && bSuccess;i++){
        bSuccess = I2C_Write(HDMI_TX_I2C_CLOCK, HDMI_TX_I2C_DATA, HDMI_TX_I2C_SLAVE_ADDR, RegAddr+i, *(pData+i));
    }        
    return bSuccess?ER_SUCCESS:ER_FAIL;       
}


#if 0 // enable RX API


void HDMIRX_Reset(void){
    OS_PRINTF("RX hardware Reset\n");
    
    IOWR(HDMI_TX_RST_N_BASE, 0, 1);
    usleep(20*1000);
    IOWR(HDMI_TX_RST_N_BASE, 0, 0);
    usleep(20*1000);
    IOWR(HDMI_TX_RST_N_BASE, 0, 1);
    usleep(20*1000);
}

void HDMIRX_DumpReg(int RegIndex){
    alt_u8 data;
    data = HDMIRX_ReadI2C_Byte(RegIndex);
    OS_PRINTF("RX Reg[%02Xh] = %02Xh\n", RegIndex, data);
}

void HDMIRX_DumpAllReg(void){
    alt_u8 data;
    int i;
//    for(i=0x10;i<=0x19;i++){
    for(i=0;i< 256;i++){
        data = HDMIRX_ReadI2C_Byte(i);
        OS_PRINTF("RX Reg[%02Xh] = %02Xh\n", i, data);
        usleep(20*1000);  // wait uart dump finish
    }        
}


BYTE
HDMIRX_ReadI2C_Byte(BYTE RegAddr)
{
	//return I2C_Read_Byte(HDMI_RX_I2C_SLAVE_ADDR,RegAddr) ;
    BYTE Value;
    HDMIRX_ReadI2C_ByteN(RegAddr, &Value, 1);
    return Value;
}

SYS_STATUS
HDMIRX_WriteI2C_Byte(BYTE RegAddr,BYTE Data)
{
	//return I2C_Write_Byte(HDMI_RX_I2C_SLAVE_ADDR,RegAddr,Data) ;
    return HDMIRX_WriteI2C_ByteN(RegAddr, &Data, 1);
}

SYS_STATUS
HDMIRX_ReadI2C_ByteN(BYTE RegAddr,BYTE *pData,int N)
{
	//return I2C_Read_ByteN(HDMI_RX_I2C_SLAVE_ADDR,RegAddr,pData,N) ;
    bool bSuccess = TRUE;
    int i;
    for(i=0;i<N && bSuccess;i++){
        bSuccess = I2C_Read(HDMI_RX_I2C_CLOCK, HDMI_RX_I2C_DATA, HDMI_RX_I2C_SLAVE_ADDR, RegAddr+i, (alt_u8 *)(pData+i));
        //OS_PRINTF("==========> Read HDMI-RX Reg[%02Xh]=%02Xh\n", RegAddr+i, *(alt_u8 *)(pData+i));
        //usleep(50); // wait
    }      
    return bSuccess?ER_SUCCESS:ER_FAIL;
}

SYS_STATUS
HDMIRX_WriteI2C_ByteN(BYTE RegAddr,BYTE *pData,int N)
{
	//return I2C_Write_ByteN(HDMI_RX_I2C_SLAVE_ADDR,RegAddr,pData,N) ;
    BOOL bSuccess = TRUE;
    int i;
    for(i=0;i<N && bSuccess;i++){
        //OS_PRINTF("==========> Write HDMI-RX Reg[%02Xh]=%02Xh\n", RegAddr+i, *(pData+i));
        bSuccess = I2C_Write(HDMI_RX_I2C_CLOCK, HDMI_RX_I2C_DATA, HDMI_RX_I2C_SLAVE_ADDR, RegAddr+i, *(pData+i));
    }        
    return bSuccess?ER_SUCCESS:ER_FAIL;    
}

BOOL ReadRXIntPin(void)
{
    bool bIrq = FALSE;

    if ((IORD(HDMI_RX_IRQ_N_BASE, 0) & 0x01) == 0x00)
        bIrq = TRUE;
    
    return bIrq;
}

#endif


BYTE
I2C_Read_Byte(BYTE Addr,BYTE RegAddr)
{
    BYTE data ;
    I2C_Read_ByteN(Addr,RegAddr,&data,1)  ;
    return data ;
}

SYS_STATUS
I2C_Write_Byte(BYTE Addr,BYTE RegAddr,BYTE Data)
{
    return I2C_Write_ByteN(Addr,RegAddr,&Data,1) ;
}

SYS_STATUS
I2C_Read_ByteN(BYTE Addr,BYTE RegAddr,BYTE *pData,int N)
{
#if 1
    BOOL bSuccess = TRUE;
    #if 1
        int i;
        for(i=0;i<N && bSuccess;i++){
            bSuccess = I2C_Read(HDMI_TX_I2C_CLOCK, HDMI_TX_I2C_DATA, Addr, RegAddr+i, (alt_u8 *)(pData+i));
            //usleep(50); // wait
        }    
    #else
        bSuccess = I2C_MultipleRead(HDMI_TX_I2C_CLOCK, HDMI_TX_I2C_DATA, Addr, RegAddr, (alt_u8 *)pData, (alt_u16)N);
    #endif
    return bSuccess?ER_SUCCESS:ER_FAIL;
#else    
    SYS_STATUS err = ER_FAIL ;
    BOOL bRc ;
    I2C_BUFF inI2C_Buff ;
    ULONG bytesReturned ;
    HANDLE hDevice ;

    // ErrorF("HDMITX_ReadI2C_Byte: read %d bytes from [%02X]\n",N,RegAddr) ;

    hDevice = CreateFile(szDosServiceLocation ,
            GENERIC_READ | GENERIC_WRITE,
            0,
            NULL,
            CREATE_ALWAYS,
            FILE_ATTRIBUTE_NORMAL,
            NULL);

    if (hDevice == INVALID_HANDLE_VALUE){
        ErrorF("Error: CreatFile Failed : %d\n",GetLastError());
        return ER_FAIL;
    }


    inI2C_Buff.ucAddr = Addr | FLAG_I2C_REG_READ ;
    inI2C_Buff.ucReg = (UCHAR)RegAddr ;
    inI2C_Buff.usCount = (USHORT)N ;

    // ErrorF("inI2C_Buff.ucAddr = %02X ucReg = %02X usCount = %d\n",inI2C_Buff.ucAddr,inI2C_Buff.ucReg,inI2C_Buff.usCount) ;

    bRc = DeviceIoControl(
            hDevice,
            IOCTL_IOACCESS_PRN_I2CACCESS,
            &inI2C_Buff,sizeof(inI2C_Buff),
            pData,N*sizeof(UCHAR) ,
            &bytesReturned,
            NULL) ;

    if(!bRc)
    {
        ErrorF("Device IO Control call failed. bytesReturned = %d\n",bytesReturned) ;
    }
    else
    {
        /*
        ErrorF("Device IO Control IOCTL_IOACCESS_PRN_I2CACCESS called successfully,returned %d bytes\ngot ",bytesReturned) ;
        for(i = 0 ;i < N ; i++)
        {
            ErrorF("%02X ",pData[i]) ;
        }
        ErrorF("\n") ;
        */
        err = ER_SUCCESS ;
    }

    CloseHandle (hDevice);

    return err ;
#endif    
}

SYS_STATUS
I2C_Write_ByteN(BYTE Addr,BYTE RegAddr,BYTE *pData,int N)
{
#if 1
    BOOL bSuccess = TRUE;
    int i;
    for(i=0;i<N && bSuccess;i++){
        bSuccess = I2C_Write(HDMI_TX_I2C_CLOCK, HDMI_TX_I2C_DATA, Addr, RegAddr, *(pData+i));
    }        
    return bSuccess?ER_SUCCESS:ER_FAIL;
#else    
    SYS_STATUS err = ER_FAIL ;
    HANDLE hDevice ;
    int i;
    BOOL bRc ;
    ULONG  Value ;
    I2C_BUFF inI2C_Buff ;
    ULONG bytesReturned ;

    if(!pData)
    {
        return ER_FAIL ;
    }

    // ErrorF("HDMITX_WriteI2C_ByteN: Write %d bytes -> [%02X]\n",N,RegAddr) ;

    hDevice = CreateFile(szDosServiceLocation ,
            GENERIC_READ | GENERIC_WRITE,
            0,
            NULL,
            CREATE_ALWAYS,
            FILE_ATTRIBUTE_NORMAL,
            NULL);

    if (hDevice == INVALID_HANDLE_VALUE){
        ErrorF("Error: CreatFile Failed : %d\n",GetLastError());
        return ER_FAIL;
    }

	Addr &= ~1 ;

    inI2C_Buff.ucAddr = Addr | FLAG_I2C_REG_WRITE ;
    inI2C_Buff.ucReg = (UCHAR)RegAddr ;
    inI2C_Buff.usCount = (USHORT)N ;

    for(i = 0 ; i < N ; i++)
    {
        inI2C_Buff.ucData[i] = pData[i] ;
        // ErrorF("inI2C_Buff.ucData[%d] = %02x\n",i,pData[i]) ;
    }

    // ErrorF("inI2C_Buff.ucAddr = %02X ucReg = %02X usCount = %d\n",inI2C_Buff.ucAddr,inI2C_Buff.ucReg,inI2C_Buff.usCount) ;

    bRc = DeviceIoControl(
            hDevice,
            IOCTL_IOACCESS_PRN_I2CACCESS,
            &inI2C_Buff,sizeof(inI2C_Buff),
            &Value,sizeof(Value),
            &bytesReturned,
            NULL) ;

    if(!bRc)
    {
        ErrorF("Device IO Control call failed. bytesReturned = %d\n",bytesReturned) ;
    }
    else
    {
        // ErrorF("Device IO Control IOCTL_IOACCESS_PRN_I2CACCESS called successfully,returned %d bytes\n",bytesReturned) ;
        err = ER_SUCCESS ;
    }

    CloseHandle (hDevice);
    return err ;
#endif    
}

#define EEPROM_DEVICE_ADDR  0xA0
//chunjie comments
/*
bool HDMIRX_EEPROM0_WriteI2C_Byte(alt_u8 RegAddr,alt_u8 Data){
    bool bSuccess;
    bSuccess = I2C_Write(HDMI_RX0_EP_SCL_BASE, HDMI_RX0_EP_SDA_BASE, EEPROM_DEVICE_ADDR, RegAddr, Data);
    return bSuccess;
}

bool HDMIRX_EEPROM1_WriteI2C_Byte(alt_u8 RegAddr,alt_u8 Data){
    bool bSuccess;
    bSuccess = I2C_Write(HDMI_RX1_EP_SCL_BASE, HDMI_RX1_EP_SDA_BASE, EEPROM_DEVICE_ADDR, RegAddr, Data);
    return bSuccess;
}

bool HDMIRX_EEPROM0_ReadI2C_Byte(alt_u8 RegAddr, alt_u8 *pData){
    bool bSuccess;
    bSuccess = I2C_Read(HDMI_RX0_EP_SCL_BASE, HDMI_RX0_EP_SDA_BASE, EEPROM_DEVICE_ADDR, RegAddr, pData);
    return bSuccess;    
}

bool HDMIRX_EEPROM1_ReadI2C_Byte(alt_u8 RegAddr, alt_u8 *pData){
    bool bSuccess;
    bSuccess = I2C_Read(HDMI_RX1_EP_SCL_BASE, HDMI_RX1_EP_SDA_BASE, EEPROM_DEVICE_ADDR, RegAddr, pData);
    return bSuccess;    
}
*/

