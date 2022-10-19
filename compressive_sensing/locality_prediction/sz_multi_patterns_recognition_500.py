import sys
import librosa
import tensorflow
import h5py
import hdf5storage
import mat4py
import numpy as np
from scipy.special import softmax

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
#     print(output_data)
    # pred = np.argmax(output_data)
    pred_probs = softmax(output_data)
#     print(f"pred_probs: {pred_probs}")
    pos_prob = pred_probs[0][1]

    return pos_prob

if __name__ == "__main__":
    # PR models configurations
    focal_pr_model_path = "./pr_models/poi_8.fold_5.mobilenet_s.onelayer.model.tflite"
    absence_pr_model_path = "./pr_models/poi_12.fold_6.mobilenet_s.onelayer.model.tflite"
    gtc_pr_model_path = "./pr_models/poi_15.fold_7.mobilenet_s.onelayer.model.tflite"

    focal_cutoff_prob = 0.47;
    absence_cutoff_prob = 0.76;
    gtc_cutoff_prob = 0.56;

    # Load matlab signal data
    f = h5py.File('input_signal.mat','r')
    data = f.get('signal')
    org_fs = int(np.array(f.get('org_fs'))[0][0])
    # print(org_fs)
    fs = 500;
    input_signal = np.array(data)
    # print(input_signal)

    # Resample and calculate MFCC
    frame = np.squeeze(input_signal)
    # frame = np.round(librosa.resample(input_signal, org_fs,  fs));

    # print(input_signal.shape)
    mfcc_coeffs = librosa.feature.mfcc(frame, sr=fs, n_mfcc=10, n_mels=64, window="hamming", n_fft=128, hop_length=64, center=False)

    # mfcc_coeffs_int = np.ceil(mfcc_coeffs);
    # print(mfcc_coeffs_int)
    # print(mfcc_coeffs)

    # Invoke the model to detect focal, absence, or gtc patterns.
    absence_prob = invoke_pr_model(mfcc_coeffs, absence_pr_model_path)
    gtc_prob = invoke_pr_model(mfcc_coeffs, gtc_pr_model_path)
    focal_prob = invoke_pr_model(mfcc_coeffs, focal_pr_model_path)


    if absence_prob > absence_cutoff_prob:
        pred = 12
    elif gtc_prob > gtc_cutoff_prob:
        pred = 15
    elif focal_prob > focal_cutoff_prob:
        pred = 8
    else:
        pred = 6

        # probs = np.array([focal_prob, absence_prob, gtc_prob])
        # labels = [8, 12, 15]
        # print(f"probs: {probs}")
        #
        # pred_index = np.argmax(probs)
        # # print(f"pred_index: {pred_index}")
        #
        # pred = labels[pred_index]
        # print(f"pred: {pred}")

    matfiledata = {} # make a dictionary to store the MAT data in
    matfiledata[u'output'] = pred
    matfiledata[u'mfcc_coeffs'] = mfcc_coeffs
    matfiledata[u'frame'] = frame
    hdf5storage.write(matfiledata, '.', 'output_prs.mat', matlab_compatible=True)
