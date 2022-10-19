/**
 * @file pdcs_misc.h
 * @author  Nhat Pham <nhat.pham@cs.ox.ac.uk>.
 * @version 0.1
 * @date 06-Sep-2021
 * @brief This contains misc. functions.
 */

#ifndef PDCS_MISC_H_
#define PDCS_MISC_H_

#ifdef __cplusplus
extern "C" {
#endif

#include "stdint.h"

typedef enum pdcs_status {
  pdcs_ok = 0,

  // Generally referring to an error in the runtime.
  pdcs_error = -1,
} pdcs_status;

/**
 * @brief    Interrupt functions.
 */

/**
 * @brief  Disables all interrupts in system
 * @param  None
 * @retval None
 */
void pdcs_disable_irqs(void);

/**
 * @brief  Enables interrupts in system.
 * @note   This function has nesting support. This means that if you call @ref pdcs_disable_irqs() 4 times,
 *         then you have to call this function also 4 times to enable interrupts.
 * @param  None
 * @retval Interrupt enabled status:
 *            - 0: Interrupts were not enabled
 *            - > 0: Interrupts were enabled
 */
uint8_t pdcs_enable_irqs(void);

/**
 * @brief    Buffer related functions.
 */
uint16_t buffer_to_uint16(uint8_t *buffer); // LSByte first
uint32_t buffer_to_uint24(uint8_t *buffer); // LSByte first
uint32_t buffer_to_uint32(uint8_t *buffer); // LSByte first
uint64_t buffer_to_uint64(uint8_t *buffer); // LSByte first
void uint16_to_buffer(uint16_t data, uint8_t *buffer); // LSByte fisrt
void uint24_to_buffer(uint32_t data, uint8_t *buffer); // LSByte fisrt
void uint32_to_buffer(uint32_t data, uint8_t *buffer); // LSByte fisrt
void uint64_to_buffer(uint64_t data, uint8_t *buffer); // LSByte fisrt
float buffer_to_float(uint8_t *buffer); // dec-2byte, frac-2byte (2 digits)
void float_to_buffer(float data, uint8_t *buffer); // dec-2byte, frac-2byte (2 digits)

#ifdef __cplusplus
}
#endif

#endif /* PDCS_MISC_H_ */
