# slashdot-ai-hype

Short exploration of the rise (and fall) of hype-laden buzzwords announcing the impending domination of the worlds by sentient computers.

---

### Background

1. Explain about the irSIR model

<img src="img/irSIR_model.png" alt="irSIR equations]" width="196">

2. Name references, i.e.
    - http://arxiv.org/abs/1401.4208v1
    - http://arxiv.org/abs/1608.07870v1


### Approach

The approach is to fit the normalized popularity data using the irSIR model. The fit is performed in Bayesian  fashion. Namely, a generative model is specified that completely describes the data generation process: 

- temporal evolution of the sate using ODEs, and 
- subsequent addition of a Poisson-like noise.

As the absolute scale is not known, the noise is approximated by a normal distribution whose width is proportional to the square root of the normalized popularity score. This approach has shown to be able to adequately describe the observed variability. 

**The key principle is to include _all_ uncertainties into prediction.**

Coupled with weak uninformative priors we obtain the _posterior predictive distribution_ of the normalized popularity. The model can also be extrapolated into the future. 

The model is implemented in the [Stan](http://mc-stan.org/) probabilistic programming language, which uses the advanced NUTS MCMC sampling algorithm.

### Example fit of irSIR model

Fit of Google Trends data for the [Facebook](https://trends.google.com/trends/explore?date=all&amp;amp;q=Facebook) and [LinkedIn](https://trends.google.com/trends/explore?date=all&amp;amp;q=LinkedIn) search strings:



![Facebook fit](img/Facebook_irSIR_fit.png)

![LinkedIn fit](img/LinkedIn_irSIR_fit.png)

### Main results

To-Do...
