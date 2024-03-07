HK Pandoc  ODT writer
=====================

Context
--------

This is a work in progress attempting to provide a better ODT writer to [Pandoc](https://pandoc.org/).
Indeed, the original writer generates a lot of inline styles in the output ODT ([LibreOffice](https://www.libreoffice.org)/OpenOffice) document. It makes it difficult to customize the output with a reference document (`reference.odt`).

Use case
--------

The typical use case is to write a document in [Markdown](https://daringfireball.net/projects/markdown/) and then render it in PDF (via [LaTex](http://www.latex-project.org/), html, or [ODT](https://en.wikipedia.org/wiki/OpenDocument). The different outputs should look alike.

The ODT version would allow to collaborate on a project with the poor guys out-there who still are stuck with so called WYSIWYG document editors. ;-)

Roadmap
-------

1) Implement the basics (bullet lists and numbered lists) and a clean reference doc as a proof of concept.
2) Implement by iteration all Pandoc objects.
3) Make it "smart" so one could change page size, lang, … of the output document via Pandoc standard mechanism (i.e. with the same reference document).

Pandoc Objects
--------------

### Blocks

#### Bullet lists

[TODO]{.mark}: tight (compact) lists are the same as normal lists :

* This is a

* (Standard) widely spaced

* list

This is a loose bullet list[^cool]:

[^cool]: Footnotes are cool :-)

* Level one

	- Level two

	- Level two again

		+ Level three

			* Level Four

			* Level Four again

		+ Level three again

	- Back to level two

* Back to level one

* Ends with Level one

### Ordered lists

This is a tight ordered list:

1) Level one
	1) Level two
	2) Level two again
		1) Level three
			1) Level Four
			2) Level Four again
		2) Level three again
	3) Back to level two
2) Back to level one
3) Must 
4) Go
5) To
6) Ten
7) Lines
8) To show
9) alignment
10) Ends with Level one

#### Quotation

This is a quotation from the great philosopher Jaegger (as reported by D^r^ Gregory House) :

> You can't always get what you want.

And another from D^r^. Gregory House (MD) :

> Reality is almost always wrong
>
> _House S1E3_

#### Code block

Here is some xml code.

~~~ .xml
    <style:style style:name="Quotations"
      style:family="paragraph"
      style:parent-style-name="Standard"
      style:class="html">
      <!-- What about the style:class ? -->
      <!-- Could use style:list-style-name to specify the list to be used in Quotations paragraphs -->
      <style:paragraph-properties
        fo:margin-left="1cm"
        fo:margin-right="1cm" fo:margin-top="0.25cm"
        fo:margin-bottom="0.25cm" style:contextual-spacing="false"
        fo:text-indent="0in"
        style:auto-text-indent="false" />
    </style:style>
~~~

Some Combinations
-----------------

### List inside quotation

I have found a list-style which render well even in BlockQuotes (Quotations) even if there is some kind of styling such as borders or colored background.

Warning ! Google docs doesn't render well the left border of a block quote with nested lists. It's probably an OpenDocument to Google docs conversion issue.


>This is a tight bullet list:
>
>* Level one
>	- Level two
>	- Level two again
>		+ Level three
>			* Level Four
>			* Level Four again
>		+ Level three again
>	- Back to level two
>* Back to **level one**
>* Ends with Level one
>
>This is a loose ordered list:
>
>1) Level one
>
>	 1) Level two
>
>	 2) Level two again
>
>		1) Level three
>
>			1) Level Four
>
>			2) Level Four again
>
>		2) Level three again
>
>	 3) Back to level two
>
>4) Back to level one
>
>5) Ends with Level one
>


### Inlines

#### Emphasis and strong emphasis

This is _emphasized_. This is **strong**. This is `code`.

#### Strikeout

This text was ~~corrected~~ edited.

#### Subscripts

This is done via Pandoc Markdown. [GitHub Flavored Markdown](https://github.github.com/gfm/) (GFM) doesn't know them and the `~` syntax is equivalent to the `~~` syntax and renders as strikeout (GFM call it strikethrough) text.

When thirsty, drink H~2~O. Don't breathe to much CO~2~


This is a definition list:

Glucose

: C~6~H~12~O~6~

Water

: H~2~O

Methanol

: CH~3~OH

Ethanol

: CH~3~CH~2~OH

Acetic Acid

: CH~3~COOH

#### Underlines, Small caps and Highlight

I cannot [underline]{.underline} enough that [small caps]{.smallcaps} and [highlighting]{.mark} are useful.