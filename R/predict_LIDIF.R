#' Estimating the latent variable based on the LIDIF model fitting results
#'
#' The function estimates the latent variable by calculating the estimated mean (and the standard error) of the latent variable given the specified exogenous variables and item responses in LIDIF function.
#'
#' @param dat.list The data list containing both the observed items matrix and enogenous variable matrix derived from `prepare_data` function. Should be of the same format as the input in the `LIDIF` function.
#' @param coefs_list The list of DIF effects. Should be of the same format as the `coefficients` value in `LIDIF` output
#' @param int_bound The adaptive integration boundaries. The default value is 3, meaning the integration taking from -3 to 3.
#' @param evalimit The number of quadrature used in the adaptive integration. The default value is 20.
#' @param variance Logical. Whether output the estimated variance as well. The default is TRUE.
#'
#' @details
#' Denote the latent variable as \eqn{Y}, the covariate matrix as \eqn{Z} and \eqn{X_1,...,X_p} are the observed items.
#' Then we can estimate the latent variable by calculating the posterior mean
#' \deqn{E(Y|Z, X_1, ..., X_p)}
#' and the posterior variance by
#' \deqn{Var(Y|Z, X_1,..., X_p)}
#' Therefore, the function can be used as both estimating the posterior mean of the latent variable for each individual,
#'  and predicting the latent level for new participants.
#'
#' @returns A list that contains
#' \itemize{
#'   \item est_mean - the estimated posterior mean.
#'   \item set_var - the estimated posterior variance. Output only if `variance` = TRUE.

#' }
#' @export
#' @examples
#'  \dontrun{
#' ## load the sample data (see `?LIDIF::binsurvs` for details)
#' binsurvs = LIDIF::binsurvs # The exogenous variables are age and sex.
#'
#' ## prepare for model fitting
#' dat.list = prepare_data(binsurvs$X, binsurvs$Z)
#'
#' ## LIDIF fitting
#' # The parameter specified is set to reduce the running time.
#' # In your analysis, please refer to the default value.
#' library(LIDIF)
#' res = LIDIF(dat.list = dat.list,
#'             cl_num = 5, # before running, please check if you have 5 cores
#'             type_list = "binary",
#'             maxit = 2,
#'             random_per = 0.5,
#'             init_nums = 2,
#'             init_maxit = 2)
#'
#' ## predict the posterior distribution of the latent variable
#' predict_LIDIF(dat.list = dat.list,
#'               coefs_list = res$coefficients)
#' }

predict_LIDIF = function(dat.list, # data of the same format as the input in LIDIF function
                         coefs_list, # list of coefficients, should be of the same format as LIDIF output
                         int_bound = 3L, # bond for integration
                         evalimit = 10L, # control number of quadrature
                         variance = TRUE # logical switch indicating if standard errors are required.
) {
  predy = expectation_y_given_x(current_est_list = coefs_list,
                                int_lower_bound = -int_bound,
                                int_upper_bound = int_bound,
                                maxEval = evalimit,
                                data_Z = dat.list$Z,
                                data_X = dat.list$X)
  if(!variance) {
    return(list("est_mean" = predy))
  } else {
    vary = covariance_y_given_x(current_est_list =  coefs_list,
                                int_lower_bound = -int_bound,
                                int_upper_bound = int_bound,
                                maxEval = evalimit,
                                data_Z = dat.list$Z,
                                data_X = dat.list$X)
    return(list("est_mean" = predy,
                "est_var" = sqrt(vary)))
  }
}
