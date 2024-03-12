#' Preparing data for LIDIF function.
#'
#' The function prepare your raw data to fit into LIDIF model.
#' @param X A numeric matrix with columns corresponding to items. If the item is binary, please code it as 0/1; if the item is ordinal, please code it as integers starting from 1, e.g. 1,2,3. X can be missing at some columns but not the entire row.
#' @param Z the matrix of exogenous variables. Z should not contain any missing data and should have the same number of rows as X. Please do not include intercept here.
#'
#' @return A list containing two elements.
#'
#' @export
#'
#' @examples
#' items_matrix = cbind.data.frame("item1" = rbinom(100, 0,1),
#'                                 "item2" = sample(c(1,2,3), size = 100, replace = TRUE))
#' covariates = cbind.data.frame("age" = runif(100, 10, 50),
#'                              "sex" = rbinom(100, 0, 1))
#' prepare_data(X = items_matrix, Z = covariates)
#'
#'
prepare_data <- function(X,
                         Z
                         ) {

  if(!is.null(Z)) {
    Z = data.frame(Z)
    Z = stats::model.matrix(stats::as.formula(paste0("~",  paste(colnames(Z), collapse = "+"))), data = Z)[,-1]
    Z = cbind.data.frame("Intercept" = rep(1, nrow(X)),
                         Z)
  } else {
    Z = data.frame("Intercept" = rep(1, nrow(X)))
  }
  dat.list <- list("X" = as.matrix(X),
                   "Z" = as.matrix(Z))
  return(dat.list)
}
