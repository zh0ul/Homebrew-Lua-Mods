local Gadget = {}

function Gadget:Awake()
  Debug.Log("RemoteCam:Awake()")
  self.useGadgetKey          = HBU.GetKey("UseGadget")
  self.useGadgetSecondaryKey = HBU.GetKey("UseGadgetSecondary")
  self.path_userdata         = Application.persistentDataPath
  self.path_gadget_user      = self.path_userdata.."/Lua/GadgetLua/"
  self.path_gadget           = HBU.GetLuaFolder().."/GadgetLua/"
  self.targetNodes           = {}
  self.wormholeImage         = HBU.LoadTexture2D(self.path_gadget.."TeleportIcon.png")
  self.wormholeImage2        = HBU.LoadTexture2D(self.path_gadget.."TeleportIcon2.png")
  self.ringImage1            = HBU.LoadTexture2D(self.path_gadget_user.."RemoteCamRing1.png")
  self.ringImage2            = HBU.LoadTexture2D(self.path_gadget_user.."RemoteCamRing2.png")
  self.ringImage3            = HBU.LoadTexture2D(self.path_gadget_user.."RemoteCamRing3.png")
  self.GameObjects           = { "targetNodes", "ring1", "ring2", "ring3" }
  self.Cams                  = {}
  self.Cams.Active           = {}
  self.active                = false
  self.camMode               = 3
  self.x,self.y,self.z       = 0,0,0
  self.camOffset             = Vector3(self.x,self.y,self.z)
  self:SetDefaults()
end


function Gadget:SetDefaults()
    self.mode      = -1
    print("Mode:"..tostring(self.mode))
    if self.vehicles and #self.vehicles > 0 then self.vehicles  = {} ; end
end


function Gadget:RotateInnerRing()
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

function Gadget:Update()

    if    HBU.MayControle() == false or HBU.InSeat() or HBU.InBuilder()
    then  return
    end

    if    self.mode == -1 then self.mode = 0 ; return ; end

    if    self.useGadgetSecondaryKey.GetKey() > 0.5
    and   ( self.mode == 0 or self.mode == 3 )
    then
          if  self.aimedAtTarget then self.aimedAtTarget = nil ; end
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
          self:RotateInnerRing()
    end

    if    self.mode == 1
    and   self.aimedAtTarget
    -- and   self.useGadgetSecondaryKey.GetKey() == 0
    and   self.useGadgetSecondaryKey.GetKeyUp()
    then
        self.mode = 2
        print("Mode:"..tostring(self.mode))

    elseif  ( self.mode == 1 and self.useGadgetSecondaryKey.GetKey() == 0 )
    or      self.mode == 2
    then
          self:DestroyObjects()
        --self:SetDefaults()
          if not self.aimedAtTarget then self.mode = -1 ; HBU.EnableGadgetMouseScroll() else self.mode = 3 ; HBU.DisableGadgetMouseScroll() ; end

          print("Mode:"..tostring(self.mode))

    elseif  self.mode == 3
    then
            if    self.useGadgetKey.GetKey() > 0.5
            then
                  self.aimedAtTarget = GameObject.Find("Player").gameObject:GetComponent("Rigidbody")
                  HBU.EnableGadgetMouseScroll()
                  GameObject.Find("Player").gameObject:GetComponent("Rigidbody").isKinematic = true
                  self.camOffset = Vector3(0,0,0)
                  Camera.main.transform.position = self.aimedAtTarget.transform.position + self.camOffset
                  -- self.mode = -1
                  -- print("Mode:"..tostring(self.mode))
                  return
            end
            self.camOffset = Vector3(0,5,5)
            Camera.main.transform.position = self.aimedAtTarget.transform.position + self.camOffset
            GameObject.Find("Player").gameObject:GetComponent("Rigidbody").isKinematic = false
    end

end


function Gadget:CreateTargetNodes()
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

  -- Create pseudo spawn points out of vehicles.
  if  self.vehicles
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
        self.targetNodes[#self.targetNodes+1] = { node, v, img2, rotSpeed, "Vehicle "..tostring(k), Color(math.random(0,255)/255, math.random(0,255)/255, math.random(0,255)/255, 0.9) }
      end
  end

end


function Gadget:UpdateTargetNodes()
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


function Gadget:AimCheck() 

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

  if  closestNode and self.aimedAtNode ~= closestNode
  then   
      --un highlight prev node if any
      if  self.aimedAtNode
      and not Slua.IsNull(self.aimedAtNode)
      then

        --self.ring:GetComponent("RawImage").color = Color(0.5,0.5,0.5,0.5)
          -- reset the size of the rect
          self.aimedAtNode.transform.sizeDelta = Vector2(24,24)
          -- bring alpha back down
          self.aimedAtNode:GetComponent("CanvasGroup").alpha = 0.2
          -- remove the panel with name on it
          if not   Slua.IsNull(self.aimedAtNode.transform:Find("Display")) then
            GameObject.Destroy(self.aimedAtNode.transform:Find("Display").gameObject)
          end
      end
      --highlight new node if any
      if  not Slua.IsNull(closestNode) then
      --set ring color
        self.ring1:GetComponent("RawImage").color = closestTargetColor
        self.ring2:GetComponent("RawImage").color = Color(0,0,0,0)
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
  if closestNode      then  self.aimedAtNode   = closestNode          ; elseif self.aimedAtNode    then self.aimedAtNode   = nil  ; end
  if closestTarget    then  self.aimedAtTarget = closestTarget        ; elseif self.aimedAtTarget  then self.aimedAtTarget = nil  ; end
  -- if not self.aimedAtNode     then  self.ring:GetComponent("RawImage").color = Color(0.7,0.7,0.7) ; end
end


function Gadget:GetAllVehicleParts()
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
    then    self.vehicle = veh
    elseif  self.vehicle and Slua.IsNull(self.vehicle)
    then    self.vehicle = nil
    end
end


function Gadget:DestroyObjects(t,selfCall)
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


function Gadget:OnDestroy()
  Debug.Log("RemoteCam:OnDestroy()")
  self:DestroyObjects()
  self:SetDefaults()
end


function main(gameObject) Gadget.gameObject = gameObject ; return Gadget ; end
