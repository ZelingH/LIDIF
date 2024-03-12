
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
#>  -0.5436569  -0.1011845   0.2598708   1.9267130  -0.4837032  -1.4660758 
#> 
#> $item2
#> (Intercept)         age         sex           Y       age:Y       sex:Y 
#> -0.82650128  1.34221856  0.88424325  1.54605663 -0.07640104  0.48517812 
#> 
#> $item3
#> (Intercept)         age         sex           Y       age:Y       sex:Y 
#>  -0.9689610   0.2619979   1.6371727   2.4491980   0.1759962   0.3770161
```

Estimated variance:

``` r
res$variance
#> $item1
#> (Intercept)         age         sex           Y       age:Y       sex:Y 
#>   0.2638503   0.1036013   0.3311531   1.2654394   0.3045737   1.3115827 
#> 
#> $item2
#> (Intercept)         age         sex           Y       age:Y       sex:Y 
#>   0.4733840   0.6645196   0.7341635   1.0230675   0.9065385   2.8182791 
#> 
#> $item3
#> (Intercept)         age         sex           Y       age:Y       sex:Y 
#>   0.9768835   0.2600129   2.1275544   6.3396067   3.6659158  17.9972100
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
#> (Intercept)   -0.48    -0.54  0.58 (0.21, 1.59)   0.290 0.595  1
#> age           -0.10    -0.10    0.9 (0.48, 1.7)   0.753 0.927  1
#> sex            0.25     0.26   1.3 (0.42, 4.01)   0.652 0.902  1
#> Y              0.89     1.93 6.87 (0.76, 62.27)   0.087 0.595  1
#> age:Y         -0.44    -0.48  0.62 (0.21, 1.82)   0.381 0.623  1
#> sex:Y         -0.83    -1.47  0.23 (0.02, 2.18)   0.200 0.595  1
#> 
#> $item2
#>             Loading Estimate         Odds Ratio p_value   FDR BF
#> (Intercept)   -0.64    -0.83  0.44 (0.11, 1.69)   0.230 0.595  1
#> age            0.80     1.34 3.83 (0.77, 18.92)   0.100 0.595  1
#> sex            0.66     0.88 2.42 (0.45, 12.98)   0.302 0.595  1
#> Y              0.84     1.55 4.69 (0.65, 34.07)   0.126 0.595  1
#> age:Y         -0.08    -0.08  0.93 (0.14, 5.99)   0.936 0.936  1
#> sex:Y          0.44     0.49 1.62 (0.06, 43.62)   0.773 0.927  1
#> 
#> $item3
#>             Loading Estimate            Odds Ratio p_value   FDR BF
#> (Intercept)   -0.70    -0.97     0.38 (0.05, 2.63)   0.327 0.595  1
#> age            0.25     0.26      1.3 (0.48, 3.53)   0.607 0.902  1
#> sex            0.85     1.64    5.14 (0.29, 89.66)   0.262 0.595  1
#> Y              0.93     2.45 11.58 (0.08, 1610.34)   0.331 0.595  1
#> age:Y          0.17     0.18    1.19 (0.03, 50.84)   0.927 0.936  1
#> sex:Y          0.35     0.38     1.46 (0, 5954.77)   0.929 0.936  1
```

Testing for combined uniform and non-uniform DIF effects for sex:

``` r
summary_LIDIF(res, terms = "sex")
#> $item1
#>           X2 df   Pr(>X2)
#> sex 1.638797  2 0.4406968
#> 
#> $item2
#>           X2 df   Pr(>X2)
#> sex 1.091974  2 0.5792698
#> 
#> $item3
#>           X2 df   Pr(>X2)
#> sex 1.261736  2 0.5321298
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

<figure>
<img src="ICC_example.png" alt="Comparison between racial groups" />
<figcaption aria-hidden="true">Comparison between racial
groups</figcaption>
</figure>
