# This is a sample Python script.
import time

# Press Shift+F10 to execute it or replace it with your code.
# Press Double Shift to search everywhere for classes, files, tool windows, actions, and settings.
import pyskynet
import pyskynet.foreign as foreign

pyskynet.start()

entry = pyskynet.newservice("entry")

foreign.call(entry, "reset")
for i in range(100):
    done, reward = foreign.call(entry, "step", 1)
    foreign.call(entry, "dump")
    time.sleep(0.1)
    if done:
        break

