# clean-up
rm(list = ls())

# load required libraries
library(rstan)
rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())
library(shinystan)

# load data
dd <- read.csv("LinkedIn.csv", as.is = T, header = F, skip = 3)
names(dd) <- c("Date", "Popularity")
dd$Date <- as.Date(paste0(dd$Date, "-01"), format = "%Y-%m-%d")

# prepare list to serve as data for STAN
idx <- which(dd$Popularity > 0)
fit_data <- list(T = length(idx),
                 Time = as.numeric(dd$Date[idx] - dd$Date[idx[1] - 1])/30,
                 Y = dd$Popularity[idx])
Y_meas = fit_data$Y

# MCMC parameters
iter <- 800
warmup <- 400
nChains <- 4

# fit data with STAN
fit <- stan(file = "../model/irSIR.stan",
            data = fit_data,
            iter = iter,
            init = rep(list(list(sigma = 0.6, log_beta = -2.6, log_nu = -3, N = 100, x = c(0.98, 0.005, 0.015))), nChains),
            warmup = warmup,
            chains = nChains,
            cores = min(nChains, parallel::detectCores()),
            verbose = T)

# print results
print(fit, pars = c("sigma", "beta", "nu", "N", "S0", "I0", "R0"))

# explore the fit in Shiny
# sso <- as.shinystan(fit)
# launch_shinystan(sso)

# posterior predictive check
Y_pred <- t(apply(extract(fit, "Y_pred", permuted = F), 3, quantile, prob = c(0.025, 0.5, 0.975)))
N_pred <- nrow(Y_pred)
Time_pred <- dd$Date[idx[1] - 1] + (1:N_pred)*30
plot(Time_pred, rep(NA, 2*length(idx)), ylim = c(0, max(Y_pred)),
     xlab = "Date", ylab = "Normalized popularity", 
     main = "LinkedIn popularity modeled by irSIR")
polygon(c(Time_pred, rev(Time_pred)), c(Y_pred[, 1], rev(Y_pred[, 3])),
        col = "gray", border = NA)
lines(Time_pred, Y_pred[, 2], lwd = 3)
points(dd$Date[idx], Y_meas, pch = 21, bg = "white", cex = 1.2)
abline(v = as.Date("2017-05-05"), lty = 2)
legend("topright", bty = "n", 
       legend = c("Google Trends data",
                  "Line of best fit",
                  "95% prediction interval",
                  "Today"),
       lty = c(NA, 1, NA, 2), lwd = c(NA, 3, NA, 1), pch = c(21, NA, 15, NA),
       col = c("black", "black", "gray", "black"), pt.cex = c(1.2, NA, 2, NA))
