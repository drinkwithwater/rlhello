
import random
import numpy as np
import torch
from torch import nn

device = "cpu"

def my_fn(a,b):
    #return np.clip(a+b, a_min=0, a_max=1)
    return (a+b)%2

X_INPUT = [[0,1], [1,0], [0,0], [1,1]]
x_train = torch.Tensor([i for i in X_INPUT])
y_train = torch.Tensor([[my_fn(X_INPUT[i][0],X_INPUT[i][1])] for i in range(4)])

class NeuralNetwork(nn.Module):
    def __init__(self):
        super().__init__()
        self._stack = nn.Sequential(
                nn.Linear(2, 2),
                nn.Sigmoid(),
                nn.Linear(2, 2),
                nn.Sigmoid(),
                nn.Linear(2, 1),
                nn.Sigmoid())

    def forward(self, x):
        return self._stack(x)


model = NeuralNetwork().to(device)


def train():
    loss_fn = nn.MSELoss()
    optimizer = torch.optim.Adam(model.parameters())
    model.train()
    x = x_train.to(device)
    y = y_train.to(device)
    # train
    for i in range(10000):
        pred = model(x)
        loss = loss_fn(pred, y)
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()
        loss = loss.item()
        if i %1000 == 1:
            print("step, loss:", i, loss)


train()
train()

#loss_fn = nn.CrossEntropyLoss()
#optimizer = torch.optim.SGD(mode.parameters(), lr=1e-3)
#out = model.forward(torch.Tensor([1,0]))

