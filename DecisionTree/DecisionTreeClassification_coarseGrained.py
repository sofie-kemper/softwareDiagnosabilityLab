import pandas as pd  
from sklearn.model_selection import train_test_split
from sklearn.model_selection import cross_val_score
from sklearn.preprocessing import Imputer
from sklearn.tree import DecisionTreeClassifier
from sklearn import metrics
import Classification_utils

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
y = Classification_utils.get_class_labels_coarse_grained(y)
class_names = Classification_utils.get_coarse_grained_class_names()
#cc.print_iterable(y)

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=0)

imp = Imputer(missing_values="NaN", strategy="mean", axis=0)
X_train = imp.fit_transform(X_train)
X_test = imp.fit_transform(X_test)

tree = DecisionTreeClassifier(max_depth=3, min_weight_fraction_leaf=0.05)
print('F1 scores during cross validation')
scores = cross_val_score(estimator=tree, X=X_train, y=y_train, scoring='f1')
print(scores)

tree.fit(X_train, y_train)
y_pred = tree.predict(X_test)

print('-------Score on training data')
print(tree.score(X_train, y_train))
print('********************* Scores on the test set *********************')
print('F1 score [0, 1]')
print(metrics.f1_score(y_test, y_pred))
print('Accuracy score (fraction and number of correct predictions)')
print(metrics.accuracy_score(y_test, y_pred))
print(metrics.accuracy_score(y_test, y_pred, normalize=False))

import plot_confusion_matrix as plt_cm
cm = metrics.confusion_matrix(y_test, y_pred)
plt_cm.plot_confusion_matrix(cm, classes=class_names,
                             title='Confusion Matrix')
plt_cm.plot_confusion_matrix(cm, classes=class_names,
                             title='Normalized Confusion Matrix',
                             normalize=True)

from sklearn.tree import export_graphviz
export_graphviz(tree, out_file='classification_tree.dot',
                feature_names=X.columns,
                filled=True, rounded=True,
                special_characters=True)