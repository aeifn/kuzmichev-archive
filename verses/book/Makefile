all:pdf

pdf:
	test -f book.toc || pdflatex book.tex
	pdflatex book.tex
clean:
	rm *.pdf *.aux *.log *.toc
