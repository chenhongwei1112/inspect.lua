-----------------------------------------------------------------------------------------------------------------------
-- inspect.lua - v0.1 (2011-04)
-- Enrique García Cota - enrique.garcia.cota [AT] gmail [DOT] com
-- human-readable representations of tables.
-- inspired by http://lua-users.org/wiki/TableSerialization
-----------------------------------------------------------------------------------------------------------------------

-- public function

-- Apostrophizes the string if it has quotes, but not aphostrophes
-- Otherwise, it returns regular a requilar quoted string
local function smartQuote(str)
  if string.match( string.gsub(str,"[^'\"]",""), '^"+$' ) then
    return "'" .. str .. "'"
  end
  return string.format("%q", str )
end

local controlCharsTranslation = {
  ["\a"] = "\\a",  ["\b"] = "\\b", ["\f"] = "\\f",  ["\n"] = "\\n",
  ["\r"] = "\\r",  ["\t"] = "\\t", ["\v"] = "\\v",  ["\\"] = "\\\\"
}

local function unescapeChar(c) return controlCharsTranslation[c] end

local function unescape(str)
  return string.gsub( str, "(%c)", unescapeChar )
end

local function isIdentifier(str)
  return string.match( str, "^[_%a][_%a%d]*$" )
end

local function isArrayKey(k, length)
  return type(k)=='number' and 1 <= k and k <= length
end

local function isDictionaryKey(k, length)
  return not isArrayKey(k, length)
end

local sortOrdersByType = {
  ['number']   = 1, ['boolean']  = 2, ['string'] = 3, ['table'] = 4,
  ['function'] = 5, ['userdata'] = 6, ['thread'] = 7
}

function sortKeys(a,b)
  local ta, tb = type(a), type(b)
  if ta ~= tb then return sortOrdersByType[ta] < sortOrdersByType[tb] end
  if ta == 'string' or ta == 'number' then return a < b end
  return false
end

local function getDictionaryKeys(t)
  local length = #t
  local keys = {}
  for k,_ in pairs(t) do
    if isDictionaryKey(k, length) then table.insert(keys,k) end
  end
  table.sort(keys, sortKeys)
  return keys
end

local Inspector = {}

function Inspector:new(v)
  local inspector = setmetatable( { buffer = {} }, { 
    __index = Inspector,
    __tostring = function(instance) return table.concat(instance.buffer) end
  } )
  return inspector:addValue(v, 0)
end

function Inspector:puts(...)
  local args = {...}
  for i=1, #args do
    table.insert(self.buffer, tostring(args[i]))
  end
  return self
end

function Inspector:tabify(level)
  self:puts("\n", string.rep("  ", level))
  return self
end

function Inspector:addTable(t, level)
  self:puts('{')
  local length = #t
  local needsComma = false
  for i=1, length do
    if i > 1 then
      self:puts(', ')
      needsComma = true
    end
    self:addValue(t[i], level + 1)
  end

  local dictKeys, k, v = getDictionaryKeys(t)

  for i=1, #dictKeys do
    if needsComma then self:puts(',') end
    needsComma = true
    k = dictKeys[i]
    self:tabify(level+1):addKey(k, level + 1):puts(' = '):addValue(t[k], level + 1)
  end
  
  if #dictKeys > 0 then self:tabify(level) end
  self:puts('}')
  return self
end

function Inspector:addValue(v, level)
  local tv = type(v)

  if tv == 'string' then
    self:puts(smartQuote(unescape(v)))
  elseif tv == 'number' or tv == 'boolean' then
    self:puts(tostring(v))
  elseif tv == 'table' then
    self:addTable(v, level)
  else
    self:puts('<',tv,'>')
  end
  return self
end

function Inspector:addKey(k, level)
  if type(k) == "string" and isIdentifier(k) then
    return self:puts(k)
  end
  return self:puts( "[" ):addValue(k, level):puts("]")
end

local function inspect(t)
  return tostring(Inspector:new(t))
end

return inspect

