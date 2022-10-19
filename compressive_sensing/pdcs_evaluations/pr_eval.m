%%%
% @file pdcs_eval.m
% @author  Nhat Pham <nhat.pham@cs.ox.ac.uk>.
% @version 1.0
% @date 11-Dec-2021
% @brief Combined pattern recognition + pattern-driven compressive sensing evaluation script.
% Input:
% poi: 8 (focal), 12 (absence), 15 (gtc). Positive POI.
% wduration: 2s-5s.
% is_sld: 1, sliding 1s window and do majority voting.
%%%

function pr_eval(poi, wduration, is_sld)
  %% Dataset folder location
  folder_location = "../../../pattern_driven_datasets_nov21/";

  bg_folder = "/seizure_patterns/seizure_patterns_test/6/";
  focal_folder = "/seizure_patterns/seizure_patterns_test/8/";
  absence_folder = "/seizure_patterns/seizure_patterns_test/12/";
  gtc_folder = "/seizure_patterns/seizure_patterns_test/15/";

  switch poi
    case 8
    pos_folder = focal_folder;
    neg_folders = [bg_folder, absence_folder, gtc_folder];
    case 12
    pos_folder = absence_folder;
    neg_folders = [bg_folder, focal_folder, gtc_folder];
    case 15
    pos_folder = gtc_folder;
    neg_folders = [bg_folder, focal_folder, absence_folder];
  end

  all_folders = [pos_folder neg_folders];
  all_folders_size = size(all_folders, 2);
  filename = "*.csv";

  mkdir("logs");
  % logfile = "logs/pdcs_sz_eval_" + poi + "_" + wduration + "_" + datestr(datetime('now'), 30) + ".txt";
  logfile = "logs/pr_sz_eval_" + poi + "_" + wduration + "_" + is_sld + ".txt";
  % delete(logfile);
  diary(logfile);

  output_file_prefix = "sz_" + wduration + "_";

  %% Compressive Sensing configurations
  % Window sizes
  fs = 250;
  n = wduration * fs;

  if (is_sld == 0)
    sliding_window = wduration*fs; % slide wduration s
    avg_window = 1; % no majority voting.
  else
    sliding_window = 1*fs; % slide 1s
    avg_window = wduration; % do majority voting every wduration windows.
  end

  disp("===================");
  disp("sliding_window: " + sliding_window + ", " + "avg_window: " + avg_window);

  % Compression Wavelet
  focal_wname = 'bior6.8';
  focal_cr = 25;
  focal_m = round(n*focal_cr/500) * 5;

  gen_wname = 'db4';
  gen_cr = 20;
  gen_m = round(n*gen_cr/500) * 5;

  gtc_wname = 'sym14';
  gtc_cr = 50;
  gtc_m = round(n*gtc_cr/500) * 5;

  % Measurement matrix Phi
  phi_prefix = "./phi_matrices/Phi_bin_";
  phi_suffix = ".csv";

  % Basis matrix Psi
  psi_prefix = "./psi_matrices/inv_";
  psi_suffix = ".csv";

  % Output results
  output_folder = "./pdcs_sz_eval_results/";

  %% Calculating CS matrices
  % Focal SZ patterns
  disp("===================");
  disp("Focal Wavelet: " + focal_wname);
  focal_m = round(n*focal_cr/500) * 5;
  disp("Focal M: " + focal_m);

  % Reading measurement matrix Phi
  focal_phi_filename = phi_prefix + focal_m + "x" + n + phi_suffix;
  disp("Reading focal measurement matrix: " + focal_phi_filename);
  focal_phi = csvread(focal_phi_filename);

  % Reading basis matrix Psi
  focal_psi_filename = psi_prefix + focal_wname + "_" + n + psi_suffix;
  disp("Reading focal basis matrix: " + focal_psi_filename);
  focal_psi = csvread(focal_psi_filename);

  focal_A = focal_phi*focal_psi;

  % Generalized SZ patterns
  disp("===================");
  disp("Gen Wavelet: " + gen_wname);
  gen_m = round(n*gen_cr/500) * 5;
  disp("Gen M: " + gen_m);

  % Reading measurement matrix Phi
  gen_phi_filename = phi_prefix + gen_m + "x" + n + phi_suffix;
  disp("Reading Gen measurement matrix: " + gen_phi_filename);
  gen_phi = csvread(gen_phi_filename);

  % Reading basis matrix Psi
  gen_psi_filename = psi_prefix + gen_wname + "_" + n + psi_suffix;
  disp("Reading Gen basis matrix: " + gen_psi_filename);
  gen_psi = csvread(gen_psi_filename);

  gen_A = gen_phi*gen_psi;

  % Tonic-Clonic SZ patterns
  disp("===================");
  disp("GTC Wavelet: " + gtc_wname);
  gtc_m = round(n*gtc_cr/500) * 5;
  disp("GTC M: " + gtc_m);

  % Reading measurement matrix Phi
  gtc_phi_filename = phi_prefix + gtc_m + "x" + n + phi_suffix;
  disp("Reading GTC measurement matrix: " + gtc_phi_filename);
  gtc_phi = csvread(gtc_phi_filename);

  % Reading basis matrix Psi
  gtc_psi_filename = psi_prefix + gtc_wname + "_" + n + psi_suffix;
  disp("Reading GTC basis matrix: " + gtc_psi_filename);
  gtc_psi = csvread(gtc_psi_filename);

  gtc_A = gtc_phi*gtc_psi;

  %% Start running through all the data files.
  tp = 0; fp = 0; tn = 0; fn = 0;
  ssims = [];
  pos_preds = [];
  neg_preds = [];

  for folder_index = 1:all_folders_size
    % Find all the .csv files in the data folder.
    folder_path = folder_location + all_folders(folder_index);
    disp("Reading data from: " + folder_path);

    folderinfo = dir(folder_path + filename);
    folder_info_size = size(folderinfo, 1);

    for index = 1:folder_info_size
      file = folderinfo(index);
      file_path = "" + file.folder + "/" + file.name;
      disp("===================");
      disp("File: " + index + "/" + folder_info_size);
      disp("Processing:" + file_path);

      data = csvread(file_path);
      s_data = size(data, 1);

      if (n > s_data)
        disp("Data size (" + s_data + ") < N (" + n + "). Skipping...");
        continue;
      end

      ssims_1file = [];
      preds_1file = [];
      stop_inc = idivide(int32(s_data-n), int32(sliding_window)) + 1;

      preds_his = [];
      preds_count = 0;
      for inc = 1:stop_inc
        % if (inc == stop_inc)
        %     continue
        % end

        start_sample = (inc-1)*sliding_window + 1;
        stop_sample = (inc-1)*sliding_window + n;
        x = data(start_sample:stop_sample);

        % disp("Samples:" + start_sample + " - " + stop_sample + "/" + s_data);

        %% Perform Pattern Recognition
        pred = sz_pattern_recognition(poi, x, fs);
        % disp("Pred: " + pred);
        preds_count = preds_count + 1;
        preds_his = [preds_his pred];

        if (inc == 1)
          preds_count = avg_window;
        end

        if (preds_count == avg_window)
          % disp("---");
          avg_pred = round(mean(preds_his));
          % disp(preds_his);
          % disp("Avg Pred: " + mean(preds_his));
          % disp("Avg Pred: " + avg_pred);
          % disp("==========");
          preds_count = 0;
          preds_his = [];

          if (folder_index == 1)
            % Positive folder
            pos_preds = [pos_preds avg_pred];
            if (avg_pred == 1)
              tp = tp + 1;
            else
              fp = fp + 1;
            end
          else
            % Negative folders
            neg_preds = [neg_preds avg_pred];
            if (avg_pred == 0)
              tn = tn + 1;
            else
              fn = fn + 1;
            end
          end

          preds_1file = [preds_1file avg_pred];
        end

      end % End for one file
      [GC,GR] = groupcounts(preds_1file');
      disp([GR, GC]);
      disp("TP: " + tp + ", FP: " + fp + ", TN: " + tn + ", FN: " + fn);

    end % End for all files
  end % End for all folders

  disp("---- Total Positive Preds ----- : ")
  [GC,GR] = groupcounts(pos_preds');
  disp([GR, GC]);

  disp("---- Total Negative Preds ----- : ")
  [GC,GR] = groupcounts(neg_preds');
  disp([GR, GC]);

  disp("TP: " + tp + ", FP: " + fp + ", TN: " + tn + ", FN: " + fn);
  sens = tp/(tp + fp);
  spec = tn/(tn + fn);
  gmean = sqrt(sens*spec);
  disp("Gmean: " + gmean + ", Sens: " + sens + ", Spec: " + spec);

end

% Input: signal with fs = 250Hz
% Output: probabilities of each sz pattterns
function pred = sz_pattern_recognition(poi, signal, org_fs)
  delete("input_signal.mat");
  save('input_signal.mat', '-v7.3');

  % Call this in Linux to prevent segfaults
  py.sys.setdlopenflags(int32(10));

  pyrunfile('sz_pattern_recognition_250.py')

  load('output_prs.mat')

  pred = output;
end
