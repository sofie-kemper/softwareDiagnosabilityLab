### This script was used for exploratory purposes but not for the final results.
### It may not work for the current folder structure and data format without adaptations.

library("jsonlite")

bug.locations <- fromJSON("coverageData/defects4j-bugs.json", flatten = F)
for(i in 1:5){#nrow(bug.locations)){
  id <- paste(bug.locations[i,"project"], bug.locations[i, "bugId"], sep="_")
  faults <- bug.locations[i,"changedFiles"]

}
