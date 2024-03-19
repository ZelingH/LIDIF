
<!-- README.md is generated from README.Rmd. Please edit that file -->

`LIDIF` is designed to detect differential item functioning (DIF) in
binary and/or ordinal items.

Here we provide a sample with details on how to estimate DIF
coefficients, variance, predict the latent variable and visualize DIF
effects in categorical variables.

## Installation

You can install the development version of LIDIF like so:

``` r
library(devtools)
#> Loading required package: usethis

## install LIDIF function

## install_github("ZelingH/LIDIF")
library(LIDIF)
```

# Sample Data

`LIDIF` comes with a simulated data set.

``` r
# load sample data
data(binsurvs)
```

The sample data consists of two parts. The first part contains the
binary items:

``` r
head(binsurvs$X)
#>   item1 item2 item3
#> 1     1     1     0
#> 2     1     0     1
#> 3     1     0     0
#> 4     1     0     1
#> 5     0     0     0
#> 6     0     1     1
```

The second part is the covariate information. We are interested in
testing the DIF effects for both `sex` and `age`. The continuous
covariate `age` has been standarded.

``` r
head(binsurvs$Z)
#>          age sex
#> 1  1.7858561   0
#> 2 -0.2906848   0
#> 3 -1.6375232   0
#> 4  0.7566259   1
#> 5 -0.2153077   1
#> 6 -0.6620240   1
```

## Prepare the data

In the first step, we sort our sample data into the format of `LIDIF`
function input.

``` r
surv.list = prepare_data(X = binsurvs$X, # item matrix
                         Z = binsurvs$Z # covariates matrix
                         )
```

**surv.list** is a list of two components.

## Run LIDIF function

The `LIDIF` function takes the `surv.list` as the model input and you
need to specify the types of items (binary or ordinal) in `type_list`
arguments. To improve computational efficiency, `LIDIF` leverages the
benefits of parallel computation and you can specify the number of
computing cores in `cl_num`.

Below is the estimating procedures in `LIDIF`. To ensure estimation
accuracy, LIDIF has a built-in random initialization procedure. You can
skip the random initialization by specifying your own starting point in
`init_input`. In random initialization, the default number of repeated
samples `init_nums` (m) $=30$, iterations `init_maxit` (k) $= 5$ and the
percentage of sampling `random_per` = $0.05$. These default setting
yields accurate estimation results in our simulation studies (1000
samples with 5 items). If you have fewer observations, increasing
`random_per` is recommended.

<figure>
<img src="estimation.png" alt="Estimating procedures" />
<figcaption aria-hidden="true">Estimating procedures</figcaption>
</figure>

``` r
res = LIDIF(dat.list = surv.list,
            cl_num = 2, # number of cores
            type_list = "binary", # item type
            maxit = 5, # m = 1
            random_per = 0.5, # number of random samples
            init_nums = 10, # k = 2
            init_maxit = 1)
```

`LIDIF` function returns a list:

Estimated coefficients:

``` r
res$coefficients
#> $item1
#> (Intercept)         age         sex           Y       age:Y       sex:Y 
#> -0.09896441 -0.14220189 -0.13848170  1.53566216 -0.39891371 -1.15920147 
#> 
#> $item2
#> (Intercept)         age         sex           Y       age:Y       sex:Y 
#> -0.73900886  1.56726187  0.85542046  1.84016548 -0.01750649  1.18076351 
#> 
#> $item3
#> (Intercept)         age         sex           Y       age:Y       sex:Y 
#>  -0.2900509   0.2068347   0.4526589   1.6536083   0.3269727  -0.3384376
```

Estimated variance:

``` r
res$variance
#> $item1
#> (Intercept)         age         sex           Y       age:Y       sex:Y 
#>  0.20058942  0.09668419  0.26786406  0.96788378  0.29967616  0.96167165 
#> 
#> $item2
#> (Intercept)         age         sex           Y       age:Y       sex:Y 
#>   0.6577958   2.0949710   1.6712815   2.8629129   1.5601336  10.3476645 
#> 
#> $item3
#> (Intercept)         age         sex           Y       age:Y       sex:Y 
#>   0.2714678   0.1684335   0.5008973   2.4776074   1.8841419   3.0304727
```

and the estimated variance-covariance matrix:

``` r
res$cov
```

## Inference of the DIF

Testing for individual DIF effects:

``` r
summary_LIDIF(res)
#> $item1
#>             Loading Estimate         Odds Ratio p_value   FDR BF
#> (Intercept)   -0.10    -0.10  0.91 (0.38, 2.18)   0.825 0.896  1
#> age           -0.14    -0.14   0.87 (0.47, 1.6)   0.647 0.896  1
#> sex           -0.14    -0.14   0.87 (0.32, 2.4)   0.789 0.896  1
#> Y              0.84     1.54 4.64 (0.68, 31.94)   0.119 0.896  1
#> age:Y         -0.37    -0.40  0.67 (0.23, 1.96)   0.466 0.896  1
#> sex:Y         -0.76    -1.16  0.31 (0.05, 2.14)   0.237 0.896  1
#> 
#> $item2
#>             Loading Estimate           Odds Ratio p_value   FDR BF
#> (Intercept)   -0.59    -0.74     0.48 (0.1, 2.34)   0.362 0.896  1
#> age            0.84     1.57   4.79 (0.28, 81.79)   0.279 0.896  1
#> sex            0.65     0.86   2.35 (0.19, 29.64)   0.508 0.896  1
#> Y              0.88     1.84   6.3 (0.23, 173.56)   0.277 0.896  1
#> age:Y         -0.02    -0.02   0.98 (0.08, 11.37)   0.989 0.989  1
#> sex:Y          0.76     1.18 3.26 (0.01, 1782.28)   0.714 0.896  1
#> 
#> $item3
#>             Loading Estimate          Odds Ratio p_value   FDR BF
#> (Intercept)   -0.28    -0.29   0.75 (0.27, 2.08)   0.578 0.896  1
#> age            0.20     0.21   1.23 (0.55, 2.75)   0.614 0.896  1
#> sex            0.41     0.45    1.57 (0.39, 6.3)   0.522 0.896  1
#> Y              0.86     1.65 5.23 (0.24, 114.29)   0.293 0.896  1
#> age:Y          0.31     0.33  1.39 (0.09, 20.44)   0.812 0.896  1
#> sex:Y         -0.32    -0.34  0.71 (0.02, 21.62)   0.846 0.896  1
```

Testing for combined uniform and non-uniform DIF effects for sex:

``` r
summary_LIDIF(res, terms = "sex")
#> $item1
#>           X2 df   Pr(>X2)
#> sex 1.579296  2 0.4540045
#> 
#> $item2
#>            X2 df   Pr(>X2)
#> sex 0.4490729  2 0.7988865
#> 
#> $item3
#>            X2 df   Pr(>X2)
#> sex 0.4119279  2 0.8138624
```

## Predict the latent variable

With the output from `LIDIF` function, we could predict the latent
variable via the posterior mean and its variance via the posterior
variance.

``` r
pred = predict_LIDIF(dat.list = surv.list,
              coefs_list = res$coefficients)
```

The histogram of posterior mean:

``` r
hist(pred$est_mean, main = "Histogram of the Latent Variable (Posterior Mean)")
```

<img src="man/figures/README-unnamed-chunk-14-1.png" width="100%" />

## Item Characteristic Curves (ICC)

Plot the DIF effects for sex using ICC curves:

``` r
# specify the covariate matrix
tt = cbind("age"= c(mean(surv.list$Z[,"age"]),mean(surv.list$Z[,"age"])), # age is set as population average
           "sex" = c(0,1))


getICC(res$coefficients,
       cov_mat = tt,
       compare_var = "sex",
       type_list = "binary")
```

<img src="man/figures/README-unnamed-chunk-15-1.png" width="100%" />
