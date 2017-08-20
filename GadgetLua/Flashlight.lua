local Flashlight = {}
function main(go) Flashlight.gameObject = go ; return Flashlight ; end

-- local Font = Slua.GetClass("UnityEngine.Font")  or Slua.GetClass("UnityEngine.Font, UnityEngine")

function Flashlight:Awake()
    print("Flashlight:Awake()")
    self.setColor                    = function(obj,r,g,b,a) if not obj or Slua.IsNull(obj) then return ; end ; r,g,b,a = r or self.r, g or self.g, b or self.b, a or self.a ; obj.color = Color(r,g,b,a) ; end
    self.setText                     = function(obj,text)    if not obj or Slua.IsNull(obj) then return ; end ; text = tostring(text) ; if obj.text then obj.text = text ; end ; end
    self.UseGadget                   = HBU.GetKey("UseGadget")
    self.UseGadgetSecondary          = HBU.GetKey("UseGadgetSecondary")
    self.obj                         = GameObject("FlashlightObj")                -- name the object FlaslightObj, cause why not
    self.obj.transform:SetParent(Camera.main.transform)                           -- parent it inside the main camera
    self.obj.transform.localPosition = Vector3(0,0,1)                             -- set the **localposition** to 0,0,0 (aka relative pos to parent)
    self.obj.transform.localRotation = Quaternion.identity                        -- set localrotation to identity (forward)
    self.light                       = self.obj:AddComponent("UnityEngine.Light") -- Add a light component, which is under UnityEngine
    self.light.type                  = LightType.Spot                             -- Defaults to Point light so, change to spot
    self.light.range                 = 100                                        -- up the range a fair bit
    self.light.intensity             = 4.0                                        -- up the intensity a bit
    self.light.spotAngle             = 45                                         -- set the angle to a neat 70° 
    self.light.enabled               = true                                       -- Turn on light by default
    self.r,self.g,self.b,self.a      = 0.5,0.5,0.5,0.5
    self.light.color                 = Color(self.r, self.b, self.g, self.a)
    self.displayValues               = true
    self.objectsToDestroy            = { "obj", "textHUD1",  "textHUD2", "textHUD3", "light", }
    self:SetupHUD()

    self.actions = {
        RESET           = function() self.light.range     = 1000  ; self.light.intensity = 3.0  ; end,
        R_UP            = function() self.r               = math.min( 1, (self.r + 0.1)%1 )     ; end,
        R_DOWN          = function() self.r               = math.max( 0, (self.r - 0.1)%1 )     ; end,
        G_UP            = function() self.g               = math.min( 1, (self.g + 0.1)%1 )     ; end,
        G_DOWN          = function() self.g               = math.max( 0, (self.g - 0.1)%1 )     ; end,
        B_UP            = function() self.b               = math.min( 1, (self.b + 0.1)%1 )     ; end,
        B_DOWN          = function() self.b               = math.max( 0, (self.b - 0.1)%1 )     ; end,
        INTENSITY_UP    = function() self.light.intensity = self.light.intensity+0.1            ; end,
        INTENSITY_DOWN  = function() self.light.intensity = self.light.intensity-0.1            ; end,
        RANGE_UP        = function() self.light.range     = self.light.range+50                 ; end,
        RANGE_DOWN      = function() self.light.range     = self.light.range-50                 ; end,
    }

    self.Variables      = {
        { self.light, "enabled",   "Enabled",   },
        { self,       "r",         "Red",       },
        { self,       "g",         "Green",     },
        { self,       "b",         "Blue",      },
        { self.light, "intensity", "Intensity", },
        { self.light, "range",     "Range",     },
        { self.light, "angle",     "Angle",     },
        index = 1,
    }

    self.keys           = {
        lmb             = HBU.GetKey("UseGadget"),
        rmb             = HBU.GetKey("UseGadgetSecondary"),
        inv             = HBU.GetKey("Inventory"),
        zoomIn          = HBU.GetKey("ZoomIn"),
        zoomOut         = HBU.GetKey("ZoomOut"),
        run             = HBU.GetKey("Run"),
        shift           = HBU.GetKey("Shift"),
        move            = HBU.GetKey("Move"),
    }
end


function Flashlight:Update()

    if    ( HBU.MayControle() == false  or  HBU.InSeat()  or HBU.InBuilder())
    or    not  self.keys
    then 
          if  self.light.enabled  or  self.displayValues  then
              self.displayValues = false
              self.light.enabled = false
              self.textHUD1.text,self.textHUD2.text,self.textHUD3.text = "","",""
          end
          return
    end

    if      self.keys.lmb.GetKeyDown() and not self.keys.rmb.GetKey() > 0.5
    then
            -- if self.displayValues then self.displayValues = false ; self.setText(self.textHUD1,"") ; self.setText(self.textHUD2,"") ; else self.light.enabled = not self.light.enabled ; self.displayValues = self.light.enabled end
            self.light.enabled = not self.light.enabled
            self.displayValues = self.light.enabled
            self.text = "" ; self.textHUD2.text = "" ; self.textHUD3.text = ""

    elseif  self.keys.rmb.GetKey() > 0.5
    then
            HBU.DisableGadgetMouseScroll()
            if self.keys.zoomIn.GetKey() > 0.5  then 

    end

    self.light.color = Color(self.r, self.g, self.b, self.a)

    if    self.light.enabled  and  self.displayValues
    then  
        self.setText( self.textHUD1, "Enabled\nRed\nGreen\nBlue\nIntensity\nRange\nAngle" )
        self.setText( self.textHUD2, string.format( "%-5s\n%.2f\n%.2f\n%.2f\n%.2f\n%.2f\n%.2f" , tostring(self.light.enabled), self.r, self.g, self.b, self.light.intensity, self.light.range, self.light.spotAngle ) )
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


function Flashlight:SetupHUD()
    local parent  = HBU.menu.transform:Find("Foreground").gameObject
    for k,v in pairs({"textHUD1","textHUD2","textHUD3",}) do
      --if Font then  Font.font = Font.CreateDynamicFontFromOSFont({"consolas","Roboto","Arial"}, 12)  end
        self[v]        = HBU.Instantiate("Text",parent):GetComponent("Text")
        HBU.LayoutRect(self[v].gameObject,Rect( 5+((k-1)*100), 35, 300, 200 ) )
        self[v].color  = Color(k%3,(k-1)%2,k%2,1)
        self[v].text   = ""
    end
end
