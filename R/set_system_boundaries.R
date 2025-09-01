#' Set system boundaries for carbon footprint calculation
#'
#' Define the scope of the carbon footprint assessment.
#' Options: "farm_gate", "processing", "full_cycle", or custom vector.
#'
#' @param scope Character. Predefined scope ("farm_gate", "processing", "full_cycle")
#'   or custom vector of sources (e.g., c("entero", "manure", "soil", "energy")).
#' @param factors Character. Version of emission factors ("IPCC2006", "IPCC2019").
#'
#' @return A list of class "cf_boundaries" with included and excluded sources.
#' @export
#'
#' @examples
#' set_system_boundaries("farm_gate")
set_system_boundaries <- function(scope = "farm_gate",
                                  factors = "IPCC2019") {

  sources <- list(
    farm_gate   = c("entero", "manure", "soil", "energy", "inputs"),
    processing  = c("entero", "manure", "soil", "energy", "inputs",
                    "transport", "processing"),
    full_cycle  = c("entero", "manure", "soil", "energy", "inputs",
                    "transport", "processing", "packaging", "consumer")
  )

  if (length(scope) == 1 && scope %in% names(sources)) {
    include <- sources[[scope]]
  } else {
    include <- scope
  }

  structure(
    list(
      scope   = scope,
      include = include,
      exclude = setdiff(unlist(sources$full_cycle), include),
      factors = factors,
      date    = Sys.Date()
    ),
    class = "cf_boundaries"
  )
}
