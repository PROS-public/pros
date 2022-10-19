%%%
% @file pdcs_eval.m
% @author  Nhat Pham <nhat.pham@cs.ox.ac.uk>.
% @version 1.0
% @date 11-Dec-2021
% @brief Combined pattern recognition + pattern-driven compressive sensing evaluation script.
% Input:
% poi: 8 (focal), 12 (absence), 15 (gtc). Positive POI.
% wduration: 2s-5s.
% is_sld: 1, sliding 1s window and do majority voting.
%%%

clear;
clc;

% Load the focal sample
load("test_samples/focal_3s_500.mat");

% Python calculation
fs = 500;
% mfcc_py = mfcc_python(x_resampled, fs);

% % Matlab calculation
% mfcc_fs = 500;
% % [Numer, Denom] = rat(mfcc_fs/fs);
% % x_resampled = resample(x, Numer, Denom);
% mfcc_window = hamming(256,'periodic');
% mfcc_fftlen = 256;
% mfcc_overlaplen = 80;
% mfcc_mat = mfcc(x_resampled, mfcc_fs, ...
%     'NumCoeffs', 10, ...
%     'Window', mfcc_window, ...
%     'FFTLength', mfcc_fftlen, ...
%     'OverlapLength', mfcc_overlaplen, ...
%     'LogEnergy', 'Ignore', ...
%     'Rectification', 'cubic-root');

% MCU calculation
mfcc_mcu = [48.140 43.360 65.058 47.024 42.951 60.286 43.913 38.604 45.192 51.033 48.046 48.735 55.694 51.970 55.018 55.475 50.131 43.174 47.411 58.074 44.092 52.055 ;
67.042 83.458 81.437 73.340 79.606 76.163 75.839 67.182 72.815 78.130 66.459 64.896 74.807 76.275 73.447 73.098 74.793 71.902 75.420 79.075 70.279 75.646 ;
41.460 46.201 54.323 54.645 45.414 48.987 51.591 53.571 49.774 39.719 42.496 52.286 50.327 47.366 59.888 50.823 54.232 59.193 55.533 54.332 54.914 56.635 ;
28.382 34.652 29.079 23.473 25.608 19.838 34.837 21.294 21.550 28.646 36.498 22.340 26.763 24.666 32.302 34.818 32.837 22.916 23.237 31.713 18.974 38.168 ;
17.983 8.769 5.265 11.896 8.043 18.030 10.102 9.183 5.850 7.045 7.955 14.500 9.289 17.439 24.471 14.537 10.825 21.718 8.570 17.050 9.638 8.665 ;
8.920 3.247 9.751 1.657 4.016 6.424 10.221 10.271 4.984 3.959 8.835 2.152 3.190 7.143 10.152 12.543 7.881 1.392 -3.048 2.017 8.563 -3.205 ;
4.800 -8.932 1.922 7.212 3.856 1.648 9.455 2.578 1.296 6.596 6.532 2.878 14.485 3.754 1.595 4.023 7.202 -1.480 3.264 15.735 -8.670 7.392 ;
1.160 -5.178 8.452 4.984 4.070 3.126 12.418 6.059 15.503 -0.919 -3.279 8.637 3.952 13.888 9.688 -0.288 2.635 8.006 10.004 0.455 2.126 5.748 ;
10.197 13.880 7.094 -8.156 -0.128 6.137 13.936 15.742 -0.417 1.901 3.650 2.485 4.088 -4.501 5.507 2.272 1.146 12.080 0.776 7.321 10.855 6.839 ;
-6.882 0.745 -0.028 5.748 14.951 -4.217 13.432 -0.012 -0.984 4.003 1.109 7.495 3.877 -4.913 11.462 5.756 7.358 9.199 1.903 4.091 0.679 -2.464 ;];

% Plot two images
figure;
image(mfcc_mcu);
colormap(jet(100));
title("MFCC MCU");
colorbar;
% figure;
% image(mfcc_py);
% title("MFCC Python");
% colorbar;

% Plot Compressive Sensing
phi = csvread("phi_matrices/Phi_bin_150x750.csv");
y1 = phi * x_resampled(1:750);
y2 = phi * x_resampled(751:1500);
y = [y1; y2];
figure;
plot(y1);
figure
plot(x_resampled(1:750));

% Plot Phi and Psi
phi2 = csvread("phi_matrices/Phi_bin_20x50.csv");
phi100 = phi2.*70;
figure;
image(phi100);
colormap(jet(100));
title("Phi");
colorbar;

phi3 = csvread("phi_matrices/Phi_bin_10x50.csv");
phi100 = phi3.*70;
figure;
image(phi100);
colormap(jet(100));
title("Phi");
colorbar;


%% Pattern Recognition function
% Input: signal with fs = 250Hz.
% Output: the predicted pattern class.
% function pred = mfcc_python(signal, org_fs)
%   % Call this in Linux to prevent segfaults
%   py.sys.setdlopenflags(int32(10));
% 
%   delete("input_signal.mat");
%   save('input_signal.mat', '-v7.3');
%   pyrunfile('mfcc_250.py')
%   load('output_prs.mat')
% 
%   pred = output;
% end

psi = csvread("psi_matrices/inv_bior4.4_250.csv");
psi100 = psi.*1000;
figure;
image(psi100);
colormap(jet(100));
title("Psi");
colorbar;

psi = csvread("psi_matrices/inv_db15_250.csv");
psi100 = psi.*1000;
figure;
image(psi100);
colormap(jet(100));
title("Psi2");
colorbar;

%% Execute compressive sensing on the input signal.
% Input: signal with fs = 250Hz, phi, psi, and A (phi*psi) matrices.
% Output: ssim after recovery.
function ssim = sz_compressive_sensing(x, phi, psi, A)
  y = phi * x;
  n = size(x,1);

  % Perform recovery.
  blkLen = 24;                  % the block size in the user-defined block partition
  groupStartLoc = 1:blkLen:n;   % user-defined block partition

  % run the algorithm
  Result = BSBL_BO(A,y,groupStartLoc,0,'prune_gamma',-1, 'max_iters',20);

  % restore recovered data
  x_hat = real(psi*Result.x);

  windowLen = 200;
  [mssim, ssim_map] = ssim_1d(x, x_hat, windowLen);

  ssim = mssim;
end
