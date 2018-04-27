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

## compute preliminary metrics needed for suspiciousness scores for all artifacts
scores <- data.table("artifact" = spectra$V1)
scores[, N_cf := sapply(matrix[pass.fail == "-",!"pass.fail", with = F], function(col){sum(col == 1)})]
scores[, N_cs := sapply(matrix[pass.fail == "+",!"pass.fail", with = F], function(col){sum(col == 1)})]
scores[, N_uf := sapply(matrix[pass.fail == "-",!"pass.fail", with = F], function(col){sum(col == 0)})]
scores[, N_us := sapply(matrix[pass.fail == "+",!"pass.fail", with = F], function(col){sum(col == 0)})]
scores[, N_f := matrix[pass.fail == "-", .N]]
scores[, N_s := matrix[pass.fail == "+", .N]]

## compute suspiciousness scores
scores[, Jaccard := N_cf /(N_cf + N_uf + N_cs)]
scores[, Tarantula := (N_cf/N_f) / ((N_cf/N_f) + (N_cs+N_s))]
scores[, Ochiai := N_cf /(sqrt(N_f * (N_cf + N_cs)))]
scores[, DStar_1 := N_cf/(N_uf + N_cs)]
scores[, DStar_2 := (N_cf^2)/(N_uf + N_cs)]
scores[, DStar_3 := (N_cf^3)/(N_uf + N_cs)]
scores[, DStar_4 := (N_cf^4)/(N_uf + N_cs)]
scores[, DStar_5 := (N_cf^5)/(N_uf + N_cs)]

## TODO: how to proceed when no tests cover a given artifact?!
## (e.g., important for Chart-1, artifact 3, Ochiai score etc.)

## delete preliminary metrics as they are now unneeded
scores[, c("N_cf", "N_cs", "N_uf", "N_us", "N_f", "N_s") := list(NULL, NULL, NULL, NULL, NULL, NULL)]

write.csv(scores, file.path(DATA.PATH, "suspiciousness.csv"), row.names = F)
