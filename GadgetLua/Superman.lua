local Gadget={}
function main(gameObject)  Gadget.gameObject = gameObject  return Gadget  end

local path = Application.persistentDataPath .. "/Lua/GadgetLua/"

function Gadget:Awake()  

  Debug.Log("Superman:Awake()")

  self.keysConfig        = { 
                              ["Jump"]     = {},
                              ["Crouch"]   = {},
                              ["Move"]     = {},
                              ["Strafe"]   = {},
                              ["Run"]      = {},
                              ["Control"]  = {},
                              ["Alt"]      = {},
                           }

  self.Components        = {
                              rigidbody  = "UnityEngine.Rigidbody",
                              rigidmotor = "rigidbody_character_motor",
                           }

  self.Actions           = {
                            {
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
                            {
                              condition  =  function() if self.keys.Control > 0.1 then return false; else return true; end; end,
                              action     =  function()
                                                     self.rigidmotor.enabled = false;
                                                     self.forces.up       =  ( Vector3.up * ( self.keys.Jump or 0 ) * self.force ) + ( Vector3.up * ( -self.keys.Crouch or 0 ) * self.force );
                                                     self.forces.forward  =  Camera.main.transform.forward * ( self.keys.Move   or 0 ) * self.force;
                                                     self.forces.strafe   =  Camera.main.transform.right   * ( self.keys.Strafe or 0 ) * self.force;
                                                     self.forces.drag     =  -self.rigidbody.velocity * self.drag;
                                                     for k,v in pairs(self.forces) do  if v ~= 0 then self.rigidbody:AddForce( v ) end;  end;
                                            end,
                            },
                            {
                              condition = function() if self.keys.Run > 0.1 and self.keys.Control > 0.1 then return true; end; return false; end,
                              action    = function() for k,v in pairs(self.settings.Defaults) do self[k] = v ; end; end,
                            },
                            {
                              condition = function() if self.keys.Run > 0.1 and ( self.keys.Move > 0.1 or self.keys.Move < -0.1 ) then return true; end; return false; end,
                              action    = function() self.force = self.force + 200*self.keys.Move; if self.force < 0 then self.force = 0; end; end,
                            },
                            {
                              condition = function() if self.keys.Control > 0.1 and ( self.keys.Move > 0.1 or self.keys.Move < -0.1 ) then return true; end; return false; end,
                              action    = function() self.drag = self.drag + 1*self.keys.Move; if self.drag < 0 then self.drag = 0; end; end,
                            },
                            {
                              condition = function() if ( self.keys.Control and ( self.keys.Control < -0.1 or self.keys.Control > 0.1 ) )  or  ( self.keys.Run and ( self.keys.Run < -0.1 or self.keys.Run > 0.1 ) ) then  return true ; end; return false; end,
                              action    = function() Debug.Log( string.format("Force:%s  Drag:%s", self.force, self.drag) ) ; end,
                            },
                          }

  self.settings           = {}
  self.settings.Name      = "SuperMan-Gadget"
  self.settings.Defaults  = { force = 3000, drag = 50, }
  self.settings.SaveFrame = 3000

  self.forces             = { forward = 0, strafe = 0, up = 0, drag = 0, }

  self.Indicators         = { "force", "drag" }

  self.noaction           = false

  self.tick               = 0

  self.UpdateEveryXTicks  = 2

  self.OnDestroyFunc      = function() if self.rigidbody  then self.rigidbody = nil ; end ; if self.rigidmotor then if not Slua.IsNull(self.rigidmotor) then self.rigidmotor.enabled = true ; end ; self.rigidmotor = nil ; end ; end

  self.HBGUIFunc          = loadstring( file2string( path.."lib/HBGUI.lua" ) )
  if self.HBGUIFunc then  self.HBGUI = self.HBGUIFunc() ; end

end


function Gadget:ManageSettings(saveSettings)
    if not self.settings          then self.settings = {} ; end
    if not self.settings.Defaults then return true ; end
    if not self.settings.Name     then self.settings.Name = "SupermanSettings" ; end
    for k,v in pairs (self.settings.Defaults) do
        if  saveSettings
        then
            if     self[k]  then HBU.SaveValue( self.settings.Name, tostring(k), tostring(self[k]) ) ; end
        else
            if not self[k]  then  local ret = HBU.LoadValue( self.settings.Name, tostring(k) )  if ret and ret ~= "" then if tonumber(ret) then self[k] = tonumber(ret) ; elseif ret == "true" then self[k] = true ; elseif ret == "false" then self[k] = false ; else self[k] = v ; end ; end ; end
        end
    end
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


function Gadget:UpdateIndicators()
  if not self.HBGUI then return ; end
  for k,v in pairs(self.Indicators) do  if v and self[v] then self.HBGUI:UpdateIndicatorBar(v,self[v],1) ; end ; end
end


function Gadget:ProcessKeys()
  if not self.keysConfig then return ; end
  if not self.keys       then self.keys = {} ; end
  for k,t in pairs(self.keysConfig)
  do
      if not self.keysConfig[k].key then  self.keysConfig[k].key = HBU.GetKey(k)                     ; end
      if     self.keysConfig[k].key then  self.keys[k]           = self.keysConfig[k].key.GetKey()   ; end
  end
end


function Gadget:ProcessActions()
  if  not self.Actions then return ; end
  if self.noaction then self.noaction = false ; end
  for k,v in pairs(self.Actions) do
      if not self.noaction and v.condition and v:condition() and v.action then v:action() end
  end
end


function Gadget:Update()
  self.tick = self.tick + 1
  if self.settings and self.settings.SaveFrame and self.tick % self.settings.SaveFrame == 0 then self:ManageSettings(true); end
  if self.tick % self.UpdateEveryXTicks ~= 0 then return ; end
  self:ManageSettings()
  self:ProcessKeys()
  self:ProcessActions()
  -- self:UpdateIndicators()
end


function Gadget:SetupHUD()
    local parent  = HBU.menu.transform:Find("Foreground").gameObject
    for k,v in pairs({"textHUD1","textHUD2","textHUD3",}) do
        if Font then  self[v].font = Font.CreateDynamicFontFromOSFont({"consolas","Roboto","Arial"}, 12)  end
        self[v]        = HBU.Instantiate("Text",parent):GetComponent("Text")
        HBU.LayoutRect(self[v].gameObject,Rect( 5+((k-1)*100), 35, 300, 200 ) )
        self[v].color  = Color(1,1,0,1)
        self[v].text   = ""
    end
end

function Gadget:OnDestroy()
  Debug.Log("Superman:OnDestroy()")
  if self.ManageSettings then self:ManageSettings(true) ; end
  if self.OnDestroyFunc  then self:OnDestroyFunc()      ; end
  if self.HBGUI then self.HBGUI:Destroy()               ; end
end

