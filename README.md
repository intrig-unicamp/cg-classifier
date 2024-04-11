# Decision tree in programmable data plane to classify various applications traffic

A decision tree (DT) is a supervised learning algorithm used for classification and regression. Nowadays, because of mostly encrypted traffic flowing in dataplane, 
it might be difficult to classify them using packet header information. Learning the traffic behavior can allow us to accurately classify specific flows among others.    
This project implements the decision tree algorithm in P4 and runs on the Tofino switch hardware. There are many applications which can be classified,
However, here we focus mainly on the cloud gaming (CG) traffic to classify among other non-cg flows.

## Repository structure

```text
├── result_cg_dt_* ------> CG Simultaor: threshold and DT based  
├── apply_dt ------------> Generate  DT by applying DecisionTreeClassifier using different features
├── bfrt_dt -------------> Configuration of control plane
├── cal_cg_thresholds ---> Compute thresholds values for CG classification
├── gen_test_dataset ----> Generate test datasets
├── gen_train_dataset ---> Generate training datasets
└── p4_src
    ├── cg_classifier_dt.p4 ---> Main P4 code to calculate features and apply DT
    ├── include
        ├── dt.p4 ---> Decision tree alogorithm
        ├── constants.p4 ---> Related constants using DT
        ├── parser.p4 ---> Packet header parser
        ├── standard_headers.p4 ---> Header defintions
```

## Getting started
To generate training dataset, ```gen_train_csv.sh``` is used as follows:

```
./gen_train_csv.sh 1 ..cg_train_data_path 0 ..non_cg_train_data_path
```
