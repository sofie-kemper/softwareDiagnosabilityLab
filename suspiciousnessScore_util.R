library("data.table")
library("plyr")

PASS.FAIL <- c("0" = "-", "1" = "+")

match.pass.fail <- function(digit){
  return(as.character(PASS.FAIL[digit+1]))
}

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
  scores[, Tarantula := (N_cf/N_f) / ((N_cf/N_f) + (N_cs/N_s))]
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
  for (j in 1:ncol(scores)) set(scores, which(is.infinite(scores[[j]]) | is.nan(scores[[j]])), j, NA)
  return(scores)
}

calculate_suspiciousness = function(scores,
                                    type = c("Jaccard", "Tarantula", "Ochiai",
                                             "DStar_1", "DStar_2", "DStar_3", "DStar_4", "DStar_5"),
                                    threshold = NA){
  type <- match.arg(type, choices = c("Jaccard", "Tarantula", "Ochiai",
                                      "DStar_1", "DStar_2", "DStar_3", "DStar_4", "DStar_5"))

  result <- scores[, .(artifact, get(type))]
  colnames(result) <- c("artifact", "suspiciousness.score")
  result <- result[order(-suspiciousness.score),]
  result[, suspiciousness.rank := frank(result, -suspiciousness.score, ties.method = "min")]

  if(!is.na(threshold)){
    result[, suspiciousness := suspiciousness.rank <= threshold]
  }

  return(result)
}

annotate_real_faults <- function(scores, real.faults){
  if(all(is.na(real.faults))){
    scores[, faulty:=NA]
    return(scores)
  }

  scores[, faulty:=F]
  for(real.fault in real.faults){
    if(!is.na(real.fault)){
      fault.split <- as.numeric(gregexpr("#", real.fault, fixed=T)[[1]]) # if -1 -> no match!
      fault.name <- substr(real.fault, 1, fault.split-1)
      fault.line <- substr(real.fault, fault.split, nchar(real.fault))
      scores[, faulty := faulty |
               (grepl(fault.name, artifact, fixed=T) & grepl(fault.line, artifact, fixed=T))]
    }
  }
  return(scores)
}

get_rank <- function(scores, type = c("Jaccard", "Tarantula", "Ochiai",
                                      "DStar_1", "DStar_2", "DStar_3", "DStar_4", "DStar_5")){
  type <- match.arg(type, choices = c("Jaccard", "Tarantula", "Ochiai",
                                      "DStar_1", "DStar_2", "DStar_3", "DStar_4", "DStar_5"))
  result <- scores[, .(artifact, get(type), faulty)]
  colnames(result) <- c("artifact", "suspiciousness.score", "faulty")
  result <- result[order(-suspiciousness.score),]
  result[, suspiciousness.rank := frank(result, -suspiciousness.score, ties.method = "min")]
  return(min(result[faulty == T, suspiciousness.rank])) # TODO first or last or avg rank of faulty methods?
}

get_nr_to_examine <- function(scores, type = c("Jaccard", "Tarantula", "Ochiai",
                                               "DStar_1", "DStar_2", "DStar_3", "DStar_4", "DStar_5")){
  type <- match.arg(type, choices = c("Jaccard", "Tarantula", "Ochiai",
                                      "DStar_1", "DStar_2", "DStar_3", "DStar_4", "DStar_5"))
  result <- scores[, .(artifact, get(type), faulty)]
  colnames(result) <- c("artifact", "suspiciousness.score", "faulty")
  result <- result[order(-suspiciousness.score),]
  result[, suspiciousness.rank := frank(result, -suspiciousness.score, ties.method = "min")]

  min.rank.faulty <- min(result[faulty == T, suspiciousness.rank]) # TODO first/last/avg?
  return(sum(result$suspiciousness.rank < min.rank.faulty)
         + ceiling(sum(result$suspiciousness.rank == min.rank.faulty)/2))
  }

get_test_statistics <- function(id, matrix){
  T_RN = nrow(matrix)
  T_NP = matrix[pass.fail == "+", .N]
  T_PP = T_NP/T_RN
  T_NF = matrix[pass.fail == "-", .N]
  T_PF = T_NF/T_RN
  ### TODO T_N
  ### TODO T_RP
  test_data <- matrix[, !"pass.fail", with=F]
  colnames(test_data) <- paste0("C", 1:ncol(test_data))
  T_D = 1 - abs(1 - 2*sum(test_data)/(nrow(test_data)*(ncol(test_data)-1)))
  #duplicates = ddply(test_data, .variables = colnames(test_data), .fun = nrow)

  numdup <- aggregate(rep(1, nrow(test_data)), test_data, sum)$x
  #numdup <- duplicates$V1
  T_G = 1 - sum(sapply(numdup, function(n){return(n*(n-1))}))/(T_RN*(T_RN-1))
  T_U = length(unique(as.data.table(t(as.matrix.data.frame(matrix[, !"pass.fail", with=F])))))/(ncol(matrix)-1)
  T_DDU = T_D * T_G * T_U

  return(list("id" = id,
              "T_RN" = T_RN,
              "T_NP" = T_NP,
              "T_PP" = T_PP,
              "T_NF" = T_NF,
              "T_PF" = T_PF,
              "T_D" = T_D,
              "T_G" = T_G,
              "T_U" = T_U,
              "T_DDY" = T_DDU))
}
