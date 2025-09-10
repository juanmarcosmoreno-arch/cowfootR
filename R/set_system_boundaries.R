#' Define system boundaries for carbon footprint calculation
#'
#' @param scope Character. Options:
#'   - "farm_gate" (default): includes enteric, manure, soil, energy, inputs
#'   - "cradle_to_farm_gate": includes feed production + farm emissions
#'   - "partial": user-specified
#' @param include Character vector of processes to include (optional).
#'
#' @return A list with $scope and $include
#' @export
#' @examples
#' b1 <- set_system_boundaries("farm_gate")
#' b2 <- set_system_boundaries(include = c("enteric", "manure", "soil"))
#' b3 <- set_system_boundaries(include = c("enteric", "manure"))
#' b1$scope; b2$include; b3$include
set_system_boundaries <- function(scope = "farm_gate", include = NULL) {

  scope <- match.arg(scope, c("farm_gate", "cradle_to_farm_gate", "partial"))

  if (scope == "farm_gate") {
    defaults <- c("enteric", "manure", "soil", "energy", "inputs")
  } else if (scope == "cradle_to_farm_gate") {
    defaults <- c("feed", "enteric", "manure", "soil", "energy", "inputs")
  } else if (scope == "partial") {
    defaults <- if (is.null(include)) character(0) else include
  }

  # Si el usuario pasa include, sobrescribe; si no, usa defaults
  include <- if (is.null(include)) defaults else include

  list(
    scope = scope,
    include = include
  )
}

