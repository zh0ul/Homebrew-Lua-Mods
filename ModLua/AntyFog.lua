--local Gadget={}
--function main(gameObject)  Gadget.gameObject = gameObject  return Gadget  end


function AntyFog:Awake()
    Camera.main:GetComponent("TOD_Scattering").enabled = false
	RenderSettings.fog = false
    Debug.Log("AntiFog:Awake()")
end

function AntyFog:Update()

--Debug Log
	--Debug.Log("AntiFog:Activate()")
	--Debug.Log( RenderSettings.ambientGroundColor )

--Toggle Fog	
    if Input.GetKeyDown( KeyCode.F5 )  then    if Camera.main:GetComponent("TOD_Scattering").enabled  == true then Camera.main:GetComponent("TOD_Scattering").enabled = false else Camera.main:GetComponent("TOD_Scattering").enabled = true end ; end
	if Input.GetKeyDown( KeyCode.F6 )  then    if RenderSettings.fog  == true then RenderSettings.fog = false else RenderSettings.fog = true end ; end

--Fog Settings
	Camera.main.gameObject:GetComponent("TOD_Scattering").GlobalDensity = 0.00012;
    RenderSettings.fogDensity = 0.00012;

--Camera Settings
    Camera.main.farClipPlane = 20000
end

function AntyFog:OnDestroy()
    Debug.Log("AntiFog:OnDestroy()")
end