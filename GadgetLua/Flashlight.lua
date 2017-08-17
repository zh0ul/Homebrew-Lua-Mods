local Flashlight = {}
function main(go) Flashlight.gameObject = go ; return Flashlight ; end


function Flashlight:Awake()
  self.useKey = HBU.GetKey("UseGadget") --HBU.GetKey fetches from settings, always CamelCase 
      --^ If you want to use W/S for instance, you'd do HBU.GetKey("Move"), then HBU.GetKey:GetKey() will give you a -1 -> 1 value ;) 
  --Create objects
  self.useKey2 = HBU.GetKey("UseGadgetSecondary")
  self.obj = GameObject("FlashlightObj") --name the object FlaslightObj, cause why not
  self.obj.transform:SetParent(Camera.main.transform) --parent it inside the main camera
  self.obj.transform.localPosition = Vector3(0,0,0) --set the **localposition** to 0,0,0 (aka relative pos to parent)
  self.obj.transform.localRotation = Quaternion.identity --set localrotation to identity (forward)
  self.light = self.obj:AddComponent("UnityEngine.Light") --Add a light component, which is under UnityEngine
  self.color = { r = 0.5, g = 0.5, b = 0.5, a = 1.0 }
  local r,g,b = self.color.r, self.color.g, self.color.b
  self.light.type = LightType.Spot --Defaults to Point light so, change to spot
  self.light.range = 1000 -- up the range a fair bit
  self.light.intensity = 1.25 -- up the intensity a bit
  self.light.spotAngle = 70 -- set the angle to a neat 70° 
  self.light.enabled = false -- Turn it off by default
  self.light.color = Color(self.r, self.b, self.g, 1)
  self.running = false
  self.objectsToDestroy = { "obj", "textGo" }
  local parent = HBU.menu.transform:Find("Foreground").gameObject
  self.textGo = HBU.Instantiate("Text",parent):GetComponent("Text")
  HBU.LayoutRect(self.textGo.gameObject,Rect(5,35,300,200))
  self.textGo.colorSet = function() self.textGo.color = Color(r,g,b,1) ;end
  self.textGo.textSet = function() self.textGo.text = " Current Red: " .. tostring(r) .. "\n Current Green: " .. tostring(g) .. "\n Current Blue:" .. tostring(b) .. "\n Light Intensity:" .. tostring(self.light.intensity) .. "\n Light Range:" .. tostring(self.light.range) .. "\n Cone Degrees:" .. tostring(self.light.spotAngle); end;
  self.textGo.colorSet()
  self.textGo.textSet()
  self.textGo.ect:SetActive(self.running)
  self.keys = {
    I = function() r = (r + 0.1)%1 ; end,
    J = function() r = (r - 0.1)%1 ; end,
    O = function() g = (g + 0.1)%1 ; end,
    K = function() g = (g - 0.1)%1 ; end,
    P = function() b = (b + 0.1)%1 ;  end,
    L = function() b = (b - 0.1)%1 ;  end,
    N = function() self.light.range = 1000 ; end,
    M = function() self.light.intensity = 1.25; end,
    Y = function() self.light.intensity = self.light.intensity+0.1; end,
    G = function() self.light.intensity = self.light.intensity-0.1; end,
    U = function() self.light.range = self.light.range+50; end,
    H = function() self.light.range = self.light.range-50; end,
  }
end

function Flashlight:Update()

  if ( HBU.MayControle() == false or HBU.InSeat()  or HBU.InBuilder()) then 
    if (self.light.enabled or self.running) then
      self.running = false
      self.light.enabled = false
      self.textGo.gameObject:SetActive(false)
    end
  end

  if ( HBU.MayControle() == false or HBU.InSeat() or HBU.InBuilder()) then return end

  if (self.useKey:GetKeyDown()) then
    self.light.enabled = not self.light.enabled --turn it on/off if useKey is pressed down 
  end

  if self.keys
  then
      for funcKey,func in pairs(self.keys) do
        if  ( Input.GetKeyDown( KeyCode[funcKey] ) ) then func() end
      end
  end

  self.light.color = Color(self.r, self.g, self.b, 1)

  if self.running then
    self.textGo.textSet()
  end 

  if(self.useKey2:GetKeyDown()) then
    self.running = not self.running
    self.textGo.gameObject:SetActive(self.running)
  end
end

function Flashlight:OnDestroy()
    self:DestroyObjects()
end

function Flashlight:DestroyObjects()
  for k,v in pairs(self.objectsToDestroy) do
    if    v  and  self[v]  and  self[v].gameObject
    then  GameObject.Destroy(self[v])
    end
  end
end
