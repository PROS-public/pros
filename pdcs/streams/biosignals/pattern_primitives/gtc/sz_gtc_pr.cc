/**
 * @file sz_gtc_pr.cc
 * @author  Nhat Pham <nhat.pham@cs.ox.ac.edu>.
 * @version 0.1
 * @date 22-Feb-2022
 * @brief This contains implementation for the gtc Seizure pattern recognition primitive.
 */
#include "streams/biosignals/biosignal_stream.h"
#include "streams/biosignals/pattern_primitives/gtc/sz_gtc_pr.h"
#include "arm_nnfunctions.h"

#define PDCS_DEBUG_EN 0
#include "pdcs_debug.h"


// Create an area of memory to use for input, output, and intermediate arrays.
// The size of this will depend on the model you're using, and may need to be
// determined by experimentation.
static constexpr int sz_gtc_tensor_arena_size = 30 * 1024;
static uint8_t sz_gtc_tensor_arena[sz_gtc_tensor_arena_size];
//__attribute__((section(".ram2")));

/*---------------------------------------------------------------------------------------------*/
sz_gtc_pr::sz_gtc_pr(void) {

}

/*---------------------------------------------------------------------------------------------*/
sz_gtc_pr::~sz_gtc_pr(void) {

}

/*---------------------------------------------------------------------------------------------*/
void sz_gtc_pr::init(tflite::ErrorReporter *global_error_reporter) {
  error_reporter = global_error_reporter;

  // Map the model into a usable data structure. This doesn't involve any
  // copying or parsing, it's a very lightweight operation.
  pr_model = tflite::GetModel(gtc_pr);
  if (pr_model->version() != TFLITE_SCHEMA_VERSION) {
    TF_LITE_REPORT_ERROR(error_reporter,
        "sz_gtc_pr: Model provided is schema version %d not equal "
            "to supported version %d.", pr_model->version(),
        TFLITE_SCHEMA_VERSION);
    while (1)
      ;
  }

  // Create an operator resolver.
  static tflite::MicroMutableOpResolver<6> op_resolver(error_reporter);
  if (op_resolver.AddConv2D() != kTfLiteOk) {
    while(1);
  }
  if (op_resolver.AddFullyConnected() != kTfLiteOk) {
    while(1);
  }
  if (op_resolver.AddMean() != kTfLiteOk) {
    while(1);
  }
  if (op_resolver.AddReshape() != kTfLiteOk) {
    while(1);
  }
  if (op_resolver.AddPad() != kTfLiteOk) {
    while(1);
  }
  if (op_resolver.AddTranspose() != kTfLiteOk) {
    while(1);
  }

  // Create an interpreter.
  static tflite::MicroInterpreter static_interpreter(pr_model,
      op_resolver, sz_gtc_tensor_arena, sz_gtc_tensor_arena_size,
      error_reporter);
  model_interpreter = &static_interpreter;

  // Allocate memory from the tensor_arena for the model's tensors.
  TfLiteStatus allocate_status = model_interpreter->AllocateTensors();
  if (allocate_status != kTfLiteOk) {
    TF_LITE_REPORT_ERROR(error_reporter, "sz_gtc_pr: AllocateTensors() failed");
    while(1);
  }

  // Obtain pointer to the model's input tensor.
  // Get information about the memory area to use for the model's input.
  model_input = model_interpreter->input(0);
  if ((model_input->dims->size != 4)
      || (model_input->dims->data[0] != 1)
      || (model_input->dims->data[1] != 1)
      || (model_input->dims->data[2] != 10)
      || (model_input->dims->data[3] != 22)
      || (model_input->type != kTfLiteFloat32)) {
    TF_LITE_REPORT_ERROR(error_reporter,
        "sz_gtc_pr: Bad input tensor parameters in model");
    while(1);
  }

  // Obtain pointer to the model's input tensor.
  model_output = model_interpreter->output(0);
}

/*---------------------------------------------------------------------------------------------*/
float32_t sz_gtc_pr::recognise(float32_t *input_p, uint32_t input_buffer_size) {
  // Copy feature buffer to input tensor
  memcpy(model_input->data.f, input_p, input_buffer_size*sizeof(float32_t));

  // Run inference, and report any error.
  TfLiteStatus invoke_status = model_interpreter->Invoke();
  if (invoke_status != kTfLiteOk) {
    TF_LITE_REPORT_ERROR(error_reporter, "sz_gtc_pr: Invoke failed\n");
    while(1);
  }

  PDCS_DEBUG("sz_gtc_pr: invoked outputs, [%.3f, %.3f]\n", model_output->data.f[0], model_output->data.f[1]);

  // Calculate softmax on the outputs.
  float32_t output_f32[2];
  pdcs_softmax(model_output->data.f, 2, output_f32);

  PDCS_DEBUG("sz_gtc_pr: invoked output probs, [%.3f, %.3f]\n", output_f32[0], output_f32[1]);
  return output_f32[1];
}
