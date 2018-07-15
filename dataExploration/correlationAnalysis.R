### This script was used for exploratory purposes but not for the final results.
### It may not work for the current folder structure and data format without adaptations.

library("data.table")
library("corrplot")

DATA.PATH <- "coverageData"
RESULTS.PATH <- "results/dataExploration"

## read in data
data <- fread(file.path(DATA.PATH, "combinedData.csv"))
data.w.target <- fread(file.path(DATA.PATH, "combinedData_w_target.csv"))
target <- fread(file.path(DATA.PATH, "targets.csv"))

target.names <- colnames(target[, !"id", with=F])
feature.names <- colnames(data[, !"id", with=F])

corr <- cor(data.w.target[,feature.names, with=F], data.w.target[,target.names, with=F], use = "pairwise.complete.obs")

pdf(file.path(RESULTS.PATH, "correlations.pdf"))
corrplot(corr)
dev.off()
