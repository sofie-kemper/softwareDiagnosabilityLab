In the scripts the path to the csv file containing all metric values and the csv file containing the target values
need to be adjusted before running them.
        C:\\study\\PythonTutorial\\data\\features\\combinedData.csv
        C:\\study\\PythonTutorial\\data\\features\\targets.csv

Script DecisionTreeClassification_coarseGrained.py
    creates a decision tree classification model on all features
    performs train test split and cross 3-fold validation
    exports tree to a dot file using graphviz, the .dot file can be transformed to a png using 'dot -Tpng tree.dot -o tree.png' in the command line afterwards
    also computes metrics and a Confusion Matrix
    uses coarse-grained class labels: useful (1-11) useless (>11)
    
Script DecisionTreeClassification_fineGrained.py
    similar as above but uses fine-grained class labels: perfect (1)    good (2-4)    medium (5-11)    useless (>11)

Script DecisionTreeRegression.py
    similar as, but uses a decision tree regression model
    performs rather bad
    
Script DecisionTreeRegression_noTestSplit.py
    performs a cross-validation on the whole data, only used for exploring