/**
 * @file biosignal_mfcc.h
 * @author  Nhat Pham <nhat.pham@cs.ox.ac.edu>.
 * @version 0.1
 * @date 19-Feb-2022
 * @brief This contains definitions for PDCS biosignal MFCC calculation.
 */

#ifndef PDCS_BIOSIGNAL_MFCC_H_
#define PDCS_BIOSIGNAL_MFCC_H_

/* PDCS includes */
#include "pdcs_misc.h"

/* CMSIS-DSP includes */
#include "arm_math.h"
#include "arm_const_structs.h"
#include "arm_math_types.h"

/* ST MFCC Lib */
#include "streams/biosignals/preprocess/st_mfcc_lib/Inc/feature_extraction.h"

/*
 * mfcc_coeffs = librosa.feature.mfcc(input_signal, sr=500, n_mfcc=10, n_mels=64,
 * window="hamming", n_fft=128, hop_length=64, center=False)
 */

#define SIG_LEN       1500 /* Input signal samples (3s) */
#define SAMPLE_RATE   500U /* Input signal sampling rate */
#define SIG_SCALING   10U /* Input signal scaling factor */
#define FFT_LEN       128U /* Number of FFT points. Must be greater or equal to FRAME_LEN */
#define FRAME_LEN     FFT_LEN /* Window length and then padded with zeros to match FFT_LEN */
#define HOP_LEN       64U /* Number of overlapping samples between successive frames */
#define NUM_MELS      64U /* Number of mel bands */
#define NUM_MEL_COEFS 126U /* Number of mel filter weights. Returned by MelFilterbank_Init */
#define NUM_MFCC      10U /* Number of MFCCs to return */
#define FFT_WINDOW    WINDOW_HAMMING
#define N_WINDOWS     (1 + (SIG_LEN - FRAME_LEN) / HOP_LEN)

class biosignal_mfcc {
 public:
  biosignal_mfcc(void);
  ~biosignal_mfcc(void);

  void init(void);
  /**
   * @brief  Calculate MFCC coffs for the input signal.
   * @param  input_p, pointer to the allocated input signal buffer. The size needs to be equal to SIG_LEN.
   * @retval pdcs_ok on success.
   */
  pdcs_status calculate(int16_t* input_p);

  /**
   * @brief  Get a pointer to the MFCC output buffer.
   * @retval a pointer to the MFCC output buffer.
   */
  float32_t* get_output_p(void);

 private:
  arm_rfft_fast_instance_f32 S_Rfft;
  MelFilterTypeDef           S_MelFilter;
  DCT_InstanceTypeDef        S_DCT;
  SpectrogramTypeDef         S_Spectr;
  MelSpectrogramTypeDef      S_MelSpectr;
  LogMelSpectrogramTypeDef   S_LogMelSpectr;
  MfccTypeDef                S_Mfcc;

  float32_t pInFrame[FRAME_LEN];
  float32_t pOutColBuffer[NUM_MFCC];
  float32_t pWindowFuncBuffer[FRAME_LEN];
  float32_t pSpectrScratchBuffer[FFT_LEN];
  float32_t pDCTCoefsBuffer[NUM_MELS * NUM_MFCC];
  float32_t pMfccScratchBuffer[NUM_MELS];
  float32_t pMelFilterCoefs[NUM_MEL_COEFS];
  uint32_t pMelFilterStartIndices[NUM_MELS];
  uint32_t pMelFilterStopIndices[NUM_MELS];

  int16_t   *input_signal;
  float32_t output_mfccs[NUM_MFCC*N_WINDOWS];
};

#endif  // PDCS_AUDIO_STREAM_H_
