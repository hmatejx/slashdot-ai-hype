# clean-up
rm(list = ls())

# load required libraries
library(rstan)
rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())

# load data
dd <- read.csv("irSIR_examples/Facebook.csv", as.is = T, header = F, skip = 3)
names(dd) <- c("Date", "Facebook")
dd$Date <- as.Date(paste0(dd$Date, "-01"), format = "%Y-%m-%d")

# normalize the jump away
dd$Facebook[dd$Date >= as.Date("2012-10-01")] <- 0.804 * dd$Facebook[dd$Date >= as.Date("2012-10-01")]
dd$Facebook <- 100 * dd$Facebook / max(dd$Facebook, na.rm = T)

idx <- which(dd$Facebook > 0)
data <- list(T = length(idx),
             Time = seq(1, length(idx)),
             Y = dd$Facebook[idx])


iter <- 200
warmup <- 100
nChains <- 1

fit <- stan(file = "facebook.stan",
            data = data,
            iter = iter,
            warmup = warmup,
            chains = nChains,
            cores = min(nChains, parallel::detectCores()),
            verbose = T)
