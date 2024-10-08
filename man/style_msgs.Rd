% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/styling_functions.R
\name{style_msgs}
\alias{style_msgs}
\title{Apply Custom Style to Text}
\usage{
style_msgs(color_name, text)
}
\arguments{
\item{color_name}{Character. Name of the color to apply. Each color name is associated with a specifically chosen color code. Available options for now are "pink", "blue", "purple", and "green".}

\item{text}{Character. The text string to which the style will be applied.}
}
\value{
The styled text is printed to the console.
}
\description{
This function applies a custom color and bold style to a given text string.
}
\examples{
syncdr:::style_msgs("blue", "This is a styled message.")

}
\keyword{internal}
