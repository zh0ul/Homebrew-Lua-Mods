local ModLua={}
function main(gameObject)  ModLua.gameObject = gameObject  return ModLua  end

function ModLua:Awake()
    Debug.Log("AntyFog:Awake()")

    self.Variables           = {
      Save                         = function() for k,v in pairs(self.Variables) do if v ~= self.Variables.Save and v ~= self.Variables.Load then HBU.SaveValue(self.Variables.SaveName,tostring(k),tostring(v)) ; end ; end ; end,
      Load                         = function() if  self.Variables.Loaded  then  return end ; for k,v in pairs(self.Variables) do local val = HBU.LoadValue(self.Variables.SaveName,tostring(k)) ; if type(v) == "number" then self.Variables[k] = tonumber(val) ; elseif type(v) == "string" then if v == "false" then self.Variables[k] = false ; elseif v == "true" then self.Variables[k] = true ; else self.Variables[k] = val  end ; end ; end ; self.Variables.Loaded = true ; end,
      SaveName                     = "AntyFog",
      Loaded                       = false,

      globalDensity                = 0.00012,
      fogDensity                   = 0.00012,
      farClipPlane                 = 40000,
      fog                          = false,
      TOD_Scattering_enabled       = false,
   }

    self.v                         = self.Variables
    
    self.Actions                   = {
        Toggle_TOD_Scattering      = function(toggle) self.v.TOD_Scattering_enabled = Set_Object_Value( Camera.main:GetComponent("TOD_Scattering"), "enabled",        toggle                ) ; end, -- Camera Settings
        Toggle_RenderSettings_fog  = function(toggle) self.v.fog                    = Set_Object_Value( RenderSettings,                             "fog",            toggle                ) ; end, -- Fog Settings
        Set_GlobalDensity          = function()       self.v.GlobalDensity          = Set_Object_Value( Camera.main:GetComponent("TOD_Scattering"), "GlobalDensity",  self.v.globalDensity  ) ; end, -- Fog Settings
        Set_FogDensity             = function()       self.v.fogDensity             = Set_Object_Value( RenderSettings,                             "fogDensity",     self.v.fogDensity     ) ; end, -- Fog Settings
        Set_farClipPlane           = function()       self.v.farClipPlane           = Set_Object_Value( Camera.main,                                "farClipPlane",   self.v.farClipPlane   ) ; end, -- Camera Settings
    }

    self.Keys                      = {
        [KeyCode.F5]               = function() self.Actions.Toggle_TOD_Scattering()     ; self:Set_General_Settings() ; end,   --  Toggle Fog
        [KeyCode.F6]               = function() self.Actions.Toggle_RenderSettings_fog() ; self:Set_General_Settings() ; end,   --  Toggle RenderSettings.fog
    }

    self.Actions.Toggle_TOD_Scattering(self.v.TOD_Scattering_enabled)
    self.Actions.Toggle_RenderSettings_fog(self.v.fog)
end

function ModLua:Set_General_Settings()
    for k,f in pairs({"Set_GlobalDensity","Set_FogDensity","Set_farClipPlane"}) do if self.Actions and self.Actions[f] then self.Actions[f]()  end end
end

function ModLua:Update()

  self.Variables.Load()

  local saveValues = false

  if    self.Keys
  then  for k,v in pairs(self.Keys) do  if Input.GetKeyDown(k) and v  then v() ; saveValues = true ; end ; end
  end

  if    saveValues  then self.Variables.Save() ; end

end

function ModLua:OnDestroy()
    Debug.Log("AntyFog:OnDestroy()")
end