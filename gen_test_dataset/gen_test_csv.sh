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

set -eu -o pipefail

#############################################################################
# Example to run this script
# e.g., ./gen_test_csv.sh 1 ..cg_test_csv_dir_path 0 ..noncg_test_csv_dir_path
##############################################################################

CG=$1 # 1 for cg traffic
INFILEDIR_CG=$2
NONCG=$3  # 0 for non cg traffic
INFILEDIR_NON_CG=$4

DIR="OUTPUT_DATASET"
if [ -d "$DIR" ]; then
  rm -r OUTPUT_DATASET
fi

echo "*** CG: Start converting each PCAP in CSV with the required parameters"
./dataset_test_csv.sh $CG $INFILEDIR_CG
echo "*** Done"

echo "*** NON CG: Start converting each PCAP in CSV with the required parameters"
./dataset_test_csv.sh $NONCG $INFILEDIR_NON_CG
echo "*** Done"

echo "*** All Done \ Ready for testing"
