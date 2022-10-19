/**
 * @file biosignal_mfcc.cc
 * @author  Nhat Pham <nhat.pham@cs.ox.ac.edu>.
 * @version 0.1
 * @date 19-Feb-2022
 * @brief This contains implemetation for PDCS biosignal MFCC calculation.
 */

#include "streams/biosignals/preprocess/biosignal_mfcc.h"

#define PDCS_DEBUG_EN 1
#include "pdcs_debug.h"

/*---------------------------------------------------------------------------------------------*/
biosignal_mfcc::biosignal_mfcc(void) {

}

/*---------------------------------------------------------------------------------------------*/
biosignal_mfcc::~biosignal_mfcc(void) {

}

/*---------------------------------------------------------------------------------------------*/
void biosignal_mfcc::init(void) {
  /* Init window function */
  if (Window_Init(pWindowFuncBuffer, FRAME_LEN, FFT_WINDOW) != 0)
  {
    PDCS_DEBUG("biosignal_mfcc: can't init the FTT window!");
    while(1);
  }

  /* Init RFFT */
  if (arm_rfft_fast_init_f32(&S_Rfft, FFT_LEN) != ARM_MATH_SUCCESS)
  {
    PDCS_DEBUG("biosignal_mfcc: can't init the ARM RFTT!");
    while(1);
  }

  /* Init mel filterbank */
  S_MelFilter.pStartIndices = pMelFilterStartIndices;
  S_MelFilter.pStopIndices  = pMelFilterStopIndices;
  S_MelFilter.pCoefficients = pMelFilterCoefs;
  S_MelFilter.NumMels   = NUM_MELS;
  S_MelFilter.FFTLen    = FFT_LEN;
  S_MelFilter.SampRate  = SAMPLE_RATE;
  S_MelFilter.FMin      = 0.0;
  S_MelFilter.FMax      = S_MelFilter.SampRate / 2.0;
  S_MelFilter.Formula   = MEL_SLANEY;
  S_MelFilter.Normalize = 1;
  S_MelFilter.Mel2F     = 1;
  MelFilterbank_Init(&S_MelFilter);
  if (S_MelFilter.CoefficientsLength != NUM_MEL_COEFS)
  {
    PDCS_DEBUG("biosignal_mfcc: Adjust NUM_MEL_COEFS to S_MelFilter.CoefficientsLength!");
    while(1); /* Adjust NUM_MEL_COEFS to match S_MelFilter.CoefficientsLength */
  }

  /* Init DCT operation */
  S_DCT.NumFilters    = NUM_MFCC;
  S_DCT.NumInputs     = NUM_MELS;
  S_DCT.Type          = DCT_TYPE_II_ORTHO;
  S_DCT.RemoveDCTZero = 0;
  S_DCT.pDCTCoefs     = pDCTCoefsBuffer;
  if (DCT_Init(&S_DCT) != 0)
  {
    PDCS_DEBUG("biosignal_mfcc: Can't init DCT!");
    while(1);
  }

  /* Init Spectrogram */
  S_Spectr.pRfft    = &S_Rfft;
  S_Spectr.Type     = SPECTRUM_TYPE_POWER;
  S_Spectr.pWindow  = pWindowFuncBuffer;
  S_Spectr.SampRate = SAMPLE_RATE;
  S_Spectr.FrameLen = FRAME_LEN;
  S_Spectr.FFTLen   = FFT_LEN;
  S_Spectr.pScratch = pSpectrScratchBuffer;

  /* Init MelSpectrogram */
  S_MelSpectr.SpectrogramConf = &S_Spectr;
  S_MelSpectr.MelFilter       = &S_MelFilter;

  /* Init LogMelSpectrogram */
  S_LogMelSpectr.MelSpectrogramConf = &S_MelSpectr;
  S_LogMelSpectr.LogFormula         = LOGMELSPECTROGRAM_SCALE_DB;
  S_LogMelSpectr.Ref                = 1.0;
  S_LogMelSpectr.TopdB              = HUGE_VALF;

  /* Init MFCC */
  S_Mfcc.LogMelConf   = &S_LogMelSpectr;
  S_Mfcc.pDCT         = &S_DCT;
  S_Mfcc.NumMfccCoefs = NUM_MFCC;
  S_Mfcc.pScratch     = pMfccScratchBuffer;
}

/*---------------------------------------------------------------------------------------------*/
pdcs_status biosignal_mfcc::calculate(int16_t* input_p) {
  volatile uint32_t num_frames = 1 + (SIG_LEN - FRAME_LEN) / HOP_LEN;

  for (uint32_t frame_index = 0; frame_index < num_frames; frame_index++)
  {
    buf_to_float(&input_p[HOP_LEN * frame_index], pInFrame, FRAME_LEN, SIG_SCALING);
    MfccColumn(&S_Mfcc, pInFrame, pOutColBuffer);
    /* Reshape column into pOutMfcc */
    for (uint32_t i = 0; i < NUM_MFCC; i++)
    {
      output_mfccs[i * num_frames + frame_index] = pOutColBuffer[i];
    }
  }

  return pdcs_ok;
}

/*---------------------------------------------------------------------------------------------*/
float32_t* biosignal_mfcc::get_output_p(void) {
  return output_mfccs;
}
