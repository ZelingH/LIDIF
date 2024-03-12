#' Summarize LIDIF output.
#'
#' @param object An object of class `LIDIF`.
#' @param terms A vector of characters containing the name of variables you would like to perform Wald tests. For example, specifying terms = "age" if you would like to test age's DIF effects. The default is `NULL`.
#' @param all_terms Logical. Whether perform Wald tests on all individual coefficients. The default is `TRUE`.
#' @param digits Numeric. Control the number of digits displayed in the results. The default value is 2.
#'
#' @return A list containing.
#' \itemize{
#'   \item `stats`: the Wald statistics.
#'   \item `p_value`: the corresponding p values.
#'   \item `coefficients`: the data frame containing estimated coefficients, standard error, factor loading and p values.
#'   \item `term`: the corresponding test statistics, degree of freedom and p values if specifying `terms` in the argument.
#' }
#' @export
#'
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
#' ## Summarize results: individual DIF effects
#' summary_LIDIF(res)
#'
#' ## Summarize results: combineing uniform and non-uniform effects for sex
#' summary_LIDIF(res, terms = "sex")
#' }
summary_LIDIF = function(object, # an object of class "LIDIF"
                         terms = NULL, # specify the variables you would like to test, the default is null
                         all_terms = TRUE, # whether test on all individual coefficients
                         digits = 2
) {
  if(!inherits(object,"LIDIF")) {
    stop("Please input your results from the LIDIF function!")
  }

  if(is.null(terms) & (!all_terms)) {
    stop("Please specify the name of variables you would like to test or change all_terms into TRUE!")
  }

  if(all_terms) {
    tmp = lapply(1:length(object$coefficients), function(i) {
      betas = object$coefficients[[i]]
      loadings = betas/sqrt(betas^2+1)
      var = object$variance[[i]]
      stats = betas^2/var
      return(list("stats" = stats,
                  "p_value" =  stats::pchisq(stats, df = 1, lower.tail = FALSE),
                  "coefficients" = cbind.data.frame("Loading" = round(loadings,digits),
                                                    "Estimate" = round(betas,digits),
                                                    "Odds Ratio" =  paste0(round(exp(betas),digits), " (", round(exp(betas - 1.96*sqrt(var)),digits), ", ", round(exp(betas + 1.96*sqrt(var)),digits), ")"))))
    })


    all_p_values = do.call(c, lapply(tmp,'[[','p_value'))
    all_p_values_fdr = stats::p.adjust(all_p_values, method = "fdr")
    all_p_values_bf = stats::p.adjust(all_p_values, method = "bonferroni")
    tt = 1
    for(idx in 1:length(tmp)) {
      lh = nrow(tmp[[idx]]$coefficients)
      tmp[[idx]]$coefficients$p_value = ifelse(all_p_values[tt:(tt+lh-1)] < 0.001, '<0.001',round(all_p_values[tt:(tt+lh-1)],3))
      tmp[[idx]]$coefficients$FDR = ifelse(all_p_values_fdr[tt:(tt+lh-1)] < 0.001, '<0.001',round(all_p_values_fdr[tt:(tt+lh-1)],3))
      tmp[[idx]]$coefficients$BF = ifelse(all_p_values_bf[tt:(tt+lh-1)] < 0.001, '<0.001',round(all_p_values_bf[tt:(tt+lh-1)],3))
      tt = tt +lh
    }

    names(tmp) = names(object$coefficients)
    out = list("stats" = lapply(tmp, '[[', "stats"),
               "p_value" = lapply(tmp, '[[', "p_value"),
               "coefficients" = lapply(tmp, '[[', "coefficients"))
  }

  if(!is.null(terms)) {
    out1 = lapply(1:length(object$coefficients), function(i) {

      betas = object$coefficients[[i]]
      cn = paste(names(object$coefficients)[[i]], names(betas), sep = "_")
      cov = object$cov[cn, cn]

      tmp = lapply(terms, function(term) {
        ctr = stringr::str_detect(names(betas), paste0("^",term))
        if(sum(ctr) == 0) {
          NULL
        } else {
          stats = t(betas[ctr]) %*% solve(cov[ctr,ctr]) %*% betas[ctr]
          c("X2" = stats,
            "df" = sum(ctr),
            "Pr(>X2)" = stats::pchisq(stats, df = sum(ctr), lower.tail = FALSE))
        }
      })
      names(tmp) = terms
      tmp = do.call(rbind, tmp)

      return(tmp)
    })
    names(out1) = names(object$coefficients)
  }

  if(all_terms & is.null(terms)) {
    print(out$coefficients)

  } else if (all_terms & !is.null(terms)) {
    out[[4]] = out1
    names(out)[4] = paste(terms, collapse = " ")
    print(out1)
  } else {
    out = out1
    print(out)
  }
  invisible(out)
}
