Head <- function(x, n=10) {
    y <- x[1:n, 1:n]
    return(y)
}

Tail <- function(x, n=10) {
    y <- x[(nrow(x)-n+1):nrow(x), (ncol(x)-n+1):ncol(x)]
    return(y)
}

library(data.table)

## data <- fread("data/perturbseq/k562_both_filt.txt")

## data <- fread("data/perturbseq/dc_both_filt_fix_tp10k.txt")

## data.backup <- data

data <- data.backup

data <- data[, -1]

data <- as.matrix(data)

rownames(data) <- data.backup$GENE

## data <- data[, grep("dc0", colnames(data))]

## data <- data[, grep("dc3", colnames(data))]

## data <- data[, grep("p7d", colnames(data))]

## data <- data[, grep("cc7d", colnames(data))]

## c2g <- read.csv("data/perturbseq/GSE90063_RAW/GSM2396857_dc_0hr_cbc_gbc_dict.csv") # not sure wtd

## c2g <- read.csv("data/perturbseq/GSE90063_RAW/GSM2396856_dc_3hr_cbc_gbc_dict_lenient.csv") # use strict to get more "controls"

## c2g <- read.csv("data/perturbseq/GSE90063_RAW/GSM2396858_k562_tfs_7_cbc_gbc_dict.csv")

## c2g <- read.csv("data/perturbseq/GSE90063_RAW/GSM2396861_k562_ccycle_cbc_gbc_dict.csv")

cn <- character(ncol(data))

for (i in 1:length(c2g[[1]])) {
    
    cells <- unlist(strsplit(as.character(c2g[[2]][[i]]), ", "))
    
    cn[which(colnames(data) %in% cells)] <- paste(cn[which(colnames(data) %in% cells)],
                                                       gsub("^c_|^c_sg|^m_|_[0-9]$", "", as.character(c2g[[1]][[i]])), sep = "_")

}

colnames(data) <- gsub("^_|^_p_sg|^_p_", "", cn)

pertdist <- unlist(lapply(colnames(data), function(x) return(length(unlist(strsplit(x, "_"))))))

if (length(grep("_", colnames(data))) > 0) {
    data <- data[, -grep("_", colnames(data))]
}

getOmega <- function(data) {
    
    Sgenes <- unique(unlist(strsplit(colnames(data), "_")))
    
    Omega <- matrix(0, length(Sgenes), ncol(data))
    
    for (i in 1:length(Sgenes)) {
        Omega[i, grep(Sgenes[i], colnames(data))] <- 1
    }
    
    rownames(Omega) <- Sgenes
    colnames(Omega) <- colnames(data)

    return(Omega)
}

## save(data, file = "~/Mount/Grid/perturbseq_p7d_data.rda")

## ## do wildetype:

## wt <- fread("data/perturbseq/GSE90063_dc3hr_umi_wt.txt")

## rn <- wt[[1]]

## wt <- wt[, -1]

## wt <- as.matrix(wt)

## rownames(wt) <- gsub(".*_", "", rn)

## rownames(data) <- gsub(".*-", "", rownames(data))

## pathwaytype <- "mmu" # pathwaytype <- "hsa"

## genelength <- grcm38$end[which(grcm38$symbol %in% rownames(data))] - grcm38$start[which(grcm38$symbol %in% rownames(data))] + 1

## names(genelength) <- grcm38$symbol[which(grcm38$symbol %in% rownames(data))]

## ##

load("~/Mount/Grid/perturbseq_p7d_data.rda")

pathwaytype <- "mmu" # pathwaytype <- "hsa"

## pathways from kegg:

source("mnem/R/mnems.r")
source("mnem/R/mnems_low.r")

library(nem)
library(graph)
library(cluster)
library(bnem)
library(snow)
library(snowfall)
library(epiNEM)

library(KEGG.db)
library(KEGGgraph)
library(Rgraphviz)
library(dplyr)
library(annotables)

genes <- toupper(sort(unique(colnames(data))))

ngenes <- length(genes)

ids <- numeric(ngenes)

count <- 0

genes2 <- character(ngenes)

for (i in 1:length(genes)) {
    if (pathwaytype %in% "hsa") {
        idx <- which(grch38$symbol %in% genes[i])
    } else {
        idx <- which(toupper(grcm38$symbol) %in% genes[i])
    }
    print(idx)
    if (length(idx) == 0) { next() }  
    if (length(idx) > 1) {
        idx <- idx[1]
    }
    if (pathwaytype %in% "hsa") {
        id <- grch38$entrez[idx]
    } else {
        id <- grcm38$entrez[idx]
    }
    ids[count+1] <- id
    genes2[count+1] <- genes[i]
    count <- count + 1
}

genes <- cbind(genes2, ids)

genes <- genes[-which(genes[, 1] %in% ""), ]

## pathways:

mypaths <- list()

for (i in genes[, 2]) {
    
    try(mypaths[[i]] <- mget(i, KEGGEXTID2PATHID))

}

pathways <- sort(unique(unlist(mypaths))) # as.list(KEGGEXTID2PATHID)

hsa <- unique(unlist(pathways))

hsa <- sort(hsa[grep(pathwaytype, hsa)])

kadj <- list()

kadjagg <- matrix(0, nrow(genes), nrow(genes))

rownames(kadjagg) <- colnames(kadjagg) <- sort(genes[, 2])

memory <- NULL

for (i in hsa) {
    
    tryres <- try(retrieveKGML(pathwayid=gsub(pathwaytype, "", i), organism=pathwaytype, destfile="temp.xml", method="internal", quiet=TRUE), silent = TRUE)
    
    if (length(grep("Error", tryres)) == 0) {
        
        keggpw <- parseKGML("temp.xml")
        
        kgraph <- KEGGpathway2Graph(keggpw)
        
        kadjtmp <- graph2adj(kgraph)

        kadjtmp <- kadjtmp[order(rownames(kadjtmp)), order(colnames(kadjtmp))]
        
        rownames(kadjtmp) <- colnames(kadjtmp) <- gsub(paste0(pathwaytype, ":"), "", colnames(kadjtmp))

        print(dim(kadjtmp))

        if (sum(rownames(kadjtmp) %in% genes[, 2]) <= 1) { next() }

        if (any(kadjtmp != 0)) {
            con <- which(apply(kadjtmp, 1, sum) > 0 | apply(kadjtmp, 2, sum) > 0)
            kadjtmp2 <- kadjtmp[con, con]
            kadjtmp2 <- transitive.closure(kadjtmp2, mat = TRUE)
            kadjtmp[con, con] <- kadjtmp2
        }
        
        diag(kadjtmp) <- 0

        kadjtmp <- kadjtmp[which(rownames(kadjtmp) %in% genes[, 2]), which(colnames(kadjtmp) %in% genes[, 2]), drop = FALSE]

        kadjtmp <- transitive.reduction(kadjtmp)

        ## if(all(kadjtmp == 0)) { next() }

        if (!is.null(dim(kadjtmp))) {

            kadjtmp <- kadjtmp[order(rownames(kadjtmp)), order(colnames(kadjtmp)), drop = FALSE]

            kadjname <- paste(sort(rownames(kadjtmp)), collapse = "_")

            if (kadjname %in% memory) {

                posdouble <- which(memory %in% kadjname)

                for (j in posdouble) {
                
                    if (all(kadj[[j]] - kadjtmp) == 0) { donext <- TRUE; break(); }

                }

                if (donext) { next() }

            }
            
            memory <- c(memory, kadjname)
            
            kadj[[i]] <- kadjtmp # transitive.closure(kadjtmp, mat = TRUE)

            kadjagg[which(rownames(kadjagg) %in% rownames(kadjtmp)),
                    which(colnames(kadjagg) %in% colnames(kadjtmp))] <- kadjagg[which(rownames(kadjagg) %in% rownames(kadjtmp)),which(colnames(kadjagg) %in% colnames(kadjtmp))] + kadjtmp
            
            plot.adj(kadjtmp)

        }
    }
}

for (i in 1:length(kadj)) {

    print(dim(kadj[[i]]))
    
}

for (i in 1:nrow(genes)) {
    colnames(kadjagg) <- gsub(paste("^", genes[i, 2], "$", sep = ""), genes[i, 1], colnames(kadjagg))
    rownames(kadjagg) <- gsub(paste("^", genes[i, 2], "$", sep = ""), genes[i, 1], rownames(kadjagg))
}

con <- which(apply(kadjagg, 1, sum) > 0 | apply(kadjagg, 2, sum) > 0)

kadjagg <- kadjagg[con, con, drop = FALSE]

## save(kadj, kadjagg, genes, file = "~/Mount/Grid/perturbseq_d3_kegg.rda")

## analyse grid mnem results:

setwd("~/Mount/Grid/")

dataset <- "p7d"

load(paste0("~/Mount/Grid/perturbseq_", dataset, "_mnem.rda"))

for (i in 1:length(allres)) {

    tmp <- Inf
    tmp2 <- 1

    for (j in 1:(length(allres[[i]])-1)) {
        
        pdf(paste0("perturbseq/", dataset, "/", i, "_", j, ".pdf"), width = 15, height = 15)
        
        plot(allres[[i]][[j]])

        dev.off()

        if (allres[[i]][[j]]$best$ll <= tmp | j == 2) {
            tmp2 <- j
            tmp <- allres[[i]][[j]]$best$ll
        }

    }
    
    print(paste0("kegg ", i))
    print(tmp2)
    print(tmp)

}

## paper:

i <- 16

pdf("temp.pdf", width = 10, height = 8)

plot(allres[[i]][[3]])

## mtext("A", side = 3, line = 2, outer = FALSE, cex = 2.5, adj = 0,
##       at = par("usr")[1] - (par("usr")[2]-par("usr")[1])*2.9)

## mtext("B", side = 3, line = 2, outer = FALSE, cex = 2.5, adj = 0,
##       at = par("usr")[1] - (par("usr")[2]-par("usr")[1])*(1.55))

## mtext("C", side = 3, line = 2, outer = FALSE, cex = 2.5, adj = 0,
##       at = par("usr")[1] - (par("usr")[2]-par("usr")[1])*(0.2))

dev.off()


