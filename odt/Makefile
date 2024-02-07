
hk-reference.odt: hk-reference/*
	cd hk-reference; zip -r ../hk-reference.odt *

# Need to generate content.xml and update odtfile afterwards
# because I cannot get to work a custom writer with the odt file
content.xml: README.md odt_hk_writer.lua
	pandoc  --standalone  --write=odt_hk_writer.lua  -o content.xml README.md

README.odt: hk-reference.odt content.xml README.md
	#pandoc --standalone -o README.odt README.md
	pandoc --standalone --reference-doc=hk-reference.odt -o README.odt README.md
	zip README.odt content.xml
