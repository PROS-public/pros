%%%
% @file compressive_sensing_eval.m
% @author  Nhat Pham <nhat.pham@cs.ox.ac.uk>.
% @version 1.0
% @date 11-Dec-2021
% @brief Compressive sensing evaluation script.
% Input: 
%   pattern: 1: alpha, 2: theta, 3: eyemov, 4: chewing, 5: shivering, 
%            6: muscle, 7: focal, 8: gen, 9: tonic-clonic.
%   wname: wavelet name
%   n: window size
%%%

function compressive_sensing_eval(pattern, wname, n)

%% Calculate the sparisties for each wavelet for all the signal segement of a pattern.
% Dataset folder location
folder_location = "../../../pattern_driven_datasets_nov21/";
%folder_location = "/Users/nhaham/Documents/GitHub/pros_nov_2021/pattern_driven_datasets_nov21/";

% /Volumes/BackupSSD/pros_nov_2021/
% folder_path = folder_location + ...
%     "/microsleep/alpha_pattern_data/1/";

switch pattern
    case 1
        % Alpha wave
        folder_path = folder_location + "/microsleep/alpha_pattern_train/1/";
        output_file_prefix = "alpha_";
    case 2
        % Theta wave
        folder_path = folder_location + "/microsleep/theta_pattern_data/1/";
        output_file_prefix = "theta_";
    case 3
        folder_path = folder_location + "/eog_emg_patterns/eog_emg_patterns_train/21/";
        output_file_prefix = "eyemov_";
    case 4
        folder_path = folder_location + "/eog_emg_patterns/eog_emg_patterns_train/22/";
        output_file_prefix = "chewing_";
    case 5
        folder_path = folder_location + "/eog_emg_patterns/eog_emg_patterns_train/23/";
        output_file_prefix = "shivering_";
    case 6
        folder_path = folder_location + "/eog_emg_patterns/eog_emg_patterns_train/24/";
        output_file_prefix = "muscle_";
    case 7
        folder_path = folder_location + "/seizure_patterns/seizure_patterns_train/8/";
        output_file_prefix = "focal_";
    case 8
        folder_path = folder_location + "/seizure_patterns/seizure_patterns_train/9/";
        output_file_prefix = "gen_";
    case 9
        folder_path = folder_location + "/seizure_patterns/seizure_patterns_train/15/";
        output_file_prefix = "tonic-clonic_";
    case 10
        folder_path = folder_location + "/seizure_patterns/seizure_patterns_train/12/";
        output_file_prefix = "absence_";
end

filename = "*.csv";

% Measurement matrix Phi
phi_prefix = "./phi_matrices/Phi_bin_";
phi_suffix = ".csv";

% Basis matrix Psi
psi_prefix = "./psi_matrices/inv_";
psi_suffix = ".csv";

% Output results
output_folder = "./cs_eval_results/";

% Logfile
diary_filename = output_file_prefix + wname + "_" + n + "_" + datestr(datetime('now'), 30) + ".txt";
diary(output_folder + diary_filename);

%% Find all the .csv files in the data folder.
folderinfo = dir(folder_path + filename);
folder_info_size = size(folderinfo, 1);

avg_ssims = [];
Ms = [];
CFs = [];
for cr = 1:5:100
    disp("===================");
    disp("Wavelet: " + wname);
    m = round(n*cr/500) * 5;
    disp("M: " + m);
    
    % Reading measurement matrix Phi
    phi_filename = phi_prefix + m + "x" + n + phi_suffix;
    disp("Reading measurement matrix: " + phi_filename);
    phi = csvread(phi_filename);
    
    % Reading basis matrix Psi
    psi_filename = psi_prefix + wname + "_" + n + psi_suffix;
    disp("Reading basis matrix: " + psi_filename);
    psi = csvread(psi_filename);
    
    A = phi*psi;
    
    ssims = [];
    
    for index = 1:folder_info_size
        file = folderinfo(index);
        file_path = "" + file.folder + "/" + file.name;
        disp("===================");
        disp("Wavelet: " + wname);
        disp("M: " + m);
        disp("File: " + index + "/" + folder_info_size);
        disp("Processing:" + file_path);
        
        data = csvread(file_path);
        fs = 250;
        s_data = size(data, 1);
        
        if (n > s_data)
            disp("Data size (" + s_data + ") < N (" + n + "). Skipping...");
            continue;
        end
        
        ssims_1file = [];
        stop_inc = idivide(int32(s_data-n), int32(fs)) + 1;
        for inc = 1:stop_inc
            start_sample = (inc-1)*fs + 1;
            stop_sample = (inc-1)*fs + n;
            x = data(start_sample:stop_sample);
            
            %disp("Samples:" + start_sample + " - " + stop_sample + "/" + s_data);
            
            % Perform compressive sensing.
            y = phi * x;
            
            % Perform recovery.
            blkLen = 24;                  % the block size in the user-defined block partition
            groupStartLoc = 1:blkLen:n;   % user-defined block partition
            
            % run the algorithm
            Result = BSBL_BO(A,y,groupStartLoc,0,'prune_gamma',-1, 'max_iters',20);
            
            % restore recovered data
            x_hat = real(psi*Result.x);
            
            windowLen = 200;
            [mssim, ssim_map] = ssim_1d(x, x_hat, windowLen);
            
            %disp("CF: " + n/m + ", SSIM: " + mssim);
            ssims = [ssims mssim];
            ssims_1file = [ssims_1file mssim];
        end % End for one file
        disp(ssims_1file);
        disp("CF: " + n/m + ", SSIM: " + mean(ssims_1file));
        
    end % End for one m
    
    % Calculate the mean
    mean_ssim = mean(ssims);    
    avg_ssims = [avg_ssims mean_ssim];

    Ms = [Ms m];
    CFs = [CFs n/m];
    
    disp("-----------------------");
    disp(wname + ", M: " + m + ", mean_ssim: " + mean_ssim);
    disp("-----------------------");
    
    % Writing all ssim values.
    ssims_filename = output_folder + output_file_prefix + wname + "_" + m + "_" + n + "_ssims.csv";
    delete(ssims_filename);
    disp("Writing: " + ssims_filename);
    csvwrite(ssims_filename, ssims);
end

% Writing average ssims of all m.
avg_ssims_filename = output_folder + output_file_prefix + wname + "_" + n + "_avg_ssims.csv";
delete(avg_ssims_filename);
disp("Writing: " + avg_ssims_filename);
csvwrite(avg_ssims_filename, avg_ssims);

Ms_filename = output_folder + output_file_prefix + wname + "_" + n + "_Ms.csv";
delete(Ms_filename);
disp("Writing: " + Ms_filename);
csvwrite(Ms_filename, Ms);

CFs_filename = output_folder + output_file_prefix + wname + "_" + n + "_CFs.csv";
delete(CFs_filename);
disp("Writing: " + CFs_filename);
csvwrite(CFs_filename, CFs);
end
