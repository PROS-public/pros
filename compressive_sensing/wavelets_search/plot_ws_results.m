clear all;
clc; close all; 

set(0,'DefaultFigureWindowStyle','docked');


results_folder = "./wavelets_search/";
%pattern = "alpha";
%pattern = "eyemov";
%pattern = "chewing";
%pattern = "shivering";
%pattern = "focal";
%pattern = "gen";

%pattern = "muscle";
%pattern = "tonic-clonic";


%pattern = "theta";
pattern = "absence";

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

% Read alpha wave sparsity files

%% dB wavelets
avg_db_sparsities = csvread(results_folder + pattern + "_1_avg_sparsities.csv");
[max_avg_db_sparsity, max_avg_db_sparsity_index] = max(avg_db_sparsities);
max_avg_db_sparsity_wnames = char(wnames_db(max_avg_db_sparsity_index));
max_avg_db_sparsity_data = csvread(results_folder + pattern + "_" + max_avg_db_sparsity_wnames + "_sparsities.csv");
max_avg_db_sparsity_stderror = std( max_avg_db_sparsity_data ) / sqrt( length( max_avg_db_sparsity_data ));
%wavefun(max_avg_db_sparsity_wnames,0);

figure;
subplot (1,2,2);
plot(avg_db_sparsities);
title(strcat("Average wavelet sparsities of the dB wavelet | MAX = ", num2str(max_avg_db_sparsity), "%"));
ylabel('Sparsity (%)')
xlabel('Wavelet index')
%ylim([70 85]) % Alpha
ylim([70 100]) % Eyemov

subplot (1,2,1);
[pi,psi,xval] = wavefun(max_avg_db_sparsity_wnames,10);
plot(xval,psi);
grid on
title(['Mother wavelet function: ',max_avg_db_sparsity_wnames])

figure(10); 
subplot (2,3,1);plot(xval,psi);grid on; title(['Mother wavelet function: ',max_avg_db_sparsity_wnames])



%% Sym wavelets
avg_sym_sparsities = csvread(results_folder + pattern + "_2_avg_sparsities.csv");
[max_avg_sym_sparsity, max_avg_sym_sparsity_index] = max(avg_sym_sparsities);
max_avg_sym_sparsity_wnames = char(wnames_sym(max_avg_sym_sparsity_index));
max_avg_sym_sparsity_data = csvread(results_folder + pattern + "_" + max_avg_sym_sparsity_wnames + "_sparsities.csv");
max_avg_sym_sparsity_stderror = std( max_avg_sym_sparsity_data ) / sqrt( length( max_avg_sym_sparsity_data ));

figure; subplot (1,2,2);
plot(avg_sym_sparsities);
title(strcat("Average wavelet sparsities of the SYM wavelets | MAX = ", num2str(max_avg_sym_sparsity), "%"));
ylabel('Sparsity (%)')
xlabel('Wavelet index')
%ylim([70 85]) % Alpha
ylim([70 100]) % Eyemov

 subplot (1,2,1);
[pi,psi,xval] = wavefun(max_avg_sym_sparsity_wnames,10);
plot(xval,psi)
grid on
title(['Mother wavelet function: ',max_avg_sym_sparsity_wnames])
figure(10); 
subplot (2,3,2);plot(xval,psi);grid on; title(['Mother wavelet function: ',max_avg_sym_sparsity_wnames])


%% FK and COIF wavelets
avg_fk_coif_sparsities = csvread(results_folder + pattern + "_3_avg_sparsities.csv");
[max_avg_fk_coif_sparsity, max_avg_fk_coif_sparsity_index] = max(avg_fk_coif_sparsities);
max_avg_fk_coif_sparsity_wnames = char(wnames_fk_coif(max_avg_fk_coif_sparsity_index));
max_avg_fk_coif_sparsity_data = csvread(results_folder + pattern + "_" + max_avg_fk_coif_sparsity_wnames + "_sparsities.csv");
max_avg_fk_coif_sparsity_stderror = std( max_avg_fk_coif_sparsity_data ) / sqrt( length( max_avg_fk_coif_sparsity_data ));


figure; subplot (1,2,2);
plot(avg_fk_coif_sparsities);
title(strcat("Average wavelet sparsities of the FK and COIF wavelets | MAX = ", num2str(max_avg_fk_coif_sparsity), "%"));
ylabel('Sparsity (%)')
xlabel('Wavelet index')
%ylim([70 85]) % Alpha
ylim([70 100]) % Eyemov

subplot (1,2,1);
[pi,psi,xval] = wavefun(max_avg_fk_coif_sparsity_wnames,10);
plot(xval,psi)
grid on
title(['Mother wavelet function: ',max_avg_fk_coif_sparsity_wnames])

figure(10); 
subplot (2,3,3);plot(xval,psi);grid on; title(['Mother wavelet function: ',max_avg_fk_coif_sparsity_wnames])



%% BIOR wavelets
avg_boir_sparsities = csvread(results_folder + pattern + "_4_avg_sparsities.csv");
[max_avg_boir_sparsity, max_avg_boir_sparsity_index] = max(avg_boir_sparsities);
max_avg_boir_sparsity_wnames = char(wnames_bior(max_avg_boir_sparsity_index));
max_avg_boir_sparsity_data = csvread(results_folder + pattern + "_" + max_avg_boir_sparsity_wnames + "_sparsities.csv");
max_avg_boir_sparsity_stderror = std( max_avg_boir_sparsity_data ) / sqrt( length( max_avg_boir_sparsity_data ));


figure; subplot (1,2,2);
plot(avg_boir_sparsities);
title(strcat("Average wavelet sparsities of the BIOR wavelets | MAX = ", num2str(max_avg_boir_sparsity), "%"));
ylabel('Sparsity (%)')
xlabel('Wavelet index')
%ylim([70 85]) % Alpha
ylim([70 100]) % Eyemov

 subplot (1,2,1);
[pi,psi,phi2,psi2,xval] = wavefun(max_avg_boir_sparsity_wnames,10);
plot(xval,psi)
grid on
title(['Mother wavelet function: ',max_avg_boir_sparsity_wnames])

figure(10); 
subplot (2,3,4);plot(xval,psi);grid on; title(['Mother wavelet function: ',max_avg_boir_sparsity_wnames])


%% RBIO wavelets
avg_rboi_sparsities = csvread(results_folder + pattern + "_5_avg_sparsities.csv");
[max_avg_rboi_sparsity, max_avg_rboi_sparsity_index] = max(avg_rboi_sparsities);
max_avg_rboi_sparsity_wnames = char(wnames_rbio(max_avg_rboi_sparsity_index));
max_avg_rboi_sparsity_data = csvread(results_folder + pattern + "_" + max_avg_rboi_sparsity_wnames + "_sparsities.csv");
max_avg_rboi_sparsity_stderror = std( max_avg_rboi_sparsity_data ) / sqrt( length( max_avg_rboi_sparsity_data ));


figure; subplot (1,2,2);
plot(avg_rboi_sparsities);
title(strcat("Average wavelet sparsities of the RBIO wavelets | MAX = ", num2str(max_avg_rboi_sparsity), "%"));
ylabel('Sparsity (%)')
xlabel('Wavelet index')
%ylim([70 85]) % Alpha
ylim([70 100]) % Eyemov

subplot (1,2,1);
[pi,psi,phi2,psi2,xval] = wavefun(max_avg_rboi_sparsity_wnames,10);
plot(xval,psi)
grid on
title(['Mother wavelet function: ',max_avg_rboi_sparsity_wnames])

figure(10); 
subplot (2,3,5);plot(xval,psi);grid on; title(['Mother wavelet function: ',max_avg_rboi_sparsity_wnames])


%% All
avg_sparsities = [avg_db_sparsities avg_sym_sparsities ...
    avg_fk_coif_sparsities avg_boir_sparsities avg_rboi_sparsities];
[max_all, max_all_index] = max(avg_sparsities);
max_all_wname = char(wnames_all(max_all_index));
[min_all, min_all_index] = min(avg_sparsities);
min_all_wname = char(wnames_all(min_all_index));

figure; 
plot(avg_sparsities);
title(strcat ("Average wavelet sparsities of all families | MAX = ", num2str(max_all),"% | at ",max_all_wname));
ylabel('Sparsity (%)')
xlabel('Wavelet index')
%ylim([70 85]) % Alpha
ylim([80 100]) % Eyemov

%% plot 5 in 1 figure 

