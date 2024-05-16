pink <- cli::make_ansi_style("#FF1493")
pink("ciao ciao ciao")
cat(pink("ciao ciao ciao"))


style_msgs <- function(color_name,
                       color_code,
                       text,
                       style) {

  style <- match.arg(arg        = style,
                    choices     = c("bold", "underline", "italic"),
                    several.ok  = TRUE)

  # create ANSI style
  color_fun <- cli::make_ansi_style(color_code)

  # Apply color to text
  styled_text <- color_fun(text)

  # return
  style_fun <- get(paste0("cli::style_", style))

  styled_text <- style_fun(text)

  print(styled_text)

  return(styled_text)

}

##############
library(cli)

library(cli)

style_msgs <- function(color_name,
                       #color_code,
                       text,
                       style) {

  # Validate the style argument
  style <- match.arg(arg = style,
                     choices = c("bold", "underline", "italics"),
                     several.ok = TRUE)

  # Validate the color_name argument
  color_name <- match.arg(arg = color_name,
                     choices = c("pink", "blue", "purple", "green"),
                     several.ok = FALSE)

  # Create ANSI style for color

  # color_code <- lapply(color_name, function(x) {
  #   switch(x,
  #          "pink" = "#FF1493",
  #          "blue" = "#a9def9",
  #          "purple" = "#e4c1f9",
  #          "green" = "#00A550")
  # })

  color_code <- switch(color_name,
           "pink" = "#FF1493",
           "blue" = "#007FFF",
           "purple" = "#DF73FF",
           "green" = "#00A550")


  print(color_code)

  color_fun <- cli::make_ansi_style(color_code)
#
# Apply color to text
  styled_text <- color_fun(text)

  # # Apply styles to text using lapply
  # styled_text <- lapply(style, function(s) {
  #   styled_text <<- do.call(paste0("cli::style_", s), list(styled_text))
  # })

  # Since lapply returns a list, we get the last element which is the fully styled text
  #styled_text <- styled_text[[length(styled_text)]]

  # style_text <- do.call(what = paste0("cli::style_", style),
  #                       args = text)

  # Print styled text
  print(styled_text, style)

  # Return styled text
  return(styled_text)
}


# Example usage:
#style_msgs("red", "#FF1493", "This is a test", c("bold", "underline"))

style_msgs(color_name = "green", style = "bold", text = "cundcbuchbv")

