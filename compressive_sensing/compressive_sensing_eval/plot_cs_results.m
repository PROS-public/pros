results_folder = "./cs_eval_results/";
% pattern = "alpha";
% wname = 'bior6.8';

% pattern = "theta";
% wname = 'bior4.4';

% pattern = "chewing";
% wname = 'bior4.4';

%pattern = "shivering";

%  pattern = "focal";
%  wname = 'bior6.8';

% pattern = "gen";
% wname = 'bior4.4';

pattern = "muscle";
wname = 'sym5';

% pattern = "tonic-clonic";
% wname = 'sym14';

% pattern = "eyemov";
% wname = 'sym5'; % eyemov

%  pattern = "absence";
%  wname = 'bior4.4'; % eyemov

N = 750;

% Read avg ssims, Ms, and CFs files

%% dB wavelets
avg_ssims = csvread(results_folder + pattern + "_" + wname + "_" + N + "_avg_ssims.csv");
Ms = csvread(results_folder + pattern + "_" + wname + "_" + N + "_Ms.csv");
CFs = csvread(results_folder + pattern + "_" + wname + "_" + N + "_CFs.csv");

figure;
plot(CFs, avg_ssims);
title("Compression factors vs. Similarity Index (SSIM) (N = " + N + " )");
ylabel('SSIM')
xlabel('Compression factor')
xlim([1 6]);
%ylim([70 85]) % Alpha
%ylim([70 100]) % Eyemov

figure;
plot(Ms, avg_ssims);
title("Compression factors vs. Similarity Index (SSIM) (N = " + N + " )");
ylabel('SSIM')
xlabel('Compressed window size (M)')
%ylim([70 85]) % Alpha
%ylim([70 100]) % Eyemov

% Find Ns and CFs with SSIM >0.8, 0.85, 0.9, 0.95
M_80 = Ms(find( avg_ssims > 0.8, 1 ));
M_85 = Ms(find( avg_ssims > 0.85, 1 ));
M_90 = Ms(find( avg_ssims > 0.9, 1 ));
M_95 = Ms(find( avg_ssims > 0.95, 1 ));

CF_80 = CFs(find( avg_ssims > 0.8, 1 ));
CF_85 = CFs(find( avg_ssims > 0.85, 1 ));
CF_90 = CFs(find( avg_ssims > 0.9, 1 ));
CF_95 = CFs(find( avg_ssims > 0.95, 1 ));
