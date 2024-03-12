#' Performing Likelihood-based Investigation of Differential Item Functioning  (LIDIF)
#'
#' The function takes the output of `prepare_data` function and run the LIDIF procedure. Notice that the procedure incoporats parallel computing functions to boost the computation speed. Therefore, we strongly recommend run the function with multiple cores. Please refer to the arguments on specifying number of cores.
#'
#' @param dat.list The data list containing both the observed items matrix and enogenous variable matrix derived from `prepare_data` function.
#' @param cl_num Number of cores LIDIF can use. The more the better!
#' @param type_list A vector of characters containing the types of items (`binary`,`ordinal`). If the length of vector is 1, then the same type would apply to all items.
#' @param output_dir The path to save intermediate results. The default value is NULL. If NULL, the results will be save in current working directory.
#' @param int_bound The adaptive integration boundaries. The default value is 3, meaning the integration taking from -3 to 3.
#' @param evalimit The number of quadrature used in the adaptive integration. The default value is 20.
#' @param stop_at The absolute convergence tolerance. The default value is 0.01.
#' @param maxit The maximum number of iterations used in the EM algorithm. The default value is 50.
#' @param optim_trace Logical. Should track optimization process? The default value is TRUE.
#' @param optim_reltol The relative convergence tolerance for M-step. The default value is 0.1.
#' @param hessian Logical. Should return the numerical hessian matrix in optimization procedures? The default value is FALSE.
#' @param variance Logical. Should calculate variance and covariance matrix in the end? The default value is TRUE.
#' @param initialization Logical. Should start from random initialization? The default is TRUE.
#' @param init_input If initialization = FALSE, specify your own initialization here. The default is NULL.
#' @param random_per Percentage of random samples in initialization. The default value is 0.05.
#' @param replace Logical. Should generate random samples with replacement? The default is FALSE.
#' @param init_nums Number of random initialization. The default is 30.
#' @param init_maxit Maximum number of iterations in initialization. The default is 5.
#'
#' @details
#' Denote the latent variable as \eqn{Y}, the covariate matrix as \eqn{Z} and \eqn{X_1,...,X_p} are the observed items.
#' For items with binary responses (0 or 1), LIDIF models
#' \deqn{logit(P(X_i =1)) = \alpha_i+\beta_i^TZ + \zeta_i^TZ \times Y}
#' For items with ordinal responses (1, 2,...,\eqn{M_i}), LIDIF models
#' \deqn{logit(P(X_i \geq m)) = \alpha_{im}+\beta_i^TZ + \zeta_i^TZ \times Y}
#' where \eqn{m \in \{1, 2,...,M_i-1\}} and \eqn{\alpha_{i1} > ...> \alpha_{im-1}}.\cr
#'
#' The model returns maximum likelihood estimators of all the coefficients and their estimated variance (by choice).\cr
#'
#' The key to the estimation accuracy of LIDIF is specifying multiple random initialization in `init_nums` arguments. A trade-off is the more
#' number of random initialization you specified, the longer it took to run `LIDIF`. But you could always speed up the process by running on multiple
#' computing cores (specified in `cl_num`) arguments.\cr
#'
#' For your reference, the default setting provides accurate estimation in simulations with 5 items and 2 exogenous covariates from 1000 observations.
#' And the computing time was 1 hour with 5 cores using R version 4.0.2.
#'
#' @return An object of the class `LIDIF` that contains
#' \itemize{
#'   \item `coefficients`: a list of the estimated DIF effects. with each sublist corresponding to an item.
#'   \item `variance`: A list of the estimated variance of the individual coefficients, following the same order as `coefficients`. Return only if variance = TRUE.
#'   \item `cov`: The estimated variance-covariance matrix for all the coefficeints. Return only if variance = TRUE.
#'
#' }
#'
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
#' }

#' @import foreach
LIDIF <- function(dat.list, #output of prepare_data function
                  cl_num, #number of cores (the more the better!)
                  type_list, # types of items
                  output_dir = NULL, # path to save intermediate results
                  int_bound = 3L, # bound for integration
                  evalimit = 10L, # control number of quadrature
                  stop_at = 0.01, # stopping criteria
                  maxit = 50L, # maximum number of iterations
                  optim_trace = TRUE, # track optimization process
                  optim_reltol = 0.1, # relative convergence rate
                  hessian = FALSE, # whether return the numerical hessian matrix in optimization procedures
                  variance = TRUE, # whether calculate variance in the end
                  initialization = TRUE, # whether start the random initialization
                  init_input = NULL, # if no random initialization, specify your own initialization here
                  random_per = 0.05, # percentage of random samples for initialization
                  replace = FALSE, # whether generate random samples with replacement
                  init_nums = 30, # number of random initialization
                  init_maxit = 5 # maximum number of iterations in initialization
) {

  if(is.null(output_dir)) {
    output_dir =  getwd()
  }
  print(paste("Outputs will be saved at:", output_dir))

  print("Starting initialization ...")
  cur_time = format(Sys.time(), "%m%d%Y%H%M")

  set.seed(1000)

  if(initialization) {

    init_i = NULL
    cl = parallel::makeCluster(cl_num)
    parallel::clusterExport(cl, c(
      "get_pseudo_pars",
      "target_M_step_i_int_gradient",
      "target_M_step_i_int",
      'target_M_step_i_gradient',
      'target_M_step_i',
      'fun_x_h_y_h_joint',
      'fun_x_h_given_y_h',
      'expit',
      'RUN_init'))

    doSNOW::registerDoSNOW(cl)

    foreach::foreach(init_i=1L:init_nums,
                     .packages=c('cubature',"foreach"),
                     .verbose = TRUE,
                     .export = ls(globalenv())
                     ) %dopar% {
                       initial_list = get_pseudo_pars(random_per = random_per, dat.list = dat.list,type_list = type_list, replace = replace)
                       init_output_path = paste0(output_dir, "/init_",cur_time, "_", init_i)
                       saveRDS(initial_list, file = paste(init_output_path , 0, sep = "_"))
                       RUN_init(initial_list = initial_list,
                                dat.list = dat.list,
                                init_output_path = init_output_path,
                                stop_at = stop_at,
                                init_i = init_i,
                                cl_num = cl_num,
                                init_maxit = init_maxit,
                                optim_reltol = optim_reltol,
                                evalimit = evalimit,
                                int_bound  = int_bound,
                                optim_trace = optim_trace)
                     }
    parallel::stopCluster(cl)

    print("Deciding on initialization ...")
    initial_list_all = lapply(1:init_nums, function(init_i) {
      re = tryCatch(readRDS(file = paste0(output_dir, "/init_",cur_time, "_", init_i, "_", init_maxit)),
                    error = function(e) NULL)
      if(!is.null(re)) {
        lapply(re,'[[','par')
      }
      else {
        NULL
      }
    })

    loglik_list = lapply(initial_list_all, function(re) {
      if(!is.null(re)) {
        fun_x_vec <- sapply(1:nrow(dat.list$X), function(h) {
          cubature::adaptIntegrate(fun_x_h_y_h_joint,
                                   lower = -int_bound, upper = int_bound, maxEval = evalimit,
                                   h = h,current_est_list = re, data_Z = dat.list$Z, data_X = dat.list$X)$integral
        })
        sum(-log(fun_x_vec))
      }
      else {
        NA
      }

    })
    loglik_list  = do.call(c, loglik_list )

    select_init = which.min(loglik_list)
    est_list_curr = initial_list_all[[select_init ]]
    est_output_path = paste0(output_dir, "/est_",cur_time)
    names(est_list_curr) = colnames(dat.list$X)
    saveRDS(est_list_curr, file = paste(est_output_path, 0, sep = "_"))

    file.remove(file.path(output_dir, dir(path=output_dir ,pattern=paste0("init_", cur_time,"*"))))
  } else {
    if(is.null(init_input)) {
      stop("Please specify your initialization parameters or change initalization = TRUE")
    }
    est_list_curr= init_input
  }

  print("Starting estimation ...")

  re = RUN_est(est_list = est_list_curr,
               dat.list = dat.list,
               est_output_path = est_output_path,
               stop_at = stop_at,
               variance = variance,
               cl_num = cl_num,
               maxit = maxit,
               optim_reltol = optim_reltol,
               evalimit = evalimit,
               int_bound = int_bound,
               optim_trace = optim_trace)
  class(re) = "LIDIF"



  if(length(type_list) == 1 & type_list == "ordinal") {
    for(i in 1L:ncol(dat.list$X)) {
      M_i = length(unique(stats::na.omit(dat.list$X[,i])))
      dd = M_i+ncol(dat.list$Z)-2
      tmpp = re$coefficients[[i]][1:dd]
      re$coefficients[[i]][1:dd] = -tmpp
    }
  } else if ("ordinal" %in% type_list) {
    for(i in 1L:ncol(dat.list$X)) {
      if(type_list[i] == "ordinal") {
        M_i = length(unique(stats::na.omit(dat.list$X[,i])))
        dd = M_i+ncol(dat.list$Z)-2
        tmpp = re$coefficients[[i]][1:dd]
        re$coefficients[[i]][1:dd] = -tmpp
      }
    }
  }
  return(re)
}
