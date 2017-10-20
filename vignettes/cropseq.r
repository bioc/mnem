
data.bulk <- read.csv("data/cropseq/GSE92872_CROP-seq_Jurkat_TCR.count_matrix.csv", stringsAsFactors = FALSE)

data <- read.csv("data/cropseq/GSE92872_CROP-seq_Jurkat_TCR.digital_expression.csv", stringsAsFactors = FALSE)

counts <- data[, grep("condition|^stim", colnames(data))]

counts <- counts[-(1:5), -1]

counts <- matrix(as.numeric(as.character(unlist(counts))), nrow(counts))

rownames(counts) <- data[6:nrow(data), 1]

colnames(counts) <- data[4, grep("^stim", colnames(data))]

colnames(counts)[which(colnames(counts) %in% "CTRL")] <- ""

## save(data, file = "~/Mount/Grid/cropseq_data.rda")

load("~/Mount/Grid/cropseq_data.rda")

data <- data[, -grep("DHODH|MVD|TUBB", colnames(data))]

## map to pathways:

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

    idx <- which(grch38$symbol %in% genes[i])

    print(idx)

    if (length(idx) == 0) { next() }  

    if (length(idx) > 1) {

        idx <- idx[1]

    }

    id <- grch38$entrez[idx]

    print(id)

    ids[count+1] <- id

    genes2[count+1] <- genes[i]

    count <- count + 1

    print(count)

    if (count == ngenes) { break() }

}

genes <- cbind(genes2, ids)

##

mypaths <- list()

for (i in genes[, 2]) {
    
    try(mypaths[[i]] <- mget(i, KEGGEXTID2PATHID))

}

pathways <- sort(unique(unlist(mypaths))) # as.list(KEGGEXTID2PATHID)

hsa <- unique(unlist(pathways))

hsa <- sort(hsa[grep("hsa", hsa)])

kadj <- list()

kadjagg <- matrix(0, nrow(genes), nrow(genes))

rownames(kadjagg) <- colnames(kadjagg) <- sort(genes[, 2])

memory <- NULL

for (i in hsa) {
    
    tryres <- try(retrieveKGML(pathwayid=gsub("hsa", "", i), organism="hsa", destfile="temp.xml", method="internal", quiet=TRUE), silent = TRUE)
    
    if (length(grep("Error", tryres)) == 0) {
        
        keggpw <- parseKGML("temp.xml")
        
        kgraph <- KEGGpathway2Graph(keggpw)
        
        kadjtmp <- graph2adj(kgraph)

        kadjtmp <- kadjtmp[order(rownames(kadjtmp)), order(colnames(kadjtmp))]
        
        rownames(kadjtmp) <- colnames(kadjtmp) <- gsub("hsa:", "", colnames(kadjtmp))

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

kadjagg <- kadjagg[con, con]

## save(kadj, kadjagg, genes, file = "~/Mount/Grid/cropseq_kegg.rda")

## analyse mnem grid results:

setwd("~/Mount/Grid/")

load("~/Mount/Grid/cropseq_kegg.rda")

load("~/Mount/Grid/cropseq_mnem.rda")

bicmat <- matrix(0, length(allres), 5)

for (i in 1:length(allres)) {

    tmp <- Inf
    tmp2 <- 1

    if (i != length(allres)) {
        tmpadj <- kadj[[i]]
    }
    
    for (k in 1:nrow(genes)) {
        colnames(tmpadj) <- gsub(paste("^", genes[k, 2], "$", sep = ""), genes[k, 1], colnames(tmpadj))
        rownames(tmpadj) <- gsub(paste("^", genes[k, 2], "$", sep = ""), genes[k, 1], rownames(tmpadj))
    }

    for (j in 1:(length(allres[[i]])-1)) {
        
        pdf(paste0("cropseq/", i, "_", j, ".pdf"), width = 15, height = 15)

        par(mfrow=c(1,2))
        
        plot(allres[[i]][[j]])

        if (i != length(allres)) {
            plot.adj(tmpadj)
        }
        
        dev.off()

        if (allres[[i]][[j]]$best$ll <= tmp | j == 2) {
            tmp2 <- j
            tmp <- allres[[i]][[j]]$best$ll
        }

    }

    bicmat[i, ] <- allres[[i]]$bics
    
    print(paste0("kegg ", i))
    print(tmp2)
    print(tmp)
    print(allres[[i]]$bics)

}

## paper:

i <- 20

pdf("temp.pdf", width = 10, height = 8)

plot(allres[[i]][[2]])

mtext("A", side = 3, line = 3, outer = FALSE, cex = 2.5, adj = 0,
      at = par("usr")[1] - (par("usr")[2]-par("usr")[1])*1.6)

mtext("B", side = 3, line = 3, outer = FALSE, cex = 2.5, adj = 0,
      at = par("usr")[1] - (par("usr")[2]-par("usr")[1])*(0.2))

dev.off()


