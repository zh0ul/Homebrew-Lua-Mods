local RemoteCam = {}

function RemoteCam:Awake()
  Debug.Log("RemoteCam:Awake()")
  self.keys   = {
      lmb     = HBU.GetKey("UseGadget"),
      rmb     = HBU.GetKey("UseGadgetSecondary"),
      inv     = HBU.GetKey("Inventory"),
      zoomIn  = HBU.GetKey("ZoomIn"),  -- HBU.DisableGadgetMouseScroll()    Use these to disable/enable Gadget Selection.
      zoomOut = HBU.GetKey("ZoomOut"), -- HBU.EnableGadgetMouseScroll()     (ex: when placing a vehicle, use Disable so ZoomIn/ZoomOut can be used to change spawn distance)
      run     = HBU.GetKey("Run"),
      shift   = HBU.GetKey("Shift"),
      control = HBU.GetKey("Control"),
      alt     = HBU.GetKey("Alt"),
      move    = HBU.GetKey("Move"),
      navback = HBU.GetKey("NavigateBack"),
      tilde   = { GetKey = function() if Input.GetKey(KeyCode.BackQuote) then return 1 else return 0 ; end ; end, GetKeyDown = function() return Input.GetKeyDown(KeyCode.BackQuote) ; end,  GetKeyUp = function() return Input.GetKeyDown(KeyCode.BackQuote) ; end, }
  }
  self.camModes = {
    "ActionCameraMode",
    "FixedCameraMode",
    "LooseCameraMode",
    "LookaroundCameraMode"
  }
  self.camModeThird          = 3
  self.camModeFirst          = 1
  self.camOffset             = Vector3(0,1,0)
  self.hbplayer              = Camera.main:GetComponent("HBPlayer")
  self.Actions               = {
      SwitchToFirstPerson    = function(viewMode) viewMode = viewMode or self.camModeFirst ; if not self.hbplayer or Slua.IsNull(self.hbplayer) then self.hbplayer = Camera.main:GetComponent("HBPlayer") ; end ; if not Slua.IsNull(self.hbplayer) then self.hbplayer.SwitchToFirstPersonView()  ; end ; end,
      SwitchToThirdPerson    = function(viewMode) viewMode = viewMode or self.camModeThird ; if not self.hbplayer or Slua.IsNull(self.hbplayer) then self.hbplayer = Camera.main:GetComponent("HBPlayer") ; end ; if not Slua.IsNull(self.hbplayer) then self.hbplayer.SwitchToThirdPersonView()  ; end ; end,
      SetCam                 = function(viewMode) viewMode = viewMode or 1 ; self.Actions.SwitchToFirstPerson(viewMode) ; end,
      SetPlayerMovement      = function(toggle) local charmotor = Camera.main:GetComponentInParent("rigidbody_character_motor") ; if type(toggle) ~= "boolean" then toggle = not charmotor.enabled ; end ; charmotor.enabled = toggle ; end
  }
  self.path_userdata         = Application.persistentDataPath
  self.path_gadget_user      = self.path_userdata.."/Lua/GadgetLua/"
  self.path_gadget           = HBU.GetLuaFolder().."/GadgetLua/"
  self.path_modlua_user      = self.path_userdata.."/Lua/ModLua/"
  self.path_modlua           = HBU.GetLuaFolder().."/ModLua/"
  self.targetNodes           = {}
  self.teleportLocations     = HBU.GetTeleportLocations()
  self.wormholeImage         = HBU.LoadTexture2D(self.path_gadget.."TeleportIcon.png")
  self.wormholeImage2        = HBU.LoadTexture2D(self.path_gadget.."TeleportIcon2.png")
  self.ringImage1            = HBU.LoadTexture2D(self.path_modlua_user.."RemoteCamRing1.png")
  self.ringImage2            = HBU.LoadTexture2D(self.path_modlua_user.."RemoteCamRing2.png")
  self.ringImage3            = HBU.LoadTexture2D(self.path_modlua_user.."RemoteCamRing3.png")
  self.GameObjects           = { "targetNodes", "ring1", "ring2", "ring3", "textHUD1", "textHUD2", "textHUD3" }
  self.active                = false
  self.tickCount             = 0
  self:SetDefaults()
  self:SetupHUD()
end


function RemoteCam:SetDefaults()
    self.mode      = -1
    print("Mode:"..tostring(self.mode))
    if self.vehicles and #self.vehicles > 0 then self.vehicles  = {} ; end
end


function RemoteCam:RotateInnerRing()
    if not  self.ring3 then return ; end
    local screenPos = Camera.main:WorldToScreenPoint(self.ring3.transform.position)
    screenPos.x = screenPos.x - (Screen.width * 0.5)
    screenPos.y = screenPos.y - (Screen.height * 0.5)
    if( screenPos.z < 0 ) then 
      screenPos.y = 1000000
    end
    screenPos.z = 0
    self.ring3.transform.anchoredPosition = screenPos

    local r = self.ring3.transform.localEulerAngles
    if self.ring3 then self.ring3.transform.localEulerAngles = r+Vector3(0,0, Time.deltaTime * 180.0 * 1) ; end
end


function RemoteCam:Update()

    self.tickCount = self.tickCount + 1

    if    HBU.InBuilder()
  --or    not HBU.MayControle()
    then  if self.player then self.player = nil ; end ; if self.rb then self.rb = nil ; end ; if self.tickCount % 90 == 0 then self:DestroyObjects() ; end ; return
    end

    if    not self.player or Slua.IsNull(self.player) then self.player = GameObject.Find("Player") ; end
    if    not self.rb     or Slua.IsNull(self.rb)     and  self.player  then self.rb = self.player.gameObject:GetComponent("Rigidbody") ; end

    if    self.mode == -1 then self.mode = 0 ; self.Actions.SetPlayerMovement(true) ; return ; end

    if    self.keys.tilde.GetKeyDown()
    and   self.mode == 0
    then
          if  self.aimedAtTarget then
              self.aimedAtTarget = nil
          end
          -- self.Actions.SetCam()
          self:SetDefaults()
          self:GetAllVehicleParts()
          self:CreateTargetNodes()
          self.mode = 1
          print("Mode:"..tostring(self.mode))
          return

    elseif self.mode == 1
    then
          self:AimCheck()
          self:UpdateTargetNodes()
        --self:RotateInnerRing()
    end

    if    self.mode == 1
    and   self.aimedAtTarget
    and   self.keys.tilde.GetKeyUp()
    then
          self.mode = 2
          print("Mode:"..tostring(self.mode))

    elseif  ( self.mode == 1 and self.keys.tilde.GetKey() == 0 )
    or      self.mode == 2
    then
        --self:SetDefaults()
          if not self.aimedAtTarget then self.mode = -1 ; HBU.EnableGadgetMouseScroll() else self.mode = 3 ; HBU.DisableGadgetMouseScroll() ; end
          self.originalLoc  = self.rb.transform.position
          self.wasInVehicle = HBU.InSeat()
          -- self.rb.isKinematic = false
          self.Actions.SetPlayerMovement(false)
          self:DestroyObjects()
          print("Mode:"..tostring(self.mode))

    elseif  self.mode == 3
    then
            if    self.keys.tilde.GetKeyDown() --self.keys.navback.GetKey() > 0.5
            then
                  self.aimedAtTarget = nil
                  HBU.EnableGadgetMouseScroll()
                  self.Actions.SetCam()
                --self.rb.transform.position = self.originalLoc + Vector3(0,1,0)
                  if not self.wasInVehicle and not HBU.InSeat() then  HBU.TeleportPlayer(self.originalLoc + Vector3(0,1,0))  ; end
                  -- self.rb.isKinematic = true
                  self.rb:AddForce( Vector3( 0,1,0 ) )
                  self.Actions.SetPlayerMovement(true)
                  self.mode = -1
                  print("Mode:"..tostring(self.mode))
                  return

            elseif  HBU.InSeat() and not self.wasInVehicle
            then
                  self.aimedAtTarget = nil
                  self.mode = -1
                  self.Actions.SetPlayerMovement(true)
                  print("Mode:"..tostring(self.mode))
                  return
            end

            if      not self.aimedAtTarget
            then    self.mode = -1
            elseif  Slua.IsNull(self.aimedAtTarget)
            then    self.aimedAtTarget = nil ; self.mode = -1
            elseif  not Slua.IsNull(Camera.main)
            then    Camera.main.transform.position = self.aimedAtTarget.transform.position + self.camOffset
            end
    end


end


function RemoteCam:CreateTargetNodes()
  local parent = HBU.menu.transform:Find("Foreground").gameObject

  self.ring1 = HBU.Instantiate("RawImage",parent)
  HBU.LayoutRect(self.ring1,Rect((Screen.width*0.5)-128,(Screen.height*0.5)-128,256,256))
  self.ring1:GetComponent("RawImage").texture = self.ringImage1
  self.ring1:GetComponent("RawImage").color = Color(0.5,0.5,0.5,0.5)

  self.ring2 = HBU.Instantiate("RawImage",parent)
  HBU.LayoutRect(self.ring2,Rect((Screen.width*0.5)-128,(Screen.height*0.5)-128,256,256))
  self.ring2:GetComponent("RawImage").texture = self.ringImage2
  self.ring2:GetComponent("RawImage").color = Color(0.5,0.5,0.5,0.5)

  self.ring3 = HBU.Instantiate("RawImage",parent)
  HBU.LayoutRect(self.ring3,Rect((Screen.width*0.5)-128,(Screen.height*0.5)-128,256,256))
  self.ring3:GetComponent("RawImage").texture = self.ringImage3
  self.ring3:GetComponent("RawImage").color = Color(0.5,0.5,0.5,0.5)

  for i in Slua.iter( self.teleportLocations ) do
      local node = HBU.Instantiate("Container",parent)
      node.transform.pivot = Vector2(0.5,0.5)
      node.transform.anchorMin = Vector2(0.5,0.5)
      node.transform.anchorMax = Vector2(0.5,0.5)
      node.transform.sizeDelta = Vector2(32,32)
      local canvasGroup = node:AddComponent("UnityEngine.CanvasGroup")
      canvasGroup.alpha = 0.2
      
      local img = HBU.Instantiate("RawImage",node)
      img.name = "WormHole"
      img.transform.anchorMin = Vector2.zero
      img.transform.anchorMax = Vector2.one
      img.transform.offsetMin = Vector2.zero
      img.transform.offsetMax = Vector2.zero
      img:GetComponent("RawImage").texture = self.wormholeImage
      img:GetComponent("RawImage").color = i.color
      
      local img2 = HBU.Instantiate("RawImage",node)
      img2.name = "WormHole2"
      img2.transform.anchorMin = Vector2.zero
      img2.transform.anchorMax = Vector2.one
      img2.transform.offsetMin = Vector2.zero
      img2.transform.offsetMax = Vector2.zero
      img2:GetComponent("RawImage").texture = self.wormholeImage2
      img2:GetComponent("RawImage").color = i.color
      
      local rotSpeed = Mathf.Clamp(Random.value,0.5,1)
      self.targetNodes[#self.targetNodes+1] = { node , i , img2 , rotSpeed }
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

        local img = HBU.Instantiate("RawImage",node)
        img.name = "WormHole"
        img.transform.anchorMin = Vector2.zero
        img.transform.anchorMax = Vector2.one
        img.transform.offsetMin = Vector2.zero
        img.transform.offsetMax = Vector2.zero
        img:GetComponent("RawImage").texture = self.wormholeImage
        img:GetComponent("RawImage").color = curColor
        
        local img2 = HBU.Instantiate("RawImage",node)
        img2.name = "WormHole2"
        img2.transform.anchorMin = Vector2.zero
        img2.transform.anchorMax = Vector2.one
        img2.transform.offsetMin = Vector2.zero
        img2.transform.offsetMax = Vector2.zero
        img2:GetComponent("RawImage").texture = self.wormholeImage2
        img2:GetComponent("RawImage").color =  curColor

        local rotSpeed = Mathf.Clamp(Random.value,0.5,1)
        self.targetNodes[#self.targetNodes+1] = { node, v, img2, rotSpeed, "Vehicle "..tostring(k), curColor }
      end
  end

end


function RemoteCam:UpdateTargetNodes()
    --position nodes on screenspace
    for i,v in pairs(self.targetNodes) do
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

  local closestAngle = 10
  local closestNode = false
  local closestNodeName = ""
  local closestTarget = false
  local closestTargetColor = Color(1,1,1,1)

  for i,v in pairs( self.targetNodes ) do
    local ang = false
    if    v and v[2] and v[2].transform.position
    then  ang = Vector3.Angle(Camera.main.transform.forward,v[2].transform.position-Camera.main.transform.position) 
    end
    if    ang and ang < closestAngle then
          closestAngle  = ang
          closestNode   = v[1]
          closestTarget = v[2]
          if v and v[5] then closestNodeName    = v[5] elseif v[2] and v[2].locationName  then  closestNodeName    = v[2].locationName ; end
          if v and v[6] then closestTargetColor = v[6] elseif v[2] and v[2].color         then  closestTargetColor = v[2].color        ; end
    end
  end

  if closestNode  and  not Slua.IsNull(closestNode) then
    --set ring color
      self.ring1:GetComponent("RawImage").color = closestTargetColor
      self.ring2:GetComponent("RawImage").color = Color(0,0,0,0)
      self.ring3:GetComponent("RawImage").color = closestTargetColor
    --move up in draw cahin
      closestNode.transform:SetAsLastSibling()
    --increase size of rect
      closestNode.transform.sizeDelta = Vector2(48,48)
    --increase alpha
      closestNode:GetComponent("CanvasGroup").alpha = 1
    --create panel with name on it
      local p = HBU.Instantiate("Panel",closestNode)
      p.name = "Display"
      HBU.LayoutRect(p,Rect(50,12,150,20))
      local pImage = p:GetComponent("Image")
      pImage.color = Color(0.2,0.2,0.2,1)
      local t = HBU.Instantiate("Text",p)
      t.transform.anchorMin = Vector2.zero
      t.transform.anchorMax = Vector2.one
      t.transform.offsetMin = Vector2.zero
      t.transform.offsetMax = Vector2.zero
      local tComp = t:GetComponent("Text")
      tComp.text = closestNodeName
      tComp.alignment = TextAnchor.MiddleCenter
      tComp.color = Color.white
      --highlight new node if any
  else
      self.ring1:GetComponent("RawImage").color = Color(0.5,0.5,0.5,0)
      self.ring2:GetComponent("RawImage").color = Color(0.5,0.5,0.5,0.5)
      self.ring3:GetComponent("RawImage").color = Color(0.5,0.5,0.5,0)
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


function RemoteCam:GetLastVehicle()
    local   veh = HBU.GetMyOldestVehicle()
    if      veh
    and     not Slua.IsNull(veh)
    then    self.vehicle = veh
    elseif  self.vehicle and Slua.IsNull(self.vehicle)
    then    self.vehicle = nil
    end
end


function RemoteCam:SetupHUD()
    local parent  = HBU.menu.transform:Find("Foreground").gameObject
    self.textHUD1 = HBU.Instantiate("Text",parent):GetComponent("Text")
    self.textHUD2 = HBU.Instantiate("Text",parent):GetComponent("Text")
    self.textHUD3 = HBU.Instantiate("Text",parent):GetComponent("Text")
    HBU.LayoutRect(self.textHUD1.gameObject,Rect(Screen.width/2-150,35,150,200))
    HBU.LayoutRect(self.textHUD2.gameObject,Rect(Screen.width/2-50,35,300,200))
    HBU.LayoutRect(self.textHUD3.gameObject,Rect(Screen.width/2+50,35,300,200))
    self.textHUD1.color = Color(1,0,0,1)
    self.textHUD2.color = Color(1,0.7,0,1)
    self.textHUD3.color = Color(0,1,0,1)
    self.textHUD1.text  = ""
    self.textHUD2.text  = ""
    self.textHUD3.text  = ""
end


function RemoteCam:DestroyObjects(t,selfCall)
    if      type(t) == "nil"      and  self.GameObjects and not selfCall     then  if self:DestroyObjects(self.GameObjects,true) then return true end
    elseif  type(t) == "string"   and  self[t]                               then  if self:DestroyObjects(self[t],true) then if type(self[t]) == "table" and #self[t] > 0 then self[t] = {} ; else self[t] = nil ; end ; return true ; end
    elseif  type(t) == "table"    and t[1]  and  type(t[1]) == "userdata"
       and  not Slua.IsNull(t[1])                                            then  GameObject.Destroy(t[1]) ; return true
    elseif  type(t) == "table"                                               then  local ret = false ; for k,v in pairs(t) do if self:DestroyObjects(v,true) then ret = true ; end ; end return ret
    elseif  type(t) == "userdata" and not Slua.IsNull(t)                     then  GameObject.Destroy(t) ; return true
                                                                             else  return false
    end
    return false
end


function RemoteCam:OnDestroy()
  Debug.Log("RemoteCam:OnDestroy()")
  self:DestroyObjects()
  self:SetDefaults()
end


function main(gameObject) RemoteCam.gameObject = gameObject ; return RemoteCam ; end
