/**
 ******************************************************************************
 * @file            : pattern_predictors.h
 * @brief           : Pattern predictors implementation based on locality.
 * @author          : Nhat Pham (nhat.pham@cs.ox.ac.uk)
 * @version         : 0.1, 11-Oct-2022
 ******************************************************************************
 * @notes
 *  TBU.
 ******************************************************************************
 */

#ifndef PATTERN_PREDICTORS_H_
#define PATTERN_PREDICTORS_H_

#include "stdint.h"

#define CORR_PRED_NUM_PATTERNS  4
#define CORR_PRED_NUM_HIS       3
#define CORR_PRED_LPT_ENTRIES   64 // CORR_PRED_NUM_PATTERNS ^ CORR_PRED_NUM_HIS
#define CORR_PRED_HIS_BITS      2  // log2(CORR_PRED_NUM_PATTERNS)

/*****************************************************************************/
class local_predictor {
public:
  local_predictor(void);
  ~local_predictor(void);

  void init(uint8_t init_val) {pred = init_val;}
  uint8_t predict(void) {return pred;}
  void update(uint8_t new_val) {
    if (new_val != pred) {
      count--;
      if (count == 0) {
        count = 2;
        pred = new_val;
      }
    }
  }

private:
  uint8_t count = 2;
  uint8_t pred = 0;
};

/*****************************************************************************/
class correlating_predictor {
public:
  correlating_predictor(void);
  ~correlating_predictor(void);

  void init(void);
  uint8_t predict(void);
  void update(uint8_t new_value);

private:
  local_predictor lpt[CORR_PRED_LPT_ENTRIES]; // Local prediction table
  uint32_t pattern_history = 0; // Pattern history format [Most recent (1st - MSB)] [2nd] ... [n-th LSB]
};

#endif /* PATTERN_PREDICTORS_H_ */
