#' @import foreach
RUN_est <- function(est_list,
                    dat.list,
                    est_output_path,
                    stop_at,
                    variance,
                    cl_num,
                    maxit,
                    optim_reltol,
                    evalimit,
                    int_bound,
                    optim_trace
) {

  int_lower_bound = - int_bound
  int_upper_bound = int_bound
  est_list_curr = est_list
  iter = 0L
  idx = NULL
  P = ncol(dat.list$X)
  cl = parallel::makeCluster(cl_num)
  parallel::clusterExport(cl, c(
    "target_M_step_i_int_gradient",
    "target_M_step_i_int",
    'target_M_step_i_gradient',
    'target_M_step_i',
    'fun_x_h_y_h_joint',
    'fun_x_h_given_y_h',
    'expit'))
  doSNOW::registerDoSNOW(cl)

  while(iter < maxit) {

    iter = iter + 1L
    print(paste0("-----------Iteration ", iter,"-----------"))
    fun_x_vec = sapply(1L:nrow(dat.list$X), function(h) {
      cubature::adaptIntegrate(fun_x_h_y_h_joint,
                               lower = int_lower_bound, upper = int_upper_bound, maxEval = evalimit,
                               h = h,current_est_list = est_list_curr, data_Z = dat.list$Z, data_X = dat.list$X)$integral
    })
    re = foreach::foreach(idx=1L:P,
                          .packages=c('cubature',
                                      'stats'),
                          .verbose = TRUE) %dopar% {
                            stats::optim(par = est_list_curr[[idx]],
                                  fn = target_M_step_i_int,
                                  method =  "BFGS",
                                  gr = target_M_step_i_int_gradient,
                                  i = idx,
                                  fun_x = fun_x_vec,
                                  current_est_list = est_list_curr,
                                  data_Z = dat.list$Z,
                                  data_X = dat.list$X,
                                  int_lower_bound = int_lower_bound,
                                  int_upper_bound = int_upper_bound,
                                  maxEval = evalimit,
                                  hessian = FALSE,
                                  control = list(trace = optim_trace,
                                                 REPORT = 1L,
                                                 reltol = optim_reltol))
                          }
    if(optim_trace) {
      saveRDS(re, file = paste(est_output_path, iter, sep = "_"))
    }
    if(all(sapply(re, '[[', "convergence") == 0)) {
      print(paste0("Iteration ", iter, " converged successfully"))
      est_list_up = lapply(re, '[[', "par")
    }
    else {
      error_idx = which(sapply(re, '[[', "convergence") != 0)
      print(paste0("Item ", error_idx," in iteration ", iter, " has converging issue"))
      break
    }
    max_absolute_change =  max(sapply(1L:P, function(idx) max(abs(est_list_up[[idx]]- est_list_curr[[idx]]))))
    print(paste0("maximum absolute change in parameters:", paste(max_absolute_change, collapse = " ")))
    if( max_absolute_change < stop_at) {
      print(paste0("-----------EM successfully converges at iteration  ",iter,"-----------"))
      break
    } else {
      est_list_curr = est_list_up
    }
  }
  names(est_list_curr) = colnames(dat.list$X)

  for(i in 1L:P) {
    M_i = length(unique(stats::na.omit(dat.list$X[,i])))
    dd = M_i+ncol(dat.list$Z)-1
    tmpp = est_list_curr[[i]]
    tmpp_l = tmpp[dd:length(tmpp)]
    if(tmpp[dd] < 0) {
      tmpp_l = -tmpp_l
    }
    est_list_curr[[i]][dd:length(tmpp)] = tmpp_l
  }

  if(variance) {
    ss = score_square_x(current_est_list = est_list_curr,
                        int_lower_bound = int_lower_bound,
                        int_upper_bound = int_upper_bound,
                        maxEval = evalimit,
                        data_Z = dat.list$Z, data_X = dat.list$X)
    cov =  solve(ss)
    var_tmp = diag(cov)
    variance_list = list(1L:P)
    tt = 0L
    for(i in 1L:P) {
      M_i = length(unique(stats::na.omit(dat.list$X[,i])))
      variance_list[[i]] =  var_tmp[(tt+1L):(tt+2L*(ncol(dat.list$Z)-1L) + M_i)]
      names(variance_list[[i]]) = names(est_list_curr[[i]])
      tt =  tt+ 2L*(ncol(dat.list$Z)-1L) + M_i
    }
    names(variance_list) = names(est_list_curr)
    colnames(cov) = rownames(cov) = sapply(1:P, function(i) paste(names(variance_list)[i], names(variance_list[[i]]), sep = "_"))
    return( list("coefficients" = est_list_curr,
                 "variance" = variance_list,
                 "cov" = cov))
  } else {
    return(list("coefficients" = est_list_curr))
  }

  parallel::stopCluster(cl)

}
