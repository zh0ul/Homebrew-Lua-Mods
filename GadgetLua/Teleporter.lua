local Teleporter = {}

function Teleporter:Awake()
  Debug.Log("Teleporter:Awake()")
  self.debug                   = true
  self.name                    = "Teleporter"
  self.useGadgetKey            = HBU.GetKey("UseGadget")
  self.useGadgetSecondaryKey   = HBU.GetKey("UseGadgetSecondary")
  self.shiftKey                = HBU.GetKey("")
  self.showing                 = false
  self.TargetNodes           = {}
  self.customLocations         = {}
  self.customLocationsFile     = Application.persistentDataPath.."/userData/User-Teleporter-Locations.txt"
  self.showVehicles            = true
  self.showPlayers             = true
  self.Vehicles                = false
  self.Players                 = false
  self.wormholeRadiusSmall     = 16
  self.wormholeRadiusLarge     = 32
  self.ringRadius              = 128
  self.fontSize                = 21
  self.GUIfontSize             = { 28, 22, 22, }
  self.GUIcolors               = {  Color(1,1,0,1),  Color(0,1,1,1),  Color(1,1,0,1), }
  self.GUIlayout               = {
                                    Vector4( (Screen.width/2)-150, Screen.height * 0.5 + 100,                           300, (self.GUIfontSize[1]+6)*1                           ),
                                    Vector4( (Screen.width/2)-150, Screen.height * 0.5 + 100 + (self.GUIfontSize[1]+6), 300, (self.GUIfontSize[2]+6)*1                           ),
                                    Vector4( (Screen.width/2)-150, Screen.height * 0.5 + 100 + (self.GUIfontSize[1]+6) + (self.GUIfontSize[2]+6), 300, (self.GUIfontSize[3]+6)*3 ),
                                 }
  --                               TextAnchor.UpperLeft,  TextAnchor.UpperCenter,  TextAnchor.UpperRight
  --                               TextAnchor.MiddleLeft, TextAnchor.MiddleCenter, TextAnchor.MiddleRight,
  --                               TextAnchor.LowerLeft,  TextAnchor.LowerCenter,  TextAnchor.LowerRight,
  self.GUItextAlignment        = { TextAnchor.MiddleCenter, TextAnchor.MiddleCenter, TextAnchor.MiddleCenter, }
  self.teleporting             = false
  self.defaultFoV              = HBU.GetSetting("FieldOfView")
  self.currentFoV              = self.defaultFoV
  self.maxFoV                  = 120
  self.maxHeightMod            = 0.1  -- The teleport distance is multiplied by this number, and the result is how high we will rise until 1/2 way mark.
  self.speedUpMod              = 25   -- Higher numbers == slower speed-up.
  self.slowDownMod             = 40   -- Higher numbers == slower slow-down.
  self.endPositionMod          = Vector3(0,0.10,0)
  self.GameObjects             = { "ring1", "ring2", "TargetNodes", "textGUI1","textGUI2", "textGUI1_panel","textGUI2_panel", "wormholeImage", "ringImage1", "ringImage2", "font1" }
  self.tick                    = 0
  self.print                   = function(msg) GameObject.FindObjectOfType("HBChat"):AddMessage("[Teleporter]",msg) end
  self.dynamicFonts            = {"Consolas","Roboto","Arial"}
  self:LoadCustomLocations()
  self:SetDefaults()

  function self:SetupCpuTime()
      self.cpu              = { new = true, tick = 0, startTime = os.clock(), currentTime = os.clock(), totalTime = 0, updateStart = os.clock(), updateEnd = os.clock(), updateTotal = 0, percent = "0%", timeDelta = Time.deltaTime, fps = 1/Time.deltaTime } 
      if not CPU then CPU = {} ; end
      CPU.Teleporter = self.cpu
  end

  function self:SetCpuTime(start)
      if not self then return end
      if not self.cpu then  if self.SetupCpuTime then self:SetupCpuTime() ; end ; return ; end
      if self.cpu.new then self.cpu.new = false ; return ; end
      if start then self.cpu.tick = self.cpu.tick + 1 ; self.cpu.currentTime = os.clock() ; self.cpu.updateStart = self.cpu.currentTime ; return ; end
      self.cpu.updateTotal = self.cpu.updateTotal + os.clock() - self.cpu.updateStart
      self.cpu.updateFrame = self.cpu.updateTotal / self.cpu.tick
      self.cpu.deltaTime   = Time.deltaTime
      self.cpu.totalTime   = self.cpu.currentTime - self.cpu.startTime
      self.cpu.fps         = 1/Time.deltaTime
      if  self.cpu.totalTime > 0
      then
          self.cpu.percent = string.format( "%.4f%%",(100/self.cpu.totalTime)*self.cpu.updateTotal )
      end
      if not CPU then CPU = {} ; end
      if not CPU.Teleporter then CPU.Teleporter = self.cpu ; end
      return
  end

end


function Teleporter:DestroyObjects(t,selfCall)
    if      type(t) == "nil"      and  self.GameObjects and not selfCall   then  if self.Vehicles then self.Vehicles = false ; end ; if self.Players then self.Players = false ; end ; if self:DestroyObjects(self.GameObjects,true) then return true end
    elseif  type(t) == "string"   and  self[t]                             then  if self:DestroyObjects(self[t],true) then if type(self[t]) == "table" and #self[t] > 0 then self[t] = {} ; else self[t] = false ; end ; return true ; end
    elseif  type(t) == "userdata" and not Slua.IsNull(t)
       and  string.sub(tostring(t),-23) == "(UnityEngine.Texture2D)"       then  GameObject.Destroy(t) ; if self.debug then print("Teleporter():DestroyObjects (Texture)") ; end ; return true
    elseif  type(t) == "userdata" and not Slua.IsNull(t)
       and  string.sub(tostring(t),-18) == "(UnityEngine.Font)"            then  GameObject.Destroy(t) ; if self.debug then print("Teleporter():DestroyObjects (Font)")    ; end ; return true
    elseif  type(t) == "table"    and t[1]  and  type(t[1]) == "userdata"
       and  not Slua.IsNull(t[1]) and selfCall                             then  if t[1].gameObject then GameObject.Destroy(t[1].gameObject)  else  GameObject.Destroy(t[1]) ; end ; if t[3] and string.sub(tostring(t[3]),-23) == "(UnityEngine.Texture2D)" then GameObject.Destroy(t[3]) ; if self.debug then print("Teleporter():DestroyObjects (texture)") ; end ; end ; return true
    elseif  type(t) == "table"                                             then  local ret = false ; for k,v in pairs(t) do if self:DestroyObjects(v,true) then ret = true ; end ; end return ret
    elseif  type(t) == "userdata" and not Slua.IsNull(t)                   then  if t.gameObject then GameObject.Destroy(t.gameObject)  else  GameObject.Destroy(t) ; end ; return true
                                                                           else  return false
    end
    return false
end


function Teleporter:OnDestroy()
  Debug.Log("Teleporter:OnDestroy()")
  if    self.teleporting
  and   self.teleporterSettings
  and   self.teleporterSettings.endPosition
  then 
        Camera.main.fieldOfView = self.defaultFoV
        HBU.TeleportPlayer(self.teleporterSettings.endPosition)
  end
--if    self.teleporterSettings.rb and not Slua.IsNull(self.teleporterSettings.rb)
--then  self.teleporterSettings.rb.isKinematic = true
--end
  if self.Vehicles then self.Vehicles = false ; end
  if self.Players  then self.Players  = false ; end
  self:DestroyObjects()
end


function Teleporter:Update()
  self.tick = self.tick + 1
  self:SetCpuTime(true)
  if  (    HBU.InSeat()  or  HBU.InBuilder()    )
  then
      self:DestroyObjects()
      self:SetCpuTime()
      return
  end
  if not self.teleporting then 
    if self.teleporterSettings and not self.teleporterSettings.updatePos then self:SetDefaults() ; end
    if( self.useGadgetSecondaryKey.GetKey() > 0.5 ) then
      if not self.showing  then
        self.showing = true
        self:CreateTargetNodes()
      else
        self:AimCheck()
      end
    else
      if      self.showing
      then
              if  self.aimedAtTeleportLocation and not Slua.IsNull(self.aimedAtTeleportLocation) then
                self:Teleport(self.aimedAtTeleportLocation)
              end
              self.showing = false

      elseif  not self.showing
      then    self:DestroyObjects()
      end
    end
  elseif  self.teleporting
  then
          self:UpdateTP()
  end
  self:SetCpuTime()
end


function Teleporter:UpdateTP()
    local s = self.teleporterSettings
    if self.useGadgetSecondaryKey.GetKey() > 0.5 then s.interruptKey = true ; else s.interruptKey = false ; end
    if  s.curDist < 0.5
    or  os.clock() > s.startClock + 15
    or  not s
    or  not s.updatePos
    or  not s.player
    or  Slua.IsNull(s.player)
    or  s.interruptKey
    then
          self.teleporting = false 
          s.updatePos      = false
          if      not s.interruptKey  and  s.obj  and  not Slua.IsNull(s.obj)  then    HBU.TeleportPlayer(s.obj.transform.position+self.endPositionMod) ; s.result = "Teleported to s.obj"
          elseif  not s.interruptKey  and  s.endPosition                       then    HBU.TeleportPlayer(s.endPosition) ; s.result = "Teleported to s.endPosition"
          end
          self.vehicles           = false
          self.currentFoV         = self.defaultFoV
          Camera.main.fieldOfView = self.defaultFoV
          if self.debug then echo(s) end
          self:SetDefaults()
          return
    end

    if    s.curDist > s.startDist then s.startDist = s.curDist + 15 ; end
    if    s.curDist > s.startDist/2
    then
        s.factor = 1.1/(s.startDist)*((s.startDist)-math.min(s.startDist,s.curDist))*2
        s.speed = ( (s.startDist) - math.min(s.startDist,s.curDist) + 15)/self.speedUpMod
        s.ymod   = s.factor*s.ymodmax/10
    else
        s.factor = 2.02-(1/(s.startDist)*((s.startDist)-math.min(s.startDist,s.curDist))*2)
        s.speed = math.max( 0.23, s.curDist/self.slowDownMod )
        s.ymod   = 0
    end
    self.currentFoV = self.defaultFoV + ( ( self.maxFoV - self.defaultFoV ) * s.factor )
    Camera.main.fieldOfView = self.currentFoV
    s.player.transform.position = Vector3.MoveTowards( s.curPosition+Vector3(0,s.ymod,0), s.endPosition, s.speed )
    s.curPosition = s.player.transform.position
    s.curDist     = Vector3.Distance( s.curPosition, s.endPosition )
end


function Teleporter:SetDefaults()
    self.teleporterSettings = {
      speed = 0.01,
      updatePos = true,
    }
end


function Teleporter:LoadCustomLocations()
    if    not  Application
    or    not  Application.persistentDataPath
    or    not  self.name
    then  return
    end
    if    not self.customLocations
    or    ( self.customLocations and #self.customLocations > 0 )
    then  self.customLocations = {}
    end
    local settingsStr  = file2string( Application.persistentDataPath.."/userData/User-Teleporter-Locations.txt" )
    local settingsFunc = loadstring(settingsStr)
    if  settingsFunc then self.customLocations = settingsFunc() end
    return true
end


function Teleporter:SaveCustomLocations()
    if    not  Application
    or    not  Application.persistentDataPath
    or    not  self.customLocations
    or        #self.customLocations == 0
    or    not  self.customLocationsFile
    then  return
    end
    local settingsStr = string.format( "local customLocations = %s\nreturn customLocations\n", dumptable(self.customLocations) )
    string2file(settingsStr,self.customLocationsFile,"w")
    print("Saved Custom Teleport Locations:\n",settingsStr)
    return true
end


function Teleporter:AddCustomLocation(nodeName,position,color)
    if not self.customLocations then self.customLocations = {} ; end
    if      not nodeName then nodeName = "Custom Location "..tostring(#self.customLocations+1) ; end
    if      not position then local player = GameObject.Find("Player") ; if player and not Slua.IsNull(player) then position = player.transform.position ; end ; end
    if      not position then Debug.Log() return false ; end
    if      not color    then color = Color(1,1,1,1) ; end
    nodeName = tostring(nodeName)
    position = tostring(position)
    color    = tostring(color)
    self.customLocations[#self.customLocations+1] = { nodeName = nodeName, position = position, color = color }
end


function  Teleporter:shell(cmd) -- Used to open the custom locations file.
    if  cmd == nil then print("usage: shell(cmd)") ; return "",false ; end
    cmd = tostring(cmd) or ""
    if ( cmd == "" ) then return "",false ; end
    local handle = io.popen(cmd)
    if ( handle == nil ) then print("# shell() error while processing command: "..cmd) ; return "",false ; end
    local result = handle:read("*a")
    handle:close()
    if result then return result:sub(1,#result-1) else return "" end
end

function Teleporter:OpenCustomLocationsFile()
    if not self.customLocationsFile then return end
    local actualFileName = "\""..string.gsub(self.customLocationsFile,"/","\\").."\""
    local fullCmd        = "start \"\" "..actualFileName
    print("shell( "..fullCmd.." )")
    print(self:shell(fullCmd))
end


function Teleporter:CreateTargetNodes()
  local parent = HBU.menu.transform:Find("Foreground").gameObject
  local camPos = Camera.main.transform.position

  self.wormholeImage           = HBU.LoadTexture2D(HBU.GetLuaFolder().."/GadgetLua/TeleportIcon.png")
  self.ringImage1              = HBU.LoadTexture2D(HBU.GetLuaFolder().."/GadgetLua/TeleportRing1.png")
  self.ringImage2              = HBU.LoadTexture2D(HBU.GetLuaFolder().."/GadgetLua/TeleportRing2.png")

  self.ring1 = HBU.Instantiate("RawImage",parent)
  HBU.LayoutRect( self.ring1, Rect( (Screen.width*0.5), (Screen.height*0.5),self.ringRadius*2,self.ringRadius*2))
  self.ring1:GetComponent("RawImage").texture = self.ringImage1
  self.ring1:GetComponent("RawImage").color   = Color(0.5,0.5,0.5,0.92)
  self.ring1.transform.pivot     = Vector2(0.5,0.5)

  self.ring2 = HBU.Instantiate("RawImage",parent)
  HBU.LayoutRect( self.ring2, Rect( (Screen.width*0.5), (Screen.height*0.5),self.ringRadius*2,self.ringRadius*2))
  self.ring2:GetComponent("RawImage").texture = self.ringImage2
  self.ring2:GetComponent("RawImage").color   = Color(0.5,0.5,0.5,0.92)
  self.ring2.transform.pivot     = Vector2(0.5,0.5)


  if      self.showPlayers
  then    self:GetAllPlayers()
  else    self.Players = false
  end

  if self.Players and #self.Players > 0 then
      for k,v in pairs(self.Players) do
          if type(k) == "string" and v and not Slua.IsNull(v) and Vector3.Distance( camPos, v.transform.position ) > 10
          then
              local color = Color(math.random(0,100000)*0.00001,math.random(0,100000)*0.00001,math.random(0,100000)*0.00001,1.0)
              local node = HBU.Instantiate("Container",parent)
              node.transform.pivot = Vector2(0.5,0.5)
              node.transform.anchorMin = Vector2(0.5,0.5)
              node.transform.anchorMax = Vector2(0.5,0.5)
              node.transform.sizeDelta = Vector2(1,1)
              node.transform.anchoredPosition = Vector3(0,0,100000)
              local canvasGroup = node:AddComponent("UnityEngine.CanvasGroup")
              canvasGroup.alpha = 0.5
              
              local image = HBU.Instantiate("RawImage",node)
              image.name = "WormHole"
              image.transform.anchorMin = Vector2.zero
              image.transform.anchorMax = Vector2.one
              image.transform.offsetMin = Vector2.zero
              image.transform.offsetMax = Vector2.zero
              image:GetComponent("RawImage").texture = self.wormholeImage
              image:GetComponent("RawImage").color   = color

              local rotSpeed = Mathf.Clamp(Random.value,0.5,1)
              self.TargetNodes[#self.TargetNodes+1] = { node, v, image, rotSpeed, "Player "..tostring(k), color }
          end
      end
  end


  if    self.showVehicles
  then  self:GetAllVehicles()
  else  self.Vehicles = false
  end

  if  self.Vehicles and #self.Vehicles > 0 then
      for k,v in pairs(self.Vehicles) do
          if v and not Slua.IsNull(v) and Vector3.Distance(camPos,v.transform.position) > 10
          then
              local node = HBU.Instantiate("Container",parent)
              node.transform.pivot = Vector2(0.5,0.5)
              node.transform.anchorMin = Vector2(0.5,0.5)
              node.transform.anchorMax = Vector2(0.5,0.5)
              node.transform.sizeDelta = Vector2(1,1)
              node.transform.anchoredPosition = Vector3(0,0,100000)
              local canvasGroup = node:AddComponent("UnityEngine.CanvasGroup")
              canvasGroup.alpha = 0.5
              
              local image = HBU.Instantiate("RawImage",node)
              image.name = "WormHole"
              image.transform.anchorMin = Vector2.zero
              image.transform.anchorMax = Vector2.one
              image.transform.offsetMin = Vector2.zero
              image.transform.offsetMax = Vector2.zero
              image:GetComponent("RawImage").texture = self.wormholeImage
              image:GetComponent("RawImage").color =  Color(0.9, 0.9, 0.9)

              local rotSpeed = Mathf.Clamp(Random.value,0.5,1)
              self.TargetNodes[#self.TargetNodes+1] = { node, v, image, rotSpeed, "Vehicle "..tostring(k), Color(0.9, 0.9, 0.9) }
          end
      end
  end


  for i in Slua.iter( HBU.GetTeleportLocations() ) do
      if  i and not Slua.IsNull(i)
      then
          local node = HBU.Instantiate("Container",parent)
          node.transform.pivot     = Vector2(0.5,0.5)
          node.transform.anchorMin = Vector2(0.5,0.5)
          node.transform.anchorMax = Vector2(0.5,0.5)
          node.transform.sizeDelta = Vector2(1,1)
          local canvasGroup = node:AddComponent("UnityEngine.CanvasGroup")
          canvasGroup.alpha = 0.5
          
          local image = HBU.Instantiate("RawImage",node)
          image.name = "WormHole2"
          image.transform.anchorMin = Vector2.zero
          image.transform.anchorMax = Vector2.one
          image.transform.offsetMin = Vector2.zero
          image.transform.offsetMax = Vector2.zero
          image:GetComponent("RawImage").texture = self.wormholeImage
          image:GetComponent("RawImage").color = i.color
          
          local rotSpeed = Mathf.Clamp(Random.value,0.5,1)
          self.TargetNodes[#self.TargetNodes+1] = { node , i , image , rotSpeed }
      end
  end


  for k,v in pairs({"textGUI1","textGUI2",}) do
      self[v.."_panel"] = HBU.Instantiate( "Panel", parent )
      self[v] = HBU.Instantiate("Text",parent):GetComponent("Text")
      if      self.GUIlayout and #self.GUIlayout > 0
      then    HBU.LayoutRect( self[v.."_panel"].gameObject, unpack(self.GUIlayout[(k-1)%#self.GUIlayout+1]) )                ; self[v.."_panel"]:GetComponent("Image").color = Color(0.2, 0.2, 0.2, 0.0)   ;  HBU.LayoutRect(self[v].gameObject,Rect( unpack(self.GUIlayout[(k-1)%#self.GUIlayout+1]) ) )
      else    HBU.LayoutRect( self[v.."_panel"].gameObject, Rect((Screen.width/2)-175,Screen.height/2+60+((k-1)*27),300,50)) ; self[v.."_panel"]:GetComponent("Image").color = Color(0.2, 0.2, 0.2, 0.0)   ;  HBU.LayoutRect(self[v].gameObject,Rect((Screen.width/2)-175,Screen.height/2+120+((k-1)*27),350,50))
      end
      if      self.GUIcolors and #self.GUIcolors > 0
      then    self[v].color = self.GUIcolors[(k-1)%#self.GUIcolors+1]
      else    self[v].color = Color(  k%2, math.floor(k/2%2), math.floor(k/4%2), 1 )
      end
      self[v].text = ""
      if      self.GUItextAlignment and #self.GUItextAlignment > 0
      then    self[v].alignment = self.GUItextAlignment[(k-1)%#self.GUItextAlignment+1]
      else    self[v].alignment = TextAnchor.MiddleCenter
      end
      if      self.GUIfontSize and #self.GUIfontSize > 0
      then    self[v].fontSize = self.GUIfontSize[(k-1)%#self.GUIfontSize+1]
      else    self[v].fontSize = self.fontSize
      end
  end

  if   not self.font1 then self.font1 = Font.CreateDynamicFontFromOSFont(self.dynamicFonts, self.fontSize) end

  if   self.font1
  then
      --self.textGUI1.font = self.font1
        self.textGUI2.font = self.font1
  end

end


function Teleporter:AimCheck() 
    --return the teleport node that we are aimaing at
    local cl = { ang = 7, node = false, nodeName = false, obj = false, color = false }
    local ring1,ring2 =  false,false
    if self.ring1 then ring1 = self.ring1:GetComponent("RawImage") ; end
    if self.ring2 then ring2 = self.ring2:GetComponent("RawImage") ; end
    if self.textGUI1_panel and self.GUIcolors then self.textGUI1_panel:GetComponent("Image").color = self.GUIcolors[0%#self.GUIcolors+1] ; end
    if self.textGUI2_panel and self.GUIcolors then self.textGUI2_panel:GetComponent("Image").color = self.GUIcolors[1%#self.GUIcolors+1] ; end
    for i,v in pairs( self.TargetNodes ) do
          if      v
          and     v[1] and not Slua.IsNull(v[1])
          and     v[2] and not Slua.IsNull(v[2])
          and     v[3] and not Slua.IsNull(v[3])
          then
                  local screenPos = Camera.main:WorldToScreenPoint(v[2].transform.position)
                  screenPos.x = screenPos.x - (Screen.width * 0.5)
                  screenPos.y = screenPos.y - (Screen.height * 0.5)
                  if( screenPos.z < 0 ) then 
                    screenPos.y = 1000000
                  end
                  screenPos.z = 0
                  v[1].transform.anchoredPosition = screenPos
                  local r = v[3].transform.localEulerAngles
                  v[3].transform.localEulerAngles = r+Vector3(0,0, Time.deltaTime * 180.0 * v[4])
                  local ang = Vector3.Angle(Camera.main.transform.forward,v[2].transform.position-Camera.main.transform.position) 
                  if ang < cl.ang
                  then
                      if  cl.node
                      then
                          cl.node.transform.sizeDelta = Vector2(self.wormholeRadiusSmall*2/90*(90-ang),self.wormholeRadiusSmall*2/90*(90-ang))
                          cl.node:GetComponent("CanvasGroup").alpha = 0.8
                      end
                      cl.ang      = ang
                      cl.node     = v[1]
                      cl.obj      = v[2]
                      if v[5] then cl.nodeName = v[5] else cl.nodeName = v[2].locationName ; end
                      if v[6] then cl.color    = v[6] else cl.color    = v[2].color        ; end
                  else
                      v[1].transform.sizeDelta = Vector2(self.wormholeRadiusSmall*2/90*(90-ang),self.wormholeRadiusSmall*2/90*(90-ang))

                      v[1]:GetComponent("CanvasGroup").alpha = 0.8
                  end

          elseif  v and v[1]
          then    v[1].transform.sizeDelta = Vector2(1,1)
          end
    end

    if  cl.node and not Slua.IsNull(cl.node)
    then
        local r = ring2.transform.localEulerAngles
        ring2.transform.localEulerAngles = r+Vector3(0,0,-1)
        if ring1 then ring1.color = cl.color ; end                                                                     -- set ring color
        if ring2 then ring2.color = Color(1,1,1,0.92) ; end                                                            -- set ring color
        if self.textGUI1_panel then self.textGUI1_panel:GetComponent("Image").color = Color(0.1, 0.1, 0.1, 0.9) ; end
        if self.textGUI2_panel then self.textGUI2_panel:GetComponent("Image").color = Color(0.1, 0.1, 0.1, 0.9) ; end
        cl.node.transform.sizeDelta               = Vector2(self.wormholeRadiusLarge*2,self.wormholeRadiusLarge*2)     -- increase size of rect
        cl.node:GetComponent("CanvasGroup").alpha = 1                                                                  -- increase alpha
        if self.textGUI1 then self.textGUI1.text  = cl.nodeName ; end                                                  -- set text displays
        if self.textGUI1 then self.textGUI1.color = cl.color  ; end
        if self.textGUI2 then self.textGUI2.text  = string.format( "%.2f meters", Vector3.Distance( Camera.main.transform.position, cl.obj.transform.position ) ) ; end

    else
        if self.textGUI1 then self.textGUI1.text  = "" end
        if self.textGUI2 then self.textGUI2.text  = "" end
        if self.textGUI1_panel then self.textGUI1_panel:GetComponent("Image").color = Color(0.1, 0.1, 0.1, 0.0) ; end
        if self.textGUI2_panel then self.textGUI2_panel:GetComponent("Image").color = Color(0.1, 0.1, 0.1, 0.0) ; end
        if ring1 then  ring1.color = Color(0.7,0.7,0.7,0.9)  end
        if ring2 then  ring2.color = Color(0,0,0,0)          end
    end

    if cl and cl.node       then  self.aimedAtNode             = cl.node     ; elseif self.aimedAtNode             then self.aimedAtNode             = nil ; end
    if cl and cl.obj        then  self.aimedAtTeleportLocation = cl.obj      ; elseif self.aimedAtTeleportLocation then self.aimedAtTeleportLocation = nil ; end
end


function Teleporter:GetAllVehicles()
    local vehicles = GameObject.FindObjectsOfType("VehiclePiece")
    local ret = {}
    for v in Slua.iter(vehicles) do 
         if not Slua.IsNull( v ) then ret[#ret+1] = v end
    end 
    if #ret == 0 then if self.Vehicles then self.Vehicles = false ; end ; return ; end
    self.Vehicles = ret
    return self.Vehicles
end


function Teleporter:GetAllPlayers()
  local player_table     = self:iter_to_table(HBU.GetPlayers())
  local player_me        = GameObject.Find("Player")
  local player_table_ret = { }
  if    player_me and not Slua.IsNull(player_me)
  then  player_table_ret[1] = player_me
  end
  for k,v in pairs(player_table) do  if  ( v and not Slua.IsNull(v) )  and  ( not player_me or player_me ~= v )  then  local newID = #player_table_ret+1 ; player_table_ret[newID] = obj ; player_table_ret[v.playerName.name] = player_table_ret[newID] ; end ; end
  self.Players = player_table_ret
  return self.Players
end

function Teleporter:iter_to_table(obj)
    local  ret = {}
    if  type(obj) == "userdata" and string.find(tostring(obj),"Array") then
      for v in Slua.iter(obj) do ret[#ret+1] = v ; end
    end
    return ret
end


function Teleporter:Teleport( obj ) 

    if    self.teleporting
    or    not obj
    or    Slua.IsNull(obj)
    then  return
    end

    local player = GameObject.Find("Player")
    if    not player or Slua.IsNull(player)
    then 
          self.teleporterSettings.player = false
          return
    else 
          self.teleporterSettings.player = player
    end

    if not self.teleporterSettings.rb or (Slua.IsNull(self.teleporterSettings.rb)) then 
      local rb = self.teleporterSettings.player:GetComponent("Rigidbody")
      if not rb or (Slua.IsNull(rb)) then
        self.teleporterSettings.rb = false
        return
      else
        self.teleporterSettings.rb = rb
      end
    end

  --self.teleporterSettings.rb.isKinematic = false
    self.teleporting                       = true
    self.teleporterSettings.obj            = obj
    self.teleporterSettings.updatePos      = true
    self.teleporterSettings.startDist      = Vector3.Distance(self.teleporterSettings.player.transform.position, obj.transform.position)
    self.teleporterSettings.curDist        = self.teleporterSettings.startDist
    self.teleporterSettings.startPosition  = self.teleporterSettings.player.transform.position
    self.teleporterSettings.curPosition    = self.teleporterSettings.startPosition
    self.teleporterSettings.endPosition    = obj.transform.position + self.endPositionMod
    self.teleporterSettings.startHeight    = self.teleporterSettings.startPosition.y
    self.teleporterSettings.endHeight      = self.teleporterSettings.endPosition.y
    self.teleporterSettings.startClock     = os.clock()
    self.teleporterSettings.ymodmax        = ( self.teleporterSettings.startDist + ( self.teleporterSettings.endHeight - self.teleporterSettings.startHeight ) ) * self.maxHeightMod
    self:DestroyObjects()
    return
end


--function main(go) Teleporter.gameObject = go ; return Teleporter ; end

return Teleporter
