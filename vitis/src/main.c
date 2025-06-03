//assign crypt_start = GPIO_in[0];
//assign den_sel = GPIO_in[1]; // 0:en 1:de
//assign GPIO_out = {evlp_done,2'b0};

#include"string.h"
#include"stdio.h"
#include <stdlib.h>
#include"xbram_hw.h"
#include"xgpiops.h"

#define Data_Byte 4
#define CRYPT_START	54
#define DEN_SEL	55
#define CRYPT_DONE	56
#define RST_EMIO	57
#define GPIO_DEVICE_ID 0
/**
 	XUARTPS_OPER_MODE_NORMAL	    (u8)0x00U
	XUARTPS_OPER_MODE_AUTO_ECHO		(u8)0x01U
	XUARTPS_OPER_MODE_LOCAL_LOOP	(u8)0x02U
	XUARTPS_OPER_MODE_REMOTE_LOOP	(u8)0x03U
	XPAR_BRAM_0_BASEADDR 0x40000000U
**/

//XUartPs PsUart;
//u8 UartRecBuf[128];
//u32 UartSendLen = 0;


XGpioPs Gpio_Ps;

int main(){
	XGpioPs_Config *ConfigPtr;
	ConfigPtr = XGpioPs_LookupConfig(GPIO_DEVICE_ID);
	XGpioPs_CfgInitialize(&Gpio_Ps, ConfigPtr,ConfigPtr->BaseAddr);

	XGpioPs_SetDirectionPin(&Gpio_Ps, CRYPT_START, 1); //1OUT 0IN
	XGpioPs_SetOutputEnablePin(&Gpio_Ps, CRYPT_START, 1);

	XGpioPs_SetDirectionPin(&Gpio_Ps, DEN_SEL, 1); //1OUT 0IN
	XGpioPs_SetOutputEnablePin(&Gpio_Ps, DEN_SEL, 1);

	XGpioPs_SetDirectionPin(&Gpio_Ps, CRYPT_DONE, 0); //1OUT 0IN

	XGpioPs_SetDirectionPin(&Gpio_Ps, RST_EMIO, 1); //1OUT 0IN
	XGpioPs_SetOutputEnablePin(&Gpio_Ps, RST_EMIO, 1);


	while(1){
		for(int i = 0;i < 2048;i+=Data_Byte){
			int empty_data = 0;
			XBram_WriteReg(XPAR_BRAM_0_BASEADDR, i , empty_data);
					}
		XGpioPs_WritePin(&Gpio_Ps, RST_EMIO, 1);
		sleep(1);
		XGpioPs_WritePin(&Gpio_Ps, RST_EMIO, 0);

		printf("\nReady:");
		int cryptsel;
		scanf("%d",&cryptsel);
		if(cryptsel == 0){
			char msg_in[1024];
//			printf("\nType in message:\n");
			scanf("%s",msg_in);
			int msg_len;
			msg_len = strlen(msg_in);
			char en_wr_data[4];
			for(int i = 0;i < msg_len;i+=Data_Byte){
				en_wr_data[0] = msg_in[i];
				en_wr_data[1] = msg_in[i+1];
				en_wr_data[2] = msg_in[i+2];
				en_wr_data[3] = msg_in[i+3];
				XBram_WriteReg(XPAR_BRAM_0_BASEADDR, i+20 , *(unsigned int*)en_wr_data);
			}
			XGpioPs_WritePin(&Gpio_Ps, DEN_SEL, 0); //gpio_1 den_sel 0en 1de
			XGpioPs_WritePin(&Gpio_Ps, CRYPT_START, 1); //gpio_0 crypt_start
			XGpioPs_WritePin(&Gpio_Ps, CRYPT_START, 0);

			//-------等待PL加密完成返回GPIO-------//
			while (XGpioPs_ReadPin(&Gpio_Ps, CRYPT_DONE) != 1) {
			}
			print("\n");
			for(int i = 0;i<2048;i+=Data_Byte){
				int Byte4 = XBram_ReadReg(XPAR_BRAM_0_BASEADDR,i);
				if(Byte4 != 0x00000000){
					printf("%08x",Byte4);
			}
			}
		}
		else if(cryptsel == 1){
			uint32_t de_wr_data;
		    char hex_in[1024];
		    int hex_len;
			scanf("%s",hex_in);
			hex_len = strlen(hex_in);
			if (hex_len % 4 != 0) {
    	    printf("\n密码长度错误\n");
    	    return 1;
			}

			int data_index = 0;
			for (int i = 0; i < hex_len; i += 8) {
				// 提取两位十六进制字符
				char hex_byte[9] = {hex_in[i], hex_in[i+1],hex_in[i+2],hex_in[i+3],hex_in[i+4], hex_in[i+5],hex_in[i+6],hex_in[i+7],'\0'};

				// 转换为整数
				char *endptr = 0;
				de_wr_data = (uint32_t)strtoul(hex_byte, &endptr, 16);
				XBram_WriteReg(XPAR_BRAM_0_BASEADDR, i/2 , de_wr_data);
			}
				XGpioPs_WritePin(&Gpio_Ps, DEN_SEL, 1); //gpio_1 den_sel 0en 1de
				XGpioPs_WritePin(&Gpio_Ps, CRYPT_START, 1); //gpio_0 crypt_start
				XGpioPs_WritePin(&Gpio_Ps, CRYPT_START, 0);

				//-------等待PL加密完成返回GPIO-------//
				while (XGpioPs_ReadPin(&Gpio_Ps, CRYPT_DONE) != 1) {
				}
				print("\n");
				for(int i = 0;i<(hex_len-40)/2;i+=Data_Byte){
					uint32_t Byte_rd = XBram_ReadReg(XPAR_BRAM_0_BASEADDR,i);
					char str[5];  // 需要 4 字节 + 1 字节空字符 '\0' 结尾
					str[3] = (Byte_rd >> 24) & 0xFF;  // 提取最高字节
					str[2] = (Byte_rd >> 16) & 0xFF;
					str[1] = (Byte_rd >> 8) & 0xFF;
					str[0] = Byte_rd & 0xFF;  // 提取最低字节
					str[4] = '\0';  // 空字符终止符
					printf("%s",str);
				}

		}
	}
}
