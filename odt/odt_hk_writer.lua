--New style writers, available since pandoc 2.17.2
PANDOC_VERSION:must_be_at_least '2.17.2'

local List = require 'pandoc.List'
local debuging=true

local M = {
  span = function(style, content)
      return List:new{pandoc.RawInline('opendocument',
                          '<text:span text:style-name="'
                          .. style .. '">')}
                .. content
                .. List:new{pandoc.RawInline('opendocument','</text:span>')}
  end,

}

--Writer = pandoc.scaffolding.Writer
--
function Writer (doc, opts)
  local filterBQ = {
    Para = function(block)
      local rList = List:new{pandoc.RawBlock('opendocument',
                              '<text:p text:style-name="Quotations">'
                    ..  pandoc.write(pandoc.Pandoc({block}), 'opendocument')
                        :match('^<text:p[^>]+>(.*)</text:p>$')
                    ..  '</text:p>')}
      debug('==============')
      debug(rList)
      debug('--------------')
      return rList
    end,
    Plain = function(block)
      local rList = List:new{pandoc.RawBlock('opendocument',
                              '<text:p text:style-name="Quotations">'
                    ..  pandoc.write(pandoc.Pandoc({block}), 'opendocument')
                        :match('^<text:p[^>]+>(.*)</text:p>$')
                    ..  '</text:p>')}
      debug('==============')
      debug(rList)
      debug('--------------')
      return rList
    end,
  }

  local filter = {
    --[[ Transform everithing in uppercase (for testing only)
    Str = function (str)
      return pandoc.text.upper(str.text)
    end,--]]
    --
    -- Bullet Lists
    BulletList = function(list)
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
    -- Emph
    Emph = function(el)
      return M.span('Emphasis', el.content)
    end,
    Strong = function(el)
      return M.span('Strong_20_Emphasis', el.content)
    end,

  }

  -- write with the default writer
  return pandoc.write(doc:walk(filter), 'opendocument', opts)
end

function Template()
  local template = pandoc.template
  -- Pandoc's doc says to compile but it fails with error
  --return template.compile(template.default('opendocument'))
  return template.default('opendocument')
end

function debug(str)
  if(debuging) then
    print(str)
  end
end
