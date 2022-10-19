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
    # Load the PR models
    interpreter = tensorflow.lite.Interpreter(model_path)
    interpreter.allocate_tensors()

    # Get input and output tensors.
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    # Check if the input type is quantized, then rescale input data to uint8
    if input_details[0]['dtype'] == np.int8:
        input_scale, input_zero_point = input_details[0]["quantization"]
        #print(f"input_scale: {input_scale}, input_zero_point: {input_zero_point}")
    else:
        print(f"tflm_input_details_int8[0]['dtype'] is not int8, abort!")
        return

    # Scale the input
    tflm_mfcc_coeffs_scaled = mfcc_coeffs / input_scale + input_zero_point

    # Convert to int8.
    tflm_mfcc_coeffs_int = np.ceil(tflm_mfcc_coeffs_scaled); # Round to the nearest ints.
    tflm_mfcc_coeffs_int = tflm_mfcc_coeffs_int.astype(np.int8);
    model_input_int8 = np.reshape(tflm_mfcc_coeffs_int, (1, 1, tflm_mfcc_coeffs_int.shape[0], tflm_mfcc_coeffs_int.shape[1]))

    # Invoke model.
    input_shape = input_details[0]['shape']
    # print(input_shape)
    input_data = model_input_int8
    # print(input_data.shape)
    interpreter.set_tensor(input_details[0]['index'], input_data)

    interpreter.invoke()

    # The function `get_tensor()` returns a copy of the tensor data.
    # Use `tensor()` in order to get a pointer to the tensor.
    output_data = interpreter.get_tensor(output_details[0]['index'])
    # print("TensorFlow Lite Micro Output (FLOAT32):")
    # print(output_data)
    # pred = np.argmax(output_data)
    # pred_probs = softmax(output_data)
    # print(f"pred_probs: {pred_probs}")
    pos_prob = int(0)
    pos_prob = output_data[0][1] - output_data[0][0]

    return pos_prob

if __name__ == "__main__":
    # PR models configurations
    focal_pr_model_path = "./pr_models/poi_8.fold_5.mobilenet_s.onelayer.model_quant_int.tflite"
    absence_pr_model_path = "./pr_models/poi_12.fold_6.mobilenet_s.onelayer.model_quant_int.tflite"
    gtc_pr_model_path = "./pr_models/poi_15.fold_7.mobilenet_s.onelayer.model_quant_int.tflite"

    focal_cutoff_prob = -1;
    absence_cutoff_prob = 1;
    gtc_cutoff_prob = 2;

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

    # print(input_signal.shape)
    mfcc_coeffs = librosa.feature.mfcc(frame, sr=fs, n_mfcc=10, n_mels=64, window="hamming", n_fft=128, hop_length=64, center=False)

    # mfcc_coeffs_int = np.ceil(mfcc_coeffs);
    # print(mfcc_coeffs_int)
    # print(mfcc_coeffs)

    # Invoke the model to detect focal, absence, or gtc patterns.
    focal_prob = invoke_pr_model(mfcc_coeffs, focal_pr_model_path)
    absence_prob = invoke_pr_model(mfcc_coeffs, absence_pr_model_path)
    gtc_prob = invoke_pr_model(mfcc_coeffs, gtc_pr_model_path)


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
    hdf5storage.write(matfiledata, '.', 'output_prs.mat', matlab_compatible=True)
    f.close()
