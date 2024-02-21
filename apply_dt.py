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

import pandas
from sklearn import tree
from sklearn.tree import DecisionTreeClassifier
import matplotlib.pyplot as plt

############################
# Example to run this script
# e.g., python apply_dt.py
############################

df = pandas.read_csv("gen_train_dataset/OUTPUT_DATASET/train_dataset.csv")

# features = ["UL_IPGw", "UL_PSw", "UL_Pkts_N", "DL_IPGw", "DL_IPGw_Dev", "DL_PSw", "DL_Pkts_N"]
features = ["UL_IPGw", "UL_PSw", "UL_Pkts_N", "DL_IPGw", "DL_PSw", "DL_Pkts_N"]

X = df[features]
y = df.CG

print ("Applying DT using given training set.....")
dtree = DecisionTreeClassifier(min_impurity_decrease=0.000, ccp_alpha=0.000)
dtree = dtree.fit(X, y)
print ("Done!")

print ("Generating DT Plot in pmng foramt....")
fig = plt.figure(figsize=(55,40))
_ = tree.plot_tree(dtree, feature_names=features, class_names=["0","1"], filled=True)

fig.savefig("decistion_tree.png")
print ("All done!")
