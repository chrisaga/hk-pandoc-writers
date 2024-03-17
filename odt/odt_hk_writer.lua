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
-- Accessory functions used to build odt xml content (might be a Lua module)
--------------------------------------------------------------------------------
local M = {
  span = function(style, content)
    -- TODO: See if wee want to return a single RawInline
    return List:new{pandoc.RawInline('opendocument',
                          '<text:span text:style-name="'
                          .. style .. '">')}
                .. content
                .. List:new{pandoc.RawInline('opendocument','</text:span>')}
  end,
  p = function(style, content)
    -- TODO: See if wee need to accept Inline contents
    return List:new{pandoc.RawBlock('opendocument',
                          '<text:p text:style-name="'
                          .. style .. '">'
                .. content .. '</text:p>')}
  end,
  cell = function(cellStyle, pStyle, cell)
    local string='      <table:table-cell table:style-name="'
                 .. cellStyle ..'">\n'
    return string .. '      </table:table-cell>\n'
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
      --[[
      debug("---------------")
      debug(pandoc.write(pandoc.Pandoc({block.content}), 'opendocument'))
      debug(block.content)
      debug("---------------")
      --]]
      return M.p("Quotations",
                      pandoc.write(pandoc.Pandoc({block}), 'opendocument')
                      :match('^<text:p[^>]+>(.*)</text:p>$')
      )
    end,
    Plain = function(block)
      --[[
      debug("---------------")
      debug(block)
      debug("---------------")
      --]]
      return M.p("Quotations_20_tight",
                      pandoc.write(pandoc.Pandoc({block}), 'opendocument')
                      :match('^<text:p[^>]+>(.*)</text:p>$')
      )
    end,
  }
  --
  -- Accessory filter used to build table captions
  --
  local filterTC = {
    Plain = function(block)
      return M.p("Table",
                  'Table <text:sequence text:ref-name="refTable'
                  .. tableCount.current()
                  .. '" text:name="Table" text:formula="ooow:Table+1" style:num-format="1">'
                  .. tableCount.current()
                  .. '</text:sequence>: ' ..
                  pandoc.write(pandoc.Pandoc({block}), 'opendocument')
                      :match('^<text:p[^>]+>(.*)</text:p>$')
      )
    end,
  }
  filterTC.Para = filterTC.Plain -- in case someday the caption is a Para
  --
  -- Accessory filter used to polish stuf just before writing
  --
  local filterF = {
    Plain = function(block)
      return M.p("Text_20_body_20_tight",
                      pandoc.write(pandoc.Pandoc({block}), 'opendocument')
                      :match('^<text:p[^>]+>(.*)</text:p>$')
      )
    end,
  }
  --
  -- Main filter used to write blocks and inlines in xml odt
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
        debug('[' .. tostring(i) .. ']' .. pandoc.utils.stringify(el))
      end
      rList = rList .. List:new{pandoc.RawBlock('opendocument',
                                                '</text:list>')}

      --debug(rList)
      return rList
    end,
    --
    -- BlockQuote
    BlockQuote = function(block)
      return pandoc.walk_block(block, filterBQ)
    end,
    --
    -- Plain (default writer makes them paragraphs)
    Plain = function(block)
      return block
    end,
    --
    -- Tables
    Table = function(table)
      tableCount.count()
      debug('================')
      debug(tableCount.current())

      local rList
      -- Process table caption if any
      if table.caption.long then
        rList = table.caption.long:walk(filterTC)
        table.caption.long = nil
      else
        rList = {}
      end

      debug(table)
      --[[
      -- Start table
      rList = rList .. List:new{pandoc.RawBlock('opendocument',
      --]]
      debug('<table:table table:name="Table'
              .. tableCount.current()
              .. '" table:style-name="DefaultTable">')
      -- Process column specifications : alignment and width
      --debug(table.colspecs)
      for i, colspec in pairs(table.colspecs) do
        --debug(" " .. i .. " " .. colspec[1]) --ColWidthDefault is nil ???
        debug('  <table:table-column table:style-name="Table'
                 .. colspec[1] .. '" />')
      end
      -- Process TableHead rows
      if(table.head) then
        debug('  <table:table-header-rows>')
        for i, row in pairs(table.head.rows) do
          debug(M.row('TableHeaderRowCell', 'Table_20_Heading', row))
        end
        debug('  </table:table-header-rows>')
      end
      -- Process TableBody rows
      -- Process TableFoot rows
      --[[
      -- End table
      rList = rList .. List:new{pandoc.RawBlock('opendocument',
      --]]
      debug('</table:table>')

      debug('================')
      local sss=pandoc.write(pandoc.Pandoc({table}), 'opendocument')
            :gsub('^(<[^>]*=")[^"]*','%1DefaultTable')
      debug('================')
      debug(sss)
      debug('================')
      rList = rList .. List:new{pandoc.RawBlock('opendocument', sss)}

      debug(rList)
      debug('================')

      return rList
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

  } -- end of main filter

  -- write with the default writer and the filter
  return pandoc.write(doc:walk(filter):walk(filterF), 'odt', opts)
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
