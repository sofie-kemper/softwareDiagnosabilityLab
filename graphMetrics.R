library("data.table")
requireNamespace("sna")
library("igraph")

PROJECT <- "Lang"
DATA.PATH <- file.path("coverageData/graphs", PROJECT)

project.data <- data.table(project = c("Chart", "Closure", "Lang", "Math", "Mockito", "Time"),
                           nr.bugs = c(NA, 133, 65, 106, NA, 27))

## check whether dynamic data exists for the chosen project
nr.versions <- project.data[project == PROJECT, nr.bugs]
if(!is.na(nr.versions)){

  ## create table for storing results
  results <- data.table(id = paste0(PROJECT, "_", (1:nr.versions)))

  ## add all columns (initialised with NA-values) to table
  dynamic.features <- c("VC", "EC", "SEC", "MEP", "MAXVD", "MVD", "VD50Q", "VD75Q", "VD80Q", "VD90Q",
                        "MAXVI", "MVI", "MAXVO", "MVO", "MSND", "GD", "GR", "MD", "MEC",
                        "EC50Q", "EC75Q", "EC80Q", "EC90Q", "VCON", "ECON", "CC")
  dynamic.features <- c(paste0("CG_", dynamic.features), paste0("DD_", dynamic.features))
  results[, (dynamic.features) := NA]

#for(i in 1:project.data[project == "Lang",nr.bugs]){
for (i in 1:1){

  ## read graph (.dot format)
  adjacency <- sna::read.dot(paste0(DATA.PATH, "/", i , ".dot"))
  dd.graph <- graph_from_adjacency_matrix(adjacency, mode = "directed")
  cg.graph <- dd.graph
  ## TODO: distinguish data dependency and callgraph edges

  ## calculate metrics


}
}
