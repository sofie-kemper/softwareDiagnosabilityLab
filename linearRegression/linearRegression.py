### This script was used for exploratory purposes but not for the final results.
### It may not work for the current folder structure and data format without adaptations.

import numpy as np
#from scipy import stats
import pandas as pandas

## configuration: which features and target to use for the regression
feature_cols = ["CG_VC", "CG_EC"]
target_col = "DD_VC"

datapath = "coverageData/graphs/Lang/dynamic_metrics.csv"

## load and prepare data
# read in data as csv-file
data = pandas.read_csv(datapath)

# delete unnecessary columns: row-numbers and ids
nrow, ncol = data.shape
data = data.drop(data.columns[[0, 1]], axis=1)

targets = data[target_col]
drop_cols = list(set([d for d in data.columns]).difference(feature_cols))
data = data.drop(drop_cols, axis=1)

# create numpy array from data for further handling
np_data = np.array(data)
print(np.shape(np_data))
np_targets = np.array(targets)
print(np.shape(np_targets))

## apply linear regression to data
#gradient, intercept, r_value, p_value, std_err = stats.linregress(np_data, np_targets)

#print("Gradient and intercept",gradient,intercept)

#print("Gradient and intercept",gradient,intercept)

#print("P-value",p_value)
