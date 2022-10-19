#include "main.h"

/*# 1- Identify the UART interface, GPIO pins and Alternate Function #########*/
/* For example:
 * B-L475E-IOT01A:
 * PB6     ------> USART1_TX
 * PB7     ------> USART1_RX
 * 
 * NUCLEO-L476RG:
 * PA2     ------> USART2_TX
 * PA3     ------> USART2_RX
 * 
 * STM32L4R9-DISCO:
 * PA2     ------> USART2_TX
 * PA3     ------> USART2_RX
 *
 * STM32H747I-DISCO:
 * PA9     ------> USART1_TX
 * PA10    ------> USART1_RX
 *
 */

/*# 2- Enable UART MODULE in Inc/stm32l4xx_hal_conf.h ########################*/
//#define HAL_UART_MODULE_ENABLED
/*# 3- From Drivers/STM32L4xx_HAL_Driver/Src/ add the HAL UART C sources
 to your project: stm32xxxx_hal_uart.c stm32xxxx_hal_uart_ex.c ############*/

/*# 4- Create Global UART Handle in Src/main.c ###############################*/
UART_HandleTypeDef log_uart_h;

/*# 5- Configure the UART interface in Src/main.c ############################*/

/**
 * @brief UART interface configuration
 */
void UART_Log_Init(void) {
#ifdef STM32L476xx
  log_uart_h.Instance = USART2;
#endif

#ifdef STM32L4R5xx
  log_uart_h.Instance = LPUART1;
#endif

  log_uart_h.Init.BaudRate = 115200;
  log_uart_h.Init.WordLength = UART_WORDLENGTH_8B;
  log_uart_h.Init.StopBits = UART_STOPBITS_1;
  log_uart_h.Init.Parity = UART_PARITY_NONE;
  log_uart_h.Init.Mode = UART_MODE_TX_RX;
  log_uart_h.Init.HwFlowCtl = UART_HWCONTROL_NONE;
  log_uart_h.Init.OverSampling = UART_OVERSAMPLING_16;
  log_uart_h.Init.OneBitSampling = UART_ONE_BIT_SAMPLE_DISABLE;
  log_uart_h.AdvancedInit.AdvFeatureInit = UART_ADVFEATURE_NO_INIT;
  if (HAL_UART_Init(&log_uart_h) != HAL_OK)
  {
    Error_Handler();
  }
}

/*# 6- Configure the UART GPIOs  in Src/stm32l4xx_hal_msp.c ##################*/
// Done with BSP_COM_Init.

/*# 7- Retarget printf to UART (std library and toolchain dependent) #########*/

#if defined(__GNUC__)
int _write(int fd, char *ptr, int len) {
  HAL_UART_Transmit(&log_uart_h, (uint8_t*) ptr, len, HAL_MAX_DELAY);
  return len;
}
#elif defined (__ICCARM__)
#include "LowLevelIOInterface.h"
size_t __write(int handle, const unsigned char * buffer, size_t size)
{
  HAL_UART_Transmit(&log_uart_h, (uint8_t *) buffer, size, HAL_MAX_DELAY);
  return size;
}
#elif defined (__CC_ARM)
int fputc(int ch, FILE *f)
{
  HAL_UART_Transmit(&log_uart_h, (uint8_t *)&ch, 1, HAL_MAX_DELAY);
  return ch;
}
#endif

// OR:

// Add syscalls.c with GCC

#ifdef __GNUC__
#define PUTCHAR_PROTOTYPE int __io_putchar(int ch)
#else
#define PUTCHAR_PROTOTYPE int fputc(int ch, FILE *f)
#endif /* __GNUC__ */

/**
 * @brief  Retargets the C library printf function to the USART.
 * @param  None
 * @retval None
 */
PUTCHAR_PROTOTYPE {
  HAL_UART_Transmit(&log_uart_h, (uint8_t*) &ch, 1, HAL_MAX_DELAY);
  return ch;
}
