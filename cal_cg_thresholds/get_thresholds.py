#!/bin/bash
import argparse
import os

from cal_thresholds import CG_Threshold_Cal
from pathlib import Path

memorySlots = 20

file_path = '../OUTPUT_DATASET/CG_CSV'

# Change the directory
os.chdir(file_path)

def get_args():
    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("--windowsize", type=int, default=1,
                        help="size of time window in sec to measure the Heavy-Hitter flows")
    parser.add_argument("--weighting_decrease", type=int, default=98,
                        help="degree of weighting decrease in percentage for EWMA calculation")
    return parser.parse_args()

args = get_args()

def get_prcnt_diff(self, uplink_val, downlink_val):
  if uplink_val == downlink_val:
      return 0
  try:
      return (abs(uplink_val - downlink_val) / ((uplink_val + downlink_val) / 2)) * 100.0
  except ZeroDivisionError:
      return 0

def getCgFeaturesThresholds():
  # iterate through all CSV files
  for file in os.listdir():
    # Check whether file is in CSV format or not
    if file.endswith(".csv"):

      cg_th = CG_Threshold_Cal(file, memorySlots)

      # list is in the below format
      # [IPG1st_quart, IPG3rd_quart, PacketSize1st_quart, PacketSize3rd_quart, No_packets, Dtls_length]
      list1, list2 = cg_th.getFeatureThresholds()

      print (list1, list2)

  return None

def main():
  getCgFeaturesThresholds()
  print ("All done!")


if __name__ == '__main__':
  main()
