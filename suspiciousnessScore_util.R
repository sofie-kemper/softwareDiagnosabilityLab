library("data.table")

compute.suspiciousness.scores <- function(matrix, spectra){

  nr.artifacts <- ncol(matrix)-1
  nr.tests <- nrow(matrix)

  ## compute preliminary metrics needed for suspiciousness scores for all artifacts
  scores <- data.table("artifact" = spectra$Component)
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

  return(scores)
}

calculate_suspiciousness = function(scores, type = c("Jaccard", "Tarantula", "Ochiai",
                                                     "DStar_1", "DStar_2", "DStar_3", "DStar_4", "DStar_5")){
  type <- match.arg(type, choices = c("Jaccard", "Tarantula", "Ochiai",
                                      "DStar_1", "DStar_2", "DStar_3", "DStar_4", "DStar_5"))

  result <- scores[, .(artifact, get(type))]
  colnames(result) <- c("artifact", "suspiciousness")
  result <- result[order(-suspiciousness),]
  result[, suspiciousness.rank := frank(result, -suspiciousness, ties.method = "min")]
  ## TODO ties.method dense or min?!

  return(result)
}
