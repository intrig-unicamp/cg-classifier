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
import csv

from create_train_csv_dt import CG_Traffic
from distutils.util import strtobool

memorySlots = 1000

# Change the directory
os.chdir('OUTPUT_DATASET')

# Locate the csv file
ISP_file_cg = 'CG_TRAIN_CSV'
ISP_file_non_cg = '../NON_CG_TRAIN_CSV'

def get_args():
    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("--windowsize", type=int, default=1,
                        help="size of time window in sec to measure the Heavy-Hitter flows")
    parser.add_argument("--weighting_decrease", type=int, default=95,
                        help="degree of weighting decrease in percentage for EWMA calculation")
    return parser.parse_args()


args = get_args()

def classfiyCloudGamingFlows():

  list_header = [["UL_IPGw", "UL_PSw", "UL_Pkts_N", "DL_IPGw", "DL_IPGw_Dev", "DL_PSw", "DL_Pkts_N", "CG"]]

  with open('train_dataset.csv', 'w', newline='') as file:
        writer = csv.writer(file)
        writer.writerows(list_header)

        # Change the directory
        os.chdir(ISP_file_cg)

        # Iterate through all CSV files
        for file in os.listdir():
            # Check whether file is in CSV format or not
            if file.endswith(".csv"):
                cg_classifier = CG_Traffic(file, memorySlots, str(args.windowsize), str(args.weighting_decrease), str(True))
                row_list_cg = cg_classifier.getListData()
                writer.writerows(row_list_cg)

        # Change the directory
        os.chdir(ISP_file_non_cg)

        # Iterate through all CSV files
        for file in os.listdir():
            # Check whether file is in CSV format or not
            if file.endswith(".csv"):
                cg_classifier = CG_Traffic(file, memorySlots, str(args.windowsize), str(args.weighting_decrease), str(False))
                row_list_non_cg = cg_classifier.getListData()
                writer.writerows(row_list_non_cg)

def main():
  classfiyCloudGamingFlows()

if __name__ == '__main__':
  main()
