/**
 * @file audio_stream.cc
 * @author  Nhat Pham <nhat.pham@cs.ox.ac.uk>.
 * @version 0.1
 * @date 06-Sep-2021
 * @brief This file contains the abstraction for the audio stream. The implementation
 * is adapted from TFLite Micro.
 */

#include "math.h"
#include "streams/biosignals/biosignal_stream.h"

void pdcs_upsampling(int16_t* input_p, uint32_t input_size, uint32_t upsampling_factor, int16_t* output_p) {
  for (uint32_t in_index = 0; in_index < input_size; in_index++) {
    for (uint32_t up_factor_index = 0; up_factor_index < upsampling_factor; up_factor_index++) {
      output_p[in_index*upsampling_factor + up_factor_index] = input_p[in_index];
    }
  }
}

void pdcs_softmax(float32_t* input, size_t size, float32_t* output) {
  size_t i;
  float32_t m, sum, constant;

  m = -INFINITY;
  for (i = 0; i < size; ++i) {
    if (m < input[i]) {
      m = input[i];
    }
  }

  sum = 0.0;
  for (i = 0; i < size; ++i) {
    sum += exp(input[i] - m);
  }

  constant = m + log(sum);
  for (i = 0; i < size; ++i) {
    output[i] = exp(input[i] - constant);
  }

}
