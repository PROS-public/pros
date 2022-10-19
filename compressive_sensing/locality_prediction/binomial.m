% @file binomial.m
% @author  Nhat Pham <nhat.pham@cs.ox.ac.uk>.
% @version 1.0
% @date 08-Oct-2022
% @brief This implements a binomial predictor. 
%

clear;
clc;

%% Read labels data
labels = csvread("5_labels.csv");

%% Two bits predictors 
tbc_count = 2;
tbc_pred = 6;

n_trues = 0;
n_falses = 0;
n_total = 0; % Only count the positive events

for i = 1:1:numel(labels)
    % make prediction
    pred = tbc_pred;

    % check with the true value
    true_event = labels(i);
    if (true_event ~= 6)
        n_total = n_total + 1;
    end

    if pred == true_event
        if (true_event ~= 6)
            n_trues = n_trues + 1;
        end
    else
        tbc_count = tbc_count - 1;
        if tbc_count == 0
            tbc_pred = true_event;
            tbc_count = 2;
        end
    end
end

disp("============================================");
disp("Accuracy: " + n_trues/n_total);


