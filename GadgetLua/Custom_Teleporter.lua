local Gadget={}
function main(gameObject)  Gadget.gameObject = gameObject  return Gadget  end

function Gadget:Awake()
  Debug.Log("Custom_Teleporter:Awake()")
  self.useGadgetKey = HBU.GetKey("UseGadget")
  self.useGadgetSecondaryKey = HBU.GetKey("UseGadgetSecondary")
  self.teleportLocations = HBU.GetTeleportLocations()
  self.showing = false
  self.teleportNodes = {}
  self.vehicles = {}
  self.wormholeImage = HBU.LoadTexture2D(HBU.GetLuaFolder().."/GadgetLua/TeleportIcon.png")
  self.wormholeImage2 = HBU.LoadTexture2D(HBU.GetLuaFolder().."/GadgetLua/TeleportIcon2.png")
  self.ringImage = HBU.LoadTexture2D(HBU.GetLuaFolder().."/GadgetLua/TeleportRing.png")
  self.teleporting = false
  self.defaultFoV = HBU.GetSetting("FieldOfView")
  self.GameObjects = { "ring", "teleportNodes", }
  self:SetDefaults()
end

function Gadget:DestroyObjects(t,selfCall)
    if      type(t) == "nil"      and  self.GameObjects and not selfCall             then  if self:DestroyObjects(self.GameObjects,true) then return true end
    elseif  type(t) == "string"   and  self[t]                                       then  if self:DestroyObjects(self[t],true) then if type(self[t]) == "table" and #self[t] > 0 then self[t] = {} ; else self[t] = nil ; end ; return true ; end
    elseif  type(t) == "table"    and t[1]  and  type(t[1]) == "userdata"
       and  not Slua.IsNull(t[1])                                                    then  GameObject.Destroy(t[1]) ; return true
    elseif  type(t) == "table"                                                       then  local ret = false ; for k,v in pairs(t) do if self:DestroyObjects(v,true) then ret = true ; end ; end return ret
    elseif  type(t) == "userdata" and not Slua.IsNull(t)                             then  GameObject.Destroy(t) ; return true
                                                                                     else  return false
    end
    return false
end

function Gadget:OnDestroy()
  Debug.Log("Custom_Teleporter:OnDestroy()")
  if(self.teleporting)then 
    Camera.main.fieldOfView = self.defaultFoV
    local obj = self.teleporterSettings.obj
    HBU.TeleportPlayer(self.teleporterSettings.obj.transform.position)
  end
  self:DestroyObjects()
  self:SetDefaults()
end

function Gadget:Update()
  if( HBU.MayControle() == false or HBU.InSeat() or HBU.InBuilder()) then return end
  if not self.teleporting then 
    if( self.useGadgetSecondaryKey.GetKey() > 0.5 ) then
      self:GetMyVehicles()
      if not self.showing  then
        self.showing = true
        self:CreateTeleportNodes()
      else
        self:AimCheck()
        self:UpdateTeleportNodes()
      end
    else
      if  self.showing   then
        if  self.aimedAtTeleportLocation  then
          self:Teleport(self.aimedAtTeleportLocation)
        end
        self.showing = false
        self:DestroyObjects()
      end
    end
  else
    self:UpdateTP()
  end
end

function Gadget:UpdateTP()
    local s = self.teleporterSettings
    if  s  and  s.updatePos  then 
      s.player.transform.position = Vector3.MoveTowards(s.player.transform.position, s.obj.transform.position, s.speed * 10)
      s.speed = s.speed + (s.speed * Time.deltaTime * 10)
      if  Vector3.Distance(s.player.transform.position, s.obj.transform.position) < 0.5  then 
        s.updatePos = false
      end
      Camera.main.fieldOfView = Mathf.Lerp(Camera.main.fieldOfView, 170, Mathf.Clamp01(s.speed/500))
    else 
      Camera.main.fieldOfView = Mathf.MoveTowards(Camera.main.fieldOfView, self.defaultFoV, Time.deltaTime * self.defaultFoV)
      if(Camera.main.fieldOfView == self.defaultFoV) then 
        self.teleporting = false 
        Camera.main.fieldOfView = self.defaultFoV
        -- Debug.Log(tostring(s.obj.transform.position))
        HBU.TeleportPlayer(s.obj.transform.position)
        self.teleporterSettings.rb.isKinematic = false
      end 
    end
end

function Gadget:SetDefaults()
    self.teleporterSettings = {
      speed = 0.5,
      updatePos = true,
    }
end

function Gadget:CreateTeleportNodes()
  local parent = HBU.menu.transform:Find("Foreground").gameObject

  self.ring = HBU.Instantiate("RawImage",parent)
  HBU.LayoutRect(self.ring,Rect((Screen.width*0.5)-256,(Screen.height*0.5)-256,512,512))
  self.ring:GetComponent("RawImage").texture = self.ringImage
  self.ring:GetComponent("RawImage").color = Color(0.5,0.5,0.5,1)
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
    self.teleportNodes[#self.teleportNodes+1] = { node , i , img2 , rotSpeed }
  end

  -- Create pseudo spawn points out of vehicles.
  if self.vehicles
  then
      for k,v in pairs(self.vehicles)
      do
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
        img:GetComponent("RawImage").color = Color(0.9, 0.9, 0.9)
        
        local img2 = HBU.Instantiate("RawImage",node)
        img2.name = "WormHole2"
        img2.transform.anchorMin = Vector2.zero
        img2.transform.anchorMax = Vector2.one
        img2.transform.offsetMin = Vector2.zero
        img2.transform.offsetMax = Vector2.zero
        img2:GetComponent("RawImage").texture = self.wormholeImage2
        img2:GetComponent("RawImage").color =  Color(0.9, 0.9, 0.9)

        local rotSpeed = Mathf.Clamp(Random.value,0.5,1)
        self.teleportNodes[#self.teleportNodes+1] = { node, v, img2, rotSpeed, "Vehicle "..tostring(k), Color(0.9, 0.9, 0.9) }
      end
  end

end

function Gadget:UpdateTeleportNodes()
  --position nodes on screenspace
  for i,v in pairs(self.teleportNodes) do
    local screenPos = Camera.main:WorldToScreenPoint(v[2].transform.position)
    --screenPos.y = Screen.height - screenPos.y
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

function Gadget:AimCheck() 
  --return the teleport node that we are aimaing at
  local cl = { ang = 10, node = false, nodeName = false, obj = false, color = false }
  local closest = 10
  local closestNode = false
  local closestNodeName = ""
  local closestTeleportLocation = false
  local closestTeleportColor = Color(1,1,1,1)
  for i,v in pairs( self.teleportNodes ) do
    local ang = Vector3.Angle(Camera.main.transform.forward,v[2].transform.position-Camera.main.transform.position) 
    if( ang < closest ) then
      closest = ang
      closestNode = v[1]
      if v[5] then closestNodeName = v[5] elseif v[2].locationName then closestNodeName = v[2].locationName ; end
      closestTeleportLocation = v[2]
      if v[6] then closestTeleportColor = v[6] elseif v[2].color then  closestTeleportColor = v[2].color ; end
    end
    if ang < cl.ang
    then
        cl.ang = ang
        cl.node = v[1]
        cl.nodeName = v[5] or v[2].locationName
        cl.color = v[6] or v[2].color
        cl.obj = v[2]
    end
  end
  
  if  closestNode and self.aimedAtNode ~= closestNode
  then   
    --un highlight prev node if any
    if  Slua.IsNull(self.aimedAtNode) == false then
      --set ring color
      self.ring:GetComponent("RawImage").color = Color(0.5,0.5,0.5,0.5)
      
      --reset the size of the rect
      self.aimedAtNode.transform.sizeDelta = Vector2(40,40)
      --bring alpha back down
      self.aimedAtNode:GetComponent("CanvasGroup").alpha = 0.2
      --remove the panel with name on it
      if Slua.IsNull(self.aimedAtNode.transform:Find("Display")) == false  then
        GameObject.Destroy(self.aimedAtNode.transform:Find("Display").gameObject)
      end
    end
    --highlight new node if any
    if  not Slua.IsNull(closestNode) then
    --set ring color
      self.ring:GetComponent("RawImage").color = closestTeleportColor
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
    end
  end
  if closestNode then  self.aimedAtNode = closestNode ; elseif self.aimedAtNode then self.aimedAtNode = nil ; end
  if closestTeleportLocation then self.aimedAtTeleportLocation = closestTeleportLocation ; elseif self.aimedAtTeleportLocation then self.aimedAtTeleportLocation = nil ; end
  if not self.aimedAtNode then self.ring:GetComponent("RawImage").color = Color(0.7,0.7,0.7) ; end
end

function Gadget:GetMyVehicles()
  local vehicles = GameObject.FindObjectsOfType("VehiclePiece")
  local ret = {}
  for v in Slua.iter(vehicles) do 
       if not Slua.IsNull( v ) then ret[#ret+1] = v end
  end 
  if #ret == 0 then if self.vehicles then self.vehicles = nil ; end ; return ; end
  self.vehicles = ret
end

function Gadget:GetLastVehicle()
    local   veh = HBU.GetMyOldestVehicle()
    if      veh
    and     not Slua.IsNull(veh)
    then    self.vehicle = veh ; Debug.Log("Found oldest vehicle at "..tostring(veh.transform.position) )
    elseif  self.vehicle and Slua.IsNull(self.vehicle)
    then    self.vehicle = nil ; Debug.Log("Oldest vehicle not found.  Wiped record.")
    else    Debug.Log("Oldest vehicle not found.")
    end
end

function Gadget:Teleport( obj ) 
  if(self.teleporting) then return end
  if( Slua.IsNull(obj) ) then return end

  if(Slua.IsNull(self.teleporterSettings.player)) then 
    local player = GameObject.Find("Player")
    if(Slua.IsNull(player)) then 
      return
    else 
      self.teleporterSettings.player = player
    end
  end

  if(Slua.IsNull(self.teleporterSettings.rb)) then 
    local rb = self.teleporterSettings.player.gameObject:GetComponent("Rigidbody")
    if(Slua.IsNull(rb)) then 
      return
    else
      self.teleporterSettings.rb = rb
    end
  end
  
  self.teleporterSettings.rb.isKinematic = true
  self.teleporting = true
  self.teleporterSettings.speed = 0.5
  self.teleporterSettings.obj = obj
  self.teleporterSettings.updatePos = true
end