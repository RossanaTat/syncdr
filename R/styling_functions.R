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
                          choices = c("pink", "blue", "purple", "green"),
                          several.ok = FALSE)

  # Create custom ANSI style for colors
  color_code <- switch(color_name,
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


# define_theme <- function(theme = "dark") {
#
#   .theme <- list()
#
#   # Fill list depending on theme
#   if (theme == "dark") {
#
#     .theme$highlight.row.bg <- "#E5E4E2"
#
#     .theme$colnames <- list(
#       bg = "#273BE2",
#       fg = "#F0F8FF",
#       decoration = "bold",
#       align = "center"
#     )
#
#     .theme$type.style <- list(
#       dateTime = list(fg = "#273BE2"),
#       logical = list(fg_true = "green", fg_false = "red")
#     )
#
#   } else if (theme == "light") {
#     .theme$highlight.row.bg <- "#FFFFFF"
#
#     .theme$colnames <- list(
#       bg = "#FFFFFF",
#       fg = "#000000",
#       decoration = "bold",
#       align = "center"
#     )
#
#     .theme$type.style <- list(
#       dateTime = list(fg = "#000000"),
#       logical = list(fg_true = "blue", fg_false = "orange")
#     )
#   } else {
#     stop("Unknown theme specified")
#   }
#
#   return(.theme)
# }
#
#
# # helper function to attach style attribute to df:
# .set_style <- function(x, style = NULL) {
#   if (is.null(style)) style <- .get_style()
#   attr(x, ".style") <- style
#   x
# }
#
#
# style_dfs <- function(x, theme = "dark") {
#
#   # Ensure x is a data frame or can be coerced into one
#
#
#   # Convert x to data frame if it's not already
#   x <- as.data.frame(x)
#
#   # Get or create the style
#   style <- define_theme(theme = theme)
#
#   # Set the style as an attribute
#   x <- .set_style(x, style)
#
#   return(x)
# }
#




# Define the function
print_styled_df <- function(df, style) {
  # Check if the style is a list and has the required elements
  if (!is.list(style)) {
    stop("Style must be a list.")
  }

  # Apply the styles from the list
  fg_color <- ifelse("fg" %in% names(style), style$fg, "default")
  bg_color <- ifelse("bg" %in% names(style), style$bg, "default")
  text_decoration <- ifelse("decoration" %in% names(style), style$decoration, NULL)

  # Create a function to apply the styles to text
  style_text <- function(text, fg, bg, decoration) {
    styled_text <- text
    if (!is.null(fg) && fg != "default") styled_text <- crayon::fg(fg)(styled_text)
    if (!is.null(bg) && bg != "default") styled_text <- crayon::bg(bg)(styled_text)
    if (decoration == "bold") styled_text <- crayon::bold(styled_text)
    # Add more decorations as needed
    return(styled_text)
  }

  # Apply the style_text function to each element of the dataframe
  styled_df <- mapply(style_text, df, MoreArgs = list(fg = fg_color, bg = bg_color, decoration = text_decoration))

  # Print the styled dataframe
  apply(styled_df, 1, function(row) cat(paste(row, collapse = " "), "\n"))
}

# Example usage:
# Create a sample dataframe
sample_df <- data.frame(
  Column1 = 1:3,
  Column2 = letters[1:3]
)

# Define the style list
style_list <- list(fg = "red", bg = "green", decoration = "bold")

# Print the dataframe with the specified style
print_styled_df(sample_df, style_list)









