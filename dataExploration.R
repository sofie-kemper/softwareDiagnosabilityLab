library("ggplot2")
library("data.table")
library("corrplot")
library("Hmisc")

PATH.TO.DATA <- "coverageData/graphs/Lang/dynamic_metrics.csv"#"coverageData/data.csv"
OUTPUT.PATH <- "results/dataExploration"

data.ids <- fread(PATH.TO.DATA)
data <- data[, -1]
data <- data[,-1]

## examine correlations between different features
r.corr <- rcorr(as.matrix(data))
p.corr <- r.corr$p
r.corr <- r.corr$r
r.corr[is.na(r.corr)] <- 0

corr <- round(cor(data), 3)
corr[is.na(corr)] <- 0

## create plot of correlations
pdf(file.path(OUTPUT.PATH, "correlations.pdf"), height = 15, width = 15)
corrplot(corr, type = "upper", order = "hclust", method = "color", diag = T)
dev.off()

## create plot of correlations including only those statistically significant (p-val < 0.05)
pdf(file.path(OUTPUT.PATH, "correlations_pval.pdf"), height = 15, width = 15)
corrplot(r.corr, type = "upper", order = "hclust", method = "color", diag = T,
         p.mat = p.corr, insig = "blank")
dev.off()

## examine variance of the different features
## (in general: higher-variance features might be more interesting)
variance <- apply(data, 2, var)
names(variance) <- colnames(data)
variance <- sort(variance, decreasing = T)

## apply PCA as dimension-reduction technique to the data
## -> examine to find actual dimensionality of underlying data (w/o correlations)
not.na.idx <- which(colSums(!is.na(data)) > 0)
data.without.na <- data[,eval(not.na.idx), with = F]
pca <- prcomp(na.omit(data.without.na), scale. = T, center = T)

## print variance explained by the components
pdf(file.path(OUTPUT.PATH, "pca_variance.pdf"))
plot(pca, type = "l")
dev.off()

## analyse variance explained by the components:
## how many components explain 90% of the variance in the data?
sum.pca <- summary(pca)$importance
nr.important.components <- sum(sum.pca[3,] <= 0.9)


## maybe try LDA for discrete target values?
