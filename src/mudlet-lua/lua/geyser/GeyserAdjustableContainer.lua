--Adjustable Container
--Just use it like a normal Geyser Container with some extras like: 
--moveable, adjustable size, attach to borders, minimizeable, save/load...
--right click on top border for menu
--Inspired heavily by Adjustable Label (by Jor'Mox ) and EMCO (by demonnic )
--by Edru 2020

Adjustable = Adjustable or {}

--- Adjustable Container
-- @class table
-- @name Adjustable.Container
Adjustable.Container = Adjustable.Container or Geyser.Container:new({name = "AdjustableContainerClass"})

local adjustInfo = {}

--- Internal function to add "%" to a value and round it
-- @param num is the value a "%" will be added to
local function make_percent(num)
    num = math.floor(10000*num)/100
    num = tostring(num).."%"
    return num
end

--- Internal function: checks where the mouse is at on the Label 
-- and saves the information for further use at resizing/repositioning
-- also changes the mousecursor for easier use of the resizing/repositioning functionality
-- @param self the Adjustable.Container it self
-- @param label the Label which allows the Container to be adjustable
-- @param event Mouse Click event and its infomations
local function adjust_Info(self, label, event)
    local x, y = getMousePosition()
    local w, h = self.adjLabel:get_width(), self.adjLabel:get_height()
    local x1, y1 = x - event.x, y - event.y
    local x2, y2 = x1 + w, y1 + h
    local left, right, top, bottom = event.x <= 10, x >= x2 - 10, event.y <= 3, y >= y2 - 10
    if right and left then left = false end
    if top and bottom then top = false end
    
    if event.button ~= "LeftButton" and not self.minimized then
        if (top or bottom) and not (left or right) then
            label:setCursor("ResizeVertical")
        elseif (left or right) and not (top or bottom) then
            label:setCursor("ResizeHorizontal")
        elseif (top and left) or (bottom and right) then
            label:setCursor("ResizeTopLeft")
        elseif (top and right) or (bottom and left) then
            label:setCursor("ResizeTopRight")
        else
            label:setCursor("OpenHand")
        end
    end
    
    adjustInfo = {name = adjustInfo.name, top = top, bottom = bottom, left = left, right = right, x = x, y = y, move = adjustInfo.move}
end

--- Internal function: hides the window title if the window gets smaller
-- @param lbl the Label which allows the Container to be adjustable and where the title text is on
local function shrink_title(lbl)
    local  w  =  lbl:get_width()
    local titleText = lbl.titleText
    if #titleText <= 15 then titleText = titleText.."   " end
    if w < (#titleText-10)*6.6+20 then
        titleText = string.sub(lbl.titleText, 0, math.floor(w/6)).."..."
    end
    if #titleText <= 15 then titleText = "" end
    lbl.adjLabel:echo(titleText, lbl.titleTxtColor, "l")
end

--- Internal function: plain Echo which allows text manipulation by stylesheets
-- @param self the menu label itself
-- @param text the text to be shown on the menu label
local function pEcho(self, text)
    if text then
        echo(self.name, text)
    end
end

--- function to give your adjustable container a new title
-- @param text new title text
-- @param color title text color
function Adjustable.Container:setTitle(text, color)
    text = text or self.name.." - Adjustable Container"
    self.titleTxtColor = color or "green"
    self.titleText = "&nbsp;&nbsp;"..text
    shrink_title(self)
end

--- internal function to change the layout of the rightClick menu if we are at the right edge
-- @param labelNest Nested Labels
-- @param fdir flying direction of the label
local function changeMenuLayout(labelNest, fdir)
    if not labelNest then return end
    for k,v in pairs (labelNest) do
        v.flyDir  = fdir
        changeMenuLayout(v.nestedLabels, fdir)
    end
end

--- internal function to handle the onClick event of main Adjustable.Container Label
-- @param label the main Adjustable.Container Label
-- @param event the onClick event and its informations
function Adjustable.Container:onClick(label, event)
    closeAllLevels(self.rCLabel)
    if label.cursorShape == "OpenHand" then
        label:setCursor("ClosedHand")
    end
    if event.button == "LeftButton" and not(self.locked) then
        if self.raiseOnClick then
            self:raiseAll()
        end
        adjustInfo.name = label.name  
        adjustInfo.move = not (adjustInfo.right or adjustInfo.left or adjustInfo.top or adjustInfo.bottom)
        if self.minimized then adjustInfo.move = true end
        adjust_Info(self, label, event)
    end
    if event.button == "RightButton" then
        --if not in the Geyser main window attach Label is not needed and will be removed
        if self.container ~= Geyser and table.index_of(self.rCLabel.nestedLabels, self.attLabel) then       
            table.remove(self.rCLabel.nestedLabels, table.index_of(self.rCLabel.nestedLabels, self.attLabel))
            -- if we are back to the Geyser main window attach Label will be readded
        elseif self.container == Geyser and not table.index_of(self.rCLabel.nestedLabels, self.attLabel) then
            table.insert(self.rCLabel.nestedLabels, table.index_of(self.rCLabel.nestedLabels, self.lockStylesLabel)-1, self.attLabel)
            self.attLabel:changeContainer(Geyser)
        end
        
        if table.index_of(self.rCLabel.nestedLabels, self.customItemsLabel) and not self.customItemsLabel.nestedLabels then
            table.remove(self.rCLabel.nestedLabels, table.index_of(self.rCLabel.nestedLabels, self.customItemsLabel))
        elseif self.rCLabel.nestedLabels[#self.rCLabel.nestedLabels] ~= self.customItemsLabel and self.customItemsLabel.nestedLabels then
            self.rCLabel.nestedLabels[#self.rCLabel.nestedLabels + 1] = self.customItemsLabel
        end
        
        if self.rCLabel.windowname ~= self.customItemsLabel.windowname then
            if self.rCLabel.windowname == "main" then
                self.customItemsLabel:changeContainer(Geyser)
            else
                self.customItemsLabel:changeContainer(Geyser.windowList[self.windowname.."Container"].windowList[self.windowname])
            end
        end
        
        local winw = getUserWindowSize(self.windowname)
        local mousepos = self:get_x() + event.x
        local maxdiff = self.ParentMenuWidth + self.ChildMenuWidth
        local diff = winw - mousepos
        local flyDir = self.rCLabel.nestedLabels[1].flyDir
        if diff <= maxdiff and flyDir == "R"then
            changeMenuLayout(self.rCLabel.nestedLabels, "L")
        elseif diff > maxdiff and flyDir == "L" then
            changeMenuLayout(self.rCLabel.nestedLabels, "R")
        end
        self.rCLabel:move(event.x, event.y)
        doNestShow(self.rCLabel)
    end
end

--- internal function to handle the onRelease event of main Adjustable.Container Label
-- @param label the main Adjustable.Container Label
-- @param event the onRelease event and its informations
function Adjustable.Container:onRelease (label, event)
    if event.button == "LeftButton" and adjustInfo ~= {} and adjustInfo.name == label.name then
        if label.cursorShape == "ClosedHand" then
            label:setCursor("OpenHand")
        end
        adjustInfo = {}
    end
end

--- internal function to handle the onMove event of main Adjustable.Container Label
-- @param label the main Adjustable.Container Label
-- @param event the onMove event and its informations
function Adjustable.Container:onMove (label, event)
    if self.locked then
        if label.cursorShape ~= 0 then 
            label:resetCursor()
        end
        return
    end
    if adjustInfo.move == nil then
        adjust_Info(self, label, event)
    end
    if adjustInfo.x and adjustInfo.name == label.name then
        self:adjustBorder()
        local x, y = getMousePosition()
        local winw, winh = getMainWindowSize()
        local x1, y1, w, h = self.get_x(), self.get_y(), self:get_width(), self:get_height()
        if (self.container) and (self.container ~= Geyser) then
            x1,y1 = x1-self.container.get_x(), y1-self.container.get_y()
            winw, winh = self.container.get_width(), self.container.get_height()
        end
        local dx, dy = adjustInfo.x - x, adjustInfo.y - y
        local max, min = math.max, math.min
        if adjustInfo.move then
            label:setCursor("ClosedHand")
            local tx, ty = max(0,x1-dx), max(0,y1-dy)
            tx, ty = min(tx, winw - w), min(ty, winh - h)
            tx = make_percent(tx/winw)
            ty = make_percent(ty/winh)
            self:move(tx, ty)
            --[[
            -- automated lock on border deactivated for now
            if x1-dx <-5 then self:attachToBorder("left") end
            if y1-dy <-5 then self:attachToBorder("top") end
            if winw - w < tx+0.1 then self:attachToBorder("right") end
            if winh - h < ty+0.1 then self:attachToBorder("bottom") end--]]
        elseif adjustInfo.move == false then
            local w2, h2, x2, y2 = w - dx, h - dy, x1 - dx, y1 - dy
            local tx, ty, tw, th = x1, y1, w, h
            if adjustInfo.top then
                ty, th = y2, h + dy
            elseif adjustInfo.bottom then
                th = h2
            end
            if adjustInfo.left then
                tx, tw = x2, w + dx
            elseif adjustInfo.right then
                tw = w2
            end
            tx, ty, tw, th = max(0,tx), max(0,ty), max(10,tw), max(10,th)
            tw, th = min(tw, winw), min(th, winh)
            tx, ty = min(tx, winw-tw), min(ty, winh-th)
            tx = make_percent(tx/winw)
            ty = make_percent(ty/winh)
            self:move(tx, ty)
            local minw, minh = 0,0
            if self.container == Geyser and not self.noLimit then minw, minh = 75,25 end
            tw,th = max(minw,tw), max(minh,th)
            tw,th = make_percent(tw/winw), make_percent(th/winh)
            self:resize(tw, th)
            shrink_title(self)
        end
        adjustInfo.x, adjustInfo.y = x, y
    end
end

--- internal function to check which valid attach position the container is at
function Adjustable.Container:validAttachPositions()
    local winw, winh = getMainWindowSize()
    local found_positions = {}
    if  (winh*0.8)-self.get_height()<= self.get_y()  then  found_positions[#found_positions+1] = "bottom" end
    if  (winw*0.8)-self.get_width() <= self.get_x() then  found_positions[#found_positions+1] = "right" end
    if self.get_y() <= winh*0.2 then found_positions[#found_positions+1] = "top" end
    if self.get_x() <= winw*0.2 then found_positions[#found_positions+1] = "left" end
    return found_positions
end

--- internal function to adjust the main console borders if needed
function Adjustable.Container:adjustBorder()
    local winw, winh = getMainWindowSize()
    local where = false
    if type(self.attached) == "string" then 
        where = self.attached:lower()
        if table.contains(self:validAttachPositions(), where) == false or self.minimized or self.hidden then self:detach()
        else
            if        where == "right"   then setBorderRight(winw-self.get_x()) 
            elseif  where == "left"    then setBorderLeft(self.get_width()+self.get_x())  
            elseif  where == "bottom"  then setBorderBottom(winh-self.get_y())  
            elseif  where == "top"     then setBorderTop(self.get_height()+self.get_y()) 
            else self.attached= false 
            end
        end
    else
        return false
    end
end

--- internal function to resize the border automatically if the window size changes
function Adjustable.Container:resizeBorder()
    local winw, winh = getMainWindowSize()
    self.timer_active = self.timer_active or true
    -- Check if Window resize already happened. 
    -- If that is not checked this creates an infinite loop and chrashes because setBorder also causes a resize event 
    if (winw ~= self.old_w_value or winh ~= self.old_h_value) and self.timer_active then
        self.timer_active = false
        tempTimer(0.2, function() self:adjustBorder() end)
    end
    self.old_w_value = winw
    self.old_h_value = winh
end

--- attaches your container to the given border
-- @param border possible border values are "top", "bottom", "right", "left"
function Adjustable.Container:attachToBorder(border)
    if self.attached then self:detach() end  
    self.attached = border
    self:adjustBorder()
    self.resizeHandlerID=registerAnonymousEventHandler("sysWindowResizeEvent", function() self:resizeBorder() end)
    closeAllLevels(self.rCLabel)  
end

--- detaches the given container
function Adjustable.Container:detach()  
    self:resetBorder(self.attached)
    self.attached=false
    if self.resizeHandlerID then killAnonymousEventHandler(self.resizeHandlerID) end
end

--- internal function to reset the given border
-- @param where possible border values are "top", "bottom", "right", "left"
function Adjustable.Container:resetBorder(where)
    if        where == "right"   then setBorderRight(0) 
    elseif  where == "left"    then setBorderLeft(0)  
    elseif  where == "bottom"  then setBorderBottom(0)  
    elseif  where == "top"     then setBorderTop(0)
    end
end

--- creates the adjustable label and the container where all the elements will be put in
function Adjustable.Container:createContainers()
    self.adjLabel = Geyser.Label:new({
        x = "0",
        y = "0",
        height = "100%",
        width = "100%",
        name = self.name.."adjLabel"
    },self)
    self.Inside = Geyser.Container:new({
        x = self.padding,
        y = self.padding*2,
        height = "-"..self.padding,
        width = "-"..self.padding,
        name = self.name.."InsideContainer"
    },self)
end

--- locks your adjustable container
-- @param lockNr the number of the lockStyle [optional]
-- @param lockStyle the lockstyle used to lock the container, integrated lockStyles are "standard", "border", "full" and "light"
function Adjustable.Container:lockContainer(lockNr, lockStyle)
    closeAllLevels(self.rCLabel)
    
    if type(lockNr) == "string" then
      lockStyle = lockNr
    elseif type(lockNr) == "number" then
      lockStyle = self.lockStyles[lockNr][1]
    end
    
    lockStyle = lockStyle or self.lockStyle
    if not self.lockStyles[lockStyle] then
      lockStyle = "standard"
    end
    
    self.lockStyle = lockStyle
    
    if self.minimized == false then
        self.lockStyles[lockStyle][2](self)
        self.exitLabel:hide()
        self.minimizeLabel:hide()
        self.locked = true
        self:adjustBorder()
    end
end

---internal function to handle the custom Items onClick event
-- @param customItem the item clicked at
function Adjustable.Container:customMenu(customItem)
    closeAllLevels(self.rCLabel)
    if self.minimized == false then
        self.customItems[customItem][2](self)
    end
end

--- unlocks your previous locked container
function Adjustable.Container:unlockContainer()
    closeAllLevels(self.rCLabel)
    shrink_title(self)
    self.Inside:resize("-"..self.padding,"-"..self.padding)
    self.Inside:move(self.padding, self.padding*2)
    self.adjLabel:setStyleSheet(self.adjLabelstyle)
    self.exitLabel:show()
    self.minimizeLabel:show()
    self.locked = false
end

--- sets the padding of your container
-- @param padding the padding value (standard is 10)
function Adjustable.Container:setPadding(padding)
    self.padding = padding
    if self.locked then
        self:lockContainer()
    else
        self:unlockContainer()
    end 
end

--- internal function: onClick Lock event
function Adjustable.Container:onClickL()
    if self.locked == true then
        self:unlockContainer()
    else
        self:lockContainer()
    end
end

--- internal function: adjusts/sets the borders if an container gets hidden
function Adjustable.Container:hideObj()
    self:hide()
    self:adjustBorder()
end

--- internal function: onClick minimize event
function Adjustable.Container:onClickMin()
    closeAllLevels(self.rCLabel)
    if self.minimized == false then
        self:minimize()
    else
        self:restore()
    end
end

--- internal function: onClick save event
function Adjustable.Container:onClickSave()
    closeAllLevels(self.rCLabel)
    self:save()
end

--- internal function: onClick load event
function Adjustable.Container:onClickLoad()
    closeAllLevels(self.rCLabel)
    self:load()
end

--- minimizes the container
function Adjustable.Container:minimize()
    if self.minimized == false and self.locked == false then
        self.origh = self.height
        self.Inside:hide()
        self:resize(nil, self.buttonsize + 10)
        self.minimized = true
        self:adjustBorder()
    end
end

--- restores the container after it was minimized
function Adjustable.Container:restore()
    if self.minimized == true then
        self.origh = self.origh or "25%"
        self.Inside:show()
        self:resize(nil,self.origh)
        self.minimized = false
        self:adjustBorder()
    end
end

--- internal function to style all labels in a labelnest
-- recursively iterates through all the labelNests
-- @param self the container itself
-- @param labelNest the given LabelNest
local function recursiveStyle(self, labelNest)
    if not labelNest then return end 
    for k,v in pairs (labelNest) do
        v:setStyleSheet(self.menustyle)
        pEcho(v, v.txt)
        recursiveStyle(self, v.nestedLabels)
    end
end

--- internal function to create the menu labels for lockstyle and custom items
-- @param self the container itself
-- @param menu name of the menu
-- @param onClick function which will be executed onClick
local function createMenus(self, menu, onClick)
    self[menu.."l"] = {}
    self[menu.."Nr"] = self[menu.."Nr"] or 1
    if not self[menu] then return end
    for i = self[menu.."Nr"], #self[menu] do
        local name = self[menu][i][1]
        self[menu.."l"][i] = self[menu.."Label"]:addChild({
            width = self.ChildMenuWidth, height = self.MenuHeight, flyOut=true, layoutDir="RV", name = self.name..menu..name
        })
        self[menu.."l"][i].txt = [[<center>]]..name
        self[menu.."l"][i]:setClickCallback(onClick, self, i, name)
    end
    recursiveStyle(self, self[menu.."Label"].nestedLabels)
    self[menu.."Nr"] = #self[menu]
    
end

--- internal function: Handler for the onEnter event of the attach menu
-- the attach menu will be created with the valid positions onEnter of the mouse
function Adjustable.Container:onEnterAtt()
    local attm = self:validAttachPositions()
    self.attLabel.nestedLabels = {}
    for i=1,#attm do
        if self.att[i].container ~= Geyser then
            self.att[i]:changeContainer(Geyser)
        end
        self.att[i].flyDir = self.attLabel.flyDir
        pEcho(self.att[i], "<center>"..attm[i])
        self.att[i]:setClickCallback("Adjustable.Container.attachToBorder", self, attm[i])
        self.attLabel.nestedLabels[#self.attLabel.nestedLabels+1] = self.att[i]
    end
end

--- internal function to create the Minimize/Close and the right click Menu Labels
function Adjustable.Container:createLabels()
    self.exitLabel = Geyser.Label:new({
        x = -(self.buttonsize * 1.4), y=4, width = self.buttonsize, height = self.buttonsize, fontSize = self.buttonFontSize, name = self.name.."exitLabel"
        
    },self)
    self.exitLabel:echo("<center>x</center>")
    
    
    self.minimizeLabel = Geyser.Label:new({
        x = -(self.buttonsize * 2.6), y=4, width = self.buttonsize, height = self.buttonsize, fontSize = self.buttonFontSize, name = self.name.."minimizeLabel"
        
    },self)
    self.minimizeLabel:echo("<center>-</center>")
    
    -- create a label with a nestable=true property to say that it can nest labels
    self.rCLabel = Geyser.Label:new({
    width = "0", height = "0", nestable=true, name = self.name.."rCLabel",
    message="<center>Clicky clicky</center>"}, self)
    
    self.lockLabel = self.rCLabel:addChild({
        width = self.ParentMenuWidth, height = self.MenuHeight, name = self.name.."lockLabel",
        layoutDir="RV", flyOut=true
    })
    
    self.minLabel = self.rCLabel:addChild({
        width = self.ParentMenuWidth, height = self.MenuHeight, name = self.name.."minLabel",
        layoutDir="RV", flyOut=true
        
    })
    
    self.saveLabel = self.rCLabel:addChild({
        width = self.ParentMenuWidth, height = self.MenuHeight, name = self.name.."saveLabel",
        layoutDir="RV", flyOut=true
    })
    
    self.loadLabel = self.rCLabel:addChild({
        width = self.ParentMenuWidth, height = self.MenuHeight, name = self.name.."loadLabel",
        layoutDir="RV", flyOut=true
    })
    
    self.attLabel = self.rCLabel:addChild({
        width = self.ParentMenuWidth, height = self.MenuHeight, nestable = true, flyOut=true, layoutDir="RV", name = self.name.."attLabel"
    })
    
    for i=1,4 do
        self.att[i] = self.attLabel:addChild({
            width = self.ChildMenuWidth, height = self.MenuHeight, layoutDir="RV", name = self.name.."att"..i
        })
    end
    
    self.lockStylesLabel = self.rCLabel:addChild({
        width = self.ParentMenuWidth, height = self.MenuHeight,  nestable = true, flyOut=true, layoutDir="RV", name = self.name.."lockStylesLabel"
    })
    createMenus(self, "lockStyles", "Adjustable.Container.lockContainer")
    
    self.customItemsLabel = self.rCLabel:addChild({
        width = self.ParentMenuWidth, height = self.MenuHeight, nestable = true, flyOut=true, layoutDir="RV", name = self.name.."customItemsLabel"
    })
        
end
    
--- internal function to apply menustyle on all nested Labels    
function Adjustable.Container:styleLabels()
    recursiveStyle(self, self.rCLabel.nestedLabels)
end

--- overriden add function to put every new window to the Inside container
-- @param window derives from the original Geyser.Container:add function
-- @param cons derives from the original Geyser.Container:add function
function Adjustable.Container:add(window,cons)
    if self.goInside then
        self.Inside:add(window, cons)
    else
        Geyser.Container.add(self, window, cons)
    end
end

--- overriden show function to prevent to show the right click menu on show
function Adjustable.Container:show(auto)
    Geyser.Container.show(self, auto)
    closeAllLevels(self.rCLabel)
end

--- saves your container settings
function Adjustable.Container:save()
    local mytable = {}
    mytable.x = self.x
    mytable.y = self.y
    mytable.height= self.height
    mytable.width= self.width
    mytable.minimized= self.minimized
    mytable.origh= self.origh
    mytable.locked = self.locked
    mytable.attached = self.attached
    mytable.lockStyle = self.lockStyle
    mytable.padding = self.padding
    mytable.hidden = self.hidden
    mytable.auto_hidden = self.auto_hidden
    if not(io.exists(getMudletHomeDir().."/AdjustableContainer/")) then lfs.mkdir(getMudletHomeDir().."/AdjustableContainer/") end
    table.save(getMudletHomeDir().."/AdjustableContainer/"..self.name..".lua", mytable)
end

-- loads your container settings
function Adjustable.Container:load()
    local mytable = {}
    
    if io.exists(getMudletHomeDir().."/AdjustableContainer/"..self.name..".lua") then
        table.load(getMudletHomeDir().."/AdjustableContainer/"..self.name..".lua", mytable)
    end
    
    self.lockStyle = mytable.lockStyle or self.lockStyle
    self.padding = mytable.padding or self.padding
    
    if mytable.x then
        self:move(mytable.x, mytable.y)
        self:resize(mytable.width, mytable.height)
        self.minimized = mytable.minimized
        
        if mytable.locked == true then self:lockContainer()  else self:unlockContainer() end
        
        if self.minimized == true then self.Inside:hide() self:resize(nil, self.buttonsize + 10) else self.Inside:show() end
        self.origh = mytable.origh
    end
    
    if mytable.attached then self:attachToBorder(mytable.attached) end
    self:adjustBorder()
    if mytable.auto_hidden or mytable.hidden then
        self:hide()
        if not mytable.hidden then self.hidden = false self.auto_hidden = true end
    else
        self:show()
    end
end

--- overridden reposition function to raise an event of the Adjustable.Container changing position/size
-- it also calls the shrink_title function
-- @see shrink_title
function Adjustable.Container:reposition()
    Geyser.Container.reposition(self)
    raiseEvent("AdjustableContainerReposition", self.name, self.get_width(), self.get_height(), self.get_x(), self.get_y())
    if self.titleText and not(self.locked) then
        shrink_title(self)
    end
end

--- saves all your container
-- @see Adjustable.Container:save()
function Adjustable.Container:saveAll()
    for  k,v in ipairs(Adjustable.Container.all) do
        v:save()
    end
end

--- loads all your container
-- @see Adjustable.Container:load()
function Adjustable.Container:loadAll()
    for  k,v in ipairs(Adjustable.Container.all) do
        v:load()
    end
end

--- shows all your container
-- @see Adjustable.Container:doAll()
function Adjustable.Container:showAll()
    for  k,v in ipairs(Adjustable.Container.all) do
        v:show()
    end
end

--- executes the function myfunc which affects all your containers
-- @param myfunc function which will be executed at all your containers
function Adjustable.Container:doAll(myfunc)
    for  k,v in ipairs(Adjustable.Container.all) do
        myfunc(v)
    end
end

--- changes the values of your container to absolute values
-- @param size_as_absolute bool true to have the size as absolute values
-- @param position_as_absolute bool true to have the position as absolute values
function Adjustable.Container:setAbsolute(size_as_absolute, position_as_absolute)
    if position_as_absolute then
        self.x, self.y = self.get_x(), self.get_y()
    end
    if size_as_absolute then
        self.width, self.height = self.get_width(), self.get_height()
    end
    self:set_constraints(self)
end

--- changes the values of your container to be percentage values
-- only needed if values where set to absolute before
-- @param size_as_percent bool true to have the size as percentage values
-- @param position_as_percent bool true to have the position as percentage values
function Adjustable.Container:setPercent (size_as_percent, position_as_percent)
    local x, y, w, h = self:get_x(), self:get_y(), self:get_width(), self:get_height()
    local winw, winh = getMainWindowSize()
    if (self.container) and (self.container ~= Geyser) then
        x,y = x-self.container.get_x(),y-self.container.get_y()
        winw, winh = self.container.get_width(), self.container.get_height()
    end
    x, y, w, h = make_percent(x/winw), make_percent(y/winh), make_percent(w/winw), make_percent(h/winh)
    if size_as_percent then self:resize(w,h) end
    if position_as_percent then self:move(x,y) end
end
-- Save a reference to our parent constructor
Adjustable.Container.parent = Geyser.Container
-- Create table to put every Adjustable.Container in it
Adjustable.Container.all = Adjustable.Container.all or {}

--- Internal function to create all the standard lockstyles
function Adjustable.Container:globalLockStyles()
    self.lockStyles = self.lockStyles or {}
    self:newLockStyle("standard", function (s) 
        s.Inside:resize("100%",-1)
        s.Inside:move(0, s.padding)
        s.adjLabel:setStyleSheet(string.gsub(s.adjLabelstyle, "(border.-)%d(.-;)","%10%2"))
        s.adjLabel:echo("")
    end)
    
    self:newLockStyle("border",  function (s) 
        s.Inside:resize("-"..s.padding,"-"..s.padding)
        s.Inside:move(s.padding, s.padding)
        s.adjLabel:setStyleSheet(s.adjLabelstyle)
        s.adjLabel:echo("")
    end)
    
    self:newLockStyle("full", function (s) 
        s.Inside:resize("100%","100%")
        s.Inside:move(0,0)
        s.adjLabel:setStyleSheet(string.gsub(s.adjLabelstyle, "(border.-)%d(.-;)","%10%2"))
        s.adjLabel:echo("")
    end)
    
    self:newLockStyle("light", function (s)
        shrink_title(s)
        s.Inside:resize("-"..s.padding,"-"..s.padding)
        s.Inside:move(s.padding, s.padding*2)
        s.adjLabel:setStyleSheet(s.adjLabelstyle)
    end)
end

--- creates a new Lockstyle
-- @param name Name of the menu item/lockstyle
-- @param func function of the new lockstyle
function Adjustable.Container:newLockStyle(name, func)
    self.lockStyles[#self.lockStyles+1] = {name, func}
    self.lockStyles[name] = self.lockStyles[#self.lockStyles]
    if self.lockStylesLabel then
        createMenus(self, "lockStyles", "Adjustable.Container.lockContainer")
    end
end

--- creates a new custom menu item
-- @param name Name of the new menu iten
-- @param func function of the new custom menu item
function Adjustable.Container:newCustomItem(name, func)
    self.customItems = self.customItems or {}
    self.customItems[#self.customItems+1] = {name, func}
    createMenus(self, "customItems", "Adjustable.Container.customMenu")
end

--- constructor for the Adjustable Container
function Adjustable.Container:new(cons,container)
    -- Prevents duplicates to be created
    -- It's still important that the name of the container is unique!
    if cons.name then
        if Geyser.windowList[cons.name] then
            return Geyser.windowList[cons.name]
        end
        if container and container.windowList[cons.name] then
            return container.windowList[cons.name]
        end
    end
    local me = self.parent:new(cons,container)
    setmetatable(me, self)
    self.__index = self
    me.type = "adjustablecontainer"
    me.ParentMenuWidth = me.ParentMenuWidth or "102"
    me.ChildMenuWidth = me.ChildMenuWidth or "82"
    me.MenuHeight = me.MenuHeight or "22"
    me.MenuFontSize = me.MenuFontSize or "8"
    me.buttonsize = me.buttonsize or "15"
    me.buttonFontSize = me.buttonFontSize or "8"
    me.padding = me.padding or 10

    me.adjLabelstyle = me.adjLabelstyle or [[
    background-color: rgba(0,0,0,100%);
    border: 4px double green;
    border-radius: 4px;]]
    me.menustyle = me.menustyle or [[QLabel::hover{ background-color: rgba(0,150,255,100%); color: white;} QLabel::!hover{color: black; background-color: rgba(240,240,240,100%);} QLabel{ font-size:]]..me.MenuFontSize..[[pt;}]]
    me.buttonstyle= me.buttonstyle or [[
    QLabel{ border-radius: 7px; background-color: rgba(255,30,30,100%);}
    QLabel::hover{ background-color: rgba(255,0,0,50%);}
    ]]

    me:globalLockStyles()
    me:createContainers()
    me.att = me.att or {}
    me:createLabels()
    me.minimized =  me.minimized or false
    me.locked =  me.locked or false
    if me.minimized then
        me:minimize()
    end
    if me.locked then
        me:lockContainer()
    end

    me.adjLabelstyle = me.adjLabelstyle..[[ qproperty-alignment: 'AlignLeft | AlignTop';]]
    me.lockLabel.txt = me.lockLabel.txt or [[<font size="5" face="Noto Emoji">🔒</font> Lock/Unlock]]
    me.minLabel.txt = me.minLabel.txt or [[<font size="5" face="Noto Emoji">🗕</font> Min/Restore]]
    me.saveLabel.txt = me.saveLabel.txt or [[<font size="5" face="Noto Emoji">💾</font> Save]]
    me.loadLabel.txt = me.loadLabel.txt or [[<font size="5" face="Noto Emoji">📁</font> Load]]
    me.attLabel.txt  = me.attLabel.txt or [[<font size="5" face="Noto Emoji">⚓</font> Attach to:]]
    me.lockStylesLabel.txt = me.lockStylesLabel.txt or [[<font size="5" face="Noto Emoji">🖌</font> Lockstyle:]]
    me.customItemsLabel.txt = me.customItemsLabel.txt or [[<font size="5" face="Noto Emoji">🖇</font> Custom:]]

    me.adjLabel:setStyleSheet(me.adjLabelstyle)
    me.exitLabel:setStyleSheet(me.buttonstyle)
    me.minimizeLabel:setStyleSheet(me.buttonstyle)
    
    me.rCLabel:setStyleSheet([[background-color: rgba(255,255,255,0%);]])
    me:styleLabels()

    me.adjLabel:setClickCallback("Adjustable.Container.onClick",me, me.adjLabel)
    me.adjLabel:setReleaseCallback("Adjustable.Container.onRelease",me, me.adjLabel)
    me.adjLabel:setMoveCallback("Adjustable.Container.onMove",me, me.adjLabel)
    
    me.minLabel:setClickCallback("Adjustable.Container.onClickMin", me)
    me.saveLabel:setClickCallback("Adjustable.Container.onClickSave", me)
    me.lockLabel:setClickCallback("Adjustable.Container.onClickL", me)
    me.loadLabel:setClickCallback("Adjustable.Container.onClickLoad", me)
    me.origh = me.height
    me.exitLabel:setClickCallback("Adjustable.Container.hideObj", me)
    me.minimizeLabel:setClickCallback("Adjustable.Container.onClickMin", me)
    me.attLabel:setOnEnter("Adjustable.Container.onEnterAtt", me)
    me.goInside = true
    me:adjustBorder()
    me.titleTxtColor = me.titleTxtColor or "green"
    me.titleText = me.titleText or me.name.." - Adjustable Container"
    me.titleText = "&nbsp;&nbsp; "..me.titleText
    shrink_title(me)
    me.lockStyle = me.lockStyle or "standard"
    me.noLimit = me.noLimit or false
    me.raiseOnClick = me.raiseOnClick or true
    -- save a list of all containers in this table
    Adjustable.Container.all[#Adjustable.Container.all+1] = me
    return me
    
end