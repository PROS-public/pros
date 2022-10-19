"""
    DS-CNN for ImageNet-1K, implemented in PyTorch.
    Original paper: 'DS-CNN: Efficient Convolutional Neural Networks for Mobile Vision Applications,'
    https://arxiv.org/abs/1704.04861.
"""

__all__ = ["BACKBONE"]

import os
import torch.onnx
import torch.nn as nn
from pytorchcv.models.common import dwsconv3x3_block, ConvBlock
import torch.nn.functional as F
from torchinfo import summary
from utils import export2onnx, onnx2tf, tf2tflite, mcu_quantization
from onnxsim import simplify
import onnx


class SVM_Loss(nn.modules.Module):
    def __init__(self):
        super(SVM_Loss, self).__init__()

    def forward(self, outputs, labels):
        return torch.sum(torch.clamp(1 - outputs.t() * labels, min=0)) / batch_size


# svm_model = nn.Linear(input_size, 2)
# svm_loss_criteria = SVM_Loss()


class BACKBONE(nn.Module):
    r"""MobileNetV1 Backbone upon which DS-CNN and MicroNet are based

    Examples::
        from dscnn import *
        # model_name=['dscnn_l', 'dscnn_m', 'dscnn_s', 'micronet_l', 'micronet_m', 'micronet_s']
        BACKBONE(model_name="dscnn-l", in_channels=NUM_IN_CHANNELS,
                             num_classes=NUM_CLASSES,
                             init_block_kernel=(HEIGHT, WIDTH),
                             pretrained=False)
    """

    def __init__(
        self,
        model_name="dscnn_l",
        in_channels=1,
        num_classes=2,
        num_heads=0,
        init_block_kernel=(10, 4),
        pretrained=False,
        **kwargs,
    ):
        super(BACKBONE, self).__init__()
        self.model = get_dscnn(
            model_name=model_name.lower(),
            in_channels=in_channels,
            num_classes=num_classes,
            num_heads=num_heads,
            init_block_kernel=init_block_kernel,
            pretrained=pretrained,
            **kwargs,
        )

    def freeze_weight(self):
        for param in self.parameters():
            param.requires_grad = False

    def freeze_weight_except_name(self, filter_name="fc"):
        for param_name, param in self.named_parameters():
            if not param_name.startswith(filter_name):
                param.requires_grad = False
        # freeze every two layers
        # for param in net.parameters():
        # if len(param.size()) >= 3: # conv layer
        #       cur_layer += 1
        # if cur_layer < from_this_layer_tune:
        #       param.requires_grad=False
        # if cur_layer >= from_this_layer_tune:
        #       param.requires_grad=True

    def unfreeze_weight(self):
        for param in self.parameters():
            param.requires_grad = True

    def forward(self, x, head_index=0):
        out = self.model(x, head_index)
        return out
        # return F.log_softmax(out, dim=1)


# padding has either 1 equivalent number or 4 numbers [left, right, top, bottom]
def get_same_padding(kernel_size=(10, 4)):
    # when kernel size is the same and odd number
    # return 1 equivalent number as a padding
    if (kernel_size[0] == kernel_size[1]) and (kernel_size[0] % 2 == 1):
        return int((kernel_size[0] - 1) / 2)
    # when kernel size differs and contains even number
    # return 4 numbers as a padding
    else:
        # kernel_size == (Height, Weight)
        # Height == (top, bottom)
        # Weight == (left, right)
        padding = [0, 0, 0, 0]
        # Kernel Height => padding's top bottom, i.e., padding[2,3]
        if kernel_size[0] % 2 == 1:
            padding[2], padding[3] = int((kernel_size[0] - 1) / 2), int((kernel_size[0] - 1) / 2)
        else:
            padding[2], padding[3] = int(kernel_size[0] / 2) - 1, int(kernel_size[0] / 2)
        # Kernel Width => padding's left right, i.e., padding[0,1]
        if kernel_size[1] % 2 == 1:
            padding[0], padding[1] = int((kernel_size[1] - 1) / 2), int((kernel_size[1] - 1) / 2)
        else:
            padding[0], padding[1] = int(kernel_size[1] / 2) - 1, int(kernel_size[1] / 2)
        return padding


class DSCNN(nn.Module):
    """
    DS-CNN model from 'DS-CNNs: Efficient Convolutional Neural Networks for Mobile Vision Applications,'
    https://arxiv.org/abs/1704.04861.

    Parameters:
    ----------
    channels : list of list of int
        Number of output channels for each unit.
    first_stage_stride : bool
        Whether stride is used at the first stage.
    dw_use_bn : bool, default True
        Whether to use BatchNorm layer (depthwise convolution block).
    dw_activation : function or str or None, default nn.ReLU(inplace=True)
        Activation function after the depthwise convolution block.
    in_channels : int, default 3
        Number of input channels.
    in_size : tuple of two ints, default (224, 224)
        Spatial size of the expected input image.
    num_classes : int, default 1000
        Number of classification classes.
    """
    def __init__(
        self,
        init_block_channel,
        init_block_kernel,
        init_block_stride,
        channels,
        strides,
        dw_use_bn=True,
        dw_activation=(lambda: nn.ReLU(inplace=True)),
        in_channels=1,
        num_classes=2,
        num_heads=0,
    ):
        super(DSCNN, self).__init__()
        self.num_classes = num_classes

        self.features = nn.Sequential()
        self.features.add_module(
            "init_block",
            ConvBlock(
                in_channels=in_channels,
                out_channels=init_block_channel,
                kernel_size=init_block_kernel,
                stride=init_block_stride,
                padding=get_same_padding(init_block_kernel),
            ),
        )

        in_channels = init_block_channel
        out_channels = init_block_channel
        if channels == None:
            pass
        else:
            for i, channels_per_stage in enumerate(channels):
                stage = nn.Sequential()
                stride = strides[i]
                for j, out_channels in enumerate(channels_per_stage):
                    stage.add_module(
                        "unit{}".format(j + 1),
                        dwsconv3x3_block(
                            in_channels=in_channels,
                            out_channels=out_channels,
                            stride=stride,
                            dw_use_bn=dw_use_bn,
                            dw_activation=dw_activation,
                        ),
                    )
                    in_channels = out_channels
                self.features.add_module("stage{}".format(i + 1), stage)
        #### Note: Add dropout layer after all blocks and before pooling
        self.features.add_module("final_dropout", nn.Dropout(0.4))
        self.features.add_module("final_pool", nn.AdaptiveAvgPool2d((1, 1)))
        # self.features.add_module("final_pool", nn.AvgPool2d((5, 17)))
        # self.features.add_module("final_pool", nn.AvgPool2d((5, 37)))

        self.num_heads = num_heads
        self.heads_output = []

        if self.num_classes > 2:
            self.heads_output = nn.Linear(out_channels, self.num_classes)
        # multi heads
        else:
            for i in range(self.num_heads):
                setattr(self, f"fc_{i}", nn.Linear(out_channels, self.num_classes))
                # self.add_module(f'conv{i}', nn.Linear(self.head_input, 2))
                self.heads_output.append(getattr(self, f"fc_{i}"))
        self.linear_output = nn.Linear(
            in_features=out_channels,
            out_features=num_classes)

        self._init_params()

    def _init_params(self):
        for name, module in self.named_modules():
            if "dw_conv.conv" in name:
                nn.init.kaiming_normal_(module.weight, mode="fan_in")
            elif name == "init_block.conv" or "pw_conv.conv" in name:
                nn.init.kaiming_normal_(module.weight, mode="fan_out")
            elif "bn" in name:
                nn.init.constant_(module.weight, 1)
                nn.init.constant_(module.bias, 0)
            elif "heads_output" in name:
                nn.init.kaiming_normal_(module.weight, mode="fan_out")
                nn.init.constant_(module.bias, 0)
            elif "linear_output" in name:
                nn.init.kaiming_normal_(module.weight, mode="fan_out")
                nn.init.constant_(module.bias, 0)

    def forward(self, data, head_index):
        x = self.features(data)
        # print(x.shape)
        # self.features[backbone_index](//3)...
        x = x.view(x.size(0), -1)

        # if no heads is defined
        if self.num_heads == 0:
            x = self.linear_output(x)
        # if heads is defined
        else:
            x = self.heads_output[head_index](x)
        # uncertain = 2 / torch.sum( F.relu(x) + 1, dim=1, keepdim=True)
        # return x, uncertain
        return x


def get_dscnn(
    model_name=None,
    in_channels=1,
    num_classes=2,
    num_heads=0,
    backbone="small",
    init_block_kernel=(10, 4),
    pretrained=False,
    dws_simplified=False,
    width_scale=1.0,
    root=os.path.join("~", ".torch", "models"),
    **kwargs,
):
    """
    Create DS-CNN model with specific parameters.

    Parameters:
    ----------
    width_scale : float
        Scale factor for width of layers.
    dws_simplified : bool, default False
        Whether to use simplified depthwise separable convolution block.
    model_name : str or None, default None
        Model name for loading pretrained model.
    pretrained : bool, default False
        Whether to load the pretrained weights for model.
    root : str, default '~/.torch/models'
        Location for keeping the model parameters.
    """
    # config for MobileNetV1
    channels = [
        [32],
        [64],
        [128, 128],
        [256, 256],
        [512, 512, 512, 512, 512, 512],
        [1024, 1024],
    ]
    # config for DS-CNN for KWS
    if (
        "dscnn_l" in model_name
        or "dscnn-l" in model_name
        or "ds-cnn_l" in model_name
        or "ds-cnn-l" in model_name
    ):
        init_block_channel = 276
        init_block_stride = (2, 1)
        channels = [[276], [276], [276], [276], [276]]
        strides = [2, 1, 1, 1, 1]
    elif (
        "dscnn_m" in model_name
        or "dscnn-m" in model_name
        or "ds-cnn_m" in model_name
        or "ds-cnn-m" in model_name
    ):
        init_block_channel = 172
        init_block_stride = (2, 1)
        channels = [[172], [172], [172], [172]]
        strides = [2, 1, 1, 1]
    elif (
        "dscnn_s" in model_name
        or "dscnn-s" in model_name
        or "ds-cnn_s" in model_name
        or "ds-cnn-s" in model_name
    ):
        init_block_channel = 64
        init_block_stride = (2, 2)
        channels = [[64], [64], [64], [64]]
        strides = [1, 1, 1, 1]
    # config for MicroNet for KWS
    elif "micronet_l" in model_name or "micronet-l" in model_name:
        init_block_channel = 276
        init_block_stride = (1, 1)
        channels = [[248], [276], [276], [248], [248], [248], [248]]
        strides = [2, 1, 1, 1, 1, 1, 1]
    elif "micronet_m" in model_name or "micronet-m" in model_name:
        init_block_channel = 140
        init_block_stride = (1, 1)
        channels = [[140], [140], [140], [112], [196]]
        strides = [2, 1, 1, 1, 1]
    elif "micronet_s" in model_name or "micronet-s" in model_name:
        init_block_channel = 84
        init_block_stride = (1, 1)
        channels = [[112], [84], [84], [84], [196]]
        strides = [2, 1, 1, 1, 1]
    elif "mobilenet_s" in model_name or "mobilenet_s" in model_name:
        init_block_channel = 64
        init_block_stride = (2, 2)
        channels = [[32], [64], [64], [64]]
        strides = [1, 1, 1, 1]
    elif "mobilenet_m" in model_name or "mobilenet_m" in model_name:
        init_block_channel = 64
        init_block_stride = (2, 2)
        channels = [[64], [128], [128], [128]]
        strides = [1, 1, 1, 1]
    elif "mobilenet_l" in model_name or "mobilenet_l" in model_name:
        init_block_channel = 64
        init_block_stride = (2, 2)
        channels = [[256], [256], [256], [256], [256]]
        strides = [1, 1, 1, 1]
    else:
        raise ValueError("Model name not defined")


    if width_scale != 1.0:
        channels = [[int(cij * width_scale) for cij in ci] for ci in channels]

    if dws_simplified:
        dw_use_bn = False
        dw_activation = None
    else:
        dw_use_bn = True
        dw_activation = lambda: nn.ReLU(inplace=True)

    backbone = backbone.lower()

    # list of lists
    # feature

    if backbone == "onelayer":
        stride = None
        channels = None
    elif backbone == "shallow":
        stride = strides[:1]
        channels = channels[:1]
    elif backbone == "medium":
        stride = strides[:2]
        channels = channels[:2]
    elif backbone == "deep":
        stride = strides[:3]
        channels = channels[:3]
    elif backbone == "x_deep" and len(channels) <= 4:
        raise ValueError("x_deep is not available for current backend")
    elif backbone == "x_deep" and len(channels) > 4:
        stride = strides[:4]
        channels = channels[:4]
    elif backbone == "full":
        pass
    else:
        raise ValueError("Wrong backbone depth nominated! use 'onelayer', 'shallow', 'medium' ... instead")

    net = DSCNN(
        init_block_channel=init_block_channel,
        init_block_kernel=init_block_kernel,
        init_block_stride=init_block_stride,
        channels=channels,
        strides=strides,
        dw_use_bn=dw_use_bn,
        dw_activation=dw_activation,
        in_channels=in_channels,
        num_classes=num_classes,
        num_heads=num_heads,
    )

    # n_layers = len(channels)
    # num_layer_tune = 2
    # from_this_layer_tune = n_layers - num_layer_tune
    # cur_layer = 0

    if pretrained:
        if (model_name is None) or (not model_name):
            raise ValueError(
                "Parameter `model_name` should be properly initialized for loading pretrained model."
            )
        from pytorchcv.models.model_store import download_model

        download_model(net=net, model_name=model_name, local_model_store_dir_path=root)

    return net


def _calc_width(net):
    import numpy as np

    net_params = filter(lambda p: p.requires_grad, net.parameters())
    weight_count = 0
    for param in net_params:
        weight_count += np.prod(param.size())
    return weight_count


def _test():
    PATH = "seizure_mobilenet_s.pt"
    backbone = "shallow"

    import re
    try:
        backname = re.search('_(.+?).pt', PATH).group(1)
        print(backname)
    except AttributeError:
        print("markers not found in the original string")

    model = BACKBONE(
        model_name=backname,
        in_channels=1,
        num_classes=2, ## must be 2 for binary
        num_heads=0, ## for oxford team
        backbone=backbone,
        init_block_kernel=(3, 3),
        pretrained=False,
    )

    import torch
    dummy = torch.rand(1, 1, 10, 101)
    dummy1 = torch.rand(1, 101)
    shape = (1,1,10,101)
    shape1 = (1,101)

    # basic test for adaptive pool
    # output,_ = model(dummy, 0)
    output = model(dummy, 0)

    summary(model)
    print(output.shape)

    # specify model and load to cpu
    model = model.cuda()
    torch.save(model,PATH)
    model = torch.load(PATH, map_location='cpu')

    # define model path
    # onnx_path = ["./checkpoint/eog_backbone_heads.onnx","./checkpoint/eog_backbone.onnx","./checkpoint/eog_heads.onnx"]
    # onnx_path = ["./checkpoint/eog_backbone_heads.onnx"]
    onnx_path = [PATH.replace(".pt",".onnx")]
    # export to onnx
    export2onnx(model, dummy, onnx_path[0])
    # export2onnx(model.model.features, dummy, onnx_path[1])
    # export2onnx(model.model.fc_0, dummy1, onnx_path[2])

    # simplify model
    for path in onnx_path:
        onnx_model = onnx.load(path)
        # convert model
        if path == "./checkpoint/heads.onnx":
            shape = shape1
        new_model, check = simplify(onnx_model, input_shapes={"input":shape})
        assert check, "Simplified ONNX model could not be validated"
        onnx.save(new_model, path)

    # backbone
    # print(model.model.features)
    # torch.save(model.model.features.state_dict(), 'backbone.pth')

    # head
    # print(model.model.fc_0)
    # torch.save(model.model.fc_0.state_dict(), 'head.pth')

    # models = [model, model.model.features, model.model.fc_0]
    # # # use for onnx
    models = model
    # for i, (layers, pth_model_path) in enumerate(zip(models, onnx_path)):
    #     if pth_model_path == "./checkpoint/heads.onnx":
    #         dummy = dummy1
    tf_model_path = onnx_path[0].replace("onnx","h5")
    tflite_model_path = onnx_path[0].replace("onnx","tflite")
    tflite_quant_model_path = tflite_model_path.replace(".tflite","_quant.tflite")

# #     # pytorch2onnx(layers, dummy, onnx_path[0])
    onnx2tf(onnx_path[0], tf_model_path)
    tf2tflite(tf_model_path, tflite_model_path)
    print(onnx_path[0])
    mcu_quantization(dummy, tf_model_path, tflite_quant_model_path)


if __name__ == "__main__":
    _test()
