# Decision tree implementation in programmable data plane to classfiy clould gaming and other applications traffic

A decision tree (DT) is a supervised learning algorithm used for classfication and regression. Nowadays, because of mostly encrypted traffic flowing in dataplane, 
it might be difficult to classfy them using packet header information. Learning the traffic behaviour can allow us to accurately classify specfic flows among others.    
This project implements the decision tree algorithm in P4 and runs on the Tofino switch hardware. There are many applications which can be classfied,
however, here we focus mainly on the cloud gaming (CG) traffic to classfiy among other non-cg flows.  

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
