/**
 * @file pdcs_debug.h
 * @author  Nhat Pham <nhat.pham@cs.ox.ac.uk>.
 * @version 0.1
 * @date 06-Sep-2021
 * @brief This contains marcos for debugging and notification.
 */

#ifndef PDCS_DEBUG_H_
#define PDCS_DEBUG_H_

#include <stdio.h>

#if PDCS_NOTIFICATION_EN
#define PDCS_NOTIFY(...) printf(__VA_ARGS__)
#else
#define PDCS_NOTIFY(...)
#endif

#if PDCS_DEBUG_EN
#define PDCS_DEBUG(...) printf(__VA_ARGS__)
#define PDCS_PRINTF(...) printf(__VA_ARGS__)
#else
#define PDCS_DEBUG(...)
#define PDCS_PRINTF(...)
#endif

#endif /* pdcs_DEBUG_H_ */
