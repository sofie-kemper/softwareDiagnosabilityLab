## libraries + util scripts

library("data.table")
source("suspiciousnessScore_util.R")

## configuration

PROJECT <- "Lang"
ARTIFACT.LEVEL <- "method"

project.data <- data.table(project = c("Chart", "Closure", "Lang", "Math", "Mockito", "Time"),
                           nr.bugs = c(26, 133, 65, 106, 38, 27))
#project.data[3,2] <- 33

for(VERSION in 1:project.data[project == PROJECT, nr.bugs]){

  DATA.PATH <- file.path("coverageData", ARTIFACT.LEVEL, PROJECT, VERSION)

  spectra <- fread(file.path(DATA.PATH, "spectra"), header = T, sep = "\t")
  matrix <- fread(file.path(DATA.PATH, "matrix"), header = F, sep = " ")
  colnames(matrix) <- unlist(c(spectra$Component, "pass.fail"))
  ## matrix: rows = tests, cols = code artifacts + 1 row for pass/fail

  scores <- compute.suspiciousness.scores(matrix, spectra)

  write.csv(scores, file.path(DATA.PATH, "suspiciousness.csv"), row.names = F)

  jaccard <- calculate_suspiciousness(scores, type = "Jaccard", threshold = 2)

}
