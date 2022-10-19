/**
 * @file sz_focal_pr.h
 * @author  Nhat Pham <nhat.pham@cs.ox.ac.edu>.
 * @version 0.1
 * @date 22-Feb-2022
 * @brief This contains definitions for the Focal Seizure pattern recognition primitive.
 */

#ifndef PDCS_SZ_FOCAL_H_
#define PDCS_SZ_FOCAL_H_

/* TF Lite Micro includes */
#include "tensorflow/lite/micro/all_ops_resolver.h"
#include "tensorflow/lite/micro/micro_error_reporter.h"
#include "tensorflow/lite/micro/micro_interpreter.h"
#include "tensorflow/lite/schema/schema_generated.h"

/* PDCS includes */
#include "pdcs_misc.h"
#include "streams/biosignals/preprocess/biosignal_mfcc.h"

class sz_focal_pr {
 public:
  sz_focal_pr();
  ~sz_focal_pr();

  /**
   * @brief  Initialise the pattern recognition object for absence seizure patterns.
   * @note   Currently, only 3s window, with MFCC feature size of 10x22 is supported.
   * @retval None
   */
  void init(tflite::ErrorReporter *global_error_reporter);
  /**
   * @brief   Predict whether the input signal is an absence seizure pattern or not.
   * @param   input_p, pointer to the extracted MFCC input (a 10x22 vector).
   * @retval  prediction probability.
   */
  float32_t recognise(float32_t *input_p, uint32_t input_buffer_size);

 private:
  int16_t *input_p; // MFCC features buffer.

  tflite::MicroInterpreter *model_interpreter = nullptr;
  const tflite::Model *pr_model = nullptr;
  TfLiteTensor *model_input = nullptr;
  TfLiteTensor *model_output = nullptr;

  tflite::ErrorReporter *error_reporter = nullptr; //A pointer to the global error reporter.
};

class sz_focal_int8_pr {
 public:
  sz_focal_int8_pr();
  ~sz_focal_int8_pr();

  /**
   * @brief  Initialise the pattern recognition object for absence seizure patterns.
   * @note   Currently, only 3s window, with MFCC feature size of 10x22 is supported.
   * @retval None
   */
  void init(tflite::ErrorReporter *global_error_reporter);
  /**
   * @brief   Predict whether the input signal is an absence seizure pattern or not.
   * @param   input_p, pointer to the extracted MFCC input (a 10x22 vector).
   * @retval  prediction probability.
   */
  int16_t recognise(float32_t *input_p, uint32_t input_buffer_size);

 private:
  int16_t *input_p; // MFCC features buffer.

  tflite::MicroInterpreter *model_interpreter = nullptr;
  const tflite::Model *pr_model = nullptr;
  TfLiteTensor *model_input = nullptr;
  TfLiteTensor *model_output = nullptr;

  tflite::ErrorReporter *error_reporter = nullptr; //A pointer to the global error reporter.
};

#endif  // PDCS_AUDIO_STREAM_H_
