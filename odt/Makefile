
hk-reference.odt: hk-reference/*
	cd hk-reference; zip -r ../hk-reference.odt *

#content.xml: README.md odt_hk_writer.lua
#	pandoc  --standalone  --write=odt_hk_writer.lua  -o content.xml README.md

README.odt: hk-reference.odt content.xml README.md
	pandoc --standalone --reference-doc=hk-reference.odt --write=odt_hk_writer.lua -o README.odt README.md

# Target make some tools and references
#

pandoc-reference.odt: README.md
	pandoc -o pandoc-reference.odt --print-default-data-file reference.odt

README.pdf: README.md
	pandoc --standalone --pdf-engine=pdflatex -o README.pdf README.md

README.latex: README.md
	pandoc --standalone -o README.latex README.md

README.ast: README.md
	pandoc -w native -o README.ast README.md

