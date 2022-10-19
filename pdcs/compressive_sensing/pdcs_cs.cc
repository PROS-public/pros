/**
 ******************************************************************************
 * @file            : pdcs_cs.cc
 * @brief           : Pattern-Driven Compressive Sensing implementation.
 * @author          : Nhat Pham (nhat.pham@cs.ox.ac.uk)
 * @version         : 0.1, 18-Dec-2021
 ******************************************************************************
 * @notes
 *  TBU.
 ******************************************************************************
 */

/* PDCS includes */
#include "pdcs_cs.h"

#define PDCS_DEBUG_EN (0)
#define PDCS_NOTIFICATION_EN (0)
#include "pdcs_debug.h"

/******************************************************************************/
pdcs_status pdcs_bin_compressing(const q15_t *x, uint16_t n, q15_t *y,
    uint16_t m) {
  const q7_t *phi;

  /* Load the measurement matrix */
  if (m == 65 && n == 250) {
    phi = Phi_bin_65x250;
  }
  else if (m == 45 && n == 250) {
    phi = Phi_bin_45x250;
  }
  else if (m == 50 && n == 250) {
    phi = Phi_bin_50x250;
  }
  else if (m == 125 && n == 250) {
    phi = Phi_bin_125x250;
  }
  else {
    PDCS_DEBUG("pdcs_bin_compressing: Unsupported n (%d) or m (%d).\n", n, m);
    return pdcs_error;
  }

  /* Compressing */
  q7_t bias[m] = { 0 };
  arm_status ret_value;

  ret_value = arm_fully_connected_mat_q7_vec_q15(x, phi, n, m, 0, 0, bias, y,
  NULL);

  if (ret_value != ARM_MATH_SUCCESS) {
    PDCS_DEBUG("pdcs_bin_compressing: Matrix-vector multiplication error (%d).\n",
        arm_status);
    return pdcs_error;
  }

  return pdcs_ok;
}

/******************************************************************************/
void pdcs_print_matrix(float32_t *m, uint16_t ncol, uint16_t nrow) {
  for (int col_index = 0; col_index < ncol; col_index++) {
    for (int row_index = 0; row_index < nrow; row_index++){
      printf("%.3f ", m[col_index * nrow + row_index]);
    }
    printf(";\n");
  }
}

/******************************************************************************/
void pdcs_print_matrix(int16_t *m, uint16_t ncol, uint16_t nrow) {
  for (int col_index = 0; col_index < ncol; col_index++) {
    for (int row_index = 0; row_index < nrow; row_index++){
      printf("%d ", m[col_index * nrow + row_index]);
    }
    printf(";\n");
  }
}

/******************************************************************************/
int vectors_dot_prod(const int *x, const int *y, int n)
{
    double res = 0.0;
    int i;
    for (i = 0; i < n; i++)
    {
        res += x[i] * y[i];
    }
    return res;
}

/******************************************************************************/
void matrix_vector_mult(const int **mat, const int *vec, int *result, int rows, int cols)
{ // in matrix form: result = mat * vec;
    int i;
    for (i = 0; i < rows; i++)
    {
        result[i] = vectors_dot_prod(mat[i], vec, cols);
    }
}
