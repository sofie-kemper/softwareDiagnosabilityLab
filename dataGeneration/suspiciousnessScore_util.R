library("data.table")
library("plyr")

PASS.FAIL <- c("0" = "-", "1" = "+")

## convert Mojdeh's matrix format to the current gzoltar format
## (use - and + for pass.fail instead of 0 and 1)
match.pass.fail <- function(digit){
  return(as.character(PASS.FAIL[digit+1]))
}

## compute all types of suspiciousness scores based on a given matrix and spectra
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

  ## delete preliminary metrics as they are now unneeded
  scores[, c("N_cf", "N_cs", "N_uf", "N_us", "N_f", "N_s") := list(NULL, NULL, NULL, NULL, NULL, NULL)]
  for (j in 1:ncol(scores)) set(scores, which(is.infinite(scores[[j]]) | is.nan(scores[[j]])), j, NA)
  return(scores)
}

## calculate suspiciousness ranks based on give scores and indicated suspiciousness type
## If a threshold is given: classes are assigned based on it; otw., ranks are used in the result
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

  if(!is.na(threshold)){## classification according to given threshold
    result[, suspiciousness := suspiciousness.rank <= threshold]
  }

  return(result)
}

## annotate which components are faulty in the given scores data.table
annotate_real_faults <- function(scores, real.faults){

  if(all(is.na(real.faults))){# no info about faulty method available
    scores[, faulty:=NA]
    return(scores)
  }

  scores[, faulty:=F]# initialise column
  for(real.fault in real.faults){# annotate every provided faulty method
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

## Get rank of first faulty method based on the given (annotated) scores and indicated suspiciousness type
get_rank <- function(scores, type = c("Jaccard", "Tarantula", "Ochiai",
                                      "DStar_1", "DStar_2", "DStar_3", "DStar_4", "DStar_5")){
  type <- match.arg(type, choices = c("Jaccard", "Tarantula", "Ochiai",
                                      "DStar_1", "DStar_2", "DStar_3", "DStar_4", "DStar_5"))
  result <- scores[, .(artifact, get(type), faulty)]
  colnames(result) <- c("artifact", "suspiciousness.score", "faulty")
  result <- result[order(-suspiciousness.score),]
  result[, suspiciousness.rank := frank(result, -suspiciousness.score, ties.method = "min")]
  return(min(result[faulty == T, suspiciousness.rank]))
}

## Compute the number of components to examine until the first faulty component is found. In cases of rank-
## ties, we assume that all lower-ranked components and half the components of the same rank have to
## be examined in order to find the fault. The calculation is based on the given (annotated) scores and
## the indicated suspiciousness type
get_nr_to_examine <- function(scores, type = c("Jaccard", "Tarantula", "Ochiai",
                                               "DStar_1", "DStar_2", "DStar_3", "DStar_4", "DStar_5")){
  type <- match.arg(type, choices = c("Jaccard", "Tarantula", "Ochiai",
                                      "DStar_1", "DStar_2", "DStar_3", "DStar_4", "DStar_5"))
  result <- scores[, .(artifact, get(type), faulty)]
  colnames(result) <- c("artifact", "suspiciousness.score", "faulty")
  result <- result[order(-suspiciousness.score),]

  # get ranks
  result[, suspiciousness.rank := frank(result, -suspiciousness.score, ties.method = "min")]

  # lowest-ranked faulty method -> first found
  min.rank.faulty <- min(result[faulty == T, suspiciousness.rank])

  # use average for ties in rank
  return(sum(result$suspiciousness.rank < min.rank.faulty)
         + ceiling(sum(result$suspiciousness.rank == min.rank.faulty)/2))
  }

## calculate test statistics based on the given gzoltar matrix (format with +/- for pass.fail, not
## Mojdeh's format)
get_test_statistics <- function(id, matrix){

  # numbers and proportions of (passing/failing) tests
  T_RN = nrow(matrix)
  T_NP = matrix[pass.fail == "+", .N]
  T_PP = T_NP/T_RN
  T_NF = matrix[pass.fail == "-", .N]
  T_PF = T_NF/T_RN

  # data preprocessing for DDU calculation
  test_data <- matrix[, !"pass.fail", with=F]
  colnames(test_data) <- paste0("C", 1:ncol(test_data))

  # test density
  T_D = 1 - abs(1 - 2*sum(test_data)/(nrow(test_data)*(ncol(test_data)-1)))

  numdup <- aggregate(rep(1, nrow(test_data)), test_data, sum)$x

  # test diversity
  T_G = 1 - sum(sapply(numdup, function(n){return(n*(n-1))}))/(T_RN*(T_RN-1))

  # test uniqueness
  T_U = length(unique(as.data.table(t(as.matrix.data.frame(matrix[, !"pass.fail", with=F])))))/(ncol(matrix)-1)
  T_DDU = T_D * T_G * T_U

  # return results in suitable format
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
