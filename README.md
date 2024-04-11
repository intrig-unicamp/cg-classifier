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

### Dataset and features used
The CG and non-CG dataset used in this project is taken from paper: <a href="https://ieeexplore.ieee.org/stamp/stamp.jsp?arnumber=10154417&casa_token=THUhgh5H01cAAAAA:8aV2n4G9SiYREKPPHuOJRFMmkK5Zf_NC1faiqMW3OP9fGGG6mx7QSTEjyeYRccToOsXSca6Ppy0&tag=1">Paper</a> , and can be downloaded from this link: <a href="https://cloud-gaming-traces.lhs.loria.fr/data.html">Dataset</a> 

There are five features are used to apply decision tree and classify CG traffic:
```
moving average of uplink packet size per time window
moving average of uplink inter packet gap per time window
number of packets per time window for uplink 
moving average of downlink packet size per window
moving average of downlink inter packet gap per window
```

### Generate training and test datasets
To generate training dataset and DT, the following commands are used:

```
./gen_train_csv.sh 1 ..cg_train_data_path 0 ..non_cg_train_data_path
python apply_dt.py
```

To generate test dataset, the following command is used:

```
./gen_test_csv.sh 1 ..cg_test_pcap_dir_path 0 ..noncg_test_pcap_dir_path
```

### Simulator to analyze CG classification 
```
python result_cg_dt_sim.py --windowsize 1 --weighting_decrease 95 --cg f --dir_path gen_test_dataset/OUTPUT_DATASET/NON_CG_TEST_CSV/
python result_cg_dt_sim.py --windowsize 1 --weighting_decrease 95 --cg t --dir_path gen_test_dataset/OUTPUT_DATASET/CG_TEST_CSV/
```

Instead of DT, the threshold based approach can also be used using script ```results_cg_th_sim.py```

### Tofino switch ASIC to analyze CG classification

#### DP
The P4 code is tested with SDE 9.12.0. The P4 ```code cg_classifier_dt.p4``` is required to compile and generate the binary to run on Tofino.

#### CP
Once the switch is ready, ```bfrt_dt.py``` can be used to push all the required entries based on the outcomes of DT. 

#### TReX Traffic Generator
In this project, TReX TG is used for testing and can be downloaded from here: <a href="https://trex-tgn.cisco.com/">TReX</a> 

The following commands can be used to send traffic to the Tofino switch:

```
./t-rex-64 -i
./trex-console
```

Required to enter to service mode for capturing traffic, then
```
portattr -a --prom on
```

For capturing traffic:

```
trex(service)>capture record start --rx 0 --limit 30000
trex(service)>push -r --port 1 -f ../pcap/path --force
trex(service)>capture record stop --id 1 -o ../output/path/out.pcap
```







