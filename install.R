RLIB <- "/usr/local/lib/R/site-library/"
install.packages("quarto", lib = RLIB)
install.packages("rmarkdown", lib = RLIB)
install.packages("devtools", lib = RLIB)
install.packages(c("Rcpp", "roxygen2", "learnr", "openintro"), lib = RLIB)
devtools::install_github("rstudio/gradethis", lib = RLIB)
