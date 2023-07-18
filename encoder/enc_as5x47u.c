/*
	Copyright 2016 - 2022 Benjamin Vedder	benjamin@vedder.se
	Copyright 2022 Zach O'Brien

	This file is part of the VESC firmware.

	The VESC firmware is free software: you can redistribute it and/or modify
	 it under the terms of the GNU General Public License as published by
	 the Free Software Foundation, either version 3 of the License, or
	 (at your option) any later version.

	 The VESC firmware is distributed in the hope that it will be useful,
	 but WITHOUT ANY WARRANTY; without even the implied warranty of
	 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	 GNU General Public License for more details.

	 You should have received a copy of the GNU General Public License
	 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "enc_as5x47u.h"

#include "ch.h"
#include "hal.h"
#include "stm32f4xx_conf.h"
#include "hw.h"
#include "mc_interface.h"
#include "utils_math.h"
#include "spi_bb.h"
#include "timer.h"

#include <string.h>
#include <math.h>

#define AS5x47U_SPI_READ_BIT 								0x4000
#define AS5x47U_SPI_WRITE_BIT 								0x0000

#define AS5x47U_SPI_DIAG_FUSA_ERROR_BIT_POS					10
#define AS5x47U_SPI_DIAG_COF_BIT_POS						2
#define AS5x47U_SPI_DIAG_COMP_LOW_BIT_POS					3
#define AS5x47U_SPI_DIAG_COMP_HIGH_BIT_POS					4

#define AS5x47U_SPI_ERRFL_WDTST_BIT_POS						7
#define AS5x47U_SPI_ERRFL_CRC_ERROR_BIT_POS					6
#define AS5x47U_SPI_ERRFL_MAG_HALF_BIT_POS					1

#define AS5x47U_SPI_EXCLUDE_PARITY_AND_ERROR_BITMASK		0x3FFF
#define AS5x47U_SPI_AGC_MASK								0xFF
#define AS5x47U_SPI_WARN_FLAG_MASK							0x8000
#define AS5x47U_SPI_ERROR_FLAG_MASK							0x4000

#define AS5x47U_SPI_ERRFL_ADR								0x0001
#define AS5x47U_SPI_DIAG_ADR								0x3FF5
#define AS5x47U_SPI_MAGN_ADR								0x3FFD
#define AS5x47U_SPI_AGC_ADR									0x3FF9
#define AS5x47U_SPI_POS_ADR									0x3FFF

#define AS5x47U_SPI_READ_ERRFL_MSG			(AS5x47U_SPI_ERRFL_ADR | AS5x47U_SPI_READ_BIT)
#define AS5x47U_SPI_READ_DIAG_MSG			(AS5x47U_SPI_DIAG_ADR  | AS5x47U_SPI_READ_BIT)
#define AS5x47U_SPI_READ_MAGN_MSG			(AS5x47U_SPI_MAGN_ADR  | AS5x47U_SPI_READ_BIT)
#define AS5x47U_SPI_READ_AGC_MSG			(AS5x47U_SPI_AGC_ADR   | AS5x47U_SPI_READ_BIT)
#define AS5x47U_SPI_READ_POS_MSG			(AS5x47U_SPI_POS_ADR   | AS5x47U_SPI_READ_BIT)

#define AS5x47U_SPI_READ_ERRFL_CRC							(0x06)
#define AS5x47U_SPI_READ_DIAG_CRC							(0x6F)
#define AS5x47U_SPI_READ_MAGN_CRC							(0x87)
#define AS5x47U_SPI_READ_AGC_CRC							(0xF3)
#define AS5x47U_SPI_READ_POS_CRC							(0xBD)

#define AS5x47U_CONNECTION_DETERMINATOR_ERROR_THRESHOLD		100000000UL

typedef struct
{
	uint8_t start;
	uint8_t flags;
	uint16_t val;
	uint16_t chk;
}AS5x47U_UART_PKT;



bool enc_as5x47u_init(AS5x47U_config_t *cfg) {
	if (cfg->sd == NULL) {
			return false;
		}

		memset(&cfg->state, 0, sizeof(AS5x47U_state));


		sdStart(cfg->sd, &cfg->uart_param);
		palSetPadMode(cfg->TX_gpio, cfg->TX_pin,
				PAL_MODE_ALTERNATE(cfg->sd_af)  | PAL_STM32_OSPEED_HIGHEST);
		palSetPadMode(cfg->RX_gpio, cfg->RX_pin,
				PAL_MODE_ALTERNATE(cfg->sd_af) | PAL_STM32_OSPEED_HIGHEST | PAL_STM32_PUDR_PULLUP);
		palSetPadMode(cfg->DE_gpio, cfg->DE_pin, PAL_MODE_OUTPUT_PUSHPULL |
				PAL_STM32_OSPEED_HIGHEST);
		palSetPadMode(cfg->DBG_gpio, cfg->DBG_pin, PAL_MODE_OUTPUT_PUSHPULL |
						PAL_STM32_OSPEED_HIGHEST);
		palWritePad(cfg->DE_gpio,cfg->DE_pin,0);
		//palWritePad(cfg->DBG_gpio,cfg->DBG_pin,0);
	return true;
}

void enc_as5x47u_deinit(AS5x47U_config_t *cfg) {
	if (cfg->sd == NULL) {
			return;
		}

	sdStop(cfg->sd);
	palSetPadMode(cfg->TX_gpio, cfg->TX_pin, PAL_MODE_INPUT_PULLUP);
	palSetPadMode(cfg->RX_gpio, cfg->RX_pin, PAL_MODE_INPUT_PULLUP);
	palSetPadMode(cfg->DE_gpio, cfg->DE_pin, PAL_MODE_INPUT_PULLDOWN);
//	cfg->state.last_enc_angle = 0.0;
//	cfg->state.spi_error_rate = 0.0;
}

unsigned short as_crc_update (unsigned short crc, unsigned char data)
{
	data ^= (crc & 0xff);
	data ^= data << 4;

	return ((((unsigned short )data << 8) | ((crc>>8)&0xff)) ^ (unsigned char )(data >> 4)
			^ ((unsigned short )data << 3));
}

unsigned short as_crc16(void* data, unsigned short cnt)
{
	unsigned short crc=0xff;
	unsigned char * ptr=(unsigned char *) data;
	int i;

	for (i=0;i<cnt;i++)
	{
		crc=as_crc_update(crc,*ptr);
		ptr++;
	}
	return crc;
}

void enc_as5x47u_routine(AS5x47U_config_t *cfg) {
	static uint8_t state=0;
	static AS5x47U_UART_PKT uartPkt;
	if (cfg->state.timeout<1000)
	{
		cfg->state.timeout++;
		if (cfg->state.timeout>cfg->state.maxTimeout)
			cfg->state.maxTimeout=cfg->state.timeout;
	}
	while (chQSpaceI(&cfg->sd->iqueue)<sizeof(AS5x47U_UART_PKT))
		chThdSleep(1);
	//palWritePad(cfg->DBG_gpio,cfg->DBG_pin,1);
	msg_t res = sdGetTimeout(cfg->sd, TIME_IMMEDIATE);
	while ((res != MSG_TIMEOUT )) {

		switch(state)
		{
			case 0:
				if (res==0xAA)
				{
					state++;
					uartPkt.start=0xAA;
				}
			break;
			case 1:
				uartPkt.flags=res;
				state++;
			break;
			case 2:
				uartPkt.val=res;
				state++;
			break;
			case 3:
				uartPkt.val|=res<<8;
				state++;
			break;
			case 4:
				uartPkt.chk=res;
				state++;
			break;
			case 5:
				uartPkt.chk|=res<<8;


				if (as_crc16(&uartPkt.start,sizeof(AS5x47U_UART_PKT)-2)==uartPkt.chk)
				{
					cfg->state.pktOk++;
					if (uartPkt.flags==0x01)
					{
						cfg->state.rawValue=uartPkt.val;
//						float angleDiff=((float)(cfg->state.rawValue * 360) / (float)(1 << 14))-cfg->state.angle;
//						if(angleDiff>180.0f)
//							angleDiff-=360.0f;
//						if(angleDiff<-180.0f)
//							angleDiff+=360.0f;
//
//						angleDiff*=0.3f;
//						cfg->state.angle+=angleDiff;
//
//						if (cfg->state.angle>360.0f)
//							cfg->state.angle-=360.0f;
//
//						if (cfg->state.angle<0.0f)
//							cfg->state.angle+=360.0f;

						cfg->state.angle=((float)(cfg->state.rawValue * 360) / (float)(1 << 14));
						//
						cfg->state.timeout=0;
						cfg->state.timeoutGlobal=0;
					}else
						cfg->state.pktValErr++;
				}else
				{
					cfg->state.pktCrcErr++;
				}
//				else
//				{
//					//palWritePad(cfg->DE_gpio,cfg->DE_pin,1);
//					cfg->state.sensor_diag.serial_AGC_value++;
//					cfg->state.sensor_diag.is_Comp_high=uartPkt.start;
//					cfg->state.sensor_diag.is_broken_hall=uartPkt.flags;
//					cfg->state.sensor_diag.serial_error_flgs=uartPkt.val;
//					cfg->state.sensor_diag.serial_magnitude=uartPkt.chk;
//
//					cfg->state.sensor_diag.is_Comp_high=uartPkt.start;
//					//palWritePad(cfg->DE_gpio,cfg->DE_pin,0);
//				}

				state=0;
			break;
			default:
				state=0;
			break;


		}


			res = sdGetTimeout(cfg->sd, TIME_IMMEDIATE);

	}
	//palWritePad(cfg->DBG_gpio,cfg->DBG_pin,0);
	//		uint8_t reply[11];
	//		int reply_ind = 0;
	//
	//		msg_t res = sdGetTimeout(cfg->sd, TIME_IMMEDIATE);
	//		while (res != MSG_TIMEOUT ) {
	//			if (reply_ind < (int) sizeof(reply)) {
	//				reply[reply_ind++] = res;
	//			}
	//			res = sdGetTimeout(cfg->sd, TIME_IMMEDIATE);
	//		}

}

//static void AS5x47U_process_pos(AS5x47U_config_t *cfg, uint16_t posData) {
//	cfg->state.spi_val = posData;
//	posData &= AS5x47U_SPI_EXCLUDE_PARITY_AND_ERROR_BITMASK;
//	cfg->state.last_enc_angle = (float)(posData * 360) / (float)(1 << 14);
//}
