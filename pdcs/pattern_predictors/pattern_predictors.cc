/**
 ******************************************************************************
 * @file            : pattern_predictors.cc
 * @brief           : Pattern predictors implementation based on locality.
 * @author          : Nhat Pham (nhat.pham@cs.ox.ac.uk)
 * @version         : 0.1, 11-Oct-2022
 ******************************************************************************
 * @notes
 *  TBU.
 ******************************************************************************
 */

#include "pattern_predictors.h"

/* PDCS includes */
#include "pdcs_misc.h"

#define PDCS_DEBUG_EN (0)
#define PDCS_NOTIFICATION_EN (0)
#include "pdcs_debug.h"

/******************************************************************************/
correlating_predictor::correlating_predictor(void) {
  return;
}

/******************************************************************************/
correlating_predictor::~correlating_predictor(void) {
  return;
}

/******************************************************************************/
void correlating_predictor::init(void) {
  /* Initialise all local predictors */
  uint8_t mrp = 0; // Most recent pattern.
  for (uint32_t i = 0; i < CORR_PRED_LPT_ENTRIES; i++) {
    mrp = (uint8_t) i >> (CORR_PRED_HIS_BITS*(CORR_PRED_NUM_HIS-1));
    lpt[i].init(mrp);
  }
}

/******************************************************************************/
uint8_t correlating_predictor::predict(void) {
  return lpt[pattern_history].predict();
}

/******************************************************************************/
void correlating_predictor::update(uint8_t new_value) {
  /* Update local predictor*/
  lpt[pattern_history].update(new_value);

  /* Update the pattern history */
  uint32_t temp = new_value;
  temp = temp << (CORR_PRED_HIS_BITS*(CORR_PRED_NUM_HIS-1));
  pattern_history = (pattern_history >> CORR_PRED_HIS_BITS) | temp;
}

/******************************************************************************/
local_predictor::local_predictor(void) {
  return;
}

/******************************************************************************/
local_predictor::~local_predictor(void) {
  return;
}
