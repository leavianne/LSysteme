@echo off
REM Das command line interface von pdflatex ist etwas umstaendlich, daher muss man es mehrfach aufrufen, damit alle Referenzen korrekt gesetzt werden.

pdflatex -interaction=nonstopmode main
bibtex -terse main
pdflatex -interaction=nonstopmode main
pdflatex -interaction=nonstopmode main

echo.
echo Kompilierung abgeschlossen!
pause
