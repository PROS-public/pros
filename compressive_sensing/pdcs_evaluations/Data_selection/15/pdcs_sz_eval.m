%%%
% @file pdcs_eval.m
% @author  Nhat Pham <nhat.pham@cs.ox.ac.uk>.
% @version 1.0
% @date 11-Dec-2021
% @brief Combined pattern recognition + pattern-driven compressive sensing evaluation script.
% Input:
%   wduration: 2s-5s.
%%%

function MinhR =  pdcs_sz_eval(wduration)
%% Dataset folder location
%folder_location = "C:/Users/Nhat Pham/Desktop/pattern_driven_datasets_nov21/";
folder_location = "../../../pattern_driven_datasets_nov21/";

folder_path = folder_location + "/seizure_patterns/seizure_patterns_test/15_test/";
%folder_path = folder_location + "/microsleep/alpha_pattern_train/0/";
output_file_prefix = "sz_" + wduration + "_";
filename = "*.csv";

delete("pdcs_sz_eval.log");
diary pdcs_sz_eval_15_Minh_Subject9578.log

%% Pattern recognition models configurations
%focal_model_path = './pr_models/alpha_pr.tflite';
% focal_pr = py.tensorflow.lite.Interpreter(focal_model_path);
% focal_pr.allocate_tensors();

%% Compressive Sensing configurations
% Window sizes
fs = 250;
sliding_window = 1*fs; %3s
n = wduration * fs;
avg_window = 3;

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

% Logfile
% diary_filename = output_file_prefix + wname + "_" + n + "_" + datestr(datetime('now'), 30) + ".txt";
% diary(output_folder + diary_filename);

%% Find all the .csv files in the data folder.
folderinfo = dir(folder_path + filename);
folder_info_size = size(folderinfo, 1);

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

ssims = [];
preds = [];

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
        pred = sz_pattern_recognition(x , fs);
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

          preds = [preds avg_pred];
          preds_1file = [preds_1file avg_pred];
        end




        %% Perform compressive sensing.
%         y = phi * x;
%
%         % Perform recovery.
%         blkLen = 24;                  % the block size in the user-defined block partition
%         groupStartLoc = 1:blkLen:n;   % user-defined block partition
%
%         % run the algorithm
%         Result = BSBL_BO(A,y,groupStartLoc,0,'prune_gamma',-1, 'max_iters',20);
%
%         % restore recovered data
%         x_hat = real(focal_psi*Result.x);
%
%         windowLen = 200;
%         [mssim, ssim_map] = ssim_1d(x, x_hat, windowLen);
%
%         %disp("CF: " + n/m + ", SSIM: " + mssim);
%         ssims = [ssims mssim];
%         ssims_1file = [ssims_1file mssim];
    end % End for one file
    [GC,GR] = groupcounts(preds_1file');
    if size(GR, 1) == 2
      sens_1file = GC(2)/(GC(1) + GC(2));
    else
      sens_1file = 1;
    end
    disp("Sens: " + sens_1file);
    disp([GR, GC]);

    MinhR(index,1:3) = [sens_1file, ];

%     disp(ssims_1file);
%     disp("CF: " + n/m + ", SSIM: " + mean(ssims_1file));

end % End for all files

disp("---- Total Preds ----- : ")
[GC,GR] = groupcounts(preds');
disp([GR, GC]);
sens = GC(2)/(GC(1) + GC(2));
disp("Sens: " + sens);



% Calculate the mean
% mean_ssim = mean(ssims);
% avg_ssims = [avg_ssims mean_ssim];
%
% Ms = [Ms m];
% CFs = [CFs n/m];
%
% disp("-----------------------");
% disp(wname + ", M: " + m + ", mean_ssim: " + mean_ssim);
% disp("-----------------------");
%
% % Writing all ssim values.
% ssims_filename = output_folder + output_file_prefix + wname + "_" + m + "_" + n + "_ssims.csv";
% delete(ssims_filename);
% disp("Writing: " + ssims_filename);
% csvwrite(ssims_filename, ssims);

end

% Input: signal with fs = 250Hz
% Output: probabilities of each sz pattterns
function pred = sz_pattern_recognition(signal, org_fs)
    delete("input_signal.mat");
    save('input_signal.mat', '-v7.3');

    % Call this in Linux to prevent segfaults
    py.sys.setdlopenflags(int32(10));

    pyrunfile('sz_pattern_recognition_250.py')

    load('output_prs.mat')

    pred = output;



end
 