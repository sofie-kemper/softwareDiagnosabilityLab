library("data.table")
library("caTools")

## CONFIGURATION
features <- c("CG_VC", "CG_EC50Q")
features <- sort(features)# alphabetically sorted, necessary for representative file names
target <- "CG_EC"

## LOAD DATA

PATH.TO.DATA <- "coverageData/graphs/Lang/dynamic_metrics.csv"#"coverageData/data.csv"
OUTPUT.PATH <- "results/linearRegression"
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
formula.txt <- paste0(target, "~", paste(features, collapse="+"))
formula <- as.formula(formula.txt)

# apply linear regression
linReg <- lm(formula, data = train)
reg.sum <- summary(linReg)
r.sq <- reg.sum$adj.r.squared# how well does the model fit the train data?
coeff <- reg.sum$coefficients# coefficients of the model

# evaluate results using test set -> calculate mean squared error
y_pred <- predict(linReg, test)
y_exp <- test[[target]]
error <- sum((y_pred - y_exp)^2)/length(y_pred)

## save results for later comparisons
# formula used, error, and resulting coefficients are printed to a txt-file
write(formula.txt, file.path(OUTPUT.PATH, paste0(formula.txt, ".txt")))
write(paste("MSE:", round(error, 2), "\n"), file.path(OUTPUT.PATH, paste0(formula.txt, ".txt")), append = T)
write(paste(rownames(coeff), round(coeff[,1], 3), sep = ": "), file.path(OUTPUT.PATH, paste0(formula.txt, ".txt")), append = T)
