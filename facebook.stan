functions {
  real[] irSIR_ODE(real t, real[] x, real[] parms, real[] x_r, int[] x_i) {
    real dxdt[3];
    real beta;
    real nu;
    real N;
    
    beta = parms[1];
    nu = parms[2];
    N = parms[3];

    dxdt[1] = -beta * x[2] * x[1] / N;
    dxdt[2] =  beta * x[2] * x[1] / N - nu* x[2] * x[3] / N;
    dxdt[3]   =  nu * x[2] * x[3] / N;
    
    return dxdt;
  }
}

data {
  int<lower = 0> T;
  real Time[T];
  real<lower=0> Y[T];
}

transformed data {
  real x_r[0];
  int x_i[0];
}

parameters {
  real<lower=0> log_beta;
  real<lower=0> log_mu;
  real<lower=0> N;
  real<lower=0> log_I0;
  real<lower=0> log_R0;
  real<lower=0> sigma;
}

transformed parameters {
  real beta;
  real mu;
  real I0;
  real R0;
  beta = exp(log_beta);
  mu = exp(log_mu);
  I0 = exp(log_I0);
  R0 = exp(log_R0);
}

model {
  real parms[3];
  real init[3];
  real y_hat[T, 3];

  # priors
  log_beta ~ normal(0, 1);
  log_mu ~ normal(0, 1);
  log_I0 ~ normal(0, 1);
  log_R0 ~ normal(0, 1);
  N ~ normal(100, 10);
  sigma ~ cauchy(0, 1);
  
  # parameters
  parms[1] = beta;
  parms[2] = mu;
  parms[3] = N;

  init[1] = N;
  init[2] = N*I0;
  init[3] = N*R0;
  # model
  y_hat = integrate_ode_rk45(irSIR_ODE, init, 0, Time, parms, x_r, x_i);
  
  # likelihood
  for (t in 1:T) {
    Y[t] ~ normal(y_hat[t, 2], sigma);
  }
}
