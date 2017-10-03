local ZoomViewHotkeys = {}


function ZoomViewHotkeys:Awake()

  print("ZoomViewHotkeys:Awake")

  self.keys            = {
      lmb              = HBU.GetKey("UseGadget"),
      rmb              = HBU.GetKey("UseGadgetSecondary"),
      zoomIn           = HBU.GetKey("ZoomIn"),  -- HBU.DisableGadgetMouseScroll()    Use these to disable/enable Gadget Selection.
      zoomOut          = HBU.GetKey("ZoomOut"), -- HBU.EnableGadgetMouseScroll()     (ex: when placing a vehicle, use Disable so ZoomIn/ZoomOut can be used to change spawn distance)
      escape           = HBU.GetKey("Escape"),
      shift            = HBU.GetKey("Shift"),
      control          = HBU.GetKey("Control"),
      alt              = HBU.GetKey("Alt"),
      submit           = HBU.GetKey("Submit"),                      -- Default: Enter
      move             = HBU.GetKey("Move"),                        -- Default: W / S
      strafe           = HBU.GetKey("Strafe"),                      -- Default: D / A
      jump             = HBU.GetKey("Jump"),                        -- Default: Space
      run              = HBU.GetKey("Run"),                         -- Default: Left-Shift
      crouch           = HBU.GetKey("Crouch"),                      -- Default: C
      ChangeCameraView = HBU.GetKey("ChangeCameraView"),            -- Default: V
      ChangeThirdView  = HBU.GetKey("ChangeThirdPersonCameraMode"), -- Default: B
      navback          = HBU.GetKey("NavigateBack"),                -- Default: Escape
      action           = HBU.GetKey("Action"),                      -- Default: F
      inventory        = HBU.GetKey("Inventory"),                   -- Default: I
      showcontrols     = HBU.GetKey("ShowControls"),                -- Default: F1
      flipvehicle      = HBU.GetKey("flipVehicle"),                 -- Default: L
      tilde            = { GetKey = function() if Input.GetKey(KeyCode.BackQuote)  then return 1 else return 0 ; end ; end, GetKeyDown = function() return Input.GetKeyDown(KeyCode.BackQuote)  ; end,  GetKeyUp = function() return Input.GetKeyDown(KeyCode.BackQuote)  ; end, },
      arrowl           = { GetKey = function() if Input.GetKey(KeyCode.LeftArrow)  then return 1 else return 0 ; end ; end, GetKeyDown = function() return Input.GetKeyDown(KeyCode.LeftArrow)  ; end,  GetKeyUp = function() return Input.GetKeyDown(KeyCode.LeftArrow)  ; end, },
      arrowr           = { GetKey = function() if Input.GetKey(KeyCode.RightArrow) then return 1 else return 0 ; end ; end, GetKeyDown = function() return Input.GetKeyDown(KeyCode.RightArrow) ; end,  GetKeyUp = function() return Input.GetKeyDown(KeyCode.RightArrow) ; end, },
      arrowu           = { GetKey = function() if Input.GetKey(KeyCode.UpArrow)    then return 1 else return 0 ; end ; end, GetKeyDown = function() return Input.GetKeyDown(KeyCode.UpArrow)    ; end,  GetKeyUp = function() return Input.GetKeyDown(KeyCode.UpArrow)    ; end, },
      arrowd           = { GetKey = function() if Input.GetKey(KeyCode.DownArrow)  then return 1 else return 0 ; end ; end, GetKeyDown = function() return Input.GetKeyDown(KeyCode.DownArrow)  ; end,  GetKeyUp = function() return Input.GetKeyDown(KeyCode.DownArrow)  ; end, },
      wheel            = { KeyUpData = { { tick = 0, }, { tick = 0, }, }, GetKey = function() return ( Input.GetAxis("Mouse ScrollWheel") * -1 ) ; end, GetKeyDown = function() local r = {false,false,false} ; local v = Input.GetAxis("Mouse ScrollWheel") ; if v ~= 0 then r[1] = true end ; if v > 0 then r[2] = true end ; if v < 0 then r[3] = true end ; return unpack(r) ; end,  GetKeyUp = function() if not self or not self.keys or not self.keys.wheel or not self.keys.wheel.KeyUpData or not self.tick then return false ; end ; local a_index,b_index = (self.tick-1)%2+1,(self.tick)%2+1 ; local d = self.keys.wheel.KeyUpData ; if self.tick ~= d[b_index].tick then d[b_index].tick = self.tick ; for k,v in pairs({self.keys.wheel.GetKeyDown()}) do d[b_index][k] = v ; end ; end ; if d[a_index].tick == self.tick - 1 then return d[a_index][1],d[a_index][2],d[a_index][3] ; else return false,false,false  ; end ; end, },      
  }


  self.CamModes = {
    [0]   = "ActionCameraMode",     ActionCameraMode     = 0,
    [1]   = "FixedCameraMode",      FixedCameraMode      = 1,
    [2]   = "LooseCameraMode",      LooseCameraMode      = 2,
    [3]   = "LookaroundCameraMode", LookaroundCameraMode = 3,
    Third                = 3,
    First                = 1,
    camOffset            = Vector3(0,0,0),
    camDistance          = 20,
    camDistanceLastSet   = os.clock(),
  }

  self.Actions               = {
      SwitchToFirstPerson    = function() Camera.main:GetComponent("HBPlayer"):SwitchToFirstPersonView() ; end,
      SwitchToThirdPerson    = function(camMode) camMode = camMode or self.CamModes.Third ; if not camMode or not self.CamModes or not self.CamModes[camMode] then camMode = 3 ; end ; local camModeName = self.CamModes[camMode] ; if camModeName then Camera.main:GetComponent("HBPlayer"):SwitchToThirdPersonView(camMode) ; if self.target and not Slua.IsNull(self.target) then Camera.main:GetComponent("HBPlayer"):GetComponent(camModeName).target = self.target.transform ; end ; end ; end,
      SetCam                 = function() if self.target or HBU.InSeat() then self.Actions.SwitchToThirdPerson() ; self.Actions.SetCamDistance() else self.Actions.SwitchToFirstPerson() ; end ; end,
      SetCamDistance         = function(dist)  dist = dist or self.CamModes.camDistance ; if not tonumber(dist) then dist = self.CamModes.camDistance else self.CamModes.camDistance = dist ; end ; local hbplayer = Camera.main:GetComponent("HBPlayer") ; for i = 0,3 do hbplayer:GetComponent(self.CamModes[i]):IncreaseCameraDistance(-100000) ; hbplayer:GetComponent(self.CamModes[i]):IncreaseCameraDistance(dist) ; self.CamModes.camDistanceLastSet = os.clock() ; end ; end,
      SetPlayerMovement      = function(toggle) if type(toggle) ~= "boolean" then toggle = true ; end ; Camera.main:GetComponentInParent("rigidbody_character_motor").enabled = toggle ; end,
  }

end

function ZoomViewHotkeys:Update()

    if HBU.InBuilder() then return ; end
    local wheel = self.keys.wheel.GetKey()
    if wheel == 0 then wheel = (self.keys.zoomIn.GetKey() - self.keys.zoomOut.GetKey()) * -0.1 ; end
    local wheelMod = self.keys.shift.GetKey()
    if wheelMod == 0 then wheelMod = self.keys.run.GetKey() ; end
    if wheelMod == 0 then wheelMod = 1 else wheelMod = wheelMod * 10 end
    if wheelMod == 1 then wheelMod = 10 - math.min( 9, (os.clock() - self.CamModes.camDistanceLastSet)*20 ) ; end

    -- If remote cam is active on a target, handle ZoomIn and ZoomOut
    if wheel ~= 0 then print( "os.clock() - self.CamModes.camDistanceLastSet = "..tostring( os.clock() - self.CamModes.camDistanceLastSet ) ) ; self.Actions.SetCamDistance(self.CamModes.camDistance + (wheel*wheelMod) ) ; print( "self.Actions.SetCamDistance("..tostring(self.CamModes.camDistance).." + ("..tostring(wheel).."*"..tostring(wheelMod).." )" ) ; end

end

function ZoomViewHotkeys:OnDestroy()
end

function main(g) ZoomViewHotkeys.gameObject = g ; return ZoomViewHotkeys ; end
