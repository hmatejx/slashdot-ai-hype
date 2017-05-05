# clean-up
rm(list = ls())

# load required libraries
library(rstan)
rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())
library(shinystan)

# load data
dd <- read.csv("irSIR_examples/Facebook.csv", as.is = T, header = F, skip = 3)
names(dd) <- c("Date", "Facebook")
dd$Date <- as.Date(paste0(dd$Date, "-01"), format = "%Y-%m-%d")

# normalize the jump at october 2012 away
dd$Facebook[dd$Date >= as.Date("2012-10-01")] <- 0.804 * dd$Facebook[dd$Date >= as.Date("2012-10-01")]
dd$Facebook <- 100 * dd$Facebook / max(dd$Facebook, na.rm = T)

# prepare list to serve as data for STAN
idx <- which(dd$Facebook > 0)
fit_data <- list(T = length(idx),
                 Time = seq(1, length(idx)),
                 Y = dd$Facebook[idx])
Y_meas = fit_data$Y

# MCMC parameters
iter <- 800
warmup <- 400
nChains <- 4

# fit data with STAN
fit <- stan(file = "irSIR.stan",
            data = fit_data,
            iter = iter,
            init = rep(list(list(sigma = 0.07, beta = 0.15, nu = 0.05, N = 120, x = c(0.94, 0.01, 0.05))), nChains),
            warmup = warmup,
            chains = nChains,
            cores = min(nChains, parallel::detectCores()),
            verbose = T)

# print results
print(fit, pars = c("sigma", "beta", "nu", "S0", "I0", "R0"))

# explore the fit in Shiny
# sso <- as.shinystan(fit)
# launch_shinystan(sso)

# posterior predictive check
Y_pred <- t(apply(extract(fit, "Y_pred", permuted = F), 3, quantile, prob = c(0.05, 0.5, 0.95)))
N_pred <- nrow(Y_pred)
x <- c(dd$Date[idx], dd$Date[idx[length(idx)]] + 1:length(idx)*30)
plot(x, rep(NA, 2*length(idx)), ylim = c(0, max(Y_pred)),
     xlab = "Date", ylab = "Normalized popularity", 
     main = "Facebook popularity modeled by irSIR")
polygon(c(x, rev(x)), c(Y_pred[, 1], rev(Y_pred[, 3])), col = "gray", border = NA)
lines(x, Y_pred[, 2], lwd = 3)
points(dd$Date[idx], Y_meas, pch = 21, bg = "white", cex = 1.2)
abline(v = as.Date("2017-05-05"), col = "darkgray")
legend("topright", bty = "n", legend = c("Line of best fit", "90% pred. int.", "Today"),
       lty = c(1, NA, 1), lwd = c(3, NA, 1), pch = c(NA, 15, NA),
       col = c("black", "gray", "darkgray"), pt.cex = c(NA, 2, NA))
