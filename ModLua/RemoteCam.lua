local RemoteCam = {}

function RemoteCam:Awake()

  Debug.Log("RemoteCam:Awake()")

  self.showVehicles    = true
  self.showPlayers     = true

  self.keys            = {
      lmb              = HBU.GetKey("UseGadget"),
      rmb              = HBU.GetKey("UseGadgetSecondary"),
      zoomIn           = HBU.GetKey("ZoomIn"),  -- HBU.DisableGadgetMouseScroll()    Use these to disable/enable Gadget Selection.
      zoomOut          = HBU.GetKey("ZoomOut"), -- HBU.EnableGadgetMouseScroll()     (ex: when placing a vehicle, use Disable so ZoomIn/ZoomOut can be used to change spawn distance)
      escape           = HBU.GetKey("Escape"),
      shift            = HBU.GetKey("Shift"),
      control          = HBU.GetKey("Control"),
      alt              = HBU.GetKey("Alt"),
      submit           = HBU.GetKey("Submit"),                      -- Default: Enter
      move             = HBU.GetKey("Move"),                        -- Default: W / S
      strafe           = HBU.GetKey("Strafe"),                      -- Default: D / A
      jump             = HBU.GetKey("Jump"),                        -- Default: Space
      run              = HBU.GetKey("Run"),                         -- Default: Left-Shift
      crouch           = HBU.GetKey("Crouch"),                      -- Default: C
      ChangeCameraView = HBU.GetKey("ChangeCameraView"),            -- Default: V
      ChangeThirdView  = HBU.GetKey("ChangeThirdPersonCameraMode"), -- Default: B
      navback          = HBU.GetKey("NavigateBack"),                -- Default: Escape
      action           = HBU.GetKey("Action"),                      -- Default: F
      inventory        = HBU.GetKey("Inventory"),                   -- Default: I
      showcontrols     = HBU.GetKey("ShowControls"),                -- Default: F1
      flipvehicle      = HBU.GetKey("flipVehicle"),                 -- Default: L
      tilde            = { GetKey = function() if Input.GetKey(KeyCode.BackQuote)  then return 1 else return 0 ; end ; end, GetKeyDown = function() return Input.GetKeyDown(KeyCode.BackQuote)  ; end,  GetKeyUp = function() return Input.GetKeyDown(KeyCode.BackQuote)  ; end, },
      arrowl           = { GetKey = function() if Input.GetKey(KeyCode.LeftArrow)  then return 1 else return 0 ; end ; end, GetKeyDown = function() return Input.GetKeyDown(KeyCode.LeftArrow)  ; end,  GetKeyUp = function() return Input.GetKeyDown(KeyCode.LeftArrow)  ; end, },
      arrowr           = { GetKey = function() if Input.GetKey(KeyCode.RightArrow) then return 1 else return 0 ; end ; end, GetKeyDown = function() return Input.GetKeyDown(KeyCode.RightArrow) ; end,  GetKeyUp = function() return Input.GetKeyDown(KeyCode.RightArrow) ; end, },
      arrowu           = { GetKey = function() if Input.GetKey(KeyCode.UpArrow)    then return 1 else return 0 ; end ; end, GetKeyDown = function() return Input.GetKeyDown(KeyCode.UpArrow)    ; end,  GetKeyUp = function() return Input.GetKeyDown(KeyCode.UpArrow)    ; end, },
      arrowd           = { GetKey = function() if Input.GetKey(KeyCode.DownArrow)  then return 1 else return 0 ; end ; end, GetKeyDown = function() return Input.GetKeyDown(KeyCode.DownArrow)  ; end,  GetKeyUp = function() return Input.GetKeyDown(KeyCode.DownArrow)  ; end, },
      wheel            = { KeyUpData = { { tick = 0, }, { tick = 0, }, }, GetKey = function() return ( Input.GetAxis("Mouse ScrollWheel") * -1 ) ; end, GetKeyDown = function() local r = {false,false,false} ; local v = Input.GetAxis("Mouse ScrollWheel") ; if v ~= 0 then r[1] = true end ; if v > 0 then r[2] = true end ; if v < 0 then r[3] = true end ; return unpack(r) ; end,  GetKeyUp = function() if not self or not self.keys or not self.keys.wheel or not self.keys.wheel.KeyUpData or not self.tick then return false ; end ; local a_index,b_index = (self.tick-1)%2+1,(self.tick)%2+1 ; local d = self.keys.wheel.KeyUpData ; if self.tick ~= d[b_index].tick then d[b_index].tick = self.tick ; for k,v in pairs({self.keys.wheel.GetKeyDown()}) do d[b_index][k] = v ; end ; end ; if d[a_index].tick == self.tick - 1 then return d[a_index][1],d[a_index][2],d[a_index][3] ; else return false,false,false  ; end ; end, },
      exp2             = {
        tick        = 0,
        inputString = "²",
        keyDown     = false,
        keyUp       = false,
        keyValue    = 0.0,
        GetKey      = function(booleanReturn) if not self or not self.keys or not self.keys.exp2 or not self.keys.exp2.inputString then if booleanReturn then return false else return 0 ; end ; end ; if Input and Input.inputString and Input.inputString == self.keys.exp2.inputString then if booleanReturn then return true ; else return 1 ; end ; else if booleanReturn then return false else return 0 ; end ; end ; end,
        GetKeyDown  = function()
            if not self or not self.keys or not self.keys.exp2 or not self.keys.exp2.TickKey then return false end
            self.keys.exp2.TickKey()
            return self.keys.exp2.keyDown
        end,
        GetKeyUp    = function()
            if not self or not self.keys or not self.keys.exp2 or not self.keys.exp2.TickKey then return false end
            self.keys.exp2.TickKey()
            return self.keys.exp2.keyUp
        end,
        TickKey    = function()
            if not self or not self.keys or not self.keys.exp2 or not self.keys.exp2.keyValue or not self.tick or not self.keys.exp2.tick or self.keys.exp2.tick == self.tick then return end
            local s = self.keys.exp2
            s.tick = self.tick
            local curKey = s.GetKey(true)
            if          curKey and s.keyValue == 0                                     then s.keyValue = 1 ; s.keyDown = true ; s.keyUp = false ; s.keyDownTime = os.clock() ; print( "keyDown = true ; keyUp = false ; keyDownTime = "..tostring(os.clock()) )
            elseif      curKey and s.keyValue == 1 and s.keyDownTime+0.7 > os.clock()  then s.keyDownTime = os.clock()
            elseif  not curKey and s.keyValue == 1 and s.keyDownTime+0.7 < os.clock()  then s.keyValue = 0 ; s.keyDown = false ; s.keyUp = true ; print( "keyDown = false ; keyUp = true ; keyDownTime = "..tostring(os.clock()).." ; os.clock() = "..tostring(os.clock()) )
            elseif                 s.keyUp                                             then s.keyUp    = false ; print( "keyDown = false ; keyUp = false ; keyDownTime = "..tostring(os.clock()) )
            end
        end,
      },
        -- if Input and Input.inputString == "²" then return
  }

  self.activateKey1   = self.keys.tilde

  self.CamModes = {
    [0]   = "ActionCameraMode",     ActionCameraMode     = 0,
    [1]   = "FixedCameraMode",      FixedCameraMode      = 1,
    [2]   = "LooseCameraMode",      LooseCameraMode      = 2,
    [3]   = "LookaroundCameraMode", LookaroundCameraMode = 3,
    Third                = 3,
    First                = 1,
    camOffset            = Vector3(0,0,0),
    camDistance          = 10,
    camDistanceLastSet   = os.clock(),
  }

  self.Actions               = {
      SwitchToFirstPerson    = function() Camera.main:GetComponent("HBPlayer"):SwitchToFirstPersonView() ; end,
      SwitchToThirdPerson    = function(camMode) camMode = camMode or self.CamModes.Third ; if not camMode or not self.CamModes or not self.CamModes[camMode] then camMode = 3 ; end ; local camModeName = self.CamModes[camMode] ; if camModeName then Camera.main:GetComponent("HBPlayer"):SwitchToThirdPersonView(camMode) ; if self.target and not Slua.IsNull(self.target) then Camera.main:GetComponent("HBPlayer"):GetComponent(camModeName).target = self.target.transform ; end ; end ; end,
      SetCam                 = function() if self.target or HBU.InSeat() then self.Actions.SwitchToThirdPerson() ; self.Actions.SetCamDistance() else self.Actions.SwitchToFirstPerson() ; end ; end,
      SetCamDistance         = function(dist)  dist = dist or self.CamModes.camDistance ; if not tonumber(dist) then dist = self.CamModes.camDistance else self.CamModes.camDistance = dist ; end ; Camera.main:GetComponent("HBPlayer"):GetComponent(self.CamModes[self.CamModes.Third]):IncreaseCameraDistance(-100000) ; Camera.main:GetComponent("HBPlayer"):GetComponent(self.CamModes[self.CamModes.Third]):IncreaseCameraDistance(dist) ; self.CamModes.camDistanceLastSet = os.clock() ; end,
      SetPlayerMovement      = function(toggle) if type(toggle) ~= "boolean" then toggle = true ; end ; Camera.main:GetComponentInParent("rigidbody_character_motor").enabled = toggle ; end,
      GetPlayerPosition      = function() return GameObject.Find("Player").gameObject:GetComponent("Rigidbody").transform.position ; end,
  }

  self.Path =                {
       gadget                = HBU.GetLuaFolder().."/GadgetLua/",
       modlua                = HBU.GetLuaFolder().."/ModLua/",
       userdata              = Application.persistentDataPath,
       gadget_user           = Application.persistentDataPath.."/Lua/GadgetLua/",
       modlua_user           = Application.persistentDataPath.."/Lua/ModLua/",
  }

  self.print = function(msg) GameObject.FindObjectOfType("HBChat"):AddMessage("[RemoteCam]",msg) end

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


  self.GameObjects           = {  "TargetNodes", "ring1", "ring2", "ring3", "textHUD1", "textHUD2", "textHUD3", "textGUI1", "textGUI2", "textGUI1_panel", "textGUI2_panel", "Wormhole1", "Ring1", "Ring2", "Ring3", "wormholeImage", "font1" }
  self.TargetNodes           = {}
  self.ringRadius            = 64
  self.tickActual            = 0
  self.tick                  = 0
  self.mode                  = -1
  if self.vehicles and #self.vehicles > 0 then self.vehicles  = {} ; end
  self.enabled               = true
  self.temporaryDisable      = false
  self.wormholeRadiusSmall   = 16
  self.wormholeRadiusLarge   = 32
  self.ringRadius            = 128

end


function RemoteCam:Enable()
    self:Awake()
end


function RemoteCam:Disable()
    self:OnDestroy()
end


function RemoteCam:EnableCheck()

    if      self.disable
    then    self:Disable() ; self.disable = false ; return false

    elseif  self.enabled
    and     (
                 ( HBU.InBuilder      and      HBU.InBuilder()     )
            )
    then    self:Disable() ; self.temporaryDisable = true ; return false

    elseif  self.temporaryDisable
    and     (
                  ( not HBU.InBuilder      or      not HBU.InBuilder()  )
            )
    then
            self:Enable() ; return false

    elseif  self.toggleKey and self.toggleKey.GetKeyDown()
    then    if self.enabled then self:Disable() else self:Enable() ; return false ; end
    end

    return  self.enabled
end


function RemoteCam:SetTarget(target)
          if      target and not Slua.IsNull(target)
          then    self.target = target
          end
          self.Actions.SetCam()
end


function RemoteCam:ClearTarget()
    if self.target        then self.target        = false ; end
    if self.aimedAtTarget then self.aimedAtTarget = false ; end
    if self.rb            then self.rb            = false ; end
    if self.player        then self.player        = false ; end
    if self.hbplayer      then self.hbplayer      = false ; end
    HBU.EnableGadgetMouseScroll()
end


function RemoteCam:Update()

    if not self or not self.keys or not self.activateKey1 then return ; end

    self.tickActual = ( self.tickActual or 0 ) + 1

    if not self:EnableCheck() then return ; end

    self.tick = self.tick + 1

    if    HBU.InBuilder()
    then  self:ClearTarget() ; self:DestroyObjects() ; return
    end

    if      self.mode == -3 then self.mode = self.mode + 1 ; self:ClearTarget() ; return
    elseif  self.mode  < -1  then self.mode = self.mode + 1 ; return
    elseif  self.mode == -1  then self.mode = self.mode + 1 ; print("Mode:-1") ; print("Mode:0") ; return
    end

    if    not self.player or Slua.IsNull(self.player) then self.player = GameObject.Find("Player") ; end

    if    self.activateKey1.GetKeyDown()
    and   self.mode == 0
    then
          self:GetAllVehicleParts()
          self:CreateTargetNodes()
          self:SetupHUD()
          HBU.DisableGadgetMouseScroll()
          self.mode = 1
          print("Mode:"..tostring(self.mode))
          return

    elseif self.mode == 1
    then
          self:AimCheck()
    end

    if      self.mode == 1
    and     self.aimedAtTarget          and not Slua.IsNull(self.aimedAtTarget)
    and     self.activateKey1.GetKey() == 0
    then
            self.wasInVehicle = HBU.InSeat()
            if    self.wasInVehicle
            then
                  self.lastVehicle = self:GetCurrentVehiclePart()
                  if    self.lastVehicle
                  then  self.originalLoc = self.lastVehicle.transform.position
                  else  self.originalLoc = GameObject.Find("Player").gameObject:GetComponent("Rigidbody").transform.position
                  end
            else  self.originalLoc  = GameObject.Find("Player").gameObject:GetComponent("Rigidbody").transform.position
            end
            self:SetTarget(self.aimedAtTarget)
            self.mode = 2
            print("Mode:"..tostring(self.mode))

    elseif  self.mode == 1
    and     ( self.activateKey1.GetKey() == 0 )
    and     (  not self.aimedAtTarget  or  Slua.IsNull(self.aimedAtTarget)  )
    then
            self.mode = -3
            if not HBU.InSeat() then Camera.main:GetComponentInParent("rigidbody_character_motor").enabled = true ; end
            self:DestroyObjects()
            print("Mode:"..tostring(self.mode))

    elseif  ( self.mode == 2 and self.activateKey1.GetKey() == 0 )
    then
          if    not self.aimedAtTarget or Slua.IsNull(self.aimedAtTarget)
          then
                self.mode = -3
          else
                self.mode = 3 ; HBU.DisableGadgetMouseScroll() ; print("HBU.DisableGadgetMouseScroll()")
          end
          self:DestroyObjects()
          print("Mode:"..tostring(self.mode))

    elseif  self.mode == 3
    then
            self:KeysCheck()
            if    ( self.activateKey1.GetKeyDown() ) --self.keys.navback.GetKey() > 0.5
            or    not self.aimedAtTarget
            or    Slua.IsNull(self.aimedAtTarget)
            or    ( self.wasInVehicle and not HBU.InSeat() )
            then
                  self.mode = 4
                  self:ClearTarget()
                  print("Mode:"..tostring(self.mode))
                  return

            elseif  HBU.InSeat() and not self.wasInVehicle
            then
                  self.mode = -3
                  self:ClearTarget()
                  print("Mode:"..tostring(self.mode))
                  return
            end

    elseif  self.mode == 4
    then
            self.Actions.SetCam()
            self.mode = self.mode + 1
            print("Mode:"..tostring(self.mode))

    elseif  self.mode > 4 and self.mode < 60
    then    self.mode = self.mode + 1

    elseif  self.mode > 59
    then
            print("Mode:60")
            self.mode = -3
            if     not self.wasInVehicle and not HBU.InSeat() then  print("Teleporting player to "..tostring(self.originalLoc)) ;  GameObject.Find("Player").transform.position = self.originalLoc + Vector3(0,7,0) --  HBU.TeleportPlayer(self.originalLoc); 
            elseif     self.wasInVehicle and HBU.InSeat()
            and        self.lastVehicle
            and        not Slua.IsNull(self.lastVehicle)      then  print("Teleporting vehicle to "..tostring( self.originalLoc)) ; self.lastVehicle.transform.position = self.originalLoc + Vector3(0,3,0) ; self.Actions.SetCam() ; self.lastVehicle = false
            elseif not self.wasInVehicle and HBU.InSeat()     then  print("Detected user hopped into a vehicle so will not set cam")  -- do nothing in this case.
                                                              else  print("self.Actions.SetCam()")  ; self.Actions.SetCam()
            end
            print("Mode:-10")
    end

end


function RemoteCam:CreateTargetNodes()
  local parent    = HBU.menu.transform:Find("Foreground").gameObject
  local camPos    = Camera.main.transform.position
  local playerPos = self.Actions.GetPlayerPosition()

  self.Wormhole1          = HBU.LoadTexture2D(HBU.GetLuaFolder().."/GadgetLua/TeleportIcon.png")
  self.Ring1              = HBU.LoadTexture2D(HBU.GetLuaFolder().."/GadgetLua/TeleportRing1.png")
  self.Ring2              = HBU.LoadTexture2D(HBU.GetLuaFolder().."/GadgetLua/TeleportRing2.png")

  self.ring1 = HBU.Instantiate("RawImage",parent)
  HBU.LayoutRect( self.ring1, Rect( (Screen.width*0.5), (Screen.height*0.5),self.ringRadius*2,self.ringRadius*2))
  self.ring1:GetComponent("RawImage").texture = self.Ring1
  self.ring1:GetComponent("RawImage").color   = Color(0.5,0.5,0.5,0.92)
  self.ring1.transform.pivot     = Vector2(0.5,0.5)

  self.ring2 = HBU.Instantiate("RawImage",parent)
  HBU.LayoutRect( self.ring2, Rect( (Screen.width*0.5), (Screen.height*0.5),self.ringRadius*2,self.ringRadius*2))
  self.ring2:GetComponent("RawImage").texture = self.Ring2
  self.ring2:GetComponent("RawImage").color   = Color(0.5,0.5,0.5,0.92)
  self.ring2.transform.pivot     = Vector2(0.5,0.5)

  if      self.showPlayers
  then    self:GetAllPlayers()
  else    self.Players = false
  end

  if  self.Players and #self.Players > 0 then
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
              image:GetComponent("RawImage").texture = self.Wormhole1
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
              image:GetComponent("RawImage").texture = self.Wormhole1
              image:GetComponent("RawImage").color =  Color(0.9, 0.9, 0.9)

              local rotSpeed = Mathf.Clamp(Random.value,0.5,1)
              self.TargetNodes[#self.TargetNodes+1] = { node, v, image, rotSpeed, "Vehicle "..tostring(k), Color(0.9, 0.9, 0.9) }
          end
      end
  end


  if HBU.GetTeleportLocations
  then
      for i in Slua.iter( HBU.GetTeleportLocations() ) do
          local node = HBU.Instantiate("Container",parent)
          node.transform.pivot = Vector2(0.5,0.5)
          node.transform.anchorMin = Vector2(0.5,0.5)
          node.transform.anchorMax = Vector2(0.5,0.5)
          node.transform.sizeDelta = Vector2(32,32)
          local canvasGroup = node:AddComponent("UnityEngine.CanvasGroup")
          canvasGroup.alpha = 0.3

          local img = HBU.Instantiate("RawImage",node)
          img.name = "WormHole1"
          img.transform.anchorMin = Vector2.zero
          img.transform.anchorMax = Vector2.one
          img.transform.offsetMin = Vector2.zero
          img.transform.offsetMax = Vector2.zero
          img:GetComponent("RawImage").texture = self.Wormhole1
          img:GetComponent("RawImage").color = i.color
          
          local rotSpeed = Mathf.Clamp(Random.value,0.5,1)
          self.TargetNodes[#self.TargetNodes+1] = { node , i , img , rotSpeed }
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

  if    self.Fonts and self.Fonts.Consolas
  then  self.textGUI2.font = self.Fonts.Consolas
  end

end


function RemoteCam:KeysCheck()

    local scroll = Input.GetAxis("Mouse ScrollWheel") * -1
    if scroll == 0 then scroll = (self.keys.zoomIn.GetKey() - self.keys.zoomOut.GetKey()) * -0.1 ; end
    local scrollMod = self.keys.shift.GetKey()
    if scrollMod == 0 then scrollMod = self.keys.run.GetKey() ; end
    if scrollMod == 0 then scrollMod = 1 else scrollMod = scrollMod * 10 end
    if scrollMod == 1 then scrollMod = 10 - math.min( 9, (os.clock() - self.CamModes.camDistanceLastSet)*20 ) ; end

    -- If remote cam is active on a target, handle ZoomIn and ZoomOut
    if self.mode == 3 and scroll ~= 0 then print( "os.clock() - self.CamModes.camDistanceLastSet = "..tostring( os.clock() - self.CamModes.camDistanceLastSet ) ) ; self.Actions.SetCamDistance(self.CamModes.camDistance + (scroll*scrollMod) ) ; print( "self.Actions.SetCamDistance("..tostring(self.CamModes.camDistance).." + ("..tostring(scroll).."*"..tostring(scrollMod).." )" ) ; end

    -- If remote cam is active on a target, handle Arrow Keys/Offset.
    if   self.mode == 3  and  self.keys.arrowl.GetKeyUp() and ( self.keys.shift.GetKey() + self.keys.run.GetKey() > 0.5 ) then self.CamModes.camOffset = Vector3( self.CamModes.camOffset.x, self.CamModes.camOffset.y + 0.2, self.CamModes.camOffset.z ) end
    if   self.mode == 3  and  self.keys.arrowr.GetKeyUp() and ( self.keys.shift.GetKey() + self.keys.run.GetKey() > 0.5 ) then self.CamModes.camOffset = Vector3( self.CamModes.camOffset.x, self.CamModes.camOffset.y - 0.2, self.CamModes.camOffset.z ) end
    if   self.mode == 3  and  self.keys.arrowl.GetKeyUp() and ( self.keys.shift.GetKey() + self.keys.run.GetKey() == 0  ) then self.CamModes.camOffset = Vector3( self.CamModes.camOffset.x+0.2, self.CamModes.camOffset.y, self.CamModes.camOffset.z ) end
    if   self.mode == 3  and  self.keys.arrowr.GetKeyUp() and ( self.keys.shift.GetKey() + self.keys.run.GetKey() == 0  ) then self.CamModes.camOffset = Vector3( self.CamModes.camOffset.x-0.2, self.CamModes.camOffset.y, self.CamModes.camOffset.z ) end
    if   self.mode == 3  and  self.keys.arrowu.GetKeyUp() then self.CamModes.camOffset = Vector3( self.CamModes.camOffset.x, self.CamModes.camOffset.y, self.CamModes.camOffset.z+0.2 ) end
    if   self.mode == 3  and  self.keys.arrowd.GetKeyUp() then self.CamModes.camOffset = Vector3( self.CamModes.camOffset.x, self.CamModes.camOffset.y, self.CamModes.camOffset.z-0.2 ) end

    return true
end

--[[
function RemoteCam:AimCheck() 

  if self.textGUI1_panel and self.GUIcolors then self.textGUI1_panel:GetComponent("Image").color = self.GUIcolors[0%#self.GUIcolors+1] ; end
  if self.textGUI2_panel and self.GUIcolors then self.textGUI2_panel:GetComponent("Image").color = self.GUIcolors[1%#self.GUIcolors+1] ; end

  local closestAngle = 6
  local closestNode = false
  local closestNodeName = ""
  local closestTarget = false
  local closestTargetColor = Color(1,1,1,1)

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
            --rotate the wormhole image
            local r = v[3].transform.localEulerAngles
            v[3].transform.localEulerAngles = r+Vector3(0,0, Time.deltaTime * 180.0 * v[4])
            local ang = false
            if    v and v[2] and v[2].transform.position
            then  ang = Vector3.Angle(Camera.main.transform.forward,v[2].transform.position-Camera.main.transform.position) 
            end
            if    ang and ang < closestAngle then
                  closestAngle  = ang
                  if closestNode then closestNode.transform.sizeDelta = Vector2(32,32) ; end
                  closestNode   = v[1]
                  closestTarget = v[2]
                  if v and v[5] then closestNodeName    = v[5] elseif v[2] and v[2].locationName  then  closestNodeName    = v[2].locationName ; end
                  if v and v[6] then closestTargetColor = v[6] elseif v[2] and v[2].color         then  closestTargetColor = v[2].color        ; end
            else
                  v[1].transform.sizeDelta = Vector2(32,32)
            end
      end
  end

  if closestNode  and  not Slua.IsNull(closestNode) then
      self.ring1:GetComponent("RawImage").color = closestTargetColor    --set ring color
      self.ring2:GetComponent("RawImage").color = Color(0,0,0,0.5)      --set ring color
    --self.ring3:GetComponent("RawImage").color = closestTargetColor    --set ring color
      closestNode.transform:SetAsLastSibling()                          --move up in draw cahin
      closestNode.transform.sizeDelta = Vector2(48,48)                  --increase size of rect
      closestNode:GetComponent("CanvasGroup").alpha = 1                 --increase alpha
      if self.textHUD2 then self.textHUD2.text = closestNodeName ; self.textHUD2.color = closestTargetColor ; end
  else
      self.ring1:GetComponent("RawImage").color = Color(0.7,0.7,0.7,0.5)
      self.ring2:GetComponent("RawImage").color = Color(0.7,0.7,0.7,0.5)
    --self.ring3:GetComponent("RawImage").color = Color(0.7,0.7,0.7,0.5)
      if self.textHUD2 then self.textHUD2.text = "" end
  end

  if closestNode      then  self.aimedAtNode   = closestNode          ; elseif self.aimedAtNode    then self.aimedAtNode   = nil  ; end
  if closestTarget    then  self.aimedAtTarget = closestTarget        ; elseif self.aimedAtTarget  then self.aimedAtTarget = nil  ; end
  if not self.aimedAtNode
  and self.ring1
  and self.ring2      then  self.ring1:GetComponent("RawImage").color = Color(0.7,0.7,0.7,0) ; self.ring2:GetComponent("RawImage").color = Color(0.7,0.7,0.7,0.95)
  end
end
--]]


function RemoteCam:AimCheck() 
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

    if cl and cl.node  then  self.aimedAtNode   = cl.node ; elseif self.aimedAtNode   then self.aimedAtNode   = nil ; end
    if cl and cl.obj   then  self.aimedAtTarget = cl.obj  ; elseif self.aimedAtTarget then self.aimedAtTarget = nil ; end
end



function RemoteCam:iter_to_table(obj)
    local  ret = {}
    if  type(obj) == "userdata"  then  for v in Slua.iter(obj) do ret[#ret+1] = v ; end ; end
    return ret
end

function RemoteCam:GetAllVehicles()
    local vehicles = GameObject.FindObjectsOfType("VehiclePiece")
    local ret = {}
    for v in Slua.iter(vehicles) do 
         if not Slua.IsNull( v ) then ret[#ret+1] = v end
    end 
    if #ret == 0 then if self.Vehicles then self.Vehicles = false ; end ; return ; end
    self.Vehicles = ret
    return self.Vehicles
end


function RemoteCam:GetAllPlayers()
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

function RemoteCam:GetAllVehicleParts()
  local vehicle_list = GameObject.FindObjectsOfType("VehiclePiece")
  self.vehicles = self:iter_to_table(vehicle_list)
  return self.vehicles
end


function RemoteCam:GetCurrentVehiclePart()
    if    not HBU.InSeat() then self.vehicle = false ; return self.vehicle end
    local lowDist = 10000000
    local ret     = false
    for k,v in pairs(self:GetAllVehicleParts()) do if v and not Slua.IsNull(v) then local curDist = Vector3.Distance( GameObject.Find("Player").gameObject:GetComponent("Rigidbody").transform.position, v.transform.position ) ; if curDist < lowDist then lowDist = curDist ; ret = v ; end ; end ; end
    if ret then self.vehicle = ret ; else self.vehicle = false ; end
    return self.vehicle
end


function RemoteCam:GetOldestVehicle()
    local   veh = HBU.GetMyOldestVehicle()
    if      veh
    and     not Slua.IsNull(veh)
    then    self.vehicle = veh
    elseif  self.vehicle and Slua.IsNull(self.vehicle)
    then    self.vehicle = false
    end
    return self.vehicle
end


function RemoteCam:SetupHUD()
    if    not self.HUDParent
    then  self.HUDParent = HBU.menu.transform:Find("Foreground").gameObject
    end
    if  not self.Fonts then self.Fonts = {} ; end
    if  not self.Fonts.Consolas then self.Fonts.Consolas = Font.CreateDynamicFontFromOSFont({"Consolas","Roboto","Arial"}, 12)  end
    for k,v in pairs({"textHUD1","textHUD2","textHUD3"}) do
        self[v] = HBU.Instantiate("Text",self.HUDParent):GetComponent("Text")
        HBU.LayoutRect( self[v].gameObject,Rect( (Screen.width/2)-150, (Screen.height/2)+((k-1)*100)-80, 300, 100 ) )
        self[v].color = Color( math.floor( (k) % 2 ), math.floor(k/2) % 2, math.floor(k/4) % 2, 1)
        self[v].text = ""
        if self.Fonts and self.Fonts.Consolas then  self[v].font = self.Fonts.Consolas ; end
        if self[v].fontSize then self[v].fontSize = 25 end
        if self[v].alignment then self[v].alignment = TextAnchor.MiddleCenter ; end
    end
end



function RemoteCam:DestroyObjects(t,selfCall)
    if      type(t) == "nil"      and  self.GameObjects and not selfCall   then  if self:DestroyObjects(self.GameObjects,true) then return true end
    elseif  type(t) == "string"   and  self[t]                             then  if self:DestroyObjects(self[t],true) then if type(self[t]) == "table" and #self[t] > 0 then self[t] = {} ; else self[t] = nil ; end ; return true ; end
    elseif  type(t) == "userdata"
       and  string.sub(tostring(t),-23) == "(UnityEngine.Texture2D)"       then  GameObject.Destroy(t) ; return true
    elseif  type(t) == "table"    and t[1]  and  type(t[1]) == "userdata"
       and  not Slua.IsNull(t[1]) and selfCall                             then  if t[1].gameObject then GameObject.Destroy(t[1].gameObject)  else  GameObject.Destroy(t[1]) ; end ; return true
    elseif  type(t) == "table"                                             then  local ret = false ; for k,v in pairs(t) do if self:DestroyObjects(v,true) then ret = true ; end ; end return ret
    elseif  type(t) == "userdata" and not Slua.IsNull(t)                   then  if t.gameObject then GameObject.Destroy(t.gameObject)  else  GameObject.Destroy(t) ; end ; return true
                                                                           else  return false
    end
    if  type(t) == "nil" and self.Fonts then
        for k,v in pairs(self.Fonts)
        do  if v and not Slua.IsNull(v) then GameObject.Destroy(v) ; end
        end
        self.Fonts = false
    end
    return false
end


function RemoteCam:OnDestroy()
  Debug.Log("RemoteCam:OnDestroy()")
  HBU.EnableGadgetMouseScroll()
  self.enabled = false
  self:DestroyObjects()
end


-- function main(gameObject) RemoteCam.gameObject = gameObject ; return RemoteCam ; end

return RemoteCam

--[[
local newCamera = GameObject("newCam"):AddComponent("Camera")
local rt = RenderTexture(width,height,0)
newCamera.targetTexture = rt
camera then renders into RT
aye
zh0ul - Today at 5:43 PM
ok, got it
Igniuss - Today at 5:43 PM
oh, and prob best to like..
newCamera.nearClipPlane=1
newCamera.farClipPlane=500
so it doesn't render too far
--]]
