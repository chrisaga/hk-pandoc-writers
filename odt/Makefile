
hk-reference.odt: hk-reference/*
	cd hk-reference; zip -r ../hk-reference.odt *

#content.xml: README.md odt_hk_writer.lua
#	pandoc  --standalone  --write=odt_hk_writer.lua  -o content.xml README.md

README.odt: hk-reference.odt content.xml README.md
	pandoc --standalone --reference-doc=hk-reference.odt --write=odt_hk_writer.lua -o README.odt README.md
