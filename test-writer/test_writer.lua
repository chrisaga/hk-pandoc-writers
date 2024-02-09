 

function Writer (doc, opts)
  local filter = {
    --[[ Transform everithing in uppercase (for testing only) --]]
    Str = function (str)
      return pandoc.text.upper(str.text)
    end,
  }
  -- write with the default writer
  return pandoc.write(doc:walk(filter), 'opendocument', opts)
end



