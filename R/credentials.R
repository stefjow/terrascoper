#' Get Terrascope credentials from environment variables
#'
#' Reads `TERRASCOPE_USER` and `TERRASCOPE_PASS` from environment variables.
#'
#' @return A named list with `user` and `pass`, or `NULL` if not set.
#' @export
terrascope_credentials = function() {
  user = Sys.getenv("TERRASCOPE_USER", "")
  pass = Sys.getenv("TERRASCOPE_PASS", "")

  if (user == "" || pass == "") {
    return(NULL)
  }

  list(user = user, pass = pass)
}
