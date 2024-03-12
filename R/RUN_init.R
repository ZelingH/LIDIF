#' @import foreach
RUN_init <- function(initial_list,
                     dat.list,
                     init_output_path,
                     stop_at,
                     init_i,
                     cl_num,
                     init_maxit,
                     optim_reltol,
                     evalimit,
                     int_bound,
                     optim_trace
) {

  int_lower_bound = - int_bound
  int_upper_bound = int_bound
  est_list_curr = initial_list

  iter = 0L
  P = ncol(dat.list$X)
  idx = NULL

  while(iter < init_maxit) {

    iter = iter + 1L
    print(paste0("----------- Initialization # ", init_i, " iteration ",iter,"-----------"))
    fun_x_vec <- sapply(1L:nrow(dat.list$X), function(h) {
      cubature::adaptIntegrate(fun_x_h_y_h_joint,
                               lower = int_lower_bound, upper = int_upper_bound,maxEval = evalimit,
                               h = h,current_est_list = est_list_curr, data_Z = dat.list$Z, data_X = dat.list$X)$integral
    })
    re = foreach::foreach(idx=1L:P,
                          .packages=c('cubature', "foreach"),
                          .verbose = FALSE
    ) %do% {
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
                                  REPORT = 1,
                                  reltol = optim_reltol))
    }

    saveRDS(re, file = paste(init_output_path, iter, sep = "_"))
    if(all(sapply(re, '[[', "convergence") == 0)) {
      print(paste0("Iteration ", iter, " converged successfully"))
      est_list_up = lapply(re, '[[', "par")
    } else {
      error_idx = which(sapply(re, '[[', "convergence") != 0L)
      print(paste0("Item ", error_idx," in iteration ", iter, " has coverging issue"))
      break
    }
    max_absolute_change =  max(sapply(1L:P, function(idx) max(abs(est_list_up[[idx]]- est_list_curr[[idx]]))))
    print(paste0("maximum absolute change in parameters:", paste(max_absolute_change, collapse = " ")))

    if( max_absolute_change < stop_at) {
      saveRDS(re, file = paste(init_output_path, iter, sep = "_"))
      print(paste0("-----------EM successfully converges at iteration  ",iter,"-----------"))
      break
    }
    else {
      est_list_curr = est_list_up
    }
  }
}
