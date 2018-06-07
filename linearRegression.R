library("data.table")
library("caTools")

## CONFIGURATION
features <- c("CG_VC", "CG_EC50Q", "CG_GD")
target <- "CG_EC"

## LOAD DATA

PATH.TO.DATA <- "coverageData/graphs/Lang/dynamic_metrics.csv"#"coverageData/data.csv"
data.ids <- fread(PATH.TO.DATA)
data <- data[,-1]
data <- data[,-1]

# split data into train and test set

set.seed(101)# for reporducible train-test split
sample <- sample.split(data[[eval(target)]], SplitRatio = 0.8)
train <- subset(data, sample)
test <- subset(data, !sample)

## APPLY LINEAR REGRESSION

# build formula of form target ~ feature1 + feature2 + ...
formula <- as.formula(paste0(target, "~", paste(features, collapse="+")))

# apply linear regression
linReg <- lm(formula, data = train)
reg.sum <- summary(linReg)
r.sq <- reg.sum$adj.r.squared
coeff <- reg.sum$coefficients

# evaluate results using test set -> calculate mean squared error
y_pred <- predict(linReg, test)
y_exp <- test[[target]]
error <- sum((y_pred - y_exp)^2)/length(y_pred)

## save results for later comparisons
# TODO
