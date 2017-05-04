library(rstan)
rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())

library(ggplot2)
source("stanTools.R")



## read-in data
data <- read_rdump("neutropenia.data.R")

## initial estimated will be generated randomly for each chain
init <- function(){
  list(CL = exp(rnorm(1, log(10), 0.2)),
       Q = exp(rnorm(1, log(20), 0.2)),
       V1 = exp(rnorm(1, log(70), 0.2)),
       V2 = exp(rnorm(1, log(70), 0.2)),
       ka = exp(rnorm(1, log(1), 0.2)),
       sigma = runif(1, 0.5, 2),
       alpha = exp(rnorm(1, log(2E-3), 0.2)),
       mtt = exp(rnorm(1, log(125), 0.2)),
       circ0 = exp(rnorm(1, 5, 0.2)),
       gamma = exp(rnorm(1, 0.17, 0.2)),
       sigmaNeut = runif(1, 0.5, 2))
}

## Specify the variables for which you want history plots
parametersToPlot <- c("CL", "Q", "V1", "V2", "ka",
                      "sigma",
                      "alpha", "mtt", "circ0", "gamma",
                      "sigmaNeut")

## Additional variables to monitor
otherRVs <- c("cPred", "neutPred")

parameters <- c(parametersToPlot, otherRVs)
parametersToPlot <- c("lp__", parametersToPlot)

nChains <- 4
nPost <- 250 ## Number of post-warm-up samples per chain after thinning
nBurn <- 250 ## Number of warm-up samples per chain after thinning
nThin <- 1

nIter <- (nPost + nBurn) * nThin
nBurnin <- nBurn * nThin

RNGkind("L'Ecuyer-CMRG")
# mc.reset.stream()

fitNeut <- stan(file = "neutropenia.stan",
                data = data,
                pars = parameters,
                iter = nIter,
                warmup = nBurnin,
                thin = nThin,
                init = init,
                chains = nChains,
                cores = min(nChains, parallel::detectCores()),
                refresh = 10,
                control = list(adapt_delta = 0.95, stepsize = 0.01),
                verbose = T)
save(fitNeut, file = "neutropeniaFit.Rsave")
#load(file = "neutropeniaFit.Rsave")

stan_trace(fitNeut, parametersToPlot)
mcmcDensity(fitNeut, parametersToPlot, byChain = TRUE)
pairs(fitNeut, pars = parametersToPlot)
print(fitNeut, pars = parametersToPlot)

## Format data for GGplot
cObs <- rep(NA, 89)
cObs[data$iObsPK] <- data$cObs
neut <- rep(NA, 89)
neut[data$iObsPD] <- data$neutObs
xdataNeut <- data.frame(cObs, neut, data$time)
xdataNeut <- plyr::rename(xdataNeut, c("data.time"  = "time"))

## Plot posterior predictive distributions of plasma concentrations
pred <- as.data.frame(fitNeut, pars = "cPred") %>%
  gather(factor_key = TRUE) %>%
  group_by(key) %>%
  summarize(lb = quantile(value, probs = 0.05),
            median = quantile(value, probs = 0.5),
            ub = quantile(value, probs = 0.95)) %>%
  bind_cols(xdataNeut)

p1 <- ggplot(pred, aes(x = time, y = cObs))
p1 <- p1 + geom_point() +
  labs(x = "time (h)", y = "plasma concentration (mg/L)") +
  theme(text = element_text(size = 12), axis.text = element_text(size = 12),
        legend.position = "none", strip.text = element_text(size = 8))
p1 + geom_line(aes(x = time, y = median)) +
  geom_ribbon(aes(ymin = lb, ymax = ub), alpha = 0.25)
print(p1)


## Plot posterior predictive distributions of neutrophil count
pred <- as.data.frame(fitNeut, pars = "neutPred") %>%
  gather(factor_key = TRUE) %>%
  group_by(key) %>%
  summarize(lb = quantile(value, probs = 0.05),
            median = quantile(value, probs = 0.5),
            ub = quantile(value, probs = 0.95)) %>%
  bind_cols(xdataNeut)

p1 <- ggplot(pred, aes(x = time, y = neut))
p1 <- p1 + geom_point() +
  labs(x = "time (h)", y = "Absolute Neutrophil Count") +
  theme(text = element_text(size = 12), axis.text = element_text(size = 12),
        legend.position = "none", strip.text = element_text(size = 8))
p1 + geom_line(aes(x = time, y = median)) +
  geom_ribbon(aes(ymin = lb, ymax = ub), alpha = 0.25)