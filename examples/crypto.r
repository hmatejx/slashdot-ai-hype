# clean-up
rm(list = ls())

# load required libraries
library(rstan)
rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())
#library(shinystan)
library(gtrendsR)

# load data
dd <- gtrends("Cryptocurrency", time = "2017-01-01 2018-01-13")$interest_over_time[, 1:2]
names(dd) <- c("Date", "Popularity")
dd$Date <- as.Date(dd$Date)
dd <- dd[dd$Popularity > 0, ]

# prepare list to serve as data for STAN
fit_data <- list(T = nrow(dd),
                 Time = as.numeric(dd$Date - dd$Date[1] + dd$Date[2] - dd$Date[1])/30,
                 Y = dd$Popularity)
Y_meas = fit_data$Y

# MCMC parameters
iter <- 800*16
warmup <- 400
nChains <- 4

# fit data with STAN
fit <- stan(file = "../model/crypto.stan",
            data = fit_data,
            iter = iter,
            init = rep(list(list(sigma = 1.5, 
                                 log_beta = log(0.032), 
                                 log_nu = log(0.7),
                                 N = 104, 
                                 x = c(0.965, 0.03, 0.005))), nChains),
            warmup = warmup,
            chains = nChains,
            cores = min(nChains, parallel::detectCores()),
            verbose = T)

# print results
print(fit, pars = c("sigma", "beta", "nu", "N", "S0", "I0", "R0"), digits_summary = 3)

# explore the fit in Shiny
#sso <- as.shinystan(fit)
#launch_shinystan(sso)

# posterior predictive check
Y_pred <- t(apply(extract(fit, "Y_pred", permuted = F), 3, quantile, prob = c(0.025, 0.5, 0.975)))
N_pred <- nrow(Y_pred)
Time_pred <- dd$Date[1] + (1:N_pred)*(dd$Date[2] - dd$Date[1])
plot(Time_pred, rep(NA, 2*nrow(dd)), ylim = c(0, max(Y_pred)),
     xlab = "Date", ylab = "Normalized popularity", 
     main = "Cryptocurrency popularity modeled by irSIR")
polygon(c(Time_pred, rev(Time_pred)), c(Y_pred[, 1], rev(Y_pred[, 3])),
        col = "gray", border = NA)
lines(Time_pred, Y_pred[, 2], lwd = 3)
points(dd$Date, Y_meas, pch = 21, bg = rgb(1, 1, 1, 0.6), cex = 1.2)
peaks <- Time_pred[c(which(Y_pred[, 1] == max(Y_pred[, 1])),
                     which(Y_pred[, 2] == max(Y_pred[, 2])),
                     which(Y_pred[, 3] == max(Y_pred[, 3])))]
points(peaks, apply(Y_pred, 2, max), pch = "*", cex = 3, col = "darkred")
text(peaks[2], max(Y_pred[, 2]), peaks[2], pos = 3)
legend("topleft", bty = "n", 
       legend = c("Google Trends (train)",
                  "Curve of best fit",
                  "95% prediction interval",
                  "",
                  paste0("Possible peak between"),
                  paste0(peaks[1], " - ", peaks[3])),
       lty = c(NA, 1, NA, NA, NA, NA),
       lwd = c(NA, 3, NA, NA, NA, NA),
       pch = c(21, NA, 15, NA, 42, NA),
       col = c("black", "black", "gray", NA, "darkred", NA), 
       pt.cex = c(1.2, NA, 2, NA, 3, NA),
       pt.bg = c("white", NA, NA, NA, NA, NA))
