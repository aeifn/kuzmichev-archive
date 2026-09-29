TYPST ?= typst
TYPST_FLAGS = --root . --ignore-system-fonts --font-path template/fonts

TEMPLATE = template/archive.typ $(wildcard template/images/*)

all: completeworks verses letters

completeworks: completeworks/book.pdf
verses: verses/book/book.pdf
letters: letters/book.pdf

completeworks/book.pdf: $(wildcard completeworks/*.typ) $(TEMPLATE)
	$(TYPST) compile $(TYPST_FLAGS) completeworks/book.typ $@

verses/book/book.pdf: $(wildcard verses/book/*.typ) $(TEMPLATE)
	$(TYPST) compile $(TYPST_FLAGS) verses/book/book.typ $@

letters/book.pdf: $(wildcard letters/*.typ) $(TEMPLATE)
	$(TYPST) compile $(TYPST_FLAGS) letters/book.typ $@

# make watch BOOK=verses/book — пересборка при изменениях
watch:
	$(TYPST) watch $(TYPST_FLAGS) $(BOOK)/book.typ

clean:
	rm -f completeworks/book.pdf verses/book/book.pdf letters/book.pdf

.PHONY: all completeworks verses letters watch clean
