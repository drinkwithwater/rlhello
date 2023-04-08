
import random
import tensorflow as tf
import numpy as np

#mnist = tf.keras.datasets.mnist
#(x_train, y_train), (x_test, y_test) = mnist.load_data()

#print(x_train.shape, y_train.shape)


TRAIN_LEN = 4
X_INPUT = [[0,1], [1,0], [0,0], [1,1]]
#x_train = [[random.randrange(2), random.randrange(2)] for i in range(TRAIN_LEN)]
x_train = X_INPUT
y_train = [[(x_train[i][0]+x_train[i][1]) % 2] for i in range(TRAIN_LEN)]

class Model(object):
    def __init__(self):
        self._sess = tf.Session()
        self.buildNet()
        self._sess.run(tf.global_variables_initializer())

    def buildNet(self):
        self._x_input = tf.placeholder(tf.float32, [None, 2], name="x_in")
        self._y_input = tf.placeholder(tf.float32, [None, 1], name="y_in")
        self._l1 = tf.layers.dense(self._x_input, 5, tf.nn.sigmoid, name="d1")
        self._y_output = tf.layers.dense(self._l1, 1, tf.nn.sigmoid, name="d3")
        self._entropy = self._y_input * tf.log(self._y_output) + (1-self._y_input) * tf.log(1-self._y_output)
        self._loss = -tf.reduce_mean(self._entropy)
        self._train = tf.train.AdamOptimizer().minimize(self._loss)
        # self._y_input = tf.placeholder(tf.float32, [None, 1], name="y_in")
        # self._y_output = tf.placeholder(tf.float32, [None, 1], name="y_out")
        # self._loss = tf.reduce_mean(self._y_input - self._y_output)

    def train(self):
        for step in range(10000):
            _, loss = self._sess.run([self._train, self._loss], feed_dict={
                self._x_input:x_train,
                self._y_input:y_train,
            })
            if step % 100 == 0:
                print("step, loss", step, loss, self.predict(X_INPUT)[:,0])


    def predict(self, x_input):
        y_output = self._sess.run(self._y_output, feed_dict={
            self._x_input:x_input,
        })
        return y_output


a = Model()
a.train()
