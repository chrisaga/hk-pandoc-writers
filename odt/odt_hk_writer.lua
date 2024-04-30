--New style writers, available since pandoc 2.17.2
PANDOC_VERSION:must_be_at_least '2.17.2'

local List = require 'pandoc.List'
local debuging=true

--------------------------------------------------------------------------------
-- Create a counter
--------------------------------------------------------------------------------
function newCounter()
  local value=0
  return {
    count = function()
      value=value+1
      return value
    end,
    current = function()
      return value
    end,
    uncount = function()
      value=value-1
      return value
    end,
  }
end
--------------------------------------------------------------------------------
-- Create a stack
--------------------------------------------------------------------------------
function newStack()
  local a={}
  return {
    push = function(v)
      table.insert(a, v)
    end,
    pop = function()
      return table.remove(a)
    end,
    pred = function()
      return a[#a-1]
    end,
    last = function()
      return a[#a]
    end,
  }
end
--------------------------------------------------------------------------------
-- Global counters and stacks
--------------------------------------------------------------------------------
local tableCount = newCounter()
local ftnCount = newCounter()
local inBlockQuote = newCounter()
local inDefList = newCounter()
local parents = newStack()
local environments = newStack()
--------------------------------------------------------------------------------
-- Style to be included as so called "automatic-styles" in the document's
-- content itself. This is needed due to Libre Office's poor table styling system
--------------------------------------------------------------------------------
-- TODO: adjust padding value
-- TODO: check if some inheritance from styles in the reference doc is possible
-- style:parent-style-name attribute
local astyles = [[
<style:style style:name="DefaultTable" style:family="table">
  <style:table-properties
    style:rel-width="80%"
    style:may-break-between-rows="false"
    fo:margin-top="0cm" fo:margin-bottom="0.5cm"
    table:align="center" fo:background-color="transparent">
    <!-- oasis doc says that style:width is mandatory.-->
    <style:background-image/>
  </style:table-properties>
</style:style>
<style:style style:name="TableAlignLeft" style:family="table-column">
  <style:table-column-properties style:use-optimal-column-width="true"/>
  <style:paragraph-properties fo:text-align="left"/>
</style:style>
<style:style style:name="TableAlignCenter" style:family="table-column">
  <style:table-column-properties style:use-optimal-column-width="true"/>
  <style:paragraph-properties fo:text-align="center"/>
</style:style>
<style:style style:name="TableAlignRight" style:family="table-column">
  <style:table-column-properties style:use-optimal-column-width="true"/>
  <style:paragraph-properties fo:text-align="right"/>
</style:style>
<style:style style:name="TableAlignDefault" style:family="table-column">
  <style:table-column-properties style:use-optimal-column-width="true"/>
</style:style>
<style:style style:name="TableHeaderRowCell" style:family="table-cell">
  <style:table-cell-properties fo:padding="0.1cm"
   fo:border-left="none" fo:border-right="none"
   fo:border-top="0.5pt solid #000000" fo:border-bottom="0.5pt solid #000000"/>
</style:style>
<style:style style:name="TableRowCell" style:family="table-cell">
  <style:table-cell-properties fo:padding="0.1cm" fo:border="none"/>
</style:style>
<style:style style:name="TableTopRowCell" style:family="table-cell">
  <style:table-cell-properties fo:padding="0.1cm"
   fo:border-left="none" fo:border-right="none"
   fo:border-bottom="none" fo:border-top="0.5pt solid #000000"/>
</style:style>
<style:style style:name="TableBottomRowCell" style:family="table-cell">
  <style:table-cell-properties fo:padding="0.1cm"
   fo:border-left="none" fo:border-right="none"
   fo:border-top="none" fo:border-bottom="0.5pt solid #000000"/>
</style:style>
<style:style style:name="TableTopBottomRowCell" style:family="table-cell">
  <style:table-cell-properties fo:padding="0.1cm"
   fo:border-left="none" fo:border-right="none"
   fo:border-top="0.5pt solid #000000" fo:border-bottom="0.5pt solid #000000"/>
</style:style>
]]
local tableContentsStyles = {
  AlignDefault = 'Table_20_Contents',
  AlignLeft = 'Table_20_Contents_20_AlignLeft',
  AlignRight = 'Table_20_Contents_20_AlignRight',
  AlignCenter = 'Table_20_Contents_20_AlignCenter',
}
local tableHeadingStyles = {
  AlignDefault = 'Table_20_Heading',
  AlignLeft = 'Table_20_Heading_20_AlignLeft',
  AlignRight = 'Table_20_Heading_20_AlignRight',
  AlignCenter = 'Table_20_Heading_20_AlignCenter',
}
local paraStyles = {
  Note = 'Footnote',
}
--------------------------------------------------------------------------------
-- Declare myWriter in advance since it's used in M (should be fixed)
local myWriter = pandoc.scaffolding.Writer
--------------------------------------------------------------------------------
-- Accessory functions used to build odt xml content (might be a Lua module)
--------------------------------------------------------------------------------
local M = {
  spanStr = function(style, content)
    return '<text:span text:style-name="' .. style .. '">'
           .. content
           .. '</text:span>'
  end,
  pStr = function(style, content)
    return '<text:p text:style-name="' .. style .. '">'
           .. content .. '</text:p>'
  end,

  span = function(style, content)
    if(type(content) == 'string') then
      return List:new{pandoc.RawInline('opendocument',
                          '<text:span text:style-name="'
                          .. style .. '">'
                .. content
                .. '</text:span>')}
    else
      return List:new{pandoc.RawInline('opendocument',
                          '<text:span text:style-name="'
                          .. style .. '">')}
                .. content
                .. List:new{pandoc.RawInline('opendocument','</text:span>')}
    end
  end,
  p = function(style, content)
    if(type(content) == 'string') then
      return List:new{pandoc.RawBlock('opendocument',
                          '<text:p text:style-name="'
                          .. style .. '">'
                  .. content .. '</text:p>')}
    else
      return List:new{pandoc.RawBlock('opendocument',
                          '<text:p text:style-name="'
                          .. style .. '">')}
                  .. content
                  .. List:new{pandoc.RawBlock('opendocument','</text:p>')}
    end
  end,
  cell = function(cellStyle, pStyle, tableStyles, cell)
    return '      <table:table-cell table:style-name="'
           .. cellStyle
           ..'" office:value-type="string">\n        <text:p text:style-name="'
           .. (cell.alignment == 'AlignDefault' and pStyle
                                or tableStyles[cell.alignment])
           .. '">'
           .. myWriter.Blocks(cell.content)
           .. '</text:p>\n      </table:table-cell>\n'
  end,
}

M.row = function(cellStyle, pStyles, tableStyles, row)
  local string='    <table:table-row>\n'
  for i, el in pairs(row.cells) do
    string = string .. M.cell(cellStyle, pStyles[i], tableStyles, el)
  end
  return string .. '    </table:table-row>'
end

--------------------------------------------------------------------------------
-- Writer functions used to build opendocument xml content
--------------------------------------------------------------------------------
myWriter.Inlines = function(inlines)
  local string = ''
  for i, el in pairs(inlines) do
    parents.push(el.tag)
    string = string .. myWriter.Inline(el)
    parents.pop()
  end
  return tostring(string)
end

myWriter.Blocks = function(blocks)
  local string = ''
  for i, el in pairs(blocks) do
    parents.push(el.tag)
    string = string .. myWriter.Block(el)
    parents.pop()
  end
  return tostring(string)
end

myWriter.Inline.Emph = function(el)
  return M.spanStr('Emphasis', myWriter.Inlines(el.content))
end

myWriter.Inline.Strikeout = function(el)
  return M.spanStr('Strikeout', myWriter.Inlines(el.content))
end

myWriter.Inline.Strong = function(el)
  return M.spanStr('Strong_20_Emphasis', myWriter.Inlines(el.content))
end

myWriter.Inline.Subscript = function(el)
  return M.spanStr('Subscript', myWriter.Inlines(el.content))
end

myWriter.Inline.Superscript = function(el)
  return M.spanStr('Superscript', myWriter.Inlines(el.content))
end

myWriter.Inline.Underline = function(el)
  return M.spanStr('Underline', myWriter.Inlines(el.content))
end

myWriter.Inline.SmallCaps = function(el)
  return M.spanStr('SmallCaps', myWriter.Inlines(el.content))
end

myWriter.Inline.Span = function(el)
  if el.classes:includes('mark') then
    return M.spanStr('Highlighted', myWriter.Inlines(el.content))
  elseif #el.classes == 1 then
    -- assume we can transparently pass it as a style name
    return M.spanStr(el.classes[1], myWriter.Inlines(el.content))
  end
end


myWriter.Inline.Code = function(el)
  return M.spanStr('Source_20_Text', myWriter.Inline.Str(el.text))
end

myWriter.Inline.Quoted = function(el)
  -- TODO: localize quotes
  if el.quotetype == 'DoubleQuote' then
    return '“' .. myWriter.Inlines(el.content) ..'”'
  else
    return '‘' .. myWriter.Inlines(el.content) ..'’'
  end
end

myWriter.Inline.Link = function(el)
  -- TODO: check style name
  return '<text:a xlink:type="simple" xlink:href="'
     .. el.target:gsub('&', '&amp;')
     .. '" text:style-name="Internet_20_link" text:visited-style-name="Visited_20_Internet_20_Link">'
     .. myWriter.Inlines(el.content)
     .. '</text:a>'
end

myWriter.Inline.Note = function(el)
  environments.push(el.tag)
  local str = '<text:note text:id="ftn'
  .. tostring(ftnCount.current())
  .. '" text:note-class="footnote"><text:note-citation>'
  .. tostring(ftnCount.count())
  .. '</text:note-citation><text:note-body>'
  .. myWriter.Blocks(el.content)
  .. '</text:note-body></text:note>'
  environments.pop()
  return str
end

myWriter.Inline.Math = function (el)
  return el.text
end

myWriter.Inline.Image = function (el)
  return '[Image not supported yet]'
end

myWriter.Inline.RawInline = function(inline)
  return inline.text
end

myWriter.Inline.Str = function (str)
  if(type(str) == 'string') then
    return str:gsub('&', '&amp;'):gsub('<', '&lt;')
  else
    return str.text:gsub('&', '&amp;'):gsub('<', '&lt;')
  end
end

myWriter.Inline.Space = function ()
  return ' '
end
myWriter.Inline.SoftBreak = function ()
  return ' '
end

myWriter.Inline.LineBreak = function ()
  return '<text:line-break/>'
end

--[[
Writer.Inline.SoftBreak = function (_, opts)
  return opts.wrap_text == "wrap-preserve"
    and cr
    or space
end

Writer.Block.Para = function (para)
  return {Writer.Inlines(para.content), pandoc.layout.blankline}
end
--]]
myWriter.Block.Plain = function(block)
  local pred = parents.pred()
  if inBlockQuote.current() > 0 then
    return M.pStr('Quotations_20_tight', myWriter.Inlines(block.content))
  elseif pred == 'BulletList' or
         pred == 'OrderedList' then
    return M.pStr('Text_20_body_20_tight', myWriter.Inlines(block.content))
  elseif inDefList.current() > 0 then
    return M.pStr('List_20_Contents_20_Tight', myWriter.Inlines(block.content))
  else
    return myWriter.Inlines(block.content)
  end
end

myWriter.Block.Para = function(block)
  local pStyle='Text_20_body'
  --TODO: handle nesting
  --debug(environments.last())
  if environments.last() == 'Note' then
    pStyle=paraStyles.Note
  elseif inBlockQuote.current() > 0 then
    pStyle='Quotations'
  elseif inDefList.current() > 0 then
    pStyle='List_20_Contents'
  end
  return M.pStr(pStyle, myWriter.Inlines(block.content))
end

myWriter.Block.HorizontalRule = function()
  return '<text:p text:style-name="Horizontal_20_Line/">'
end

myWriter.Block.CodeBlock = function(block)
  -- Use default opendocument writer since it does quite a good job
  -- The paragraph style to be used has been previously stored in
  -- block.attributes.pStyle
  if block.attributes.pStyle == nil then
    -- TODO: better handle of nesting
    if inBlockQuote.current() > 0 then
      block.attributes.pStyle='Quoted_20_Preformatted_20_Text'
    else
      block.attributes.pStyle='Preformatted_20_Text'
    end
  end
  return pandoc.write(pandoc.Pandoc({block}), 'opendocument')
        :gsub('<text:p[^>]*>',
              '<text:p text:style-name="' .. block.attributes.pStyle .. '">')
end

myWriter.Block.RawBlock = function(block)
  return block.text
end

myWriter.Block.DefinitionList = function(block)
  inDefList.count()
  local str = ''
  for i, el in pairs(block.content) do
    str = str .. M.pStr('List_20_Heading', myWriter.Inlines(el[1]))
    --debug(el[2])
    for _, blocks in pairs(el[2]) do
      str = str .. myWriter.Blocks(blocks)
    end
  end
  inDefList.uncount()
  return str
end

myWriter.Block.BlockQuote = function(block)
  inBlockQuote.count()
  local str=myWriter.Blocks(block.content)
  inBlockQuote.uncount()
  return str
end

myWriter.Block.OrderedList = function(list)
  --[[ TODO
  list.start
  list.style -- DefaultStyle, Example, Decimal, LowerRoman, UpperRoman, LowerAlpha,
             -- UpperAlpha
  list.delimiter -- DefaultDelim, Period, OneParen, and TwoParens
  --]]
  local str = '<text:list text:style-name="Numbering_20_123">\n'
  for i, el in pairs(list.content) do
    str = str
          .. '<text:list-item>\n'
          .. myWriter.Blocks(el)
          .. '</text:list-item>\n'
  end
  str = str .. '</text:list>\n'
  return str
end

myWriter.Block.BulletList = function(list)
  local str = '<text:list text:style-name="List_20_2">\n'
  for i, el in pairs(list.content) do
    str = str
        .. '<text:list-item>\n'
        ..  myWriter.Blocks(el)
        .. '</text:list-item>\n'
  end
  str = str .. '</text:list>\n'
  return str
end

myWriter.Block.Table = function(table)
      tableCount.count()
      local  pStylesHeading= {}
      local  pStylesContents= {}

  local tableString = ""
  -- Process table caption if any
  if table.caption.long[1] then
    --TODO: use caption.short if exists
    tableString = M.pStr('Table',
                  'Table <text:sequence text:ref-name="refTable'
                  .. tableCount.current()
                  .. '" text:name="Table" text:formula="ooow:Table+1" style:num-format="1">'
                  .. tableCount.current()
                  .. '</text:sequence>: '
                  .. myWriter.Blocks(table.caption.long))
                  .. '\n'
    table.caption.long = nil
  end
  --
  -- Start the Table
  --debug(table.identifier)
  tableString = tableString .. '<table:table table:name="Table'
              .. tableCount.current()
              .. '" table:style-name="DefaultTable">\n'
  --
  -- Process column specifications : alignment and width
  -- TODO: process width
  for i, colspec in pairs(table.colspecs) do
    --debug(" " .. i .. " " .. colspec[1]) --ColWidthDefault is nil ???
    tableString = tableString
                  .. '  <table:table-column table:style-name="Table'
                  .. colspec[1] .. '" />\n'
    -- build list of paragraph styles based on text alignment for each column
    pStylesContents[i]=tableContentsStyles[colspec[1]]
    pStylesHeading[i]=tableHeadingStyles[colspec[1]]
  end
  --
  -- Process TableHead rows
  if(table.head and table.head.rows[1]) then
        tableString = tableString .. '  <table:table-header-rows>\n'
    for i, row in pairs(table.head.rows) do
      tableString = tableString
                    .. M.row('TableHeaderRowCell', pStylesHeading,
                              tableHeadingStyles, row)
                    .. '\n'
    end
      tableString = tableString  .. '  </table:table-header-rows>\n'
    end
  --
  -- Process TableBody rows
  local cellStyle=''
  local body
  if(table.bodies) then
    for i, b in pairs(table.bodies) do
      body=b.body
      for r, row in pairs(body) do
        if( r == 1 and (table.head and not table.head.rows[1])) then
          -- headerless table => style the top row
          if r == #body then
            -- only one row
            cellStyle='TableTopBottomRowCell'
          else
            cellStyle='TableTopRowCell'
          end
        elseif r == #body then
          -- style the bottom row
          -- TODO: test if there is a TableFoot
          cellStyle='TableBottomRowCell'
        else
          cellStyle='TableRowCell'
        end
        tableString = tableString
                      .. M.row(cellStyle, pStylesContents, tableContentsStyles, row)
                      .. '\n'
      end
    end
  end
  --
  -- Process TableFoot rows
  -- TODO

  -- End the Table
  tableString = tableString .. '</table:table>'
  return tableString
end
--------------------------------------------------------------------------------
-- Main Writer function
--
-- Beware ! Must use ByteStringWriter to write odt docs (zipfiles)
-- Writer is OK for flat opendocument (content.xml)
--------------------------------------------------------------------------------
function ByteStringWriter (doc, opts)
  --
  -- Accessory filter used to polish stuf just before writing
  --
  local filterF = {
    Plain = function(block)
      debug('filterF.' .. block.tag)
      debug(block)
      return M.p("Text_20_body_20_tight",
                  myWriter.Inlines(block.content)
      )
    end,
  }
  -- Process document
  -- Note 1: filters function will probably be replaced by something here
  -- Note 2: then it will be possible to have everything in a single RawBlock
  --
  -- Build the block(s)
  local pList =  List:new{pandoc.RawBlock('opendocument','')}
  for i, el in pairs(doc.blocks) do
    if el.tag == 'Para' or
           el.tag == 'DefinitionList' or
           el.tag == 'BulletList' or
           el.tag == 'OrderedList' or
           el.tag == 'CodeBlock' or
           el.tag == 'BlockQuote' or
           el.tag == 'Table' then
      parents.push(el.tag)
      pList = pList .. List:new{pandoc.RawBlock('opendocument',
                                                myWriter.Block[el.tag](el))}
      parents.pop()
    else
      pList = pList .. {el}
    end
  end
  --
  -- Make the Doc
  local pDoc = pandoc.Pandoc(pList, doc.meta)
  pDoc.meta['automatic-styles']=pandoc.MetaBlocks(
                List:new{pandoc.RawBlock('opendocument',astyles)})
  --
  -- Write the doc with the default writer and the filters
  return pandoc.write(pDoc:walk(filterF), 'odt', opts)
end -- of main writer function

--------------------------------------------------------------------------------
-- Assign a default template (required if not set by a CLI option)
--------------------------------------------------------------------------------
function Template()
  local template = pandoc.template
  -- Pandoc's doc says to compile but it fails with error
  --return template.compile(template.default('opendocument'))
  return template.default('odt')
end

--------------------------------------------------------------------------------
function debug(str)
  if(debuging) then
    print(str)
  end
end
