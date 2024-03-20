# Directories

# Commands
PANDOC := pandoc

hk-reference.odt: hk-reference/*
	cd hk-reference; zip -r ../hk-reference.odt *

#content.xml: README.md odt_hk_writer.lua
#	pandoc  --standalone  --write=odt_hk_writer.lua  -o content.xml README.md

README.odt: hk-reference.odt content.xml README.md

#pandoc --standalone --reference-doc=hk-reference.odt --write=odt_hk_writer.lua -o README.odt README.md

# Target make some tools and references
#

pandoc-reference.odt: README.md
	pandoc -o pandoc-reference.odt --print-default-data-file reference.odt

%.pdf: %.md
	$(PANDOC) --standalone --pdf-engine=pdflatex -o "$@" "$<"

%.pdf: %.native
	$(PANDOC) --standalone --pdf-engine=pdflatex -o "$@" "$<"

%.html: %.native
	$(PANDOC) --standalone -o "$@" "$<"

%.latex: %.md
	$(PANDOC) --standalone -o "$@" "$<"

%.native: %.md
	$(PANDOC) -o "$@" "$<"

%.odt: %.md
	$(PANDOC) --standalone --reference-doc=hk-reference.odt --write=odt_hk_writer.lua -o "$@" "$<"

%.odt: %.native
	$(PANDOC) --standalone --reference-doc=hk-reference.odt --write=odt_hk_writer.lua -o "$@" "$<"
