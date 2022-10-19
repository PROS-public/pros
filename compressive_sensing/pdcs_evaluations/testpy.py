import sys
import librosa
import tensorflow
import h5py
import hdf5storage
import mat4py
import numpy as np

# Test loading matlab data
# data = mat4py.loadmat('input_signal.mat')
f = h5py.File('myfile.mat','r')
data = f.get('signal')
print(data)
data = np.array(data)
print(data)

matfiledata = {} # make a dictionary to store the MAT data in
matfiledata[u'output_signal'] = data
hdf5storage.write(matfiledata, '.', 'example.mat', matlab_compatible=True)

# input_signal = np.ndarray(data["signal"])
# print(input_signal)

interpreter = tensorflow.lite.Interpreter("./models/alpha_pr.tflite")
interpreter.allocate_tensors()
