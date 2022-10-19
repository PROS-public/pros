% @file labels_combine.m
% @author  Nhat Pham <nhat.pham@cs.ox.ac.uk>.
% @version 1.0
% @date 08-Oct-2022
% @brief Combine all the labels into one csv file. 
%

clear;
clc;

%% Read labels data
labels_0 = csvread("0_labels.csv");
labels_1 = csvread("1_labels.csv");
labels_4 = csvread("4_labels.csv");
labels_5 = csvread("5_labels.csv");
labels = [labels_0 labels_1 labels_4 labels_5];
labels_temp = [];

for i = 1:1:numel(labels_0)
    for c_i = 1:4
        labels_temp = [labels_temp; labels(i, c_i)];
    end
end

csvwrite("labels.csv", labels_temp);


