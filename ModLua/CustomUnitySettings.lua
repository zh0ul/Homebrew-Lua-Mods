local CustomUnitySettings = {}

------------------------------------------------------------------------------------------------------------

function CustomUnitySettings:Awake()

    print("CustomUnitySettings:Awake()")

    self.paths = {
          hbdata = {
              gadgetlua   = HBU.GetLuaFolder().."/GadgetLua/",
              modlua      = HBU.GetLuaFolder().."/ModLua/",
          },
          userdata = {
              root        = Application.persistentDataPath,
              gadgetlua   = Application.persistentDataPath.."/Lua/GadgetLua/",
              modlua      = Application.persistentDataPath.."/Lua/ModLua/",
          },
    }

    self.InBuilder = false

    self.tick = 0

end

------------------------------------------------------------------------------------------------------------

function CustomUnitySettings:Set_Custom_Settings(override)

    if  not override  and self.tick ~= 2 then return ; end

    if RenderSettings then  RenderSettings.fog = false ; end

    if    Camera and Camera.main
    then
          print( string.format( "  %-60s = %s", 'Camera.main:GetComponent("TOD_Scattering").GlobalDensity', tostring(Camera.main:GetComponent("TOD_Scattering").GlobalDensity) ) )
          print( string.format( "  %-60s = %s", 'Camera.main:GetComponent("TOD_Scattering").HeightFalloff', tostring(Camera.main:GetComponent("TOD_Scattering").HeightFalloff) ) )
          print( string.format( "  %-60s = %s", 'Camera.main:GetComponent("TOD_Scattering").ZeroLevel', tostring(Camera.main:GetComponent("TOD_Scattering").ZeroLevel) ) )
          print( string.format( "  %-60s = %s", 'Camera.main:GetComponent("TOD_Scattering").enabled', tostring(Camera.main:GetComponent("TOD_Scattering").enabled) ) )
          print( string.format( "  %-60s = %s", 'Camera.main.farClipPlane', tostring(Camera.main.farClipPlane) ) )
          Camera.main:GetComponent("TOD_Scattering").GlobalDensity = 0
          Camera.main:GetComponent("TOD_Scattering").HeightFalloff = 0
          Camera.main:GetComponent("TOD_Scattering").ZeroLevel     = 0
          Camera.main:GetComponent("TOD_Scattering").enabled       = false
          Camera.main.farClipPlane = 50000
          print( string.format( "  %-60s = %s", 'Camera.main:GetComponent("TOD_Scattering").GlobalDensity', tostring(Camera.main:GetComponent("TOD_Scattering").GlobalDensity) ) )
          print( string.format( "  %-60s = %s", 'Camera.main:GetComponent("TOD_Scattering").HeightFalloff', tostring(Camera.main:GetComponent("TOD_Scattering").HeightFalloff) ) )
          print( string.format( "  %-60s = %s", 'Camera.main:GetComponent("TOD_Scattering").ZeroLevel', tostring(Camera.main:GetComponent("TOD_Scattering").ZeroLevel) ) )
          print( string.format( "  %-60s = %s", 'Camera.main:GetComponent("TOD_Scattering").enabled', tostring(Camera.main:GetComponent("TOD_Scattering").enabled) ) )
          print( string.format( "  %-60s = %s", 'Camera.main.farClipPlane', tostring(Camera.main.farClipPlane) ) )
          local comp = Camera.main:GetComponent("PostProcessingBehaviour")  ; if comp and not Slua.IsNull(comp) then comp.enabled = false ; end
    end

end

------------------------------------------------------------------------------------------------------------

function CustomUnitySettings:OnDestroy()
    print("CustomUnitySettings:OnDestroy()")
end

------------------------------------------------------------------------------------------------------------

function CustomUnitySettings:Update()
    self.tick = self.tick + 1
    self:Set_Custom_Settings()
    if      not self.InBuilder and HBU.InBuilder()                     then  self.InBuilder = true
    elseif  self.InBuilder and not HBU.InBuilder()                     then  self.InBuilder = false ; self.setMovementTick = self.tick + 90
    elseif  self.setMovementTick and self.setMovementTick == self.tick then  SetPlayerMovement(true)  
    end
    return
end

--function main(go) CustomUnitySettings.gameObject = go ; return CustomUnitySettings ; end

return CustomUnitySettings
