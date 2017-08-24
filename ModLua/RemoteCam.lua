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

  self.CamModes = {
    [1]   = 1,      ActionCameraMode     = 1,
    [2]   = 2,      FixedCameraMode      = 2,
    [3]   = 3,      LooseCameraMode      = 3,
    [4]   = 4,      LookaroundCameraMode = 4,
                    Third                = 3,
                    First                = 1,
                    Offset               = Vector3(0,1,0),
  }

  self.Actions               = {
      SwitchToFirstPerson    = function(viewMode) viewMode = viewMode or self.camMode.First ; if not self.hbplayer or Slua.IsNull(self.hbplayer) then self.hbplayer = Camera.main:GetComponent("HBPlayer") ; end ; if not Slua.IsNull(self.hbplayer) then self.hbplayer.SwitchToFirstPersonView()  ; end ; end,
      SwitchToThirdPerson    = function(viewMode) viewMode = viewMode or self.camMode.Third ; if not self.hbplayer or Slua.IsNull(self.hbplayer) then self.hbplayer = Camera.main:GetComponent("HBPlayer") ; end ; if not Slua.IsNull(self.hbplayer) then self.hbplayer.SwitchToThirdPersonView()  ; end ; end,
      SetCam                 = function(viewMode) viewMode = viewMode or 1 ; self.Actions.SwitchToFirstPerson(viewMode) ; end,
      SetPlayerMovement      = function(toggle) local charmotor = Camera.main:GetComponentInParent("rigidbody_character_motor") ; if type(toggle) ~= "boolean" then toggle = not charmotor.enabled ; end ; charmotor.enabled = toggle ; end
  }

  self.Path =                {
       gadget                = HBU.GetLuaFolder().."/GadgetLua/",
       modlua                = HBU.GetLuaFolder().."/ModLua/",
       userdata              = Application.persistentDataPath,
       gadget_user           = Application.persistentDataPath.."/Lua/GadgetLua/",
       modlua_user           = Application.persistentDataPath.."/Lua/ModLua/",
  }

  self.Images                = {
       Default               = HBU.LoadTexture2D(self.Path.gadget     .."TeleportIcon.png"),
       Wormhole1             = HBU.LoadTexture2D(self.Path.gadget     .."TeleportIcon.png"),
       Wormhole2             = HBU.LoadTexture2D(self.Path.gadget     .."TeleportIcon2.png"),
       Ring1                 = HBU.LoadTexture2D(self.Path.modlua_user.."RemoteCamRing1.png"),
       Ring2                 = HBU.LoadTexture2D(self.Path.modlua_user.."RemoteCamRing2.png"),
       Ring3                 = HBU.LoadTexture2D(self.Path.modlua_user.."RemoteCamRing3.png"),
  }

  self.GameObjects           = {  "TargetNodes", "ring1", "ring2", "ring3", "textGUI1", "textGUI2", "textGUI3", }
  self.TargetNodes           = {}
  if GetAllTeleportLocations then self.TeleportLocations = GetAllTeleportLocations() ; end --- HBU.GetTeleportLocations()
  self.hbplayer              = Camera.main:GetComponent("HBPlayer")
  self.ringRadius            = 64
  self.tickCount             = 0
  self.teleportLocations     = HBU.GetTeleportLocations()
  self:SetDefaults()
  --self:SetupGUI()
end


function RemoteCam:SetDefaults()
    self.mode      = -1
    print("Mode:"..tostring(self.mode))
    if self.vehicles and #self.vehicles > 0 then self.vehicles  = {} ; end
end


function RemoteCam:RotateInnerRing()
    if not  self.ring3 then return ; end
    local r = self.ring3.transform.localEulerAngles
    if self.ring3 then self.ring3.transform.localEulerAngles = r+Vector3(0,0, Time.deltaTime * 180.0 * 1) ; end
    local screenPos = Camera.main:WorldToScreenPoint(self.ring3.transform.position)
    screenPos.x = (Screen.width*0.5)-128
    screenPos.y = (Screen.height*0.5)-128
    screenPos.z = 0
    self.ring3.transform.anchoredPosition = screenPos
end


function RemoteCam:Update()

    self.tickCount = self.tickCount + 1

    if    HBU.InBuilder()
  --or    not HBU.MayControle()
    then  if self.player then self.player = nil ; end ; if self.rb then self.rb = nil ; end ; if self.tickCount % 90 == 0 then self:DestroyObjects() ; self:SetDefaults(); end ; return
    end

    if    not self.player or Slua.IsNull(self.player) then self.player = GameObject.Find("Player") ; end
    if    not self.rb     or Slua.IsNull(self.rb)     and  self.player  then self.rb = self.player.gameObject:GetComponent("Rigidbody") ; end

    if    self.mode == -1 then self.mode = 0 ; self.Actions.SetPlayerMovement(true) ; if  self.aimedAtTarget then  self.aimedAtTarget = false  end ; return ; end

    if    self.keys.tilde.GetKeyDown()
    and   self.mode == 0
    then
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
          if not self.aimedAtTarget then self.mode = -1 ; HBU.EnableGadgetMouseScroll() else self.mode = 3 ; HBU.DisableGadgetMouseScroll() ; end
          self.originalLoc  = self.rb.transform.position
          self.wasInVehicle = HBU.InSeat()
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
                  if not self.wasInVehicle and not HBU.InSeat() then  HBU.TeleportPlayer(self.originalLoc + Vector3(0,2,0))  ; end
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
            then    Camera.main.transform.position = self.aimedAtTarget.transform.position + self.CamModes.Offset
            end
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
      
      -- local img = HBU.Instantiate("RawImage",node)
      -- img.name = "WormHole"
      -- img.transform.anchorMin = Vector2.zero
      -- img.transform.anchorMax = Vector2.one
      -- img.transform.offsetMin = Vector2.zero
      -- img.transform.offsetMax = Vector2.zero
      -- img:GetComponent("RawImage").texture = self.Images.Wormhole1
      -- img:GetComponent("RawImage").color = i.color
      
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

        -- local img = HBU.Instantiate("RawImage",node)
        -- img.name = "WormHole"
        -- img.transform.anchorMin = Vector2.zero
        -- img.transform.anchorMax = Vector2.one
        -- img.transform.offsetMin = Vector2.zero
        -- img.transform.offsetMax = Vector2.zero
        -- img:GetComponent("RawImage").texture = self.Images.Wormhole1
        -- img:GetComponent("RawImage").color = curColor
        
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
      local p = HBU.Instantiate("Panel",closestNode)                    --create panel with name on it
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


function RemoteCam:SetupGUI()
    if    not self.GUIParent
    then  self.GUIParent = HBU.menu.transform:Find("Foreground").gameObject
    end
    for k,v in pairs({"textGUI1","textGUI2","textGUI3"}) do
        self[v] = HBU.Instantiate("Text",self.GUIParent):GetComponent("Text")
        HBU.LayoutRect(self[v].gameObject,Rect((Screen.width/2)-100+((k-1)*100),200,100,200))
        self[v].color = Color((k%2),((k+1)%2),((k-1)%2),1)
        self[v].text = ""
        if Font then  self[v].font = Font.CreateDynamicFontFromOSFont({"consolas","Roboto","Arial"}, 12)  end

    end
end


function RemoteCam:DestroyObjects(t,selfCall)
    if      type(t) == "nil"      and  self.GameObjects and not selfCall     then  if self:DestroyObjects(self.GameObjects,true) then return true end
    elseif  type(t) == "string"   and  self[t]                               then  if self:DestroyObjects(self[t],true) then if type(self[t]) == "table" and #self[t] > 0 then self[t] = {} ; else self[t] = nil ; end ; return true ; end
    elseif  type(t) == "table"    and  type(t[1]) == "userdata"
     --and  ( type(t[2]) == "nil" or type(t[2]) ~= "userdata" )
       and  not Slua.IsNull(t[1])                                            then  GameObject.Destroy(t[1].gameObject) ; return true
    elseif  type(t) == "table"                                               then  local ret = false ; for k,v in pairs(t) do if self:DestroyObjects(v,true) then ret = true ; end ; end return ret
    elseif  type(t) == "userdata" and not Slua.IsNull(t)                     then  GameObject.Destroy(t.gameObject) ; return true
    else    return false
    end
    return false
end


function RemoteCam:OnDestroy()
  Debug.Log("RemoteCam:OnDestroy()")
  self:DestroyObjects()
end


function main(gameObject) RemoteCam.gameObject = gameObject ; return RemoteCam ; end
