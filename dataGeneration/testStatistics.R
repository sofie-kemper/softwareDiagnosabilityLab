## libraries + util scripts

library("data.table")
source("/Users/sofiekemper/Documents/Uni/SS2018/lab/softwareDiagnosabilityLab/dataGeneration/suspiciousnessScore_util.R")

## CONFIGURATION

# set working directory to git root directory
setwd("/Users/sofiekemper/Documents/Uni/SS2018/lab/softwareDiagnosabilityLab")

PROJECT <- "Math"
ARTIFACT.LEVEL <- "method"

# Is the data in Mojdeh's provided format? We only use this data for Closure and Time, thus,
# the analysis might not work with Mojdeh's format for other projects
# (due to naming, structure, and encoding inconsistencies!)
DATA.BY.MOJDEH <- FALSE

project.data <- data.table(project = c("Chart", "Closure", "Lang", "Math", "Mockito", "Time"),
                           nr.bugs = c(26, 133, 65, 106, 38, 27))

real.faults <- fread("data/realFaults/faults_handwritten.csv", header = T)

## READ DATA + CALCULATE TEST METRICS

stats <- lapply(1:project.data[project == PROJECT, nr.bugs], function(VERSION){
  print(VERSION)# for logging purposes

  if (!DATA.BY.MOJDEH){
    DATA.PATH <- file.path("data", ARTIFACT.LEVEL, PROJECT, VERSION)

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
    return(NULL)
  }

  spectra <- fread(file.path(DATA.PATH, "spectra"), header = F, sep = "\t")

  worked = TRUE
  worked = tryCatch({# in case there are errors when reading -> catch exception...
    matrix <- fread(file.path(DATA.PATH, "matrix"), header = F, sep = " ")
    TRUE}, error = function(e){
      print(paste("#####", VERSION, "##### wrongly-formatted data!"))# for logging purposes
      return(FALSE)
    })

  if(!worked){# ... and set data to NA
    return(NULL)
  }


  if(dim(matrix)[2] == 1){# sometimes a different separator is used...
    matrix <- fread(file.path(DATA.PATH, "matrix"), header = F, sep = "\t")
  }

  colnames(matrix) <- unlist(c(spectra[,1], "pass.fail"))
  colnames(spectra) <- c("Component")
  ## matrix: rows = tests, cols = code artifacts + 1 row for pass/fail

  if(DATA.BY.MOJDEH){# fix matrix pass.vail column
    matrix[, pass.fail := match.pass.fail(pass.fail)]
  }

  return(get_test_statistics(p.id, matrix))
})


## COLLECT RESULTS + SAVE AS CSV

res <- rbindlist(stats)

write.csv(res, paste0("data/", PROJECT, "_testStatistics.csv"), row.names = FALSE)
