% @file correlating_predictor.m
% @author  Nhat Pham <nhat.pham@cs.ox.ac.uk>.
% @version 1.0
% @date 08-Oct-2022
% @brief This implements a correlating predictor for seizure patterns. 
%

clear;
clc;

%% Read labels data
labels = csvread("labels.csv");
convert_arrays = [6 8 12 15];

%% Two bits predictors 
c_pred = correlating_predictor(4,3);

n_trues = 0;
n_falses = 0;
n_total = 0; % Only count the positive events

for i = 1:1:numel(labels)
    % make prediction
    pred_i = predict(c_pred);
    pred = convert_arrays(pred_i);

    % check with the true value
    true_event = labels(i);
    if (true_event ~= 6)
        n_total = n_total + 1;
    end

    if pred == true_event
        if (true_event ~= 6)
            n_trues = n_trues + 1;
        end
    end

    % Update
    true_event_i = find(convert_arrays == true_event);
    c_pred = update(c_pred, true_event_i);
end

disp("============================================");
disp("Accuracy: " + n_trues/n_total);


