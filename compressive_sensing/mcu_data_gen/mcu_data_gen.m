%%%
% @file mcu_data_gen.m
% @author  Nhat Pham <nhat.pham@cs.ox.ac.uk>.
% @version 1.0
% @date 28-Feb-2021
% @brief Data generation for MCU evaluations.
%%%

function mcu_data_gen(wduration)
    %% Dataset folder location
    folder_location = "../../../pattern_driven_datasets_nov21/";

    bg_folder = "/seizure_patterns/seizure_patterns_test/6/";
    focal_folder = "/seizure_patterns/seizure_patterns_test/8/";
    absence_folder = "/seizure_patterns/seizure_patterns_test/12/";
    gtc_folder = "/seizure_patterns/seizure_patterns_test/15/";

    all_folders = [gtc_folder absence_folder focal_folder bg_folder];
    all_folder_names = [15 12 8 6];
    all_folders_size = size(all_folders, 2);
    filename = "*.csv";

    fs = 250;
    window_s = wduration*fs; % slide wduration s
    disp("===================");
    disp("Window size: " + window_s);

    %% Start running through all the data files.
    for folder_index = 1:all_folders_size
        % Find all the .csv files in the data folder.
        folder_path = folder_location + all_folders(folder_index);
        disp("Reading data from: " + folder_path);

        folderinfo = dir(folder_path + filename);
        folder_info_size = size(folderinfo, 1);

        data = [];
        total_data = 0;

        for index = 1:folder_info_size
          file = folderinfo(index);
          file_path = "" + file.folder + "/" + file.name;
          disp("===================");
          disp("File: " + index + "/" + folder_info_size);
          disp("Processing:" + file_path);

          raw_data = csvread(file_path);
          s_data = size(raw_data, 1);

          if s_data < window_s
            disp("Data size (" + s_data + ") < window_s (" + window_s + "). Skipping...");
            continue;
          else
            stop_inc = idivide(int32(s_data-window_s), int32(window_s)) + 1;
          end

          for inc = 1:stop_inc
            % if (inc == stop_inc)
            %     continue
            % end

            start_sample = (inc-1)*window_s + 1;
            stop_sample = (inc-1)*window_s + window_s;
            % disp("Samples:" + start_sample + " - " + stop_sample + "/" + s_data);
            x = raw_data(start_sample:stop_sample);
            frame = pr_resample(x, fs);
            x_upsampled = round(frame.*10);
            x_reshaped = reshape(x_upsampled, 10, []);
            x_reshaped2 = x_reshaped.';

            data = [data; x_reshaped2];
            total_data = total_data + window_s;
          end % End for one file

          disp("Total_data: " + total_data);

        end % End for all files

        output_file_prefix = "output/" + all_folder_names(folder_index) + "_" + wduration;
        output_file_suffix = ".csv";
        csvwrite(output_file_prefix + output_file_suffix, data);
    end % End for all folders
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
