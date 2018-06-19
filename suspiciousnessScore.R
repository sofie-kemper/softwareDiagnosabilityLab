## libraries + util scripts

library("data.table")
source("suspiciousnessScore_util.R")

## configuration

PROJECT <- "Lang"
ARTIFACT.LEVEL <- "method"

project.data <- data.table(project = c("Chart", "Closure", "Lang", "Math", "Mockito", "Time"),
                           nr.bugs = c(26, 133, 65, 106, 38, 27))

real.faults <- fread("coverageData/realFaults/faults_handwritten.csv", header = T)

all.scores <- lapply(1:project.data[project == PROJECT, nr.bugs], function(VERSION){

  DATA.PATH <- file.path("coverageData", ARTIFACT.LEVEL, PROJECT, VERSION)
  p.id <- paste(PROJECT, VERSION, sep="_")

  spectra <- fread(file.path(DATA.PATH, "spectra"), header = F, sep = "\t")
  matrix <- fread(file.path(DATA.PATH, "matrix"), header = F, sep = " ")
  colnames(matrix) <- unlist(c(spectra[,1], "pass.fail"))
  colnames(spectra) <- c("Component")
  ## matrix: rows = tests, cols = code artifacts + 1 row for pass/fail

  scores <- compute.suspiciousness.scores(matrix, spectra)
  scores <- annotate_real_faults(scores, real.faults[id == p.id, faulty.method])

  write.csv(scores, file.path(DATA.PATH, "suspiciousness.csv"), row.names = F)
  return(scores)
})

res <- lapply(1:length(all.scores), function(VERSION){
  score <- all.scores[[VERSION]]
  p.id <- paste(PROJECT, VERSION, sep="_")

  if(!all(is.na(score$faulty))){# otw we don't have information about which method is faulty!
    return(list(id = p.id,# TODO percentage to examine?
                nr.to.examine.dstar.2 = get_nr_to_examine(score, "DStar_2"),
                rank.dstar.2 = get_rank(score, "DStar_2"),
                nr.to.examine.dstar.3 = get_nr_to_examine(score, "DStar_3"),
                rank.dstar.3 = get_rank(score, "DStar_3"),
                nr.to.examine.dstar.4 = get_nr_to_examine(score, "DStar_4"),
                rank.dstar.4 = get_rank(score, "DStar_4"),
                nr.to.examine.jaccard = get_nr_to_examine(score, "Jaccard"),
                rank.jaccard = get_rank(score, "Jaccard"),
                nr.to.examine.tarantula = get_nr_to_examine(score, "Tarantula"),
                rank.tarantula = get_rank(score, "Tarantula"),
                nr.to.examine.ochiai = get_nr_to_examine(score, "Ochiai"),
                rank.ochiai = get_rank(score, "Ochiai")))
  }
})

diagnosability.scores <- rbindlist(res, use.names=T, fill=F)

write.csv(diagnosability.scores, paste0("coverageData/", PROJECT, "_diagnosability.csv"), row.names = FALSE)
