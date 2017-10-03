local RemoteCam = {}

if not flags then flags = {} ; end

function RemoteCam:Awake()

  Debug.Log("RemoteCam:Awake()")

  self.keys            = {
      lmb              = HBU.GetKey("UseGadget"),
      rmb              = HBU.GetKey("UseGadgetSecondary"),
      zoomIn           = HBU.GetKey("ZoomIn"),  -- HBU.DisableGadgetMouseScroll()    Use these to disable/enable Gadget Selection.
      zoomOut          = HBU.GetKey("ZoomOut"), -- HBU.EnableGadgetMouseScroll()     (ex: when placing a vehicle, use Disable so ZoomIn/ZoomOut can be used to change spawn distance)
      escape           = HBU.GetKey("Escape"),
      shift            = HBU.GetKey("Shift"),
      control          = HBU.GetKey("Control"),
      alt              = HBU.GetKey("Alt"),
      submit           = HBU.GetKey("Submit"),                     -- Default: Enter
      move             = HBU.GetKey("Move"),                       -- Default: W / S
      strafe           = HBU.GetKey("Strafe"),                     -- Default: D / A
      jump             = HBU.GetKey("Jump"),                       -- Default: Space
      run              = HBU.GetKey("Run"),                        -- Default: Left-Shift
      crouch           = HBU.GetKey("Crouch"),                     -- Default: C
      ChangeCameraView = HBU.GetKey("ChangeCameraView"),           -- Default: V
      ChangeThirdView  = HBU.GetKey("ChangeThirdPersonCameraMode"), -- Default: B
      navback          = HBU.GetKey("NavigateBack"),               -- Default: Escape
      action           = HBU.GetKey("Action"),                     -- Default: F
      inventory        = HBU.GetKey("Inventory"),                  -- Default: I
      showcontrols     = HBU.GetKey("ShowControls"),               -- Default: F1
      flipvehicle      = HBU.GetKey("flipVehicle"),                -- Default: L
      tilde            = { GetKey = function() if Input.GetKey(KeyCode.BackQuote)  then return 1 else return 0 ; end ; end, GetKeyDown = function() return Input.GetKeyDown(KeyCode.BackQuote)  ; end,  GetKeyUp = function() return Input.GetKeyDown(KeyCode.BackQuote)  ; end, },
      arrowl           = { GetKey = function() if Input.GetKey(KeyCode.LeftArrow)  then return 1 else return 0 ; end ; end, GetKeyDown = function() return Input.GetKeyDown(KeyCode.LeftArrow)  ; end,  GetKeyUp = function() return Input.GetKeyDown(KeyCode.LeftArrow)  ; end, },
      arrowr           = { GetKey = function() if Input.GetKey(KeyCode.RightArrow) then return 1 else return 0 ; end ; end, GetKeyDown = function() return Input.GetKeyDown(KeyCode.RightArrow) ; end,  GetKeyUp = function() return Input.GetKeyDown(KeyCode.RightArrow) ; end, },
      arrowu           = { GetKey = function() if Input.GetKey(KeyCode.UpArrow)    then return 1 else return 0 ; end ; end, GetKeyDown = function() return Input.GetKeyDown(KeyCode.UpArrow)    ; end,  GetKeyUp = function() return Input.GetKeyDown(KeyCode.UpArrow)    ; end, },
      arrowd           = { GetKey = function() if Input.GetKey(KeyCode.DownArrow)  then return 1 else return 0 ; end ; end, GetKeyDown = function() return Input.GetKeyDown(KeyCode.DownArrow)  ; end,  GetKeyUp = function() return Input.GetKeyDown(KeyCode.DownArrow)  ; end, },
      wheel            = { KeyUpData = { { tick = 0, }, { tick = 0, }, }, GetKey = function() return ( Input.GetAxis("Mouse ScrollWheel") * -1 ) ; end, GetKeyDown = function() local r = {false,false,false} ; local v = Input.GetAxis("Mouse ScrollWheel") ; if v ~= 0 then r[1] = true end ; if v > 0 then r[2] = true end ; if v < 0 then r[3] = true end ; return unpack(r) ; end,  GetKeyUp = function() if not self or not self.keys or not self.keys.wheel or not self.keys.wheel.KeyUpData or not self.tick then return false ; end ; local a_index,b_index = (self.tick-1)%2+1,(self.tick)%2+1 ; local d = self.keys.wheel.KeyUpData ; if self.tick ~= d[b_index].tick then d[b_index].tick = self.tick ; for k,v in pairs({self.keys.wheel.GetKeyDown()}) do d[b_index][k] = v ; end ; end ; if d[a_index].tick == self.tick - 1 then return d[a_index][1],d[a_index][2],d[a_index][3] ; else return false,false,false  ; end ; end, },
  }

  --self.toggleKey = self.keys.tilde

  self.activateKey = self.keys.tilde

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
  }

  self.Path =                {
       gadget                = HBU.GetLuaFolder().."/GadgetLua/",
       modlua                = HBU.GetLuaFolder().."/ModLua/",
       userdata              = Application.persistentDataPath,
       gadget_user           = Application.persistentDataPath.."/Lua/GadgetLua/",
       modlua_user           = Application.persistentDataPath.."/Lua/ModLua/",
  }

  self.Images                = {
       Default               = HBU.LoadTexture2D(self.Path.gadget     .."TeleportIcon2.png"),
       Wormhole1             = HBU.LoadTexture2D(self.Path.gadget     .."TeleportIcon2.png"),
       Wormhole2             = HBU.LoadTexture2D(self.Path.gadget     .."TeleportIcon.png"),
       Ring1                 = HBU.LoadTexture2D(self.Path.modlua_user.."RemoteCamRing1.png"),
       Ring2                 = HBU.LoadTexture2D(self.Path.modlua_user.."RemoteCamRing2.png"),
       Ring3                 = HBU.LoadTexture2D(self.Path.modlua_user.."RemoteCamRing3.png"),
  }

  self.print = function(msg) GameObject.FindObjectOfType("HBChat"):AddMessage("[RemoteCam]",msg) end

  self.GameObjects           = {  "TargetNodes", "ring1", "ring2", "ring3", "textHUD1", "textHUD2", "textHUD3", }
  self.TargetNodes           = {}
  if GetAllTeleportLocations then self.TeleportLocations = GetAllTeleportLocations() ; end --- HBU.GetTeleportLocations()
  self.ringRadius            = 64
  self.tick                  = 0
  self.teleportLocations     = HBU.GetTeleportLocations()
  self.mode                  = -1
  if self.vehicles and #self.vehicles > 0 then self.vehicles  = {} ; end
  self.enabled               = true
  self.temporaryDisable      = false
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
                 -- ( HBU.MayControle    and  not HBU.MayControle()   )
                 -- ( HBU.InSeat         and      HBU.InSeat()        )
                 ( HBU.InBuilder      and      HBU.InBuilder()     )
             -- or  ( self.GetComponents and not self:GetComponents() )
            )
    then    self:Disable() ; self.temporaryDisable = true ; return false

    elseif  self.temporaryDisable
    and     (
                  -- ( not HBU.MayControle    or      HBU.MayControle()    )
                  -- ( not HBU.InSeat         or      not HBU.InSeat()     )
                  ( not HBU.InBuilder      or      not HBU.InBuilder()  )
             -- and  ( not self.GetComponents or      self:GetComponents() )
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

    self.tick = self.tick + 1

    if not self:EnableCheck() then return ; end

  --   if    HBU.InBuilder()
  -- --or    not HBU.MayControle()
  --   then  self:ClearTarget() ; self:DestroyObjects() ; return
  --   end

    
    if      self.mode == -10 then self.mode = self.mode + 1 ; self:ClearTarget() ; return
    elseif  self.mode  < -1  then self.mode = self.mode + 1 ; return
    elseif  self.mode == -1  then self.mode = self.mode + 1 ; print("Mode:-1") ; print("Mode:0") ; return
    end

    if    not self.player or Slua.IsNull(self.player) then self.player = GameObject.Find("Player") ; end

    if    self.activateKey.GetKeyDown()
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
          self:UpdateTargetNodes()
    end

    if      self.mode == 1
    and     self.aimedAtTarget          and not Slua.IsNull(self.aimedAtTarget)
    and     self.activateKey.GetKey() == 0
    then
            self.wasInVehicle = HBU.InSeat()
            if    self.wasInVehicle
            then  self.lastVehicle = self:GetCurrentVehiclePart() ; if self.lastVehicle then self.originalLoc = self.lastVehicle.transform.position ; else self.originalLoc  = GameObject.Find("Player").gameObject:GetComponent("Rigidbody").transform.position ; end
            else  self.originalLoc  = GameObject.Find("Player").gameObject:GetComponent("Rigidbody").transform.position
            end
            self:SetTarget(self.aimedAtTarget)
            self.mode = 2
            print("Mode:"..tostring(self.mode))

    elseif  self.mode == 1
    and     self.activateKey.GetKey() == 0
    and     (  not self.aimedAtTarget  or  Slua.IsNull(self.aimedAtTarget)  )
    then
            self.mode = -10
            if not HBU.InSeat() then Camera.main:GetComponentInParent("rigidbody_character_motor").enabled = true ; end
            self:DestroyObjects()
            print("Mode:"..tostring(self.mode))

    elseif  ( self.mode == 2 and self.activateKey.GetKey() == 0 )
    then
          if    not self.aimedAtTarget or Slua.IsNull(self.aimedAtTarget)
          then
                self.mode = -10
          else
                self.mode = 3 ; HBU.DisableGadgetMouseScroll() ; print("HBU.DisableGadgetMouseScroll()")
          end
          self:DestroyObjects()
          print("Mode:"..tostring(self.mode))

    elseif  self.mode == 3
    then
            self:KeysCheck()
            if    self.activateKey.GetKeyDown() --self.keys.navback.GetKey() > 0.5
            or    not self.aimedAtTarget
            or    Slua.IsNull(self.aimedAtTarget)
            or    ( self.wasInVehicle and not HBU.InSeat() )
            then
                  self.mode          = 4
                  self:ClearTarget()
                  print("Mode:"..tostring(self.mode))
                  return

            elseif  HBU.InSeat() and not self.wasInVehicle
            then
                  self.mode = -10
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
            self.mode = -10
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
  local parent = HBU.menu.transform:Find("Foreground").gameObject

  self.ring1 = HBU.Instantiate("RawImage",parent)
  HBU.LayoutRect( self.ring1, Rect( (Screen.width*0.5)-self.ringRadius, (Screen.height*0.5)-self.ringRadius,self.ringRadius*2,self.ringRadius*2))
  self.ring1:GetComponent("RawImage").texture = self.Images.Ring1
  self.ring1:GetComponent("RawImage").color = Color(0.5,0.5,0.5,0.5)

  self.ring2 = HBU.Instantiate("RawImage",parent)
  HBU.LayoutRect( self.ring2, Rect( (Screen.width*0.5)-self.ringRadius, (Screen.height*0.5)-self.ringRadius,self.ringRadius*2,self.ringRadius*2))
  self.ring2:GetComponent("RawImage").texture = self.Images.Ring2
  self.ring2:GetComponent("RawImage").color = Color(0.5,0.5,0.5,0.5)

  self.ring3 = HBU.Instantiate("RawImage",parent)
  HBU.LayoutRect( self.ring3, Rect( (Screen.width*0.5)-self.ringRadius, (Screen.height*0.5)-self.ringRadius,self.ringRadius*2,self.ringRadius*2))
  self.ring3:GetComponent("RawImage").texture = self.Images.Ring3
  self.ring3:GetComponent("RawImage").color = Color(0.5,0.5,0.5,0.5)

  for i in Slua.iter( self.teleportLocations ) do
      local node = HBU.Instantiate("Container",parent)
      node.transform.pivot = Vector2(0.5,0.5)
      node.transform.anchorMin = Vector2(0.5,0.5)
      node.transform.anchorMax = Vector2(0.5,0.5)
      node.transform.sizeDelta = Vector2(32,32)
      local canvasGroup = node:AddComponent("UnityEngine.CanvasGroup")
      canvasGroup.alpha = 0.3

      local img2 = HBU.Instantiate("RawImage",node)
      img2.name = "WormHole2"
      img2.transform.anchorMin = Vector2.zero
      img2.transform.anchorMax = Vector2.one
      img2.transform.offsetMin = Vector2.zero
      img2.transform.offsetMax = Vector2.zero
      img2:GetComponent("RawImage").texture = self.Images.Wormhole2
      img2:GetComponent("RawImage").color = i.color
      
      local rotSpeed = Mathf.Clamp(Random.value,0.5,1)
      self.TargetNodes[#self.TargetNodes+1] = { node , i , img2 , rotSpeed }
  end

  if  self.vehicles
  then
      for k,v in pairs(self.vehicles)
      do
        local r,g,b,a = math.random(192,255)/255, math.random(192,255)/255, math.random(192,255)/255, 1
        if math.random(1,2) == 1 then r = 0 ; elseif math.random(1,2) == 1 then g = 0 else b = 0 ; end
        local curColor = Color(r,g,b,a)
        local node = HBU.Instantiate("Container",parent)
        node.transform.pivot = Vector2(0.5,0.5)
        node.transform.anchorMin = Vector2(0.5,0.5)
        node.transform.anchorMax = Vector2(0.5,0.5)
        node.transform.sizeDelta = Vector2(32,32)
        local canvasGroup = node:AddComponent("UnityEngine.CanvasGroup")
        canvasGroup.alpha = 0.5

        local img2 = HBU.Instantiate("RawImage",node)
        img2.name = "WormHole2"
        img2.transform.anchorMin = Vector2.zero
        img2.transform.anchorMax = Vector2.one
        img2.transform.offsetMin = Vector2.zero
        img2.transform.offsetMax = Vector2.zero
        img2:GetComponent("RawImage").texture = self.Images.Wormhole2
        img2:GetComponent("RawImage").color =  curColor

        local rotSpeed = Mathf.Clamp(Random.value,0.5,1)
        self.TargetNodes[#self.TargetNodes+1] = { node, v, img2, rotSpeed, "Vehicle "..tostring(k), curColor }
      end
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

function RemoteCam:UpdateTargetNodes()
    --position nodes on screenspace
    for i,v in pairs(self.TargetNodes) do
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
      end
end


function RemoteCam:AimCheck() 

  local closestAngle = 6
  local closestNode = false
  local closestNodeName = ""
  local closestTarget = false
  local closestTargetColor = Color(1,1,1,1)

  for i,v in pairs( self.TargetNodes ) do
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

  if closestNode  and  not Slua.IsNull(closestNode) then
      self.ring1:GetComponent("RawImage").color = closestTargetColor    --set ring color
      self.ring2:GetComponent("RawImage").color = Color(0,0,0,0)        --set ring color
      self.ring3:GetComponent("RawImage").color = closestTargetColor    --set ring color
      closestNode.transform:SetAsLastSibling()                          --move up in draw cahin
      closestNode.transform.sizeDelta = Vector2(48,48)                  --increase size of rect
      closestNode:GetComponent("CanvasGroup").alpha = 1                 --increase alpha

      -- local p = HBU.Instantiate("Panel",closestNode)                    --create panel with name on it
      -- p.name = "Display"
      -- HBU.LayoutRect(p,Rect(50,12,150,20))
      -- local pImage = p:GetComponent("Image")
      -- pImage.color = Color(0.2,0.2,0.2,1)

      -- local t = HBU.Instantiate("Text",p)
      -- t.transform.anchorMin = Vector2.zero
      -- t.transform.anchorMax = Vector2.one
      -- t.transform.offsetMin = Vector2.zero
      -- t.transform.offsetMax = Vector2.zero
      -- local tComp = t:GetComponent("Text")
      -- tComp.text = closestNodeName
      -- tComp.alignment = TextAnchor.MiddleCenter
      -- tComp.color = Color.white
      if self.textHUD2 then self.textHUD2.text = closestNodeName ; self.textHUD2.color = closestTargetColor ; end
  else
      self.ring1:GetComponent("RawImage").color = Color(0.5,0.5,0.5,0)
      self.ring2:GetComponent("RawImage").color = Color(0.5,0.5,0.5,0.5)
      self.ring3:GetComponent("RawImage").color = Color(0.5,0.5,0.5,0)
      if self.textHUD2 then self.textHUD2.text = "" end
  end

  if closestNode      then  self.aimedAtNode   = closestNode          ; elseif self.aimedAtNode    then self.aimedAtNode   = nil  ; end
  if closestTarget    then  self.aimedAtTarget = closestTarget        ; elseif self.aimedAtTarget  then self.aimedAtTarget = nil  ; end
  if not self.aimedAtNode
  and self.ring1
  and self.ring2      then  self.ring1:GetComponent("RawImage").color = Color(0.7,0.7,0.7,0) ; self.ring2:GetComponent("RawImage").color = Color(0.7,0.7,0.7,0.95)
  end
end

function RemoteCam:iter_to_table(obj)
    local  ret = {}
    if  type(obj) == "userdata"  then  for v in Slua.iter(obj) do ret[#ret+1] = v ; end ; end
    return ret
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
    for k,v in pairs({"textHUD1","textHUD2","textHUD3"}) do
        self[v] = HBU.Instantiate("Text",self.HUDParent):GetComponent("Text")
        HBU.LayoutRect( self[v].gameObject,Rect( (Screen.width/2)-150, (Screen.height/2)+((k-1)*100)-80, 300, 100 ) )
        self[v].color = Color( math.floor( (k) % 2 ), math.floor(k/2) % 2, math.floor(k/4) % 2, 1)
        self[v].text = ""
        if Font then  self[v].font = Font.CreateDynamicFontFromOSFont({"consolas","Roboto","Arial"}, 25)  end
        if self[v].fontSize then self[v].fontSize = 25 end
        if self[v].alignment then self[v].alignment = TextAnchor.MiddleCenter ; end
    end
end



function RemoteCam:DestroyObjectsExcept(t)
    if not self.GameObjects then return ; end
    local t2 = {}
    if    type(t) == "table"
    then  for k,v in pairs(t) do t2[tostring(v)]=true ; end
    end
    for k,v in pairs(self.GameObjects)
    do  if not t2[v] then self:DestroyObjects(v) ; end
    end
end


function RemoteCam:DestroyObjects(t,selfCall)
    if      type(t) == "nil"      and  self.GameObjects and not selfCall     then  if self:DestroyObjects(self.GameObjects,true) then return true end
    elseif  type(t) == "string"   and  self[t]                               then  if self:DestroyObjects(self[t],true) then if type(self[t]) == "table" and #self[t] > 0 then self[t] = {} ; else self[t] = false ; end ; return true ; end
    elseif  type(t) == "table"    and  type(t[1]) == "userdata"
     --and  ( type(t[2]) == "nil" or type(t[2]) ~= "userdata" )
       and  not Slua.IsNull(t[1])                                            then  GameObject.Destroy(t[1].gameObject) ; return true
    elseif  type(t) == "table"                                               then  local ret = false ; for k,v in pairs(t) do if self:DestroyObjects(v,true) then ret = true ; end ; end return ret
    elseif  type(t) == "userdata" and not Slua.IsNull(t)                     then  GameObject.Destroy(t) ; return true
    else    return false
    end
    return false
end

function RemoteCam:OnDestroy()
  Debug.Log("RemoteCam:OnDestroy()")
  HBU.EnableGadgetMouseScroll()
  self.enabled = false
  self:DestroyObjects()
end


function main(gameObject) RemoteCam.gameObject = gameObject ; return RemoteCam ; end

