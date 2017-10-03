local Superman = {}

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
                ["Alt"]                 = HBU.GetKey("Alt"),
                ["Tilde"]               = { GetKey = function() if Input.GetKey(KeyCode.BackQuote) then return 1 else return 0 ; end ; end, GetKeyDown = function() return Input.GetKeyDown(KeyCode.BackQuote) ; end,  GetKeyUp = function() return Input.GetKeyDown(KeyCode.BackQuote) ; end, },
                ["F5"]                  = { GetKey = function() if Input.GetKey(KeyCode.F5)        then return 1 else return 0 ; end ; end, GetKeyDown = function() return Input.GetKeyDown(KeyCode.F5)        ; end,  GetKeyUp = function() return Input.GetKeyDown(KeyCode.F5)        ; end, },
                ["wheel"]               = { KeyUpData = { { tick = 0, }, { tick = 0, }, }, GetKey = function() return ( Input.GetAxis("Mouse ScrollWheel") * -1 ) ; end, GetKeyDown = function() local r = {false,false,false} ; local v = Input.GetAxis("Mouse ScrollWheel") ; if v ~= 0 then r[1] = true end ; if v > 0 then r[2] = true end ; if v < 0 then r[3] = true end ; return unpack(r) ; end,  GetKeyUp = function() if not self or not self.keys or not self.keys.wheel or not self.keys.wheel.KeyUpData or not self.tick then return false ; end ; local a_index,b_index = (self.tick-1)%2+1,(self.tick)%2+1 ; local d = self.keys.wheel.KeyUpData ; if self.tick ~= d[b_index].tick then d[b_index].tick = self.tick ; for k,v in pairs({self.keys.wheel.GetKeyDown()}) do d[b_index][k] = v ; end ; end ; if d[a_index].tick == self.tick - 1 then return d[a_index][1],d[a_index][2],d[a_index][3] ; else return false,false,false  ; end ; end, },
               }

  self.toggleKey         = self.keys.F5


  self.Components        = {
                              rigidbody  = "UnityEngine.Rigidbody",
                              rigidmotor = "rigidbody_character_motor",
                           }

  self.Actions           = {
                            [1] = {
                                    condition = function() return true ; end,
                                    action    = function()
                                                  if   ( self.keys.Move.GetKey() ~= 0  or self.keys.Strafe.GetKey() ~= 0  or self.keys.Jump.GetKey() ~= 0  or self.keys.Crouch.GetKey() ~= 0 )
                                                  and  ( self.Variables.curForce and self.Variables.maxForce )
                                                  then self.Variables.curForce = math.max( 2000,  math.min( self.Variables.maxForce, math.max( 2000, self.Variables.curForce+self.Variables.curForce*0.1 ) ) )
                                                  else self.Variables.curForce = 2000
                                                  end
                                                end,
                                  },
                            [2] = {
                                    condition = function() if self.keys.Run.GetKey() > 0.1 and self.keys.Control.GetKey() > 0.1 then return true; end; return false; end,
                                    action    = function() for k,v in ipairs(self.Variables) do if v[1] and v[2] and type(v[6]) ~= "nil" then v[1][v[2]] = v[6] ; end; end; end,
                                  },

                            [3] = {
                                    condition = function() if self.keys.Run.GetKey() > 0.1 and ( self.keys.Move.GetKey() ~= 0 ) then return true; end; return false; end,
                                    action    = function() self.Variables.maxForce = math.max( 2000, self.Variables.maxForce + 400*self.keys.Move.GetKey() ) ; end,
                                  },

                            [4] = {
                                    condition = function() if self.keys.Control.GetKey() > 0.1 and ( self.keys.Move.GetKey() ~= 0 ) then return true; end; return false; end,
                                    action    = function() self.Variables.drag = math.max( 0, self.Variables.drag + 1*self.keys.Move.GetKey() ) ; end
                                  },

                            [5] = {
                                    condition  =  function() return true; end,
                                    action     =  function() self.forces.negative = ( (-self.rigidbody.velocity*2000)*self.keys.Action.GetKey() ) ; self.forces.up =  ( Vector3.up * ( self.keys.Jump.GetKey() or 0 ) * self.Variables.curForce ) + ( Vector3.up * ( -self.keys.Crouch.GetKey() or 0 ) * self.Variables.curForce ) + ( Vector3.up * -1 * self.Variables.gravity * 100 ) ; self.forces.forward  =  Camera.main.transform.forward * ( self.keys.Move.GetKey()   or 0 ) * self.Variables.curForce; self.forces.strafe   =  Camera.main.transform.right   * ( self.keys.Strafe.GetKey() or 0 ) * self.Variables.curForce; self.forces.drag     =  -self.rigidbody.velocity * self.Variables.drag;  end,
                                  },

                            [6] = {
                                    condition = function() return true; end,
                                    action    = function()     local t = Vector3(0,0,0) ; if self.forces then  for k,v in pairs(self.forces) do t = t + v ; end ; if t ~= Vector3.zero then self.rigidbody:AddForce( t ) ; end end ; end,
                                  },

                            MAXFORCE_UP   = function() self.Variables.maxForce = math.max( 3000, self.Variables.maxForce + self.Variables.maxForce*0.05  ) ; end,
                            MAXFORCE_DOWN = function() self.Variables.maxForce = math.max( 3000, self.Variables.maxForce - self.Variables.maxForce*0.05 )  ; end,
                            DRAG_UP       = function() self.Variables.drag     = self.Variables.drag + 0.01 + self.Variables.drag*0.1                     ; end,
                            DRAG_DOWN     = function() self.Variables.drag     = math.max( 0, self.Variables.drag  - self.Variables.drag*0.1  )           ; end,
                            GRAVITY_UP    = function() self.Variables.gravity  = self.Variables.gravity + 0.2  end,
                            GRAVITY_DOWN  = function() self.Variables.gravity  = self.Variables.gravity - 0.2  end,
                            MOVE_PLAYER   = function(loc) if not loc then return ; end ;  HBU.TeleportPlayer(loc) ; end,
                            MOVE_X_UP     = function() HBU.TeleportPlayer( Vector3( self.Variables.x+5, self.Variables.y,    self.Variables.z    ) ) ; end,
                            MOVE_X_DOWN   = function() HBU.TeleportPlayer( Vector3( self.Variables.x-5, self.Variables.y,    self.Variables.z    ) ) ; end,
                            MOVE_Y_UP     = function() HBU.TeleportPlayer( Vector3( self.Variables.x,    self.Variables.y+5, self.Variables.z    ) ) ; end,
                            MOVE_Y_DOWN   = function() HBU.TeleportPlayer( Vector3( self.Variables.x,    self.Variables.y-5, self.Variables.z    ) ) ; end,
                            MOVE_Z_UP     = function() HBU.TeleportPlayer( Vector3( self.Variables.x,    self.Variables.y,    self.Variables.z+5 ) ) ; end,
                            MOVE_Z_DOWN   = function() HBU.TeleportPlayer( Vector3( self.Variables.x,    self.Variables.y,    self.Variables.z-5 ) ) ; end,
                          }


  self.Variables          = {
      Save                         = function() for k,v in ipairs(self.Variables) do if v[1] and v[2] and type(v[1][v[2]]) ~= "nil" then HBU.SaveValue(self.Variables.SaveName,tostring(v[2]),tostring(v[1][v[2]])) ; end ; end ; end,
      Load                         = function() if  self.Variables.Loaded  then  return end ; self.Variables.Loaded = true ; for k,v in ipairs(self.Variables) do local val,var,def = HBU.LoadValue( self.Variables.SaveName, tostring(v[2]) ), false, self.Variables[k][6] ; if val ~= "" then if v[1] and v[1][v[2]] then var = v[1][v[2]] ; end ; if type(def) == "number"  then  if val ~= "" and tonumber(val)  then v[1][v[2]] = tonumber(val) ; end ; elseif  type(var) == "boolean" then  if val == "false" then v[1][v[2]] = false ; elseif v[1] and v[2] and type(v[1][v[2]]) == "nil" and val == "" and type(def) ~= "nil"  then v[1][v[2]] = def ; elseif v[1] and v[2] then  v[1][v[2]] = true ; end ; elseif v[1] and v[2] then v[1][v[2]] = val  end ; end ; end ; end,
      SaveName                     = "SuperMan-Gadget",
      Loaded                       = false,

      index       = 1,
      varSelected = 0,
      saveFrame   = 5400,

      disabledMouseScrollTime = false,

      maxForce      = 3000,
      curForce      = 0,
      drag          = 50,
      gravity       = 0,
      gc_bytes      = 0,
      gc_bytes_last = 0,
      x             = 0,
      y             = 0,
      z             = 0,
  }

--self.Variables[#self.Variables+1] = { parent,           "varName",   "Display Name",   action_when_wheel_down,        action_when_wheel_up,     default_value, }
  self.Variables[#self.Variables+1] = { self.Variables,   "curForce",  "Current Force",  self.Actions.MAXFORCE_DOWN,    self.Actions.MAXFORCE_UP,             0, }
  self.Variables[#self.Variables+1] = { self.Variables,   "maxForce",  "Max Force",      self.Actions.MAXFORCE_DOWN,    self.Actions.MAXFORCE_UP,          3000, }
  self.Variables[#self.Variables+1] = { self.Variables,   "drag",      "Drag",           self.Actions.DRAG_DOWN,        self.Actions.DRAG_UP,                50, }
  self.Variables[#self.Variables+1] = { self.Variables,   "gravity",   "Gravity",        self.Actions.GRAVITY_DOWN,     self.Actions.GRAVITY_UP,              0, }
  self.Variables[#self.Variables+1] = { self.Variables,   "x",         "X",              self.Actions.MOVE_X_UP,        self.Actions.MOVE_X_DOWN,             0, }
  self.Variables[#self.Variables+1] = { self.Variables,   "y",         "Y",              self.Actions.MOVE_Y_UP,        self.Actions.MOVE_Y_DOWN,             0, }
  self.Variables[#self.Variables+1] = { self.Variables,   "z",         "Z",              self.Actions.MOVE_Z_UP,        self.Actions.MOVE_Z_DOWN,             0, }
  self.Variables[#self.Variables+1] = { self.Variables,   "rx",        "RX",             nil,                           nil,                                  0, }
  self.Variables[#self.Variables+1] = { self.Variables,   "ry",        "RY",             nil,                           nil,                                  0, }
  self.Variables[#self.Variables+1] = { self.Variables,   "rz",        "RZ",             nil,                           nil,                                  0, }

-- -- For debugging purposes only --
  self.Variables[#self.Variables+1] = { self.Variables,   "gc_bytes",  "GC:Bytes",       nil,                           nil,                                  0, }
  self.Variables[#self.Variables+1] = { self.Variables,   "gc_frame",  "GC:Frame",       nil,                           nil,                                  0, }

  self.forces              = { negative = Vector3.one, forward = Vector3.one, strafe = Vector3.one, up = Vector3.one, drag = Vector3.one, }

  self.noaction            = false

  self.hold                = false

  self.skipFrame           = 8

  self.tickActual          = 0

  self.tick                = 0

  self.ObjectsToDestroy    = { "textHUD1","textHUD2","textHUD3",  }

  -- self.texture_1           = HBU.LoadTexture2D()

  self.HUDKeysEnabled      = true

  self.enabled             = true

  self.disable             = false

  self.temporaryDisable    = false

  self.HUD = {
        top      = Screen.height/2,
        left     = 5,
        width    = 200,
        height   = 250,
        fontSize = 16,
        colors = { Color(1,0,0,1), Color(0,1,0,1), Color(1,1,0,1), Color(0,1,1,1), Color(0,0,1,1), },
  }

  if self.GetComponents then self:GetComponents() end

  if self.SetupHUD then self:SetupHUD() ; end

end

function Superman:Enable()   self:Awake()     end

function Superman:Disable()  self:OnDestroy() end

function Superman:EnableCheck()

    if      self.disable
    then    self:Disable() ; self.disable = false ; return false

    elseif  self.enabled
    and     (
                 -- ( HBU.MayControle    and  not HBU.MayControle()   )
                 ( HBU.InSeat         and      HBU.InSeat()        )
             or  ( HBU.InBuilder      and      HBU.InBuilder()     )
             or  ( self.GetComponents and not self:GetComponents() )
            )
    then    self:Disable() ; self.temporaryDisable = true ; return false

    elseif  self.temporaryDisable
    and     (
                  -- ( not HBU.MayControle    or      HBU.MayControle()    )
                  ( not HBU.InSeat         or      not HBU.InSeat()     )
             and  ( not HBU.InBuilder      or      not HBU.InBuilder()  )
             and  ( not self.GetComponents or      self:GetComponents() )
            )
    then
            self:Enable() ; return false

    elseif  self.toggleKey.GetKeyDown()
    then    if self.enabled then self:Disable() else self:Enable() ; return false ; end
    end

    return  self.enabled
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


function Superman:ClearComponents()
    if not self.Components then return true ; end
    for k,v in pairs(self.Components)
    do
        if self[k]  then  self[k] = false end
    end
end


function Superman:ProcessActions()
  if  not self.Actions then return ; end
  if self.noaction then self.noaction = false ; end
  for k,v in ipairs(self.Actions) do
      if not self.noaction and v.condition and v.condition() and v.action then v.action() end
  end
  return not self.noaction
end


function Superman:GetNextKey(toggle)
    if not KeyCode then return ; end
    if not toggle and self.GetNextKeyActive then self.GetNextKeyActive = false ; return ; end
    if not toggle then return ; end
    if not self.GetNextKeyActive then self.GetNextKeyActive = true ; self.GetNextKey_ID = -1 ; self.GetNextKey_Key = "" ; end
    for k,v in pairs(KeyCode) do if Input.GetKeyDown(v) then self.GetNextKey_Key = k ; self.GetNextKey_ID = v ; print("GetNextKey_Key =",k,"GetNextKey_ID =",v) ; if self.GetNextKeyActive then self.GetNextKeyActive = false ; end ; end ; end
end


function Superman:ProcessHUD()

    if      self.HUDKeysEnabled
    and     ( not HBU.InSeat()  or  self.keys.Control.GetKey() > 0.5 )
    and     self.keys.UseGadgetSecondary.GetKey() > 0.5  or  self.Variables.varSelected ~= 0
    then
            if not self.Variables.disabledMouseScrollTime then HBU.DisableGadgetMouseScroll() ; print("HBU.DisableGadgetMouseScroll()") ; end

            self.Variables.disabledMouseScrollTime = os.clock()

            if    self.keys.UseGadget.GetKeyDown()
            or    ( self.Variables.varSelected ~= 0 and self.keys.UseGadgetSecondary.GetKeyDown() )
            then
                  if      self.Variables.varSelected == 0
                  and     ( self.Variables[self.Variables.index][4] or self.Variables[self.Variables.index][5] )
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
            HBU.EnableGadgetMouseScroll() ; print("HBU.EnableGadgetMouseScroll()")
    end

    local   camPos = Camera.main.transform.position
    self.Variables.x,self.Variables.y,self.Variables.z    =  string.format( "%.2f", camPos.x ), string.format( "%.2f", camPos.y ), string.format( "%.2f", camPos.z )
    local   camRot = Camera.main.transform.rotation
    self.Variables.rx,self.Variables.ry,self.Variables.rz =  string.format( "%.4f", camRot.x ), string.format( "%.4f", camRot.y ), string.format( "%.4f", camRot.z )

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
    if not self.HUD then return ; end
    if self.textHUD1 and not Slua.IsNull(self.textHUD1) then return ; end
    self.HUD.parent = HBU.menu.transform:Find("Foreground").gameObject
    for k,v in pairs({"textHUD1","textHUD2","textHUD3",}) do
        self[v]        = HBU.Instantiate("Text",self.HUD.parent):GetComponent("Text")
        self[v].text   = ""
        HBU.LayoutRect(self[v].gameObject,Rect( self.HUD.left+((k-1)*100), self.HUD.top, self.HUD.width, self.HUD.height ) )
        if    self.HUD.colors and #self.HUD.colors > 0
        then  self[v].color = self.HUD.colors[(k-1)%#self.HUD.colors+1]
        else  self[v].color  = Color( math.floor( (k) % 2 ), math.floor(k/2) % 2, math.floor(k/4) % 2, 1)
        end
        self[v].fontSize = self.HUD.fontSize
        if Font then  self[v].font = Font.CreateDynamicFontFromOSFont({"consolas","Roboto","Arial"}, self.HUD.fontSize )  end
    end
end


function Superman:DestroyObjects()
  for k,v in pairs(self.ObjectsToDestroy) do
    if    v  and  self[v]  and not Slua.IsNull( self[v] )
    then  GameObject.Destroy(self[v]) ; self[v] = false
    end
  end
  self:ClearComponents()
end


function Superman:OnDestroy()
  Debug.Log("Superman:OnDestroy()")
  if self.rigidmotor then if not Slua.IsNull(self.rigidmotor) then self.rigidmotor.enabled = true ; end ; self.rigidmotor = false ; end
  self:DestroyObjects()
  HBU.EnableGadgetMouseScroll() ; print("HBU.EnableGadgetMouseScroll()")
  self.enabled = false
end


function Superman:Update()
  self.tickActual = self.tickActual + 1
  if self.skipFrame and self.skipFrame ~= 0 and self.tickActual % self.skipFrame == 0 then return end
  if not self:EnableCheck() then return ; end
  self:SetupHUD()
  self.tick = self.tick + 1
  self.Variables.gc_bytes_last = self.Variables.gc_bytes
  self.Variables.gc_bytes      = gc.count()*1024
  self.Variables.gc_frame      = self.Variables.gc_bytes - self.Variables.gc_bytes_last
  if not self.Variables.Loaded then self.Variables.Load() ; end -- Only actually loads variables once.  Returns quickly if already loaded.
  if self.Variables and self.Variables.saveFrame and self.tick % self.Variables.saveFrame == 0 then self.Variables.Save() end
  if not self:ProcessActions() then return ; end
  if self.rigidmotor and not Slua.IsNull(self.rigidmotor) then self.rigidmotor.enabled = false; end
  self:ProcessHUD()
  return
end

function main(gameObject)  Superman.gameObject = gameObject  return Superman end
