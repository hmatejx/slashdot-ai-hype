# clean-up
rm(list = ls())

# load required libraries
library(rstan)
rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())
#library(shinystan)

# load data
dd <- read.csv("Facebook.csv", as.is = T, header = F, skip = 3)
names(dd) <- c("Date", "Popularity")
dd$Date <- as.Date(paste0(dd$Date, "-01"), format = "%Y-%m-%d")

# normalize the jump at october 2012 away
dd$Popularity[dd$Date >= as.Date("2012-10-01")] <- 0.804 * dd$Popularity[dd$Date >= as.Date("2012-10-01")]
dd$Popularity <- 100 * dd$Popularity / max(dd$Popularity, na.rm = T)

# split into training and validation set
cutoff_date <- "2017-05-05"
dd.new <- dd[dd$Date > as.Date(cutoff_date), ]
dd <- dd[dd$Date <= as.Date(cutoff_date), ]

# prepare list to serve as data for STAN
idx <- which(dd$Popularity > 0)
fit_data <- list(Th = length(idx),
                 Tn = 200,
                 Time = as.numeric(dd$Date[idx] - dd$Date[idx[1] - 1])/30,
                 Y = dd$Popularity[idx])
Y_meas = fit_data$Y

# MCMC parameters
iter <- 1600
warmup <- 400
nChains <- 4

# fit data with STAN
fit <- stan(file = "../model/irSIR.stan",
            data = fit_data,
            iter = iter,
            init = rep(list(list(sigma = 0.35, log_beta = -2, log_nu = -3, N = 120, x = c(0.94, 0.01, 0.05))), nChains),
            warmup = warmup,
            chains = nChains,
            cores = min(nChains, parallel::detectCores()),
            verbose = T)

# print results
print(fit, pars = c("sigma", "beta", "nu", "N", "S0", "I0", "R0"), digits_summary = 3)

# explore the fit in Shiny
# sso <- as.shinystan(fit)
# launch_shinystan(sso)

# posterior predictive check
Y_pred <- t(apply(extract(fit, "Y_pred", permuted = F), 3, quantile, prob = c(0.025, 0.5, 0.975)))
N_pred <- nrow(Y_pred)
Time_pred <- dd$Date[idx[1] - 1] + (1:N_pred)*30
plot(Time_pred, rep(NA, fit_data$Th + fit_data$Tn),
     ylim = c(0, max(Y_pred)), xlim = c(Time_pred[1], as.Date("2026-01-01")),
     xlab = "Date", ylab = "Normalized popularity",
     main = "Facebook popularity modeled by irSIR")
polygon(c(Time_pred, rev(Time_pred)), c(Y_pred[, 1], rev(Y_pred[, 3])),
        col = "gray", border = NA)
lines(Time_pred, Y_pred[, 2], lwd = 3)
points(dd$Date[idx], Y_meas, pch = 21, bg = rgb(1, 1, 1, 0.6), cex = 1.2)
points(dd.new$Date, dd.new$Popularity, pch = 21, bg = rgb(1, 0, 0, 0.6), cex = 1.2)
abline(v = as.Date(cutoff_date), lty = 2)
abline(v = as.Date("2021-10-01"), col = "steelblue4")
legend("topright", #bty = "n",
       legend = c("Google Trends (train)",
                  "Google Trends (val.)",
                  "Curve of best fit",
                  "95% prediction interval"),
       lty = c(NA, NA, 1, NA), lwd = c(NA, NA, 3, NA), pch = c(21, 21, NA, 15),
       col = c("black", "black", "black", "gray"), pt.cex = c(1.2, 1.2, NA, 2),
       pt.bg = c("white", "red", NA, NA))
text(as.Date("2021-10-01"), 30, "Meta rebrand", adj = -0.1, col = "steelblue4")
