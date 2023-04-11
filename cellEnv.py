from typing import Union
import time
import random

import gym
import numpy as np
import pyskynet
import pyskynet.foreign as foreign

pyskynet.start()

entry = pyskynet.newservice("entry")

def dump(state):
    pass

class Env(object):
    def __init__(self):
        self.action_space = gym.spaces.Discrete(2)
        self.observation_space = gym.spaces.Box(0, 2, (20,))

    def reset(self):
        foreign.call(entry, "reset")
        return self.get_state()

    def get_state(self):
        return np.array(foreign.call(entry, "dump")[0])[-2:].flatten()
        #return np.array(foreign.call(entry, "dump")[0])

    def step(self, action): # i : Union(1,2)
        done, reward = foreign.call(entry, "step", action)
        return self.get_state(), reward, done, reward

if __name__=="__main__":
    env = Env()

    env.reset()
    for i in range(1000):
        time.sleep(0.1)
        env.step(random.randrange(1,3))
        t = env.get_state()
        print("===================")
        print(t)
