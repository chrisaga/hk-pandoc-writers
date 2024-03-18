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
  }
end
--------------------------------------------------------------------------------
-- Style to be included as so called "automatic-styles" in the document's
-- content itself. This is needed due to Libre Office's poor table styling system
--------------------------------------------------------------------------------
-- TODO:adjust padding value
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
<style:style style:name="TableBottomRowCell" style:family="table-cell">
  <style:table-cell-properties fo:padding="0.1cm"
   fo:border-left="none" fo:border-right="none"
   fo:border-top="none" fo:border-bottom="0.5pt solid #000000"/>
</style:style>
]]
--------------------------------------------------------------------------------
-- Accessory functions used to build odt xml content (might be a Lua module)
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

myWriter.Inline.RawInline = function(inline)
  return inline.text
end

myWriter.Inline.Str = function (str)
  return str.text
end

myWriter.Inline.Space = function ()
  return ' '
end
--[[
Writer.Inline.SoftBreak = function (_, opts)
  return opts.wrap_text == "wrap-preserve"
    and cr
    or space
end
Writer.Inline.LineBreak = cr

Writer.Block.Para = function (para)
  return {Writer.Inlines(para.content), pandoc.layout.blankline}
end
--]]
myWriter.Block.Plain = function(block)
  return myWriter.Inlines(block.content)
end

local M = {
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
    -- TODO: See if wee need to accept Inline contents
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
  cell = function(cellStyle, pStyle, cell)
    local string='      <table:table-cell table:style-name="'
                 .. cellStyle
                 ..'" office:value-type="string">\n        <text:p text:style-name="'
                 .. pStyle .. '">'
                 .. myWriter.Blocks(cell.content)
    return string .. '</text:p>\n      </table:table-cell>\n'
  end,
}

M.row = function(cellStyle, pStyle, row)
  local string='    <table:table-row>\n'
  for i, el in pairs(row.cells) do
    string = string .. M.cell(cellStyle, pStyle, el)
  end
  return string .. '    </table:table-row>'
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
  }
  --
  -- First filter used to process inlines and structures like Tables, BlockQuotes...
  --
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
    -- Inline styles
    Emph = function(el)
      return M.span('Emphasis', el.content)
    end,
    Strikeout = function(el)
      return M.span('Strikeout', el.content)
    end,
    Strong = function(el)
      return M.span('Strong_20_Emphasis', el.content)
    end,
    Subscript = function(el)
      return M.span('Subscript', el.content)
    end,
    Superscript = function(el)
      return M.span('Superscript', el.content)
    end,
    Underline = function(el)
      return M.span('Underline', el.content)
    end,
    SmallCaps = function(el)
      return M.span('SmallCaps', el.content)
    end,
    Code = function(el)
      return M.span('Source_Text', el.text)
    end,
    Quoted = function(el)
      -- TODO: localize quotes
      if el.quotetype == 'DoubleQuote' then
        return pandoc.RawInline('opendocument',
                                 '“' .. myWriter.Inlines(el.content) ..'”')
      else
        return pandoc.RawInline('opendocument',
                                 '‘' .. myWriter.Inlines(el.content) ..'’')
      end
    end,
    --
    -- Inline elements
    SoftBreak = function()
      return pandoc.RawInline('opendocument','<text:line-break/>')
    end,
    --
    -- Tables
    Table = function(table)
      tableCount.count()

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
      --debug(table.colspecs)
      -- TODO: text alignment in colum style doesn't work =>
      -- memorize it and set text style for each cell
      for i, colspec in pairs(table.colspecs) do
        --debug(" " .. i .. " " .. colspec[1]) --ColWidthDefault is nil ???
        tableString = tableString
                      .. '  <table:table-column table:style-name="Table'
                      .. colspec[1] .. '" />\n'
      end
      -- Process TableHead rows
      if(table.head) then
        tableString = tableString .. '  <table:table-header-rows>\n'
        for i, row in pairs(table.head.rows) do
          tableString = tableString
                        .. M.row('TableHeaderRowCell', 'Table_20_Heading', row)
                        .. '\n'
        end
        tableString = tableString  .. '  </table:table-header-rows>\n'
      end
      -- Process TableBody rows
      local cellStyle=''
      local body
      if(table.bodies) then
        for i, b in pairs(table.bodies) do
          cellStyle='TableRowCell'
          body=b.body
          for r, row in pairs(body) do
            if r == #body then
              cellStyle='TableBottomRowCell'
            end
            tableString = tableString
                          .. M.row(cellStyle, 'Table_20_Contents', row)
                        .. '\n'
          end
        end
      end
      -- Process TableFoot rows
      -- TODO

      tableString = tableString .. '</table:table>'
      -- use Pandoc's writer to get the table done
      --debug(table)
      --[[
      local sss=pandoc.write(pandoc.Pandoc({table}), 'opendocument')
            :gsub('^(<[^>]*=")[^"]*','%1DefaultTable')
      --debug('================')
      --debug(tableString)
      debug('================')
      debug(sss)
      debug('================')
      --]]
      --rList = rList .. List:new{pandoc.RawBlock('opendocument', sss)}
      rList = rList .. List:new{pandoc.RawBlock('opendocument', tableString)}

      --debug(rList)
      --debug('================')

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

  -- write with the default writer and the filter
  --debug(doc)
  return pandoc.write(doc:walk(filterI):walk(filter):walk(filterF), 'odt', opts)
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
