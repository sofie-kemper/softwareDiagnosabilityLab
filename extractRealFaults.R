library("data.table")

## configuration
PROJECTS <- c("Chart", "Closure", "Lang", "Math", "Mockito", "Time")

project.data <- data.table(project = c("Chart", "Closure", "Lang", "Math", "Mockito", "Time"),
                           nr.bugs = c(26, 133, 65, 106, 38, 27))

ids <- c()
for (PROJECT in PROJECTS){
  nr.versions <- project.data[project == PROJECT, nr.bugs]
  ids <- c(ids, paste(PROJECT, 1:nr.versions, sep="_"))
}

real.faults <- data.table(id = ids, faulty.method = NA_character_)
for (PROJECT in c("Lang", "Closure", "Time")){
  nr.versions <- project.data[project == PROJECT, nr.bugs]
  for (version in 1:nr.versions){
    data.path <- paste0("coverageData/realFaults/", PROJECT, "/", version, ".dot")
    data <- readLines(data.path)
    real.idx <- grep("real", data, fixed = T)-1
    if(length(real.idx) > 1){
      browser()
    }
    faulty <- data[real.idx]
    idx <- as.numeric(gregexpr("\"", faulty, fixed = T)[[1]])
    faulty <- substr(faulty, idx[1]+1, idx[2]-1)
    real.faults[id == paste(PROJECT, version, sep="_"),] <- list(paste(PROJECT, version, sep="_"), faulty)
  }
}

write.csv(real.faults, paste0("coverageData/realFaults/faults.csv"), row.names=F)
