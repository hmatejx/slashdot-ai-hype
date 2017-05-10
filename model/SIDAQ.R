# clean-up
rm(list = ls())

# load required libraries
library(deSolve)


SIDAQ <- function(t, state, parameters) {
  with(as.list(c(state, parameters)), {
    dS <- -beta/N*I*S
    dI <-  beta/N*I*S - nu/N*I*D - mu_I/N*I*A - eta_I/N*I*Q
    dD <-               nu/N*I*D - mu_D/N*D*A - eta_D/N*D*Q
    dA <-  mu_I/N*I*A + mu_D/N*D*A
    dQ <-                          eta_I/N*I*Q + eta_D/N*D*Q
    list(c(dS, dI, dD, dA, dQ))
  })
}

# example scenario
parameters <- c(N = 100,
                beta = 3.36e-02, nu = 4.98e-02,
                mu_I = 2.3e-02, mu_D = 2.2e-02,
                eta_I = 1.8e-02, eta_D = 2.7e-02
                )
state      <- c(S = 1, I = 6.43e-05, D = 2.35e-06, A = 1e-05, Q = 1e-05) * parameters["N"]
times      <- seq(0, 1000, by = 1)
out <- ode(y = state, times = times, func = SIDAQ, parms = parameters)
out <- as.data.frame(out)

# plot scenario
plot(NA, NA, xlim = c(0, 1000), ylim = c(0, 100), xlab = "time", ylab = "% population")
lines(out$time,  out$S, col = "grey", lwd = 1)
lines(out$time, out$I, col = "green", lwd = 1)
lines(out$time, out$D, col = "red", lwd = 1)
lines(out$time, out$A, col = "blue", lwd = 1)
lines(out$time, out$Q, col = "magenta", lwd = 1)
lines(out$time, out$I + out$A, lwd = 4)
legend("topright", bty = "n",
       legend = c("Susceptible", "Infected", "Disilusioned", "Adopters", "Quitters", "Active users"),
       lty = 1, lwd = c(2, 2, 2, 2, 2, 5),
       col = c("grey", "green","red", "blue", "magenta", "black"),
       cex = 0.8)
title(main = "SIDAQ model of the hype cycle")
