%%%
% @file pattern_test_samples_gen.m
% @author  Nhat Pham <nhat.pham@cs.ox.ac.uk>.
% @version 1.0
% @date 16-Dec-2021
% @brief Compressive sensing test samples generation.
%%%

pattern = 7;
num_of_test_samples = 3;
n = 250;

psi_matrix_folder = "./psi_matrices/";
%psi_matrix = "inv_sym5_250.csv"; % Eyemov
psi_matrix = "inv_bior6.8_250.csv"; % Focal

test_matrix_folder = "./phi_matrices/";
test_matrix = "Phi_bin_80x250.csv";

folder_location = "/Users/nhaham/Documents/GitHub/pros_nov_2021/pattern_driven_datasets_nov21/";
filename = "*.csv";

output_folder = "./test_samples/";

switch pattern
    case 1
        % Alpha wave
        folder_path = folder_location + "/microsleep/alpha_pattern_train/1/";
        output_file_prefix = "alpha_";
    case 2
        % Theta wave
        folder_path = folder_location + "/microsleep/theta_pattern_train/1/";
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
end

%% Find all the .csv files in the data folder.
folderinfo = dir(folder_path + filename);
folder_info_size = size(folderinfo, 1); 

for index = 2:num_of_test_samples+1
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
        
        start_sample = 1;
        stop_sample = n;
        x = round(data(start_sample:stop_sample));
        
        % Write x to file
        sample_varname = output_file_prefix + strrep(file.name, '.csv', '');
        c_filename = output_folder + output_file_prefix + strrep(file.name, '.csv', '.cc');
        delete(c_filename);
        fileID = fopen(c_filename, 'w');

        fprintf(fileID, '#include "compressive_sensing/pdcs_cs.h"\n');
        fprintf(fileID, '\n');
        fprintf(fileID, 'const q15_t %s[] = {\n', sample_varname);
        fprintf(fileID, ['    %d, %d, %d, %d, %d, %d, %d, %d, %d, %d,' ...
            ' %d, %d, %d, %d, %d, %d, %d, %d, %d, %d,\n'], x);
        fprintf(fileID, '};\n');

        fclose(fileID);
        
        % Calculate the matrix multiplication results
        phi = csvread(test_matrix_folder + test_matrix);
        y = phi*x;
        
        % Write y to file
        y_sample_varname = output_file_prefix + strrep(test_matrix, '.csv', '') + '_' + strrep(file.name, '.csv', '');
        y_c_filename = output_folder + output_file_prefix + strrep(test_matrix, '.csv', '') + '_' + strrep(file.name, '.csv', '.cc');
        delete(y_c_filename);
        fileID = fopen(y_c_filename, 'w');

        fprintf(fileID, '#include "compressive_sensing/pdcs_cs.h"\n');
        fprintf(fileID, '\n');
        fprintf(fileID, 'const q15_t %s[] = {\n', y_sample_varname);
        fprintf(fileID, ['    %d, %d, %d, %d, %d, %d, %d, %d, %d, %d,' ...
            ' %d, %d, %d, %d, %d, %d, %d, %d, %d, %d,\n'], y);
        fprintf(fileID, '};\n');

        fclose(fileID);
        
        % Test CS
        % Perform recovery.
        blkLen = 24;                  % the block size in the user-defined block partition
        groupStartLoc = 1:blkLen:n;   % user-defined block partition

        % run the algorithm
        psi = csvread(psi_matrix_folder + psi_matrix);
        A = phi*psi;
        Result = BSBL_BO(A,y,groupStartLoc,0,'prune_gamma',-1, 'max_iters',20);

        % restore recovered data
        x_hat = real(psi*Result.x);

        windowLen = 200;
        [mssim, ssim_map] = ssim_1d(x, x_hat, windowLen);
        
        figure;
        plot(x)
        hold on
        grid on
        plot(x_hat)
        legend('Original','Reconstruction')
        title('BSBL-BO: Original signal recovery')
        
        disp("SSIM: " + mssim);
end 