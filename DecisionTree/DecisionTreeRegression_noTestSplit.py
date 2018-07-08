import pandas as pd  
import numpy as np  
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split
from sklearn.model_selection import cross_val_score
from sklearn.preprocessing import Imputer
from sklearn.tree import DecisionTreeRegressor
from sklearn import metrics

dataset = pd.read_csv('C:\\study\\PythonTutorial\\data\\features\\combinedData.csv')
targets = pd.read_csv('C:\\study\\PythonTutorial\\data\\features\\targets.csv')
drop_ids = ['Chart_12','Chart_23',
            'Closure_28','Closure_43','Closure_46','Closure_90',
            'Lang_23','Lang_25','Lang_56',
            'Math_12','Math_35','Math_61','Math_104',
            'Time_2','Time_11', 'Time_23']
dataset = dataset.query('id not in @drop_ids')
dataset.sort_values('id', inplace=True)
dataset.reset_index(drop=True, inplace=True)
X = dataset.drop('id', axis=1)

targets.sort_values('id', inplace=True)
targets.reset_index(drop=True, inplace=True)
y = targets['nr_to_examine_dstar_2']

imp = Imputer(missing_values="NaN", strategy="mean", axis=0)
X = imp.fit_transform(X)

regressor = DecisionTreeRegressor(min_samples_leaf=3)
scores = cross_val_score(estimator=regressor, X=X, y=y, cv=3)
print('---cross validation scores')
print(scores)