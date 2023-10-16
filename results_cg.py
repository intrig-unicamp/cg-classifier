#!/bin/bash
import argparse
import os

from cg_classifier_sim import CG_Classifier
from distutils.util import strtobool


memorySlots = 1000

# Locate the csv file
ISP_file = 'OUTPUT_DATASET/CG_CSV'

# Change the directory
os.chdir(ISP_file)

def get_args():
    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("--windowsize", type=int, default=1,
                        help="size of time window in sec to measure the Heavy-Hitter flows")
    parser.add_argument("--weighting_decrease", type=int, default=98,
                        help="degree of weighting decrease in percentage for EWMA calculation")
    parser.add_argument("--cg", type=lambda x: bool(strtobool(x)),
                        help="select true for cg traffic, and false for non cg traffic")
    return parser.parse_args()


args = get_args()

def classfiyCloudGamingFlows():

  # Iterate through all CSV files
  for file in os.listdir():
    # Check whether file is in CSV format or not
    if file.endswith(".csv"):
      cg_classifier = CG_Classifier(file, memorySlots, str(args.windowsize), str(args.weighting_decrease), str(args.cg))

      if str(args.cg) == str(True):
        true_prediction, wrong_prediction = cg_classifier.getCgResult()
      else:
        true_prediction, wrong_prediction = cg_classifier.getNonCgResult()
        
      print ("True Prediction :", true_prediction)
      print ("Wrong Prediction :", wrong_prediction)

def main():
  classfiyCloudGamingFlows()
  print ("All done!")

if __name__ == '__main__':
  main()
