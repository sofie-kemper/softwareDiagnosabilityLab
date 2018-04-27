## libraries

library("data.table")

## configuration

PROJECT <- "Chart"
VERSION <- 1
DATA.PATH <- file.path("coverageData", PROJECT, VERSION)

spectra <- fread(file.path(DATA.PATH, "spectra"), header = F)
matrix <- fread(file.path(DATA.PATH, "matrix"), header = F, sep = " ")
colnames(matrix) <- unlist(c(spectra$V1, "pass.fail"))

## matrix: rows = tests, cols = code artifacts + 1 row for pass/fail

nr.artifacts <- nrow(spectra)
nr.tests <- nrow(matrix)

## compute metrics needed for suspiciousness scores for all artifacts
scores <- data.table("artifact" = spectra$V1)
scores[, N_cf := sapply(matrix[pass.fail == "-",!"pass.fail", with = F], function(col){sum(col == 1)})]
scores[, N_cs := sapply(matrix[pass.fail == "+",!"pass.fail", with = F], function(col){sum(col == 1)})]
scores[, N_uf := sapply(matrix[pass.fail == "-",!"pass.fail", with = F], function(col){sum(col == 0)})]
scores[, N_us := sapply(matrix[pass.fail == "+",!"pass.fail", with = F], function(col){sum(col == 0)})]
scores[, N_f := matrix[pass.fail == "-", .N]]
scores[, N_s := matrix[pass.fail == "+", .N]]
