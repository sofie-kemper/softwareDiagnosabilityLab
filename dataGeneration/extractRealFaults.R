library("data.table")

## CONFIGURATION
PROJECTS <- c("Chart", "Closure", "Lang", "Math", "Mockito", "Time")

## set working directory to git root directory
setwd("/Users/sofiekemper/Documents/Uni/SS2018/lab/softwareDiagnosabilityLab")

project.data <- data.table(project = c("Chart", "Closure", "Lang", "Math", "Mockito", "Time"),
                           nr.bugs = c(26, 133, 65, 106, 38, 27))

## initialise empty table for results
real.faults <- data.table(id = character(0), faulty.method = character(0))

### FIND BUGGY METHODS FOR ALL AVAILABLE PROJECT VERSIONS
for (PROJECT in PROJECTS){
  nr.versions <- project.data[project == PROJECT, nr.bugs]

  for (version in 1:nr.versions){
    data.path <- paste0("data/realFaults/", PROJECT, "/", version, ".dot")

    if(file.exists(data.path)){# otw: no automatic fault matching possible since no data is provided
      data <- readLines(data.path)

      # find real fault(s)
      real.idx <- grep("[style=striped shape=box fillcolor=\"red", data, fixed = T)

      for (i in 1:(length(real.idx))){# save all matched real faults
        faulty <- data[real.idx[i]]
        idx <- as.numeric(gregexpr("\"", faulty, fixed = T)[[1]])

        # processing due to result format
        faulty <- substr(faulty, idx[1]+1, idx[2]-1)

        if(faulty != "real"){# "real" is the guide-box
          if(as.numeric(gregexpr("#", faulty, fixed=T)[[1]]) == -1){
            real.faults <- rbind(real.faults, list(paste(PROJECT, version, sep="_"), NA))
          }else{
            real.faults <- rbind(real.faults, list(paste(PROJECT, version, sep="_"), faulty))
          }
        }
      }
    }else{# no data available
      real.faults <- rbind(real.faults, list(paste(PROJECT, version, sep="_"), NA))
    }
  }
}

### SAVE RESULTS AS CSV
write.csv(real.faults, paste0("data/realFaults/faults.csv"), row.names=F)
