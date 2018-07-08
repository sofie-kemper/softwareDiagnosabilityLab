import pandas as pd  
import numpy as np  
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split
from sklearn.model_selection import cross_val_score
from sklearn.tree import DecisionTreeRegressor
from sklearn import metrics

dataset = pd.read_csv('C:\study\PythonTutorial\data\petrol_consumption.csv')
#print(dataset.describe())

X = dataset.drop('Petrol_Consumption', axis=1)
y = dataset['Petrol_Consumption']
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=0)

regressor = DecisionTreeRegressor()
#scores = cross_val_score(estimator=regressor, X=X_train, y=y_train)
print('---cross validation scores')
#print(scores)
regressor.fit(X_train, y_train)
y_pred = regressor.predict(X_test)
print('Regressor Tree Score')
#print(dataset.describe())
print(regressor.score(X_test, y_test))
print('Metrics r2 score')
print(metrics.r2_score(y_true=y_test, y_pred=y_pred))