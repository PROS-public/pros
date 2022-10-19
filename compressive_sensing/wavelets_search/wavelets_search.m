clear;
clc;

%% List of wavelets
wnames = {'db1', 'db2', 'db3', 'db4', 'db5', ...
         'db6', 'db7', 'db8', 'db9', 'db10', ...
         'sym2', 'sym3', 'sym4', 'sym5', 'sym6', 'sym7', 'sym8', ...
         'coif2', 'coif3', 'coif4', 'coif5', ...
         'bior1.3', 'bior1.5', 'bior2.2', 'bior2.6', ...
         'bior2.8', 'bior3.1', 'bior3.3', 'bior4.4', ...
         'bior5.5', 'bior6.8'};

%% Calculate the sparisties for each wavelet for all the signal segement of a pattern.
% EEG
folder_location = "C:/Users/Nhat Pham/Desktop/GithubRepos/pros_nov_2021/pattern_driven_datasets_nov21/";
% /Vo
% 
% lumes/BackupSSD/pros_nov_2021/
% folder_path = folder_location + ...
%     "/microsleep/alpha_pattern_data/1/";
folder_path = folder_location + ...
    "/eog_emg_patterns/eog_emg_patterns_train/21/";
filename = "*.csv";

output_folder = "./wavelets_search/";
%output_file_prefix = "alpha_";
output_file_prefix = "eyemov_";

%% Find all the .csv files in the data folder.
folderinfo = dir(folder_path + filename);
folder_info_size = size(folderinfo, 1);

%% Run for all wavelets
num_wavelets = size(wnames,2);

avg_prds = [];
avg_sparsities = [];
avg_thrs = [];

for w = 1:num_wavelets
    wname = char(wnames(w));

    disp("============================================");
    disp("Wavelet: " + wname);
    
    prds = [];
    sparsities = [];
    thrs = [];

    for index = 1:folder_info_size
        file = folderinfo(index);
        file_path = "" + file.folder + "/" + file.name;
        disp("===");
        disp("Session: " + index);
        disp("Processing:" + file_path);

        data = csvread(file_path);
        fs = 250;
        x = data;

        [PRD, sparsity, thr] = finding_threshold_wavelet(x, wname);
        disp("Best PRD: " + PRD + ", Best Sparsity: " + sparsity + ", Best Thr: " ...
            + thr);

        prds = [prds PRD];
        sparsities = [sparsities sparsity];
        thrs = [thrs thr];
    end
    
    % Calculate the mean
    mean_prd = mean(prds);
    mean_sparsity = mean(sparsities);
    mean_thr = mean(thrs);
    
    avg_prds = [avg_prds mean_prd];
    avg_sparsities = [avg_sparsities mean_sparsity];
    avg_thrs = [avg_thrs mean_thr];
    
    disp("-----------------------");
    disp(wname + ": mean_sparsity" + mean_sparsity + ", mean_prd: " ...
        + mean_prd + ", mean_thr: " + mean_thr);
    disp("-----------------------");
    
    % Writing data down.
    prds_filename = output_folder + output_file_prefix + wname + "_prds.csv";
    delete(prds_filename);
    disp("Writing: " + prds_filename);
    csvwrite(prds_filename, prds);
    
    sparsities_filename = output_folder + output_file_prefix + wname + "_sparsities.csv";
    delete(sparsities_filename);
    disp("Writing: " + sparsities_filename);
    csvwrite(sparsities_filename, sparsities);
    
    thrs_filename = output_folder + output_file_prefix + wname + "_thrs.csv";
    delete(thrs_filename);
    disp("Writing: " + thrs_filename);
    csvwrite(thrs_filename, thrs);
end

% Writing data down.
prds_filename = output_folder + output_file_prefix + "avg_prds.csv";
delete(prds_filename);
disp("Writing: " + prds_filename);
csvwrite(prds_filename, avg_prds);

sparsities_filename = output_folder + output_file_prefix + "avg_sparsities.csv";
delete(sparsities_filename);
disp("Writing: " + sparsities_filename);
csvwrite(sparsities_filename, avg_sparsities);

thrs_filename = output_folder + output_file_prefix + "avg_thrs.csv";
delete(thrs_filename);
disp("Writing: " + thrs_filename);
csvwrite(thrs_filename, avg_thrs);

%% Finding the best optimal threshold
function [best_prd, best_sparsity, best_thr] = finding_threshold_wavelet(x, wname)
    best_thr = 0.01;
    [best_prd, best_sparsity] = sparsity_wavelet(x, wname, best_thr);
    for thr = 0.02:0.01:1000
        [prd, sparsity] = sparsity_wavelet(x, wname, thr);
        if prd > 9
            break;
        elseif sparsity > best_sparsity
            best_prd = prd;
            best_sparsity = sparsity;
            best_thr = thr;
        end
    end  
end

%% Wavelet calcualtions function
function [PRD, sparsity] = sparsity_wavelet(x, wname, thr)
    level = 7;
    [c,l] = wavedec(x, level, wname);
    approx = appcoef(c, l, wname);

    if level == 1
        [cd1] = detcoef(c,l,[1]);
    elseif level == 2
        [cd1,cd2] = detcoef(c,l,[1 2]);
    elseif level == 3
        [cd1,cd2,cd3] = detcoef(c,l,[1 2 3]);
    elseif level == 4
        [cd1,cd2,cd3,cd4] = detcoef(c,l,[1 2 3 4]);
    elseif level == 5
        [cd1,cd2,cd3,cd4,cd5] = detcoef(c,l,[1 2 3 4 5]);
    elseif level == 6
        [cd1,cd2,cd3,cd4,cd5,cd6] = detcoef(c,l,[1 2 3 4 5 6]);
    elseif level == 7
        [cd1,cd2,cd3,cd4,cd5,cd6,cd7] = detcoef(c,l,[1 2 3 4 5 6 7]);
    elseif level == 8
        [cd1,cd2,cd3,cd4,cd5,cd6,cd7,cd8] = detcoef(c,l,[1 2 3 4 5 6 7 8]);
    end

    % Compress using a fixed threshold.
    keepapp = 1;
    [xd,cxd,lxd,perf0,perfl2] = ...
        wdencmp('gbl',c,l,wname,level,thr,'h',keepapp);

%     figure;
%     plot(x)
%     hold on
%     grid on
%     plot(xd)
%     legend('Original','Reconstruction')

    PRD = (norm(x - xd)/norm(x))*100;
    sparsity = perf0;
end