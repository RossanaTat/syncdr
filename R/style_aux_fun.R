#' Apply custom style to text
#'
#' @param color_name name of color to apply (only selected choices for now)
#' @text test string to style
#' @return printed text
#'
#' @keywords internal
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
           "pink" = "#FF1493",
           "blue" = "#00BFFF",
           "purple" = "#BF00FF",
           "green" = "#06d6a0")

  color_fun <- cli::make_ansi_style(color_code)

  #Apply color to text and make it bold
  styled_text <- color_fun(text) |>
    cli::style_bold()

  #todo: apply style

  # Return styled text
  cat(styled_text)
}


# Example usage:
# style_msgs(color_name = "purple", text = "ciao! this is a test")

