local Gadget={}
function main(gameObject)  Gadget.gameObject = gameObject  return Gadget  end


function Gadget:Awake()  
    self.force      = 3000
    self.drag       = 50
    self.jumpkey    = HBU.GetKey("Jump")
    self.crouchkey  = HBU.GetKey("Crouch")
    self.movekey    = HBU.GetKey("Move")
    self.strafekey  = HBU.GetKey("Strafe")
    self.runkey     = HBU.GetKey("Run")
    self.controlkey = HBU.GetKey("Control")
    self.altkey     = HBU.GetKey("Alt")
end


function Gadget:GetPlayerAndRigidbody()
    if not self.player  and  Slua.IsNull(self.player)  then  self.player = GameObject.Find("Player")  end
    if self.player and  ( not self.rigidbody  or  Slua.IsNull(self.rigidbody) )  then  self.rigidbody = self.player.gameObject:GetComponent("Rigidbody")   end
end


function Gadget:AddForceToCamera()

    Camera.main:GetComponentInParent("rigidbody_character_motor").enabled = false

    if  self.rigidbody and not Slua.IsNull(self.rigidbody)
    then

        self.forces = {
              forward = Camera.main.transform.forward * self.movekey.GetKey() * self.force,
              strafe = Camera.main.transform.right * self.strafekey.GetKey() * self.force,
              up = ( Vector3.up * self.jumpkey.GetKey() * self.force ) + ( Vector3.up * -self.crouchkey.GetKey() * self.force ),
              drag = -self.rigidbody.velocity * self.drag,
        }

        self.rigidbody:AddForce( self.forces.forward )
        self.rigidbody:AddForce( self.forces.strafe )
        self.rigidbody:AddForce( self.forces.up )
        self.rigidbody:AddForce( self.forces.drag )
    else
        self:GetPlayerAndRigidbody()
    end

end


function Gadget:ProcessKeys()

    if Input.GetKeyDown( KeyCode.Keypad9 ) then
      self.force = self.force + 250
      Debug.Log("Speed set to "..tostring(self.force))

    end
    
    if Input.GetKeyDown( KeyCode.Keypad7 ) then
      self.force = self.force - 250
      Debug.Log("Speed set to "..tostring(self.force))

    end
    
    if Input.GetKeyDown( KeyCode.Keypad6 ) then
      self.drag = self.drag + 25
      Debug.Log("Drag set to "..tostring(self.dragspeed))

    end
    
    if Input.GetKeyDown( KeyCode.Keypad4 ) then
      self.drag = self.drag - 25
      Debug.Log("Drag set to "..tostring(self.dragspeed))
    end 

end


function Gadget:Update()

  	if ( not HBU.MayControle()  or  HBU.InSeat()  or  HBU.InBuilder() ) then return ; end
	
    self:ProcessKeys()
    self:AddForceToCamera()

end


function Gadget:OnDestroy() 
    Camera.main:GetComponentInParent("rigidbody_character_motor").enabled = true
    self.rigidbody = nil
    self.player = nil
end
