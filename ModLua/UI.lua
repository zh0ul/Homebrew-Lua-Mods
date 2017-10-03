UI = {

  Image   = {

      LabelLayouts = {
            [1] = function(self) if not self or not self.label then return ; end ; self.label.transform.anchoredPosition = Vector2(0, self.height)      ; self.label.alignment = TextAnchor.LowerCenter  ; self.label.horizontalOverflow = 0 --[[ HorizontalWrapMode  Wrap=0, Overflow=1 --]] ; self.label.verticalOverflow   = 0 --[[ VerticalWrapMode Truncate=0, Overflow=1 --]] ; end,
            [2] = function(self) if not self or not self.label then return ; end ; self.label.transform.anchoredPosition = Vector2(self.width, 0)       ; self.label.alignment = TextAnchor.MiddleLeft   ; self.label.horizontalOverflow = 0 --[[ HorizontalWrapMode  Wrap=0, Overflow=1 --]] ; self.label.verticalOverflow   = 0 --[[ VerticalWrapMode Truncate=0, Overflow=1 --]] ; end,
            [3] = function(self) if not self or not self.label then return ; end ; self.label.transform.anchoredPosition = Vector2(0, -1 * self.height) ; self.label.alignment = TextAnchor.UpperCenter  ; self.label.horizontalOverflow = 0 --[[ HorizontalWrapMode  Wrap=0, Overflow=1 --]] ; self.label.verticalOverflow   = 0 --[[ VerticalWrapMode Truncate=0, Overflow=1 --]] ; end,
            [4] = function(self) if not self or not self.label then return ; end ; self.label.transform.anchoredPosition = Vector2(-1 * self.width, 0)  ; self.label.alignment = TextAnchor.MiddleRight  ; self.label.horizontalOverflow = 0 --[[ HorizontalWrapMode  Wrap=0, Overflow=1 --]] ; self.label.verticalOverflow   = 0 --[[ VerticalWrapMode Truncate=0, Overflow=1 --]] ; end,
            [5] = function(self) if not self or not self.label then return ; end ; self.label.transform.anchoredPosition = Vector2(0,self.height/2)     ; self.label.transform.pivot = Vector2(0.5, 0.5)            ; self.label.alignment = TextAnchor.MiddleCenter ; self.label.horizontalOverflow = 0 --[[ HorizontalWrapMode  Wrap=0, Overflow=1 --]] ; self.label.verticalOverflow   = 1 --[[ VerticalWrapMode Truncate=0, Overflow=1 --]] ; end,
            [6] = function(self) if not self or not self.label then return ; end ; self.label.transform.pivot = Vector2(0.5, 0.5) ; self.label.alignment = TextAnchor.MiddleCenter ; self.label.horizontalOverflow = 1 --[[ HorizontalWrapMode  Wrap=0, Overflow=1 --]] ; self.label.verticalOverflow   = 1 --[[ VerticalWrapMode Truncate=0, Overflow=1 --]] ; end,
      },
  },

  Line = {},

  Label = {},

}


function UI:Awake()
    print("UI:Awake()")
    if not self then return ; end
    self.debug                 = true
    self.tick                  = 1
    self.userDataPath          = Application.persistentDataPath.."/userData"
    self.appDataPath           = Application.persistentDataPath
    self.ObjectsToDestroy      = {}
    self.updatetotalTime       = 0
    if self.SetupInput        then self:SetupInput()        ; end
    if self.SetupFonts        then self:SetupFonts()        ; end
    if self.SetupTextureCache then self:SetupTextureCache() ; end
    if self.SetupShaders      then self:SetupShaders()      ; end
    if self.GetPlayerAndCam   then self:GetPlayerAndCam()   ; end
end


function UI:Update()
    self:SetCpuTime(true)
    local updatestartTime = os.clock()
    self.tick = self.tick + 1
    self.Input:Update()
    if self.InBuilder and not HBU.InBuilder() then self.InBuilder = false ; TextureCache.rescan = true ; elseif HBU.InBuilder() and not self.InBuilder then self.InBuilder = true ; end
    self.InBuilder = HBU.InBuilder()
    if  TextureCache and TextureCache.Tick and ( not TextureCache.all_vehicle_images_cached or TextureCache.rescan ) then TextureCache:Tick() ; end
    if  self.GetPlayerAndCam then self:GetPlayerAndCam() end
    if  self.RegisteredTicks and self.ProcessRegisteredTicks then self:ProcessRegisteredTicks() ; end
    self.updatetotalTime = self.updatetotalTime + os.clock() - updatestartTime
    self.updateTimeFrame = self.updatetotalTime / self.tick
    self:SetCpuTime(false)
end


function UI:OnDestroy()
    print("UI:OnDestroy()")
    for k,v in pairs(UI.Fonts) do if not Slua.IsNull(v) then GameObject.Destroy(v) ; UI.Fonts[k] = nil ; end ; end
    if not self or not self.ObjectsToDestroy then return end
    for k,v in pairs(self.ObjectsToDestroy) do self:CleanUp(k)  end
    UI = false
end


function UI:Raycast(fromPosition,forwardDirection,castDistance)
  if      not fromPosition     and UI and UI.cam    and UI.cam.position    then fromPosition     = UI.cam.position
  elseif  not fromPosition                                                 then fromPosition     = Camera.main.transform.position
  end
  if      not forwardDirection and UI and UI.cam    and UI.cam.forward     then forwardDirection = UI.cam.forward
  elseif  not forwardDirection                                             then forwardDirection = Camera.main.transform.forward
  end
  castDistance = castDistance or 100000
  return Physics.Raycast(fromPosition, forwardDirection, Slua.out )
end


function UI:RaycastAll(fromPosition,forwardDirection,castDistance)
  if      not fromPosition     and UI and UI.cam    and UI.cam.position    then fromPosition     = UI.cam.position
  elseif  not fromPosition                                                 then fromPosition     = Camera.main.transform.position
  end
  if      not forwardDirection and UI and UI.cam    and UI.cam.forward     then forwardDirection = UI.cam.forward
  elseif  not forwardDirection                                             then forwardDirection = Camera.main.transform.forward
  end
  castDistance = castDistance or 100000
  local rt = {}
  for v in Slua.iter(Physics.RaycastAll(fromPosition, forwardDirection, castDistance)) do rt[#rt+1] = v ; end
  return rt
end


function UI:GetPlayerAndCam()

    if      not self.player        then  self.player = {} ; end

    if      self.player and ( not self.player.player or Slua.IsNull(self.player.player) )  then self.player.player = GameObject.Find("Player") ; end

    if      self.player.player and ( not self.player.transform or Slua.IsNull(self.player.transform) )
    then    self.player.transform = self.player.player.transform
    end

    if      self.player.player and ( not self.player.rigidbody  or  Slua.IsNull(self.player.rigidbody) )
    then    self.player.rigidbody = self.player.player:GetComponent("Rigidbody")
    end

    if      self.player.player and self.player.rigidbody
    then
            self.player.position   = self.player.transform.position
            self.player.rotation   = self.player.transform.rotation
            self.player.velocity   = self.player.rigidbody.velocity
            self.player.forward    = self.player.transform.forward
            self.player.right      = self.player.transform.right
            self.player.up         = self.player.transform.up

    elseif  self.playerPos
    then
            self.player.transform  = false
            self.player.rigidbody  = false
            self.player.position   = false
            self.player.rotation   = false
            self.player.velocity   = false
            self.player.forward    = false
            self.player.right      = false
            self.player.up         = false
    end

    if    not self.cam                                  then self.cam = {} ; end
    if    not self.cam.cam or Slua.IsNull(self.cam.cam) then self.cam.cam = Camera.main ; end
    if    not self.cam.transform                        then self.cam.transform = self.cam.cam.transform ; end

    if      self.cam.cam
    then
            self.cam.position   = self.cam.transform.position
            self.cam.rotation   = self.cam.transform.rotation
            self.cam.forward    = self.cam.transform.forward
            self.cam.right      = self.cam.transform.right
            self.cam.up         = self.cam.transform.up

    elseif  self.cam.position
    then
            self.cam.position   = false
            self.cam.rotation   = false
            self.cam.forward    = false
            self.cam.right      = false
            self.cam.up         = false
    end

end

------------------------------------------------------------------------------------------------------------

function UI:RegisterTick(name,callback)
    if not self and UI and UI.RegisterTick then return UI:RegisterTick(name,callback) ; end
    if  not self.RegisteredTicks then self.RegisteredTicks = {} end
    name = tostring(  name or tostring(debug.getinfo(0).name).."."..tostring(debug.getinfo(0).what).."/"..tostring(debug.getinfo(1).name).."."..tostring(debug.getinfo(1).what).."/"..tostring(debug.getinfo(2).name).."."..tostring(debug.getinfo(2).what).."/" )
    if type(callback) ~= "function" then  if self.RegisteredTicks[name] then return true ; end ; return false ; end
    if    not self.RegisteredTicks[name]
    then  self.RegisteredTicks[name] = #self.RegisteredTicks+1 ; if self.debug then print("UI:RegisterTick : Callback registered for "..name) ; end
    else  if self.debug then print("UI:RegisterTick : Callback updated for "..name) ; end
    end
    self.RegisteredTicks[self.RegisteredTicks[name]] = { callback = callback }
    return true
end


function UI:UnregisterTick(name)
    if not self and UI and UI.RegisterTick then return UI:UnregisterTick(name) ; end
    name = tostring(  name or tostring(debug.getinfo(1).name)..tostring(debug.getinfo(2).name)  )
    if name == "" or not self.RegisteredTicks[name] then return false ; end
    local newRT = {}
    for k,v in pairs(self.RegisteredTicks) do  if type(k) == "string" then if k ~= name then newRT[k] = #newRT+1 ; newRT[#newRT+1] = v ; end ; end ; end
    if self.debug then print("UI:UnregisterTick : Callback unregistered for "..name) ; end
    self.RegisteredTicks = newRT
    return true
end


function UI:IsTickRegistered(name)
    if not self or not self.RegisteredTicks then return false ; end
    name = tostring(  name or tostring(debug.getinfo(0).name).."."..tostring(debug.getinfo(0).what).."/"..tostring(debug.getinfo(1).name).."."..tostring(debug.getinfo(1).what).."/"..tostring(debug.getinfo(2).name).."."..tostring(debug.getinfo(2).what).."/" )
    if self.RegisteredTicks[name] then return true ; end
    return false
end


function UI:ProcessRegisteredTicks()
    if not self or not self.RegisteredTicks then return end
    for k,v in pairs(self.RegisteredTicks) do 
        if    type(k) == "number" and v and v.callback
        then  v.callback()
        end
    end
end

------------------------------------------------------------------------------------------------------------

function UI.Line:RemoveLine(name)
    if not self or not self.Lines or not self.Lights then return ; end
    if not name then name = "" ; end
    local toRemove = {}
    for k,v in pairs(self.Lines) do
        if      name == "ALL"  or  ( name ~= "" and v.name and string.find(v.name,name) )  or  ( v.line and Slua.IsNull(v.line) )
        then    toRemove[#toRemove+1] = k ; if self.Lines[k] and self.Lines[k].line and not Slua.IsNull(self.Lines[k].line) then self:DestroyIfPresent(self.Lines[k],"line",true) ; end ; if self.Lights[k] and self.Lights[k].light and not Slua.IsNull(self.Lights[k].light) then  self:DestroyIfPresent(self.Lights[k],"light",true)   ; end
        end
    end
    for i = #toRemove,1,-1 do
        if self.Lines[toRemove[i]]  then table.remove(self.Lines, toRemove[i]) end
        if self.Lights[toRemove[i]] then table.remove(self.Lights,toRemove[i]) end
    end
end


function UI.Line:CreateLine(parent,name,lineStartColor,lineEndColor,lineWidth,addLight,lightColor,lightRange,lightIntensity)
    if not self then return false ; end
    if not self.Lines  then self.Lines  = {} ; end
    if not self.Lights then self.Lights = {} ; end

    addLight        = addLight        or false
    lineStartColor  = lineStartColor  or Color.red
    lineEndColor    = lineEndColor    or Color.red
    lightColor      = lightColor      or Color.red
    lightRange      = lineRange       or 20
    lightIntensity  = lightIntensity  or 5
    lineWidth       = lineWidth       or 0.1

    if not parent or Slua.IsNull(parent) then if self.parent then parent = self.parent ; else self.parent = GameObject("UI.Line") ; parent = self.parent ; end ; end

    if type(name) ~= "string" or type(name) ~= "number" then name = "Line "..tostring(#self.Lines+1) ; else name = tostring(name) ; end
    local mat                   = Resources.Load("Commons/LineMaterial")
    local line                  = parent:AddComponent("UnityEngine.LineRenderer")
    line.material               = mat
    line.widthMultiplier        = lineWidth
    line.positionCount          = 12
    line.useWorldSpace          = true
    line.startColor             = lineStartColor
    line.endColor               = lineEndColor
    local light                 = parent:AddComponent("UnityEngine.Light")
    light.color                 = lightColor
    light.range                 = lightRange
    light.intensity             = lightIntensity
    light.shadows               = LightShadows.None
    if not self.Lines  then self.Lines  = {} end
    if not self.Lights then self.Lights = {} end
    self.Lines[#self.Lines+1]   = { name = name, line  = line  }
    self.Lights[#self.Lights+1] = { name = name, light = light }
    return self.Lines[#self.Lines]
end


function UI.Line:SetLineColor(col,name)
    col  = col or Color(math.random(0,100000)*0.00001,math.random(0,100000)*0.00001,math.random(0,100000)*0.00001,1)
    name = tostring( name or "" )
    for k,v in pairs(self.Lines) do
        if  v and v.line and ( name == "" or name == "ALL" or name == v.name ) and not Slua.IsNull(v.line)
        then
            v.line.startColor = col
            v.line.endColor   = col
            if self.Lights and self.Lights[k] and self.Lights[k].light and not Slua.IsNull(self.Lights[k].light) then self.Lights[k].light.color = col ; end

        elseif  self.RemoveLine
        then    self:RemoveLine("ALL") ; return
        end
    end
end

------------------------------------------------------------------------------------------------------------

function UI:SetupCpuTime()
    self.cpu              = { new = true, tick = 0, startTime = os.clock(), currentTime = os.clock(), totalTime = 0, updateStart = os.clock(), updateEnd = os.clock(), updateTotal = 0, percent = "0%", timeDelta = Time.deltaTime, fps = 1/Time.deltaTime } 
    if not CPU then CPU = {} ; end
    CPU.UI = self.cpu
end


function UI:SetCpuTime(start)
    if not self then return end
    if not self.cpu then  if self.SetupCpuTime then self:SetupCpuTime() ; end ; return ; end
    if start then self.cpu.tick = self.cpu.tick + 1 ; self.cpu.currentTime = os.clock() ; self.cpu.updateStart = self.cpu.currentTime ; return ; end
    if self.cpu.new then self.cpu.new = false ; return ; end
    self.cpu.updateTotal  = self.cpu.updateTotal + os.clock() - self.cpu.updateStart
    self.cpu.updateFrame  = self.cpu.updateTotal / self.cpu.tick
    self.cpu.deltaTime    = Time.deltaTime
    self.cpu.totalTime    = self.cpu.currentTime - self.cpu.startTime
    self.cpu.fps          = 1/Time.deltaTime
    if   self.cpu.totalTime == 0 then return ; end
    self.cpu.percent = string.format( "%.4f%%",(100/self.cpu.totalTime)*self.cpu.updateTotal )
    return
end


function UI:SetupFonts()
      if not self then return elseif self.Fonts then return self.Fonts ; end
      self.Fonts = {
           Consolas      = Font.CreateDynamicFontFromOSFont({"Consolas"}, 12),
           LucidaConsole = Font.CreateDynamicFontFromOSFont({"Lucida Console"}, 12),
      }
end


function UI:SetupShaders()
  if not self then return elseif self.Shaders then return self.Shaders ; end
  self.Shaders = { Shader.Find("Transparent/Diffuse") }
end

------------------------------------------------------------------------------------------------------------

function UI:SetupTextureCache()

    if  not TextureCache               then  TextureCache = {}               end
    if  not TextureCache.Textures      then  TextureCache.Textures = {}      end
    if  not TextureCache.TextureNames  then  TextureCache.TextureNames = {}  end

    TextureCache.debug                     = true
    TextureCache.cacheDir                  = Application.persistentDataPath.."/userData/img_cache"
    TextureCache.userData                  = Application.persistentDataPath.."/userData"
    TextureCache.rescan                    = false

    HBU.CreateDirectory(TextureCache.cacheDir)
    HBU.CreateDirectory(TextureCache.cacheDir.."/tmp")


    function  TextureCache.file_exists(name)
      if not name then return false ; end
      local f = io.open(name,"r")
      if    f   then  io.close(f)  ;  return true  ;  else  return false  ;  end
    end


    if    string2file and not TextureCache.file_exists(TextureCache.cacheDir.."/texture-cache.txt")
    then  string2file("This directory is targeted as a Texture Cache directory.",TextureCache.cacheDir.."/texture-cache.txt","w")
    end


    function TextureCache:Clear()
        if not TextureCache or not TextureCache.Textures then return ; end
        if self.debug then print("TextureCache:Clear() "..tostring(table.count(TextureCache.Textures)).." textures cleared.") ; end
        local texturesCleared = false
        for k,v in pairs(TextureCache.Textures)     do texturesCleared = true ; if v.texture and type(v.texture) == "userdata" and not Slua.IsNull(v.texture) then  GameObject.Destroy(v.texture) ; end ; end
        for k,v in pairs(TextureCache.TextureNames) do texturesCleared = true ; if v.texture and type(v.texture) == "userdata" and not Slua.IsNull(v.texture) then  GameObject.Destroy(v.texture) ; end ; end
        if texturesCleared then TextureCache.Textures = {} ; TextureCache.TextureNames = {} ; end
        TextureCache.error_texture             = false
        TextureCache.crosshair                 = false
        TextureCache.selection_box             = false
        TextureCache.all_vehicle_images_cached = false
        UI:SetupTextureCache()
    end


    function TextureCache.GetVehicleImageList(filter)
        filter = string.lower(tostring(filter or ""))
        local path = TextureCache.userData or Application.persistentDataPath.."/userData" or ""
        local file_name = path.."/ref.hbr"
        local r    = {}
        local firstFile = ""
        local func = function(inp) if ( not string.find(inp,"[<]Path[>]Vehicle/") and not string.find(inp,"/Vehicle/") ) or not string.find(inp,"[.][Pp][Nn][Gg]") or not string.find(inp,"Vehicle/") or ( filter and filter ~= "" and not string.find(string.lower(inp),filter) ) then return end ; inp = string.gsub(inp,"<[^>]*>","") ; local name = string.gsub(inp,".*/","") ; name = string.upper(name:sub(1,1))..name:sub(2) ; inp = string.gsub(inp,"/[^/]*$","/")..name ; r[#r+1] = path.."/"..inp ; end
      --forLineIn(file_name,func,suppressBlankLines,trimEdgeWhiteSpace,trimAllWhiteSpace)
        forLineIn(file_name,func,true,              true,              false)
        if r[1] then firstFile = r[1] ; end
        table.sort(r)
        r.firstFile = firstFile
        return r
    end


    function TextureCache.GetImageHash(file_name)
        local r = ""
        if type(file_name) == "string"
        then
            if not TextureCache.file_exists(file_name) then print("TextureCache.GetImageHash() : ERROR : File does not exist: "..file_name) ; return r ; end
            local f = io.open(file_name,"rb")
            if not f then print("TextureCache.GetImageHash() : ERROR : Could not open file: "..file_name)  ; return r ; end
            local current = f:seek()      -- get current position
            local size = f:seek("end")    -- get file size
            f:seek("set", current)        -- restore position
            for j = 1,4 do  if  f:seek("set",128+(16*(j-1))) then  for i = 1,4 do  r = r..string.format( "%02X", string.byte(f:read(1) or " ")  )  ; end ; end ; end
            io.close(f)
            return r

        elseif type(file_name) == "userdata" and string.find(tostring(file_name),"Texture2D") and file_name.width and file_name.height
        then
            local texture = file_name
            local h,huge = { 0,0,0,0, }, 70368744177664
            for x = 0,texture.width-1 do
            for y = 0,texture.height-1 do
                local p  = texture:GetPixel(x,y)
                local i  = (x+(x*y))%#h+1
                local j  = ((x+(x*y))%(#h*2)+1)%2+1
                h[i] = ( h[i] + p.r*j*2^24 + p.g*j*2^16 + p.b*j*2^8 + p.a*j ) % huge
            end
            end
            r = r..string.format("%08X%08X%08X%08X", h[1],h[2],h[3],h[4] )
            return r
        else
            return tostring(r)
        end
    end


    function TextureCache.ScaleTexture( texIn, nWidth, nHeight, transColor )
        if      TextureCache.debug then print("TextureCache.ScaleTexture : Enter function.") ; end
        if      type(transColor) == "nil" or ( type(transColor) == "boolean" and transColor ) then transColor = 0.35294118523597717 ; end
        if      type(texIn) == "string" and file_exists and file_exists(texIn)
        then    texIn = HBU.LoadTexture2D(texIn) ; if type(texIn) ~= "userdata" then if TextureCache.debug then print("TextureCache.ScaleTexture : texIn is not userdata (1) : "..type(texIn)) ; end ; return texIn end
        elseif  type(texIn) ~= "userdata" or not texIn.format or not texIn.height or not texIn.width
        then    if TextureCache.debug then print("TextureCache.ScaleTexture : texIn is not userdata (2) : "..type(texIn)) ; end ; return texIn
        end
        nWidth,nHeight = nWidth or 256, nHeight or 256
        local oWidth,oHeight = texIn.width,texIn.height
        local texOut = Texture2D.Instantiate(Texture2D.blackTexture)
        if not texOut or type(texOut) ~= "userdata" then return texIn end
        texOut:Resize(nWidth,nHeight)
        for y = 0,nHeight-1 do
        for x = 0,nWidth-1  do
            local vx,vy = math.min( oWidth, math.floor(oWidth/nWidth*x) ), math.min( oHeight, math.floor(oHeight/nHeight*y) )
            local p = texIn:GetPixel(vx,vy)
            if transColor and p.r == transColor and p.g == transColor and p.b == transColor then   p.a = 0   end
            texOut:SetPixel(x, y, p)
        end
        end
        texOut:Apply()
        GameObject.Destroy(texIn)
        if TextureCache.debug then print("TextureCache.ScaleTexture : Exit  function.") ; end
        return texOut
    end


    function TextureCache.CropTexture( texIn, x1, y1, x2, y2, transColor )
        if      TextureCache.debug then print("TextureCache.CropTexture : Enter function.") ; end
        if      type(transColor) == "nil" or ( type(transColor) == "boolean" and transColor ) then transColor = 0.35294118523597717 ; end
        if      type(texIn) == "string" and file_exists and file_exists(texIn)
        then    texIn = HBU.LoadTexture2D(texIn) ; if type(texIn) ~= "userdata" then if TextureCache.debug then print("TextureCache.CropTexture : texIn is not userdata (1) : "..type(texIn)) ; end ; return texIn end
        elseif  type(texIn) ~= "userdata" or not texIn.format or not texIn.height or not texIn.width
        then    if TextureCache.debug then print("TextureCache.CropTexture : texIn is not userdata (2) : "..type(texIn)) ; end ; return texIn
        end
        if      type(x1) == "number" then x1 = x1-(x1%1)
        elseif  type(x1) == "string" and x1:sub(-1) == "%" and tonumber(x1:sub(1,-2)) and tonumber(x1:sub(1,-2)) ~= 0 then x1 = math.floor( texIn.width / (100/tonumber(x1:sub(1,-2))) )
        else    x1 = 0
        end
        if      type(y1) == "number" then y1 = y1-(y1%1)
        elseif  type(y1) == "string" and y1:sub(-1) == "%" and tonumber(y1:sub(1,-2)) and tonumber(y1:sub(1,-2)) ~= 0 then y1 = math.floor( texIn.height / (100/tonumber(y1:sub(1,-2))) )
        else    y1 = 0
        end
        if      type(x2) == "number" then x2 = x2-(x2%1)
        elseif  type(x2) == "string" and x2:sub(-1) == "%" and tonumber(x2:sub(1,-2)) and tonumber(x2:sub(1,-2)) ~= 0 then x2 = math.floor( texIn.width / (100/tonumber(x2:sub(1,-2))) )
        else    x2 = texIn.width
        end
        if      type(y2) == "number" then y2 = y2-(y2%1)
        elseif  type(y2) == "string" and y2:sub(-1) == "%" and tonumber(y2:sub(1,-2)) and tonumber(y2:sub(1,-2)) ~= 0 then y2 = math.floor( texIn.height / (100/tonumber(y2:sub(1,-2))) )
        else    y2 = texIn.height
        end
        local oWidth,oHeight = texIn.width,texIn.height
        local nWidth,nHeight = math.min(texIn.width-x1, x2 - x1), math.min(texIn.height-y1, y2 - y1)
        if    oWidth < nWidth  or oHeight < nHeight then return texIn ; end
        if    TextureCache.debug then print( "TextureCache.CropTexture : Original Width/Height: "..tostring(oWidth).."/"..tostring(oHeight) ) ; end
        if    TextureCache.debug then print( "TextureCache.CropTexture : New      Width/Height: "..tostring(nWidth).."/"..tostring(nHeight) ) ; end
        local texOut = Texture2D.Instantiate(Texture2D.blackTexture)
        if not texOut or type(texOut) ~= "userdata" then return texIn end
        texOut:Resize(nWidth,nHeight)
        texOut:SetPixels(texIn:GetPixels(x1,y1,nWidth,nHeight))
        -- for y = 0,nHeight-1 do
        -- for x = 0,nWidth-1  do
        --     texOut:SetPixel(x, y, texIn:GetPixel(x+x1,y+y1))
        -- end
        -- end
        texOut:Apply()
        GameObject.Destroy(texIn)
        if TextureCache.debug then print("TextureCache.CropTexture : Exit  function.") ; end
        return texOut
    end


    function TextureCache.SetTextureColorTransparent(texture,transColor)
        if    not texture or type(texture) ~= "userdata" or Slua.IsNull(texture) or not texture.height or not texture.width then if TextureCache.debug then print("TextureCache.SetTextureColorTransparent : Exit Fast.") ; end ; return texture ; end
        if    (  type(transColor) == "nil" )
        or    (  type(transColor) == "boolean" and transColor  )
        then  transColor = 0.35294118523597717
        end
        for y = 0, texture.height-1 do
        for x = 0, texture.width-1  do
            local p = texture:GetPixel(x,y)
            if  p  and  transColor  and  p.r == transColor and p.g == transColor and p.b == transColor
            then
                p.a = 0
                texture:SetPixel(x, y, p)
            end
        end
        end
        texture:Apply()
        return texture
    end


    function TextureCache.IsInCacheDir(file_name)
        if type(file_name) ~= "string" or file_name == "" then return false ; end
        if not string.find(file_name,"/") then file_name = TextureCache.cacheDir.."/"..file_name ; end
        if    TextureCache.file_exists(file_name) and string.find(string.lower(file_name),string.lower(TextureCache.cacheDir))
        then  return true,  file_name
        else  return false, file_name
        end
    end


    function TextureCache.AddTexture(...)

        local t = { id = false, file_name_short = false,  file_name = false,  file_cache = false,  file_source = false,  file_hash = false,  texture = false }
        local temporaryNameHolder = ""

        for k,v in pairs({...}) do
            if    type(v) == "string"
            then
                    local   file_name_short = string.gsub(v,"[\\]","/") ; file_name_short = string.gsub( file_name_short,".*/","" ) ; file_name_short = string.gsub(file_name_short,"_[Ii][Mm][Gg][.][Pp][Nn][Gg]$","") ; file_name_short = string.gsub(file_name_short,"[.][Pp][Nn][Gg]$","")

                    if      (  string.find(v,"[\\/]")  and TextureCache.file_exists(v) )
                    then
                            v = string.gsub(v,"[\\]","/")

                            if      TextureCache.IsInCacheDir(v)
                            then
                                    t.file_cache = v
                                    t.file_source = v
                                    if #file_name_short == 32 and not string.find(file_name_short,"[a-zG-Z]") then t.file_hash = file_name_short ; end
                            else
                                    t.file_name  = v
                                    t.file_hash  = TextureCache.GetImageHash(v)
                                    t.file_cache = TextureCache.cacheDir.."/"..t.file_hash..".png"
                                    if      TextureCache.file_exists(t.file_cache)
                                    then    t.file_source = t.file_cache
                                    else    t.file_source = v
                                    end
                            end

                    elseif  TextureCache.IsInCacheDir(TextureCache.cacheDir.."/"..v)
                    then
                            v = string.gsub(TextureCache.cacheDir.."/"..v,"[\\]","/")
                            t.file_source = v
                            t.file_cache  = v
                    else
                            temporaryNameHolder = v
                    end


            elseif  type(v) == "userdata" and string.find( tostring(v), "Texture2D" )
            then
                    if    v.width > 256 or v.height > 256
                    then  t.texture = TextureCache.ScaleTexture(v,256,256,true)
                    else  t.texture = TextureCache.SetTextureColorTransparent(v)
                    end
            end
        end

        if      t.texture and not t.file_name and not t.file_cache and not t.file_source and not t.file_name_short
        then
                if temporaryNameHolder == "" then temporaryNameHolder = TextureCache.GetImageHash(t.texture) ; end
                t.file_name       = temporaryNameHolder
                t.file_cache      = TextureCache.cacheDir.."/"..temporaryNameHolder..".png"
                t.file_source     = temporaryNameHolder
                t.file_name_short = temporaryNameHolder
                t.file_hash       = temporaryNameHolder
        end

        if      not t.file_name and t.file_cache and TextureCache.IsInCacheDir(t.file_cache)
        then
                t.file_name       = t.file_cache
                t.file_source     = t.file_cache
                local   file_name_short = string.gsub( t.file_cache,".*/","" )
                file_name_short   = string.gsub(file_name_short,"_[Ii][Mm][Gg].[Pp][Nn][Gg]$","")
                file_name_short   = string.gsub(file_name_short,".[Pp][Nn][Gg]$","")
                t.file_hash       = file_name_short
                t.file_name_short = file_name_short
        end

        if      t.file_name and TextureCache.TextureNames[t.file_name] then t.id = TextureCache.TextureNames[t.file_name].id ; end -- if not t.texture and t.file_hash and TextureCache.TextureNames[t.file_name].file_hash and t.file_hash == TextureCache.TextureNames[t.file_name].file_hash and TextureCache.TextureNames[t.file_name].texture and type(TextureCache.TextureNames[t.file_name].texture) == "userdata" and not Slua.IsNull(TextureCache.TextureNames[t.file_name].texture) then return TextureCache.TextureNames[t.file_name].id ; end ; end

        if      t.id and t.file_name and t.file_hash
        and     TextureCache.TextureNames[t.file_name]
        and     TextureCache.TextureNames[t.file_name].file_hash
        and     t.file_hash == TextureCache.TextureNames[t.file_name].file_hash
        and     TextureCache.TextureNames[t.file_name].texture
        and     type(TextureCache.TextureNames[t.file_name].texture) == "userdata"
        and     not Slua.IsNull(TextureCache.TextureNames[t.file_name].texture)
        then    return TextureCache.TextureNames[t.file_name].id
        end

        if      t.file_name and not t.file_name_short
        then
                local file_name_short = string.gsub( t.file_name,".*/","" )
                file_name_short = string.gsub(file_name_short,"_[Ii][Mm][Gg].[Pp][Nn][Gg]$","")
                file_name_short = string.gsub(file_name_short,".[Pp][Nn][Gg]$","")
                t.file_name_short = file_name_short
        end

        if      not t.file_hash and t.file_name and string.find(t.file_name,"/") and TextureCache.file_exists(t.file_name)
        then
                t.file_hash  = TextureCache.GetImageHash(t.file_name)
                t.file_cache = TextureCache.cacheDir.."/"..t.file_hash..".png"
                if TextureCache.file_exists(t.file_cache)
                then t.file_source = t.file_cache
                else t.file_source = t.file_name
                end
        end

        if      not t.texture  and  t.file_source and t.file_cache and t.file_source == t.file_cache and TextureCache.IsInCacheDir(t.file_cache)
        then
                t.texture   = HBU.LoadTexture2D(t.file_cache)
                if t.texture
                then
                    local file_hash = string.gsub( t.file_cache,".*/","" )
                    file_hash = string.gsub(file_hash,"_[Ii][Mm][Gg].[Pp][Nn][Gg]$","")
                    file_hash = string.gsub(file_hash,".[Pp][Nn][Gg]$","")
                    t.file_hash = file_hash
                end
        end

        if      not t.texture  and  t.file_source  and  TextureCache.file_exists(t.file_source)
        then
                t.file_hash   = TextureCache.GetImageHash(t.file_source)
                t.file_cache  = TextureCache.cacheDir.."/"..t.file_hash..".png"

                if    TextureCache.IsInCacheDir(t.file_cache)
                then
                      if not t.file_name then  t.file_name   = t.file_source  ; end
                      t.file_source = t.file_cache
                      t.texture     = HBU.LoadTexture2D(t.file_cache)
                else
                      t.texture = HBU.LoadTexture2D(t.file_source)
                      if not t.file_name then t.file_name = t.file_source ; end
                end

                if      t.texture  and  t.texture.width  and  t.texture.height  and  ( t.texture.width > 256 or t.texture.height > 256 )
                then    t.texture = TextureCache.ScaleTexture(t.file_source,256,256,true)
                elseif  t.texture  and  t.file_source ~= t.file_cache
                then    t.texture = TextureCache.SetTextureColorTransparent(t.texture)
                end
        end

        if      t.texture and t.texture.wrapMode then t.texture.wrapMode = 1 ; end

        if      not t.texture and TextureCache.GetErrorTexture then t.texture = TextureCache.GetErrorTexture ; end

        if      t.texture  and TextureCache.TextureNames[t.file_name]
        then
                if type( TextureCache.TextureNames[t.file_name].texture) == "userdata" then GameObject.Destroy(TextureCache.TextureNames[t.file_name].texture) ; end
                t.id                                                   = TextureCache.TextureNames[t.file_name].id
                TextureCache.TextureNames[t.file_name].file_hash       = t.file_hash
                TextureCache.TextureNames[t.file_name].file_cache      = t.file_cache
                TextureCache.TextureNames[t.file_name].texture         = t.texture
                TextureCache.TextureNames[t.file_name].file_name_short = t.file_name_short
                TextureCache.TextureNames[t.file_name].file_source     = t.file_source
                if TextureCache.debug then print( "TextureCache.AddTexture : Updated existing  : "..tostring(t.file_name).." : id = "..tostring(t.id) ) ; end

        elseif  t.texture
        then
                t.file_name = t.file_name or t.file_cache or t.file_source
                if not t.file_name then   if TextureCache.debug then print("TextureCache.AddTexture : ERROR : Texture given with no file_name or file_cache") ; echo(t) ; end ; return 0 ; end
                t.id = #TextureCache.Textures+1
                TextureCache.Textures[t.id] = t
                TextureCache.TextureNames[t.file_name] = TextureCache.Textures[t.id]
                if TextureCache.debug then print( "TextureCache.AddTexture : Created new entry : "..tostring(t.file_name).." : id = "..tostring(t.id) ) ; end
        end

        if    not t.file_cache and t.file_hash
        then  t.file_cache = TextureCache.cacheDir.."/"..t.file_hash..".png"
        end

        if t.texture and t.file_cache and t.file_cache ~= t.file_source and string.find(t.file_cache,"[/]") then HBU.SaveTexture2D(t.texture, t.file_cache) ; end

        return t.id

    end

    function TextureCache:Tick()
          if TextureCache and TextureCache.all_vehicle_images_cached and not TextureCache.rescan then return ; end
          for k,v in pairs( TextureCache.GetVehicleImageList() ) do if not TextureCache.TextureNames[v] or not TextureCache.TextureNames[v].texture or Slua.IsNull(TextureCache.TextureNames[v].texture) then TextureCache.AddTexture(v) end ; end
          TextureCache.all_vehicle_images_cached = true
          local hashTab1,hashTab2 = {},{}
          if not TextureCache.Textures  then  return ; end
          for k,v in pairs (TextureCache.Textures) do if v.file_hash and not hashTab1[v.file_hash] then hashTab1[v.file_hash] = v.file_hash ; hashTab2[#hashTab2+1] = v.file_hash ;  end ; end
          if string2file and hashTab2 and #hashTab2 ~= 0 then string2file( table.concat( hashTab2,"\n"), Application.persistentDataPath.."/userData/img_cache/img_cache.txt", "w","\n" ) end
          if not TextureCache.rescan then TextureCache.ExecuteCleanupScript() ; end
          TextureCache.rescan = false
    end


    function TextureCache.ExecuteCleanupScript()
        if not shell then return ; end
        local dir       =  TextureCache.cacheDir or Application.persistentDataPath.."/userData/img_cache/" or ""
        dir = string.gsub(dir,"[/]","\\")
        local script    = 'PUSHD "'..dir..'"&& TITLE Homebrew: Cache Cleanup&& ECHO Cache Cleanup Begin&& ( IF EXIST "img_cache.txt" FOR /F %f in (img_cache.txt) do @( IF EXIST %f.png MOVE /Y %f.png tmp ) ) && @( IF EXIST *.png DEL /Q /F *.png ) && @( IF EXIST tmp\\*.png  MOVE /Y tmp\\*.png . ) && ECHO Cache Cleanup Complete'
        print("#### Execute Cleanup Shell Script ####")
        print("  "..script)
        if  TextureCache.debug  then  print( shell(script) )  ; else  shell(script) ; end
    end


    function TextureCache.GetErrorTexture()
        if TextureCache.error_texture and not Slua.IsNull(TextureCache.error_texture) then return TextureCache.error_texture ; end
        local textureString = 
            "................................\n"..
            ".....#....................#.....\n"..
            ".......#................#.......\n"..
            ".........#............#.........\n"..
            "...........#........#...........\n"..
            ".............#....#.............\n"..
            "...............##...............\n"..
            ".............#....#.............\n"..
            "...........#........#...........\n"..
            ".........#............#.........\n"..
            ".......#................#.......\n"..
            ".....#....................#.....\n"..
            "................................\n"
        local textureID = TextureCache.AddTexture( TextureCache.TextureFromString(textureString,4,4,Color(1,0,0,1)), "error_texture" )
        local texture   = TextureCache.Textures[textureID].texture
        TextureCache.error_texture = texture
        return texture
    end


    function TextureCache.GetErrorTexture2()
        if TextureCache.error_texture and not Slua.IsNull(TextureCache.error_texture) then return TextureCache.error_texture ; end
        local texture = Texture2D.Instantiate(Texture2D.blackTexture)
        texture:Resize(256,256)
        local transColor    = Color(1,1,1,0)
        local fillColor     = Color(1,0,0,0.5)
        local width         = 20
        for x = 0,255  do
        for y = 0,255  do
            if ((x+y) > 256-width and (x+y) < 256+width ) or ((x-y) > 0-width  and (x-y) < width )
            then  texture:SetPixel(x,y,fillColor)
            else  texture:SetPixel(x,y,transColor)
            end
        end
        end
        texture:Apply()
        local texID = 0
        if    TextureCache and TextureCache.AddTexture
        then  texID = TextureCache.AddTexture("error_texture","error_texture","error_texture",texture)
        end
        if    TextureCache.Textures[texID] and TextureCache.Textures[texID].texture and not Slua.IsNull(TextureCache.Textures[texID].texture)
        then
              texture = TextureCache.Textures[texID].texture
              TextureCache.error_texture = TextureCache.Textures[texID].texture
        end
        return texture
    end

    function TextureCache.TextureFromString(textureStr,scaleX,scaleY,fillColor,transColor)

        scaleX              = math.floor( tonumber(scaleX or 1) or 1 )
        scaleY              = math.floor( tonumber(scaley or scaleX) or scaleX )
        transColor          = transColor or Color(0,0,0,0)
        fillColor           = fillColor  or Color(1,1,1,1)
        local curX,curY     = 0,0
        local curAlpha      = 1.0
        local curChar       = ""
        local curCharDec    = ""
        local curChar1      = ""
        local curChar2      = ""
        local newStr        = ""
        local newLine       = ""
        local newStrTab     = {}
        local curChar1Dec   = 0
        local curChar2Dec   = 0
        local curChar1Val   = 0
        local curChar2Val   = 0
        local debug         = TextureCache.debug
        local texWidth      = 0
        local texHeight     = 0
        local curLine       = ""
        local trailLines    = 0
        local commentArea   = false
        local i             = 0
        local charToValue   = { [0x00] = 0.0, [0x30] = 0.0, [0x31] = 0.1, [0x32] = 0.2, [0x33] = 0.3,[0x34] = 0.4, [0x35] = 0.5, [0x36] = 0.6, [0x37] = 0.7, [0x38] = 0.8, [0x39] = 0.9, [0x23] = 1.0, }

        local printState = function(penState) penState = penState or "Down" ; print( string.format( "TextureFromString : curAlpha = %.4f  curX = %4s/%-4s  curY = %4s/%-4s  penState = '%s'  i = '%s'", curAlpha, tostring(curX), texWidth-1, tostring(curY), texHeight-1, penState, tostring(i)  )  ) ; end

        -- If string could be a filename, and that filename exists, load the data in the file as the string to process.
        if    type(textureStr) == "string" and not string.find(textureStr,"\n") and file_exists and file_exists(textureStr) and file2string
        then  textureStr = file2string(textureStr)
        end

        if type(textureStr) ~= "string" then return ; end

        textureStr = string.gsub(textureStr,string.char(0x0d),"")
        textureStr = string.gsub(textureStr,"[/-][^\n]*","")
        textureStr = string.gsub(textureStr,"^[\n][\n]*","")
        textureStr = string.gsub(textureStr,"[\n][\n]*$","")

        while scaleX > 1
        do
              newStrTab = {}
              for i = 1,#textureStr do curChar =  textureStr:sub(i,i) ; if curChar == "\n" then newStrTab[i] = curChar ; else newStrTab[i] = curChar..curChar ; end ; end
              textureStr = table.concat(newStrTab,"")
              scaleX = scaleX - 1
        end

        while scaleY > 1
        do
              newStrTab = {}
              for v in string.gmatch(textureStr.."\n","[^\n]*\n") do newStrTab[#newStrTab+1] = v..v ; end
              textureStr = table.concat(newStrTab,"")
              scaleY = scaleY - 1
        end

        while  textureStr:sub(-2) == "\n\n"
        do     textureStr = textureStr:sub(1,-2)
        end

        for i = 1,#textureStr do
            curChar    = textureStr:sub(i,i)
            curCharDec = string.byte(curChar)
            if      curCharDec == 10 then texWidth = math.max(texWidth,math.ceil(#curLine/2)) ; texHeight = texHeight + 1 ; commentArea = false ; curLine = ""
            elseif  curCharDec == 0x2d or curCharDec == 0x2f then commentArea = true
            elseif  not commentArea  then  curLine = curLine..curChar
            end
            if i == #textureStr then texWidth = math.max(texWidth,math.ceil(#curLine/2)) ; if #curLine > 0 then texHeight = texHeight + 1 ; end ; end
        end

        if texWidth == 0 or texHeight == 0 then return ; end

        local texture = Texture2D.Instantiate(Texture2D.blackTexture)
        texture:Resize(texWidth,texHeight)
        texture:Apply()

        curX,curY = 0,texHeight-1
        commentArea = false

        if debug then print( "TextureFromString : Converting text:\n"..textureStr ) ; end

        while i < #textureStr do

            curChar1Dec = string.byte(textureStr:sub(i+1,i+1))

            if i < #textureStr-1 then curChar2Dec = string.byte(textureStr:sub(i+2,i+2)) ; else curChar2Dec = curChar1Dec ; end

            curChar1Val = charToValue[curChar1Dec] or 0

            curChar2Val = charToValue[curChar2Dec] or 0

            curAlpha    = 1 * curChar1Val * curChar2Val

            if      curChar1Dec == 10
            then
                    i = i + 1
                    if curX < texWidth-1 then for j = curX,texWidth-1 do curX = j ; texture:SetPixel(curX,curY,transColor) ; if debug then printState("Trans") ; end ; end ; end
                    curY = curY - 1
                    curX = 0
                    commentArea = false
                    curChar2Dec = 0

            elseif  not commentArea
            then
                    i = i + 2
                    curAlpha = curChar1Val
            end

            if      curChar2Dec ~= 0
            then
                    if      curChar2Dec == 10
                    then    i = i - 1

                    elseif  curChar2Dec == 0x2d or curChar2Dec == 0x2f
                    then    commentArea = true

                    elseif  not commentArea
                    then
                        curAlpha = ( curAlpha + curChar2Val ) * 0.5
                        texture:SetPixel(curX,curY,Color(fillColor.r,fillColor.g,fillColor.b,curAlpha))
                        if debug  and  ( curX == 0 or curX == texWidth-1 ) then printState("Fill") ; end
                    end
                    curX = curX + 1
                    
            end
        end

        texture:Apply()

        local textureID = TextureCache.AddTexture(texture)

        if TextureCache.Textures and TextureCache.Textures[textureID] then texture = TextureCache.Textures[textureID].texture ; end

        return texture

    end


    function TextureCache.GetCrosshairTexture()
        if TextureCache.crosshair and not Slua.IsNull(TextureCache.crosshair) then return TextureCache.crosshair ; end
        local textureString = 
            "......##############........\n"..
            "....##..............##......\n"..
            "..##..................##....\n"..
            "##......................##..\n"..
            "##......................##..\n"..
            "##......................##..\n"..
            "##..........##..........##..\n"..
            "##......................##..\n"..
            "##......................##..\n"..
            "##......................##..\n"..
            "..##..................##....\n"..
            "....##..............##......\n"..
            "......##############........\n"
        local texture = TextureCache.TextureFromString(textureString)
        TextureCache.crosshair = texture
        return texture
    end

    function TextureCache.GetSelectionBoxTexture(width,transColor,fillColor)
        if TextureCache.selection_box and not Slua.IsNull(TextureCache.selection_box) then return TextureCache.selection_box ; end
        local texture = Texture2D.Instantiate(Texture2D.blackTexture)
        texture:Resize(256,256)
        transColor,fillColor,width = transColor or Color(1,1,1,0), fillColor or Color(1,0,0,0.5),  width or 20
        for x = 0,255  do
        for y = 0,255  do
            if ((x+y) > 256-width and (x+y) < 256+width ) or ((x-y) > 0-width  and (x-y) < width )
            then  texture:SetPixel(x,y,fillColor)
            else  texture:SetPixel(x,y,transColor)
            end
        end
        end
        texture:Apply()
        local texID = 0
        if    TextureCache and TextureCache.AddTexture
        then  texID = TextureCache.AddTexture("selection_box","selection_box","selection_box",texture)
        end
        if    TextureCache.Textures[texID] and TextureCache.Textures[texID].texture and not Slua.IsNull(TextureCache.Textures[texID].texture)
        then
              texture = TextureCache.Textures[texID].texture
              TextureCache.selection_box = TextureCache.Textures[texID].texture
        end
        return texture
    end


    function TextureCache.GetSphereTexture(fillColor)
        local l = TextureCache.sphere_texture_fillColor
        if   TextureCache.sphere_texture
        and  not Slua.IsNull(TextureCache.sphere_texture)
        and  ( not fillColor or ( l and l.r == fillColor.r and l.g == fillColor.g and l.b == fillColor.b and l.a == fillColor.a ) )
        then return TextureCache.sphere_texture
        end
        local texture = Texture2D.Instantiate(Texture2D.blackTexture)
        texture:Resize(256,256)
        fillColor = fillColor or Color(0,0,0,0.98)
        TextureCache.sphere_texture_fillColor = fillColor
        for x = 0,255  do
        for y = 0,255  do
            texture:SetPixel(x,y,fillColor)
        end
        end
        texture:Apply()
        local texID = 0
        if    TextureCache and TextureCache.AddTexture
        then  texID = TextureCache.AddTexture("sphere_texture","sphere_texture","sphere_texture",texture)
        end
        if    TextureCache.Textures[texID] and TextureCache.Textures[texID].texture and not Slua.IsNull(TextureCache.Textures[texID].texture)
        then
              texture = TextureCache.Textures[texID].texture
              TextureCache.sphere_texture = TextureCache.Textures[texID].texture
        end
        return texture
    end

    TextureCache.error_texture  = TextureCache.GetErrorTexture()
    TextureCache.selection_box  = TextureCache.GetSelectionBoxTexture()
    TextureCache.crosshair      = TextureCache.GetCrosshairTexture()
    TextureCache.sphere_texture = TextureCache.GetSphereTexture()

    TextureCache.startTime = os.clock()

    TC = TextureCache

end


function UI.GetVehicleImageList(filter)
    filter = string.lower(tostring(filter or ""))
    local path = Application.persistentDataPath.."/userData"
    local file_name = path.."/ref.hbr"
    local r    = {}
    local firstFile = ""
    local func = function(inp) inp = string.gsub(inp,"<[^>]*>","") ; if not string.find(inp,"[.][Pp][Nn][Gg]") or not string.find(inp,"Vehicle/") or ( filter and filter ~= "" and not string.find(string.lower(inp),filter) ) then return ; end ; r[#r+1] = path.."/"..inp ; end
  --forLineIn(file_name,func,suppressBlankLines,trimEdgeWhiteSpace,trimAllWhiteSpace)
    forLineIn(file_name,func,true,              true,              false)
    if r[1] then firstFile = r[1] ; end
    table.sort(r)
    r.firstFile = firstFile
    return r
end


function UI.Image.SetTextureColorTransparent(texture,transColor)
    if not texture or type(texture) ~= "userdata" or not texture.format or not texture.height or not texture.width then if UI.debug then print("UI.Image.SetTextureColorTransparent : Exit Fast.") ; end ; return texture ; end
    transColor = transColor or 0.35294118523597717
    for y = 0, texture.height do
    for x = 0, texture.width  do
        local p = texture:GetPixel(x,y)
        if p and p.r == transColor and p.g == transColor and p.b == transColor then
          p.a = 0
          texture:SetPixel(x, y, p)
        end
    end
    end
    texture:Apply()
    return texture
end


function UI.Image.ScaleTexture( texIn, nWidth, nHeight, transColor )
    if UI.debug then print("UI.Image.ScaleTexture : Enter function.") ; end
    if      type(transColor) == "boolean" and transColor then transColor = 0.35294118523597717 ; end
    if      type(texIn) == "string" and file_exists and file_exists(texIn)
    then    texIn = HBU.LoadTexture2D(texIn) ; if type(texIn) ~= "userdata" then if UI.debug then print("UI.Image.ScaleTexture : texIn is not userdata (1) : "..type(texIn)) ; end ; return texIn end
    elseif  type(texIn) ~= "userdata" or not texIn.format or not texIn.height or not texIn.width
    then    if UI.debug then print("UI.Image.ScaleTexture : texIn is not userdata (2) : "..type(texIn)) ; end ; return texIn
    end
    nWidth,nHeight = nWidth or 256, nHeight or 256
    local oWidth,oHeight = texIn.width,texIn.height
    local texOut = Texture2D.Instantiate(Texture2D.blackTexture)
    if not texOut or type(texOut) ~= "userdata" then return texIn end
    texOut:Resize(nWidth,nHeight)
    -- texOut:Apply()
    for y = 0,nHeight do
    for x = 0,nWidth  do
        local vx,vy = math.min( oWidth, math.floor(oWidth/nWidth*x) ), math.min( oHeight, math.floor(oHeight/nHeight*y) )
        local p = texIn:GetPixel(vx,vy)
        if transColor and p.r == transColor and p.g == transColor and p.b == transColor then   p.a = 0   end
        texOut:SetPixel(x, y, p)
    end
    end
    texOut:Apply()
    GameObject.Destroy(texIn)
    if UI.debug then print("UI.Image.ScaleTexture : Exit  function.") ; end
    return texOut
end


function UI.Image.List          (self)                   if not self or ( not self.isUIImage and not self.isUILabel ) then return false ; end ; for k,v in pairs(self) do print( string.format( "%-20s %30s = %s", type(v),k,tostring(v) ) ) end ; end
function UI.Image.GetPosition   (self)                   if not self or ( not self.isUIImage and not self.isUILabel ) then return false ; end ; return self.x, self.y  end
function UI.Image.GetDimensions (self)                   if not self or ( not self.isUIImage and not self.isUILabel ) then return false ; end ; return self.width, self.height end
function UI.Image.SetColor      (self,objID)             if not self or ( not self.isUIImage and not self.isUILabel ) then return false ; end ; end
function UI.Image.SetPanelColor (self,color)             if not self or ( not self.isUIImage and not self.isUILabel ) then return false ; end self.panel_color = color or self.panel_color ; self.panel:GetComponent("Image").color = self.panel_color ; end
function UI.Image.SetPosition   (self,x,y)               if not self or ( not self.isUIImage and not self.isUILabel ) then return false ; end ; self.x,self.y = x or self.x, y or self.y; self:UpdateRect()  end
function UI.Image.SetDimensions (self,width,height)      if not self or ( not self.isUIImage and not self.isUILabel ) then return false ; end ; self.width,self.height = width or self.width, height or self.height ; self:UpdateRect()  end
function UI.Image.SetPosAndDim  (self,x,y,width,height)  if not self or ( not self.isUIImage and not self.isUILabel ) then return false ; end ; self.x,self.y,self.width,self.height = x or self.x, y or self.y, width or self.width, height or self.height ; self:UpdateRect()  end
function UI.Image.Destroy       (self)                   if not self or ( not self.isUIImage and not self.isUILabel ) or not self.id or not self.owner or not UI then return false ; end ; UI:CleanUp(self.id, self.owner)  end


function UI.Image.UpdateRect(self)
    if not self or ( not self.isUIImage and not self.isUILabel ) then return ; end;
  --local screenPos = Camera.main:WorldToScreenPoint(v[2].transform.position)
    if    self.container and not Slua.IsNull(self.container) and self.x and self.y and self.width and self.height
    then
          self.container.transform.anchorMin = Vector2(self.x/Screen.width,self.y/Screen.height)
          self.container.transform.anchorMax = Vector2(self.x/Screen.width,self.y/Screen.height)
          self.container.transform.sizeDelta = Vector2(self.width,self.height)
    end
end


function UI.Image.SetTexture(self)
        if not self or not self.isUIImage or not self.image then print("UI.Image.SetTexture return fast", type(self)) ;return false ; end
        local file_hash   = false
        local texture     = false
        local color       = self.color or Color(1,1,1,1)
        local file_name   = self.file_name

        if      self.texture and type(self.texture) == "userdata" and not Slua.IsNull(self.texture)
        then    texture = self.texture

        elseif  not texture   or type(self.texture) ~= "userdata"      or Slua.IsNull(self.texture)
        then
                if      type(file_name) == "string" and file_exists and not file_exists(file_name)
                then
                        if      TextureCache.error_texture and not Slua.IsNull(TextureCache.error_texture)
                        then    texture = TextureCache.error_texture
                        elseif  TextureCache.TextureNames and TextureCache.TextureNames.error_texture
                        and     TextureCache.TextureNames.error_texture.texture and not Slua.IsNull(TextureCache.TextureNames.error_texture.texture)
                        then    texture = TextureCache.TextureNames.error_texture.texture
                        end

                elseif  type(file_name) == "string" and file_exists and file_exists(file_name) and TextureCache
                then
                        local texID = TextureCache.AddTexture(file_name)
                        if    texID and texID ~= 0 and TextureCache.Textures and TextureCache.Textures[texID] and TextureCache.Textures[texID].texture
                        then  texture = TextureCache.Textures[texID].texture
                        end

                elseif  TextureCache and TextureCache.GetErrorTexture
                then    texture = TextureCache.GetErrorTexture()
                end
        elseif  type(texture) == "userdata"
        then    -- Do nothing texture = self.texture
        elseif  TextureCache.error_texture and not Slua.IsNull(TextureCache.error_texture)
        then    texture = TextureCache.error_texture
        elseif  TextureCache.TextureNames and TextureCache.TextureNames.error_texture  and  TextureCache.TextureNames.error_texture.texture  and  not Slua.IsNull(TextureCache.TextureNames.error_texture.texture)
        then    texture = TextureCache.TextureNames.error_texture.texture
        end

        if    type(texture) == "userdata"
        then
              self.image:GetComponent("RawImage").texture = texture
              self.image:GetComponent("RawImage").color   = color
              self.image.transform.pivot  = Vector2(0.5,0.5)
              self.texture                = texture
              self.file_hash              = file_hash
              self.color                  = color
              self:UpdateRect()

        else print("UI.Image.SetTexture : ERROR : wrong type given for texture : "..tostring(type(texture)).." : "..tostring(texture))
        end

end


function UI.Image.SetLabel( self, label_text, label_font, label_fontSize, label_color, label_layout )
      if not self or ( not self.isUIImage and not self.isUILabel ) then return false ; end
      if not self.label then return false ; end
      if    type(label_text) == "string" and not label_font and not label_fontSize and not label_color and not label_layout
      then
            self.label_text = label_text
            self.label.text = self.label_text
            return
      end
      self.label_text, self.label_font, self.label_fontSize, self.label_color, self.label_layout = label_text or self.label_text, label_font or self.label_font, label_fontSize or self.label_fontSize, label_color or self.label_color, label_layout or self.label_layout
      self.label.text      = self.label_text
      self.label.fontSize  = self.label_fontSize
      self.label.color     = self.label_color
    --self.label.alignment = TextAnchor.UpperCenter
      if ( not self.label_layout_last_set or self.label_layout_last_set ~= self.label_layout )  and  UI.Image.LabelLayouts[self.label_layout] then UI.Image.LabelLayouts[self.label_layout](self) ; self.label_layout_last_set = self.label_layout ; end
      if UI and UI.Fonts and UI.Fonts[self.label_font] then  self.label.font = UI.Fonts[self.label_font] ; end
      self:UpdateRect()
end


function UI.Label:New( x, y, width, height, label_text, label_font, label_fontSize, label_color, label_layout, panel_color )

    if not self then return(UI.Label:New( x, y, width, height, label_text, label_font, label_fontSize, label_color, panel_color )) ; end
    local  owner = tostring(debug.getinfo(2).short_src)
    if not self.parent then self.parent = HBU.menu.transform:Find("Foreground").gameObject ; end
    local  parent = self.parent
    if not parent then return ; end

    x,y,width,height               =  x or 0, y or 0, width or 256, height or 256
    label_text                     = label_text     or "a label with text that-is-longer-than-it-is-short"
    label_font                     = label_font     or "Consolas"
    label_fontSize                 = label_fontSize or 16
    label_color                    = label_color    or Color(1,1,1,1)
    label_layout                 = label_layout or 1

    panel_color                    = panel_color or Color( 0.0, 0.0, 0.0, 0.0 )

    local co                       = HBU.Instantiate("Container",parent)
    co.transform.pivot             = Vector2(0.5,0.5)
    co.transform.anchorMin         = Vector2(x/Screen.width,y/Screen.height)
    co.transform.anchorMax         = Vector2(x/Screen.width,y/Screen.height)
    co.transform.sizeDelta         = Vector2(width,height+10)

    local ca                       = co:AddComponent("UnityEngine.CanvasGroup")
    ca.alpha                       = 1.0

    local pa                       = HBU.Instantiate("Panel", co)
    pa.transform.anchorMin         = Vector2.zero
    pa.transform.anchorMax         = Vector2.one
    pa.transform.offsetMin         = Vector2.zero
    pa.transform.offsetMax         = Vector2.zero
    pa:GetComponent("Image").color = panel_color

    local la                       = HBU.Instantiate("Text", co):GetComponent("Text")
    la.transform.pivot             = Vector2(0.5,0.5)
    -- la.transform.anchorMin         = Vector2.zero
    -- la.transform.anchorMax         = Vector2.one
    -- la.transform.offsetMin         = Vector2.one*1.1
    -- la.transform.offsetMax         = Vector2.zero
    la.text                        = label_text

    local label = {
              parent                     = co,
              owner                      = owner,
              container                  = co,
              canvas                     = ca,
              panel                      = pa,
              label                      = la,
            --image                      = im,
              isUILabel                  = true,
              x                          = x,
              y                          = y,
              height                     = height,
              width                      = width,
              name                       = "A Label",
              label                      = false,
              label_text                 = label_text,
              label_layout               = label_layout,
              label_layout_last_set      = false,
              label_fontSize             = label_fontSize,
              label_font                 = label_font,
              label_color                = label_color,
              panel_color                = panel_color,
            --file_name                  = file_name,
            --textureId                  = textureId,
            --texture                    = texture,
            --file_hash                  = false,
            --error_texture              = TextureCache.TextureNames.error_texture.texture,
              UpdateRect                 = function(self,...) return UI.Image.UpdateRect(self,...)     ; end,
              List                       = function(self,...) return UI.Image.List(self,...)           ; end,
              GetPosition                = function(self,...) return UI.Image.GetPosition(self,...)    ; end,
              GetDimensions              = function(self,...) return UI.Image.GetDimensions(self,...)  ; end,
            --GetImageHash               = function(self,...) return TextureCache.GetImageHash(self.file_name) ; end,
              SetPosition                = function(self,...) return UI.Image.SetPosition(self,...)    ; end,
              SetDimensions              = function(self,...) return UI.Image.SetDimensions(self,...)  ; end,
              SetPosAndDim               = function(self,...) return UI.Image.SetPosAndDim(self,...)   ; end,
              SetLabel                   = function(self,...) return UI.Image.SetLabel(self,...)       ; end,
              SetPanelColor              = function(self,...) return UI.Image.SetPanelColor(self,...)  ; end,
            --SetTexture                 = function(self)     return UI.Image.SetTexture(self)         ; end,
            --SetTextureColorTransparent = function(self,...) if self.texture then self.texture = UI.Image.SetTextureColorTransparent(self.texture) ; end ; end,
            --ScaleTexture               = function(self,...) self.texture = UI.Image.ScaleTexture(self.texture,...) ; self.SetTexture(self) end,
              Destroy                    = function(self,...) return UI.Image.Destroy(self,...)        ; end,
    }

    label.id = UI:AddObjectToDestroy(owner,label)
    label:SetLabel()

    return label

end


function UI.Image:New( x, y, width, height, color, file_name, label_text, label_font, label_fontSize, label_color, label_layout, panel_color )

    if not self then return ; end
    local  owner = tostring(debug.getinfo(2).short_src)
    if not self.parent then self.parent = HBU.menu.transform:Find("Foreground").gameObject ; end
    local  parent = self.parent
    if not self or not parent then return ; end

    x,y,width,height  =  x or 0, y or 0, width or 256, height or 256

    color          = color or Color(1,1,1,1)

    file_name      = file_name  or false

    label_text     = label_text     or "a label with text that-is-longer-than-it-is-short"
    label_font     = label_font     or "Consolas"
    label_fontSize = label_fontSize or 16
    label_color    = label_color    or Color(1,1,1,1)
    label_layout = label_layout or 1
    
    panel_color = panel_color or Color(0.1, 0.1, 0.1, 0.8) 

    local co,ca = false,false
    co = HBU.Instantiate("Container",parent)
    co.transform.pivot     = Vector2(0.5,0.5)
    co.transform.anchorMin = Vector2(x/Screen.width,y/Screen.height)
    co.transform.anchorMax = Vector2(x/Screen.width,y/Screen.height)
    co.transform.sizeDelta = Vector2(width,height+100)
    ca = co:AddComponent("UnityEngine.CanvasGroup")
    ca.alpha = 1.0
    local pa = HBU.Instantiate("Panel", co)
    pa.transform.anchorMin = Vector2.zero
    pa.transform.anchorMax = Vector2.one
    pa.transform.offsetMin = Vector2.zero
    pa.transform.offsetMax = Vector2.zero
    pa:GetComponent("Image").color = panel_color
    local im = HBU.Instantiate("RawImage",co)
    im.name = "WormHole2"
    im.transform.anchorMin = Vector2.zero
    im.transform.anchorMax = Vector2.one
    im.transform.offsetMin = Vector2.zero
    im.transform.offsetMax = Vector2.zero
    im:GetComponent("RawImage").color = color
    local la = HBU.Instantiate("Text", co):GetComponent("Text")
    la.transform.anchorMin = Vector2.zero
    la.transform.anchorMax = Vector2.one
    la.transform.offsetMin = Vector2.one*1.1
    la.transform.offsetMax = Vector2.zero
    la.text                = label_text

    local  textureId = 0
    local  texture   = false

    if      type(file_name) == "string"
    then    textureId = TextureCache.AddTexture(file_name) ; if textureID and TextureCache.Textures[textureID] then texture = TextureCache.Textures[textureID].texture ; end
    elseif  type(file_name) == "userdata" and string.find(string.lower(tostring(file_name)),"texture2d")
    then    textureID = TextureCache.AddTexture(file_name)
    end

    if UI.Fonts and not UI.Fonts[label_font] then label_font = "Consolas" ; end

    local img = {
              parent                     = co,
              owner                      = owner,
              container                  = co,
              canvas                     = ca,
              panel                      = pa,
              image                      = im,
              label                      = la,
              isUIImage                  = true,
              x                          = x,
              y                          = y,
              height                     = height,
              width                      = width,
              color                      = color,
              name                       = "An Image",
              label                      = false,
              label_text                 = label_text,
              label_layout               = label_layout,
              label_fontSize             = label_fontSize,
              label_font                 = label_font,
              label_color                = label_color,
              panel_color                = panel_color,
              file_name                  = file_name,
              textureId                  = textureId,
              texture                    = texture,
              file_hash                  = false,
              error_texture              = TextureCache.TextureNames.error_texture.texture,
              UpdateRect                 = function(self,...) return UI.Image.UpdateRect(self,...)     ; end,
              List                       = function(self,...) return UI.Image.List(self,...)           ; end,
              GetPosition                = function(self,...) return UI.Image.GetPosition(self,...)    ; end,
              GetDimensions              = function(self,...) return UI.Image.GetDimensions(self,...)  ; end,
              GetImageHash               = function(self,...) return TextureCache.GetImageHash(self.file_name) ; end,
              SetPosition                = function(self,...) return UI.Image.SetPosition(self,...)    ; end,
              SetDimensions              = function(self,...) return UI.Image.SetDimensions(self,...)  ; end,
              SetPosAndDim               = function(self,...) return UI.Image.SetPosAndDim(self,...)   ; end,
              SetTexture                 = function(self)     return UI.Image.SetTexture(self)         ; end,
              SetLabel                   = function(self,...) return UI.Image.SetLabel(self,...)       ; end,
              SetTextureColorTransparent = function(self,...) if self.texture then self.texture = UI.Image.SetTextureColorTransparent(self.texture) ; end ; end,
              Destroy                    = function(self,...) return UI.Image.Destroy(self,...)        ; end,
              ScaleTexture               = function(self,...) self.texture = UI.Image.ScaleTexture(self.texture,...) ; self.SetTexture(self) end,
    }

    img.id = UI:AddObjectToDestroy(owner,img)
    img:SetTexture()
    img:SetLabel()

    return img

end


function UI:SetupInput()

  if not self then return end

  self.Input = {
      index               = 0,
      tick                = 0,
      memoryMax           = 1024,
      inputStringNoInput  = "",
      Mouse               = {  x = 0,  y = 0, xraw = 0, yraw = 0, scroll = 0, position = {}, Button = { [0] = { down = false, up = false,  } } },
      Joysticks           = {  [1] = { active = false, },   [2] = { active = false, },   [3] = { active = false, },    [4] = { active = false, },    [5] = { active = false, },    [6] = { active = false, },    [7] = { active = false, },    [8] = { active = false, },  },
      JoystickAxisNames   = { "D-Pad X Axis", "D-Pad Y Axis", "Left Stick X Axis", "Left Stick Y Axis", "Left Trigger", "Right Stick X Axis", "Right Stick Y Axis", "Right Trigger", "Triggers",  },
      Axis                = {
                ["Mouse X"]             = 0,
                ["Mouse Y"]             = 0,
                ["Mouse ScrollWheel"]   = 0,
                ["Horizontal"]          = 0,
                ["Vertical"]            = 0,
                [1] = {  ["Joy1Axis1"]  = 0, ["Joy1Axis2"]  = 0, ["Joy1Axis3"]  = 0, ["Joy1Axis4"]  = 0, ["Joy1Axis5"]  = 0, ["Joy1Axis6"]  = 0, ["Joy1Axis7"]  = 0, ["Joy1Axis8"]  = 0, ["Joy1Axis9"]  = 0, ["Joy1Axis10"]  = 0, ["Joy1Axis11"]  = 0, ["Joy1Axis12"]  = 0, ["Joy1Axis13"]  = 0, ["Joy1Axis14"]  = 0, ["Joy1Axis15"]  = 0, ["Joy1Axis16"]  = 0, ["Joy1Axis17"]  = 0, ["Joy1Axis18"]  = 0, ["Joy1Axis19"]  = 0, ["Joy1Axis20"]  = 0, },
                [2] = {  ["Joy2Axis1"]  = 0, ["Joy2Axis2"]  = 0, ["Joy2Axis3"]  = 0, ["Joy2Axis4"]  = 0, ["Joy2Axis5"]  = 0, ["Joy2Axis6"]  = 0, ["Joy2Axis7"]  = 0, ["Joy2Axis8"]  = 0, ["Joy2Axis9"]  = 0, ["Joy2Axis10"]  = 0, ["Joy2Axis11"]  = 0, ["Joy2Axis12"]  = 0, ["Joy2Axis13"]  = 0, ["Joy2Axis14"]  = 0, ["Joy2Axis15"]  = 0, ["Joy2Axis16"]  = 0, ["Joy2Axis17"]  = 0, ["Joy2Axis18"]  = 0, ["Joy2Axis19"]  = 0, ["Joy2Axis20"]  = 0, },
                [3] = {  ["Joy3Axis1"]  = 0, ["Joy3Axis2"]  = 0, ["Joy3Axis3"]  = 0, ["Joy3Axis4"]  = 0, ["Joy3Axis5"]  = 0, ["Joy3Axis6"]  = 0, ["Joy3Axis7"]  = 0, ["Joy3Axis8"]  = 0, ["Joy3Axis9"]  = 0, ["Joy3Axis10"]  = 0, ["Joy3Axis11"]  = 0, ["Joy3Axis12"]  = 0, ["Joy3Axis13"]  = 0, ["Joy3Axis14"]  = 0, ["Joy3Axis15"]  = 0, ["Joy3Axis16"]  = 0, ["Joy3Axis17"]  = 0, ["Joy3Axis18"]  = 0, ["Joy3Axis19"]  = 0, ["Joy3Axis20"]  = 0, },
                [4] = {  ["Joy4Axis1"]  = 0, ["Joy4Axis2"]  = 0, ["Joy4Axis3"]  = 0, ["Joy4Axis4"]  = 0, ["Joy4Axis5"]  = 0, ["Joy4Axis6"]  = 0, ["Joy4Axis7"]  = 0, ["Joy4Axis8"]  = 0, ["Joy4Axis9"]  = 0, ["Joy4Axis10"]  = 0, ["Joy4Axis11"]  = 0, ["Joy4Axis12"]  = 0, ["Joy4Axis13"]  = 0, ["Joy4Axis14"]  = 0, ["Joy4Axis15"]  = 0, ["Joy4Axis16"]  = 0, ["Joy4Axis17"]  = 0, ["Joy4Axis18"]  = 0, ["Joy4Axis19"]  = 0, ["Joy4Axis20"]  = 0, },
                [5] = {  ["Joy5Axis1"]  = 0, ["Joy5Axis2"]  = 0, ["Joy5Axis3"]  = 0, ["Joy5Axis4"]  = 0, ["Joy5Axis5"]  = 0, ["Joy5Axis6"]  = 0, ["Joy5Axis7"]  = 0, ["Joy5Axis8"]  = 0, ["Joy5Axis9"]  = 0, ["Joy5Axis10"]  = 0, ["Joy5Axis11"]  = 0, ["Joy5Axis12"]  = 0, ["Joy5Axis13"]  = 0, ["Joy5Axis14"]  = 0, ["Joy5Axis15"]  = 0, ["Joy5Axis16"]  = 0, ["Joy5Axis17"]  = 0, ["Joy5Axis18"]  = 0, ["Joy5Axis19"]  = 0, ["Joy5Axis20"]  = 0, },
                [6] = {  ["Joy6Axis1"]  = 0, ["Joy6Axis2"]  = 0, ["Joy6Axis3"]  = 0, ["Joy6Axis4"]  = 0, ["Joy6Axis5"]  = 0, ["Joy6Axis6"]  = 0, ["Joy6Axis7"]  = 0, ["Joy6Axis8"]  = 0, ["Joy6Axis9"]  = 0, ["Joy6Axis10"]  = 0, ["Joy6Axis11"]  = 0, ["Joy6Axis12"]  = 0, ["Joy6Axis13"]  = 0, ["Joy6Axis14"]  = 0, ["Joy6Axis15"]  = 0, ["Joy6Axis16"]  = 0, ["Joy6Axis17"]  = 0, ["Joy6Axis18"]  = 0, ["Joy6Axis19"]  = 0, ["Joy6Axis20"]  = 0, },
                [7] = {  ["Joy7Axis1"]  = 0, ["Joy7Axis2"]  = 0, ["Joy7Axis3"]  = 0, ["Joy7Axis4"]  = 0, ["Joy7Axis5"]  = 0, ["Joy7Axis6"]  = 0, ["Joy7Axis7"]  = 0, ["Joy7Axis8"]  = 0, ["Joy7Axis9"]  = 0, ["Joy7Axis10"]  = 0, ["Joy7Axis11"]  = 0, ["Joy7Axis12"]  = 0, ["Joy7Axis13"]  = 0, ["Joy7Axis14"]  = 0, ["Joy7Axis15"]  = 0, ["Joy7Axis16"]  = 0, ["Joy7Axis17"]  = 0, ["Joy7Axis18"]  = 0, ["Joy7Axis19"]  = 0, ["Joy7Axis20"]  = 0, },
                [8] = {  ["Joy8Axis1"]  = 0, ["Joy8Axis2"]  = 0, ["Joy8Axis3"]  = 0, ["Joy8Axis4"]  = 0, ["Joy8Axis5"]  = 0, ["Joy8Axis6"]  = 0, ["Joy8Axis7"]  = 0, ["Joy8Axis8"]  = 0, ["Joy8Axis9"]  = 0, ["Joy8Axis10"]  = 0, ["Joy8Axis11"]  = 0, ["Joy8Axis12"]  = 0, ["Joy8Axis13"]  = 0, ["Joy8Axis14"]  = 0, ["Joy8Axis15"]  = 0, ["Joy8Axis16"]  = 0, ["Joy8Axis17"]  = 0, ["Joy8Axis18"]  = 0, ["Joy8Axis19"]  = 0, ["Joy8Axis20"]  = 0, },
                [9] = {  ["Joy9Axis1"]  = 0, ["Joy9Axis2"]  = 0, ["Joy9Axis3"]  = 0, ["Joy9Axis4"]  = 0, ["Joy9Axis5"]  = 0, ["Joy9Axis6"]  = 0, ["Joy9Axis7"]  = 0, ["Joy9Axis8"]  = 0, ["Joy9Axis9"]  = 0, ["Joy9Axis10"]  = 0, ["Joy9Axis11"]  = 0, ["Joy9Axis12"]  = 0, ["Joy9Axis13"]  = 0, ["Joy9Axis14"]  = 0, ["Joy9Axis15"]  = 0, ["Joy9Axis16"]  = 0, ["Joy9Axis17"]  = 0, ["Joy9Axis18"]  = 0, ["Joy9Axis19"]  = 0, ["Joy9Axis20"]  = 0, },
               [10] = {  ["Joy10Axis1"] = 0, ["Joy10Axis2"] = 0, ["Joy10Axis3"] = 0, ["Joy10Axis4"] = 0, ["Joy10Axis5"] = 0, ["Joy10Axis6"] = 0, ["Joy10Axis7"] = 0, ["Joy10Axis8"] = 0, ["Joy10Axis9"] = 0, ["Joy10Axis10"] = 0, ["Joy10Axis11"] = 0, ["Joy10Axis12"] = 0, ["Joy10Axis13"] = 0, ["Joy10Axis14"] = 0, ["Joy10Axis15"] = 0, ["Joy10Axis16"] = 0, ["Joy10Axis17"] = 0, ["Joy10Axis18"] = 0, ["Joy10Axis19"] = 0, ["Joy10Axis20"] = 0, },
               [11] = {  ["Joy11Axis1"] = 0, ["Joy11Axis2"] = 0, ["Joy11Axis3"] = 0, ["Joy11Axis4"] = 0, ["Joy11Axis5"] = 0, ["Joy11Axis6"] = 0, ["Joy11Axis7"] = 0, ["Joy11Axis8"] = 0, ["Joy11Axis9"] = 0, ["Joy11Axis10"] = 0, ["Joy11Axis11"] = 0, ["Joy11Axis12"] = 0, ["Joy11Axis13"] = 0, ["Joy11Axis14"] = 0, ["Joy11Axis15"] = 0, ["Joy11Axis16"] = 0, ["Joy11Axis17"] = 0, ["Joy11Axis18"] = 0, ["Joy11Axis19"] = 0, ["Joy11Axis20"] = 0, },
      },
    }
  self.Input.J            = self.Input.Joysticks
  self.Input.A            = self.Input.Axis

  function self.Input:Get(indexQuery)
      if not self or not self.inputStringNoInput then return UI.Input:Get(indexQuery) ; end
      if self.index == 0 then return "",0 ; end
      indexQuery = tonumber(indexQuery or self.index) or self.index
      if indexQuery > self.index then return "", 0 ; end
      return self[(indexQuery-1)%#self+1], indexQuery
  end

  function self.Input:GetAll(count)  if self.index == 0 then return "" ; end ; count = tonumber(count or #self) or #self ; local r = "" ; for i = 1,count do r = r..self[(self.index+i-1)%#self+1]  ; end ; return r ; end

  function self.Input:GetIndex(relFrame) if self.index == 0 then return 0 ; end ; relFrame = tonumber(relFrame or 0) or 0 ;  return (relFrame + self.index-1)%#self+1 ; end

  function self.Input:GetJoystickNames() self.JoystickNames = { Slua.iter(Input.GetJoystickNames())() } ; end

  --------------------------------------------------------
  --     Axis Name                     Axis ID
  --                          Win      MacOSX     Linux
  --------------------------------------------------------
  -- Left Stick X Axis      "X Axis"  "X Axis"  "X Axis"
  -- Left Stick Y Axis      "Y Axis"  "Y Axis"  "Y Axis"
  -- Right Stick X Axis        4         3         4
  -- Right Stick Y Axis        5         4         5
  -- D-Pad X Axis              6         7
  -- D-Pad Y Axis              7         8
  -- Triggers                  3
  -- Left Trigger              9         5         3
  -- Right Trigger            10         6         6

  ---------------------------------------------
  --   Button Name            Button ID
  --                      Win  MacOSX     Linux
  ---------------------------------------------
  -- A Button                 0     16      0
  -- B Button                 1     17      1
  -- X Button                 2     18      2
  -- Y Button                 3     19      3
  -- Left Bumper              4     13      4
  -- Right Bumper             5     14      5
  -- Back Button              6     10      6
  -- Start Button             7      9      7
  -- Left Stick Click         8     11      9
  -- Right Stick Click        9     12     10
  -- D-Pad Up                        5     13
  -- D-Pad Down                      6     14
  -- D-Pad Left                      7     11
  -- D-Pad Right                     8     12
  -- Xbox Button                    15

  self.Input.JoystickButtonNames = {
      [1] = { "Joystick1Button0", "Joystick1Button1", "Joystick1Button2", "Joystick1Button3", "Joystick1Button4", "Joystick1Button5", "Joystick1Button6", "Joystick1Button7", "Joystick1Button8", "Joystick1Button9", "Joystick1Button10", "Joystick1Button11", "Joystick1Button12", "Joystick1Button13", "Joystick1Button14", "Joystick1Button15", "Joystick1Button16", "Joystick1Button17", "Joystick1Button18", "Joystick1Button19", },
      [2] = { "Joystick2Button0", "Joystick2Button1", "Joystick2Button2", "Joystick2Button3", "Joystick2Button4", "Joystick2Button5", "Joystick2Button6", "Joystick2Button7", "Joystick2Button8", "Joystick2Button9", "Joystick2Button10", "Joystick2Button11", "Joystick2Button12", "Joystick2Button13", "Joystick2Button14", "Joystick2Button15", "Joystick2Button16", "Joystick2Button17", "Joystick2Button18", "Joystick2Button19", },
      [3] = { "Joystick3Button0", "Joystick3Button1", "Joystick3Button2", "Joystick3Button3", "Joystick3Button4", "Joystick3Button5", "Joystick3Button6", "Joystick3Button7", "Joystick3Button8", "Joystick3Button9", "Joystick3Button10", "Joystick3Button11", "Joystick3Button12", "Joystick3Button13", "Joystick3Button14", "Joystick3Button15", "Joystick3Button16", "Joystick3Button17", "Joystick3Button18", "Joystick3Button19", },
      [4] = { "Joystick4Button0", "Joystick4Button1", "Joystick4Button2", "Joystick4Button3", "Joystick4Button4", "Joystick4Button5", "Joystick4Button6", "Joystick4Button7", "Joystick4Button8", "Joystick4Button9", "Joystick4Button10", "Joystick4Button11", "Joystick4Button12", "Joystick4Button13", "Joystick4Button14", "Joystick4Button15", "Joystick4Button16", "Joystick4Button17", "Joystick4Button18", "Joystick4Button19", },
      [5] = { "Joystick5Button0", "Joystick5Button1", "Joystick5Button2", "Joystick5Button3", "Joystick5Button4", "Joystick5Button5", "Joystick5Button6", "Joystick5Button7", "Joystick5Button8", "Joystick5Button9", "Joystick5Button10", "Joystick5Button11", "Joystick5Button12", "Joystick5Button13", "Joystick5Button14", "Joystick5Button15", "Joystick5Button16", "Joystick5Button17", "Joystick5Button18", "Joystick5Button19", },
      [6] = { "Joystick6Button0", "Joystick6Button1", "Joystick6Button2", "Joystick6Button3", "Joystick6Button4", "Joystick6Button5", "Joystick6Button6", "Joystick6Button7", "Joystick6Button8", "Joystick6Button9", "Joystick6Button10", "Joystick6Button11", "Joystick6Button12", "Joystick6Button13", "Joystick6Button14", "Joystick6Button15", "Joystick6Button16", "Joystick6Button17", "Joystick6Button18", "Joystick6Button19", },
      [7] = { "Joystick7Button0", "Joystick7Button1", "Joystick7Button2", "Joystick7Button3", "Joystick7Button4", "Joystick7Button5", "Joystick7Button6", "Joystick7Button7", "Joystick7Button8", "Joystick7Button9", "Joystick7Button10", "Joystick7Button11", "Joystick7Button12", "Joystick7Button13", "Joystick7Button14", "Joystick7Button15", "Joystick7Button16", "Joystick7Button17", "Joystick7Button18", "Joystick7Button19", },
      [8] = { "Joystick8Button0", "Joystick8Button1", "Joystick8Button2", "Joystick8Button3", "Joystick8Button4", "Joystick8Button5", "Joystick8Button6", "Joystick8Button7", "Joystick8Button8", "Joystick8Button9", "Joystick8Button10", "Joystick8Button11", "Joystick8Button12", "Joystick8Button13", "Joystick8Button14", "Joystick8Button15", "Joystick8Button16", "Joystick8Button17", "Joystick8Button18", "Joystick8Button19", },
      AltNames = { [0] = "A Button", [1] = "B Button", [2] = "X Button", [3] = "Y Button", [4] = "Left Bumper", [5] = "Right Bumper", [6] = "Back Button", [7] = "Start Button", [8] = "Left Stick Click", [9] = "Right Stick Click", },
   -- The following only avail on Linux/Mac as buttons, because in Windows, they are axis:  "D-Pad Up", "D-Pad Down", "D-Pad Left", "D-Pad Right", "Xbox Button", 
  }

  self.Input:GetJoystickNames()

  for i = 1,8 do if #self.Input.JoystickNames >= i then self.Input.Joysticks[i].active = true ; else self.Input.Joysticks[i].active = false ; end ; end

  function self.Input:Update()
      self.tick = self.tick + 1
      if self.tick % 900 == 0 then self:GetJoystickNames() ; end
      if    Input.anyKeyDown and Input.inputString ~= ""
      -- then  self.index = (self.index)%self.memoryMax+1 ; self[self.index] = Input.inputString ; self.now = self[self.index]
      then  self.index = self.index+1  ; self[(self.index-1)%self.memoryMax+1] = Input.inputString ; self.now = self[(self.index-1)%self.memoryMax+1]
      else  self.now = self.inputStringNoInput
      end
      self.Mouse.position = Input.mousePosition
      self.Mouse.x        = Input.GetAxis(    "Mouse X"           )
      self.Mouse.y        = Input.GetAxis(    "Mouse Y"           )
      self.Mouse.xraw     = Input.GetAxisRaw( "Mouse X"           )
      self.Mouse.yraw     = Input.GetAxisRaw( "Mouse Y"           )
      self.Mouse.scroll   = Input.GetAxisRaw( "Mouse ScrollWheel" )
      self.horizontal     = Input.GetAxis(    "Horizontal"        )
      self.horizontalraw  = Input.GetAxisRaw( "Horizontal"        )
      self.vertical       = Input.GetAxis(    "Vertical"          )
      self.verticalraw    = Input.GetAxisRaw( "Vertical"          )
    --for k,v in pairs(self.Axis) do self.Axis[k] = Input.GetAxis(k) ; if self.Axis[k] ~= 0 then print("Axis["..tostring(k).."] = "..tostring(self.Axis[k])) ; end ; end
      for k1,v1 in pairs(self.Axis) do if type(v1) == "string" then self.Axis[k1] = Input.GetAxis(k1) ; elseif type(v1) == "table" and self.J[k1] and self.J[k1].active then  for k2,v2 in pairs(v1) do self.J[k1][k2] = Input.GetAxis(k2) ; end ; end ; end
      for k1,v1 in pairs(self.Joysticks) do  if v1 and v1.active then  for k2,v2 in pairs(self.JoystickButtonNames[k1]) do if self.JoystickButtonNames.AltNames[k2-1] then self.Joysticks[k1][self.JoystickButtonNames.AltNames[k2-1]] = Input.GetButton(v2) ; end ; end ; end ; end
  end

end


function UI:AddObjectToDestroy(owner,obj)
    if not owner or not obj then return end
    if not self.ObjectsToDestroy then self.ObjectsToDestroy = {} ; end
    if not self.ObjectsToDestroy[owner] then self.ObjectsToDestroy[owner] = {} ; end
    local newID = #self.ObjectsToDestroy[owner]+1
    self.ObjectsToDestroy[owner][newID] = obj
    return newID
end


function UI:CleanUp(id, owner)
    
    local owner = owner or tostring(debug.getinfo(2).short_src)

    if      type(id) == "number" then -- do nothin'
    elseif  type(id) == "string" then owner = id ; id = -1
    else    id = -1
    end

    if not self or not self.ObjectsToDestroy or not self.ObjectsToDestroy[owner] then return ; end

    if  id ~= -1
    then
        local v = self.ObjectsToDestroy[owner][id]
        if  v
        then
            if  v.parent  and not Slua.IsNull(v.parent) then GameObject.Destroy(v.parent.gameObject)
            end
            self.ObjectsToDestroy[owner][id] = nil
        end
        return
    end

    local resetTable = false

    for k, v in pairs(self.ObjectsToDestroy[owner])
    do
            resetTable = true
            if  v.parent  and not Slua.IsNull(v.parent) then GameObject.Destroy(v.parent.gameObject)
            end
    end

    if  resetTable then self.ObjectsToDestroy[owner] = {} ; end
end

function main(go) UI.gameObject = go ; return UI ; end

return UI
