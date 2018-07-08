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
features= ['T_NF', 'T_NP', 'T_PP',
           'BF_MAXCC', 'BF_CF_D']
dataset = dataset.query('id not in @drop_ids')
dataset.sort_values('id', inplace=True)
dataset.reset_index(drop=True, inplace=True)
X = dataset.filter(items=features)
print(X.describe())
targets.sort_values('id', inplace=True)
targets.reset_index(drop=True, inplace=True)
y = targets['nr_to_examine_dstar_2']

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=0)

regressor = DecisionTreeRegressor(min_samples_leaf=5)   #max_depth=5)
regressor.fit(X_train, y_train)
y_pred = regressor.predict(X_test)
print('-------Regression Tree Score')
print(regressor.score(X_test, y_test))
print('-------Score on training data')
print(regressor.score(X_train, y_train))

from sklearn.tree import export_graphviz
export_graphviz(regressor, out_file='tree_filteredFeatures.dot',
                feature_names=features,
                filled=True, rounded=True,
                special_characters=True)