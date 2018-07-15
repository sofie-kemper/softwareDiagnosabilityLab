library("data.table")
requireNamespace("sna")
library("igraph")

## CONFIGURATION

PROJECT <- "Time"

# set working directory to git root directory
setwd("/Users/sofiekemper/Documents/Uni/SS2018/lab/softwareDiagnosabilityLab")

# is the data in Thomas' format or in the one provided by Mojdeh
THOMAS.DATA <- FALSE

DATA.PATH <- file.path("data/graphs", PROJECT)

project.data <- data.table(project = c("Chart", "Closure", "Lang", "Math", "Mockito", "Time"),
                           nr.bugs = c(NA, 133, 65, 106, NA, 27))

real.faults <- fread("data/realFaults/faults_handwritten.csv", header = T)

## PERFORM ANALYSIS OF CALLGRAPHS AND DATA DEPENDENCY GRAPHS

## check whether dynamic data exists for the chosen project
nr.versions <- project.data[project == PROJECT, nr.bugs]
if(!is.na(nr.versions)){

  ## create table for storing results
  results <- data.table(id = 1:nr.versions)

  ## add all columns (initialised with NA-values) to table
  dynamic.features <- c("VC", "EC", "MAXVD", "MVD", "VD50Q", "VD75Q", "VD80Q", "VD90Q",
                        "MAXVI", "MVI", "MAXVO", "MVO", "MSND", "GD", "GR", "MD", "MAXEC",
                        "EC50Q", "EC75Q", "EC80Q", "EC90Q", "VCON", "ECON", "CC")
  dynamic.features <- c(paste0("CG_", dynamic.features), paste0("DD_", dynamic.features))
  results[, (dynamic.features) := NA_real_]

  for(i in 1:nr.versions){
    print(i)# for logging purposes

    if(THOMAS.DATA){# multiple graphs per version

      if(!dir.exists(file.path(DATA.PATH, i))){
        print(paste("----- no data -----"))
        next
      }
      dd.adjacency <- sna::read.dot(paste0(DATA.PATH, "/", i, "/ddg/", "ddg.dot"))
      dd.graph <- graph_from_adjacency_matrix(dd.adjacency, mode = "directed")

      cg.directory <- file.path(DATA.PATH, i, "cg")
      cg.files <- list.files(cg.directory)

      if(length(cg.files) > 0){# read in all graphs and combine them into a single graph
      cg <- lapply(cg.files, function(file.name){
        return(graph_from_adjacency_matrix(sna::read.dot(file.path(cg.directory, file.name)), mode = "directed"))
      })
      cg.graph <- igraph::simplify(Reduce(igraph::union, cg))

      }else{
        print("empty callgraph")
        cg.graph <- igraph::make_empty_graph()
      }

    }else{# one single graph per version -> no other preprocessing necessary

    ## read graph (.dot format)
    dd.adjacency <- sna::read.dot(paste0(DATA.PATH, "/dataDependency/", i , ".dot"))
    cg.adjacency <- sna::read.dot(paste0(DATA.PATH, "/callGraph/", i , ".dot"))
    dd.graph <- graph_from_adjacency_matrix(dd.adjacency, mode = "directed")
    cg.graph <- graph_from_adjacency_matrix(cg.adjacency, mode = "directed")
    }

    ## calculate metrics for call graph and data dependency graph data
    for(type in c("CG", "DD")){

      ## retrieve suitable graph
      if(type == "CG"){
        graph = cg.graph
      }else{
        graph = dd.graph
      }

      if(vcount(graph) == 0){
        next
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
      results[i, paste(type, "GR", sep = "_")] <- radius(graph)

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

      faults <- real.faults[id == paste(PROJECT, i, sep="_") & !is.na(faulty.method), faulty.method]
      if (length(faults) > 0){
        faulty.vertices <- sapply(faults, function(fault){
          if(grepl("#", fault, fixed=T)){# real faulty method location
            return(grep(fault, V(graph)$name, fixed = T))
          }else{
            print("no faulty method provided")
          }
        })
      }

      ## Here, we already have the real faulty nodes -> possibility to perform additional analyses based
      ## on this specific node
    }
  }

  ## Write results in csv format (for the specific project)
  results <- round(results, digits = 2)
  results[, id:= paste0(PROJECT, "_", id)]
  write.csv(results, file = paste(DATA.PATH, "dynamic_metrics.csv", sep = "/"))
}
