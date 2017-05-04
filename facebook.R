# clean-up
rm(list = ls())

# load required libraries
library(deSolve)

# load data
dd <- read.csv("multiTimeline.csv", as.is = T, skip = 1)
names(dd) <- c("Date", "Facebook")
dd$Date <- as.Date(paste0(dd$Date, "-01"), format = "%Y-%m-%d")

# normalize the jump away
dd$Facebook[dd$Date >= as.Date("2012-10-01")] <- 0.804 * dd$Facebook[dd$Date >= as.Date("2012-10-01")]
dd$Facebook <- 100 * dd$Facebook / max(dd$Facebook, na.rm = T)

# Cannarella et al. prediction (arXiv:1401.4208v1)
# Infectious recovery SIR model
irSIR <- function(t, state, parameters) {
  with(as.list(c(state, parameters)), {
    dS <- -beta * I * S / N
    dI <-  beta * I * S / N - nu * I * R / N
    dR <-  nu * I * R / N
    list(c(dS, dI, dR))
  })
}

# best fit scenario
parameters <- c(beta = 3.36e-02, nu = 4.98e-02, N = 100)
state      <- c(S = 1, I = 6.43e-05, R = 2.35e-06) * parameters["N"]
times      <- seq(0, 1000, by = 1)
out <- ode(y = state, times = times, func = irSIR, parms = parameters)
sim_best <- data.frame(Date = as.Date("2004-01-01") + out[, 1]*7, Prediction = out[, 3])
# early scenario
parameters <- c(beta = 3.43e-02, nu = 8.23e-02, N = 100*93.61/94.5)
state      <- c(S = 1, I = 5.47e-05, R = 1.04e-09) * parameters["N"]
times      <- seq(0, 1000, by = 1)
out <- ode(y = state, times = times, func = irSIR, parms = parameters)
sim_early <- data.frame(Date = as.Date("2004-01-01") + out[, 1]*7, Prediction = out[, 3])
# late scenario
parameters <- c(beta = 3.27e-02, nu = 2.71e-02, N = 100*97/94.5)
state      <- c(S = 1, I = 8.09e-05, R = 4.10e-04) * parameters["N"]
times      <- seq(0, 1000, by = 1)
out <- ode(y = state, times = times, func = irSIR, parms = parameters)
sim_late <- data.frame(Date = as.Date("2004-01-01") + out[, 1]*7, Prediction = out[, 3])

# compare data and prediction
plot(dd, type = "l", lwd = 2, ylab = "Normalized weekly search queries", main = "Facebook")
lines(sim_best$Date,  sim_best$Prediction,  col = "red", lwd = 2)
lines(sim_early$Date, sim_early$Prediction, col = "red", lwd = 2, lty = 2)
lines(sim_late$Date,  sim_late$Prediction,  col = "red", lwd = 2, lty = 2)


