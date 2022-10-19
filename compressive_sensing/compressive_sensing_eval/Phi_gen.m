clear;
clc;

output_folder = "./phi_matrices/";
filename_ext = ".csv";

% Generate inverse wavelet transform matrix

n_array = 250:250:1250;
m_step = 5;

num_n = size(n_array,2);

for n_index = 1:num_n
    disp("============================================");
    n = n_array(n_index);
    disp("n: " + n);
    
    m_array = 5:m_step:n;
    num_m = size(m_array,2);
    disp("m: ");
    disp(m_array);
    
    for m_index = 1:num_m
        m = m_array(m_index);
        
        Phi = randsrc(m,n,[0,1]); % Binary random matrix

        filename = output_folder + "Phi_bin_" + m + "x" + n + filename_ext;
        delete(filename);
        csvwrite(filename, Phi);
    end
end

