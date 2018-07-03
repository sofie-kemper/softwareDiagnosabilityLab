## libraries + util scripts

library("data.table")
source("suspiciousnessScore_util.R")

## configuration

PROJECT <- "Closure"
ARTIFACT.LEVEL <- "method"
DATA.BY.MOJDEH <- TRUE

project.data <- data.table(project = c("Chart", "Closure", "Lang", "Math", "Mockito", "Time"),
                           nr.bugs = c(26, 133, 65, 106, 38, 27))

real.faults <- fread("coverageData/realFaults/faults_handwritten.csv", header = T)

stats <- lapply(1:project.data[project == PROJECT, nr.bugs], function(VERSION){
  print(VERSION)

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
    print(paste("#####", VERSION, "##### data missing"))
    return(NULL)
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

res <- rbindlist(stats)

write.csv(res, paste0("coverageData/", PROJECT, "_testStatistics.csv"), row.names = FALSE)
