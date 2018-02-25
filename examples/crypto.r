# clean-up
rm(list = ls())

# load required libraries
library(rstan)
rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())
#library(shinystan)
library(gtrendsR)

# load data (stitch together multiple shorter time periods)
startDate <- "2017-01-01"
keyword <- "Cryptocurrency"
dd <- gtrends(keyword, time = paste(as.Date(startDate) + 0, as.Date(startDate) + 90))$interest_over_time[, 1:2]
dd$block <- 0
for (i in 1:4) {
  period <- paste(as.Date(startDate) + i*90, min(Sys.Date(), as.Date(startDate) + (i + 1)*90))
  cat("period =", period, "\n")
  dd <- rbind(dd, cbind(gtrends(keyword, time = period)$interest_over_time[, 1:2], block = i))
}
names(dd)[1:2] <- c("Date", "Popularity")
for (b in 1:4) {
  bc <- which(dd$block == b)
  bp <- which(dd$block == b - 1)
  dd[bc, 2] <- dd[bc, 2] * dd[bp[length(bp)], 2] / dd[bc[1], 2]
}
dd <- dd[-which(diff(dd$block) == 1), ]
dd$Popularity <- 100 * dd$Popularity / max(dd$Popularity)
dd$Date <- as.Date(dd$Date)
dd <- dd[dd$Popularity > 0, ]

dd <- dd[!(dd$Date < as.Date("2017-10-01")), ]

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
            init = rep(list(list(sigma = 0.2, 
                                 log_beta = log(0.086), 
                                 log_nu = log(0.022),
                                 N = 107, 
                                 x = c(0.75, 0.05, 0.2))), nChains),
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
plot(Time_pred, rep(NA, 2*nrow(dd)), ylim = c(0, max(Y_pred, Y_meas)),
     xlab = "Date", ylab = "Normalized popularity", 
     main = "Cryptocurrency popularity modeled by FOMO/FUD")
polygon(c(Time_pred, rev(Time_pred)), c(Y_pred[, 1], rev(Y_pred[, 3])),
        col = "gray", border = NA)
lines(Time_pred, Y_pred[, 2], lwd = 3)
points(dd$Date, Y_meas, pch = 21, bg = rgb(1, 1, 1, 0.6), cex = 1.2) 
lines(dd$Date, stats::filter(Y_meas, rep(1, 31)/31), col = "darkred", lwd = 2)
peaks <- Time_pred[c(which(Y_pred[, 1] == max(Y_pred[, 1])),
                     which(Y_pred[, 2] == max(Y_pred[, 2])),
                     which(Y_pred[, 3] == max(Y_pred[, 3])))]
legend("topleft", bty = "n", 
       legend = c("Google Trends (GT)",
                  "GT - 31 day MA",
                  "Curve of best fit",
                  "95% prediction interval"),
       lty = c(NA, 1, 1, NA),
       lwd = c(NA, 2, 3, NA),
       pch = c(21, NA, NA, 15),
       col = c("black", "darkred", "black", "gray"), 
       pt.cex = c(1.2, NA, NA, 2),
       pt.bg = c("white", NA, NA, NA))
