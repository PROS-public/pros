/**
 * @file biosignal_stream.h
 * @author  Nhat Pham <nhat.pham@cs.ox.ac.edu>.
 * @version 0.1
 * @date 19-Feb-2022
 * @brief This contains definitions for PDCS biosignal stream abstraction.
 */

#ifndef PDCS_BIOSIGNAL_STREAM_H_
#define PDCS_BIOSIGNAL_STREAM_H_

#include "pdcs_misc.h"
#include "arm_math_types.h"
#include "streams/biosignals/preprocess/biosignal_mfcc.h"
#include "streams/biosignals/pattern_primitives/absence/sz_absence_pr.h"
#include "streams/biosignals/pattern_primitives/focal/sz_focal_pr.h"
#include "streams/biosignals/pattern_primitives/gtc/sz_gtc_pr.h"

/* Absence Seizure pattern model data */
extern const unsigned char absence_dr_pr[];
extern const unsigned int absence_dr_pr_len;
extern const unsigned char absence_pr[];
extern const unsigned int absence_pr_len;
extern const unsigned char absence_int8_pr[];
extern const unsigned int absence_int8_pr_len;

/* Focal Seizure pattern model data */
extern const unsigned char focal_dr_pr[];
extern const unsigned int focal_dr_pr_len;
extern const unsigned char focal_pr[];
extern const unsigned int focal_pr_len;
extern const unsigned char focal_int8_pr[];
extern const unsigned int focal_int8_pr_len;

/* GTC Seizure pattern model data */
extern const unsigned char gtc_dr_pr[];
extern const unsigned int gtc_dr_pr_len;
extern const unsigned char gtc_pr[];
extern const unsigned int gtc_pr_len;
extern const unsigned char gtc_int8_pr[];
extern const unsigned int gtc_int8_pr_len;

void pdcs_upsampling(int16_t* input_p, uint32_t input_size, uint32_t upsampling_factor, int16_t* output_p);
void pdcs_softmax(float32_t* input, size_t size, float32_t* output);

#endif  // PDCS_AUDIO_STREAM_H_
