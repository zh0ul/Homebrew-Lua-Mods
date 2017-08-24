local Superman = {}
function main(gameObject)  Superman.gameObject = gameObject  return Superman end

function Superman:Awake()

  Debug.Log("Superman:Awake()")

  self.keys = { 
                ["UseGadget"]           = HBU.GetKey("UseGadget"),
                ["UseGadgetSecondary"]  = HBU.GetKey("UseGadgetSecondary"),
                ["Jump"]                = HBU.GetKey("Jump"),
                ["Crouch"]              = HBU.GetKey("Crouch"),
                ["Move"]                = HBU.GetKey("Move"),
                ["Strafe"]              = HBU.GetKey("Strafe"),
                ["Run"]                 = HBU.GetKey("Run"),
                ["Control"]             = HBU.GetKey("Control"),
                ["Action"]              = HBU.GetKey("Action"),
              --["Alt"]                 = HBU.GetKey(""),
               }

  self.Components        = {
                              rigidbody  = "UnityEngine.Rigidbody",
                              rigidmotor = "rigidbody_character_motor",
                           }

  self.Actions           = {
                            [1] = {
                                    condition  =  function()
                                                              if    ( HBU.MayControle    and  not HBU.MayControle()   )
                                                              or    ( HBU.InSeat         and      HBU.InSeat()        )
                                                              or    ( HBU.InBuilder      and      HBU.InBuilder()     )
                                                              or    ( self.GetComponents and not self:GetComponents() )
                                                              then  return true
                                                              else  return false
                                                              end
                                                  end,
                                    action     =  function()  self.noaction = true ; if not self.hold then self.hold = true ; self:DestroyObjects() ;  end ; end,
                                  },

                            [2] = {
                                    condition = function() return true ; end,
                                    action    = function()
                                                  if   ( self.keys.Move.GetKey() ~= 0  or self.keys.Strafe.GetKey() ~= 0  or self.keys.Jump.GetKey() ~= 0  or self.keys.Crouch.GetKey() ~= 0 )
                                                  and  ( self.Variables.curForce and self.Variables.maxForce )
                                                  then self.Variables.curForce = math.max( 2000,  math.min( self.Variables.maxForce, math.max( 2000, self.Variables.curForce+self.Variables.curForce*0.1 ) ) )
                                                  else self.Variables.curForce = 2000
                                                  end
                                                end,
                                  },
                            [3] = {
                                    condition = function() if self.keys.Run.GetKey() > 0.1 and self.keys.Control.GetKey() > 0.1 then return true; end; return false; end,
                                    action    = function() for k,v in ipairs(self.Variables) do if v[1] and v[2] and type(v[6]) ~= "nil" then v[1][v[2]] = v[6] ; end; end; end,
                                  },

                            [4] = {
                                    condition = function() if self.keys.Run.GetKey() > 0.1 and ( self.keys.Move.GetKey() ~= 0 ) then return true; end; return false; end,
                                    action    = function() self.Variables.maxForce = math.max( 2000, self.Variables.maxForce + 400*self.keys.Move.GetKey() ) ; end,
                                  },

                            [5] = {
                                    condition = function() if self.keys.Control.GetKey() > 0.1 and ( self.keys.Move.GetKey() ~= 0 ) then return true; end; return false; end,
                                    action    = function() self.Variables.drag = math.max( 0, self.Variables.drag + 1*self.keys.Move.GetKey() ) ; end
                                  },

                            [6] = {
                                    condition = function() if self.keys.Action.GetKey() ~= 0  then  return true ; end; return false; end,
                                    action    = function()  self.rigidbody:AddForce( -self.rigidbody.velocity*2000 )  end,
                                  },

                            [7] = {
                                    condition  =  function() return true; end,
                                    action     =  function() self.forces.up =  ( Vector3.up * ( self.keys.Jump.GetKey() or 0 ) * self.Variables.curForce ) + ( Vector3.up * ( -self.keys.Crouch.GetKey() or 0 ) * self.Variables.curForce ) + ( Vector3.up * -1 * self.Variables.gravity * 100 ) ; self.forces.forward  =  Camera.main.transform.forward * ( self.keys.Move.GetKey()   or 0 ) * self.Variables.curForce; self.forces.strafe   =  Camera.main.transform.right   * ( self.keys.Strafe.GetKey() or 0 ) * self.Variables.curForce; self.forces.drag     =  -self.rigidbody.velocity * self.Variables.drag; local t = Vector3(0,0,0) ; for k,v in pairs(self.forces) do t = t + v ; end ; if t ~= Vector3.zero then self.rigidbody:AddForce( t )  end end,
                                  },

                            -- [8] = {
                            --         condition = function() if self.Variables and self.Variables.gravity and self.Variables.gravity ~= 0 then return true ; end ; end,
                            --         action    = function() self.rigidbody:AddForce( Vector3.up * -1 * self.Variables.gravity * 100 ) ; end,
                            --       },
                            MAXFORCE_UP   = function() self.Variables.maxForce = math.max( 3000, self.Variables.maxForce + self.Variables.maxForce*0.1  ) ; end,
                            MAXFORCE_DOWN = function() self.Variables.maxForce = math.max( 3000, self.Variables.maxForce - self.Variables.maxForce*0.1 )  ; end,
                            DRAG_UP       = function() self.Variables.drag     = self.Variables.drag + 0.01 + self.Variables.drag*0.1                     ; end,
                            DRAG_DOWN     = function() self.Variables.drag     = math.max( 0, self.Variables.drag  - self.Variables.drag*0.1  )           ; end,
                            GRAVITY_UP    = function() self.Variables.gravity  = self.Variables.gravity + 0.2  end,
                            GRAVITY_DOWN  = function() self.Variables.gravity  = self.Variables.gravity - 0.2  end,
                          }


  self.Variables          = {
      Save                         = function() print ("Superman.Variables.Save()") ; for k,v in ipairs(self.Variables) do if v[1] and v[2] and type(v[1][v[2]]) ~= "nil" then HBU.SaveValue(self.Variables.SaveName,tostring(v[2]),tostring(v[1][v[2]])) ; end ; end ; end,
      Load                         = function() if  self.Variables.Loaded  then  return end ; self.Variables.Loaded = true ; for k,v in ipairs(self.Variables) do local val,var,def = HBU.LoadValue( self.Variables.SaveName, tostring(v[2]) ), false, self.Variables[k][6] ; if val ~= "" then if v[1] and v[1][v[2]] then var = v[1][v[2]] ; end ; if type(def) == "number"  then  if val ~= "" and tonumber(val)  then v[1][v[2]] = tonumber(val) ; end ; elseif  type(var) == "boolean" then  if val == "false" then v[1][v[2]] = false ; elseif v[1] and v[2] and type(v[1][v[2]]) == "nil" and val == "" and type(def) ~= "nil"  then v[1][v[2]] = def ; elseif v[1] and v[2] then  v[1][v[2]] = true ; end ; elseif v[1] and v[2] then v[1][v[2]] = val  end ; end ; end ; end,
      SaveName                     = "SuperMan-Gadget",
      Loaded                       = false,

      index       = 1,
      varSelected = 0,
      saveFrame   = 5400,

      disabledMouseScrollTime = false,

      maxForce    = 3000,
      curForce    = 0,
      drag        = 50,
      gravity     = 0,
      gc_bytes    = 0,
  }

--self.Variables[#self.Variables+1] = { parent,           "varName",   "Display Name",   action_when_wheel_down,        action_when_wheel_up,     default_value, }
  self.Variables[#self.Variables+1] = { self.Variables,   "curForce",  "Current Force",  self.Actions.MAXFORCE_DOWN,    self.Actions.MAXFORCE_UP,             0, }
  self.Variables[#self.Variables+1] = { self.Variables,   "maxForce",  "Max Force",      self.Actions.MAXFORCE_DOWN,    self.Actions.MAXFORCE_UP,          3000, }
  self.Variables[#self.Variables+1] = { self.Variables,   "drag",      "Drag",           self.Actions.DRAG_DOWN,        self.Actions.DRAG_UP,                50, }
  self.Variables[#self.Variables+1] = { self.Variables,   "gravity",   "Gravity",        self.Actions.GRAVITY_DOWN,     self.Actions.GRAVITY_UP,              0, }
  self.Variables[#self.Variables+1] = { self.Variables,   "gc_bytes",  "GC:Bytes",       nil,                           nil,                                  0, }
  self.Variables[#self.Variables+1] = { self.Variables,   "gc_frame",  "GC:Frame",       nil,                           nil,                                  0, }

  self.forces             = { forward = 0, strafe = 0, up = 0, drag = 0, }

  self.noaction           = false

  self.hold               = false

  self.tick               = 0

  self.ObjectsToDestroy    = { "textHUD1","textHUD2","textHUD3",  }

  self.ObjectsToNotDestroy = { rigidmotor = true, rigidbody = true, }

  self.HUDKeysEnabled      = true

  if self.SetupHUD then self:SetupHUD() ; end

end


function Superman:GetComponents()
    if not self.Components then return true ; end
    local ret = true
    for k,v in pairs(self.Components) do
        if not self[k] or Slua.IsNull(self[k])
        then
            local comp = Camera.main:GetComponentInParent(v)
            if not Slua.IsNull(comp) then self[k] = comp else ret = false end
        end
    end
    return ret
end


function Superman:ProcessActions()
  if  not self.Actions then return ; end
  if self.noaction then self.noaction = false ; end
  for k,v in ipairs(self.Actions) do
      if not self.noaction and v.condition and v.condition() and v.action then v.action() end
  end
end

function Superman:ProcessHUD()

    if      self.HUDKeysEnabled
    and     ( not HBU.InSeat()  or  self.keys.Control.GetKey() > 0.5 )
    and     self.keys.UseGadgetSecondary.GetKey() > 0.5  or  self.Variables.varSelected ~= 0
    then
            if not self.Variables.disabledMouseScrollTime then HBU.DisableGadgetMouseScroll() ; end

            self.Variables.disabledMouseScrollTime = os.clock()

            if    self.keys.UseGadget.GetKeyDown()
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

    elseif  self.Variables.disabledMouseScrollTime and self.Variables.disabledMouseScrollTime + 1 < os.clock()
    then
            self.Variables.disabledMouseScrollTime = false
            HBU.EnableGadgetMouseScroll()
    end

    if self.textHUD1 and self.textHUD2 and self.textHUD3
    then
        local textTab1,textTab2,textTab3 = {},{},{}
        for k,v in ipairs(self.Variables) do  if v[3] then textTab1[#textTab1+1] = v[3] end ; if v[1] and v[2] and type(v[1][v[2]]) ~= "nil" then if type(v[1][v[2]]) == "number" then textTab2[#textTab2+1] = string.format( "%.2f", v[1][v[2]] )  ; else textTab2[#textTab2+1] = tostring(v[1][v[2]]) ; end ; else textTab2[#textTab2+1] = ""   end ; if self.Variables.index == k then textTab3[#textTab3+1] = "<---" ; else textTab3[#textTab3+1] = "" ; end ; end
        self.textHUD1.text = table.concat(textTab1,"\n")
        self.textHUD2.text = table.concat(textTab2,"\n")
        if ( not HBU.InSeat()  or  self.keys.Control.GetKey() > 0.5 ) and ( self.keys.UseGadgetSecondary.GetKey() > 0.5 or self.Variables.varSelected ~= 0 ) then self.textHUD3.text = table.concat(textTab3,"\n") else self.textHUD3.text = "" ; end
    end
end

function Superman:SetupHUD()
    if self.textHUD1 and not Slua.IsNull(self.textHUD1) then return ; end
    local parent  = HBU.menu.transform:Find("Foreground").gameObject
    for k,v in pairs({"textHUD1","textHUD2","textHUD3",}) do
        self[v]        = HBU.Instantiate("Text",parent):GetComponent("Text")
        HBU.LayoutRect(self[v].gameObject,Rect( 5+((k-1)*100), 50, 200, 200 ) )
        self[v].color  = Color( math.floor( (k) % 2 ), math.floor(k/2) % 2, math.floor(k/4) % 2, 1)
        self[v].text   = ""
        if Font then  self[v].font = Font.CreateDynamicFontFromOSFont({"consolas","Roboto","Arial"}, 14)  end
    end
end

function Superman:DestroyObjects()
  for k,v in pairs(self.ObjectsToDestroy) do
    if    v  and  self[v]  and not Slua.IsNull( self[v] )
    then  GameObject.Destroy(self[v]) ; self[v] = false
    end
  end
end

function Superman:OnDestroy()
  Debug.Log("Superman:OnDestroy()")
  self:DestroyObjects()
  if self.rigidmotor then if not Slua.IsNull(self.rigidmotor) then self.rigidmotor.enabled = true ; end ; self.rigidmotor = nil ; end
end

function Superman:Update()
  self.tick = self.tick + 1
  self.Variables.gc_bytes_last = self.Variables.gc_bytes
  self.Variables.gc_bytes      = gc.bytes()
  self.Variables.gc_frame      = self.Variables.gc_bytes - self.Variables.gc_bytes_last
  if self.tick % 2 == 0 then return ; end

  if not self.Variables.Loaded then self.Variables.Load() ; end -- Only actually loads variables once.  Returns quickly if already loaded.
  if self.Variables and self.Variables.saveFrame and self.tick % self.Variables.saveFrame == 0 then self.Variables.Save() end
  self:ProcessActions()
  if self.noaction then if self.rigidmotor then self.rigidmotor.enabled = true end; return ; end
  if not self.textHUD1 then self:SetupHUD() ; end
  if self.rigidmotor then self.rigidmotor.enabled = false; end
  self:ProcessHUD()
  return
end

