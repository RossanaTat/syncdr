#' Apply Custom Style to Text
#'
#' This function applies a custom color and bold style to a given text string.
#'
#' @param color_name Character. Name of the color to apply. Each color name is associated with a specifically chosen color code. Available options for now are "pink", "blue", "purple", and "green".
#' @param text Character. The text string to which the style will be applied.
#' @return The styled text is printed to the console.
#'
#' @keywords internal
#' @examples
#' syncdr:::style_msgs("blue", "This is a styled message.")
#'
style_msgs <- function(color_name,
                       #color_code,
                       #style,
                       text) {

  # Validate the style argument
  # style <- match.arg(arg = style,
  #                    choices = c("bold", "underline", "italics"),
  #                    several.ok = TRUE)

  # Validate the color_name argument
  color_name <- match.arg(arg = color_name,
                          choices = c("pink", "blue", "purple", "green", "orange"),
                          several.ok = FALSE)

  # Create custom ANSI style for colors
  color_code <- switch(color_name,
                       "orange" = "#FE5A1D",
                       "pink"   = "#FF1493",
                       "blue"   = "#00BFFF",
                       "purple" = "#BF00FF",
                       "green"  = "#06d6a0")

  color_fun <- cli::make_ansi_style(color_code)

  #Apply color to text and make it bold
  styled_text <- color_fun(text) |>
    cli::style_bold()

  #todo: apply more styles

  # Return styled text
  cat(styled_text)
}

# Testing new styling functions


#' #' Create style TO COMPLETE DOCUMENTATION
#' #' @param theme character string specifying theme
#' #' @return style list with info on TODO
#' define_theme <- function(theme = "dark") {
#'
#'   .theme <- list()
#'
#'   # Fill list depending on theme
#'   if (theme == "dark") {
#'
#'     .theme$highlight.row.bg <- "#E5E4E2"
#'
#'     .theme$colnames <- list(
#'       bg = "#273BE2",
#'       fg = "#F0F8FF",
#'       decoration = "bold",
#'       align = "center"
#'     )
#'
#'     .theme$type.style <- list(
#'       dateTime = list(fg = "#273BE2"),
#'       logical = list(fg_true = "green", fg_false = "red")
#'     )
#'
#'   } else if (theme == "light") {
#'     .theme$highlight.row.bg <- "#FFFFFF"
#'
#'     .theme$colnames <- list(
#'       bg = "#FFFFFF",
#'       fg = "#000000",
#'       decoration = "bold",
#'       align = "center"
#'     )
#'
#'     .theme$type.style <- list(
#'       dateTime = list(fg = "#000000"),
#'       logical = list(fg_true = "blue", fg_false = "orange")
#'     )
#'   } else {
#'     stop("Unknown theme specified")
#'   }
#'
#'   return(.theme)
#' }
#'
#'
#' # helper function to attach style attribute to df:
#' .set_style <- function(x, style = NULL) {
#'   if (is.null(style)) style <- .get_style()
#'   attr(x, ".style") <- style
#'   x
#' }
#'
#'
#' style_dfs <- function(x, theme = "dark") {
#'
#'   # Ensure x is a data frame or can be coerced into one
#'
#'
#'   # Convert x to data frame if it's not already
#'   x <- as.data.frame(x)
#'
#'   # Get or create the style
#'   style <- define_theme(theme = theme)
#'
#'   # Set the style as an attribute
#'   x <- .set_style(x, style)
#'
#'   return(x)
#' }
#'









