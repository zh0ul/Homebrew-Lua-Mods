local ModLua={}
function main(gameObject)  ModLua.gameObject = gameObject  return ModLua  end

function ModLua:Awake()
    Debug.Log("AntyFog:Awake()")

    self.GlobalDensity             = 0.00012
    self.fogDensity                = 0.00012
    self.farClipPlane              = 40000
    self.fog                       = false
    self.TOD_Scattering_enabled    = true

    self.Actions                   = {
        Toggle_TOD_Scattering      = function(toggle) self.TOD_Scattering_enabled = Set_Object_Value( Camera.main:GetComponent("TOD_Scattering"), "enabled",        toggle              ) ; end, -- Camera Settings
        Toggle_RenderSettings_fog  = function(toggle) self.fog                    = Set_Object_Value( RenderSettings,                             "fog",            toggle              ) ; end, -- Fog Settings
        Set_GlobalDensity          = function() self.GlobalDensity                = Set_Object_Value( Camera.main:GetComponent("TOD_Scattering"), "GlobalDensity",  self.GlobalDensity  ) ; end, -- Fog Settings
        Set_FogDensity             = function() self.fogDensity                   = Set_Object_Value( RenderSettings,                             "fogDensity",     self.fogDensity     ) ; end, -- Fog Settings
        Set_farClipPlane           = function() self.farClipPlane                 = Set_Object_Value( Camera.main,                                "farClipPlane",   self.farClipPlane   ) ; end, -- Camera Settings
    }

    self.Keys                      = {
        [KeyCode.F5]               = function() self.Actions.Toggle_TOD_Scattering()     ; self:Set_General_Settings() ; end,   --  Toggle Fog
        [KeyCode.F6]               = function() self.Actions.Toggle_RenderSettings_fog() ; self:Set_General_Settings() ; end,   --  Toggle RenderSettings.fog
    }

    self.Actions.Toggle_TOD_Scattering()
    self.Actions.Toggle_RenderSettings_fog()
end


function ModLua:Set_General_Settings()
    local a = self.Actions
    a.Set_GlobalDensity()
    a.Set_FogDensity()
    a.Set_farClipPlane()
end

function ModLua:Update()
  if    self.Keys
  then  for k,v in pairs(self.Keys) do  if Input.GetKeyDown(k) and v  then v() ; end ; end
  end
end

function ModLua:OnDestroy()
    Debug.Log("AntyFog:OnDestroy()")
end
