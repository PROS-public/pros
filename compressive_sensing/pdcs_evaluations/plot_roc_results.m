clear;
clc;

% Focal
results_subjects = "../../cam-ml/results/seizure/binary/onelayer/plots/best_subject/onelayer.8.dur_3.fold.5-roc.mat";
% results_subjects = "../../cam-ml/results/seizure/binary/onelayer/plots/best_test/onelayer.8.dur_3.fold.5-roc.mat";

% Absence
% results_subjects = "../../cam-ml/results/seizure/binary/onelayer/plots/best_subject/onelayer.12.dur_3.fold.6-roc.mat";
% results_subjects = "../../cam-ml/results/seizure/binary/onelayer/plots/best_test/onelayer.12.dur_3.fold.6-roc.mat";


% GTC
% results_subjects = "../../cam-ml/results/seizure/binary/onelayer/plots/best_subject/onelayer.15.dur_3.fold.7-roc.mat";

load(results_subjects)

figure;
plot(Specificity,Sensivity, '-o','MarkerIndices', [find( Sensivity >= 0.8, 1 ) find( Sensivity >= 0.85, 1 ) find( Sensivity >= 0.9, 1 )]);
title("Specificity vs. Sensivity curve");
ylabel('Sensivity')
xlabel('Specificity')

% Find the thresholds for Sensivity >= 80, 85, 90, 95%.
Sens_80_thr = thresholds(find( Sensivity >= 0.8, 1 ));
Sens_85_thr = thresholds(find( Sensivity >= 0.85, 1 ));
Sens_90_thr = thresholds(find( Sensivity >= 0.9, 1 ));
Sens_95_thr = thresholds(find( Sensivity >= 0.95, 1 ));

Sens_80_Spec = Specificity(find( Sensivity >= 0.8, 1 ));
Sens_85_Spec = Specificity(find( Sensivity >= 0.85, 1 ));
Sens_90_Spec = Specificity(find( Sensivity >= 0.9, 1 ));
Sens_95_Spec = Specificity(find( Sensivity >= 0.95, 1 ));

Sens_80_Sens = Sensivity(find( Sensivity >= 0.8, 1 ));
Sens_85_Sens = Sensivity(find( Sensivity >= 0.85, 1 ));
Sens_90_Sens = Sensivity(find( Sensivity >= 0.9, 1 ));
Sens_95_Sens = Sensivity(find( Sensivity >= 0.95, 1 ));
