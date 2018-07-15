library("ggplot2")
library("data.table")
library("corrplot")
library("Hmisc")

## CONFIGURATION

# set working directory to git root directory
setwd("/Users/sofiekemper/Documents/Uni/SS2018/lab/softwareDiagnosabilityLab")
DATA.PATH <- "data"
RESULTS.PATH <- "results/dataExploration"

## DATA PREPARATION

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

## examine correlations between different features (feature-feature correlations)
r.corr <- rcorr(as.matrix(data.w.target[,feature.names, with=F]), as.matrix(data.w.target[,target.names, with=F]))
p.corr <- r.corr$P
r.corr <- r.corr$r

r.corr.wo.na <- r.corr
r.corr.wo.na[is.na(r.corr.wo.na)] <- 0

## create plot of correlations
pdf(file.path(RESULTS.PATH, "correlations.pdf"), height = 15, width = 15)
corrplot(r.corr.wo.na, order = "hclust", method = "color", insig = "blank",
         type="upper", tl.cex = 0.6, tl.col = "darkgray")
dev.off()

## create plot of correlations including only those statistically significant (p-val < 0.05)
pdf(file.path(RESULTS.PATH, "correlations_pval.pdf"), height = 15, width = 15)
corrplot(r.corr.wo.na, order = "hclust", method = "color",p.mat = p.corr,
         insig = "blank", type="upper", tl.cex = 0.6, tl.col = "darkgray")
dev.off()

## get correlation of features to targets (feature-target correlations)
f.t.corr <- r.corr[feature.names, target.names]
plot.f.t.corr <- melt(f.t.corr)

# plot correlations
p <- ggplot(plot.f.t.corr, aes(Var1, Var2, fill = value)) + geom_tile()
p <- p + scale_fill_gradient2(mid = "white", midpoint = 0, low = "firebrick4", high = "dodgerblue4",
                              limits = c(-1,1), na.value = "gray88")
p <- p + theme(axis.text.x = element_text(angle = 45, size = 6, vjust = 1, hjust = 1))
pdf(file.path(RESULTS.PATH, "featureTargetCorrelations.pdf"), height = 5, width = 15)
print(p)
dev.off()

## filter only statistically significant correlations
r.corr.p <- r.corr
r.corr.p[abs(p.corr) > 0.05] <- NA
f.t.corr.p <- r.corr.p[feature.names, target.names]
feature.order <- rownames(f.t.corr.p)[order(f.t.corr.p[, "nr_to_examine_dstar_2"])]

# plot correlations
plot.f.t.corr.p <- melt(f.t.corr.p)
p <- ggplot(plot.f.t.corr.p, aes(factor(Var1, levels=feature.order), Var2, fill = value)) + geom_tile()
p <- p + scale_fill_gradient2(mid = "white", midpoint = 0, low = "firebrick4", high = "dodgerblue4",
                              limits = c(-1,1), na.value = "gray88")
p <- p + theme(axis.text.x = element_text(angle = 45, size = 6, vjust = 1, hjust = 1))
pdf(file.path(RESULTS.PATH, "featureTargetCorrelations_pVal.pdf"), height = 5, width = 15)
print(p)
dev.off()

# find the features (names) that are correlated
corr.features <- data.table(f.t.corr.p)
corr.features[, name := rownames(f.t.corr.p)]
corr.features <- corr.features[, .(nr_to_examine_dstar_2, name)]
corr.features <- corr.features[!is.na(nr_to_examine_dstar_2),]
corr.features <- merge(corr.features, feature.types, by = "name")
corr.features[, cor.type := "none"]
corr.features[nr_to_examine_dstar_2 < 0, "cor.type"] <- "negative"
corr.features[nr_to_examine_dstar_2 > 0, "cor.type"] <- "positive"

# plot types of correlated features
p <- ggplot(corr.features, aes(type, nr_to_examine_dstar_2, colour = cor.type))
p <- p + geom_jitter(width = 0.1, size = 5)
p <- p + theme(legend.position = "bottom")
p <- p + scale_color_manual(values = c("negative" = "firebrick4", "positive" = "dodgerblue4", "none" = "gray66"))
pdf(file.path(RESULTS.PATH, "correlatedFeatureTypes.pdf"), height = 5, width = 7)
print(p)
dev.off()

## examine variance of the different features
## (in general: higher-variance features might be more interesting)
variance <- apply(data[,!"id"], 2, var, na.rm = T)
names(variance) <- colnames(data)[-1]
variance <- sort(variance, decreasing = T)

## save variance as CSV
write.csv(variance, file = file.path(RESULTS.PATH,"featureVariance.csv"), col.names = F)

## apply PCA as dimension-reduction technique to the data
## -> examine to find actual dimensionality of underlying data (w/o correlations)
data.wo.id <- data[,!"id"]
non.constant.columns <- which(apply(data.wo.id, 2, var, na.rm=TRUE) != 0)
data.wo.id[is.na(data.wo.id)] <- 0
DT <- data.wo.id

for (j in seq_len(ncol(DT))){
  set(DT,which(is.na(DT[[j]])),j,0)
}

pca <- prcomp(DT[,non.constant.columns, with = F], scale. = T, center = T)

## print variance explained by the components
pdf(file.path(RESULTS.PATH, "pca_variance.pdf"))
plot(pca, type = "l")
dev.off()

## analyse variance explained by the components:
## how many components explain 90% of the variance in the data?
sum.pca <- summary(pca)$importance
nr.important.components <- sum(sum.pca[3,] <= 0.9)
