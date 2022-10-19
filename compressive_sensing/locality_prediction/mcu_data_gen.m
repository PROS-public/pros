%%%
% @file mcu_data_gen.m
% @author  Nhat Pham <nhat.pham@cs.ox.ac.uk>.
% @version 1.0
% @date 28-Feb-2021
% @brief Data generation for MCU evaluations.
%%%

function mcu_data_gen(wduration)
    %% Dataset folder location
    signal_0 = csvread("0_signal.csv");
    signal_1 = csvread("1_signal.csv");
    signal_4 = csvread("4_signal.csv");
    signal_5 = csvread("5_signal.csv");
    signals = [signal_0 signal_1 signal_4 signal_5];

    fs = 250;
    upsample = 2;
    window_s = wduration*fs; % slide wduration s
    upwindow_s = window_s*upsample;
    disp("===================");
    disp("Window size: " + window_s);

    %% Start running through all the data files.
    total_wins = idivide(int32(numel(signal_0)-window_s), int32(window_s)) + 1;
    total_data = total_wins*upwindow_s*4;
    data = zeros(total_data/10, 10);

    for inc = 1:total_wins
      for c_i = 1:4
        start_sample = (inc-1)*window_s + 1;
        stop_sample = (inc-1)*window_s + window_s;
        % disp("Samples:" + start_sample + " - " + stop_sample + "/" + s_data);
        x = signals(start_sample:stop_sample, c_i);
        frame = pr_resample(x, fs);
        x_upsampled = round(frame.*10);
        x_reshaped = reshape(x_upsampled, 10, []);
        x_reshaped2 = x_reshaped.';

        row_index = ((inc-1)*4+c_i-1)*upwindow_s/10;
        data(row_index+1:row_index + upwindow_s/10, :) = x_reshaped2;
      end % End for one file

      disp("Window : " + inc + "/" + total_wins);

    end % End for all files

    csvwrite("signals.csv", data);
end

%% Pattern Recognition function
% Input: signal with fs = 250Hz.
% Output: the predicted pattern class.
function [pred, mfcc_coeffs, frame] = pr_recognize(signal, org_fs)
  % Call this in Linux to prevent segfaults
  py.sys.setdlopenflags(int32(10));

  delete("input_signal.mat");
  save('input_signal.mat', '-v7.3');
  pyrunfile('sz_multi_patterns_recognition_250.py')
  load('output_prs.mat')

  pred = output;
end

function frame = pr_resample(signal, org_fs)
  % Call this in Linux to prevent segfaults
  py.sys.setdlopenflags(int32(10));

  delete("input_signal.mat");
  save('input_signal.mat', '-v7.3');
  pyrunfile('sz_resample.py')
  load('output_prs.mat')
end
