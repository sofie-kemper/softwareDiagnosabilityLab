import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split
from sklearn.model_selection import cross_val_score
from sklearn.preprocessing import Imputer
from sklearn.tree import DecisionTreeRegressor
from sklearn import metrics

dataset = pd.read_csv('../data/combinedData.csv')
targets = pd.read_csv('../data/targets.csv')
drop_ids = ['Chart_12','Chart_23',
            'Closure_28','Closure_43','Closure_46','Closure_90',
            'Lang_23','Lang_25','Lang_56',
            'Math_12','Math_35','Math_61','Math_104',
            'Time_2','Time_11', 'Time_23', 'Mockito_1','Mockito_2','Mockito_3',
            'Mockito_4','Mockito_5','Mockito_6','Mockito_7','Mockito_8','Mockito_9',
            'Mockito_10','Mockito_11','Mockito_12','Mockito_13','Mockito_14',
            'Mockito_15','Mockito_16','Mockito_17','Mockito_18','Mockito_19',
            'Mockito_20','Mockito_21','Mockito_22','Mockito_23','Mockito_24',
            'Mockito_25','Mockito_26','Mockito_27','Mockito_28','Mockito_29',
            'Mockito_30','Mockito_31','Mockito_32','Mockito_33','Mockito_34',
            'Mockito_35','Mockito_36','Mockito_37', 'Mockito_38']
dataset = dataset.query('id not in @drop_ids')
dataset.sort_values('id', inplace=True)
dataset.reset_index(drop=True, inplace=True)
X = dataset.drop('id', axis=1)

targets = targets.query('id not in @drop_ids')
targets.sort_values('id', inplace=True)
targets.reset_index(drop=True, inplace=True)
y = targets['nr_to_examine_dstar_2']

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=0)

imp = Imputer(missing_values="NaN", strategy="mean", axis=0)
X_train = imp.fit_transform(X_train)
X_test = imp.fit_transform(X_test)

regressor = DecisionTreeRegressor()  #min_weight_fraction_leaf=0.03, max_depth=5)
scores = cross_val_score(estimator=regressor, X=X_train, y=y_train, cv=3)
print('---cross validation scores')
print(scores)
regressor.fit(X_train, y_train)
y_pred = regressor.predict(X_test)
print('Regressor Tree Score')
print(regressor.score(X_test, y_test))
print('-------Score on training data')
print(regressor.score(X_train, y_train))

from sklearn.tree import export_graphviz
export_graphviz(regressor, out_file='../results/decisionTree/regression_tree.dot',
                feature_names=X.columns,
                filled=True, rounded=True,
                special_characters=True)
