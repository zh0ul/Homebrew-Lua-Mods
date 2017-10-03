local Teleporter = {}

function Teleporter:Awake()
  Debug.Log("Teleporter:Awake()")
  self.name                    = "Teleporter"
  self.useGadgetKey            = HBU.GetKey("UseGadget")
  self.useGadgetSecondaryKey   = HBU.GetKey("UseGadgetSecondary")
  self.shiftKey                = HBU.GetKey("")
  self.teleportLocations       = HBU.GetTeleportLocations()
  self.showing                 = false
  self.teleportNodes           = {}
  self.customLocations         = {}
  self.customLocationsFile     = Application.persistentDataPath.."/userData/User-Teleporter-Locations.txt"
  self.vehicles                = false
  self.wormholeImage           = HBU.LoadTexture2D(HBU.GetLuaFolder().."/GadgetLua/TeleportIcon.png")
  self.ringImage1              = HBU.LoadTexture2D(HBU.GetLuaFolder().."/GadgetLua/TeleportRing1.png")
  self.ringImage2              = HBU.LoadTexture2D(HBU.GetLuaFolder().."/GadgetLua/TeleportRing2.png")
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
  self.maxFoV                  = 130
  self.maxHeightMod            = 0.1  -- The teleport distance is multiplied by this number, and the result is how high we will rise until 1/2 way mark.
  self.speedUpMod              = 25   -- Higher numbers == slower speed-up.
  self.slowDownMod             = 40   -- Higher numbers == slower slow-down.
  self.endPositionMod          = Vector3(0,0.10,0)
  self.GameObjects             = { "ring1", "ring2", "teleportNodes", "textGUI1","textGUI2","textGUI3", "textGUI1_panel","textGUI2_panel","textGUI3_panel",  }
  self.tick                    = 0
  self.print                   = function(msg) GameObject.FindObjectOfType("HBChat"):AddMessage("[Teleporter]",msg) end
  self:LoadCustomLocations()
  self:SetDefaults()
end


function Teleporter:DestroyObjects(t,selfCall)
    if      type(t) == "nil"      and  self.GameObjects and not selfCall   then  if self:DestroyObjects(self.GameObjects,true) then return true end
    elseif  type(t) == "string"   and  self[t]                             then  if self:DestroyObjects(self[t],true) then if type(self[t]) == "table" and #self[t] > 0 then self[t] = {} ; else self[t] = nil ; end ; return true ; end
    elseif  type(t) == "table"    and t[1]  and  type(t[1]) == "userdata"
       and  not Slua.IsNull(t[1])                                          then  if t[1].gameObject then GameObject.Destroy(t[1].gameObject)  else  GameObject.Destroy(t[1]) ; end ; return true
    elseif  type(t) == "table"                                             then  local ret = false ; for k,v in pairs(t) do if self:DestroyObjects(v,true) then ret = true ; end ; end return ret
    elseif  type(t) == "userdata" and not Slua.IsNull(t)                   then  if t.gameObject then GameObject.Destroy(t.gameObject)  else  GameObject.Destroy(t[1]) ; end ; return true
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
  -- if    self.teleporterSettings.rb and not Slua.IsNull(self.teleporterSettings.rb)
  -- then  self.teleporterSettings.rb.isKinematic = true
  -- end
  self:DestroyObjects()
end


function Teleporter:Update()
  self.tick = self.tick + 1
  if  (
        -- not HBU.MayControle()
           HBU.InSeat()
        or HBU.InBuilder()
      )
  then
      self:DestroyObjects()
      return
  end
  if not self.teleporting then 
    if self.teleporterSettings and not self.teleporterSettings.updatePos then self:SetDefaults() ; end
    if( self.useGadgetSecondaryKey.GetKey() > 0.5 ) then
      if not self.showing  then
        self.showing = true
        self:GetMyVehicles()
        self:CreateTeleportNodes()
      else
        self:AimCheck()
        self:UpdateTeleportNodes()
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
          echo(s)
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
    -- end
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


function Teleporter:CreateTeleportNodes()
  local parent = HBU.menu.transform:Find("Foreground").gameObject
  local camPos = Camera.main.transform.position

  self.ring1 = HBU.Instantiate("RawImage",parent)
  HBU.LayoutRect( self.ring1, Rect( (Screen.width*0.5), (Screen.height*0.5),self.ringRadius*2,self.ringRadius*2))
  self.ring1:GetComponent("RawImage").texture = self.ringImage1
  self.ring1:GetComponent("RawImage").color   = Color(0.5,0.5,0.5,0.92)
  self.ring1.transform.pivot     = Vector2(0.5,0.5)
  -- self.ring1.transform.anchorMin = Vector2(0.5,0.5)
  -- self.ring1.transform.anchorMax = Vector2(0.5,0.5)


  self.ring2 = HBU.Instantiate("RawImage",parent)
  HBU.LayoutRect( self.ring2, Rect( (Screen.width*0.5), (Screen.height*0.5),self.ringRadius*2,self.ringRadius*2))
  self.ring2:GetComponent("RawImage").texture = self.ringImage2
  self.ring2:GetComponent("RawImage").color   = Color(0.5,0.5,0.5,0.92)
  self.ring2.transform.pivot     = Vector2(0.5,0.5)
  -- self.ring2.transform.anchorMin = Vector2(0.5,0.5)
  -- self.ring2.transform.anchorMax = Vector2(0.5,0.5)


  self.teleportLocations = HBU.GetTeleportLocations()
  for i in Slua.iter( self.teleportLocations ) do
      if  i and not Slua.IsNull(i)
      then
          local node = HBU.Instantiate("Container",parent)
          node.transform.pivot = Vector2(0.5,0.5)
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
          self.teleportNodes[#self.teleportNodes+1] = { node , i , image , rotSpeed }
      end
  end

  self:GetMyVehicles()

  if self.vehicles and #self.vehicles > 0 then
      for k,v in pairs(self.vehicles) do
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
              self.teleportNodes[#self.teleportNodes+1] = { node, v, image, rotSpeed, "Vehicle "..tostring(k), Color(0.9, 0.9, 0.9) }
          end
      end
  end

  for k,v in pairs({"textGUI1","textGUI2","textGUI3"}) do
      self[v.."_panel"] = HBU.Instantiate( "Panel", parent )
      self[v] = HBU.Instantiate("Text",parent):GetComponent("Text")
      if      self.GUIlayout and #self.GUIlayout > 0
      then    HBU.LayoutRect( self[v.."_panel"].gameObject, unpack(self.GUIlayout[(k-1)%#self.GUIlayout+1]) )                ; self[v.."_panel"]:GetComponent("Image").color = Color(0.2, 0.2, 0.2, 0.0)   ;  HBU.LayoutRect(self[v].gameObject,Rect( unpack(self.GUIlayout[(k-1)%#self.GUIlayout+1]) ) )
      else    HBU.LayoutRect( self[v.."_panel"].gameObject, Rect((Screen.width/2)-175,Screen.height/2+60+((k-1)*27),300,50)) ; self[v.."_panel"]:GetComponent("Image").color = Color(0.2, 0.2, 0.2, 0.0)                                              ;  HBU.LayoutRect(self[v].gameObject,Rect((Screen.width/2)-175,Screen.height/2+120+((k-1)*27),350,50))
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

  if   Font 
  then
      local dynamicFonts = {"consolas","Roboto","Arial"}
      local dynamicFont1,dynamicFont2  = Font.CreateDynamicFontFromOSFont(dynamicFonts, self.fontSize)
      if    dynamicFont1 and dynamicFont2
      then
            self.textGUI1.font = dynamicFont1,dynamicFont2
            self.textGUI2.font = dynamicFont1,dynamicFont2
            self.textGUI3.font = dynamicFont1,dynamicFont2
      end
  end

end


function Teleporter:UpdateTeleportNodes()
    --position nodes on screenspace
    for i,v in pairs(self.teleportNodes) do
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
        end
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
    if self.textGUI3_panel and self.GUIcolors then self.textGUI3_panel:GetComponent("Image").color = self.GUIcolors[2%#self.GUIcolors+1] ; end
    for i,v in pairs( self.teleportNodes ) do
          if      v and not Slua.IsNull(v) and v[2] and not Slua.IsNull(v[2])
          then
                  local ang = Vector3.Angle(Camera.main.transform.forward,v[2].transform.position-Camera.main.transform.position) 
                  if ang < cl.ang
                  then
                      if cl.node then cl.node.transform.sizeDelta = Vector2(self.wormholeRadiusSmall*2,self.wormholeRadiusSmall*2) ; cl.node:GetComponent("CanvasGroup").alpha = 0.8 end
                      cl.ang      = ang
                      cl.node     = v[1]
                      cl.obj      = v[2]
                      if v[5] then cl.nodeName = v[5] else cl.nodeName = v[2].locationName ; end
                      if v[6] then cl.color    = v[6] else cl.color    = v[2].color        ; end
                  else
                      -- v[1].transform.sizeDelta = Vector2(self.wormholeRadiusSmall*2,self.wormholeRadiusSmall*2)
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
        if self.textGUI3_panel then self.textGUI3_panel:GetComponent("Image").color = Color(0.1, 0.1, 0.1, 0.9) ; end
        cl.node.transform.sizeDelta               = Vector2(self.wormholeRadiusLarge*2,self.wormholeRadiusLarge*2)     -- increase size of rect
        cl.node:GetComponent("CanvasGroup").alpha = 1                                                                  -- increase alpha
        if self.textGUI1 then self.textGUI1.text  = cl.nodeName ; end                                                  -- set text displays
        if self.textGUI1 then self.textGUI1.color = cl.color  ; end
        if self.textGUI2 then self.textGUI2.text  = string.format( "%.2f meters",                 Vector3.Distance( Camera.main.transform.position, cl.obj.transform.position ) ) ; end
        if self.textGUI3 then self.textGUI3.text  = string.format( "x %.1f\ny %.1f\nz %.1f",   unpack(cl.obj.transform.position) ) ; end

    else
        if self.textGUI1 then self.textGUI1.text  = "" end
        if self.textGUI2 then self.textGUI2.text  = "" end
        if self.textGUI2 then self.textGUI3.text  = "" end
        if self.textGUI1_panel then self.textGUI1_panel:GetComponent("Image").color = Color(0.1, 0.1, 0.1, 0.0) ; end
        if self.textGUI2_panel then self.textGUI2_panel:GetComponent("Image").color = Color(0.1, 0.1, 0.1, 0.0) ; end
        if self.textGUI3_panel then self.textGUI3_panel:GetComponent("Image").color = Color(0.1, 0.1, 0.1, 0.0) ; end
        if ring1 then  ring1.color = Color(0.7,0.7,0.7,0.9)  end
        if ring2 then  ring2.color = Color(0,0,0,0)          end
    end

    if cl and cl.node       then  self.aimedAtNode             = cl.node     ; elseif self.aimedAtNode             then self.aimedAtNode             = nil ; end
    if cl and cl.obj        then  self.aimedAtTeleportLocation = cl.obj      ; elseif self.aimedAtTeleportLocation then self.aimedAtTeleportLocation = nil ; end
end


function Teleporter:GetMyVehicles()
    local vehicles = GameObject.FindObjectsOfType("VehiclePiece")
    local ret = {}
    for v in Slua.iter(vehicles) do 
         if not Slua.IsNull( v ) then ret[#ret+1] = v end
    end 
    if #ret == 0 then if self.vehicles then self.vehicles = nil ; end ; return ; end
    self.vehicles = ret
end


function Teleporter:GetLastVehicle()
    local   veh = HBU.GetMyOldestVehicle()
    if      veh
    and     not Slua.IsNull(veh)
    then    self.vehicle = veh ; Debug.Log("Found oldest vehicle at "..tostring(veh.transform.position) )
    elseif  self.vehicle and Slua.IsNull(self.vehicle)
    then    self.vehicle = nil ; Debug.Log("Oldest vehicle not found.  Wiped record.")
    else    Debug.Log("Oldest vehicle not found.")
    end
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
      local rb = self.teleporterSettings.player.gameObject:GetComponent("Rigidbody")
      if not rb or (Slua.IsNull(rb)) then
        self.teleporterSettings.rb = false
        return
      else
        self.teleporterSettings.rb = rb
      end
    end

    -- self.teleporterSettings.rb.isKinematic = false
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


function main(gameObject)  Teleporter.gameObject = gameObject  return Teleporter end


--[[ External File Dependents
Depends HBU.GetLuaFolder().."/GadgetLua/TeleportRing1.png" 89504e470d0a1a0a0000000d49484452000001000000010008060000005c72a8660000000467414d410000b18f0bfc610500000a3a6943435050686f746f73686f70204943432070726f66696c65000048899d96775454d71687cfbd777aa1cd30142943efbd0d20bd37a9d2446198196028030e3334b121a2021145440415418222068c8622b1228a858060c11e9020a0c4601451517933b25674e5e5bd9797df1f677d6b9fbdf73d67ef7dd6ba0090bcfdb9bc74580a80349e801fe2e54a8f8c8aa663fb010cf00003cc0060b2323302423dc380483e1e6ef44c9113f82208803777c42b00378dbc83e874f0ff499a95c11788d20489d882cdc96489b850c4a9d9820cb17d46c4d4f81431c32831f3450714b1bc981317d9f0b3cf223b8b999dc6638b587ce60c761a5bcc3d22de9a25e48818f11771511697932de25b22d64c15a67145fc561c9bc6616602802289ed020e2b49c4a62226f1c342dc44bc14001c29f12b8eff8a059c1c81f8526ee919b97c6e629280aecbd2a39bd9da32e8de9cec548e406014c464a530f96cba5b7a5a0693970bc0e29d3f4b465c5bbaa8c8d666b6d6d646e6c6665f15eabf6efe4d897bbb48af823ff70ca2f57db1fd955f7a3d008c59516d767cb1c5ef05a0633300f2f7bfd8340f022029ea5bfbc057f7a189e7254920c8b03331c9cece36e67258c6e282fea1ffe9f037f4d5f78cc5e9fe280fdd9d93c014a60ae8e2bab1d253d3857c7a660693c5a11bfd7988ff71e05f9fc3308493c0e17378a28870d194717989a276f3d85c01379d47e7f2fe5313ff61d89fb438d722511a3e016aac31901aa002e4d73e80a21001127340b403fdd1377f7c3810bfbc08d589c5b9ff2ce8dfb3c265e225939bf839ce2d248cce12f2b316f7c4cf12a0010148022a50002a4003e80223600e6c803d70061ec0170482301005560116480269800fb2413ed8088a4009d80176836a500b1a40136801274007380d2e80cbe03ab8016e830760048c83e76006bc01f310046121324481142055480b3280cc2106e4087940fe50081405c54189100f1242f9d026a8042a87aaa13aa809fa1e3a055d80ae4283d03d68149a827e87dec3084c82a9b032ac0d9bc00cd805f683c3e0957022bc1ace830be1ed70155c0f1f83dbe10bf075f8363c023f8767118010111aa28618210cc40d0944a29104848fac438a914aa41e6941ba905ee42632824c23ef50181405454719a1ec51dea8e528166a356a1daa14558d3a826a47f5a06ea2465133a84f68325a096d80b643fba023d189e86c7411ba12dd886e435f42df468fa3df6030181a46076383f1c6446192316b30a598fd9856cc79cc20660c338bc56215b00658076c20968915608bb07bb1c7b0e7b043d871ec5b1c11a78a33c779e2a2713c5c01ae127714771637849bc0cde3a5f05a783b7c209e8dcfc597e11bf05df801fc387e9e204dd0213810c208c9848d842a420be112e121e11591485427da1283895ce2066215f138f10a7194f88e2443d227b991624842d276d261d279d23dd22b3299ac4d7626479305e4ede426f245f263f25b098a84b1848f045b62bd448d44bbc490c40b49bca496a48be42ac93cc94ac993920392d35278296d293729a6d43aa91aa95352c352b3d2146933e940e934e952e9a3d257a52765b032da321e326c99429943321765c628084583e246615136511a289728e3540c5587ea434da69650bfa3f653676465642d65c36573646b64cfc88ed0109a36cd87964a2ba39da0dda1bd9753967391e3c86d936b911b929b935f22ef2ccf912f966f95bf2dff5e81aee0a190a2b053a143e191224a515f3158315bf180e225c5e925d425f64b584b8a979c58725f0956d2570a515aa37448a94f69565945d94b394379aff245e569159a8ab34ab24a85ca599529558aaaa32a57b542f59cea33ba2cdd859e4aafa2f7d067d494d4bcd5846a756afd6af3ea3aeacbd50bd45bd51f691034181a091a151add1a339aaa9a019af99acd9af7b5f05a0cad24ad3d5abd5a73da3ada11da5bb43bb42775e4757c74f2749a751eea92759d7457ebd6ebded2c3e831f452f4f6ebddd087f5adf493f46bf4070c60036b03aec17e834143b4a1ad21cfb0de70d88864e4629465d46c346a4c33f6372e30ee307e61a269126db2d3a4d7e493a99569aa6983e9033319335fb302b32eb3dfcdf5cd59e635e6b72cc8169e16eb2d3a2d5e5a1a58722c0f58deb5a25805586db1eab6fa686d63cdb76eb19eb2d1b489b3d96733cca0328218a58c2bb6685b57dbf5b6a76ddfd959db09ec4ed8fd666f649f627fd47e72a9ce52ced286a5630eea0e4c873a871147ba639ce341c711273527a653bdd313670d67b673a3f3848b9e4bb2cb319717aea6ae7cd736d739373bb7b56ee7dd11772ff762f77e0f198fe51ed51e8f3dd53d133d9b3d67bcacbcd6789df7467bfb79eff41ef651f661f934f9ccf8daf8aef5edf123f985fa55fb3df1d7f7e7fb7705c001be01bb021e2ed35ac65bd61108027d0277053e0ad2095a1df46330263828b826f8698859487e486f28253436f468e89b30d7b0b2b007cb75970b9777874b86c7843785cf45b84794478c449a44ae8dbc1ea518c58dea8cc64687473746cfaef058b17bc5788c554c51cc9d953a2b73565e5da5b82a75d59958c95866ecc938745c44dcd1b80fcc40663d7336de277e5ffc0ccb8db587f59cedccae604f711c38e59c89048784f284c94487c45d8953494e499549d35c376e35f765b277726df25c4a60cae19485d488d4d6345c5a5cda299e0c2f85d793ae929e933e986190519431b2da6ef5eed5337c3f7e632694b932b3534015fd4cf50975859b85a3598e5935596fb3c3b34fe648e7f072fa72f573b7e54ee479e67dbb06b586b5a63b5f2d7f63fee85a97b575eba075f1ebbad76bac2f5c3fbec16bc3918d848d291b7f2a302d282f78bd29625357a172e186c2b1cd5e9b9b8b248af845c35becb7d46e456de56eeddf66b16defb64fc5ece26b25a62595251f4a59a5d7be31fba6ea9b85ed09dbfbcbaccb0eecc0ece0edb8b3d369e79172e9f2bcf2b15d01bbda2be815c515af77c7eebe5a695959bb87b047b867a4cabfaa73afe6de1d7b3f542755dfae71ad69dda7b46fdbbeb9fdecfd43079c0fb4d42ad796d4be3fc83d78b7ceabaebd5ebbbef210e650d6a1a70de10dbddf32be6d6a546c2c69fc78987778e448c8919e269ba6a6a34a47cb9ae16661f3d4b1986337be73ffaeb3c5a8a5ae95d65a721c1c171e7ff67ddcf7774ef89de83ec938d9f283d60ffbda286dc5ed507b6efb4c4752c7486754e7e029df53dd5df65d6d3f1aff78f8b4dae99a33b267cace12ce169e5d3897776ef67cc6f9e90b8917c6ba63bb1f5c8cbc78ab27b8a7ff92dfa52b973d2f5fec75e93d77c5e1cae9ab76574f5d635cebb86e7dbdbdcfaaafed27ab9fdafaadfbdb076c063a6fd8dee81a5c3a7876c869e8c24df79b976ff9dcba7e7bd9edc13bcbefdc1d8e191eb9cbbe3b792ff5decbfb59f7e71f6c78887e58fc48ea51e563a5c7f53febfddc3a623d7266d47db4ef49e8930763acb1e7bf64fef261bcf029f969e584ea44d3a4f9e4e929cfa91bcf563c1b7f9ef17c7ebae857e95ff7bdd07df1c36fcebff5cd44ce8cbfe4bf5cf8bdf495c2abc3af2d5f77cf06cd3e7e93f6667eaef8adc2db23ef18ef7adf47bc9f98cffe80fd50f551ef63d727bf4f0f17d21616fe050398f3fc25771675000000206348524d00007a26000080840000fa00000080e8000075300000ea6000003a98000017709cba513c00000006624b474400ff00ff00ffa0bda793000000097048597300000b1300000b1301009a9c180000000774494d4507e1080e0c192d16a6527c0000163a4944415478daed9d7bac55d59dc73f3f24888ca9026ae561f0018a835225c8086d933a378692a2224ad42126d5984cad224aa41308899a18c88c06449ce834044c0d3e62455a48a831d44e3a0554062d95c8cb0711c4172fc3c823d8357fec75bcfbac7b0efbde7b1eacb3f7f79318ef5ee7dec3dabff5fb7df75a6baff55b2084104208218410420821841042082184104208218410420821841042082184104208218410420821841042082184104208218410420821841042082184104208218410420821841042082184104208218410420821841042082184104208218410420821841042082184104208218410420821841042082184104208218410420821841042082184104208218410420821841042082184686d9c73639c73cfcb1299767ade39374696680e261334dca14f0116022300ccec1a59e584f67ac3ffb819986e66dfca2a8da3874cd05067be07f84329f845971801fcc1db5048001a1eac6739e7063be7ac0edf35c477f76f067acabadda62770b31f160ca943bb986fe3b3645a0940da31ce05c6003f0286d52202ceb9fb80a5c0800a1f7f216b6752c9460380a5deb6dd0e7e60986fe331becd3507a0e07767f9e01fec8bbe063602dbcdcc75f1bb9602e757f9f8056089991d97db9dd0863d813b81dbaafccac766764737837f14f03d5fbc0b78cbccbe520fa0d8f44e3905fee7515de90938e7da9c73abab04ff26e09766f66b057f279e4866c7cdecd7c02fbded42ce77cead76ceb5d510fca576eead1e809e38d51ca4533d01e7dc0ce0ba2a1f2f36b3650aeb9ada672a7057958f579ad9fc46b5ad04402270424771ce2d044656f8ca1dc01366b659d6ad4bfb8c00ee078656ea6199d97405bf04a0a922e09c5b060cacf055ab80f972ae86b4cf0c6062858f3f35b3a90a7e0940c3450038936496ff8c0a5ff1a499bd2a4b36b48d6e042abd0d3808dc011c50f04b001a25027b810780d3823fdb0fcc35b30db26053da6834301be81b7c74185800f457f04b00ea2d02838049c011e09bd4af6f051e35b35db25c53db68303007b82455dc8764667f05b05bc12f01a897085c0a4c014e018e0387bc08bc093c62668765b193d246a7010f01ffe483ff7492d583df022f03ef2bf84f8cd6015453c6c461b6fb6eff241ffc78073b9de41df52c05ff496da3c3c02cdf16a5e0c7b7d524df760a7e0940b739d38ff98ff8277f896dc03a6a5c362cead64b5be7dba4c471df660ff836141a0274cbc156d03edb5fea626e03566b7c19d510ad344f3301b8383544033868669364310940571dacd27bfe4dfe69a319e6f882bfd41663e9b838ab6c9d80d01020cbc1165608fe374956a36df48e56a2cb7b0744c3827fa36fa337833f1be8db544800321d6c468527c85692d9fed2c4a04420cee02ff5c21ef16d9666a46f5b2101a8ea606d74dcd8b39fe43dff61287b3b20118833f84b6f071ef56d97e6baceee22d41c40319d6c351db788ceacb4c24febcde30cfee0ef46038f05c547cc6c82acaa1e40e82c4b2b04ff93d596f7aa271077f0fb36da003c1914f7f66d2d2400df39d97d744ce6b12a6b638f4420dee04fb5d1ab243b34d39c5f4b7a310940be9c6c08c9aab1343b80f99d1a434904a20dfe14f37d9ba699548f44a31280d6675e85b99027ba327e9708441dfca5f679222cf66d2f0128b0a3dd43c7ecbd8bbb93c947221067f0a7da6733b038281e50f473077a14d8d14ea9d0f5df544b0e3f89409cc19f6a9f65744c343ac9fb8204a0602ca4e3a11dcfd4faa512813883ff046ddcd3fb8204a040ce36868ec775bd6066efd7e3fb2502d1063fbe8d5f088a4714f540d2a2f600ee0faebf0096d4f31f9008c417fc2996d0f104a2fb8b68ff9e0574b8ebe938f1f76c230eed3033e79cdbee2fd30e5e12019c730d5d31e89c1b4eb2457608495ab3b34972e9f5017af95f3b46b27d763ff025493aad9dc03633db92b3e0c7cc8e3be79e057e952a1ee09cbbdecc7e5fa478b0020ac02b40bf54d17b66362d2f4f39e7dc00601c70157005706a8d5f79147817781b586b667b5a39f8833a2c022e4b15ed33b39b2400f90dfec94018ecb3cd6c5dab77759d7313806b812b1b7c2bef00af9bd9ea560e7e5f8fb1c0dca07891992d9700e453007e4b9232bac406339bd9c47fbf07c9e93675717c9f14730a7043d0ab49b31bd842b2126e17f039b08f246bce31ff3bbd48b21df503be4f7250ea5060b81f3654621ff03be0e5aee445ec44f0ef30b3bf37b14d1e0346a78af69ad9cd9a03c85ff0b705c10f49e6d8863ff9fd5c8001a589c19ae7049c73b702537de086ac07d67a81eb4c97fda8ff6f6faa7ee921c5683facb83af5513f928338a638e79699d98bf578f287366b424fe0e54000fa3be7dacc6c8d7a00f91280674926c24a543c53ae01ddfe7283b78b41b7bac0bedb7a1770618527fd2adf3ddfdba0fbe9ef8719132bf40c3e245945b9ae966e7f359b35b89dc2331e779ad9cf2500f909fec1c07341f12366f6a766067fda99bb2302ceb969c0e4e02b3f025e32b3d79a6cd3f1c02dc005c147cbcd6c5177c7fc59766bd0bdfc84e47c8134b717e1b097a208c05c926491257699d9edcd7cfa574958d1d9a7e245c04cca4fc1f906586266af9c64dbde04dc49f25ab1c456e03133fba086641ed62c01f0ffde737eeea3c43a339b2d01c88700bc46fb3b6f80ffeacc98b55e5dfe1ac7c503480ebf48bfce5b033cdda8ae7e37870677036dc1bcc23c600f354c7a366b48e0e754fe355574ccccc6e73d367a1420f82707c10fd094ee72671cb5ca8ac152800c071e0e827fbe993d1a4bf0fb7bd86b668f529e43e1545ff7e155ee6d7b17ecd30c429fe8e57d4702d0e284493edf30b3fd8deeeed7984f60237039c9c936257603f79ad9ca68bb9349ddeea5fd604efc3d5c1edc5b97f7f357980fb13ad77d3ff04686ef48005a9030eb4b435eef941cb2bb4fac400486fb402af11e30bd3b790a4e82086c06a6fb3a97b837d513d85ea38d68e01e8a3519be230168b1eeffedc13cc74133fbcbc9ecf277e2ef07044ffe8dc0833175f93b3324001ef4754ff70406d4c9468daaf75f8083e922ef43128016e59f83eb3fd7fba95f5aac520fc7f4b3fdb38227ff6c333bda6a86f7759e1df40466f97bac59684b6b061ad01bf873860f49005a88f382ebb5f57ee2d7f9893493f609bfddc0c3ad18fc81083c9c9a1338d5df63acf6afe423e749005ab3fbdf46724e7c89a3244b6463adef34cadff3cf6ba56e7fc670209d7cf3127fafb1b2defb4a8953f27c9a509e7b0061a3bd1deb493d7e796ffa95d3fc5698f0eb82086ca6fc15e1647fcf31d6d5916c7d3e912f49005a804b83eb8d11d7f5aed4cf6b627ed5574360ada47c96fdae88abbb31c39724002dc019c1f5bb913efd6fa57d63cf37c0d3396e93a7fd3d025ce8ef3d46decdf02509400b8cffd3b3c3fbcdeca308eb791ac996de124bf230eecf980f48e75e9cea6d105b3d3fa2fc6461cbeb3c405e7b005707d7b18ea7a7d0be9fffa393bdb1a749c1f50ac90e46fcbd4f89b4aa9b337c4a021031c382eb2d91d6f386d4cf2f511c5eaa628398d892e1531280883927b8de1e61f77f02ed69bc76377b3fff49ee05bc46fbda807ede16b1b13dc3a7240011138e2b3f88b08ed7a67e5e45f15855c516b1f041864f490062c4397779507430b689359f672f9dbdf7f5020a40fa9eaff43689a997b297f27d01957c4b0210219705d79f4458c771a99fd7e779e63f23c0d657b1492c7c92e15b1280080993657e1a611daf4afdbc96e2b2b68a4d62e1d30cdf92004448d895fc2cc23a5e91fa794381056043159bc4c26719be25018890bec1f597918dff8793daf157afa3b65a7418b087d44e416f9b98f832c3b7240011f20fc1756ce3eb8b533f6f416ca9629b18d89be15b128008090fc3fc4164f54ba799daa1f82fb3416c29b87e90e15b128008098f3beb1359fdd227eaec52fc97d960506475eb93e15b1280083925b83e33b2fa9d9dfaf973c57f990dce8eac6e6766f896042042c21c710323ab5f7a22699fe2bfcc06b14db20dccf0addc7597f3c850e7dc33913e550e29fecb6c7066646d3594e444e7dc5204017094e7da8b89638aff321b58646de5f26efc1ef23f218a4b117a00465cefdb2f4e8d257b519e81b688f40a9eb8db22aadb700d015a9f1d66f68b68fa94ce2da77db2eb7409c0771991000e44d6568b818bf26cfc3c0e0142c58e6d33503ad75c3f7542cb6cb03fb2ba7d9af739813c0ac0b7c1f581c8ea975e5ffe7dc57f990dbe8cac6e07327c4b021021c783eb6f22ab5ffae8ecc18aff321bec8eac6edf64f896042042c231f55f23abdfced4cf4315ff6536d81959ddfe9ae15b128008f9bfe0ba7f64f54bcf720f57fc97d9605b6475eb9fe15b128008092792a25a5f6e665b524f9241b1e5c26b26fede4b1b808e7adbc4c4d919be2501889030c1c6b911d6317df4d4e8023ffd4757b1492c9c9be15b128008f930b81e18611dd3a7cf8e2bb0008cab6293581898e15b128008792fb83e2fc23aa693615eed9ceb5fb4c8f7f77c75159bc4c27919be2501880d33fb5b5074466c01e673e1bd932aba96e291bee77762cb8de87de68c0cdf920044cae1e03ac6e59ce98331261650002656b1452c5c94e153128088f922b88eee6047335b4d7b328c41ceb9f105eafe8fa77df67f9fb7456c0ccbf0290940c484073bc6fabefd77a99f6f29d0d3ff962a368889e1193e25018898f5c1f58848ebf932ed19712e70cedd5480a7ff4dc005fef290b7418c8cc8f0290940ac98d91aca776ef575ce5d10613d0f03cb524577e6f98d80bfb73b5345cbbc0d62abe70594e72774dea724002dc4c1e03ac6a3a730b317697fbfdc07b83bc76d7237eda9b63ff4f71e235764f89204a005783fb81e15715d17a77e6e73ce5d97c3a7ff75405b957b8e8d5119be24016801c22edb55ceb928d33a9bd93a6079aa6886736e448e827f04302355b4dcdf738c75353a9e54bc4602d09af300e9040ea752bef22cb6fa2e02b6a68a66e5613ec0dfc3ac54d1567fafb17235e547807d9bd7f17fde7b00009f04d7e3eaecdc56e75ec563a4760a020f3be74e6de1e03f157898d48e3f7f8fb1dabf928f7c92e700c9bb00fc31b8fe719d9fdacecc5cbd1cd1cc3e00e6a58a2e03e6b6a208f83acff5f750629ebfc7ba047ec9fe75aefa8f337c4802d042c380e7287f1d788673ee870d1e3fd6faf77b8005a9e251c0e3ad341cf0757d9cf2c9b405c09e3ad9a851f5fe21e5ebff9df72109400b13a6996a6b90d8b85a1cd4ffdd301f345b80a7829ec0c2569818f4755c183cf99ff2f7340a1856a38d68c053bf9a6feccc7b701441005606d7d738e7fa3622f8bb3b360d82ff7bfeff7f0b7a028380a7627e45e8ebf614e5c77c2ff0f792beb7615db54ff8fbf51601ef13d764f88e04a0058701cbe97806dff82605847523f84905ca169249b47432ca19ceb939310d099c73fd9d7373287fd577d4d77d4b957b1bd605fb3483d0278e79df9100e480ff0dae7fd6a86140383175a2de4095e007f81ad8086c37b3ff06eea1fc15611bf09b18f60ef83afc26e83e6f05eef175dfeeefe5ebd4e7992210daad926debcccf327c269f0fc822dca4736e30104ee63c62667f6af6d33f982bc80afe7068310d981c7ce547c04b66f65a936d3a9e64575fb8c76279f89ebf2bf79a65b706ddcb4f808782e2dbcd6c9704203f22f02c302455b4c9cca6377b08507a6dd8d5e04f7de758e02ee0c2e0a3ddc02ae07533dbdba8ae3e49269f89c1381f92fd0c8babadf0ebec3d57b35983db6921303255b4d3cc7eae1e40be04a00d981314ff9b99bdd56811a8e0d8dd0afee07b6f05a6527eb86689f52439f636d49a6acba7ee1e4db240a6d24aca4324bbfa5eec8c2db2ee3d14ca2604ff18e0df83e247f3bcfaaf9002e01bfbb7941ff6b0c1cc6636f1dfef4172124e4dc19ffabed38029c00d543f687437c944dc0e6017f0394926a243b44f8ef6f242d28fe4acbec1be9ec32b3ce94bec2349e6f17257b6f47642047698d9df9bd8268f519e9e7caf99dd5c9498289a004c06a605c5b39bb131a5966e7f27bf7f82ef9e5fd9e05b79c70f3356c76a8b2ed4632cc96ac5348b8a30fb5f4801f08dfe4af0b47ccfcca6b572f057e8b28f23d9d17605e51b5bbac35192433bde06d6d62b7b6f0c22e09c5b44f982a57d66765391e2a18802703df04050fc1f8d4a4c79b21ddd39371cb89864027410c971577d491273f4f2bf768ce424dcfd244774ef265905b7ad91c7759d4cdbf81ed3af82e20566f67b0940fe45e079207d26df17c054333b9ea7e06f91b668ba8d9c733d4952b19d932ade6366ff5234fbf728a8df3d115c9f4379ae3a057fb39e40890dbab558a806ee0c82bf924f480072ec746f019b83e2db9c73972af8f32d02be8d6f0b8a3737fa75b004203ea6036197ff170afedc8b40d8c6c7bd2f20012896c37d0bac088a473ae7a62af8f32902be6d4706c52bbc2f14d3e64577ba0a138200f79ad96605ff496b93badbd2e729782a282ee4c49f7a00e5cca23c6b10c0fd35eee757f047d413f0bf7b7f584c79b2520940419d6d6785a1c050caf7b62bf85b5b0466f8360dbbfe3b250002337b12f838289ee89cbb51c1dfda22e0db303c7efd63dfe6b2b14c50e62cab81de41f14c33dba0e06fbd3901e7dc683aa6213f6266136455f5002af17885b2d93ea18882bf857a02becd6677b28d2500e2bbd384c244907d81397eebad82bf0544c0b7d51cca4ff8055859947dfe1280ee3bda7c6053507c09f09082bf6544e021df666936f9b6159a03e8d4b8731930307422609d823fea3981b1745cecf3a9994d95e524005d75b415b49f14d387246bce3660b5823f4a119840b2f5f910c9f666808366364916d310a03bdc011c4e057f4fe01fbda329f8e31a0e4cf06dd3d3b7551fdf7677c85a1280ee7280e4649bdedeb14a5cecbb9a0afe384460ac6f93123d7d9b2df06d282400ddee62f627592958da3072dc77314702f34a6f07c44969a3d3484e531ee9dba4b4bbb3b4d1ab3f8dc927a03980028e2f0701938023a9f12524a7e03c5a844324226ba3c124affad2b3fd7dfc937f05495a3334549300d423f84b8eb497249f60f8d4df0fccadb4625034a48d46932cf209dff31ff6ddfefee84d8d04a0cec15f3ab8e24c6029e5e7c89778d2cc5e95251bda463702f755f8e820c984df01b4564302d088e00f0efdacb44e0092e3b9e6cbc91ad23e33e8b8b10782f7fc5ab025016868f0a7fe2e3c53aec40ee089ae26151155db6704c97efea1153eae78c6a3444002d0d0e04ffdfd0ce0ba2a1f2f36b3650ae19ada672ac961a8955879a2e5bd12010940671c6c30f0236a3ba8b30d78908e5b8921593efc8c99bdaf70ee52bb5c4a92c0b3520feb08f0786736f66488c0ff14fded8d04c0b9b38031240762d6f47470ce2d05ceaff2f10bc0927a1f3e92c3f6e84992b7ffb62abff2b199ddd1c5efac2402bb80b7ccec2b09809ceedc9473d4d43574cedd47b25ea0926dbf30b35b64f113daef253a1eda01490ebf15ddcde41388c0d7c04633fb4c730022dd13e80decae755ce89c1b42b2426d4007839b5d236b9fd0766f5428de03ccaa35879f178141245981be92b525008d76e67b7c6fa0a704a05b0270dc3ff5ff5396690cda0bd048754d1cf7a7743c864c64b319f8a9825fe4e5c936c61f42224e6ca7e79d73636409218410420821841042082184104208218410420821841042082184104208218410420821841042082184104208218410420821841042082184104208218410420821841042082184104208218410420821841042082184104208218410420821841042082184104208218410420821841042082184104208218410420821841042082184104208218410420821841042082184104208215a9cff077570206e39a372240000000049454e44ae426082
Depends HBU.GetLuaFolder().."/GadgetLua/TeleportRing2.png" 89504e470d0a1a0a0000000d49484452000001000000010008060000005c72a8660000000467414d410000b18f0bfc610500000a3a6943435050686f746f73686f70204943432070726f66696c65000048899d96775454d71687cfbd777aa1cd30142943efbd0d20bd37a9d2446198196028030e3334b121a2021145440415418222068c8622b1228a858060c11e9020a0c4601451517933b25674e5e5bd9797df1f677d6b9fbdf73d67ef7dd6ba0090bcfdb9bc74580a80349e801fe2e54a8f8c8aa663fb010cf00003cc0060b2323302423dc380483e1e6ef44c9113f82208803777c42b00378dbc83e874f0ff499a95c11788d20489d882cdc96489b850c4a9d9820cb17d46c4d4f81431c32831f3450714b1bc981317d9f0b3cf223b8b999dc6638b587ce60c761a5bcc3d22de9a25e48818f11771511697932de25b22d64c15a67145fc561c9bc6616602802289ed020e2b49c4a62226f1c342dc44bc14001c29f12b8eff8a059c1c81f8526ee919b97c6e629280aecbd2a39bd9da32e8de9cec548e406014c464a530f96cba5b7a5a0693970bc0e29d3f4b465c5bbaa8c8d666b6d6d646e6c6665f15eabf6efe4d897bbb48af823ff70ca2f57db1fd955f7a3d008c59516d767cb1c5ef05a0633300f2f7bfd8340f022029ea5bfbc057f7a189e7254920c8b03331c9cece36e67258c6e282fea1ffe9f037f4d5f78cc5e9fe280fdd9d93c014a60ae8e2bab1d253d3857c7a660693c5a11bfd7988ff71e05f9fc3308493c0e17378a28870d194717989a276f3d85c01379d47e7f2fe5313ff61d89fb438d722511a3e016aac31901aa002e4d73e80a21001127340b403fdd1377f7c3810bfbc08d589c5b9ff2ce8dfb3c265e225939bf839ce2d248cce12f2b316f7c4cf12a0010148022a50002a4003e80223600e6c803d70061ec0170482301005560116480269800fb2413ed8088a4009d80176836a500b1a40136801274007380d2e80cbe03ab8016e830760048c83e76006bc01f310046121324481142055480b3280cc2106e4087940fe50081405c54189100f1242f9d026a8042a87aaa13aa809fa1e3a055d80ae4283d03d68149a827e87dec3084c82a9b032ac0d9bc00cd805f683c3e0957022bc1ace830be1ed70155c0f1f83dbe10bf075f8363c023f8767118010111aa28618210cc40d0944a29104848fac438a914aa41e6941ba905ee42632824c23ef50181405454719a1ec51dea8e528166a356a1daa14558d3a826a47f5a06ea2465133a84f68325a096d80b643fba023d189e86c7411ba12dd886e435f42df468fa3df6030181a46076383f1c6446192316b30a598fd9856cc79cc20660c338bc56215b00658076c20968915608bb07bb1c7b0e7b043d871ec5b1c11a78a33c779e2a2713c5c01ae127714771637849bc0cde3a5f05a783b7c209e8dcfc597e11bf05df801fc387e9e204dd0213810c208c9848d842a420be112e121e11591485427da1283895ce2066215f138f10a7194f88e2443d227b991624842d276d261d279d23dd22b3299ac4d7626479305e4ede426f245f263f25b098a84b1848f045b62bd448d44bbc490c40b49bca496a48be42ac93cc94ac993920392d35278296d293729a6d43aa91aa95352c352b3d2146933e940e934e952e9a3d257a52765b032da321e326c99429943321765c628084583e246615136511a289728e3540c5587ea434da69650bfa3f653676465642d65c36573646b64cfc88ed0109a36cd87964a2ba39da0dda1bd9753967391e3c86d936b911b929b935f22ef2ccf912f966f95bf2dff5e81aee0a190a2b053a143e191224a515f3158315bf180e225c5e925d425f64b584b8a979c58725f0956d2570a515aa37448a94f69565945d94b394379aff245e569159a8ab34ab24a85ca599529558aaaa32a57b542f59cea33ba2cdd859e4aafa2f7d067d494d4bcd5846a756afd6af3ea3aeacbd50bd45bd51f691034181a091a151add1a339aaa9a019af99acd9af7b5f05a0cad24ad3d5abd5a73da3ada11da5bb43bb42775e4757c74f2749a751eea92759d7457ebd6ebded2c3e831f452f4f6ebddd087f5adf493f46bf4070c60036b03aec17e834143b4a1ad21cfb0de70d88864e4629465d46c346a4c33f6372e30ee307e61a269126db2d3a4d7e493a99569aa6983e9033319335fb302b32eb3dfcdf5cd59e635e6b72cc8169e16eb2d3a2d5e5a1a58722c0f58deb5a25805586db1eab6fa686d63cdb76eb19eb2d1b489b3d96733cca0328218a58c2bb6685b57dbf5b6a76ddfd959db09ec4ed8fd666f649f627fd47e72a9ce52ced286a5630eea0e4c873a871147ba639ce341c711273527a653bdd313670d67b673a3f3848b9e4bb2cb319717aea6ae7cd736d739373bb7b56ee7dd11772ff762f77e0f198fe51ed51e8f3dd53d133d9b3d67bcacbcd6789df7467bfb79eff41ef651f661f934f9ccf8daf8aef5edf123f985fa55fb3df1d7f7e7fb7705c001be01bb021e2ed35ac65bd61108027d0277053e0ad2095a1df46330263828b826f8698859487e486f28253436f468e89b30d7b0b2b007cb75970b9777874b86c7843785cf45b84794478c449a44ae8dbc1ea518c58dea8cc64687473746cfaef058b17bc5788c554c51cc9d953a2b73565e5da5b82a75d59958c95866ecc938745c44dcd1b80fcc40663d7336de277e5ffc0ccb8db587f59cedccae604f711c38e59c89048784f284c94487c45d8953494e499549d35c376e35f765b277726df25c4a60cae19485d488d4d6345c5a5cda299e0c2f85d793ae929e933e986190519431b2da6ef5eed5337c3f7e632694b932b3534015fd4cf50975859b85a3598e5935596fb3c3b34fe648e7f072fa72f573b7e54ee479e67dbb06b586b5a63b5f2d7f63fee85a97b575eba075f1ebbad76bac2f5c3fbec16bc3918d848d291b7f2a302d282f78bd29625357a172e186c2b1cd5e9b9b8b248af845c35becb7d46e456de56eeddf66b16defb64fc5ece26b25a62595251f4a59a5d7be31fba6ea9b85ed09dbfbcbaccb0eecc0ece0edb8b3d369e79172e9f2bcf2b15d01bbda2be815c515af77c7eebe5a695959bb87b047b867a4cabfaa73afe6de1d7b3f542755dfae71ad69dda7b46fdbbeb9fdecfd43079c0fb4d42ad796d4be3fc83d78b7ceabaebd5ebbbef210e650d6a1a70de10dbddf32be6d6a546c2c69fc78987778e448c8919e269ba6a6a34a47cb9ae16661f3d4b1986337be73ffaeb3c5a8a5ae95d65a721c1c171e7ff67ddcf7774ef89de83ec938d9f283d60ffbda286dc5ed507b6efb4c4752c7486754e7e029df53dd5df65d6d3f1aff78f8b4dae99a33b267cace12ce169e5d3897776ef67cc6f9e90b8917c6ba63bb1f5c8cbc78ab27b8a7ff92dfa52b973d2f5fec75e93d77c5e1cae9ab76574f5d635cebb86e7dbdbdcfaaafed27ab9fdafaadfbdb076c063a6fd8dee81a5c3a7876c869e8c24df79b976ff9dcba7e7bd9edc13bcbefdc1d8e191eb9cbbe3b792ff5decbfb59f7e71f6c78887e58fc48ea51e563a5c7f53febfddc3a623d7266d47db4ef49e8930763acb1e7bf64fef261bcf029f969e584ea44d3a4f9e4e929cfa91bcf563c1b7f9ef17c7ebae857e95ff7bdd07df1c36fcebff5cd44ce8cbfe4bf5cf8bdf495c2abc3af2d5f77cf06cd3e7e93f6667eaef8adc2db23ef18ef7adf47bc9f98cffe80fd50f551ef63d727bf4f0f17d21616fe050398f3fc25771675000000206348524d00007a26000080840000fa00000080e8000075300000ea6000003a98000017709cba513c00000006624b474400ff00ff00ffa0bda793000000097048597300000b1300000b1301009a9c180000000774494d4507e1080e0c173a0bf6fa35000017714944415478daed9d7bac55d59dc73f3f6554a816116de5a1680b88434bad2223b64dea90c692624b7dc43ac4a41a93d6d65749e90462a2264633a3015f13db86a04983d658292d26d4348c4d3a15ab88ad95085caca220ad1610b52204bbe68fbd76ef3aebeec3b9f79eb32febecfdfd2484bdf7b9f7dcb57eebf7fbaec75e0f10420821841042082184104208218410420821841042082184104208218410420821841042082184104208218410420821841042082184104208218410420821841042082184104208218410420821841042082184104208218410420821841042082184104208218410420821841042082184104208218410420821841042082184104208218410420821841042082184104208218410427437ceb919ceb987648996767ac839374396181a4c2628dda10f07ee06a60298d979b2ca41edf5a4bfdc005c6f661fca2ae571984c50aa337f17f8551efc62404c057ee56d282400a507ebf1ceb9f1ce39ebc0774df0cdfd8b8161b2eea019065cecbb05133a502ee6cbf878995602103ac689c00ce0f3c0a47644c039771df00030a6e0e33765ed9614d9680cf080b7eda0831f98e4cb78862f738d0128f8ddf13ef8c7fb47ef00eb811e337303fcae0780539a7cfc30b0cccc0ec8ed0e6ac361c095c0654d7ee45533bb6290c17f26f051ff781bf08c99fd4d2d807a7354e014f8eb3307d21270cecd72cead6e12fc2f00df31b31f2bf8fb5123991d30b31f03dff1b68b39c539b7da3937ab8de0cfcbf928b50054e33473907eb5049c73f3810b9a7cbcd4cc962bacdb2a9f79c0554d3e5e65668bcb2a5b098044e0a08ee29cbb1b9856f0955b80bbcc6c83acdb91f2990adc004c2c6a6199d9f50a7e09c0908a80736e3930b6e0ab1e0716cbb94a299ff9c09c828fdf30b3790a7e0940e922001c4b36ca3fb2e02bee31b39fcb92a596d1d781a2b7017b802b80b715fc1280b2446027f03d6078f46bbb81dbcc6c9d2c382465341d58048c8a3eda0b2c01462bf825009d168171c05ce003e0fde0c73701b79ad936596e48cb683c7023705af07804d9c8fe4a60bb825f02d02911381db804381c3800bce745e0f7c02d66b657163b2465341cb809f8371ffc4793cd1efc1078147849c17f70340fa09932660ed3e39bfd737df0e31dec68b277d40b15fc87b48cf6020b7d59e4c18f2fabb9beec14fc12804173aceff37fe06bfe9ccdc05ada9c362c3ad64a5bebcb24e7802fb3eff93214ea020ccac156d23bda9f37313703abd5bf4caa8b968fd3cc0626075d34803d6636571693000cd4c18adef3bfe06b1b8d30a717fc7959cca4efe4ac867902425d80560e767741f0ff9e6c36da7aef6839035e3b204a0bfef5be8c7e1ffdda585fa64202d0d2c1e617d4209bc846fbf3814189409ac19fb7c26ef1651632cd97ad90003475b059f45dd8b39bec3dff5e68783b20114833f8f3b703b7fab20bb9a0bfab083506504f275b4ddf25a20b8a66f869be799ac11ffdde74e08ee8f10766365b56550b207696070a82ff9e66d37bd512483bf87d19ad03ee891e1fe5cb5a4800fee964d7d177338fc75b2dec9108a41bfc4119fd9c6c8566c829ed6c2f2601a896934d209b3516b20558dcaf3e944420d9e00f58eccb34646e27361a9500743fb7178c85dc3590febb4420e9e0cfcbe7aef8b12f7b09408d1dedbbf4ddbd77e96076f29108a419fc41f96c0096468fc7d4fddc81c36aec68871734fd5f68670f3f89409ac11f94cf72fa6e343ad7fb8204a066dc4ddf433b7ed8ee974a04d20cfe8394f130ef0b12801a39db0cfa1ed7f5b099bdd489ef9708241bfcf8327e387a3cb5ae0792d6b505704374ff26b0ac937f4022905ef0072ca3ef094437d4d1fec36ae8705fa5efc0df83651cda6166ce39d7e36f4307cf4500e75ca933069d7353c896c84e20dbd6ec04b2bdf4460047f81fdb4fb67c7637f016d9765a5b81cd66b6b162c18f991d70ce3d08fc20783cc639f75533fb659de2c16a28008f01c7058f5e34b36bab52cb39e7c600e7026703670047b6f995fb803f00cf024f99d98e6e0efe280df7029f0a1eed32b38b2400d50dfe0b8138d81799d9da6e6fea3ae766035f023e5b72569e077e6d66abbb39f87d3a6602b7458fef35b31512806a0ac0cfc8b68cce5967660b86f0ef1f4676ba4d471cdf6f8a7909f0b5a85513b21dd84836136e1bf0576017d9ae39fbfdcf1c41b6dbd171c0c7c90e4a9d084cf1dd86227601bf001e1dc8be88fd08fe2d66f68f212c933b80e9c1a39d6676b1c600aa17fcb3a2e0876ce7d8d26b7e3f1660403e30d8f6988073ee1bc03c1fb8314f034f7981eb4f937d9fffb733485fd8a598eebb15e7041f1d477610c725ceb9e566f6d34ed4fcb1cd86a025f0682400a39d73b3cc6c8d5a00d5128007c906c2720acf942ba1d9df68f05e31185413d8375baf023e5150d33fee9be73b4bcacf68dfcd9853d032f833d92ccab5ed34fb9bd9ace4728acf78dc6a66df94005427f8c7033f891edf6266bf19cae00f9d793022e09cbb16b830faca578047ccec8926e938123899eccd47fe06e018b2d38df216e001b25375dea5f74dc00ee03533dbd7e47bcf072e054e8d3e5a6166f70eb6cfdfca6e2595d517c9ce1708b9bc0e87bdd445006e23db2c32679b995d3e94b57f930d2bfa5b2b7e125840e32938ef03cbccecb182ef1d4936d16972d4ea190c5bc97642de60667b0afed645c09564af157336017798d9cb6d6ce661432500feeffdc48f7de4ac35b34512806a08c013f4bef306f8517ffaac9d6af2b7d92f1e4376f845f83a6f0d707fdcd477ce4d02ce8a84a2936c029e33b39e82aec1d5c0ac685ce176df9218f4a0e7507509fc98cab78247fbcdec7c0940f7077fd1abbf0bcd6cf7a1a8f5fb290279804c213bdc2264b199ad4ad4d617901de11db284ec2d449cb79e01daa76c011805c4afff2aff4ab00e5381e34d3e9fec74f01739689bfb09ac073e1d05ff76e09a5483dfe76315700dbd0773e2f3f0e9286f035ecf5f301e621d4efb6ee0c916be2301e842e23e7029af7772871c6ced1489c0141f48392f02d70f669f824320021b80eb7d9a73aef1796a6b924fab81c20eb0a685ef4800baacf97f79d4cdd96366bf2bd1f95d077e7f4c54f3af07be5fd6abbd92ecb013f8be4f7bd81218d3211b9595eedf01e140a7791f92007429ff1eddffb6d3b57e3e59a5138ee947fb174635ffa266afe21217817dc0a2a825b0d0e7b16da1cde70c94d01af86d0b1f920074112745f74f75bac6ef708db480ded1feedc0cddd18fc9108dc1c8c091ce9f398aafd8b7ce42409407736ff67919d139fb38f6c8a6caae9bd96c6d777b7e7cd7e3f99a75b4560278d9b6f9ee6f39a2a4f7b5fc939bccaa70955b9051017dab3a99ed4e3a7f78633fc1687037edddc0af0e9df40e336eb17fa3ca7985647b6f4f960be2401e8024e8feed7279cd6ab82eb3529bfea6b23b056d138ca7e55c2c95ddfc29724005dc0c8e8fe0f89d6fedfa07761cffbc0fd152e93fb7d1e013ee1f39e227f68e14b12802ee8ff87a3c3bbcdec9504d3399c6c496fceb26e7add37c8f18070efc579de06a9a5f3151a4f16b6aa8e0354b505704e749fea049a4be85dcfff4ad1c29e0a8ac063642b18f179bf24d1a46e68e1531280849914dd6f4c349d5f0bae1fa13e3cd2c40629b1b1854f490012e663d17d4f82cdffd9f46ee3b5bdd97afe8ab6029ea0776ec071de16a9d1d3c2a724000913f72b5f4e308d5f0aae1f0f84615255033fcadbe34d6c910a2fb7f0290940a24ef6e9e8d19ed406d6fc3e7be1eebdbf0eaecfaa70e57f56933c7fd6db24a556ca4e1ad70514f9960420413e15ddbf9e601acf0dae9f0e66fc8da4bccd3c52e0349fc73cc09e6e62935478bd856f49001224de2cf38d04d37876701dce3d9f5a832180a94df27e7682697da3856f490012246e4afe25c1349e115caf0bae27d740002637c9fb1909a6f52f2d7c4b029020a3a2fbb712ebff4f2158f197efdbef17fc4ca881004cc81737f9bcff73a5a0b74d4abcd5c2b7240009f291e83eb59975610d18be6b3e99fa7072131ba4d602dad9c2b7240009122f9dfd4c6a356070bda5cacdcb7e76d3b634b14d0a7ca6856f490012243eee6c4462e90b4fd4090f9e38a146027042131b8c4b2c9d235af8960420410e8fee8f4dd8f9ff5ae5fee54118d5c406a989e0b12d7c4b029020f11e71631376fe5dc1f531351280639ad82035111cdbc2b72ad75cae22139d733f4cb456792fb81e5e230118dec406c726565613c94e74ae2c75100047bab3ebf6d7ac2c8af2ba3faa614f4bcc772acd6108216a4b1d6a1d23adfd0026077dc923e8dd81f600f02f35f1bb03c1f511518dbb39a1744e5117a0fbd96266df4ea64de9dc0a7a07bb8e0e04606f8d04606f707d7470fd766265b514f864950ba28a5d8058b1535b0c14ee35775c70fd6e8d5a9eef36b1c1eec4d2f946d5c704aa28001f46f76f2796be707ef9c71376fea112c18f37b14d0abcddc2b7240089f72fa1771bea54088fce1e9fb0f30f95088e6f629b1478bf856f490012243e45e78f89a56f6b703d31b8de512301d8d1c4065b134be71f5bf896042041fe1edd8f4e2c7de12877b8fcf5b51a09c06b4d6cb039b1748e6ee15b1280c4fb9790d8fc7233db18d424e3f2bdf0fcf97f5b6b10fc5bf3b30e7ddef30540fbbc6d52e28416be250148bc7909706282690c8f9e9a9e700d58760b687a139ba4c2892d7c4b0290207f8eeec72698c6f0f4d97033cc0d3510800d4df2fe6c82691ddbc2b7240009f262747f5282690c37c33cc73937da7703f6009b2a1cfc9b7c1ef1793ea7894d52e1a416be2501480d33fb53f468641e6009a57107f07cf0283c18e3b90a0bc0734df2fc7cbe37622a789f19d9c2b7240089b237ba4f713a677830c69cc0c97aaa1afd51dee634b1452a7cb2854f490012e6cde87e5282c1b09adecd30c639e7cea726f8bce6a3ffbbbc2d5263520b9f9200244c5c8b4e49349dbf08ae2fa53e5cdac4062931a5854f490012e6e9e83ed513771ea577479c539d7317d5a0f6bf0838d5dfbee76d9022535bf8940420e1bee61a1a576e8d72ce9d9a603af702cb834757a63660d9e1e01f0d5c193c5aee6d905a3a4fa5717f42e77d4a02d045ec89ee533c7a0a33fb29bdef9747005757b84caea677abed3ffbbca7c8192d7c4902d005bc14dd9f99705a9706d7b39c731754b0f6bf0098d524cfa971660b5f920074017193ed6ce75c92db3a9bd95a6045f068be736e6a85827f2a303f78b4c2e739c5b41a7d4f2a5e2301e8ce718070038723699c79965a7aefa57116e0c2703cc039f7912e0dfed1c0c2e0d1269fd7543987c623c03eac6affbfea2d0080d7a3fb733b5d5b74b8557107c14a41e0e6e024ddbf7761f01f09dc4cb0e2cfe73155fb17f9c8eb550e90aa0bc0ff46f75fe870adedcccc75ca11cdec65e0f6e0d1a780db7211e8c2e0bfcde721e7769fc78e047e6eff0e27fd0b2d7c4802d045dd809fd0f83a70a473ee7325f71fdbfdfd1dc092e0f199c09dddf47ad0a7f54e1a07d396003b3a64a3b2d2fd391ae7ff3bef4312802e26de6463564962e3da7150ff7b937cd06c04ee8b5a027777c3c0a04fe3dd51cd7f9fcfd399c0a4366d4409b57e33dfa8fc062d75108055d1fd79ceb9516504ff60fba651f07fd4ffffa7a825300eb82fe557843e6df7d178ccf7129f97306f93066a9ff8e73b2d02de27ce6be13bd56b25d7400070ce3d41e309343f2a63124a9153b772d482e0cf7907580f8c211b450fc701d600f79bd9cee8bb26016751def97a9b80e7e2158bbec97f755483eef3e3193b0e92b79e7eda873283dfff9d6f00df0a1eed37b3ca2fd0aacb8194cf013383fbaf001d1780d03173c73d58b3b51fc1df63669b9d73db80054160cf02663ae79699d963c1dfef017a9c7323c9e6b24f062674a00bb519d8906fe611e5e122b2e9bd2322a1b8c3cc5e0e0238cc63de12c039d77310db941af4115f29f099ca539716c078201eccb9c5cc7e53e2dfb47e8c15b40afeb86b712d7061f495af008f98d9134dd2712470b26f499c4036c7fd18b223baf30ae000d97af777c936be7ccbd7dcafe51b78167ceff964abfae235162be2f7fc03c96b2bbb9554565f046e8a1e5f6e66db2400d5118107a3daf00533bbbee4bf59d87c1d4cf007df3913b80af844f4d176e071e0d771d7a083f9194db693cf9ca89f0fd97a86a5cd66f8f537cf43d5e48fd27637302d6cf598d937d502a89600cc026e8c1effa7993d53b6081438f6a082bfa0cf3a8fc6c335739e26db636f5dbb5b6df9adbba7934d90299a49f91ed9aabe9ff6c716adf21e0be51004ff0ce0bfa2c7b75679f65f2d05c017f6cf683cec619d992d18c2bf7f18d949386d057ff07dc3814b80afd178c866dc32d8086c01b6017f25db89e83d60bfff9923bc901c477656df789fce2905357dce2eb2cd3c1e1dc892de7e88c01633fbc71096c91d346e4fbed3cc2eae4b4cd44d002e04ae8d1e2f1a8a8529ed34fbfbf9fdb37df3fcb32567e579dfcd589daa2d06908e9964b31543ee35b3151280ea8ac063516df9a2995ddbcdc15fd0643f976c45db1934be3e1c0cfbc80eed781678aa53bbf7a62002ceb97b699cb0b4cbcc2eaa533cd45100be0a7c2f7afcdf656d4c79a81ddd393785ded781e3e87d133082deb911fbc94ec2cddf006cc7bffe2bf3b8ae43691bdf62fa41f4788999fd5202507d117888ecb558ce9bc03c333b50a5e0ef92b218721b39e786916dc5f6b1e0f10e33fb8fbad9ffb09afadd5dd1fdc768dcab4ec13f54355066831e6f9377828f06356db89f5c19057f914f48002aec74cfd0f71cbecb9c73a72bf8ab2d02be8c2f8b1e6f28fb75b004203dae279b0117f26d057fe545202ee303de179000d4cbe13e0456468fa739e7e629f8ab2902be6ca7458f577a5fa8a7cdebee7405038200d798d90605ff212b938edbd2ef53705ff4b896037f6a0134b290c65d83006e68733dbf823fa19680ffd91be2c7346e562a01a8a9b36d2de80a4ca4711b6b057f778bc07c5fa671d37fab04406066f700af468fe738e7beaee0ef6e11f06538277afcaa2f73d95826687096d5c051d1e30566b64ec1df7d6302ceb9e9f4dd86fc03339b2dabaa0550c49d05cf16f90d4514fc5dd412f065b6a89f652c0110ff3c4d28de08721470a35f7aabe0ef0211f06575238d27fc02acaacb3a7f09c0e01d6d31f042f4f834e026057fd788c04df4dd18f5055fb6426300fdea772e07c6c64e04ac55f0273d263093be937dde30b379b29c0460a08eb692de93624690ed9ab31958ade04f520466932d7d7e8f6c7933c01e339b2b8ba90b3018ae20db2d370ffe61c0bf7a4753f0a7d51d98edcb66982fab11beecae90b5240083e56db2936d8ea2f10c85c9bea9a9e04f430466fa32c919e6cb6c892f4321011874137334d94cc17cc1c801dfc49c06dc9ebf1d1087a48c86939d3e34cd9749beba335fe8359a72f613d018400dfb97e380b9c00741ff12b253706eadc321128995d178b2577de168ff085ff3af24dbd60c75d524009d08fedc917692ed2718d7fabb81db8a660c8a52ca683ad9249ff83dff5edfec1f8dded448003a1cfcf9c115c7020fd0788e7cce3d66f67359b2d432fa3a705dc1477bc806fcde467335240065047f74f867d13c01c88ee75a2c272ba57ce6d377610f44eff935614b02506af007bf179f2997b305b86ba09b8a88a6e533956c3dffc4828f0bcf78940848004a0dfee0f7e7031734f978a9992d5708b7553ef3c80e432d62d5c1a6f74a042400fd71b0f1c0e769efa0ce59c0f7e9bb9418b2e9c33f34b39714ce032a97d3c936f02c6a617d00dcd99f853d2d44e0ffeafef64602e0dcf1c00cb20331dbaa1d9c730f00a734f9f8616059a70f1fa960790c23dbb7ffb2263ff2aa995d31c0ef2c12816dc03366f63709809ceec4c039da6a1a3ae7ae239b2f5064db37cdec5259fca0f67b84be877640b687dfcac1eee41389c03bc07a33fb8bc60044d812380ad8de6ebfd03937816c86da983e06373b4fd63ea8ed9e2c78bc0358d8ee1e7e5e04c691ed0af437595b0250b6337fd7b706864900062500077cadff3fb24c39682d4099ea9a39ee97e97b0c9968cd06e0cb0a7e51959a6d863f84441cdc4e0f39e766c812420821841042082184104208218410420821841042082184104208218410420821841042082184104208218410420821841042082184104208218410420821841042082184104208218410420821841042082184104208218410420821841042082184104208218410420821841042082184104208218410420821841042082184104208218410420821841042082184104208218410427439ff0f7f00930f6c188e740000000049454e44ae426082
--]]
