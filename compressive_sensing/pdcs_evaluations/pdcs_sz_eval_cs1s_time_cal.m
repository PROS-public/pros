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

function pdcs_sz_eval_cs1s(wduration)


global TimeRun TestNum;
TestNum = 1;
TimeRun = [];

  %% Dataset folder location
  folder_location = "../../../pattern_driven_datasets_nov21/";

  bg_folder = "/seizure_patterns/seizure_patterns_test/6/";
  focal_folder = "/seizure_patterns/seizure_patterns_test/8/";
  absence_folder = "/seizure_patterns/seizure_patterns_test/12/";
  gtc_folder = "/seizure_patterns/seizure_patterns_test/15/";

  all_folders = [gtc_folder absence_folder focal_folder bg_folder];
  all_folders_size = size(all_folders, 2);
  filename = "*.csv";

  mkdir("logs");
  % logfile = "logs/pdcs_sz_eval_cs1s_" + poi + "_" + wduration + "_" + datestr(datetime('now'), 30) + ".txt";
  logfile = "logs/pdcs_sz_eval_cs1s_" + wduration + ".txt";
  delete(logfile);
  diary(logfile);

  fs = 250;
  window_s = wduration*fs; % slide wduration s
  disp("===================");
  disp("Window size: " + window_s);

  %% Compressive Sensing configurations
  % Compressive window sizes, N = FS (1s window) seems to be the best peformance.
  n = fs;

  % Measurement matrix Phi
  phi_prefix = "./phi_matrices/Phi_bin_";
  phi_suffix = ".csv";

  % Basis matrix Psi
  psi_prefix = "./psi_matrices/inv_";
  psi_suffix = ".csv";

  % Output results
  output_folder = "pdcs_sz_eval_cs1s_results";
  mkdir(output_folder);

  %% Calculating CS matrices
  % Focal SZ patterns
  focal_wname = 'bior6.8';
  focal_cr = 5.5;
  focal_m = round((n/focal_cr)/5) * 5;

  disp("===================");
  disp("Focal Wavelet: " + focal_wname);
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

  % Absence SZ patterns
  absence_wname = 'bior4.4';
  absence_cr = 4.5;
  absence_m = round((n/absence_cr)/5) * 5;

  disp("===================");
  disp("Absence Wavelet: " + absence_wname);
  disp("Absence M: " + absence_m);

  % Reading measurement matrix Phi
  absence_phi_filename = phi_prefix + absence_m + "x" + n + phi_suffix;
  disp("Reading Absence measurement matrix: " + absence_phi_filename);
  absence_phi = csvread(absence_phi_filename);

  % Reading basis matrix Psi
  absence_psi_filename = psi_prefix + absence_wname + "_" + n + psi_suffix;
  disp("Reading absence basis matrix: " + absence_psi_filename);
  absence_psi = csvread(absence_psi_filename);

  absence_A = absence_phi*absence_psi;

  % Tonic-Clonic SZ patterns
  n_gtc = window_s; % CS for GTC will crash with small N so we use N = Windows Size.
  gtc_wname = 'sym14';
  gtc_cr = 2.2;
  gtc_m = round((n_gtc/gtc_cr)/5) * 5;

  disp("===================");
  disp("GTC Wavelet: " + gtc_wname);
  disp("GTC M: " + gtc_m);

  % Reading measurement matrix Phi
  gtc_phi_filename = phi_prefix + gtc_m + "x" + n_gtc + phi_suffix;
  disp("Reading GTC measurement matrix: " + gtc_phi_filename);
  gtc_phi = csvread(gtc_phi_filename);

  % Reading basis matrix Psi
  gtc_psi_filename = psi_prefix + gtc_wname + "_" + n_gtc + psi_suffix;
  disp("Reading GTC basis matrix: " + gtc_psi_filename);
  gtc_psi = csvread(gtc_psi_filename);

  gtc_A = gtc_phi*gtc_psi;

  %% Start running through all the data files.
  tp = 0; fp = 0; tn = 0; fn = 0;
  ssims = [];
  focal_ssims = []; absence_ssims = []; gtc_ssims = [];
  pos_preds = [];
  neg_preds = [];
  total_data = 0; pdcs_data = 0;

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
      if s_data < window_s
        stop_inc = 0;
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
        x = data(start_sample:stop_sample);

        %%%%%%%% Perform Pattern Recognition %%%%%%%%
         % sz_pattern_recognition(x, fs);

%% Minh switch case
    
        switch (folder_index)
            case 1
                pred =  15;
            case 2 
                pred =  12;
            case 3
                pred =  8;
            otherwise
                pred =  6;
        end 




        % disp("Pred: " + pred);

        if (folder_index ~= all_folders_size)
          % Negative folder is always the last one.
          % Positive folders
          pos_preds = [pos_preds pred];
          if (pred ~= 6)
            tp = tp + 1;
          else
            fp = fp + 1;
          end
        else
          % Negative folder
          neg_preds = [neg_preds pred];
          if (pred == 6)
            tn = tn + 1;
          else
            fn = fn + 1;
          end
        end

        total_data = total_data + window_s;
        preds_1file = [preds_1file pred];

        %%%%%%%% Perform compressive sensing %%%%%%%%
        if (pred ~= 6)
          ssims_1window = [];
          if (pred == 15)
            % CS for GTC will crash with small N so we use N = Windows Size.
            ssim = sz_compressive_sensing(x, gtc_phi, gtc_psi, gtc_A);
            ssims_1window = [ssims_1window ssim];
            pdcs_data = pdcs_data + gtc_m;
          else
            for cs_index = 1:wduration
              cs_start_sample = (cs_index-1)*fs + 1;
              cs_stop_sample = (cs_index-1)*fs + fs;
              cs_x = x(cs_start_sample:cs_stop_sample);

              switch pred
                case 8
                  ssim = sz_compressive_sensing(cs_x, focal_phi, focal_psi, focal_A);
                  ssims_1window = [ssims_1window ssim];
                  pdcs_data = pdcs_data + focal_m;
                case 12
                  ssim = sz_compressive_sensing(cs_x, absence_phi, absence_psi, absence_A);
                  ssims_1window = [ssims_1window ssim];
                  pdcs_data = pdcs_data + absence_m;
              end % End switch
            end % End for
          end % End if else

          % disp("Pred: " + pred + ", SSIM: " + mean(ssims_1window));
          ssims_1file = [ssims_1file mean(ssims_1window)];
          switch pred
            case 8
              focal_ssims = [focal_ssims mean(ssims_1window)];
            case 12
              absence_ssims = [absence_ssims mean(ssims_1window)];
            case 15
              gtc_ssims = [gtc_ssims mean(ssims_1window)];
          end

        else
          % disp("Pred: " + pred + ", skipped.");
        end

      end % End for one file
      [GC,GR] = groupcounts(preds_1file');
      disp([GR, GC]);
      disp("TP: " + tp + ", FP: " + fp + ", TN: " + tn + ", FN: " + fn);

      if (size(ssims_1file, 1) > 0)
        disp("Mean SSIM: " + mean(ssims_1file));
      end
      ssims = [ssims ssims_1file];
      % disp(ssims_1file);
      disp("Total Focal SSIMs: " + mean(focal_ssims));
      disp("Total Absence SSIMs: " + mean(absence_ssims));
      disp("Total GTC SSIMs: " + mean(gtc_ssims));
      disp("Total Mean SSIM: " + mean(ssims));
      disp("CF: " + total_data/pdcs_data + ", total_data: " + total_data + ", pdcs_data: " + pdcs_data);

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

  disp("---- Total Data and SSIM ----- : ")
  disp("CF: " + total_data/pdcs_data + ", Total SSIM: " + mean(ssims));
  disp("total_data: " + total_data + ", pdcs_data: " + pdcs_data);
  disp("Total Focal SSIMs: " + mean(focal_ssims));
  disp("Total Absence SSIMs: " + mean(absence_ssims));
  disp("Total GTC SSIMs: " + mean(gtc_ssims));

  output_ssims_file_prefix = "logs/pdcs_sz_eval_cs1s_" + wduration;
  output_ssims_file_suffix = ".csv";
  csvwrite(output_ssims_file_prefix + "_ssims" + output_ssims_file_suffix, ssims);
  csvwrite(output_ssims_file_prefix + "_focal_ssims" + output_ssims_file_suffix, focal_ssims);
  csvwrite(output_ssims_file_prefix + "_absence_ssims" + output_ssims_file_suffix, absence_ssims);
  csvwrite(output_ssims_file_prefix + "_gtc_ssims" + output_ssims_file_suffix, gtc_ssims);
end

%% Pattern Recognition function
% Input: signal with fs = 250Hz.
% Output: the predicted pattern class.
function pred = sz_pattern_recognition(signal, org_fs)
  % Call this in Linux to prevent segfaults
  py.sys.setdlopenflags(int32(10));

  delete("input_signal.mat");
  save('input_signal.mat', '-v7.3');
  pyrunfile('sz_multi_patterns_recognition_250.py')
  load('output_prs.mat')

  pred = output;
end

%% Execute compressive sensing on one signal window.
% Input: signal with fs = 250Hz, poi, window duration.
% Output: ssim after recovery.
function ssim = sz_compressive_sensing_1window(x, poi, wduration)

end

%% Execute compressive sensing on the input signal.
% Input: signal with fs = 250Hz, phi, psi, and A (phi*psi) matrices.
% Output: ssim after recovery.
function ssim = sz_compressive_sensing(x, phi, psi, A)
  y = phi * x;
  n = size(x,1);

  % Perform recovery.
  blkLen = 24;                  % the block size in the user-defined block partition
  groupStartLoc = 1:blkLen:n;   % user-defined block partition

  % run the algorithm
  %% 
  tic
  Result = BSBL_BO(A,y,groupStartLoc,0,'prune_gamma',-1, 'max_iters',20);
  T = toc;


global TimeRun TestNum;
TimeRun(TestNum) = T;
TestNum = TestNum + 1;

writematrix(TimeRun,'MinhTimeRun02.csv');




  % restore recovered data
  x_hat = real(psi*Result.x);

  windowLen = 200;
  [mssim, ssim_map] = ssim_1d(x, x_hat, windowLen);

  ssim = mssim;
end
