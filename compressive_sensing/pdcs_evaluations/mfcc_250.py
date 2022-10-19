import sys
import librosa
import h5py
import hdf5storage
import mat4py
import numpy as np
import tensorflow
from scipy.special import softmax

# Load matlab signal data
f = h5py.File('input_signal.mat','r')
data = f.get('signal')
org_fs = int(np.array(f.get('org_fs'))[0][0])

fs = 500;
input_signal = np.array(data)
# print(input_signal)

# Resample and calculate MFCC
input_signal = np.squeeze(input_signal)
frame = input_signal
#frame = librosa.resample(input_signal, org_fs,  fs)

mfcc_coeffs = librosa.feature.mfcc(input_signal, sr=fs, n_mfcc=10, n_mels=64, window="hamming", n_fft=128, hop_length=64, center=False)

pr_model_path = "./pr_models/poi_8.fold_5.mobilenet_s.onelayer.model_quant_dr.tflite"

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
print("TensorFlow Lite Micro Output (FLOAT32):")
print(output_data)
pred_probs = softmax(output_data)
print(pred_probs)

matfiledata = {} # make a dictionary to store the MAT data in
matfiledata[u'output'] = mfcc_coeffs
hdf5storage.write(matfiledata, '.', 'output_prs.mat', matlab_compatible=True)
