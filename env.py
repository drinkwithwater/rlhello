from typing import Union
import time
import random

import numpy as np
import pyskynet
import pyskynet.foreign as foreign

pyskynet.start()

entry = pyskynet.newservice("entry")

def dump(state):
    pass

class Env(object):
    def __init__(self):
        pass

    def reset(self):
        foreign.call(entry, "reset")

    def get_state(self):
        return np.array(foreign.call(entry, "dump")[0])

    def step(self, action): # i : Union(1,2)
        done, reward = foreign.call(entry, "step", action)
        return done, reward

if __name__=="__main__":
    env = Env()

    env.reset()
    for i in range(1000):
        time.sleep(0.1)
        env.step(random.randrange(1,3))
        t = env.get_state()
        print("===================")
        print(t)
