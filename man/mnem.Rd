% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mnems.r
\name{mnem}
\alias{mnem}
\title{Mixture NEMs - main function.}
\usage{
mnem(
  D,
  inference = "em",
  search = "greedy",
  phi = NULL,
  theta = NULL,
  mw = NULL,
  method = "llr",
  marginal = FALSE,
  parallel = NULL,
  reduce = FALSE,
  runs = 1,
  starts = 3,
  type = "networks",
  complete = FALSE,
  p = NULL,
  k = NULL,
  kmax = 10,
  verbose = FALSE,
  max_iter = 100,
  parallel2 = NULL,
  converged = -Inf,
  redSpace = NULL,
  affinity = 0,
  evolution = FALSE,
  lambda = 1,
  subtopoX = NULL,
  ratio = TRUE,
  logtype = 2,
  domean = TRUE,
  modulesize = 5,
  compress = FALSE,
  increase = TRUE,
  fpfn = c(0.1, 0.1),
  Rho = NULL,
  ksel = c("kmeans", "silhouette", "cor"),
  nullcomp = FALSE,
  tree = FALSE,
  burnin = 10,
  hastings = TRUE,
  nodeswitch = TRUE,
  postgaps = 10,
  penalized = FALSE,
  accept_range = 1,
  ...
)
}
\arguments{
\item{D}{data with cells indexing the columns and features (E-genes)
indexing the rows}

\item{inference}{inference method "em" for expectation maximization or "mcmc" for markov chain monte carlo sampling}

\item{search}{search method for single network inference "greedy",
"exhaustive" or "modules" (also possible: "small", which is greedy with
only one edge change per M-step to make for a smooth convergence)}

\item{phi}{a list of n lists of k networks for n starts of the EM and
k components}

\item{theta}{a list of n lists of k attachment vector for the E-genes
for n starts of the EM and k components}

\item{mw}{mixture weights; if NULL estimated or uniform}

\item{method}{"llr" for log ratios or foldchanges as input (see ratio)}

\item{marginal}{logical to compute the marginal likelihood (TRUE)}

\item{parallel}{number of threads for parallelization of the number of
em runs}

\item{reduce}{logical - reduce search space for exhaustive search to
unique networks}

\item{runs}{number of runs for greedy search}

\item{starts}{number of starts for the em or mcmc}

\item{type}{initialize with responsibilities either by "random",
"cluster" (each S-gene is clustered and the different S-gene clustered
differently combined for several starts),
"cluster2" (clustNEM is used to infer reasonable phis, which are then
used as a start for one EM run), "cluster3" (global clustering as a start),
or "networks" (initialize with random phis), inference='mcmc' only supports
'networks' and 'empty' for unconncected networks phi}

\item{complete}{if TRUE, optimizes the expected complete log likelihood
of the model, otherwise the log likelihood of the observed data}

\item{p}{initial probabilities as a k (components) times l (cells) matrix}

\item{k}{number of components}

\item{kmax}{maximum number of components when k=NULL is inferred}

\item{verbose}{verbose output}

\item{max_iter}{maximum iterations (moves for inference='mcmc'.
adjust parameter  burnin)}

\item{parallel2}{if parallel=NULL, number of threads for single component
optimization}

\item{converged}{absolute distance for convergence between new and old log
likelihood; if set to -Inf, the EM stops if neither the phis nor thetas were
changed in the most recent iteration}

\item{redSpace}{space for "exhaustive" search}

\item{affinity}{0 is default for soft clustering, 1 is for hard clustering}

\item{evolution}{logical. If TRUE components are penelized for being
different from each other.}

\item{lambda}{smoothness value for the prior put on the components, if
evolution set to TRUE}

\item{subtopoX}{hard prior on theta as a vector with entry i equal to j,
if E-gene i is attached to S-gene j}

\item{ratio}{logical, if true data is log ratios, if false foldchanges}

\item{logtype}{logarithm type of the data (e.g. 2 for log2 data or exp(1)
for natural)}

\item{domean}{average the data, when calculating a single NEM (speed
improvment)}

\item{modulesize}{max number of S-genes per module in module search}

\item{compress}{compress networks after search (warning: penelized
likelihood not interpretable)}

\item{increase}{if set to FALSE, the algorithm will not stop if the
likelihood decreases}

\item{fpfn}{numeric vector of length two with false positive and false
negative rates for discrete data}

\item{Rho}{perturbation matrix with dimensions nxl with n S-genes and
l samples; either as probabilities with the sum of probabilities for a
sample less or equal to 1 or discrete with 1s and 0s}

\item{ksel}{character vector of methods for the inference of k; can combine
as the first two vlues "hc" (hierarchical clustering) or "kmeans" with
"silhouette", "BIC" or "AIC"; the third value is either "cor" for
correlation distance or any method accepted by the function 'dist'}

\item{nullcomp}{if TRUE, adds a null component (k+1)}

\item{tree}{if TRUE, restrict inference on trees (MCMC not included)}

\item{burnin}{number of iterations to be discarded prior to
analyzing the posterior distribution of the mcmc}

\item{hastings}{if set to TRUE, the Hastings ratio is calculated}

\item{nodeswitch}{if set to TRUE, node switching is allowed as a
move, additional to the edge moves}

\item{postgaps}{can be set to numeric. Determines after how
many iterations the next Phi mixture is added to the Phi edge Frequency
tracker in the mcmc}

\item{penalized}{if set to TRUE, the penalized likelihood will be
used for the mcmc.
Per default this is FALSE, since no component learning is involved and
sparcity is hence not enforced}

\item{accept_range}{the random probability the acceptance probability
is compared to (default: 1)}

\item{...}{arguments to function nem}
}
\value{
object of class mnem
\item{comp}{list of the component with each component being
a list of the causal network phi and the E-gene attachment theta}
\item{data}{input data matrix}
\item{limits}{list of results for all indpendent searches}
\item{ll}{log likelihood of the best model}
\item{lls}{log likelihood ascent of the best model search}
\item{mw}{vector with mixture weights}
\item{probs}{kxl matrix containing the cell log likelihoods
of the model}
}
\description{
This function simultaneously learns a mixture
of causal networks and clusters of a cell population from single cell
perturbation data (e.g. log odds of fold change) with a multi-trait
readout. E.g. Pooled CRISPR scRNA-Seq data (Perturb-Seq. Dixit et al., 2016,
Crop-Seq. Datlinger et al., 2017).
}
\examples{
sim <- simData(Sgenes = 3, Egenes = 2, Nems = 2, mw = c(0.4,0.6))
data <- (sim$data - 0.5)/0.5
data <- data + rnorm(length(data), 0, 1)
result <- mnem(data, k = 2, starts = 1)
}
\author{
Martin Pirkl
}
