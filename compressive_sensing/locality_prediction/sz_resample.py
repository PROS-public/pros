import sys
import librosa
import tensorflow
import h5py
import hdf5storage
import mat4py
import numpy as np
from scipy.special import softmax
import warnings

# Invoke a PR model with MFCC coefficients as input and positive probablity as the output.
def invoke_pr_model(mfcc_coeffs, model_path):
    # TensorFlow Models (no int8 quantization)
    mfcc_coeffs_f32 = mfcc_coeffs.astype(np.float32);
    model_input_f32 = np.reshape(mfcc_coeffs_f32, (1, 1, mfcc_coeffs_f32.shape[0], mfcc_coeffs_f32.shape[1]))

    # Load the PR models
    interpreter = tensorflow.lite.Interpreter(model_path)
    interpreter.allocate_tensors()

    # Get input and output tensors.
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    # Invoke model.
    input_shape = input_details[0]['shape']
    # print(input_shape)
    input_data = model_input_f32
    # print(input_data.shape)
    interpreter.set_tensor(input_details[0]['index'], input_data)

    interpreter.invoke()

    # The function `get_tensor()` returns a copy of the tensor data.
    # Use `tensor()` in order to get a pointer to the tensor.
    output_data = interpreter.get_tensor(output_details[0]['index'])
    # print("TensorFlow Lite Micro Output (FLOAT32):")
    # print(output_data)
    # pred = np.argmax(output_data)
    pred_probs = softmax(output_data)
    # print(f"pred_probs: {pred_probs}")
    pos_prob = pred_probs[0][1]

    return pos_prob

if __name__ == "__main__":
    warnings.filterwarnings('ignore')

    # Load matlab signal data
    f = h5py.File('input_signal.mat','r')
    data = f.get('signal')
    org_fs = int(np.array(f.get('org_fs'))[0][0])
    # print(org_fs)
    fs = 500;
    input_signal = np.array(data)
    # print(input_signal)

    # Resample and calculate MFCC
    input_signal = np.squeeze(input_signal)
    frame = librosa.resample(input_signal, org_fs,  fs);

    matfiledata = {} # make a dictionary to store the MAT data in
    # matfiledata[u'output'] = pred
    # matfiledata[u'mfcc_coeffs'] = mfcc_coeffs
    matfiledata[u'frame'] = frame
    hdf5storage.write(matfiledata, '.', 'output_prs.mat', matlab_compatible=True)
