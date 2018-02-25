# slashdot-ai-hype

Short exploration of the rise (and fall) of hype-laden buzzwords announcing the impending domination of the world by sentient computers.

---

### Background

To-Do:

1. Explain the irSIR model

<img src="img/irSIR_model.png" alt="irSIR equations]" width="196">

2. Cite references, i.e.
    - http://arxiv.org/abs/1401.4208v1
    - http://arxiv.org/abs/1608.07870v1


### Approach

The approach to prediction is to fit the (normalized) popularity data using the irSIR model. The fit is performed in a Bayesian fashion. Namely, a generative model is specified that completely describes the data generation process: 

- temporal evolution of the sate using ODEs, and 
- subsequent addition of a Poisson-like noise.

As the absolute scale is not known, the noise is approximated by a normal distribution whose width is proportional to the square root of the normalized popularity score. This approach has been shown to adequately describe the observed variability. 

**The key principle is to try to include _all_ uncertainties into prediction.**

Coupled with weak uninformative priors we obtain the _posterior predictive distribution_ of the normalized popularity. The model can be extrapolated into the future. 

The model is implemented in the [Stan](http://mc-stan.org/) probabilistic programming language, which uses the advanced NUTS MCMC sampling algorithm.

Of course, it goes without saying that even a Bayesian approach cannot mitigate the consequences of fitting the wrong model ;-)

### Example fits of irSIR model

Fit of Google Trends data for the [Facebook](https://trends.google.com/trends/explore?q=Facebook) and [LinkedIn](https://trends.google.com/trends/explore?q=LinkedIn) search keywords.

The model is fitted to data up to 2017-05-01. The remaining data will be used for ongoing validation. I am genuinely curious to see how accurate the predictions will turn out to be.

![Facebook fit](img/Facebook_irSIR_fit.png)

![LinkedIn fit](img/LinkedIn_irSIR_fit.png)

### Related example (FOMO/FUD model)

Below is a slightly different model shown fitting to the Cryptocurrency search keyword. The model, which I call the [FOMO](https://en.wikipedia.org/wiki/Fear_of_missing_out)/[FUD](https://en.wikipedia.org/wiki/Fear,_uncertainty_and_doubt) model, builds upon the ideas of irSIR. 

The differential equations are similar to irSIR, but the SI/N and IR/N terms are replaced with S(I/N)^2 and I(R/N)^2. The square terms approximate the _perceived value_ of belonging to a particular sub-group as modeled by [Metcalfe's law](https://en.wikipedia.org/wiki/Metcalfe%27s_law).

#### Attempt at a global fit

The fit to the time period from 2017 onwards is shown in the figure below. Two things can be noticed immediately. The minor bubbles of June and September are not very well described, which is to be expected. After all, the model is only able to describe a single bubble. Moreover, at early time periods, as well as after the big peak, the lower limit of the 95% prediction interval goes below zero. This is a consequence the variability is being modeled by a normal distribution with the width proportional to the square root of the mean value.

![Cryptocurrency fit_all](img/Cryptocurrency_FOMO-FUD_fit%28update%29.png)

#### Describing the shape of the peak

In order to improve the fit further, the process is repeated by using data from 2017-10-01 onwards (therefore excluding the two pre-peaks), and the variability model is replaced by a log-normal distribution. The fit of this improved model on the reduced data set is shown below.

![Cryptocurrency fit_peak](img/Cryptocurrency_FOMO-FUD_%28jan%20peak%29.png)

I personally find it astounding how well does the median prediction line match the 31-day moving average of the Google Trends data.

#### Quo vadis, crypto?

One way to use the above result is to monitor the Google Trends data for a break outside the 95% prediction interval. Now it the above assumptions hold approximately, one would expect to see either of these two things:
- future trend data within the 95% prediction interval (the decay will continue),
- or an upwards break-out (which would indicate this was a bubble indeed, but overlaid on slowly rising background adoption curve).

Let's see what the future holds :-)
