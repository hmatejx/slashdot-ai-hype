functions {
  real[] irSIR_ODE(real t, real[] x, real[] parms, real[] x_r, int[] x_i) {
    real dxdt[3];

    dxdt[1] = -parms[1] * x[2] * x[2] * x[1] / parms[3];
    dxdt[2] =  parms[1] * x[2] * x[2] * x[1] / parms[3] - parms[2] * x[2] * x[3] * x[3] / parms[3];
    dxdt[3] =                                      parms[2] * x[2] * x[3] * x[3] / parms[3];
    
    return dxdt;
  }
  
  real[] irSIR(real[] t, real[] init, real[] parms, real[] x_r, int[] x_i) {
    real y_hat[size(t), 3];
 
    y_hat = integrate_ode_rk45(irSIR_ODE, init, 0, t, parms, x_r, x_i);
    
    return y_hat[, 2];
  }
}

data {
  int<lower=0> T;
  real<lower=0> Time[T];
  real<lower=0> Y[T];
}

transformed data {
  real x_r[0];
  int x_i[0];
  real Time_pred[2*T];
  
  for (t in 1:(2*T)) {
    Time_pred[t] = t * Time[T] / T;
  }
}

parameters {
  real log_beta;
  real log_nu;
  real<lower=0> N;
  simplex[3] x;
  real<lower=0> sigma;
}

transformed parameters {
  real beta;
  real nu;
  real S0;
  real I0;
  real R0;
  
  beta = exp(log_beta);
  nu = exp(log_nu);
  S0 = N * x[1];
  I0 = N * x[2];
  R0 = N * x[3];
}

model {
  real y[T];

  // priors
  log_beta ~ normal(0, 1);
  log_nu ~ normal(0, 1);
  N ~ normal(100, 10);
  x ~ dirichlet([20, 1, 1]');
  sigma ~ cauchy(0, 1);

  // model
  y = irSIR(Time, {S0, I0, R0}, {beta, nu, N}, x_r, x_i);

  // likelihood
  for (t in 1:T) {
    log(Y[t]) ~ normal(log(y[t]) - sigma*sigma/2, sigma);
  }
}

generated quantities {
  real Y_pred[2*T];
 
  Y_pred = irSIR(Time_pred, {S0, I0, R0}, {beta, nu, N}, x_r, x_i);
  
  for (t in 1:(2*T)) {
    Y_pred[t] = exp(normal_rng(log(Y_pred[t] + 0.0001) - sigma*sigma/2, sigma));
  }
}
