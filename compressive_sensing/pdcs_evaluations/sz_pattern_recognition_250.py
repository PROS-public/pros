import sys
import librosa
import tensorflow
import h5py
import hdf5storage
import mat4py
import numpy as np
from scipy.special import softmax

# Load matlab signal data
f = h5py.File('input_signal.mat','r')
data = f.get('signal')
org_fs = int(np.array(f.get('org_fs'))[0][0])
# print(org_fs)
poi = int(np.array(f.get('poi'))[0][0])
# print(poi)
fs = 4000;
input_signal = np.array(data)
# print(input_signal)

# Load the PR models
if poi == 8:
    pr_model_path = "./pr_models/poi_8.fold_2.mobilenet_s.shallow.model_quant_dr.tflite"
    pos_cutoff_prob = 0.65
elif poi == 12:
    pr_model_path = "./pr_models/poi_12.fold_1.mobilenet_s.shallow.model_quant_dr.tflite"
    pos_cutoff_prob = 0.41
elif poi == 15:
    pr_model_path = "./pr_models/poi_15.fold_4.mobilenet_s.shallow.model_quant_dr.tflite"
    pos_cutoff_prob = 0.70
else:
    print(f"UNKNOWN poi {poi}, exitting...")
    exit()

# Resample and calculate MFCC
input_signal = np.squeeze(input_signal)
frame = librosa.resample(input_signal, org_fs,  fs);

mfcc_coeffs = librosa.feature.mfcc(
            y=frame,
            sr= 4000,
            window="hamming",
            n_mfcc=10,
            n_fft= 40 *  4000 // 1000,
            hop_length= 20 *  4000 // 1000,
            )

# mfcc_coeffs_int = np.ceil(mfcc_coeffs);
# print(mfcc_coeffs_int)

# print(mfcc_coeffs)

# TensorFlow Models (no int8 quantization)
mfcc_coeffs_f32 = mfcc_coeffs.astype(np.float32);
model_input_f32 = np.reshape(mfcc_coeffs_f32, (1, 1, mfcc_coeffs_f32.shape[0], mfcc_coeffs_f32.shape[1]))

# Load the PR models
interpreter = tensorflow.lite.Interpreter(pr_model_path)
interpreter.allocate_tensors()

# Get input and output tensors.
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# Invoke model.
input_shape = input_details[0]['shape']
input_data = model_input_f32
interpreter.set_tensor(input_details[0]['index'], input_data)

interpreter.invoke()

# The function `get_tensor()` returns a copy of the tensor data.
# Use `tensor()` in order to get a pointer to the tensor.
output_data = interpreter.get_tensor(output_details[0]['index'])
# print("TensorFlow Lite Micro Output (FLOAT32):")
# print(output_data)
pred_probs = softmax(output_data)
# print(pred_probs)
pos_prob = pred_probs[0][1]
# print(pos_prob)

if pos_prob >= pos_cutoff_prob:
    pred = 1
else:
    pred = 0

# print(f"preds: {pred}")

matfiledata = {} # make a dictionary to store the MAT data in
matfiledata[u'output'] = pred
hdf5storage.write(matfiledata, '.', 'output_prs.mat', matlab_compatible=True)
