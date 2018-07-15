library("data.table")
library("caTools")

## CONFIGURATION

# set working directory to git root directory
setwd("/Users/sofiekemper/Documents/Uni/SS2018/lab/softwareDiagnosabilityLab")
DATA.PATH <- "data"
RESULTS.PATH <- "results/linearRegression"

## DATA PREPARATION

## read in data
data <- fread(file.path(DATA.PATH, "combinedData.csv"))
data.w.target <- fread(file.path(DATA.PATH, "combinedData_w_target.csv"))
targets <- fread(file.path(DATA.PATH, "targets.csv"))
target <- "nr_to_examine_dstar_2"

target.names <- colnames(targets[, !"id", with=F])
feature.names <- colnames(data[, !"id", with=F])

# define which types the different features belong to
feature.types <- data.table(name = feature.names, type = "static")
feature.types[grepl("^CG_", name), "type"] <- "dynamic"
feature.types[grepl("^DD_", name), "type"] <- "dynamic"
feature.types[grepl("^T_", name), "type"] <- "test"
feature.types[grepl("^B_", name), "type"] <- "bug"
feature.types[grepl("^BF_", name), "type"] <- "bug"

# split data into train and test set

set.seed(101)# for reproducible train-test split
data <- subset(data.w.target, select = c("id", feature.names, target))
sample <- sample.split(data$id, SplitRatio = 0.8)
train <- subset(data, sample)
test <- subset(data, !sample)

train$log_nr_to_examine_dstar_2 <- log(train$nr_to_examine_dstar_2)
test$log_nr_to_examine_dstar_2 <- log(test$nr_to_examine_dstar_2)

## APPLY LINEAR REGRESSION

### choose feature combination used, adapt result name, adapt target used

combinations.1 <- data.frame(name = feature.names)
combinations.2 <- CJ(feature.names, feature.names)
combinations.3 <- CJ(corr.features$name, corr.features$name)
combinations.4 <- CJ(corr.features$name, corr.features$name, corr.features$name)

combintaions <- combinations.3

target <- "log_nr_to_examine_dstar_2" # "nr_to_examine_dstar_2

res3 <- lapply(1:nrow(combinations), function(i){

  features <- as.character(combinations[i,])
  if(!all(features == sort(features)) | length(unique(features)) != length(features)){
    # avoid duplicate analyses of the same feature set: only analyse if features given in
    # alphabetical order and no duplicate features contained
    return()
  }

  # build formula of form target ~ feature1 + feature2 + ...
  formula.txt <- paste0(target, "~", paste(features, collapse="+"))
  formula <- as.formula(formula.txt)
  print(formula.txt)# for logging purposes

  # apply linear regression
  linReg <- lm(formula, data = train, na.action = na.omit)
  reg.sum <- summary(linReg)
  r.sq <- reg.sum$adj.r.squared# how well does the model fit the train data?
  coeff <- reg.sum$coefficients# coefficients of the model

  # evaluate results using test set -> calculate mean squared error
  y_pred <- predict(linReg, test)
  y_exp <- test[[target]]
  error <- sum((y_pred - y_exp)^2, na.rm = T)/length(y_pred)

  ## save results for later comparisons (uncomment if wanted)
  # formula used, error, and resulting coefficients are printed to a txt-file
  #write(formula.txt, file.path(RESULTS.PATH, paste0(formula.txt, ".txt")))
  #write(paste("MSE:", round(error, 2), "\n"), file.path(RESULTS.PATH, paste0(formula.txt, ".txt")), append = T)
  #write(paste(rownames(coeff), round(coeff[,1], 3), sep = ": "), file.path(RESULTS.PATH, paste0(formula.txt, ".txt")), append = T)

  # create data.frame of the results
  df <- data.frame(id = formula.txt)
  for (name in c("mse", "r2_score", "intercept", colnames(data.w.target), target)){
    df[,name] <- NA_real_
  }

  if(length(coeff[,1]) == (length(features)+1)){
    df[1,c("id","mse", "r2_score", "intercept", features, target)] <-  c(formula.txt, error, r.sq, coeff[,1], TRUE)
    return(df)
  }
})

## CREATE AND SAVE RESULTS

## uncomment correct combination of results and writing it to memory

## Table of the results: view by calling View(name) on the R console or by looking at the csv file

#res.1 <- rbindlist(res)
#res.2 <- rbindlist(res2)
res.3 <- rbindlist(res3)
#res.4 <- rbindlist(res4)

#write.csv(res.1, file = file.path(RESULTS.PATH, "oneFeature_number_regression.csv"), row.names = F)
#write.csv(res.2, file = file.path(RESULTS.PATH, "twoImportantFeatures_number_regression.csv"), row.names = F)
#write.csv(res.3, file = file.path(RESULTS.PATH, "twoImportantFeatures_LogNumber_regression.csv"), row.names = F)
#write.csv(res.4, file = file.path(RESULTS.PATH, "threeImportantFeatures_LogNumber_regression.csv"), row.names = F)
