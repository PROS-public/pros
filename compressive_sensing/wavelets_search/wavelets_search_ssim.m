function wavelets_search_ssim(wavelet_range, pattern)

%% List of wavelets
wnames_db = {'db1', 'db2', 'db3', 'db4', 'db5', ...
         'db6', 'db7', 'db8', 'db9', 'db10', ...
         'db11', 'db12', 'db13', 'db14', 'db15'}; % dB wavelets

wnames_sym = {'sym2', 'sym3', 'sym4', 'sym5', 'sym6', 'sym7', 'sym8', ...
         'sym9', 'sym10', 'sym11', 'sym12', 'sym13', 'sym14', 'sym15'};

wnames_fk_coif = {'fk4', 'fk6', 'fk8', 'fk14', 'fk18', 'fk22', ...
         'coif1', 'coif2', 'coif3', 'coif4', 'coif5'};

wnames_bior = {'bior1.1', 'bior1.3', 'bior1.5', 'bior2.2', 'bior2.4',...
         'bior2.6', 'bior2.8', 'bior3.1', 'bior3.3', 'bior3.5',...
         'bior3.7', 'bior3.9', 'bior4.4', 'bior5.5', 'bior6.8'};

wnames_rbio = {'rbio1.1', 'rbio1.3', 'rbio1.5', 'rbio2.2', 'rbio2.4',...
         'rbio2.6', 'rbio2.8', 'rbio3.1', 'rbio3.3', 'rbio3.5',...
         'rbio3.7', 'rbio3.9', 'rbio4.4', 'rbio 5.5', 'rbio 6.8'};

switch wavelet_range
    case 1
        disp("Searching for DB wavelets.");
        wnames = wnames_db;
    case 2
        disp("Searching for SYM wavelets.");
        wnames = wnames_sym;
    case 3
        disp("Searching for FK and COIF wavelets.");
        wnames = wnames_fk_coif;
    case 4
        disp("Searching for BIOR wavelets.");
        wnames = wnames_bior;
    case 5
        disp("Searching for RBIO wavelets.");
        wnames = wnames_rbio;
    otherwise
        disp("Could not find wnames, Aborting...");
        return;
end

disp(wnames);
disp("---------------------")

%% Calculate the sparisties for each wavelet for all the signal segement of a pattern.
% Dataset folder location
%folder_location = "C:/Users/nhahamadmin/Desktop/pattern_driven_datasets_nov21/";
folder_location = "../../../pattern_driven_datasets_nov21/";
% /Volumes/BackupSSD/pros_nov_2021/
% folder_path = folder_location + ...
%     "/microsleep/alpha_pattern_data/1/";

switch pattern
    case 1
        % Alpha wave
        folder_path = folder_location + "/microsleep/alpha_pattern_data/1/";
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

% EOG data


filename = "*.csv";

output_folder = "./wavelets_search/";

%% Find all the .csv files in the data folder.
folderinfo = dir(folder_path + filename);
folder_info_size = size(folderinfo, 1);

%% Run for all wavelets
num_wavelets = size(wnames,2);

avg_ssims = [];
avg_sparsities = [];
avg_thrs = [];

for w = 1:num_wavelets
    wname = char(wnames(w));

    disp("============================================");
    disp("Wavelet: " + wname);

    ssims = [];
    sparsities = [];
    thrs = [];

    for index = 1:folder_info_size
        file = folderinfo(index);
        file_path = "" + file.folder + "/" + file.name;
        disp("===");
        disp("Wavelet " + w + "/" + num_wavelets + ":" + wname);
        disp("Session: " + index);
        disp("Processing:" + file_path);

        data = csvread(file_path);
        fs = 250;
        x = data;

        [ssim, sparsity, thr] = finding_threshold_wavelet(x, wname);
        disp("Best SSIM: " + ssim + ", Best Sparsity: " + sparsity + ", Best Thr: " ...
            + thr);

        ssims = [ssims ssim];
        sparsities = [sparsities sparsity];
        thrs = [thrs thr];
    end

    % Calculate the mean
    mean_ssim = mean(ssims);
    mean_sparsity = mean(sparsities);
    mean_thr = mean(thrs);

    avg_ssims = [avg_ssims mean_ssim];
    avg_sparsities = [avg_sparsities mean_sparsity];
    avg_thrs = [avg_thrs mean_thr];

    disp("-----------------------");
    disp(wname + ": mean_sparsity" + mean_sparsity + ", mean_ssim: " ...
        + mean_ssim + ", mean_thr: " + mean_thr);
    disp("-----------------------");

    % Writing data down.
    ssims_filename = output_folder + output_file_prefix + wname + "_ssims.csv";
    delete(ssims_filename);
    disp("Writing: " + ssims_filename);
    csvwrite(ssims_filename, ssims);

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
avg_ssims_filename = output_folder + output_file_prefix + wavelet_range + "_avg_ssims.csv";
delete(avg_ssims_filename);
disp("Writing: " + avg_ssims_filename);
csvwrite(avg_ssims_filename, avg_ssims);

avg_sparsities_filename = output_folder + output_file_prefix + wavelet_range + "_avg_sparsities.csv";
delete(avg_sparsities_filename);
disp("Writing: " + avg_sparsities_filename);
csvwrite(avg_sparsities_filename, avg_sparsities);

avg_thrs_filename = output_folder + output_file_prefix + wavelet_range + "_avg_thrs.csv";
delete(avg_thrs_filename);
disp("Writing: " + avg_thrs_filename);
csvwrite(avg_thrs_filename, avg_thrs);

end

%% Finding the best optimal threshold
function [best_ssim, best_sparsity, best_thr] = finding_threshold_wavelet(x, wname)
    best_thr = 0.1;
    [best_ssim, best_sparsity] = sparsity_wavelet_ssim(x, wname, best_thr);
    for thr = 0.2:0.1:1000
        [ssim, sparsity] = sparsity_wavelet_ssim(x, wname, thr);
        if ssim < 0.9
            break;
        elseif sparsity > best_sparsity
            best_ssim = ssim;
            best_sparsity = sparsity;
            best_thr = thr;
        end
    end
end

%% Wavelet calcualtions function
function [ssim, sparsity] = sparsity_wavelet_ssim(x, wname, thr)
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
    windowLen = 100;
    [ssim, ssim_map] = ssim_1d(x, xd, windowLen);
    sparsity = perf0;
end
