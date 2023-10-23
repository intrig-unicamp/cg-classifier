 ################################################################################
 # Copyright 2023 INTRIG
 #
 # Licensed under the Apache License, Version 2.0 (the "License");
 # you may not use this file except in compliance with the License.
 # You may obtain a copy of the License at
 #
 #     http://www.apache.org/licenses/LICENSE-2.0
 #
 # Unless required by applicable law or agreed to in writing, software
 # distributed under the License is distributed on an "AS IS" BASIS,
 # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 # See the License for the specific language governing permissions and
 # limitations under the License.
 ################################################################################

#!/bin/bash

import argparse
import os

from cg_classifier_th_sim import CG_Classifier
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
