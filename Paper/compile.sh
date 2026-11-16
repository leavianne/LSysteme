pdflatex -interaction=nonstopmode main
bibtex -terse main
pdflatex -interaction=nonstopmode main
pdflatex -interaction=nonstopmode main
# das command line interface von pdlatex ist komplett retarded, daher muss man das 4 mal aufrufen, damit die referenzen korrekt gesetzt werden.