local Flashlight = {}

-- local Font = Slua.GetClass("UnityEngine.Font")  or Slua.GetClass("UnityEngine.Font, UnityEngine")

function Flashlight:Awake()
    print("Flashlight:Awake()")
    self.obj                         = GameObject("FlashlightObj")                -- name this object FlaslightObj
    self.obj.transform:SetParent(Camera.main.transform)                           -- Parent it inside the main camera
    self.obj.transform.localPosition = Vector3(0,0,1)                             -- set the **localposition** to 0,0,0 (aka relative pos to parent)
    self.obj.transform.localRotation = Quaternion.identity                        -- Set localrotation to identity (forward)
    self.light                       = self.obj:AddComponent("UnityEngine.Light") -- Add a light component, which is under UnityEngine
    self.lightType                   = "Spot"
    self.light.type                  = LightType[self.lightType]                  -- Defaults to Point light so, change to spot
    self.light.range                 = 100                                        -- up the range a fair bit
    self.light.intensity             = 4.0                                        -- up the intensity a bit
    self.light.spotAngle             = 45                                         -- set the angle to a neat 70° 
    self.light.enabled               = true                                       -- Turn on light by default
    self.r,self.g,self.b,self.a      = 0.5,0.5,0.5,0.5
    self.light.color                 = Color(self.r, self.b, self.g, self.a)
    self.objectsToDestroy            = { "textHUD1",  "textHUD2", "textHUD3", "light", "gameObject", "obj" }
    self:SetupHUD()

    self.Actions = {
        TOGGLE          = function() self.light.enabled   = not self.light.enabled              ; end,
        R_UP            = function() self.r               = math.min( 5, self.r + 0.1 )         ; end,
        R_DOWN          = function() self.r               = math.max( 0, self.r - 0.1 )         ; end,
        G_UP            = function() self.g               = math.min( 5, self.g + 0.1 )         ; end,
        G_DOWN          = function() self.g               = math.max( 0, self.g - 0.1 )         ; end,
        B_UP            = function() self.b               = math.min( 5, self.b + 0.1 )         ; end,
        B_DOWN          = function() self.b               = math.max( 0, self.b - 0.1 )         ; end,
        INTENSITY_UP    = function() self.light.intensity = self.light.intensity+0.1            ; end,
        INTENSITY_DOWN  = function() self.light.intensity = self.light.intensity-0.1            ; end,
        RANGE_UP        = function() self.light.range     = self.light.range+10                 ; end,
        RANGE_DOWN      = function() self.light.range     = self.light.range-10                 ; end,
        ANGLE_UP        = function() self.light.spotAngle = self.light.spotAngle+5              ; end,
        ANGLE_DOWN      = function() self.light.spotAngle = self.light.spotAngle-5              ; end,
        TYPE_UP         = function() local getNextValue,firstValue,newValue = false,false,false ; for k,v in pairs(LightType) do if not firstValue then firstValue = k  end ; if k == self.lightType then getNextValue = true ; elseif getNextValue then newValue = k ; getNextValue = false ; end ; end ; if not newValue then newValue = firstValue  end ; self.lightType = newValue ; if not LightType[self.lightType] then self.lightType = "Spot"  end;  self.light.type = LightType[self.lightType] ; end,
        TYPE_DOWN       = function() local getNextValue,lastValue,newValue  = false,false,false ; for k,v in pairs(LightType) do if k == self.lightType and lastValue then newValue = lastValue  end ; lastValue = k end ;                                                                                 if not newValue then newValue = lastValue   end ; self.lightType = newValue ; if not LightType[self.lightType] then self.lightType = "Spot"  end;  self.light.type = LightType[self.lightType] ; end,
        TOD_TOGGLE      = function() local comp = Camera.main:GetComponent("TOD_Scattering") ; self.TODToggle = not comp.enabled ; comp.enabled = self.TODToggle ; print("TOD_Scattering",tostring(self.TODToggle)) ; if not self.TODToggle then Camera.main.farClipPlane = 10000 else Camera.main.farClipPlane = 40000 ; end ; end,
        FOG_TOGGLE      = function() self.FOGToggle = not RenderSettings.fog ; RenderSettings.fog = self.FOGToggle ; print("fog",tostring(self.FOGToggle))  end,
    }

    self.Variables      = {
        Save                         = function() print( "Save settings for: "..tostring(self.Variables.SaveName) ) ;          for k,v in ipairs(self.Variables) do if v[1] and v[2] and type(v[1][v[2]]) ~= "nil" then HBU.SaveValue(self.Variables.SaveName,tostring(v[2]),tostring(v[1][v[2]])) ; end ; end ; end,
        Load                         = function() if  self.Variables.Loaded  then  return end ; self.Variables.Loaded = true ; for k,v in ipairs(self.Variables) do local val,var = HBU.LoadValue( self.Variables.SaveName, tostring(v[2]) ), false ; if v[1] and v[1][v[2]] then var = v[1][v[2]] ; end ; if      type(var) == "number"  then  if val ~= "" and tonumber(val)  then v[1][v[2]] = tonumber(val) ; end ; elseif  type(var) == "boolean" then  if val == "false" then v[1][v[2]] = false ; elseif v[1] and v[2] and type(v[1][v[2]]) == "nil" and val == "" and type(v[6]) ~= "nil"  then v[1][v[2]] = v[6] ; elseif v[1] and v[2] then  v[1][v[2]] = true ; end ; elseif v[1] and v[2] then v[1][v[2]] = val  end ; end ; end,
        SaveName                     = "Flashlight",
        Loaded                       = false,

        { self.light, "enabled",   "Enabled",    self.Actions.TOGGLE,         self.Actions.TOGGLE,       true,         },
        { self,       "r",         "Red",        self.Actions.R_DOWN,         self.Actions.R_UP,         1,            },
        { self,       "g",         "Green",      self.Actions.G_DOWN,         self.Actions.G_UP,         1,            },
        { self,       "b",         "Blue",       self.Actions.B_DOWN,         self.Actions.B_UP,         1,            },
        { self.light, "intensity", "Intensity",  self.Actions.INTENSITY_DOWN, self.Actions.INTENSITY_UP, 3,            },
        { self.light, "range",     "Range",      self.Actions.RANGE_DOWN,     self.Actions.RANGE_UP,     300,          },
        { self.light, "spotAngle", "Angle",      self.Actions.ANGLE_DOWN,     self.Actions.ANGLE_UP,     60,           },
        { self,       "lightType", "Type",       self.Actions.TYPE_DOWN,      self.Actions.TYPE_UP,      "Spot",       },
        { self,       "TODToggle", "TOD Toggle", self.Actions.TOD_TOGGLE,     self.Actions.TOD_TOGGLE,   Camera.main:GetComponent("TOD_Scattering").enabled, },
        { self,       "FOGToggle", "FOG Toggle", self.Actions.FOG_TOGGLE,     self.Actions.FOG_TOGGLE,   RenderSettings.fog },

        index          = 1,
        varSelected    = 0,

        gc_bytes       = 0,
        gc_setstepmul  = 0,
        gc_bytes_frame = 0,
        gc_bytes_last  = 0,
    }

    self.Variables[#self.Variables+1] = { self.Variables,   "gc_bytes",      "GC:Bytes",    nil, nil, 0, }
    self.Variables[#self.Variables+1] = { self.Variables,   "gc_bytes_frame",  "GC:PerFrame", nil, nil, 0, }

    self.keys           = {
        lmb             = HBU.GetKey("UseGadget"),
        rmb             = HBU.GetKey("UseGadgetSecondary"),
        inv             = HBU.GetKey("Inventory"),
        run             = HBU.GetKey("Run"),
        shift           = HBU.GetKey("Shift"),
        move            = HBU.GetKey("Move"),
        control         = HBU.GetKey("Control"),
    }

    gc.stop()
    gc.restart()

    -- for k,v in pairs(getmetatable(self.light)) do if tostring(k):sub(1,2) ~= "__" then print( string.format("%-20s  %30s  %s", tostring(v), tostring(k), tostring(self.light[k]) ) ) ; end ; end
end


function Flashlight:Update()

    self.Variables.gc_bytes_last   = self.Variables.gc_bytes or gc.bytes()
    self.Variables.gc_bytes        = gc.bytes()
    self.Variables.gc_bytes_frame  = self.Variables.gc_bytes - self.Variables.gc_bytes_last
    self.Variables.gc_per_frame    = gc.setstepmul()

    if    ( HBU.MayControle() == false  or  HBU.InBuilder() )
    or    not  self.keys
    then 
          if  self.light.enabled
          then
              self.light.enabled = false
          end
          return
    end

    self.Variables.Load()

    if  ( not HBU.InSeat()  or  self.keys.control.GetKey() > 0.5 )
    and     self.keys.rmb.GetKey() > 0.5  or  self.Variables.varSelected ~= 0
    then
            HBU.DisableGadgetMouseScroll() ; self.Variables.disabledMouseScrollTime = os.clock()

            if    self.keys.lmb.GetKeyDown() or self.keys.rmb.GetKeyDown()
            then
                  if      self.Variables.varSelected == 0
                  then
                          self.Variables.varSelected = self.Variables.index
                          self.Variables.selected    = self.Variables[self.Variables.index]
                          self.Variables.prevColor   = self.textHUD3.color
                          self.textHUD3.color        = Color(0,1,0,1)

                  elseif  self.Variables.varSelected > 0
                  then
                          self.textHUD3.color        = self.Variables.prevColor
                          self.Variables.varSelected = 0
                          self.Variables.selected    = false
                  end
            else
                  if    Input.GetAxis("Mouse ScrollWheel") < 0  then if self.Variables.varSelected == 0 then self.Variables.index =   self.Variables.index % #self.Variables + 1                         ; self.Variables.selected = self.Variables[self.Variables.index] ; elseif self.Variables.selected[4] then self.Variables.selected[4]()  end ; end
                  if    Input.GetAxis("Mouse ScrollWheel") > 0  then if self.Variables.varSelected == 0 then self.Variables.index = ( self.Variables.index + #self.Variables - 2 ) % #self.Variables + 1 ; self.Variables.selected = self.Variables[self.Variables.index] ; elseif self.Variables.selected[5] then self.Variables.selected[5]()  end ; end
            end

    elseif  self.keys.rmb.GetKey() == 0 and self.Variables.varSelected == 0 and self.Variables.prevColor
    then
            self.textHUD3.color      = self.Variables.prevColor
            self.Variables.prevColor = false
    end

    self.light.color = Color(self.r, self.g, self.b, self.a)

    local textTab1,textTab2,textTab3 = {},{},{}
    for k,v in ipairs(self.Variables) do  if v[3] then textTab1[#textTab1+1] = v[3] end ; if v[1] and v[2] and type(v[1][v[2]]) ~= "nil" then if type(v[1][v[2]]) == "number" then textTab2[#textTab2+1] = string.format( "%.2f", v[1][v[2]] )  ; else textTab2[#textTab2+1] = tostring(v[1][v[2]]) ; end ; else textTab2[#textTab2+1] = ""   end ; if self.Variables.index == k then textTab3[#textTab3+1] = "<---" ; else textTab3[#textTab3+1] = "" ; end ; end
    local text1,text2,text3 = table.concat(textTab1,"\n"),table.concat(textTab2,"\n"),table.concat(textTab3,"\n")
    self.textHUD1.text = text1
    self.textHUD2.text = text2
    if ( not HBU.InSeat()  or  self.keys.control.GetKey() > 0.5 ) and self.keys.rmb.GetKey() > 0.5 or self.Variables.varSelected ~= 0 then self.textHUD3.text = text3 else self.textHUD3.text = "" ; end

    if    self.keys.rmb.GetKey() < 0.5 and self.Variables.disabledMouseScrollTime and self.Variables.disabledMouseScrollTime + 1 <  os.clock()
    then
          HBU.EnableGadgetMouseScroll()
          self.Variables.disabledMouseScrollTime = false
          if self.Variables.prevColor then self.textHUD3.color = self.Variables.prevColor ; end
          self.Variables.varSelected = 0
          self.Variables.selected    = false
          self.Variables.Save()
    end

end


function Flashlight:OnDestroy()
    print("Flashlight:OnDestroy()")
    self:DestroyObjects()
end


function Flashlight:DestroyObjects()
  for k,v in pairs(self.objectsToDestroy) do
    if    v  and  self[v]  and not Slua.IsNull(self[v])
    then  GameObject.Destroy(self[v])
    end
  end
end

function Flashlight:SetupHUD()
    local parent  = HBU.menu.transform:Find("Foreground").gameObject
    for k,v in pairs({"textHUD1","textHUD2","textHUD3",}) do
      --if Font then  Font.font = Font.CreateDynamicFontFromOSFont({"consolas","Roboto","Arial"}, 12)  end
        self[v]        = HBU.Instantiate("Text",parent):GetComponent("Text")
        HBU.LayoutRect(self[v].gameObject,Rect( 5+((k-1)*80), 50, 200, 200 ) )
        self[v].color  = Color( math.floor( (k) % 2 ), math.floor(k/2) % 2, math.floor(k/4) % 2, 1)
        self[v].text   = ""
        if Font then  self[v].font = Font.CreateDynamicFontFromOSFont({"consolas","Roboto","Arial"}, 12)  end
    end
end

function main(go) Flashlight.gameObject = go ; return Flashlight ; end

