/**
 * @file pdcs_misc.h
 * @author  Nhat Pham <nhat.pham@cs.ox.ac.uk>.
 * @version 0.1
 * @date 06-Sep-2021
 * @brief This contains misc. functions.
 */

#include "pdcs_misc.h"
#include "stm32l4xx_hal.h"

static uint16_t InterruptDisabledCount = 0;

/*----------------------------------------------------------------------------*/
void pdcs_disable_irqs(void) {
  /* Disable interrupts */
  __disable_irq();

  /* Increase number of disable interrupt function calls */
  InterruptDisabledCount++;
}

/*----------------------------------------------------------------------------*/
uint8_t pdcs_enable_irqs(void) {
  /* Decrease number of disable interrupt function calls */
  if (InterruptDisabledCount) {
    InterruptDisabledCount--;
  }

  /* Check if we are ready to enable interrupts */
  if (!InterruptDisabledCount) {
    /* Enable interrupts */
    __enable_irq();
  }

  /* Return interrupt enabled status */
  return !InterruptDisabledCount;
}

/*----------------------------------------------------------------------------*/
uint16_t buffer_to_uint16(uint8_t *buffer) {
  uint16_t ret_val;

  ret_val = (*(buffer + 1)) | (*(buffer) << 8);

  return ret_val;
}

/*----------------------------------------------------------------------------*/
uint32_t buffer_to_uint32(uint8_t *buffer) {
  uint32_t ret_val;

  ret_val = (*(buffer + 3)) | (*(buffer + 2) << 8) | (*(buffer + 1) << 16)
      | (*(buffer) << 24);

  return ret_val;
}

/*----------------------------------------------------------------------------*/
uint32_t buffer_to_uint24(uint8_t *buffer) {
  uint32_t ret_val;

  ret_val = (*(buffer + 2)) | (*(buffer + 1) << 8) | (*(buffer) << 16);

  return ret_val;
}

/*----------------------------------------------------------------------------*/
uint64_t buffer_to_uint64(uint8_t *buffer) {
  uint64_t ret_val = 0;

  for (int count = 0; count < 8; count++) {
    ret_val |= (uint64_t) *(buffer + count) << ((7 - count) * 8);
  }

  return ret_val;
}

/*----------------------------------------------------------------------------*/
void uint16_to_buffer(uint16_t data, uint8_t *buffer) {
  *buffer = (uint8_t) (data >> 8);
  *(++buffer) = (uint8_t) (data);
}

/*----------------------------------------------------------------------------*/
void uint32_to_buffer(uint32_t data, uint8_t *buffer) {
  *buffer = (uint8_t) (data >> 24);
  *(++buffer) = (uint8_t) (data >> 16);
  *(++buffer) = (uint8_t) (data >> 8);
  *(++buffer) = (uint8_t) (data);
}

/*----------------------------------------------------------------------------*/
void uint24_to_buffer(uint32_t data, uint8_t *buffer) {
  *buffer = (uint8_t) (data >> 16);
  *(++buffer) = (uint8_t) (data >> 8);
  *(++buffer) = (uint8_t) (data);
}

/*----------------------------------------------------------------------------*/
void uint64_to_buffer(uint64_t data, uint8_t *buffer) {
  *buffer = (uint8_t) (data >> 56);
  *(++buffer) = (uint8_t) (data >> 48);
  *(++buffer) = (uint8_t) (data >> 40);
  *(++buffer) = (uint8_t) (data >> 32);
  *(++buffer) = (uint8_t) (data >> 24);
  *(++buffer) = (uint8_t) (data >> 16);
  *(++buffer) = (uint8_t) (data >> 8);
  *(++buffer) = (uint8_t) (data);
}

/*----------------------------------------------------------------------------*/
float buffer_to_float(uint8_t *buffer) {
  float ret_val;
  uint16_t dec;
  uint16_t frac;

  dec = buffer_to_uint16(buffer);
  buffer += 2;
  frac = buffer_to_uint16(buffer);

  ret_val = (float) dec;
  ret_val += ((float) frac) / 100;

  return ret_val;
}

/*----------------------------------------------------------------------------*/
void float_to_buffer(float data, uint8_t *buffer) {
  uint16_t dec, frac;

  dec = (uint16_t) data;
  frac = ((uint16_t) (data * 100)) % 100;

  uint16_to_buffer(dec, buffer);
  buffer += 2;
  uint16_to_buffer(frac, buffer);
}

