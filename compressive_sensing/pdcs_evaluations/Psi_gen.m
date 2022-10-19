clear;
clc;

output_folder = "./psi_matrices/";
filename_ext = ".csv";

% Generate inverse wavelet transform matrix
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

wnames_all = [wnames_db wnames_sym wnames_fk_coif wnames_bior wnames_rbio];

n_array = 250:250:1250;

num_n = size(n_array,2);
wnames = wnames_all;
num_wavelets = size(wnames,2);

level = 7; % DWT levels
keepapp = 1;

for w = 1:num_wavelets
    wname = char(wnames(w));

    disp("============================================");
    disp("Wavelet: " + wname);
    
    for index = 1:num_n
        n = n_array(index);
        disp("n: " + n);
        
        % Dummy DWT
        x = zeros(n,1);
        [c,l] = wavedec(x,level,wname);
        wsize = size(c,1);
        
        invW = zeros(n);
        XI2 = eye(wsize);

        for i=1:n
            [xd_2,cxd_2,lxd_2,perf0_2,perfl2_2] = ...
                wdencmp('gbl',XI2(:,i),l,wname,level,0,'h',keepapp);
            invW(:,i) = xd_2;
        end
        
        filename = output_folder + "inv_" + wname + "_" + n + filename_ext;
        delete(filename);
        csvwrite(filename, invW);
    end
end

