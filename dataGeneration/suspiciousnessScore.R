## LIBRARIES AND UTILITY SCRIPTS

library("data.table")

source("/Users/sofiekemper/Documents/Uni/SS2018/lab/softwareDiagnosabilityLab/dataGeneration/suspiciousnessScore_util.R")

## CONFIGURATION

# set working directory to git root directory
setwd("/Users/sofiekemper/Documents/Uni/SS2018/lab/softwareDiagnosabilityLab")

PROJECT <- "Time"
ARTIFACT.LEVEL <- "method"

# Is the data in Mojdeh's provided format? We only use this data for Closure and Time, thus,
# the analysis might not work with Mojdeh's format for other projects
# (due to naming, structure, and encoding inconsistencies!)
DATA.BY.MOJDEH <- TRUE

project.data <- data.table(project = c("Chart", "Closure", "Lang", "Math", "Mockito", "Time"),
                           nr.bugs = c(26, 133, 65, 106, 38, 27))

real.faults <- fread("data/realFaults/faults_handwritten.csv", header = T)

### READ IN AND ANALYSE DATA
all.scores <- lapply(1:project.data[project == PROJECT, nr.bugs], function(VERSION){
  print(VERSION)# for logging purposes

  if (!DATA.BY.MOJDEH){
    DATA.PATH <- file.path("coverageData", ARTIFACT.LEVEL, PROJECT, VERSION)

  }else{
    if (PROJECT == "Closure" | PROJECT == "Time"){
      DATA.PATH <- file.path("/Users/sofiekemper/Desktop/Mojdeh_data", PROJECT, tolower(PROJECT), VERSION)
    }else{
      DATA.PATH <- file.path("/Users/sofiekemper/Desktop/Mojdeh_data", PROJECT, tolower(PROJECT), paste0(PROJECT, VERSION), "gzoltars", PROJECT, VERSION)
    }
  }
  p.id <- paste(PROJECT, VERSION, sep="_")

  if(file.size(file.path(DATA.PATH, "spectra")) == 0) {
    print(paste("#####", VERSION, "##### data missing"))# for logging purposes
    return(NA)
  }

  spectra <- fread(file.path(DATA.PATH, "spectra"), header = F, sep = "\t")

  worked = TRUE
  worked = tryCatch({# in case there are errors when reading -> catch exception...
    matrix <- fread(file.path(DATA.PATH, "matrix"), header = F, sep = " ")
    TRUE}, error = function(e){
    print(paste("#####", VERSION, "##### wrongly-formatted data!"))
    return(FALSE)
  })

  if(!worked){# ... and set data to NA
    return(NA)
  }

  if(dim(matrix)[2] == 1){# sometimes a different separator is used...
    matrix <- fread(file.path(DATA.PATH, "matrix"), header = F, sep = "\t")
  }

  colnames(matrix) <- unlist(c(spectra[,1], "pass.fail"))
  colnames(spectra) <- c("Component")
  ## matrix: rows = tests, cols = code artifacts + 1 row for pass/fail

  if(DATA.BY.MOJDEH){# fix matrix pass.fail column
    matrix[, pass.fail := match.pass.fail(pass.fail)]
  }

  ## compute suspiciousness
  scores <- compute.suspiciousness.scores(matrix, spectra)
  scores <- annotate_real_faults(scores, real.faults[id == p.id, faulty.method])

  # optional writing of the raw suspiciousness scores (not the target values for maching learning)
  #write.csv(scores, file.path(DATA.PATH, "suspiciousness.csv"), row.names = F)
  return(scores)
})

### PROCESSING OF SUSPICIOUSNESS -> TARGET VALUES

res <- lapply(1:length(all.scores), function(VERSION){
  score <- all.scores[[VERSION]]
  p.id <- paste(PROJECT, VERSION, sep="_")
  print(VERSION)

  if(!all(is.na(score))){
    if(!all(is.na(score$faulty))){# otw we don't have information about which method is faulty!
      return(list(id = p.id,
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
  }
})

diagnosability.scores <- rbindlist(res, use.names=T, fill=F)

### SAVE DATA AS CSV

write.csv(diagnosability.scores, paste0("data/", PROJECT, "_diagnosability.csv"), row.names = FALSE)
