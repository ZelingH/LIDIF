fun_x_h_y_h_joint_y <- function(y, h,
                                current_est_list,
                                data_Z, data_X) {

  fun_x_h_given_y_h(y = y, h = h,
                    current_est_list = current_est_list,
                    data_Z = data_Z, data_X = data_X)*exp(-y^2L/2L)*y/sqrt(2L*pi)
}

fun_x_h_y_h_joint_y_square <- function(y, h,
                                       current_est_list,
                                       data_Z, data_X) {

  fun_x_h_given_y_h(y = y, h = h,
                    current_est_list = current_est_list,
                    data_Z = data_Z, data_X = data_X)*exp(-y^2L/2L)*y^2/sqrt(2L*pi)
}

expectation_y_given_x <- function(current_est_list,
                                  int_lower_bound,
                                  int_upper_bound,
                                  maxEval = 10,
                                  data_Z, data_X) {


  J <- ncol(as.matrix(data_Z))
  n <- nrow(data_X)
  P <- ncol(data_X)

  numeritor <- sapply(1L:n, function(h) {
    cubature::adaptIntegrate(fun_x_h_y_h_joint_y, lower = int_lower_bound, upper = int_upper_bound,
                             h = h,current_est_list = current_est_list, data_Z = data_Z, data_X = data_X, maxEval = maxEval)$integral
  })
  denominator <- sapply(1L:n, function(h) {
    cubature::adaptIntegrate(fun_x_h_y_h_joint, lower = int_lower_bound, upper = int_upper_bound,
                             h = h,current_est_list = current_est_list, data_Z = data_Z, data_X = data_X, maxEval = maxEval)$integral
  })
  numeritor/denominator
}

covariance_y_given_x <-  function(current_est_list,
                                  int_lower_bound,
                                  int_upper_bound,
                                  maxEval = 10,
                                  data_Z, data_X) {

  J <- ncol(as.matrix(data_Z))
  n <- nrow(data_X)
  P <- ncol(data_X)


  numeritor_1 <- sapply(1L:n, function(h) {
    cubature::adaptIntegrate(fun_x_h_y_h_joint_y_square, lower = int_lower_bound, upper = int_upper_bound, maxEval = maxEval,
                             h = h,current_est_list = current_est_list, data_Z = data_Z, data_X = data_X)$integral
  })
  denominator_1 <- sapply(1L:n, function(h) {
    cubature::adaptIntegrate(fun_x_h_y_h_joint, lower = int_lower_bound, upper = int_upper_bound, maxEval = maxEval,
                             h = h,current_est_list = current_est_list, data_Z = data_Z, data_X = data_X)$integral
  })
  numeritor_2 <- sapply(1L:n, function(h) {
    cubature::adaptIntegrate(fun_x_h_y_h_joint_y, lower = int_lower_bound, upper = int_upper_bound,maxEval = maxEval,
                             h = h,current_est_list = current_est_list, data_Z = data_Z, data_X = data_X)$integral
  })
  numeritor_1/denominator_1 - (numeritor_2/denominator_1)^2L
}
