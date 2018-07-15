library("data.table")

## CONFIGURATION

# set working directory to git root directory
setwd("/Users/sofiekemper/Documents/Uni/SS2018/lab/softwareDiagnosabilityLab")
DATA.PATH <- "data"
PROJECTS = c("Chart", "Closure", "Lang", "Math", "Time")#"Mockito"

## READ DATA

## read in static metrics
static.list <- lapply(PROJECTS, function(project){
  return(fread(file.path(DATA.PATH, "teamscale", project, "staticMetrics.csv")))
})
static <- Reduce(rbind, static.list)

## read in dynamic metrics
dynamic.list <- lapply(c("Closure", "Lang", "Math", "Time"), function(project){
    dt <- fread(file.path(DATA.PATH, "graphs", project, "dynamic_metrics.csv"))
    dt[, V1:=NULL]
    return(dt)
})
dynamic <- Reduce(rbind, dynamic.list)

## read in test metrics
test.list <- lapply(PROJECTS, function(project){
  dt <- fread(paste0(DATA.PATH, "/", project, "_testStatistics.csv"))
  dt[, T_DDU := T_DDY]
  dt[, T_DDY := NULL]
  return(dt)
})
test <- Reduce(rbind, test.list)

## read in bug metrics
bug <- fread(file.path(DATA.PATH, "bugMetrics.csv"))
bug[, NrFailingTests := NULL] # row is already contained in the test metrics

## read in teamscale bug metrics
ts.bug.list <- lapply(PROJECTS, function(project){
  return(fread(file.path(DATA.PATH, "teamscale", project, "buggyFiles_staticMetrics.csv")))
})
ts.bug <- Reduce(rbind, ts.bug.list)

## read in target values
target.list <- lapply(PROJECTS, function(project){
  return(fread(paste0(DATA.PATH, "/", project, "_diagnosability.csv")))
})
target <- Reduce(rbind, target.list)

## COMBINE ALL DATA

data <- merge(static, dynamic, by = "id", all = T)
data <- merge(data, test, by = "id", all = T)
data <- merge(data, bug, by = "id", all = T)
data <- merge(data, ts.bug, by = "id", all = T)
data.w.target <- merge(data, target, by = "id", all = T)

colnames(data) <- gsub("-", "_", colnames(data), fixed = T)
colnames(data) <- gsub(".", "_", colnames(data), fixed = T)

colnames(data.w.target) <- gsub("-", "_", colnames(data.w.target), fixed = T)
colnames(data.w.target) <- gsub(".", "_", colnames(data.w.target), fixed = T)

colnames(target) <- gsub("-", "_", colnames(target), fixed = T)
colnames(target) <- gsub(".", "_", colnames(target), fixed = T)

## SAVE DATA AS CSV

write.csv(data, file = paste(DATA.PATH, "combinedData.csv", sep = "/"), row.names = FALSE)
write.csv(data.w.target, file = paste(DATA.PATH, "combinedData_w_target.csv", sep = "/"), row.names = FALSE)
write.csv(target, file = paste(DATA.PATH, "targets.csv", sep = "/"), row.names = FALSE)
