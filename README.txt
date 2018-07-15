Exploring the Relationship between Design Metrics and Software Diagnosability
Seminar: summer term 2018, TUM
Thomas Dornberger, Sofie Kemper
Advisor: Mojdeh Golagha

## Results

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

## Folder Structure

## Description of Scripts
