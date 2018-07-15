# Exploring the Relationship between Design Metrics and Software Diagnosability
Seminar: summer term 2018, TUM
Thomas Dornberger, Sofie Kemper
Advisor: Mojdeh Golagha

GitHub repository: https://github.com/sofie-kemper/softwareDiagnosabilityLab

# Results

We use the number of methods to examine until the first faulty method is found (average-case in cases of rank-ties) (respectively, its log transformation) as target for our machine learning. In addition, we use a classification based on this target.

The final metrics we have found to be good predictors for the quality of spectrum-based fault localisation, are the following:
- CG_MAXVO = maximum vertex outdegree in callgraph; well-suited for correlation-based analyses (e.g., linear regression) as well as split-based analyses (e.g., decision trees)
-DD_EC90Q, DD_MAXEC = 90th quantile and maximum, respectively, of eigenvector-centrality values in the data dependency graph; particularly well-suited for correlation-based analyses (in fact, the entire tail end of the eigenvector-centrality distribution, i.e., the median, and all quantiles above, seem to be good predictors)
- CG_MD = mean geodesic distance in callgraph; well-suited for correlation-based analyses
- CG_EC = number of edges in callgraph; well-suited for correlation-based analyses
- CG_VC = number of vertices in callgraph; well-suited for correlation-based analyses
- T_U = uniqueness of test suite; well-suited for split-based analyses
- T_DDU = density-diversity-uniqueness of test suite; well-suited for split-based analyses
- T_NF = absolute number of failing tests; well-suited for split-based analyses

All results regarding callgraphs, data dependency graphs, and test suites are based only on the relevant tests and components (see documentation of gzoltar for further info).

# Folder Structure

All data is in the folder "data". This includes raw data, e.g., the gzoltar files as well as pre-processed data and metric analysis results, e.g., dynamic metrics. The latter are generated using scripts in "dataGeneration". Where applicable, all data is provided in CSV format, which can be read in with almost all technologies. The final dataset consists of "data/combinedData_w_target.csv" (features + targets), "data/combinedData.csv" (only features), and "data/targets.csv" (only targets).

The analysis scripts are organised in three categories and corresponding folders: "dataExploration", "decisionTree", and "linearRegression". The "results" folder containing all final results (e.g., feature-feature correlation plots) is divided into these same categories, i.e., three subfolders.

The "documentation" folder contains some project and analysis documentation, e.g., the pdf containing all metrics used, the final presentation as pdf and pptx, etc.

# Description of Scripts

All script descriptions are ordered by subfolder and execution order.

## dataGeneration

### subfolder: teamscale_metrics
The subfolder contains all scripts for the extraction and processing of teamscale metrics as well as a detailed README on how these metrics are obtained.

### suspiciousnessScore_util.R
This utility-script provides several methods for pre-processing data (in order to provide uniform formats), calculating suspiciousness scores and processing these to obtain meaningful target values.

### suspiciousnessScore.R
This script generates the target values based on suspiciousness of artifacts and real fault locations for one project at a time. Its results are written to "data/PROJECT_suspiciousness.csv".

### graphMetrics.R
This script analyses callgraph and data dependency graph files to create dynamic metrics. It analyses one project at a time and its results are written to "data/graphs/PROJECT/dynamic_metrics.csv".

### extractRealFaults.R
This script matches provided location of faults to the corresponding method names (in our gzoltar format). Its results are written to "data/realFaults/faults.csv". The file "data/realFaults/faults_handwritten.csv" contains the same information supplemented by the manually evaluated faults. This is the file used for all analyses.

### testStatistics.R
This script analyses gzoltar files one project at a time to generate test statistics which are written to "/data/PROJECT_testStatistics.csv".

### combineData.R
This script is used to combine the different features and targets (teamscale, dynamic, test, bug, targets) into one single data.frame. Its results are written to "data/combinedData_w_target.csv" (features + targets), "data/combinedData.csv" (only features), and "data/targets.csv" (only targets).

### Non-maintained scripts: findBuggyMethods.R

## dataExploration

### dataExploration.R

This script performs different data exploration techniques, e.g., correlation and variance analyses as well as PCA. Its results (mostly plots) are saved in "results/dataExploration".

### Non-maintained scripts: correlationAnalysis.R

## linearRegression

### linearRegression.R

This script performs an linear regression analysis of the indicated dataset. The target value to consider as well as the features/feature combinations can be specified. The script writes its results to "results/linearRegression" in the specified CSV files, as a txt-file with name "TARGET~FEATURE1+FEATURE2+...+FEATUREn.txt" if the corresponding option was set.

### Non-maintained scripts: linearRegression.py, linearRegression_PCA.R

## decisionTree

TODO Thomas
