/**
 ******************************************************************************
 * @file            : pdcs_cs.h
 * @brief           : Pattern-Driven Compressive Sensing implementation.
 * @author          : Nhat Pham (nhat.pham@cs.ox.ac.uk)
 * @version         : 0.1, 18-Dec-2021
 ******************************************************************************
 * @notes
 *  TBU.
 ******************************************************************************
 */

#ifndef COMPRESSIVE_SENSING_PDCS_CS_H_
#define COMPRESSIVE_SENSING_PDCS_CS_H_

/* CMSIS-DSP includes */
#include "arm_math.h"

/* CMSIS-NN includes */
#include "arm_nnfunctions.h"

/* PDCS includes */
#include "pdcs_misc.h"

/* Phi matrices */
extern const q7_t Phi_bin_45x250[];
extern const q7_t Phi_bin_50x250[];
extern const q7_t Phi_bin_65x250[];
extern const q7_t Phi_bin_125x250[];

/* Test samples */
extern const q15_t eyemov_00000254_s005_t000_13_1[];
extern const q15_t eyemov_Phi_bin_65x250_00000254_s005_t000_13_1[];

extern const q15_t focal_00007235_s001_t002_19_9[];
extern const q15_t focal_Phi_bin_65x250_00007235_s001_t002_19_9[];

const extern q15_t focal_00002991_s003_t000_11_1_500[];

/**
 * @brief  PDCS Compressive Sensing with binary [0, 1] matrices.
 * @param[in]   x: pointer to the input signal vector.
 * @param[in]   n: size of the input signal vector. (Current supported values: 250)
 * @param[out]  y: pointer to the output compressed vector.
 * @param[in]   m: size of the output compressed vector. (Current supported values: 45, 50, 65, 125)
 *
 * @retval pdcs_ok on SUCCESS; pdcs_error if m or n values are not supported.
 */
pdcs_status pdcs_bin_compressing(const q15_t *x, uint16_t n, q15_t *y, uint16_t m);

/**
 * @brief  Print a matrix to UART.
 * @param[in]   x: pointer to the input matrix.
 * @param[in]   ncol: number of columns.
 * @param[out]  nrow: number of rows.
 */
void pdcs_print_matrix(float32_t *m, uint16_t ncol, uint16_t nrow);
void pdcs_print_matrix(int16_t *m, uint16_t ncol, uint16_t nrow);

/**
 * @brief  Naive vector dot product.
 * @param[in]   x: pointer to the 1st input vector.
 * @param[in]   y: pointer to the 2nd input vector.
 * @param[in]  n: number of elements.
 */
int vectors_dot_prod(const int *x, const int *y, int n);

/**
 * @brief  Naive matrix vector multiplication.
 * @param[in]   mat: pointer to the input matrix.
 * @param[in]   vec: pointer to the input vector.
 * @param[out]  result: pointer to the output vector.
 * @param[in]   rows: number of rows.
 * @param[in]   cols: number of columns.
 */
void matrix_vector_mult(const int **mat, const int *vec, int *result, int rows, int cols);

#endif /* COMPRESSIVE_SENSING_PDCS_CS_H_ */
