## code to prepare `DATASET` dataset goes here

x <- 1:10
y <- 1:100
z <- runif(50)

usethis::use_data(x, y, internal = TRUE)
