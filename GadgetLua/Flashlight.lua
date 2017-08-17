local Flashlight = {}
function main(go) Flashlight.gameObject = go ; return Flashlight ; end


function Flashlight:Awake()
  print("Flashlight:Awake()")
  self.setColor                    = function(obj,r,g,b,a) if not obj or Slua.IsNull(obj) then return ; end ; r,g,b,a = r or self.r, g or self.g, b or self.b, a or self.a ; obj.color = Color(r,g,b,a) ; end
  self.setText                     = function(obj,text)    if not obj or Slua.IsNull(obj) then return ; end ; text = tostring(text) ; obj.text = text ; end;
  self.useKey                      = HBU.GetKey("UseGadget")
  self.useKey2                     = HBU.GetKey("UseGadgetSecondary")
  self.obj                         = GameObject("FlashlightObj")                -- name the object FlaslightObj, cause why not
  self.obj.transform:SetParent(Camera.main.transform)                           -- parent it inside the main camera
  self.obj.transform.localPosition = Vector3(0,0,1)                             -- set the **localposition** to 0,0,0 (aka relative pos to parent)
  self.obj.transform.localRotation = Quaternion.identity                        -- set localrotation to identity (forward)
  self.light                       = self.obj:AddComponent("UnityEngine.Light") -- Add a light component, which is under UnityEngine
  self.light.type                  = LightType.Spot                             -- Defaults to Point light so, change to spot
  self.light.range                 = 1000                                       -- up the range a fair bit
  self.light.intensity             = 1.25                                       -- up the intensity a bit
  self.light.spotAngle             = 70                                         -- set the angle to a neat 70° 
  self.light.enabled               = false                                      -- Turn off light by default
  self.r,self.g,self.b,self.a      = 0.5,0.5,0.5,0.5
  self.light.color                 = Color(self.r, self.b, self.g, self.a)
  self.running                     = false
  self.objectsToDestroy            = { "obj", "textGo","light" }
  local parent                     = HBU.menu.transform:Find("Foreground").gameObject
  self.textGo                      = HBU.Instantiate("Text",parent):GetComponent("Text")
  HBU.LayoutRect(self.textGo.gameObject,Rect(5,35,300,200))
  self.setColor(self.textGo,1,1,0,1)
  self.setText(self.textGo," Current Red: " .. tostring(self.r) .. "\n Current Green: " .. tostring(self.g) .. "\n Current Blue:" .. tostring(self.b) .. "\n Light Intensity:" .. tostring(self.light.intensity) .. "\n Light Range:" .. tostring(self.light.range) .. "\n Cone Degrees:" .. tostring(self.light.spotAngle))
  self.textGo.gameObject:SetActive( self.running )
  self.keys = {
    I = function() self.r               = (self.r + 0.1)%1 ; end,
    J = function() self.r               = (self.r - 0.1)%1 ; end,
    O = function() self.g               = (self.g + 0.1)%1 ; end,
    K = function() self.g               = (self.g - 0.1)%1 ; end,
    P = function() self.b               = (self.b + 0.1)%1 ;  end,
    L = function() self.b               = (self.b - 0.1)%1 ;  end,
    N = function() self.light.range     = 1000 ; end,
    M = function() self.light.intensity = 1.25; end,
    Y = function() self.light.intensity = self.light.intensity+0.1; end,
    G = function() self.light.intensity = self.light.intensity-0.1; end,
    U = function() self.light.range     = self.light.range+50; end,
    H = function() self.light.range     = self.light.range-50; end,
  }
end

function Flashlight:Update()

    if  ( HBU.MayControle() == false  or  HBU.InSeat()  or HBU.InBuilder())  then 
          if  self.light.enabled  or  self.running  then
              self.running = false
              self.light.enabled = false
              self.textGo.gameObject:SetActive(false)
          end
          return
    end

    if    (self.useKey:GetKeyDown())
    then  self.light.enabled = not self.light.enabled -- turn light on/off
    end

    if  self.keys  then
        for funcKey,func  in  pairs(self.keys)  do
            if  ( Input.GetKeyDown( KeyCode[funcKey] ) ) then func() end
        end
        if  self.running then
            self.light.color = Color(self.r, self.g, self.b, self.a)
        end
        self.setText( self.textGo, " Current Red: " .. tostring(self.r) .. "\n Current Green: " .. tostring(self.g) .. "\n Current Blue:" .. tostring(self.b) .. "\n Light Intensity:" .. tostring(self.light.intensity) .. "\n Light Range:" .. tostring(self.light.range) .. "\n Cone Degrees:" .. tostring(self.light.spotAngle) )
    end

    if  self.useKey2:GetKeyDown()  then
        self.running = not self.running
        self.textGo.gameObject:SetActive(self.running)
    end
end

function Flashlight:OnDestroy()
    print("Flashlight:OnDestroy()")
    self:DestroyObjects()
end

function Flashlight:DestroyObjects()
  for k,v in pairs(self.objectsToDestroy) do
    if    v  and  self[v]  and  self[v].gameObject
    then  GameObject.Destroy(self[v])
    end
  end
end

