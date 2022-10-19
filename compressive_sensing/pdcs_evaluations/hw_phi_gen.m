%%%
% @file hw_phi_gen.m
% @author  Nhat Pham <nhat.pham@cs.ox.ac.uk>.
% @version 1.0
% @date 16-Dec-2021
% @brief Compressive sensing Phi matrices generation.
%%%

folder_path = "./phi_matrices/";
filename = "*.csv";

%% Find all the .csv files in the data folder.
folderinfo = dir(folder_path + filename);
folder_info_size = size(folderinfo, 1); 

for index = 1:folder_info_size
        file = folderinfo(index);
        file_path = "" + file.folder + "/" + file.name;
        disp("===================");
        disp("File: " + index + "/" + folder_info_size);
        disp("Processing:" + file_path);
        
        data = (csvread(file_path)).';
        
        % Open file
        c_filename = strrep(file_path, '.csv', '.cc');
        phi_varname = strrep(file.name, '.csv', '');
        delete(c_filename);
        fileID = fopen(c_filename, 'w');

        fprintf(fileID, '#include "compressive_sensing/pdcs_cs.h"\n');
        fprintf(fileID, '\n');
        fprintf(fileID, 'const q7_t %s[] = {\n', phi_varname);
        fprintf(fileID, ['    %d, %d, %d, %d, %d, %d, %d, %d, %d, %d,' ...
            ' %d, %d, %d, %d, %d, %d, %d, %d, %d, %d,\n'], data);
        fprintf(fileID, '};\n');

        fclose(fileID);
end 