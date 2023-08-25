#
#  render a quarto doc to see if it's something weird from within R that is grabbing the wrong Tex?
#
library(quarto)
quarto_render("test.qmd", output_format = "pdf")
quarto_render("test.qmd", output_format = "docx")

