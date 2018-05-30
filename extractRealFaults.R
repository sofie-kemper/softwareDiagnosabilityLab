library("data.table")

## configuration
PROJECTS <- c("Chart", "Closure", "Lang", "Math", "Mockito", "Time")

project.data <- data.table(project = c("Chart", "Closure", "Lang", "Math", "Mockito", "Time"),
                           nr.bugs = c(26, 133, 65, 106, 38, 27))

real.faults <- data.table(id = character(0), faulty.method = character(0))

for (PROJECT in PROJECTS){
  nr.versions <- project.data[project == PROJECT, nr.bugs]

  for (version in 1:nr.versions){
    data.path <- paste0("coverageData/realFaults/", PROJECT, "/", version, ".dot")

    if(file.exists(data.path)){
      data <- readLines(data.path)
      real.idx <- grep("[style=striped shape=box fillcolor=\"red", data, fixed = T)

      for (i in 1:(length(real.idx))){
        faulty <- data[real.idx[i]]
        idx <- as.numeric(gregexpr("\"", faulty, fixed = T)[[1]])
        faulty <- substr(faulty, idx[1]+1, idx[2]-1)

        if(faulty != "real"){# "real" is the guide-box
          real.faults <- rbind(real.faults, list(paste(PROJECT, version, sep="_"), faulty))
        }
      }
    }else{
      real.faults <- rbind(real.faults, list(paste(PROJECT, version, sep="_"), NA))
    }
  }
}

write.csv(real.faults, paste0("coverageData/realFaults/faults.csv"), row.names=F)
