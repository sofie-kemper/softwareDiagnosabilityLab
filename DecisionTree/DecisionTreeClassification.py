import pandas as pd  
import numpy as np  
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split
from sklearn.model_selection import cross_val_score
from sklearn.preprocessing import Imputer
from sklearn.tree import DecisionTreeClassifier
from sklearn import metrics
import Classification_utils as cc

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
#print('Target values:')
#cc.print_iterable(y)
#print('Class values (0 - 3):')
y = cc.get_class_labels(y)
#cc.print_iterable(y)

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=0)

imp = Imputer(missing_values="NaN", strategy="mean", axis=0)
X_train = imp.fit_transform(X_train)
X_test = imp.fit_transform(X_test)

tree = DecisionTreeClassifier(min_weight_fraction_leaf=0.05)
scores = cross_val_score(estimator=tree, X=X_train, y=y_train)
print('---cross validation scores')
print(scores)
tree.fit(X_train, y_train)
y_pred = tree.predict(X_test)
print('Regressor Tree Score')
print(tree.score(X_test, y_test))
print('-------Score on training data')
print(tree.score(X_train, y_train))

from sklearn.tree import export_graphviz
export_graphviz(tree, out_file='classification_tree.dot',
                feature_names=X.columns,
                filled=True, rounded=True,
                special_characters=True)