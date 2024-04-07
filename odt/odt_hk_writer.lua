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
local ftnCount = newCounter()
local inBlockQuote = newCounter()
local inDefList = newCounter()
--------------------------------------------------------------------------------
-- Style to be included as so called "automatic-styles" in the document's
-- content itself. This is needed due to Libre Office's poor table styling system
--------------------------------------------------------------------------------
-- TODO: adjust padding value
-- TODO: check if some inheritance from styles in the reference docis possible
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
local myWriter = pandoc.scaffolding.Writer
myWriter.Inlines = function(inlines) -- Why is this necessary ?
  local string = ''
  for i, el in pairs(inlines) do
    string = string .. myWriter.Inline(el)
  end
  return tostring(string)
end

myWriter.Blocks = function(blocks) -- Why is this necessary ?
  local string = ''
  for i, el in pairs(blocks) do
    string = string .. myWriter.Block(el)
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
  return '<text:note text:id="ftn'
  .. tostring(ftnCount.current())
  .. '" text:note-class="footnote"><text:note-citation>'
  .. tostring(ftnCount.count())
  .. '</text:note-citation><text:note-body><text:p text:style-name="Footnote">'
  .. myWriter.Blocks(el.content)
  .. '</text:p></text:note-body></text:note>'
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
  if inBlockQuote.current() > 0 then
    return M.pStr('Quotations_20_Tight', myWriter.Inlines(block.content))
  elseif inDefList.current() > 0 then
    return M.pStr('List_20_Contents_20_Tight', myWriter.Inlines(block.content))
  else
    return myWriter.Inlines(block.content)
  end
end

myWriter.Block.Para = function(block)
  --[[
  return '<text:p text:style-name="Text_20_body">'
         .. myWriter.Inlines(block.content)
         .. '</text:p>'
         --]]
  local pStyle='Text_20_body'
  --TODO: handle nesting
  if inBlockQuote.current() > 0 then
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
  --[[
  debug(block)
  debug('attr :')
  debug(block.attr)
  debug('identifier')
  debug(block.identifier)
  debug('classes')
  debug(block.classes)
  debug('attributes')
  debug(block.attributes)
  debug(pandoc.write(pandoc.Pandoc({block}), 'opendocument')
        :gsub('<text:p[^>]*>',
              '<text:p text:style-name="' .. block.attributes.pStyle .. '">'))
  ]]--
  -- Use default opendocument writer since it does quite a good job
  -- The paragraph style to bue used has been previously stored in
  -- block.attributes.pStyle
  if block.attributes.pStyle == nil then
    -- TODO: better handle of nesting
    block.attributes.pStyle='Preformatted_20_Text'
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
--------------------------------------------------------------------------------
-- Main Writer function
--
-- Beware ! Must use ByteStringWriter to write odt docs (zipfiles)
-- Writer is OK for flat opendocument (content.xml)
--------------------------------------------------------------------------------
function ByteStringWriter (doc, opts)
  local tableCount = newCounter()
  --
  -- Accessory filter used to write BlockQuote which can contain Para and Plain
  -- blocks (Plain blocks are for tight list items)
  --
  local filterBQ = {
    Para = function(block)
      return M.p("Quotations",
                  myWriter.Inlines(block.content)
      )
    end,
    Plain = function(block)
      return M.p("Quotations_20_tight",
                  myWriter.Inlines(block.content)
      )
    end,
    CodeBlock = function(block)
      block.attributes.pStyle='Quoted_20_Preformatted_20_Text'
      return List:new{pandoc.RawBlock('opendocument',
                     myWriter.Block.CodeBlock(block))}
    end,
  }
  --
  -- Accessory filter used to polish stuf just before writing
  --
  local filterF = {
    Plain = function(block)
      return M.p("Text_20_body_20_tight",
                  myWriter.Inlines(block.content)
      )
    end,
    CodeBlock = function(block)
      block.attributes.pStyle='Preformatted_20_Text'
      return List:new{pandoc.RawBlock('opendocument',
                     myWriter.Block.CodeBlock(block))}
    end,
  }
  --
  -- First filter used to process structures like Tables.
  local filterI = {
    --
    -- Metadata
    Meta = function(meta)
      -- TODO: test if the meta is passed via another way
      meta['automatic-styles']=pandoc.MetaBlocks(
                List:new{pandoc.RawBlock('opendocument',astyles)})
      return meta
    end,
    --
    -- Tables
    Table = function(table)
      tableCount.count()
      local  pStylesHeading= {}
      local  pStylesContents= {}

      local rList
      -- Process table caption if any
      if table.caption.long[1] then
        --TODO: use caption.short if exists
        rList = M.p('Table',
                  'Table <text:sequence text:ref-name="refTable'
                  .. tableCount.current()
                  .. '" text:name="Table" text:formula="ooow:Table+1" style:num-format="1">'
                  .. tableCount.current()
                  .. '</text:sequence>: '
                  .. myWriter.Blocks(table.caption.long))
        table.caption.long = nil
      else
        rList = {}
      end

      -- Start table
      --debug(table.identifier)
      local tableString = '<table:table table:name="Table'
              .. tableCount.current()
              .. '" table:style-name="DefaultTable">\n'
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
              cellStyle='TableBottomRowCell'
            else
              cellStyle='TableRowCell'
            end
            tableString = tableString
                          .. M.row(cellStyle, pStylesContents,
                                   tableContentsStyles, row)
                          .. '\n'
          end
        end
      end
      -- Process TableFoot rows
      -- TODO

      tableString = tableString .. '</table:table>'
      rList = rList .. List:new{pandoc.RawBlock('opendocument', tableString)}

      return rList
    end,
  }
  --
  -- Main filter used to write blocks in xml odt
  --
  local filter = {
    -- Lists : list items are Para blocks in loose lists and Plain blocks in
    --         tight lists.
    --
    -- Bullet Lists
    BulletList = function(list)
      --[[
      debug("---------------")
      debug(list.content)
      debug("---------------")
      --]]
      local rList = List:new{pandoc.RawBlock('opendocument',
                             '<text:list text:style-name="List_20_2">')}
      for i, el in pairs(list.content) do
        rList = rList
            .. List:new{pandoc.RawBlock('opendocument','<text:list-item>')}
            .. el
            .. List:new{pandoc.RawBlock('opendocument','</text:list-item>')}
      end
      rList = rList .. List:new{pandoc.RawBlock('opendocument',
                                                '</text:list>')}
      return rList
    end,
    --
    -- Ordered Lists
    OrderedList = function(list)
      --[[
      debug("---------------")
      debug(list.content)
      debug("---------------")
      --]]
      local rList = List:new{pandoc.RawBlock('opendocument',
                          '<text:list text:style-name="Numbering_20_123">')}
      for i, el in pairs(list.content) do
        rList = rList
            .. List:new{pandoc.RawBlock('opendocument','<text:list-item>')}
            .. el
            .. List:new{pandoc.RawBlock('opendocument','</text:list-item>')}
        --debug('[' .. tostring(i) .. ']' .. pandoc.utils.stringify(el))
      end
      rList = rList .. List:new{pandoc.RawBlock('opendocument',
                                                '</text:list>')}

      --debug(rList)
      return rList
    end,
    --
    -- BlockQuote
    BlockQuote = function(block)
      return pandoc.walk_block(block, filterBQ).content
    end,
    --
    -- Plain (default writer makes them paragraphs)
    Plain = function(block)
      return block
    end,

  } -- end of main filter

  -- Process document
  -- Note: filters function will probably be replaced by something here
  local pList =  List:new{pandoc.RawBlock('opendocument','')}
  for i, el in pairs(doc.blocks) do
    --debug(el.tag)
    if el.tag == 'Para' then
      pList = pList .. {el}
      --debug(el)
      --debug(myWriter.Block[el.tag](el))
    elseif el.tag == 'DefinitionList' then
      --debug(myWriter.Block[el.tag](el))
      pList = pList .. List:new{pandoc.RawBlock('opendocument',
                                                myWriter.Block[el.tag](el))}
    else
      pList = pList .. {el}
    end
  end
  local pDoc = pandoc.Pandoc(pList, doc.meta)

  -- write with the default writer and the filters
  return pandoc.write(pDoc:walk(filterI):walk(filter):walk(filterF), 'odt', opts)
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
