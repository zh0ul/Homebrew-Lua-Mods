
local Flashlight={}

function main(gameObject)
  Flashlight.gameObject = gameObject
  return Flashlight
end

function Flashlight:Awake()
  self.LightSwitch = HBU.GetKey("UseGadget") --HBU.GetKey fetches from settings, always CamelCase
      --^ If you want to use W/S for instance, you'd do HBU.GetKey("Move"), then HBU.GetKey:GetKey() will give you a -1 -> 1 value ;)

  --Create objects
  self.obj = GameObject("FlashlightObj") --name the object FlaslightObj, cause why not
  self.obj.transform:SetParent(Camera.main.transform) --parent it inside the main camera
  self.obj.transform.localPosition = Vector3(0,0,0) --set the **localposition** to 0,0,0 (aka relative pos to parent)
  self.obj.transform.localRotation = Quaternion.identity --set localrotation to identity (forward)
  self.light = self.obj:AddComponent("UnityEngine.Light") --Add a light component, which is under UnityEngine
  self.light.type = LightType.Point --Defaults to Point light so, change to spot
  self.light.range = 10000 -- up the range a fair bit
  self.light.intensity = 2.5 -- up the intensity a bit
  self.light.spotAngle = 55 -- set the angle to a neat 55°
  self.light.enabled = false -- Turn it off by default
  self.red   = 1 -- Color of light
  self.green = 1
  self.blue  = 1
  self.alpha = 2
  self.light.color = Color(self.red, self.green, self.blue, self.alpha)
end

function Flashlight:Update()
  --if (self.LightSwitch:GetKeyUp  ())    then self.light.enabled = false
  --end
  --if (self.LightSwitch:GetKeyDown  ())  then self.light.enabled = true
  --end
  
  if (self.LightSwitch:GetKeyDown  ())  then self.light.enabled = not self.light.enabled   end
  
end

function Flashlight:OnDestroy()
  GameObject.Destroy(self.obj) --since we create an object, we don't wanna add infinite amount of objects obviously ;)
end