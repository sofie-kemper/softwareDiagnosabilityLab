### This script was used for exploratory purposes but not for the final results.
### It may not work for the current folder structure and data format without adaptations.

library("data.table")
library("caTools")

## CONFIGURATION

DATA.PATH <- "coverageData/graphs/Lang/dynamic_metrics.csv"
OUTPUT.PATH <- "results/linearRegression_PCA"

target <- "CG_EC"
possible.targets <- c("CG_EC")

## READ DATA

data.ids <- fread(DATA.PATH)
data <- data.ids[,-1]
data <- data[,-1]

## PREPARE DATA

# delete columns containing only NA
not.na.idx <- which(colSums(!is.na(data)) > 0)
data.without.na <- na.omit(data[,eval(not.na.idx), with = F])

# split data into train and test set
set.seed(101)# for reproducible train-test split
sample <- sample.split(data.without.na[[target]], SplitRatio = 0.8)
train <- subset(data.without.na, sample)
test <- subset(data.without.na, !sample)

train.target <- train[[target]]
train.features <- train[, !(colnames(train) %in% possible.targets), with=F]

test.target <- test[[target]]
test.features <- test[,!(colnames(test) %in% possible.targets), with=F]

## APPLY PCA

## apply PCA as dimension-reduction technique to the data
pca <- prcomp(train.features, scale. = T, center = T)

# which components explain 90% of data variance?
sum.pca <- summary(pca)$importance
nr.important.components <- sum(sum.pca[3,] < 0.9) + 1

# transform training data to these most important principal components, discard the other components
pca.train <- predict(pca, train.features)
pca.train <- pca.train[, 1:nr.important.components]
pca.train <- cbind(pca.train, data.frame("target" = train.target))

# transform test data to the most important principal components
pca.test <- predict(pca, test.features)
pca.test <- pca.test[, 1:nr.important.components]
pca.test <- cbind(pca.test, data.frame("target" = test.target))

## APPLY LINEAR REGRESSION

# apply linear regression model to PCA-transformed training data
formula <- as.formula(target ~ .)
pca.lm <- lm(formula, data = pca.train)

# predict test set using obtained model
y_pred <- predict(pca.lm, pca.test)
y_exp <- pca.test$target

# calculate mean squared error
error <- sum((y_pred - y_exp)^2)/length(y_pred)

# save results as R file
save.image(file = paste0(OUTPUT.PATH, "/linearRegression_PCA_", target, ".RData"))
