/* USER CODE BEGIN Header */
/**
 ******************************************************************************
 * @file           : main.c
 * @brief          : Main program body
 ******************************************************************************
 * @attention
 *
 * <h2><center>&copy; Copyright (c) 2020 STMicroelectronics.
 * All rights reserved.</center></h2>
 *
 * This software component is licensed by ST under Ultimate Liberty license
 * SLA0044, the "License"; You may not use this file except in compliance with
 * the License. You may obtain a copy of the License at:
 *                             www.st.com/SLA0044
 *
 ******************************************************************************
 */
/* USER CODE END Header */
/* Includes ------------------------------------------------------------------*/
#include "stdio.h"
#include "main.h"

/* FATFS includes. */
#include "fatfs.h"

/* Kernel includes. */
#include "FreeRTOS.h"
#include "task.h"
#include "semphr.h"

/* pdcs abstraction includes */
/* Compressive Sensing */
#include "compressive_sensing/pdcs_cs.h"

/* Biosignal stream */
#include "streams/biosignals/biosignal_stream.h"

/* pdcs debug */
#define PDCS_DEBUG_EN (1)
#define PDCS_NOTIFICATION_EN (1)
#include "pdcs_debug.h"

/* Global variables */
namespace {
tflite::MicroErrorReporter micro_error_reporter;
tflite::ErrorReporter *error_reporter = nullptr;
}  // namespace

/* Biosignal pattern recognition primitives */
#define BIOS_CS_DATA_LEN 375
#define BIOS_N_FILES      4

int16_t biosignal_window[SIG_LEN];
float32_t biosignal_window_f32[SIG_LEN];
int16_t biosignal_cs_data[BIOS_CS_DATA_LEN];
biosignal_mfcc bio_mfcc; // MFCC feature extraction object.

/* FLOAT32 PRs */
//sz_absence_pr sz_absence;
//sz_focal_pr sz_focal;
//sz_gtc_pr sz_gtc;

/* INT8 PRs */
sz_absence_int8_pr sz_absence_int8;
sz_focal_int8_pr sz_focal_int8;
sz_gtc_int8_pr sz_gtc_int8;

bool raw_data_streaming = false;

const char sz_focal_file[] = "8_3.CSV";
const char sz_absence_file[] = "12_3.CSV";
const char sz_gtc_file[] = "15_3.CSV";
const char sz_bg_file[] = "6_3.CSV";

const char* sz_files[BIOS_N_FILES] = {sz_focal_file, sz_absence_file, sz_gtc_file, sz_bg_file};
const char sz_file_labels[BIOS_N_FILES] = {8, 12, 15, 6};

uint8_t bt_heart_beat[15];
/* Private variables ---------------------------------------------------------*/
TIM_HandleTypeDef htim1;
UART_HandleTypeDef hbtspp;
SD_HandleTypeDef hsd1;

/* USER CODE BEGIN PV */

/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
static void GPIO_ConfigAN(void);
static void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_SDMMC1_SD_Init(void);
void SystemClock_80MHz(void);
void SystemClock_24MHz(void);
void SystemClock_Config_80Mhz_SMPS(void);

static void RN4678_Init(void);
static void RN4678_Transmit(const uint8_t *buffer, uint16_t size);

/* BioSignal Pattern Recognition task */
#define bio_signal_pr_TASK_PRIORITY    ( tskIDLE_PRIORITY + 3 )
static void bio_signal_pr_task(void *argument);

/* Tracing - User's channel
 */
//traceString chn;

/* USER CODE BEGIN PFP */

/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */

/* USER CODE END 0 */

/**
 * @brief  The application entry point.
 * @retval int
 */
int main(void) {
  BaseType_t ret_val;

  /* MCU Configuration--------------------------------------------------------*/
  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* Initialise SMPS */
  SystemClock_Config_80Mhz_SMPS();
//  SystemClock_24MHz();
//  SystemClock_Config();


  /* USER CODE BEGIN 2 */
  /* Initialise all configured peripherals */
//  GPIO_ConfigAN();
  MX_GPIO_Init();
  MX_SDMMC1_SD_Init();
  MX_FATFS_Init();

  /* Initialise LEDs */
  BSP_LED_Init(LED1);
  BSP_LED_Init(LED2);
  BSP_PB_Init(BUTTON_USER, BUTTON_MODE_GPIO);

  /* Initialise Logging UART */
  UART_Log_Init();

  /* Initialise RN4678 */
  RN4678_Init();

  PDCS_NOTIFY("Hello, This is PROS running on an STM32L476 board.\n");
  PDCS_DEBUG("Powerup: micro_error_reporter test.\n");
  error_reporter = &micro_error_reporter;
  error_reporter->Report("Number: %d", 42);
  error_reporter->Report("Badly-formed format string %");
  error_reporter->Report("Another % badly-formed %% format string");
  error_reporter->Report("~~~%s~~~", "ALL TESTS PASSED");

  /* USER CODE BEGIN 2 */
  /* Init BioSignal PR models */
  bio_mfcc.init();

  /* FLOAT32 PRs */
//  sz_absence.init(error_reporter);
//  sz_focal.init(error_reporter);
//  sz_gtc.init(error_reporter);

  /* INT8 PRs */
  sz_focal_int8.init(error_reporter);
  sz_absence_int8.init(error_reporter);
  sz_gtc_int8.init(error_reporter);

  /* Biosignal PR task */
  ret_val = xTaskCreate(bio_signal_pr_task, "BioS PR", 256,
  NULL,
  bio_signal_pr_TASK_PRIORITY,
  NULL);
  if (ret_val != pdPASS) {
    printf("Error creating Hand-free control task \n");
    while (1)
      ;
  }

  /* Start scheduler */
  vTaskStartScheduler();

  /* We should never get here as control is now taken by the scheduler */
  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1) {
    ;
  }
}

#ifdef STM32L476xx
/**
 * @brief System Clock Configuration
 * @retval None
 */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /** Configure the main internal regulator output voltage
  */
  if (HAL_PWREx_ControlVoltageScaling(PWR_REGULATOR_VOLTAGE_SCALE1) != HAL_OK)
  {
    Error_Handler();
  }
  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI;
  RCC_OscInitStruct.HSIState = RCC_HSI_ON;
  RCC_OscInitStruct.HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSI;
  RCC_OscInitStruct.PLL.PLLM = 1;
  RCC_OscInitStruct.PLL.PLLN = 10;
  RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV7;
  RCC_OscInitStruct.PLL.PLLQ = RCC_PLLQ_DIV2;
  RCC_OscInitStruct.PLL.PLLR = RCC_PLLR_DIV2;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }
  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV1;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_4) != HAL_OK)
  {
    Error_Handler();
  }
}

#endif

#ifdef STM32L4R5xx
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /** Configure the main internal regulator output voltage
  */
  if (HAL_PWREx_ControlVoltageScaling(PWR_REGULATOR_VOLTAGE_SCALE1_BOOST) != HAL_OK)
  {
    Error_Handler();
  }
  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_MSI;
  RCC_OscInitStruct.MSIState = RCC_MSI_ON;
  RCC_OscInitStruct.MSICalibrationValue = 0;
  RCC_OscInitStruct.MSIClockRange = RCC_MSIRANGE_6;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_MSI;
  RCC_OscInitStruct.PLL.PLLM = 1;
  RCC_OscInitStruct.PLL.PLLN = 60;
  RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV2;
  RCC_OscInitStruct.PLL.PLLQ = RCC_PLLQ_DIV2;
  RCC_OscInitStruct.PLL.PLLR = RCC_PLLR_DIV2;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }
  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV1;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_5) != HAL_OK)
  {
    Error_Handler();
  }
}
#endif


/*----------------------------------------------------------------------------------------------------*/
static int fill_up_input_signal_buffer(FIL* fp, int16_t* input_signal_p, const int16_t len) {
  int16_t row_len = 10;
  TCHAR* res; /* FatFs function common result code */
  char rtext[_MAX_SS]; /* File read buffer */

  for (int16_t row_i = 0; row_i < len/row_len; row_i++) {
    // Get one data line from file
    res = f_gets(rtext, _MAX_SS, &SDFile);
    if (res == 0) {
      PDCS_DEBUG("fill_up_input_signal_buffer: no data read.\n");
      return pdcs_error;
    }

    sscanf(rtext,
        "%hd, %hd, %hd, %hd, %hd, %hd, %hd, %hd, %hd, %hd",
        &input_signal_p[row_len*row_i], &input_signal_p[row_len*row_i+1], &input_signal_p[row_len*row_i+2],
        &input_signal_p[row_len*row_i+3], &input_signal_p[row_len*row_i+4], &input_signal_p[row_len*row_i+5],
        &input_signal_p[row_len*row_i+6], &input_signal_p[row_len*row_i+7], &input_signal_p[row_len*row_i+8],
        &input_signal_p[row_len*row_i+9]);
  }

  return pdcs_ok;
}

/**
 * @brief  Hand-free control application. Needed patterns: (1) Yes, No from audio streams,
 *         (2) Eyes move left/right, open mouth, grind teeth from biopotential streams.
 * @param  argument: Not used
 * @retval None
 */
/* USER CODE END Header_StartDefaultTask */
static void bio_signal_pr_task(void *argument) {
  float32_t pos_prob;
  float32_t focal_cutoff_prob = 0.47;
  float32_t absence_cutoff_prob = 0.76;
  float32_t gtc_cutoff_prob = 0.56;

  int16_t pos_prob_int8;
  int16_t focal_cutoff_prob_int8 = -1;
  int16_t absence_cutoff_prob_int8 = 1;
  int16_t gtc_cutoff_prob_int8 = 2;

  float32_t *output_mfccs;
  TickType_t start_ticks, end_ticks;
  int32_t pred = 6, prev1_pred = 6, prev2_pred = 6;
  int32_t total = 0, tp = 0, tn = 0, fp = 0, fn = 0, ud = 0;
  int32_t abz_p = 0, abz_n = 0, gtc_p = 0, gtc_n = 0, focal_p = 0, focal_n = 0, bg_p = 0, bg_n = 0;
  float32_t window_eng = 0;
  uint16_t n, m;

  /* Waiting for the button */
  PDCS_NOTIFY("Waiting for the button.\r\n");
  HAL_Delay(15000);
  PDCS_NOTIFY("- START -.\r\n");
//  while (BSP_PB_GetState(BUTTON_USER) == GPIO_PIN_RESET);

  /* Mount the SD Card */
  if (f_mount(&SDFatFS, (TCHAR const*) SDPath, 0) != FR_OK) {
    PDCS_DEBUG("bio_signal_pr_task: error mounting the SD card!\n");
    Error_Handler();
  }

  for (uint16_t i = 0; i < BIOS_N_FILES; i++) {
    /* Open file for reading */
    PDCS_DEBUG("***\n");
    PDCS_DEBUG("%s\n", sz_files[i]);
    if (f_open(&SDFile, sz_files[i], FA_READ) != FR_OK) {
      PDCS_DEBUG("bio_signal_pr_task: error opening a data file!\n");
      Error_Handler();
    }

    /* Infinite loop */
    while (1) {
      /* Fill up an input buffer */
      start_ticks = xTaskGetTickCount();
      if (fill_up_input_signal_buffer(&SDFile, biosignal_window, SIG_LEN)
          != pdcs_ok) {
        break;
      }
      end_ticks = xTaskGetTickCount();
      PDCS_DEBUG("Data %lu (ms): \r\n", end_ticks - start_ticks);

      /* TEST */
      m = 50;
      PDCS_DEBUG("CS start \r\n");
      start_ticks = xTaskGetTickCount();
      for (uint16_t i = 0; i < 3; i++) {
        // TODO: downsample biosignal_window.
        pdcs_bin_compressing((q15_t*) &biosignal_window[i * n], n,
            (q15_t*) &biosignal_cs_data[i * m], m);
      }
      end_ticks = xTaskGetTickCount();
      PDCS_DEBUG("CS %lu (ms): \r\n", end_ticks - start_ticks);

      /* Energy calculation */
      buf_to_float(biosignal_window, biosignal_window_f32, SIG_LEN,
          SIG_SCALING);
      arm_power_f32(biosignal_window_f32, SIG_LEN, &window_eng);
      PDCS_DEBUG("E: %.3f\r\n", window_eng);

      /* TEST sleep */
      if (total == 100) {
        PDCS_NOTIFY("Test sleeping.\r\n");
        HAL_Delay(15000);
      }

      /* Raw data tranmission */
      if (raw_data_streaming) {
        RN4678_Transmit((uint8_t *)biosignal_window, 250 * 3);
        RN4678_Transmit((uint8_t *)biosignal_window, 250 * 3);
        RN4678_Transmit((uint8_t *)biosignal_window, 250 * 3);

        PDCS_NOTIFY("T: %ld, tp: %ld, tn: %ld, fp: %ld, fn: %ld.\r\n", total, tp,
            tn, fp, fn);
        continue;
      }

      /* Static Energy thresholding */
      pred = 6;
      if (window_eng > 310000) {
        /* MFCC Extraction */
        PDCS_DEBUG("MFCC start \r\n");
        start_ticks = xTaskGetTickCount();
        bio_mfcc.calculate(biosignal_window);
        end_ticks = xTaskGetTickCount();
        output_mfccs = bio_mfcc.get_output_p();

        PDCS_DEBUG("MFCC %lu (ms): \r\n", end_ticks - start_ticks);

        /* Running PRs */
        /* Absence PR */
        if (pred == 6) {
          PDCS_DEBUG("ABSZ start \r\n");
          start_ticks = xTaskGetTickCount();

          /* FLOAT32 PR */
//          pos_prob = sz_absence.recognise(output_mfccs, NUM_MFCC * N_WINDOWS);
//          if (pos_prob > absence_cutoff_prob) {
//            pred = 12;
//          }

          /* INT8 PR */
          pos_prob_int8 = sz_absence_int8.recognise(output_mfccs, NUM_MFCC * N_WINDOWS);
          if (pos_prob_int8 > absence_cutoff_prob_int8) {
            pred = 12;

            if (sz_file_labels[i] != 6) {
              abz_p++;
            }
            else {
              abz_n++;
            }
          }

          end_ticks = xTaskGetTickCount();
          PDCS_DEBUG("Absence PR %lu (ms): \r\n", end_ticks - start_ticks);

        }

        /* GTC PR */
        if (pred == 6) {
          start_ticks = xTaskGetTickCount();

          /* FLOAT32 PR */
//          pos_prob = sz_gtc.recognise(output_mfccs, NUM_MFCC * N_WINDOWS);
//          if (pos_prob > gtc_cutoff_prob) {
//            pred = 15;
//          }

          /* INT8 PR */
          pos_prob_int8 = sz_gtc_int8.recognise(output_mfccs, NUM_MFCC * N_WINDOWS);
          if (pos_prob_int8 > gtc_cutoff_prob_int8) {
            pred = 15;

            if (sz_file_labels[i] != 6) {
              gtc_p++;
            }
            else {
              gtc_n++;
            }
          }

          end_ticks = xTaskGetTickCount();
          PDCS_DEBUG("GTC PR %lu (ms): \r\n", end_ticks - start_ticks);

        }

        /* Focal PR */
        if (pred == 6) {
          start_ticks = xTaskGetTickCount();

          /* FLOAT32 PR */
//          pos_prob = sz_focal.recognise(output_mfccs, NUM_MFCC * N_WINDOWS);
//          if (pos_prob > focal_cutoff_prob) {
//            pred = 8;
//          }

          /* INT8 PR */
          pos_prob_int8 = sz_focal_int8.recognise(output_mfccs, NUM_MFCC * N_WINDOWS);
          if (pos_prob_int8 > focal_cutoff_prob_int8) {
            pred = 8;

            if (sz_file_labels[i] != 6) {
              focal_p++;
            }
            else {
              focal_n++;
            }
          }

          end_ticks = xTaskGetTickCount();
          PDCS_DEBUG("Focal PR %lu (ms): \r\n", end_ticks - start_ticks);
        }
      }
      else {
        ud++;
      }

      /* Calculate TP, TN, FP, FN */
      if (pred != 6) {
        if (sz_file_labels[i] != 6) {
          tp++;
        }
        else {
          fn++;
        }
      }
      else { // pred == 6
        if (sz_file_labels[i] == 6) {
          tn++;
        }
        else {
          fp++;
        }
      }

      if (pred != 6) {
        /* Compressive Sensing */
        n = 250;
        switch (pred) {
        case 8:
          m = 45;
          break;
        case 12:
          m = 50;
          break;
        case 15:
          m = 125;
          break;
        default:
          m = 0;
          Error_Handler();
          break;
        }

        PDCS_DEBUG("MFCC start \r\n");
        start_ticks = xTaskGetTickCount();
        for (uint16_t i = 0; i < 3; i++) {
          // TODO: downsample biosignal_window.
          pdcs_bin_compressing((q15_t*) &biosignal_window[i * n], n,
              (q15_t*) &biosignal_cs_data[i * m], m);
        }
        end_ticks = xTaskGetTickCount();
        PDCS_DEBUG("CS %lu (ms): \r\n", end_ticks - start_ticks);

        /* Data tranmission */
        start_ticks = xTaskGetTickCount();
        RN4678_Transmit((uint8_t*) biosignal_cs_data, m * 6);
        end_ticks = xTaskGetTickCount();
        PDCS_DEBUG("Transmit %lu (ms): \r\n", end_ticks - start_ticks);
      }

      /* Update prev predictions */
      prev2_pred = prev1_pred;
      prev1_pred = pred;

      PDCS_NOTIFY("T: %ld\r\n", total);
      if (total % 1000 == 0) {
        PDCS_NOTIFY("(S) T: %ld, tp: %ld, tn: %ld, fp: %ld, fn: %ld, ut: %ld.\r\n",
            total, tp, tn, fp, fn, ud);
        PDCS_DEBUG("(S) abz_p: %ld, gtc_p: %ld, focal_p: %ld, abz_n: %ld, gtc_n: %ld, focal_n: %ld.\r\n",
            abz_p, gtc_p, focal_p, abz_n, gtc_n, focal_n);
      }

      total++;

    }// End for one file.

    f_close(&SDFile);
  }

//  f_mount(&SDFatFS, (TCHAR const*) NULL, 0);
  PDCS_NOTIFY("- DONE!!! -\r\n");
  PDCS_NOTIFY("(S) T: %ld, tp: %ld, tn: %ld, fp: %ld, fn: %ld, ut: %ld.\r\n",
      total, tp, tn, fp, fn, ud);
  PDCS_NOTIFY(
      "(S) abz_p: %ld, gtc_p: %ld, focal_p: %ld, abz_n: %ld, gtc_n: %ld, focal_n: %ld.\r\n",
      abz_p, gtc_p, focal_p, abz_n, gtc_n, focal_n);
  BSP_LED_On(LED1);
  BSP_LED_On(LED2);

  while(1) {
    vTaskDelay(500);
  }
}


/**
  * @brief SDMMC1 Initialization Function
  * @param None
  * @retval None
  */
static void MX_SDMMC1_SD_Init(void)
{

  /* USER CODE BEGIN SDMMC1_Init 0 */

  /* USER CODE END SDMMC1_Init 0 */

  /* USER CODE BEGIN SDMMC1_Init 1 */

  /* USER CODE END SDMMC1_Init 1 */
  hsd1.Instance = SDMMC1;
  hsd1.Init.ClockEdge = SDMMC_CLOCK_EDGE_RISING;
  hsd1.Init.ClockPowerSave = SDMMC_CLOCK_POWER_SAVE_DISABLE;
  hsd1.Init.BusWide = SDMMC_BUS_WIDE_4B;
  hsd1.Init.HardwareFlowControl = SDMMC_HARDWARE_FLOW_CONTROL_DISABLE;
  hsd1.Init.ClockDiv = 1;
  hsd1.Init.Transceiver = SDMMC_TRANSCEIVER_DISABLE;
  /* USER CODE BEGIN SDMMC1_Init 2 */

  /* USER CODE END SDMMC1_Init 2 */

}

/**
  * @brief GPIO Initialization Function
  * @param None
  * @retval None
  */
static void MX_GPIO_Init(void)
{

  /* GPIO Ports Clock Enable */
  __HAL_RCC_GPIOC_CLK_ENABLE();
  __HAL_RCC_GPIOH_CLK_ENABLE();
  __HAL_RCC_GPIOG_CLK_ENABLE();
  HAL_PWREx_EnableVddIO2();
  __HAL_RCC_GPIOA_CLK_ENABLE();
  __HAL_RCC_GPIOD_CLK_ENABLE();

}

/**
 * @brief  Period elapsed callback in non blocking mode
 * @note   This function is called  when TIM6 interrupt took place, inside
 * HAL_TIM_IRQHandler(). It makes a direct call to HAL_IncTick() to increment
 * a global variable "uwTick" used as application time base.
 * @param  htim : TIM handle
 * @retval None
 */
void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim) {
  /* USER CODE BEGIN Callback 0 */

  /* USER CODE END Callback 0 */
  if (htim->Instance == TIM6) {
    HAL_IncTick();
  }
  /* USER CODE BEGIN Callback 1 */

  /* USER CODE END Callback 1 */
}

/**
  * @brief  Pre Sleep Processing
  * @param  ulExpectedIdleTime: Expected time in idle state
  * @retval None
  */
void PreSleepProcessing(uint32_t ulExpectedIdleTime)
{
  /* Called by the kernel before it places the MCU into a sleep mode because
  configPRE_SLEEP_PROCESSING() is #defined to PreSleepProcessing().

  NOTE:  Additional actions can be taken here to get the power consumption
  even lower.  For example, peripherals can be turned off here, and then back
  on again in the post sleep processing function.  For maximum power saving
  ensure all unused pins are in their lowest power state. */

  /*
    (ulExpectedIdleTime) is set to 0 to indicate that PreSleepProcessing contains
    its own wait for interrupt or wait for event instruction and so the kernel vPortSuppressTicksAndSleep
    function does not need to execute the wfi instruction
  */
  (void) ulExpectedIdleTime;

  /* Suspend the HAL Tick */
  HAL_SuspendTick();

  /*Enter to sleep Mode using the HAL function HAL_PWR_EnterSLEEPMode with WFI instruction*/
  HAL_PWR_EnterSLEEPMode(PWR_MAINREGULATOR_ON, PWR_SLEEPENTRY_WFI);
}

/**
  * @brief  Post Sleep Processing
  * @param  ulExpectedIdleTime: Not used
  * @retval None
  */
void PostSleepProcessing(uint32_t ulExpectedIdleTime)
{
  /* Called by the kernel when the MCU exits a sleep mode because
  configPOST_SLEEP_PROCESSING is #defined to PostSleepProcessing(). */

  /* Avoid compiler warnings about the unused parameter. */
  (void) ulExpectedIdleTime;

  /* resume the HAL tick */
  HAL_ResumeTick();

}

/**
  * @brief  Configure all GPIO's to AN to reduce the power consumption
  * @param  None
  * @retval None
  */
static void GPIO_ConfigAN(void)
{
  GPIO_InitTypeDef GPIO_InitStruct;

  /* Configure all GPIO as analog to reduce current consumption on non used IOs */
  /* Enable GPIOs clock */
  __HAL_RCC_GPIOA_CLK_ENABLE();
  __HAL_RCC_GPIOB_CLK_ENABLE();
  __HAL_RCC_GPIOC_CLK_ENABLE();
  __HAL_RCC_GPIOD_CLK_ENABLE();
  __HAL_RCC_GPIOE_CLK_ENABLE();
  __HAL_RCC_GPIOF_CLK_ENABLE();
  __HAL_RCC_GPIOG_CLK_ENABLE();
  __HAL_RCC_GPIOH_CLK_ENABLE();
  __HAL_RCC_GPIOI_CLK_ENABLE();

  GPIO_InitStruct.Mode = GPIO_MODE_ANALOG;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Pin = GPIO_PIN_All;
  HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);
  HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);
  HAL_GPIO_Init(GPIOC, &GPIO_InitStruct);
  HAL_GPIO_Init(GPIOD, &GPIO_InitStruct);
  HAL_GPIO_Init(GPIOE, &GPIO_InitStruct);
  HAL_GPIO_Init(GPIOF, &GPIO_InitStruct);
  HAL_GPIO_Init(GPIOG, &GPIO_InitStruct);
  HAL_GPIO_Init(GPIOH, &GPIO_InitStruct);
  HAL_GPIO_Init(GPIOI, &GPIO_InitStruct);

  /* Disable GPIOs clock */
  __HAL_RCC_GPIOA_CLK_DISABLE();
  __HAL_RCC_GPIOC_CLK_DISABLE();
  __HAL_RCC_GPIOC_CLK_DISABLE();
  __HAL_RCC_GPIOD_CLK_DISABLE();
  __HAL_RCC_GPIOE_CLK_DISABLE();
  __HAL_RCC_GPIOF_CLK_DISABLE();
  __HAL_RCC_GPIOG_CLK_DISABLE();
  __HAL_RCC_GPIOH_CLK_DISABLE();
  __HAL_RCC_GPIOI_CLK_DISABLE();
}

void SystemClock_Config_80Mhz_SMPS(void)
{
  GPIO_InitTypeDef GPIO_InitStruct;

  uint32_t SMPS_status_local = 0;

  SMPS_status_local = BSP_SMPS_DeInit();
  if (SMPS_status_local != SMPS_OK)
  {
    Error_Handler();
  }
  SMPS_status_local = BSP_SMPS_Init(PWR_REGULATOR_VOLTAGE_SCALE2);
  if (SMPS_status_local != SMPS_OK)
  {
    Error_Handler();
  }

  /* ------------------------------------------ */


  __HAL_FLASH_PREFETCH_BUFFER_DISABLE();
  /* Set the System clock to 24 MHz */
  /* so that SMPS can be enabled */
  SystemClock_24MHz();

  /* Insert 1 second delay */
  HAL_Delay(1000);

  /********************************/
  /* 24 MHZ                       */
  /* PWR_REGULATOR_VOLTAGE_SCALE1 */
  /* SMPS IS OFF                  */
  /********************************/

  /* ------------------------------------------ */

  /* PWR_REGULATOR_VOLTAGE_SCALE2 only with AD SMPS */
  HAL_PWREx_ControlVoltageScaling(PWR_REGULATOR_VOLTAGE_SCALE2);
  if (SMPS_status_local != SMPS_OK)
  {
    Error_Handler();
  }

  /* Insert 1 second delay */
  HAL_Delay(1000);

  /********************************/
  /* 24 MHZ                       */
  /* PWR_REGULATOR_VOLTAGE_SCALE2 */
  /* SMPS IS OFF                  */
  /********************************/

  /* ------------------------------------------ */

  /* Enable SMPS */

#ifdef USE_ADP5301ACBZ
  /* Check of PG but not blocking */
  SMPS_status_local = BSP_SMPS_Enable (0 , 1);
#endif /* USE_ADP5301ACBZ */

#ifdef USE_ADP5301ACBZ
  /* Check of PG */
  SMPS_status_local = BSP_SMPS_Supply_Enable (4 , 1);
#endif /* USE_ADP5301ACBZ */

  if (SMPS_status_local != SMPS_OK)
  {
    Error_Handler();
  }

  /* Insert 2 seconds delay */
  HAL_Delay(2000);

  /********************************/
  /* 24 MHZ                       */
  /* PWR_REGULATOR_VOLTAGE_SCALE2 */
  /* SMPS IS ON                  */
  /********************************/

  /* ------------------------------------------ */

  /* Set System clock to 80 MHz (MSI) */
  SystemClock_80MHz();

  GPIO_InitStruct.Mode = GPIO_MODE_ANALOG;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  GPIO_InitStruct.Pull = GPIO_NOPULL;

  GPIO_InitStruct.Pin = GPIO_PIN_All;
  GPIO_InitStruct.Pin ^= (PIN_SMPS_ENABLE | PIN_SMPS_SWITCH_ENABLE);

  HAL_GPIO_Init(GPIOG, &GPIO_InitStruct);

  __HAL_RCC_GPIOG_CLK_DISABLE();
}

/**
  * @brief  System Clock Configuration
  *         The system Clock is configured as follow :
  *            System Clock source            = PLL (MSI)
  *            SYSCLK(Hz)                     = 80000000
  *            HCLK(Hz)                       = 80000000
  *            AHB Prescaler                  = 1
  *            APB1 Prescaler                 = 1
  *            APB2 Prescaler                 = 1
  *            MSI Frequency(Hz)              = 4000000
  *            PLL_M                          = 1
  *            PLL_N                          = 40
  *            PLL_R                          = 2
  *            PLL_P                          = 7
  *            PLL_Q                          = 4
  *            Flash Latency(WS)              = 4
  * @param  None
  * @retval None
  */
void SystemClock_80MHz(void)
{
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};

  __HAL_FLASH_SET_LATENCY(FLASH_LATENCY_3);
  HAL_RCC_DeInit();

  /* MSI is enabled after System reset, activate PLL with MSI as source */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_MSI;
  RCC_OscInitStruct.MSIState = RCC_MSI_ON;
  RCC_OscInitStruct.MSIClockRange = RCC_MSIRANGE_6;
  RCC_OscInitStruct.MSICalibrationValue = RCC_MSICALIBRATION_DEFAULT;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_MSI;
  RCC_OscInitStruct.PLL.PLLM = 1;
  RCC_OscInitStruct.PLL.PLLN = 40;
  RCC_OscInitStruct.PLL.PLLR = 2;
  RCC_OscInitStruct.PLL.PLLP = 7;
  RCC_OscInitStruct.PLL.PLLQ = 4;
  if(HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    /* Initialization Error */
    Error_Handler();
  }

  /* Select PLL as system clock source and configure the HCLK, PCLK1 and PCLK2
     clocks dividers */
  RCC_ClkInitStruct.ClockType = (RCC_CLOCKTYPE_SYSCLK | RCC_CLOCKTYPE_HCLK | RCC_CLOCKTYPE_PCLK1 | RCC_CLOCKTYPE_PCLK2);
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV1;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;
  if(HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_4) != HAL_OK)
  {
    /* Initialization Error */
    Error_Handler();
  }
}

/**
  * @brief  System Clock Configuration to 24 MHz
  *         The system Clock is configured as follows :
  *            System Clock source            = PLL (MSI)
  *            SYSCLK(Hz)                     = 24000000
  *            AHB Prescaler                  = 1
  *            APB1 Prescaler                 = 1
  *            APB2 Prescaler                 = 1
  *            MSI Frequency(Hz)              = 4000000
  * @param  None
  * @retval None
  */

void SystemClock_24MHz(void)
{
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_PeriphCLKInitTypeDef PeriphClkInit;

  __HAL_FLASH_SET_LATENCY(FLASH_LATENCY_3);
  HAL_RCC_DeInit();

  /* MSI is enabled after System reset, update MSI to 24Mhz (RCC_MSIRANGE_9) */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_MSI;
  RCC_OscInitStruct.MSIState = RCC_MSI_ON;
  RCC_OscInitStruct.MSIClockRange = RCC_MSIRANGE_9;
  RCC_OscInitStruct.MSICalibrationValue = RCC_MSICALIBRATION_DEFAULT;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_OFF;
  if(HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    /* Initialization Error */
    Error_Handler();
  }

  /* Select MSI as system clock source and configure the HCLK, PCLK1 and PCLK2
     clocks dividers */
  RCC_ClkInitStruct.ClockType = (RCC_CLOCKTYPE_SYSCLK | RCC_CLOCKTYPE_HCLK | RCC_CLOCKTYPE_PCLK1 | RCC_CLOCKTYPE_PCLK2);
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_MSI;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV1;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;
  if(HAL_RCC_ClockConfig(&RCC_ClkInitStruct,__HAL_FLASH_GET_LATENCY()) != HAL_OK)
  {
    /* Initialization Error */
    Error_Handler();
  }

  PeriphClkInit.PeriphClockSelection = RCC_PERIPHCLK_LPUART1;
  PeriphClkInit.Lpuart1ClockSelection = RCC_LPUART1CLKSOURCE_PCLK1;
  if (HAL_RCCEx_PeriphCLKConfig(&PeriphClkInit) != HAL_OK)
  {
    Error_Handler();
  }
}



/**
  * @brief  Configure RN4678 UART
  * @param  None
  * @retval None
  */
static void RN4678_UART_Init(void)
{
#ifdef STM32L4R5xx
  hbtspp.Instance = USART2;
#endif

  hbtspp.Init.BaudRate = 115200;
  hbtspp.Init.WordLength = UART_WORDLENGTH_8B;
  hbtspp.Init.StopBits = UART_STOPBITS_1;
  hbtspp.Init.Parity = UART_PARITY_NONE;
  hbtspp.Init.Mode = UART_MODE_TX_RX;
  hbtspp.Init.HwFlowCtl = UART_HWCONTROL_RTS_CTS;
  hbtspp.Init.OverSampling = UART_OVERSAMPLING_16;
  hbtspp.Init.OneBitSampling = UART_ONE_BIT_SAMPLE_DISABLE;
  hbtspp.AdvancedInit.AdvFeatureInit = UART_ADVFEATURE_NO_INIT;
  if (HAL_UART_Init(&hbtspp) != HAL_OK)
  {
    Error_Handler();
  }
}

/**
  * @brief  Configure RN4678 RX_IND GPIO
  * @param  None
  * @retval None
  */
static void RN4678_GPIO_Init(void)
{
  GPIO_InitTypeDef  GPIO_InitStruct;

  /* Enable the GPIO_LED Clock */
  __HAL_RCC_GPIOA_CLK_ENABLE();

  /* Configure the GPIO_LED pin */
  GPIO_InitStruct.Pin = GPIO_PIN_7 | GPIO_PIN_5;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;

  HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);
  HAL_GPIO_WritePin(GPIOA, GPIO_PIN_7, GPIO_PIN_SET);

  /* Reset module */
  HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_SET);
  HAL_Delay(3000);
  HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_RESET);
  HAL_Delay(1000);
  HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_SET);
  HAL_Delay(1000);
}

/**
  * @brief  Initialise RN4678
  * @param  None
  * @retval None
  */
const uint8_t RN4678_cmd_mode[] = "$$$";
const uint8_t RN4678_set_dual_mode[] = "SG,0\r\n";
/* min con. interval 1500ms, max 1500, slave latency 0, supervision timeout 2.56s */
const uint8_t RN4678_set_ble_connection_interval[] = "T,04B0,04B0,0000,0100\r\n";
const uint8_t RN4678_set_ble_slave_ad_interval[] = "NA,12,04B0\r\n";
const uint8_t RN4678_end_cmd[] = "---\r\n";

static void RN4678_Init(void)
{
  uint8_t res[10];

  RN4678_UART_Init();
  RN4678_GPIO_Init();

//  /* Enable Dual mode BT */
//  RN4678_Transmit(RN4678_cmd_mode, sizeof(RN4678_cmd_mode));
//  HAL_Delay(1000);
//  RN4678_Transmit(RN4678_set_ble_connection_interval, sizeof(RN4678_set_ble_connection_interval));
//  HAL_Delay(1000);
//  RN4678_Transmit(RN4678_end_cmd, sizeof(RN4678_end_cmd));
//  HAL_Delay(1000);
}

/**
  * @brief  Transmit data through RN4678.
  * @param  None
  * @retval None
  */
static void RN4678_Transmit(const uint8_t *buffer, uint16_t size) {
  uint8_t res[10];

  HAL_GPIO_WritePin(GPIOA, GPIO_PIN_7, GPIO_PIN_RESET);
  HAL_Delay(5);
  HAL_UART_Transmit(&hbtspp, buffer, size, HAL_MAX_DELAY);
  HAL_GPIO_WritePin(GPIOA, GPIO_PIN_7, GPIO_PIN_SET);
}

/**
 * @brief  This function is executed in case of error occurrence.
 * @retval None
 */
void Error_Handler(void) {
  /* USER CODE BEGIN Error_Handler_Debug */
  /* User can add his own implementation to report the HAL error return state */
  __disable_irq();

  PDCS_NOTIFY("System halted!\n");

  while (1)
  {
  }
  /* USER CODE END Error_Handler_Debug */
}

#ifdef  USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     tex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */

/* Some useful code */


/************************ (C) COPYRIGHT STMicroelectronics *****END OF FILE****/
