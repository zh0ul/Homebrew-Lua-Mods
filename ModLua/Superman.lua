local Superman = {}

function Superman:Awake()

  Debug.Log("Superman:Awake()")

  self.keys = { 
          ["lmb"]     = HBU.GetKey("UseGadget"),
          ["rmb"]     = HBU.GetKey("UseGadgetSecondary"),
          ["Jump"]    = HBU.GetKey("Jump"),
          ["Crouch"]  = HBU.GetKey("Crouch"),
          ["Move"]    = HBU.GetKey("Move"),
          ["Strafe"]  = HBU.GetKey("Strafe"),
          ["Run"]     = HBU.GetKey("Run"),
          ["Control"] = HBU.GetKey("Control"),
          ["Action"]  = HBU.GetKey("Action"),
          ["Alt"]     = HBU.GetKey("Alt"),
          ["Tilde"]   = { GetKey = function() if Input.GetKey(KeyCode.BackQuote) then return 1 else return 0 ; end ; end, GetKeyDown = function() return Input.GetKeyDown(KeyCode.BackQuote) ; end,  GetKeyUp = function() return Input.GetKeyDown(KeyCode.BackQuote) ; end, },
          ["F5"]      = { GetKey = function() if Input.GetKey(KeyCode.F5)        then return 1 else return 0 ; end ; end, GetKeyDown = function() return Input.GetKeyDown(KeyCode.F5)        ; end,  GetKeyUp = function() return Input.GetKeyDown(KeyCode.F5)        ; end, },
          ["F6"]      = { GetKey = function() if Input.GetKey(KeyCode.F6)        then return 1 else return 0 ; end ; end, GetKeyDown = function() return Input.GetKeyDown(KeyCode.F6)        ; end,  GetKeyUp = function() return Input.GetKeyDown(KeyCode.F6)        ; end, },
          ["wheel"]   = { KeyUpData = { { tick = 0, }, { tick = 0, }, }, GetKey = function() return ( Input.GetAxis("Mouse ScrollWheel") * -1 ) ; end, GetKeyDown = function() local r = {false,false,false} ; local v = Input.GetAxis("Mouse ScrollWheel") ; if v ~= 0 then r[1] = true end ; if v > 0 then r[2] = true end ; if v < 0 then r[3] = true end ; return unpack(r) ; end,  GetKeyUp = function() if not self or not self.keys or not self.keys.wheel or not self.keys.wheel.KeyUpData or not self.tick then return false ; end ; local a_index,b_index = (self.tick-1)%2+1,(self.tick)%2+1 ; local d = self.keys.wheel.KeyUpData ; if self.tick ~= d[b_index].tick then d[b_index].tick = self.tick ; for k,v in pairs({self.keys.wheel.GetKeyDown()}) do d[b_index][k] = v ; end ; end ; if d[a_index].tick == self.tick - 1 then return d[a_index][1],d[a_index][2],d[a_index][3] ; else return false,false,false  ; end ; end, },
               }

  self.toggleKey         = self.keys.F5

  -- self.print = function(...) local sTab = {} ; for k,v in pairs({...}) do sTab[k] = tostring(v) ; end ; GameObject.FindObjectOfType("HBChat"):AddMessage("[Superman]",table.concat(sTab,"  ")) end

  self.Components        = {
                              rigidbody  = "UnityEngine.Rigidbody",
                              rigidmotor = "rigidbody_character_motor",
                           }

  self.Actions           = {
                            [1] = {
                                    action = 
                                      function()

                                          local control,alt,run,move,strafe,jump,crouch = self.keys.Control.GetKey(), self.keys.Alt.GetKey(), self.keys.Run.GetKey(), self.keys.Move.GetKey(),self.keys.Strafe.GetKey(),self.keys.Jump.GetKey(),self.keys.Crouch.GetKey() 

                                          if   ( move ~= 0  or strafe ~= 0  or jump ~= 0  or crouch ~= 0 )
                                          and  ( self.Variables.curForce and self.Variables.maxForce )
                                          then self.Variables.curForce = math.floor( math.min( self.Variables.maxForce, self.Variables.curForce+(self.Variables.maxForce-self.Variables.curForce)*0.004/0.0158*Time.deltaTime ) )
                                          else self.Variables.curForce = math.floor( math.max( 1000, self.Variables.curForce-(self.Variables.maxForce-self.Variables.curForce)*0.006/0.0158*Time.deltaTime ) )
                                          end

                                          if  ( run > 0.1 and self.keys.Control.GetKeyDown() ) or ( self.keys.Run.GetKeyDown() and control > 0.1 )  then
                                              for k,v in ipairs(self.Variables) do if v and v[1] and v[2] and v[6] and type(v[7]) ~= "nil" then v[1][v[2]] = v[7] ; end; end; 
                                              self.Variables.saveOnOrAfter = os.clock() + 2
                                          end

                                          if  run > 0.1 and ( move ~= 0 ) then
                                              self.Variables.maxForce = math.max( 1000, self.Variables.maxForce + 400*move )
                                              self.Variables.saveOnOrAfter = os.clock() + 2 
                                          end

                                          if  control > 0.1 and ( move ~= 0 ) then
                                              self.Variables.drag = math.max( 0, self.Variables.drag + 1*move)
                                              self.Variables.saveOnOrAfter = os.clock() + 2
                                          end

                                          if  alt > 0.1 and ( move ~= 0 ) then
                                              self.Variables.gravity = math.max( 0, self.Variables.gravity + 1*move )
                                              self.Variables.saveOnOrAfter = os.clock() + 2
                                          end

                                      end
                                  },


                            [2] = {
                                  --action    =  function() self.forces.negative = ( (-self.rigidbody.velocity*2000)*self.keys.Action.GetKey() ) ; self.forces.up =  ( Vector3.up * ( self.keys.Jump.GetKey() or 0 ) * self.Variables.curForce ) + ( Vector3.up * ( -self.keys.Crouch.GetKey() or 0 ) * self.Variables.curForce ) + ( Vector3.up * -1 * self.Variables.gravity * 100 ) ; self.forces.forward  =  Camera.main.transform.forward * ( self.keys.Move.GetKey()   or 0 ) * self.Variables.curForce; self.forces.strafe   =  Camera.main.transform.right   * ( self.keys.Strafe.GetKey() or 0 ) * self.Variables.curForce; self.forces.drag     =  -self.rigidbody.velocity * self.Variables.drag;  end,
                                    action    =  function() self.forces.all      = ( (-self.rigidbody.velocity*2000)*self.keys.Action.GetKey() ) + ( Vector3.up * ( self.keys.Jump.GetKey() or 0 ) * self.Variables.curForce ) + ( Vector3.up * ( -self.keys.Crouch.GetKey() or 0 ) * self.Variables.curForce ) + ( Vector3.up * -1 * self.Variables.gravity * 100 )  +  Camera.main.transform.forward * ( self.keys.Move.GetKey()   or 0 ) * self.Variables.curForce + Camera.main.transform.right * ( self.keys.Strafe.GetKey() or 0 ) * self.Variables.curForce + ((self.rigidbody.velocity*-1)*self.Variables.drag) ;  end,
                                  },

                            [3] = {
                                    -- condition  = function() return true; end,
                                    action    = function()     local t = Vector3(0,0,0) ; if self.forces then  for k,v in pairs(self.forces) do t = t + v ; end ; if t.x < -10 or t.x > 10 or t.y < -10 or t.y > 10 or t.z < -10 or t.z > 10  then self.rigidbody:AddForce( t ) ; end end ; end,
                                  },

                            MAXFORCE_UP   = function() self.Variables.maxForce = math.max( 3000, self.Variables.maxForce + self.Variables.maxForce*0.05  ) ; end,
                            MAXFORCE_DOWN = function() self.Variables.maxForce = math.max( 3000, self.Variables.maxForce - self.Variables.maxForce*0.05 )  ; end,
                            DRAG_UP       = function() self.Variables.drag     = self.Variables.drag + 0.01 + self.Variables.drag*0.1                      ; end,
                            DRAG_DOWN     = function() self.Variables.drag     = math.max( 0, self.Variables.drag  - self.Variables.drag*0.1  )            ; end,
                            GRAVITY_UP    = function() self.Variables.gravity  = self.Variables.gravity + 0.2                                              ; end,
                            GRAVITY_DOWN  = function() self.Variables.gravity  = self.Variables.gravity - 0.2                                              ; end,
                            MOVE_PLAYER   = function(loc) if not loc then return ; end ;  HBU.TeleportPlayer(loc)                                          ; end,
                            MOVE_X_UP     = function() HBU.TeleportPlayer( Vector3( self.Variables.x+5, self.Variables.y,    self.Variables.z    ) )       ; end,
                            MOVE_X_DOWN   = function() HBU.TeleportPlayer( Vector3( self.Variables.x-5, self.Variables.y,    self.Variables.z    ) )       ; end,
                            MOVE_Y_UP     = function() HBU.TeleportPlayer( Vector3( self.Variables.x,    self.Variables.y+5, self.Variables.z    ) )       ; end,
                            MOVE_Y_DOWN   = function() HBU.TeleportPlayer( Vector3( self.Variables.x,    self.Variables.y-5, self.Variables.z    ) )       ; end,
                            MOVE_Z_UP     = function() HBU.TeleportPlayer( Vector3( self.Variables.x,    self.Variables.y,    self.Variables.z+5 ) )       ; end,
                            MOVE_Z_DOWN   = function() HBU.TeleportPlayer( Vector3( self.Variables.x,    self.Variables.y,    self.Variables.z-5 ) )       ; end,
                          }


  self.Variables          = {
      Save                         = function() for k,v in ipairs(self.Variables) do if v[1] and v[2] and v[6] and type(v[1][v[2]]) ~= "nil" then HBU.SaveValue(self.Variables.SaveName,tostring(v[2]),tostring(v[1][v[2]])) ; end ; end ; end,
      Load                         = function() if  self.Variables.Loaded  then  return end ; self.Variables.Loaded = true ; for k,v in ipairs(self.Variables) do  if v and v[6] then  local val,var,def = HBU.LoadValue( self.Variables.SaveName, tostring(v[2]) ), false, v[7] ; if val ~= "" then if v[1] and v[1][v[2]] then var = v[1][v[2]] ; end ; if type(def) == "number"  then  if val ~= "" and tonumber(val)  then v[1][v[2]] = tonumber(val) ; end ; elseif  type(var) == "boolean" then  if val == "false" then v[1][v[2]] = false ; elseif v[1] and v[2] and type(v[1][v[2]]) == "nil" and val == "" and type(def) ~= "nil"  then v[1][v[2]] = def ; elseif v[1] and v[2] then  v[1][v[2]] = true ; end ; elseif v[1] and v[2] then v[1][v[2]] = val  end ; end ; end ; end ; end,
      SaveName                     = "SuperMan-Gadget",
      Loaded                       = false,
      saveOnOrAfter                = false,

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

--self.Variables[#self.Variables+1] = { parent,           "varName",   "Display Name",   action_when_wheel_down,        action_when_wheel_up,      save_value,  default_value, }
  self.Variables[#self.Variables+1] = { self.Variables,   "curForce",  "Force",          self.Actions.MAXFORCE_DOWN,    self.Actions.MAXFORCE_UP,  false,                   0, }
  self.Variables[#self.Variables+1] = { self.Variables,   "maxForce",  "Max Force",      self.Actions.MAXFORCE_DOWN,    self.Actions.MAXFORCE_UP,  true,                 3000, }
  self.Variables[#self.Variables+1] = { self.Variables,   "drag",      "Drag",           self.Actions.DRAG_DOWN,        self.Actions.DRAG_UP,      true,                   50, }
  self.Variables[#self.Variables+1] = { self.Variables,   "gravity",   "Gravity",        self.Actions.GRAVITY_DOWN,     self.Actions.GRAVITY_UP,   true,                    0, }
  self.Variables[#self.Variables+1] = { self.Variables,   "x",         "X",              self.Actions.MOVE_X_UP,        self.Actions.MOVE_X_DOWN,  false,                   0, }
  self.Variables[#self.Variables+1] = { self.Variables,   "y",         "Y",              self.Actions.MOVE_Y_UP,        self.Actions.MOVE_Y_DOWN,  false,                   0, }
  self.Variables[#self.Variables+1] = { self.Variables,   "z",         "Z",              self.Actions.MOVE_Z_UP,        self.Actions.MOVE_Z_DOWN,  false,                   0, }
  self.Variables[#self.Variables+1] = { self.Variables,   "rx",        "RX",             nil,                           nil,                       false,                   0, }
  self.Variables[#self.Variables+1] = { self.Variables,   "ry",        "RY",             nil,                           nil,                       false,                   0, }
  self.Variables[#self.Variables+1] = { self.Variables,   "rz",        "RZ",             nil,                           nil,                       false,                   0, }

-- -- For debugging purposes only --
  self.Variables[#self.Variables+1] = { self.Variables,   "gc_bytes",  "GC:Bytes",       nil,                           nil,                       false,                   0, }
  self.Variables[#self.Variables+1] = { self.Variables,   "gc_frame",  "GC:Frame",       nil,                           nil,                       false,                   0, }
  self.Variables[#self.Variables+1] = { Time,             "deltaTime", "DeltaT",         nil,                           nil,                       false,                   0, }

--self.forces              = { negative = Vector3.zero, forward = Vector3.zero, strafe = Vector3.zero, up = Vector3.zero, drag = Vector3.zero, }
  self.forces              = { all = Vector3.zero, }
  self.noaction            = false
  self.hold                = false
  self.tickActual          = 0
  self.tick                = 0
  self.ObjectsToDestroy    = { "textHUD1","textHUD2", "Font1", } -- "textHUD3",  }
  self.HUDKeysEnabled      = true
  self.enabled             = true
  self.disable             = false
  self.temporaryDisable    = false

  self.HUD = {
        top      = Screen.height/3,
        left     = 5,
        width    = 200,
        height   = 250,
        fontSize = 14,
        colors   = { Color(1,0,0,1), Color(0,1,0,1), Color(1,1,0,1), Color(0,1,1,1), Color(0,0,1,1), },
  }


  function self:SetupCpuTime()
      self.cpu              = { new = true, tick = 0, startTime = os.clock(), currentTime = os.clock(), totalTime = 0, updateStart = os.clock(), updateEnd = os.clock(), updateTotal = 0, percent = "0%", timeDelta = Time.deltaTime, fps = 1/Time.deltaTime } 
      if not CPU then CPU = {} ; end
      CPU.Superman = self.cpu
  end

  function self:SetCpuTime(start)
      if not self then return end
      if not self.cpu then  if self.SetupCpuTime then self:SetupCpuTime() ; end ; return ; end
      if self.cpu.new then self.cpu.new = false ; return ; end
      if start then self.cpu.tick = self.cpu.tick + 1 ; self.cpu.currentTime = os.clock() ; self.cpu.updateStart = self.cpu.currentTime ; return ; end
      self.cpu.updateTotal = self.cpu.updateTotal + os.clock() - self.cpu.updateStart
      self.cpu.updateFrame = self.cpu.updateTotal / self.cpu.tick
      self.cpu.deltaTime   = Time.deltaTime
      self.cpu.totalTime   = self.cpu.currentTime - self.cpu.startTime
      self.cpu.fps         = 1/Time.deltaTime
      if  self.cpu.totalTime > 0
      then
          self.cpu.percent = string.format( "%.4f%%",(100/self.cpu.totalTime)*self.cpu.updateTotal )
      end
      return
  end


  if self.GetComponents then self:GetComponents(true) ; end
  if self.SetupHUD      then self:SetupHUD()          ; end
  self.textHUD1Text = ""

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
          -- and  ( not self.GetComponents or      self:GetComponents() )
            )
    then
            self:Enable() ; return false

    elseif  self.toggleKey.GetKeyDown()
    then    if self.enabled then self:Disable() else self:Enable() ; return false ; end
    end

    return  self.enabled
end


function Superman:GetComponents(override)
    if not self.Components then return true ; end
    local ret = true
    for k,v in pairs(self.Components) do
        if not self[k] or Slua.IsNull(self[k]) or override
        then
            local comp = Camera.main:GetComponentInParent(v)
            if not Slua.IsNull(comp) then self[k] = comp else ret = false end
        end
    end
    return ret
end


function Superman:ClearComponents()
    if not self.Components then return true ; end
    for   k,v  in  pairs(self.Components)
    do    if self[k]  then  self[k] = false ; end
    end
end


function Superman:ProcessActions()
  if  not self.Actions then return ; end
  if self.noaction then self.noaction = false ; end
  for  k,v  in ipairs(self.Actions)
  do   if not self.noaction and ( not v.condition or v.condition() ) and v.action then v.action() end
  end
  return not self.noaction
end


function Superman:GetNextKey(toggle)
    if not self or ( not toggle and self.GetNextKeyActive ) then self.GetNextKeyActive = false ; return ; end
    if not toggle then return ; end
    if not KeyCode2 then KeyCode2 = {} ; for k,v in pairs(KeyCode) do KeyCode2[v] = k ; KeyCode2[k] = v ; end ; end
    if not self.print then   self.print = function(...) local sTab = {} ; for k,v in pairs({...}) do sTab[k] = tostring(v) ; end ; GameObject.FindObjectOfType("HBChat"):AddMessage("[Superman]",table.concat(sTab,"  ")) ; print(table.concat(sTab,"  ")) ; end ; end
    if not self.GetNextKeyActive then self.GetNextKeyActive = true ; self.GetNextKey_ID = -1 ; self.GetNextKey_Key = "" ; self.print("Getting next key pressed...") return ; end
    local  mouse_scroll = Input.GetAxis("Mouse ScrollWheel")
    local  mouse_vert   = Input.GetAxis("Vertical")
    local  mouse_hori   = Input.GetAxis("Horizontal")
    local  mouse_x      = Input.GetAxis("Mouse X")
    local  mouse_y      = Input.GetAxis("Mouse Y")
    for k,v in pairs(KeyCode) do
      local name = "Unknown Key:"
      if    KeyCode2[v] then name = KeyCode2[v] end
      if    Input.GetKeyDown(v)
      then
            self.GetNextKey_Key = name
            self.GetNextKey_ID  = v
            self.print("GetNextKey_Key =",name,"GetNextKey_ID =",v)
            if self.GetNextKeyActive then self.GetNextKeyActive = false ; end
      end
    end

end


function Superman:ProcessHUD()

    -- if      self.HUDKeysEnabled
    -- and     not HBU.InSeat()
    -- and     self.keys.rmb.GetKey() > 0.5  or  self.Variables.varSelected ~= 0
    -- then
    --         if not self.Variables.disabledMouseScrollTime then HBU.DisableGadgetMouseScroll() ; print("HBU.DisableGadgetMouseScroll()") ; end

    --         self.Variables.disabledMouseScrollTime = os.clock()

    --         if    self.keys.lmb.GetKeyDown()
    --         or    ( self.Variables.varSelected ~= 0 and self.keys.rmb.GetKeyDown() )
    --         then
    --               if      self.Variables.varSelected == 0
    --               and     ( self.Variables[self.Variables.index][4] or self.Variables[self.Variables.index][5] )
    --               then
    --                       self.Variables.varSelected = self.Variables.index
    --                       self.Variables.selected    = self.Variables[self.Variables.index]
    --                       self.Variables.prevColor   = self.textHUD3.color
    --                       self.textHUD3.color        = Color(0,1,0,1)

    --               elseif  self.Variables.varSelected > 0
    --               then
    --                       self.textHUD3.color        = self.Variables.prevColor
    --                       self.Variables.varSelected = 0
    --                       self.Variables.selected    = false
    --               end
    --         else
    --               if    Input.GetAxis("Mouse ScrollWheel") < 0  then if self.Variables.varSelected == 0 then self.Variables.index =   self.Variables.index % #self.Variables + 1                         ; self.Variables.selected = self.Variables[self.Variables.index] ; elseif self.Variables.selected[4] then self.Variables.selected[4]()  end ; self.Variables.saveOnOrAfter = os.clock() + 2 ; end
    --               if    Input.GetAxis("Mouse ScrollWheel") > 0  then if self.Variables.varSelected == 0 then self.Variables.index = ( self.Variables.index + #self.Variables - 2 ) % #self.Variables + 1 ; self.Variables.selected = self.Variables[self.Variables.index] ; elseif self.Variables.selected[5] then self.Variables.selected[5]()  end ; self.Variables.saveOnOrAfter = os.clock() + 2 ; end
    --         end

    -- elseif  self.Variables.disabledMouseScrollTime and self.Variables.disabledMouseScrollTime + 1 < os.clock()
    -- then
    --         self.Variables.disabledMouseScrollTime = false
    --         HBU.EnableGadgetMouseScroll() ; print("HBU.EnableGadgetMouseScroll()")
    -- end

    -- local   camPos = Camera.main.transform.position
    -- self.Variables.x,self.Variables.y,self.Variables.z    =  string.format( "%.2f", camPos.x ), string.format( "%.2f", camPos.y ), string.format( "%.2f", camPos.z )
    -- local   camRot = Camera.main.transform.rotation
    -- self.Variables.rx,self.Variables.ry,self.Variables.rz =  string.format( "%.4f", camRot.x ), string.format( "%.4f", camRot.y ), string.format( "%.4f", camRot.z )
    self.Variables.x,self.Variables.y,self.Variables.z    =  unpack(Camera.main.transform.position)
    self.Variables.rx,self.Variables.ry,self.Variables.rz =  unpack(Camera.main.transform.rotation)

    if  self.textHUD1 and self.textHUD2
    then
        if    self.textHUD1Text == ""
        then
              -- local textTab1,textTab2,textTab3 = {},{},{}
              -- for k,v in ipairs(self.Variables) do  if v[3] then textTab1[#textTab1+1] = v[3] end ; if v[1] and v[2] and type(v[1][v[2]]) ~= "nil" then if type(v[1][v[2]]) == "number" then if v[1][v[2]] % 1 == 0 then textTab2[#textTab2+1] = string.format( "%.0f", v[1][v[2]] )  ; else textTab2[#textTab2+1] = string.format( "%.4f", v[1][v[2]] ) ; end ; else textTab2[#textTab2+1] = tostring(v[1][v[2]]) ; end ; else textTab2[#textTab2+1] = ""   end ; if self.Variables.index == k then textTab3[#textTab3+1] = "<---" ; else textTab3[#textTab3+1] = "" ; end ; end
              local textTab1,textTab2= {},{}
              for k,v in ipairs(self.Variables) do  if v[3] then textTab1[#textTab1+1] = v[3] end ; if v[1] and v[2] and type(v[1][v[2]]) ~= "nil" then if type(v[1][v[2]]) == "number" then if v[1][v[2]] % 1 == 0 then textTab2[#textTab2+1] = string.format( "%.0f", v[1][v[2]] )  ; else textTab2[#textTab2+1] = string.format( "%.4f", v[1][v[2]] ) ; end ; else textTab2[#textTab2+1] = tostring(v[1][v[2]]) ; end ; else textTab2[#textTab2+1] = "" end ; end
              self.textHUD1Text  = table.concat(textTab1,"\n")
              self.textHUD1.text = self.textHUD1Text
              self.textHUD2.text = table.concat(textTab2,"\n")
            --if ( not HBU.InSeat()  or  self.keys.Control.GetKey() > 0.5 ) and ( self.keys.rmb.GetKey() > 0.5 or self.Variables.varSelected ~= 0 ) then self.textHUD3.text = table.concat(textTab3,"\n") else self.textHUD3.text = "" ; end
        else
              local textTab2= {}
              for k,v in ipairs(self.Variables) do if v[1] and v[2] and type(v[1][v[2]]) ~= "nil" then if type(v[1][v[2]]) == "number" then if v[1][v[2]] % 1 == 0 then textTab2[#textTab2+1] = string.format( "%.0f", v[1][v[2]] )  ; else textTab2[#textTab2+1] = string.format( "%.4f", v[1][v[2]] ) ; end ; else textTab2[#textTab2+1] = tostring(v[1][v[2]]) ; end ; else textTab2[#textTab2+1] = "" end ; end
            --self.textHUD1Text  = table.concat(textTab1,"\n")
            --self.textHUD1.text = self.textHUD1Text
              self.textHUD2.text = table.concat(textTab2,"\n")
        end
    end
end


function Superman:SetupHUD()
    if not self.HUD then return ; end
    if self.textHUD1 and not Slua.IsNull(self.textHUD1) then return ; end
    if not self.Font1 then self.Font1 = Font.CreateDynamicFontFromOSFont({"Consolas","Consolas Bold","Mongolian Baiti"}, 14) ; end
    self.HUD.parent = HBU.menu.transform:Find("Foreground").gameObject
    for k,v in pairs({"textHUD1","textHUD2", }) do  --"textHUD3",}) do
        self[v]          = HBU.Instantiate("Text",self.HUD.parent):GetComponent("Text")
        self[v].text     = ""
        self[v].font     = self.Font1 or self[v].font
        self[v].fontSize = self.HUD.fontSize
        HBU.LayoutRect(self[v].gameObject,Rect( self.HUD.left+((k-1)*100), self.HUD.top, self.HUD.width, self.HUD.height ) )
        if    self.HUD.colors and #self.HUD.colors > 0
        then  self[v].color = self.HUD.colors[(k-1)%#self.HUD.colors+1]
        else  self[v].color  = Color( math.floor( (k) % 2 ), math.floor(k/2) % 2, math.floor(k/4) % 2, 1)
        end
    end
end


function Superman:DestroyObjects()
  for k,v in pairs(self.ObjectsToDestroy) do
    if  v  and  self[v]  and not Slua.IsNull( self[v] )
    then
            -- if      tostring(self[v]):sub(-16) == "UnityEngine.Font"  then GameObject.Destroy(self[v])
            -- elseif  self[v].gameObject                                then GameObject.Destroy(self[v].gameObject)
            -- else                                                           GameObject.Destroy(self[v])
            -- end
            if      string.find(tostring(self[v]),"UnityEngine.Font") then GameObject.Destroy(self[v])
            elseif  self[v].gameObject                                then GameObject.Destroy(self[v].gameObject)
            else                                                           GameObject.Destroy(self[v])
            end
            self[v] = false
    elseif  v and self[v]
    then    self[v] = false
    end
  end
  self:ClearComponents()
end


function Superman:OnDestroy()
  Debug.Log("Superman:OnDestroy()")
  if not self then return ; end
  if self.rigidmotor and not Slua.IsNull(self.rigidmotor) then self.rigidmotor.enabled = true ; end
  -- HBU.EnableGadgetMouseScroll()
  -- print("HBU.EnableGadgetMouseScroll()")
  self:DestroyObjects()
  self.enabled = false
end


function Superman:Update()
  self.tickActual = self.tickActual + 1
  self:SetCpuTime(true)
  if not self:EnableCheck() then  self:SetCpuTime() ; return ; end
  self.tick = self.tick + 1
  self:SetupHUD()
  self.Variables.gc_bytes_last = self.Variables.gc_bytes
  self.Variables.gc_bytes      = gc.count()*1024
  self.Variables.gc_frame      = self.Variables.gc_bytes - self.Variables.gc_bytes_last
  self.Variables.Load()
  if self.Variables and self.Variables.saveOnOrAfter and self.Variables.saveOnOrAfter < os.clock() then self.Variables.saveOnOrAfter = false ; self.Variables.Save() end
  if not self:ProcessActions() then self:SetCpuTime() ; return ; end
  if self.tick%30 == 0 and self.rigidmotor and not Slua.IsNull(self.rigidmotor) then self.rigidmotor.enabled = false; end
  if self.tick % 4 == 0 then self:ProcessHUD() end
  if      self.keys.F6.GetKeyUp()  then    self:GetNextKey(true)  else    self:GetNextKey(self.GetNextKeyActive)  end
  self:SetCpuTime()
  return
end

--function main(go) Superman.gameObject = go ; return Superman ; end

return Superman
