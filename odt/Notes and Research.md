Notes and research
==========================

List Styles
-----------

There are multiple ways to define a list style

### A

This came from first tests I made (2023-10).

~~~ .xml

    <text:list-style style:name="List_20_4" style:display-name="List 4">
    
      <text:list-level-style-bullet text:level="1"
        text:style-name="Numbering_20_Symbols"
        loext:num-list-format="%1%" text:bullet-char="➢">
        <style:list-level-properties text:min-label-width="0.4cm"/>
        <style:text-properties style:font-name="StarSymbol"/>
      </text:list-level-style-bullet>
      
      <text:list-level-style-bullet text:level="2"
        text:style-name="Numbering_20_Symbols"
        loext:num-list-format="%2%" text:bullet-char="">
        <style:list-level-properties
          text:space-before="0.401cm"
          text:min-label-width="0.4cm"/>
        <style:text-properties style:font-name="StarSymbol"/>
      </text:list-level-style-bullet>
      
      <text:list-level-style-bullet text:level="3"
        text:style-name="Numbering_20_Symbols"
        loext:num-list-format="%3%" text:bullet-char="">
        <style:list-level-properties
          text:space-before="0.799cm" text:min-label-width="0.4cm"/>
        <style:text-properties style:font-name="StarSymbol"/>
      </text:list-level-style-bullet>
      
      <text:list-level-style-bullet text:level="4"
        text:style-name="Numbering_20_Symbols"
        loext:num-list-format="%4%" text:bullet-char="">
        <style:list-level-properties
          text:space-before="1.2cm" text:min-label-width="0.4cm"/>
        <style:text-properties style:font-name="StarSymbol"/>
      </text:list-level-style-bullet>

    </text:list-style>
    
~~~

### B

This came from proof of concept (2024-02)

~~~ .xml
    <text:list-style style:name="List_20_2" style:display-name="List 2">
    
      <text:list-level-style-bullet text:level="1"
        text:style-name="Numbering_20_Symbols"*
        text:bullet-char="–">
        <style:list-level-properties
          text:list-level-position-and-space-mode="label-alignment">
            <style:list-level-label-alignment
              text:label-followed-by="listtab"
              text:list-tab-stop-position="0.3cm"
              fo:text-indent="-0.3cm" fo:margin-left="0.3cm"/>
        </style:list-level-properties>
        <style:text-properties style:font-name="OpenSymbol"/>
      </text:list-level-style-bullet>
      
      <text:list-level-style-bullet text:level="2"
        text:style-name="Numbering_20_Symbols" text:bullet-char="–">
        <style:list-level-properties
          text:list-level-position-and-space-mode="label-alignment">
          <style:list-level-label-alignment
            text:label-followed-by="listtab"
            text:list-tab-stop-position="0.6cm"
            fo:text-indent="-0.3cm" fo:margin-left="0.6cm"/>
        </style:list-level-properties>
        <style:text-properties style:font-name="OpenSymbol"/>
      </text:list-level-style-bullet>
      
      <text:list-level-style-bullet text:level="3"
        text:style-name="Numbering_20_Symbols" text:bullet-char="–">
        <style:list-level-properties
          text:list-level-position-and-space-mode="label-alignment">
          <style:list-level-label-alignment
            text:label-followed-by="listtab"
            text:list-tab-stop-position="0.9cm"
            fo:text-indent="-0.3cm" fo:margin-left="0.9cm"/>
        </style:list-level-properties>
        <style:text-properties style:font-name="OpenSymbol"/>
      </text:list-level-style-bullet>
      
      <text:list-level-style-bullet text:level="4"
        text:style-name="Numbering_20_Symbols" text:bullet-char="–">
        <style:list-level-properties
          text:list-level-position-and-space-mode="label-alignment">
          <style:list-level-label-alignment
            text:label-followed-by="listtab"
            text:list-tab-stop-position="1.199cm"
            fo:text-indent="-0.3cm" fo:margin-left="1.199cm"/>
        </style:list-level-properties>
        <style:text-properties style:font-name="OpenSymbol"/>
      </text:list-level-style-bullet>
      
    </text:list-style>
    
~~~

Documentation Reference [element-text_list-style](https://docs.oasis-open.org/office/OpenDocument/v1.3/os/part3-schema/OpenDocument-v1.3-os-part3-schema.html#element-text_list-style)

~~~ .xml

<text:list-style
  style:name="List_20_2"
  style:display-name="List 2"
  text:consecutive-numbering="false">	<!-- Numbering is reset at each level -->
  
  <!-- Bullet Lists -->
  <text:list-level-style-bullet
    style:num-prefix=""		<!-- Character before the nummber -->
    style:num-suffix=""		<!-- Character after the nummber -->
    style:num-format="1"		<!-- Sequence style = 1|a|A|i|I -->
    loext:num-list-format="%1%)" <!-- num-suffix is ignored -->
    
    text:bullet-char="•"		<!-- Unicode character to use as a bullet -->
    text:bullet-relative-size="100%"	<!-- Relative size of the bullet -->
    text:level				<!-- List level -->
    text:style-name>			<!-- Style for numbers or bullets -->
    
    <style:list-level-properties
      fo:height="" fo:width=""	<!-- Set absolute size of a bullet -->
      fo:text-align				<!-- start, end, left, right, center or justify>
      style:font-name
      style:vertical-pos style:vertical-rel svg:y	<!-- See doc -->
      text:list-level-position-and-space-mode="label-width-and-position"
      text:min-label-distance
      text:min-label-width
      text:space-before>		<!-- Just adds more margin to the paragraph => No good>
      
      <!-- If text:list-level-position-and-space-mode="label-alignment" -->
      <!-- The definition below is used instead of the three metrics above
      fo:margin-left is ignored if the paragraph style already defines a margin -->
      <style:list-level-label-alignment
        fo:text-indent="" fo:margin-left=""
        text:label-followed-by="listtab"	<!-- listtab, space or nothing -->
        text:list-tab-stop-position=""
        />
        <!-- label position is fo:text-indent+fo:margin-left>
        <!-- used for list paragraph where style do not specify them>
      </style:list-level-label-alignment>
      
    </style:list-level-properties>
    
    <style:text-properties>
      <!-- All the language and font properties -->
    </style:text-properties>
  </text:list-level-style-bullet>
  
  <!-- Icons instead of bullets -->
  <text:list-level-style-image>
  </text:list-level-style-image>
  
  <!-- Ordered Lists -->
  <text:list-level-style-number>
  </text:list-level-style-number>
  
</text:list-style>

~~~

* style:vertical-pos style:vertical-rel svg:y see [https://docs.oasis-open.org/office/OpenDocument/v1.3/os/part3-schema/OpenDocument-v1.3-os-part3-schema.html#property-style_vertical-pos](https://docs.oasis-open.org/office/OpenDocument/v1.3/os/part3-schema/OpenDocument-v1.3-os-part3-schema.html#property-style_vertical-pos)

* text:space-before : not a solution. It adds some margin to the paragraph so paragraph are not aligned. It should be padding instead of margin :-(


### Paragraph styles

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

~~~ .xml

    <style:style style:name="Text_20_body"
      style:display-name="Text body"
      style:family="paragraph"
      style:parent-style-name="Standard"
      style:class="text">
      <!-- What about the style:class ? -->
      <!-- Could use style:list-style-name to specify the list to be used in Text body paragraphs -->
      <style:paragraph-properties
        fo:margin-top="0cm"
        fo:margin-bottom="0.247cm"
        style:contextual-spacing="false"
        fo:line-height="115%"/>
    </style:style>

~~~



* `style:class`: 
   - What is it really about ?
   - Common Values are : `text`, `list`, html`, `index`, extra`
   - Doc says it's "a white separated list of styles" to apply in order
   - Those styles are not explicitly defined.
   - Maybe some LibreOffice trick

* `style:family`
   - Values listed in the doc are : `text`, `paragraph`, `table-cell`. They are related to formatting "inheritance".
   - Aparently `style:default-style` should be defined (explicitly ?) for each familly.
   - See doc [element-style_style](https://docs.oasis-open.org/office/OpenDocument/v1.3/os/part3-schema/OpenDocument-v1.3-os-part3-schema.html#element-style_style)

* `style:next-style-name`: defines next paragraph style if different from current. Is useful when editing in LibreOffice.

Styling paragraph with style:paragraph-properties:

* `fo:line-height`:
	- normal
	- percentage
	- length
	
* `fo:margin`(top|bottom|left|right):
	- percentage
	- length
	
* `fo:padding`(top|bottom|left|right): length

* `fo:orphans` and `fo:widows`: >-1

* `fo:text-align` and `fo:text-align-last`: relative | start | center | end | justify | inside | outside | left | right | inherit

* `fo:line-height` and `style:line-spacing`



* Usefull for later: document field (such as current chapter number and name) are childs of `<tex:p>`


Tables
------
`<table:table-row table:default-cell-style-name="TableHeaderRowCell">` does not work. Attribute ignored ?

Globally tables in Libre Office are shitty. Styles are not really styles. Styles in `styles.xml` are ignored.

You can only use so called "automatic-styles" in `content.xml`.
Those styles can be set via the template variable `$automatic-styles$` (template `open document` or `odt`).