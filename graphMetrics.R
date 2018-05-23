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
  results <- data.table(id = 1:nr.versions)

  ## add all columns (initialised with NA-values) to table
  dynamic.features <- c("VC", "EC", "SEC", "MEP", "MAXVD", "MVD", "VD50Q", "VD75Q", "VD80Q", "VD90Q",
                        "MAXVI", "MVI", "MAXVO", "MVO", "MSND", "GD", "GR", "MD", "MEC",
                        "EC50Q", "EC75Q", "EC80Q", "EC90Q", "VCON", "ECON", "CC")
  dynamic.features <- c(paste0("CG_", dynamic.features), paste0("DD_", dynamic.features))
  results[, (dynamic.features) := NA_real_]

  for(i in 1:project.data[project == "Lang",nr.bugs]){

    ## read graph (.dot format)
    adjacency <- sna::read.dot(paste0(DATA.PATH, "/", i , ".dot"))
    dd.graph <- graph_from_adjacency_matrix(adjacency, mode = "directed")
    cg.graph <- dd.graph
    ## TODO: distinguish data dependency and callgraph edges

    ## calculate metrics for call graph and data dependency graph data
    for(type in c("CG", "DD")){

      ## retrieve suitable graph
      if(type == "CG"){
        graph = cg.graph
      }else{
        graph = dd.graph
      }

      ## count-based metrics
      results[i, paste(type, "VC", sep = "_")] <- vcount(graph)
      results[i, paste(type, "EC", sep = "_")] <- ecount(graph)

      ## degree-based metrics
      degrees <- degree(graph)
      results[i, paste(type, "MAXVD", sep = "_")] <- max(degrees)
      results[i, paste(type, "MVD", sep = "_")] <- mean(degrees)
      results[i, paste(type, "VD50Q", sep = "_")] <- quantile(degrees, 0.50)
      results[i, paste(type, "VD75Q", sep = "_")] <- quantile(degrees, 0.75)
      results[i, paste(type, "VD80Q", sep = "_")] <- quantile(degrees, 0.80)
      results[i, paste(type, "VD90Q", sep = "_")] <- quantile(degrees, 0.90)

      in.degrees <- degree(graph, mode = "in")
      results[i, paste(type, "MAXVI", sep = "_")] <- max(in.degrees)
      results[i, paste(type, "MVI", sep = "_")] <- mean(in.degrees)

      out.degrees <- degree(graph, mode = "out")
      results[i, paste(type, "MAXVO", sep = "_")] <- max(out.degrees)
      results[i, paste(type, "MVO", sep = "_")] <- mean(out.degrees)

      start.nodes <- V(graph)[degree(graph, mode = "in") == 0]
      results[i, paste(type, "MSND", sep = "_")] <- max(degree(graph, v = start.nodes, mode = "out"))

      ## distance-based metrics
      results[i, paste(type, "GD", sep = "_")] <- diameter(graph)
      results[i, paste(type, "GD", sep = "_")] <- radius(graph)

      results[i, paste(type, "MD", sep = "_")] <- mean_distance(graph, unconnected = FALSE)

      ## centrality-based metrics
      eigen.centralitites <- eigen_centrality(graph, directed = FALSE, scale = FALSE)$vector

      results[i, paste(type, "MAXEC", sep = "_")] <- max(eigen.centralitites)
      results[i, paste(type, "EC50Q", sep = "_")] <- quantile(eigen.centralitites, 0.5)
      results[i, paste(type, "EC75Q", sep = "_")] <- quantile(eigen.centralitites, 0.75)
      results[i, paste(type, "EC80Q", sep = "_")] <- quantile(eigen.centralitites, 0.80)
      results[i, paste(type, "EC90Q", sep = "_")] <- quantile(eigen.centralitites, 0.90)

      ## connectivity-based metrics
      results[i, paste(type, "VCON", sep = "_")] <- vertex_connectivity(as.undirected(graph))
      results[i, paste(type, "ECON", sep = "_")] <- edge_connectivity(as.undirected(graph))

      ## clustering-based metric
      results[i, paste(type, "CC", sep = "_")] <- transitivity(graph, type = "global")
    }
  }

  results <- round(results, digits = 2)
  results[, id:= paste0(PROJECT, "_", id)]
  write.csv(results, file = paste(DATA.PATH, "dynamic_metrics.csv", sep = "/"))
}
