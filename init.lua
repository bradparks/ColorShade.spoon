local screen = require 'hs.screen'
local drawing = require 'hs.drawing'
local log = require'hs.logger'.new('ColorShade')

local colorShade = {}
colorShade.__index = colorShade

colorShade.name = "ColorShade"
colorShade.version = "0.1"
colorShade.author = "Brad Parks"
colorShade.homepage = "https://github.com/bradparks/ColorShade.spoon"
colorShade.license = "MIT - https://opensource.org/licenses/MIT"

-- global variables
colorShade.shades = {}
colorShade.shadeColor = {}
colorShade.shadeTransparency = {}

function colorShade:startWatchingForMonitorChanges()
  local screenWatcher = hs.screen.watcher.new(function()
    colorShade:reloadShades()
  end)
  screenWatcher:start()
end

function colorShade:setT(index, value)
  colorShade.shadeTransparency[index] = value
end

function colorShade:setC(index, value)
  colorShade.shadeColor[index] = value
end

function colorShade:getTCurrent()
  return colorShade:getT(colorShade:getCurrentScreenIndex())
end

function colorShade:getCCurrent()
  return colorShade:getC(colorShade:getCurrentScreenIndex())
end

function colorShade:setCCurrent(value)
  colorShade.shadeColor[colorShade:getCurrentScreenIndex()] = value
  colorShade:reloadShades()
end

function colorShade:setTCurrent(value)
  colorShade.shadeTransparency[colorShade:getCurrentScreenIndex()] = value
  colorShade:reloadShades()
end

function colorShade:deleteLayout(layoutName)
  local layouts = colorShade:getLayouts()
  layouts[layoutName] = nil
  colorShade:setSetting("layouts", layouts)
end

function colorShade:saveLayout(key)
  local layouts = colorShade:getLayouts()

  local layout = {}
  local screens=screen.allScreens()
  for index,screen in ipairs(screens) do
    local values = {}
    values["t"] = colorShade:getT(index)
    values["c"] = colorShade:getC(index)
    table.insert(layout, values)
  end

  layouts[key] = layout

  colorShade:setSetting("layouts", layouts)
end

function colorShade:reloadShades()
  colorShade:createShades()
end

function colorShade:loadLayout(layoutName)
  local layouts = colorShade:getLayouts()
  local layout = layouts[layoutName]

  local screens=screen.allScreens()
  for index,screen in ipairs(screens) do
    local t = layout[index]["t"]
    local c = layout[index]["c"]
    colorShade:setT(index,t)
    colorShade:setC(index,c)
  end

  colorShade:reloadShades()
end

function colorShade:setCAll(value)
  local screens=screen.allScreens()
  for index,screen in ipairs(screens) do
    colorShade:setC(index,value)
  end

  colorShade:reloadShades()
end

function colorShade:setTAll(value)
  local screens=screen.allScreens()
  for index,screen in ipairs(screens) do
    colorShade:setT(index,value)
  end

  colorShade:reloadShades()
end

function colorShade:getC(index)
  return colorShade:nvl(colorShade.shadeColor[index],hs.drawing.color.black)
end

function colorShade:getT(index)
  return colorShade:nvl(colorShade.shadeTransparency[index], 0)
end

function colorShade:createShades()
  for index,item in ipairs(colorShade.shades) do
    item:delete()
  end
  colorShade.shades = {}

  local screens=screen.allScreens()
  for index,screen in ipairs(screens) do
    local item = hs.drawing.rectangle(screen:fullFrame())
    local c = colorShade:getC(index)
    local t = colorShade:getT(index) 
    c["alpha"] = t
    --item:setFillColor({[c]=1, ["alpha"]=t })
    item:setFillColor(c)
    item:setStroke(true):setFill(true)

    --set to cover the whole monitor, all spaces and expose
    item:bringToFront(true):setBehavior(17)
    if t == 0 then
      item:hide()
    else
      item:show()
    end
    table.insert(colorShade.shades, item)
  end
end

function colorShade:init()
  self.createShades()
end

function colorShade:stop()
  for index,item in ipairs(colorShade.shades) do
    item:hide()
  end
end

function colorShade:bindHotkeys(map)
  local callback = function()
    colorShade:chooseShade()
  end

  local def = {chooseShade = callback}
  hs.spoons.bindHotkeysToSpec(def, map)
end

function colorShade:n(msg, more)
  hs.alert.show(msg)
end

function colorShade:getCurrentScreenIndex(s)
  local screens=screen.allScreens()
  local currentScreen = colorShade:getCurrentScreen(s)
  for index,screen in ipairs(screens) do
    if (currentScreen == screen) then
      return index
    end
  end
  colorShade:n('problem: screen not found!')
end

function colorShade:getCurrentScreen(s)
  return s or hs.mouse.getCurrentScreen() or hs.screen.mainScreen() or hs.screen.primaryScreen()
end

function colorShade:createChoiceSpacer(shouldCreate)
  if false and shouldCreate then
    colorShade:createChoice("", "spacer", "spacer")
  end
end

function colorShade:createChoice(text, t, mode)
  local item = {}
  item["text"] = text
  item["value"] = t
  item["mode"] = mode
  table.insert(colorShade.choices, item)
end

function colorShade:getLayouts()
  return colorShade:getSetting("layouts", {})
end

function colorShade:confirm(title, question, button1, button2)
  button1 = colorShade:nvl(button1, "OK")
  button2 = colorShade:nvl(button2, "Cancel")
  hs.application.launchOrFocus("Hammerspoon")
  local btn = hs.dialog.blockAlert(title, question, button1, button2, "NSWarningAlertStyle")
  local result = (btn == button1)
  return result
end

function colorShade:prompt(title, question, defaultValue)
  hs.application.launchOrFocus("Hammerspoon")
  local btn,result = hs.dialog.textPrompt(title, question, defaultValue, "OK", "Cancel")
  if (btn == "Cancel") then
    return nil
  end
  return result
end

function colorShade:addLoadLayoutChoice(layoutName)
  colorShade:createChoice("load layout: " .. layoutName, layoutName, "colorShade:loadLayout")
end

function colorShade:addDeleteLayoutChoice(layoutName)
  colorShade:createChoice("delete layout: " .. layoutName, layoutName, "colorShade:deleteLayout")
end

function createChoices()
  if (colorShade.choices ~= nil) then
    return colorShade.choices;
  end
  return colorShade:recreateChoices()
end

function colorShade:tableHasItems(T)
  for _ in pairs(T) do 
    return true
  end
  return false
end

function colorShade:recreateChoices()
  colorShade.choices = {}
  local layouts = colorShade:getLayouts()
  local hasLayouts = colorShade:tableHasItems(layouts)

  for layoutName,layout in pairs(layouts) do
    colorShade:addLoadLayoutChoice(layoutName)
  end

  colorShade:createChoiceSpacer(hasLayouts)
  colorShade:createChoice("save layout", nil, "colorShade:saveLayout")

  colorShade:createChoiceSpacer(true)
  colorShade:createChoice("set layout color for all monitors", nil, "colorShade:setLayoutColorAll")
  colorShade:createChoice("set layout color for current monitor", nil, "colorShade:setLayoutColorCurrent")

  colorShade:createChoiceSpacer(true)
  for i = 0, 100 do  
    colorShade:createChoice(i .. "% - all monitors", i/100, "all")
  end

  colorShade:createChoiceSpacer(true)
  for i = 0, 100 do  
    colorShade:createChoice(i .. "% - current monitor" , i/100, "current")
  end

  colorShade:createChoiceSpacer(hasLayouts)
  for layoutName,layout in pairs(layouts) do
    colorShade:addDeleteLayoutChoice(layoutName)
  end

  return colorShade.choices
end

function colorShade:startsWith(data, searchFor)
  local start,finish = self:find(data, searchFor)
  if (start == nil) then
    return false
  end
  if (start == 1) then
    return true
  end
  return false
end

function colorShade:find(input, searchFor, startIndex)
  local result = nil
  local callback = function()
    result = string.find(input, searchFor, startIndex)
  end

  pcall(callback)

  return result
end

function colorShade:matchesNotOperator(subject, searchFor)
  if (searchFor == nil) or (string.len(searchFor) == 1) then
    return false
  end

  if not self:startsWith(searchFor, "!") then
    return false
  end

  local realSearchFor = searchFor:sub(2)
  local result = not self:stringContains(subject, realSearchFor)

  return result
end

function colorShade:stringContains(subject, searchFor)
  local result = nil
  local callback = function()
    result = string.match(subject, searchFor) ~= nil
  end

  pcall(callback)

  return result
end

function colorShade:splitSpace(pString)
  local result = {}  
  for w in pString:gmatch("%S+") do 
     table.insert(result, w) 
  end
  return result
end

function colorShade:getSetting(key, defaultValue)
  local result = hs.settings.get(key)
  if result == nil then
    return defaultValue
  end
  return result
end

function colorShade:setSetting(key, value)
  return hs.settings.set(key, value)
end

function colorShade:matchesQuery(subject, query)
    if colorShade:isMissing(query) then
      return true
    end

    local result = {}
    local keywords = self:splitSpace("" .. query)

    for _, v in ipairs(keywords) do
      if not self:matchesNotOperator(subject, v) then
        if v ~= "!" then
          if not self:stringContains(subject, v) then
            return false
          end
        end
      end
    end

    return true
end

function colorShade:tableToString(tt)
  return hs.json.encode(tt)
end

function colorShade:isMissing(v)
  return not colorShade:isDefined(v)
end

function colorShade:nvl(v, defaultValue)
  if colorShade:isDefined(v) then
    return v
  end
  return defaultValue
end

function colorShade:isDefined(v)
  if (v == nil) then 
    return false
  end

  return (type(v) ~= "string" or string.len(v .. "") > 0)
end

function colorShade:chooseShade()
  local itemSelectedCallback = function(input) 
    if colorShade:isMissing(input) then
      return
    end

    local value = input["value"]
    local mode = input["mode"]

    if mode == "all" then
      colorShade:setTAll(value)
    end

    if mode == "current" then
      colorShade:setTCurrent(value)
    end

    if mode == "colorShade:setLayoutColorAll" then
      local callback = function(a)
        colorShade:setCAll(a)
      end
      colorShade:chooseColor(callback)
    end

    if mode == "colorShade:setLayoutColorCurrent" then
      local callback = function(a)
        colorShade:setCCurrent(a)
      end
      colorShade:chooseColor(callback)
    end

    if mode == "colorShade:saveLayout" then
      local key = colorShade:prompt("Save Layout", "name", "")
      if colorShade:isMissing(key) then
        return
      end

      colorShade:n("Saved layout " .. key)

      colorShade:saveLayout(key)
      colorShade:recreateChoices()
    end

    if mode == "colorShade:loadLayout" then
      colorShade:loadLayout(value)
    end

    if mode == "colorShade:deleteLayout" then
      if colorShade:confirm("Delete layout " .. value, "Proceed?") then
        colorShade:n("Deleted layout " .. value)
        colorShade:deleteLayout(value)
        colorShade:recreateChoices()
      end
    end
  end

  local chooser
  local queryChangedCallback = function (query)
    local choices = createChoices()
    if colorShade:isMissing(query) then
      chooser:choices(choices)
      return
    end

    local pickedChoices = {}
    local q = query:lower()
    for i,j in pairs(choices) do
      local fullText = (j["text"]):lower()
      if colorShade:matchesQuery(fullText, q) then
        table.insert(pickedChoices, j)
      end
    end

    chooser:choices(pickedChoices)
  end

  local choices = createChoices()
  chooser = hs.chooser.new(itemSelectedCallback)
  chooser:queryChangedCallback(queryChangedCallback)
  chooser:choices(choices)
  chooser:placeholderText("ColorShade: " .. (colorShade:getTCurrent() * 100) .. "%") 
  chooser:show();
end

function colorShade:colorChoices(list)
  local result = {}
  for k,v in pairs(list) do 
    local item = {}
    item["text"] = hs.styledtext.new(k, {font={size=18}, color=v})
    item["value"] = v
    table.insert(result, item)
  end
  return result
end

function colorShade:chooseColor(callback)
  local colors = hs.drawing.color.colorsFor("x11")
  local choices = colorShade:colorChoices(colors)

  local localCallback = function(input) 
    if (input ~= nil) then
      callback(input["value"])
    end
  end

  local rightClickCallback = function (index)
    callback(choices[index]["value"])
  end

  local chooser = hs.chooser.new(localCallback)
  chooser:choices(choices)
  chooser:placeholderText("Choose a color, or right click to apply")
  chooser:rightClickCallback(rightClickCallback)
  chooser:show();
end

colorShade:startWatchingForMonitorChanges()

return colorShade
