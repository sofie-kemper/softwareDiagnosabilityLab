library("ggplot2")
library("data.table")
library("corrplot")
library("Hmisc")

DATA.PATH <- "coverageData"
RESULTS.PATH <- "results/dataExploration"

## read in data
data <- fread(file.path(DATA.PATH, "combinedData.csv"))
data.w.target <- fread(file.path(DATA.PATH, "combinedData_w_target.csv"))
target <- fread(file.path(DATA.PATH, "targets.csv"))

target.names <- colnames(target[, !"id", with=F])
feature.names <- colnames(data[, !"id", with=F])

# define which types the different features have
feature.types <- data.table(name = feature.names, type = "static")
feature.types[grepl("^CG_", name), "type"] <- "dynamic"
feature.types[grepl("^DD_", name), "type"] <- "dynamic"
feature.types[grepl("^T_", name), "type"] <- "test"
feature.types[grepl("^B_", name), "type"] <- "bug"
feature.types[grepl("^BF_", name), "type"] <- "bug"

## examine correlations between different features
r.corr <- rcorr(as.matrix(data.w.target[,feature.names, with=F]), as.matrix(data.w.target[,target.names, with=F]))
p.corr <- r.corr$P
r.corr <- r.corr$r

r.corr.wo.na <- r.corr
r.corr.wo.na[is.na(r.corr.wo.na)] <- 0

#corr <- round(cor(data), 3)

## create plot of correlations
pdf(file.path(RESULTS.PATH, "correlations.pdf"), height = 15, width = 15)
corrplot(r.corr.wo.na, order = "hclust", method = "color")
dev.off()

## create plot of correlations including only those statistically significant (p-val < 0.05)
pdf(file.path(RESULTS.PATH, "correlations_pval.pdf"), height = 15, width = 15)
corrplot(r.corr.wo.na, order = "hclust", method = "color",p.mat = p.corr, insig = "blank")
dev.off()

## get correlation of features to targets
f.t.corr <- r.corr[feature.names, target.names]
plot.f.t.corr <- melt(f.t.corr)

p <- ggplot(plot.f.t.corr, aes(Var1, Var2, fill = value)) + geom_tile()
p <- p + scale_fill_gradient2(mid = "white", midpoint = 0, low = "deeppink3", high = "green4", limits = c(-1,1))
p <- p + theme(axis.text.x = element_text(angle = 45, size = 6, vjust = 1, hjust = 1))
pdf(file.path(RESULTS.PATH, "featureTargetCorrelations.pdf"), height = 5, width = 15)
print(p)
dev.off()

r.corr.p <- r.corr
r.corr.p[abs(p.corr) > 0.05] <- NA
f.t.corr.p <- r.corr.p[feature.names, target.names]
feature.order <- rownames(f.t.corr.p)[order(f.t.corr.p[, "nr_to_examine_dstar_2"])]

plot.f.t.corr.p <- melt(f.t.corr.p)
p <- ggplot(plot.f.t.corr.p, aes(factor(Var1, levels=feature.order), Var2, fill = value)) + geom_tile()
p <- p + scale_fill_gradient2(mid = "white", midpoint = 0, low = "deeppink3", high = "green4", limits = c(-1,1))
p <- p + theme(axis.text.x = element_text(angle = 45, size = 6, vjust = 1, hjust = 1))
pdf(file.path(RESULTS.PATH, "featureTargetCorrelations_pVal.pdf"), height = 5, width = 15)
print(p)
dev.off()

# find the features that are correlated
corr.features <- data.table(f.t.corr.p)
corr.features[, name := rownames(f.t.corr.p)]
corr.features <- corr.features[, .(nr_to_examine_dstar_2, name)]
corr.features <- corr.features[!is.na(nr_to_examine_dstar_2),]
corr.features <- merge(corr.features, feature.types, by = "name")
corr.features[, cor.type := "none"]
corr.features[nr_to_examine_dstar_2 < 0, "cor.type"] <- "negative"
corr.features[nr_to_examine_dstar_2 > 0, "cor.type"] <- "positive"

p <- ggplot(corr.features, aes(type, nr_to_examine_dstar_2, colour = cor.type))
p <- p + geom_jitter(width = 0.1)
p <- p + theme(legend.position = "bottom")
p <- p + scale_color_manual(values = c("negative" = "green4", "positive" = "deeppink3", "none" = "gray66"))
pdf(file.path(RESULTS.PATH, "correlatedFeatureTypes.pdf"), height = 5, width = 7)
print(p)
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

## apply linear regression to PCA-transformed result

## TODO correlation targets -> features
## TODO only static, only dynamic, etc -> look at which are relevant

## TODO dynamic complexity
