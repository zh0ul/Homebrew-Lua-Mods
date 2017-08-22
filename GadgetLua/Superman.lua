local Gadget={}
function main(gameObject)  Gadget.gameObject = gameObject  return Gadget  end

local path = Application.persistentDataPath .. "/Lua/GadgetLua/"

function Gadget:Awake()  

  Debug.Log("Superman:Awake()")

  self.keysConfig        = { 
                              ["UseGadget"]           = {},
                              ["UseGadgetSecondary"]  = {},
                              ["Jump"]                = {},
                              ["Crouch"]              = {},
                              ["Move"]                = {},
                              ["Strafe"]              = {},
                              ["Run"]                 = {},
                              ["Control"]             = {},
                              ["Alt"]                 = {},
                              ["Action"]              = {},
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
                                    action     =  function() self.noaction = true end,
                                  },

                            [2] = {
                                    condition = function() return true ; end,
                                    action    = function()
                                                  if   ( self.keys.Move ~= 0  or self.keys.Strafe ~= 0  or self.keys.Jump ~= 0  or self.keys.Crouch ~= 0 )
                                                  and  ( self.Variables.curForce and self.Variables.maxForce )
                                                  then self.Variables.curForce = math.min( self.Variables.maxForce, self.Variables.curForce+1+self.Variables.curForce*0.10 )
                                                  else self.Variables.curForce = 1000
                                                  end
                                                end,
                                  },
                            [3] = {
                                    condition = function() if self.keys.Run > 0.1 and self.keys.Control > 0.1 then return true; end; return false; end,
                                    action    = function() for k,v in ipairs(self.Variables) do if v[1] and v[2] and type(v[6]) ~= "nil" then v[1][v[2]] = v[6] ; end; end; end,
                                  },

                            [4] = {
                                    condition = function() if self.keys.Run > 0.1 and ( self.keys.Move > 0.1 or self.keys.Move < -0.1 ) then return true; end; return false; end,
                                    action    = function() self.Variables.maxForce = self.Variables.maxForce + 200*self.keys.Move; if self.Variables.maxForce < 0 then self.Variables.maxForce = 0; end; end,
                                  },

                            [5] = {
                                    condition = function() if self.keys.Control > 0.1 and ( self.keys.Move > 0.1 or self.keys.Move < -0.1 ) then return true; end; return false; end,
                                    action    = function() self.Variables.drag = self.Variables.drag + 1*self.keys.Move; if self.Variables.drag < 0 then self.Variables.drag = 0; end; end,
                                  },

                            [6] = {
                                    condition = function() if self.keys.Action ~= 0  then  return true ; end; return false; end,
                                    action    = function()  self.rigidbody:AddForce( -self.rigidbody.velocity*500 )  end,
                                  },

                            [7] = {
                                    condition  =  function() if self.keys.Control > 0.1 then return false; else return true; end; end,
                                    action     =  function()
                                                           self.rigidmotor.enabled = false;
                                                           self.forces.up       =  (
                                                            Vector3.up * 
                                                            ( self.keys.Jump or 0 ) *
                                                                    self.Variables.curForce ) + (
                                                                      Vector3.up *
                                                                        ( -self.keys.Crouch or 0 )
                                                                          * self.Variables.curForce
                                                                          );
                                                           self.forces.forward  =  Camera.main.transform.forward * ( self.keys.Move   or 0 ) * self.Variables.curForce;
                                                           self.forces.strafe   =  Camera.main.transform.right   * ( self.keys.Strafe or 0 ) * self.Variables.curForce;
                                                           self.forces.drag     =  -self.rigidbody.velocity * self.Variables.drag;
                                                           for k,v in pairs(self.forces) do  if v ~= 0 then self.rigidbody:AddForce( v ) end;  end;
                                                  end,
                                  },

                            [8] = {
                                    condition = function() if self.Variables and self.Variables.gravity and self.Variables.gravity ~= 0 then return true ; end ; end,
                                    action    = function() self.rigidbody:AddForce( Vector3.up * -1 * self.Variables.gravity * 100 ) ; end,
                                  },
                          }

  self.Actions.MAXFORCE_UP   = function() self.Variables.maxForce = self.Variables.maxForce + self.Variables.maxForce*0.1                ; end
  self.Actions.MAXFORCE_DOWN = function() self.Variables.maxForce = math.max( 1000, self.Variables.maxForce - self.Variables.maxForce*0.1 ) ; end
  self.Actions.DRAG_UP       = function() self.Variables.drag     = self.Variables.drag + 0.01 + self.Variables.drag*0.1                 ; end
  self.Actions.DRAG_DOWN     = function() self.Variables.drag     = math.max( 0, self.Variables.drag  - self.Variables.drag*0.1  )       ; end
  self.Actions.GRAVITY_UP    = function() self.Variables.gravity  = self.Variables.gravity + 0.2                                         ; end
  self.Actions.GRAVITY_DOWN  = function() self.Variables.gravity  = self.Variables.gravity - 0.2                                         ; end

  self.Variables          = {
      Save                         = function() for k,v in ipairs(self.Variables) do if v[1] and v[2] and type(v[1][v[2]]) ~= "nil" then HBU.SaveValue(self.Variables.SaveName,tostring(v[2]),tostring(v[1][v[2]])) ; end ; end ; end,
      Load                         = function() if  self.Variables.Loaded  then  return end ; self.Variables.Loaded = true ; for k,v in ipairs(self.Variables) do local val,var = HBU.LoadValue( self.Variables.SaveName, tostring(v[2]) ), false ; if v[1] and v[1][v[2]] then var = v[1][v[2]] ; end ; if      type(var) == "number"  then  if val ~= "" and tonumber(val)  then v[1][v[2]] = tonumber(val) ; end ; elseif  type(var) == "boolean" then  if val == "false" then v[1][v[2]] = false ; elseif v[1] and v[2] and type(v[1][v[2]]) == "nil" and val == "" and type(v[6]) ~= "nil"  then v[1][v[2]] = v[6] ; elseif v[1] and v[2] then  v[1][v[2]] = true ; end ; elseif v[1] and v[2] then v[1][v[2]] = val  end ; end ; end,
      SaveName                     = "SuperMan-Gadget",
      Loaded                       = false,

      index       = 1,
      varSelected = 0,
      saveFrame   = 5400,

      maxForce    = 3000,
      curForce    = 0,
      drag        = 50,
      gravity     = 0,
  }

--self.Variables[#self.Variables+1] = { parent,           "varName",   "Display Name",   action_when_wheel_down,        action_when_wheel_up,     default_value, }
  self.Variables[#self.Variables+1] = { self.Variables,   "curForce",  "Current Force",  self.Actions.MAXFORCE_DOWN,    self.Actions.MAXFORCE_UP,             0, }
  self.Variables[#self.Variables+1] = { self.Variables,   "maxForce",  "Max Force",      self.Actions.MAXFORCE_DOWN,    self.Actions.MAXFORCE_UP,          3000, }
  self.Variables[#self.Variables+1] = { self.Variables,   "drag",      "Drag",           self.Actions.DRAG_DOWN,        self.Actions.DRAG_UP,                50, }
  self.Variables[#self.Variables+1] = { self.Variables,   "gravity",   "Gravity",        self.Actions.GRAVITY_DOWN,     self.Actions.GRAVITY_UP,              0, }

  self.forces             = { forward = 0, strafe = 0, up = 0, drag = 0, }

  self.noaction           = false

  self.tick               = 0

  self.ObjectsToDestroy    = {"textHUD1","textHUD2","textHUD3"}
  self.ObjectsToNotDestroy = { rigidmotor = true, rigidbody = true, }

  if self.SetupHUD then self:SetupHUD() ; end

end


function Gadget:GetComponents()
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


function Gadget:ProcessKeys()
  if not self.keysConfig then return ; end
  if not self.keys       then self.keys = {} ; end
  if not self.keysUp     then self.keysUp = {} ; end
  if not self.keysDown   then self.keysDown = {} ; end
  for k,t in pairs(self.keysConfig)
  do
      if not self.keysConfig[k].key then  self.keysConfig[k].key = HBU.GetKey(k)                        ; end
      if     self.keysConfig[k].key then  self.keys[k]           = self.keysConfig[k].key.GetKey()      ; end
      if     self.keysConfig[k].key then  self.keysUp[k]         = self.keysConfig[k].key.GetKeyUp()    ; end
      if     self.keysConfig[k].key then  self.keysDown[k]       = self.keysConfig[k].key.GetKeyDown()  ; end
  end
end


function Gadget:ProcessActions()
  if  not self.Actions then return ; end
  if self.noaction then self.noaction = false ; end
  for k,v in ipairs(self.Actions) do
      if not self.noaction and v.condition and v.condition() and v.action then v.action() end
  end
end


function Gadget:ProcessHUD()

    if  ( not HBU.InSeat()  or  self.keys.Control > 0.5 )
    and     self.keys.UseGadgetSecondary > 0.5  or  self.Variables.varSelected ~= 0
    then
            HBU.DisableGadgetMouseScroll() ; self.Variables.disabledMouseScrollTime = os.clock()

            if    self.keysDown.UseGadget
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
    end
    local textTab1,textTab2,textTab3 = {},{},{}
    for k,v in ipairs(self.Variables) do  if v[3] then textTab1[#textTab1+1] = v[3] end ; if v[1] and v[2] and type(v[1][v[2]]) ~= "nil" then if type(v[1][v[2]]) == "number" then textTab2[#textTab2+1] = string.format( "%.2f", v[1][v[2]] )  ; else textTab2[#textTab2+1] = tostring(v[1][v[2]]) ; end ; else textTab2[#textTab2+1] = ""   end ; if self.Variables.index == k then textTab3[#textTab3+1] = "<---" ; else textTab3[#textTab3+1] = "" ; end ; end
    local text1,text2,text3 = table.concat(textTab1,"\n"),table.concat(textTab2,"\n"),table.concat(textTab3,"\n")
    self.textHUD1.text = text1
    self.textHUD2.text = text2
    if ( not HBU.InSeat()  or  self.keys.Control > 0.5 ) and self.keys.UseGadgetSecondary > 0.5 or self.Variables.varSelected ~= 0 then self.textHUD3.text = text3 else self.textHUD3.text = "" ; end
end


function Gadget:Update()
  self.tick = self.tick + 1
  self.Variables.Load() -- Only actually loads variables once.  Returns quickly if already loaded.
  if self.Variables and self.Variables.saveFrame and self.tick % self.Variables.saveFrame == 0 then self.Variables.Save() end
  self:ProcessKeys()
  self:ProcessActions()
  self:ProcessHUD()
end


function Gadget:SetupHUD()
    local parent  = HBU.menu.transform:Find("Foreground").gameObject
    for k,v in pairs({"textHUD1","textHUD2","textHUD3",}) do
        self[v]        = HBU.Instantiate("Text",parent):GetComponent("Text")
        HBU.LayoutRect(self[v].gameObject,Rect( 5+((k-1)*100), 35, 300, 200 ) )
        self[v].color  = Color( math.floor( (k) % 2 ), math.floor(k/2) % 2, math.floor(k/4) % 2, 1)
        self[v].text   = ""
    end
end


function Gadget:DestroyObjectTable(t,keyStr)
    keyStr = keyStr or "self."
    for k,v in pairs(t) do  if type(v) == "table" then self:DestroyObjectTable(v,keyStr..tostring(k)..".") ; elseif type(v) == "userdata" and ( keyStr ~= "self." or tostring(k) ~= "gameObject" ) and ( not self.ObjectsToNotDestroy or not self.ObjectsToNotDestroy[k] ) and getmetatable(v) and not Slua.IsNull(v) then print( "GameObject.Destroy( "..keyStr..tostring(k).." )" ) ; GameObject.Destroy(v) ; t[v] = false  end ; end
end


function Gadget:DestroyObjects()
  --self:DestroyObjectTable(self)
  for k,v in pairs(self.ObjectsToDestroy) do
    if    v  and  self[v]  and not Slua.IsNull( self[v] )
    then  GameObject.Destroy(self[v]) ; self[v] = false
    end
  end
end

function Gadget:OnDestroy()
  Debug.Log("Superman:OnDestroy()")
  -- for k,v in pairs(self) do
  --     if      k ~= "gameObject" and ( not self.ObjectsToNotDestroy or not self.ObjectsToNotDestroy[k] ) and getmetatable(v) and not Slua.IsNull(v) then print( "1 GameObject.Destroy( self."..tostring(k).." )" )
  --     elseif  type(v) == "table"                    then for k2,v2 in pairs(v) do if ( not self.ObjectsToNotDestroy or not self.ObjectsToNotDestroy[k2] ) and type(v2) == "userdata" and getmetatable(v2) and not Slua.IsNull(v2) then print( "2 GameObject.Destroy( self."..tostring(k).."."..tostring(k2) ) ; end ; end
  --     elseif  k ~= "gameObject" and ( not self.ObjectsToNotDestroy or not self.ObjectsToNotDestroy[k] ) and type(v) == "userdata" and not Slua.IsNull(v)  then print( "3 GameObject.Destroy(","self."..tostring(k) )
  --     end
  -- end
  if self.rigidmotor then if not Slua.IsNull(self.rigidmotor) then self.rigidmotor.enabled = true ; end ; self.rigidmotor = nil ; end
  self:DestroyObjects()
end
