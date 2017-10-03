local QuantumCube = {}

function QuantumCube:Awake()

    Debug.Log("QuantumCube:Awake()")

    self.keys = {
        lmb     = HBU.GetKey("UseGadget"),
        rmb     = HBU.GetKey("UseGadgetSecondary"),
        inv     = HBU.GetKey("Inventory"),
        zoomIn  = HBU.GetKey("ZoomIn"),
        zoomOut = HBU.GetKey("ZoomOut"),
        run     = HBU.GetKey("Run"),
        shift   = HBU.GetKey("LeftShift"),
        control = HBU.GetKey("Control"),
        escape  = HBU.GetKey("Escape"),
    }

    self.Lines = {}

    self.Lights = {}

    self.DefaultDestroyObjects = {
        {self, "disabled"},
        {self, "target"},
        {self, "vehicle"},
        {self, "browser"},
    }

    self.browserArgs = {
        "",
        {"Vehicle",},
        {"WorkshopDownloaded", "WorkshopUploaded", "Favorite"},
        function(...) self:OnBrowserAssetSelected(...) end,
        function()    self:OnBrowserCancel()           end,
    }

    self.print = function(...) local sTab = {} ; for k,v in pairs({...}) do sTab[k] = tostring(v) ; end ; GameObject.FindObjectOfType("HBChat"):AddMessage("[QuantumCube]",table.concat(sTab," ")) ; print(table.concat(sTab,"  ")) ; end

    self.tick              = 0

    self.ResetVarsComplete = false

    self:ResetVars(true,0)

    self.debug             = false

end

function QuantumCube:ResetVars(override,phase)
    if self.ResetVarsComplete and not override and not phase then return end
    phase = phase or -5
    self.phase = phase
    if self.ResetVarsComplete and not override then return end
    self.ResetVarsComplete    = true
    self.distanceSpeed        = 0.2
    self.killBrowser          = false
    self.killBrowserNextFrame = false
    self.lastScrollTime       = 0.0
    self.launchVelocity       = Vector3.zero
    self.launchLastPos        = Vector3.zero
    self.launchVelocityMult   = 20
    self.dropOnSpawn          = false
    self.freezePosition       = false
    self.freezeRotation       = false
    self.rotationMod          = false
    if not self.targetDistance         then self.targetDistance = 10;            end
    if not self.targetDistanceFromSave then self.targetDistanceFromSave = false; end
    if     self.vehicle                then self.vehicle = false ; end
    if     self.browser                then self:DestroyIfPresent(self,"browser") ; end
    HBU.EnableGadgetMouseScroll() ; print("HBU.EnableGadgetMouseScroll()")
end

function QuantumCube:Null(obj)   if not obj or      Slua.IsNull(obj) then return true end return false end
function QuantumCube:Exists(obj) if     obj and not Slua.IsNull(obj) then return true end return false end


function QuantumCube:DestroyIfPresent(parent, gameObjectName, doNotNilLuaObject)
    if    not parent or type(gameObjectName) ~= "string" or not parent[gameObjectName] then return false; end
    if    not Slua.IsNull(parent[gameObjectName])
    then
          if      gameObjectName == "browser"
          or      string.sub(tostring(parent[gameObjectName]),-23) == "(UnityEngine.Texture2D)"
          or      string.sub(tostring(parent[gameObjectName]),-18) == "(UnityEngine.Font)"
          then    if self.debug then print("GameObject.Destroy("..gameObjectName..") : "..tostring(parent[gameObjectName])) ; end            ; GameObject.Destroy(parent[gameObjectName])
          elseif  parent[gameObjectName].gameObject
          then    if self.debug then print("GameObject.Destroy("..gameObjectName..").gameObject : "..tostring(parent[gameObjectName])) ; end ; GameObject.Destroy(parent[gameObjectName].gameObject)
          else    if self.debug then print("GameObject.Destroy("..gameObjectName..") : "..tostring(parent[gameObjectName])) ; end            ; GameObject.Destroy(parent[gameObjectName])
          end
    end
    if not doNotNilLuaObject then parent[gameObjectName] = false ; end
    return true
end


function QuantumCube:DestroyObjects(...)
    local except_these_objects = {...}
    for k,v in pairs(except_these_objects) do except_these_objects[tostring(v)] = true end
    if self and self.DefaultDestroyObjects
    then
        for k, v in pairs(self.DefaultDestroyObjects)
        do
            local doDestroy = true
            if    v and v[1] and type(v[2]) == "string" and v[1][v[2]] and not Slua.IsNull( v[1][v[2]] ) and not except_these_objects[v[2]]
            then  self:DestroyIfPresent(v[1], v[2])
            end
        end
    end
    self:RemoveLine("ALL")
end


function QuantumCube:OnDestroy()
    print("QuantumCube:OnDestroy()")
    self:DestroyObjects()
    print("HBU.EnableGadgetMouseScroll()")
    HBU.EnableGadgetMouseScroll()
end


function QuantumCube:HandleBrowser()

    if      self.killBrowser and self.browser and not self.killBrowserNextFrame
    then
            self.killBrowserNextFrame = true

    elseif  self.killBrowserNextFrame
    then
            print("QuantumCube:Destroy(self.browser)")
            self:DestroyObjects()
            self:ResetVars(true,0)

    elseif  not self.browser
    and     HBU.MayControle()
    and     ( self.keys.rmb.GetKeyUp() or self.keys.inv.GetKey() > 0.1 )
    then
            print("QuantumCube:OpenBrowser()")
            self.browser = self:OpenBrowser()
            self:DestroyIfPresent(self, "disabled")

    elseif  self.keys.escape.GetKeyDown()  and self.browser
    then
            self:DestroyObjects()
            self:ResetVars(true,0)
    end

end


function QuantumCube:UpdateTarget()

    if not self.target then return; end

    local scroll = Input.GetAxis("Mouse ScrollWheel")

    if scroll == 0 then scroll = self.keys.zoomIn.GetKey() - self.keys.zoomOut.GetKey() end

    local speedMult = 1.0

    speedMult = 5 - math.min(1,(os.clock() - self.lastScrollTime))*4

    if self.keys.run.GetKey() > 0.1 then speedMult = speedMult*2.0 end

    if (scroll > 0) then
        self.targetDistance = math.max( 1, self.targetDistance + (self.targetDistance*0.05*speedMult) )
    end

    if (scroll < 0) then
        self.targetDistance = math.max( 1, self.targetDistance - (self.targetDistance*0.05*speedMult) )
    end

    if scroll ~= 0 then self.lastScrollTime = os.clock() end

    --smooth move target
    local   targetDist = Vector3.Distance(Camera.main.transform.position, self.target.transform.position)
    local   targetPos  = Vector3.zero
    local   targetRot  = Vector3.zero

    if      self.freezePosition
    then
            targetPos        = self.target.transform.position
            targetRot        = Camera.main.transform.rotation
            self.rotationMod = targetRot

    elseif  not self.freezePosition
    then
            targetPos = Camera.main.transform.position + Camera.main.transform.forward * self.targetDistance

            if    self.rotationMod
            then  targetRot  = self.rotationMod
            else  targetRot  = Quaternion.LookRotation(Vector3.Scale(Camera.main.transform.forward, Vector3(1, 0, 1)), Vector3.up)
            end
    end

    if self.phase < 6
    then
        local launchVelocity = targetPos - self.target.transform.position
        if    math.abs(launchVelocity.y) > math.abs(launchVelocity.x*1.5)
        and   math.abs(launchVelocity.y) > math.abs(launchVelocity.z*1.5)
        then  launchVelocity = Vector3( 0, launchVelocity.y, 0)
        end
        launchVelocity = Vector3( math.max( -10000, math.min( 10000, launchVelocity.x ) ),  math.max( -10000, math.min( 10000, launchVelocity.y ) ),  math.max( -10000, math.min( 10000, launchVelocity.z ) )  )
        self.launchVelocity = launchVelocity
    end

    self.target.transform.position = Vector3.Lerp(self.target.transform.position, targetPos, Mathf.Clamp01(Time.deltaTime * 20.0))
    self.target.transform.rotation = targetRot

    --draw line
    local i = 1
    local a = Camera.main.transform:TransformPoint(Vector3(-0.3, -0.5, 0))
    local b = Camera.main.transform:TransformPoint(Vector3(0, 0, targetDist * 0.8))
    local c = self.target.transform.position
    if self.Lines and #self.Lines > 0
    then
        for k,v in pairs(self.Lines) do
            if v.line and not Slua.IsNull(v.line) then
                for i = 1, v.line.positionCount do
                    local factor = (i - 1.0) * (1.0 / v.line.positionCount)
                    v.line:SetPosition(i - 1, self:Bezier(a, b, c, factor))
                end
            end
        end
    end

end


function QuantumCube:Bezier(a, b, c, f)
    --return bezier point between a,b,c using factor f (0-1)
    if not a or not b or not c or not f then return Vector3.zero ; end
    return Vector3.Lerp( Vector3.Lerp(a, b, f), Vector3.Lerp(b, c, f), f)
end


function QuantumCube:CreateCantSpawn()
    if not self.disabled or Slua.IsNull(self.disabled)
    then
        self.disabled = HBU.Instantiate("Panel", HBU.menu.gameObject.transform:Find("Foreground").gameObject)
        HBU.LayoutRect(self.disabled, Rect((Screen.width / 2) - 100, (Screen.height / 2) - 25, 200, 50))
        self.disabled:GetComponent("Image").color = Color(0.2, 0.2, 0.2, 1)
        self.disabledText = HBU.Instantiate("Text", self.disabled)
        local text = self.disabledText:GetComponent("Text")
        text.color = Color(1.0, 1.0, 1.0, 1.0)
        text.text = HBU.GetSpawnError(self.assetPath)
        text.alignment = TextAnchor.MiddleCenter
    end
end


function QuantumCube:RemoveLine(name)
    if not self or not self.Lines then return ; end
    if not name then name = "" ; end
    local toRemove = {}
    for k,v in pairs(self.Lines) do
        if      name == "ALL"  or  ( name ~= "" and v.name and string.find(v.name,name) )  or  ( v.line and Slua.IsNull(v.line) )
        then    toRemove[#toRemove+1] = k ; if self.Lines[k] and self.Lines[k].line and not Slua.IsNull(self.Lines[k].line) then self:DestroyIfPresent(self.Lines[k],"line",true) ; end ; if self.Lights[k] and self.Lights[k].light and not Slua.IsNull(self.Lights[k].light) then  self:DestroyIfPresent(self.Lights[k],"light",true)   ; end
        end
    end
    for i = #toRemove,1,-1 do
        if self.Lines[toRemove[i]]  then table.remove(self.Lines, toRemove[i]) end
        if self.Lights[toRemove[i]] then table.remove(self.Lights,toRemove[i]) end
    end
end


function QuantumCube:CreateLine(parent,name,lineStartColor,lineEndColor,lineWidth,addLight,lightColor,lightRange,lightIntensity)
    if not self then return false ; end
    if not self.Lines  then self.Lines  = {} ; end
    if not self.Lights then self.Lights = {} ; end

    addLight        = addLight        or false
    lineStartColor  = lineStartColor  or Color.red
    lineEndColor    = lineEndColor    or Color.red
    lightColor      = lightColor      or Color.red
    lightRange      = lineRange       or 20
    lightIntensity  = lightIntensity  or 5
    lineWidth       = lineWidth       or 0.1

    if not parent or Slua.IsNull(parent) then return ; end
    if type(name) ~= "string" or type(name) ~= "number" then name = "Line "..tostring(#self.Lines+1) ; else name = tostring(name) ; end
    local mat            = Resources.Load("Commons/LineMaterial")
    local line           = parent:AddComponent("UnityEngine.LineRenderer")
    line.material        = mat
    line.widthMultiplier = lineWidth
    line.positionCount   = 20
    line.useWorldSpace   = true
    line.startColor      = lineStartColor
    line.endColor        = lineEndColor
    local light          = parent:AddComponent("UnityEngine.Light")
    light.color          = lightColor
    light.range          = lightRange
    light.intensity      = lightIntensity
    light.shadows        = LightShadows.None
    if not self.Lines  then self.Lines  = {} end
    if not self.Lights then self.Lights = {} end
    self.Lines[#self.Lines+1]   = { name = name, line  = line  }
    self.Lights[#self.Lights+1] = { name = name, light = light }
    return self.Lines[#self.Lines]
end


function QuantumCube:SetLineColor(col)
    col = col or Color(math.random(0,100000)*0.00001,math.random(0,100000)*0.00001,math.random(0,100000)*0.00001,1)
    for k,v in pairs(self.Lines) do
        if v and v.line and not Slua.IsNull(v.line)
        then
            v.line.startColor = Color.green;
            v.line.endColor   = Color.green;
            if self.Lights and self.Lights[k] and self.Lights[k].light and not Slua.IsNull(self.Lights[k].light) then self.Lights[k].light.color = Color.green ; end

        elseif  self.RemoveLine
        then    self:RemoveLine("ALL") ; return
        end
    end
end


function QuantumCube:CreateTarget()

    if self.target and self:Exists(self.target) then return; end

    -- local mat = Resources.Load("Commons/LineMaterial")
    local mat2 = Resources.Load("Commons/SpawnEffectMaterial")

    --create gameObject from resources
    local prefab = Resources.Load("Commons/SphereUVMapped")
    self.target = GameObject.Instantiate(prefab)

    --load targetDistance from save file, if not yet loaded.
    self.targetDistance = tonumber(HBU.LoadValue("quantumCubeSave", "targetDistance")) or 5.0

    --load resources
    --assign material to the line renderer and setup its points + width and color
    self.target:GetComponent("MeshRenderer").sharedMaterial = mat2

    --position the target infront of camera
    self.target.transform.position = Camera.main.transform.position + Camera.main.transform.forward * self.targetDistance

    self:CreateLine(self.target,"Line")

end

function QuantumCube:OnBrowserAssetSelected(assetPath)
    self:DestroyIfPresent(self, "browser")
    if type(assetPath) ~= "string" or assetPath == "" then return; end
    self:SetAssetPath(assetPath)
    --print("HBU.EnableMouseLock()") ; HBU.EnableMouseLock()
end

function QuantumCube:OnBrowserCancel()
    self:DestroyIfPresent(self, "browser")
    --print("HBU.EnableMouseLock()") ; HBU.EnableMouseLock()
end

function QuantumCube:OpenBrowser()
    if not self.browserArgs then return end
    return HBU.OpenBrowser(self.browserArgs[1],self.browserArgs[2],self.browserArgs[3],self.browserArgs[4],self.browserArgs[5],self.browserArgs[6],self.browserArgs[7],self.browserArgs[8],self.browserArgs[9])
end

function QuantumCube:SetAssetPath(assetPath)
    if type(assetPath) ~= "string" or assetPath == "" then return ; end
    self.assetPath = tostring(assetPath)
    HBU.SaveValue("quantumCubeSave", "assetPath", assetPath)
    if self.debug then print("QuantumCube:SetAssetPath() : INFO : self.assetPath = "..tostring(assetPath)) ; end
end


function QuantumCube:Update()

    self.tick = self.tick + 1

    if self.tick < 2 then return ; end

    local mayControl = HBU.MayControle()

    if      HBU.InSeat()   or  HBU.InBuilder()  or  not self.phase
    then
            self:DestroyObjects()
            self:ResetVars()
            return

    elseif  self.phase < 0
    then
            self.phase = self.phase + 1
            if self.debug then print("self.phase = "..tostring(self.phase)) end
            return

    elseif  self.phase == 0   -- and  not self.browser
    then
            if self.target then self:DestroyIfPresent(self, "target"); return; end

            if self.disabled and self.tick % 5 == 0 and self.assetPath and HBU.CanSpawnVehicle(self.assetPath) then self:DestroyIfPresent(self, "disabled") ; self.disabled  = false ; end

            if  mayControl  and  not self.browser  and  self.keys.lmb.GetKeyDown() then

                if not self.assetPath then
                    self.assetPath = HBU.LoadValue("quantumCubeSave", "assetPath") or ""
                    if self.debug then print('HBU.LoadValue("quantumCubeSave", "assetPath")') ; end
                end

                if  self.assetPath and self.assetPath ~= "" and HBU.CanSpawnVehicle(self.assetPath)
                then
                    self:DestroyIfPresent(self,"disabled")
                    HBU.SaveValue("quantumCubeSave", "assetPath", self.assetPath)
                    print("Spawn: "..tostring(self.assetPath))
                    self.phase = 1
                    HBU.DisableGadgetMouseScroll() ; print("HBU.DisableGadgetMouseScroll()")
                    self:CreateTarget()
                    self.spawnTime = os.clock()
                    if self.debug then print("self.phase = "..tostring(self.phase)) end

                    return
                else
                    self:CreateCantSpawn()
                end
            end

            self:HandleBrowser()

    elseif self.phase and self.phase > 0
    then
            if mayControl and self.keys.control.GetKey() > 0.1 then self.freezePosition = true ; elseif self.freezePosition and self.keys.control.GetKey() == 0 then self.freezePosition = false ; end

            self:UpdateTarget()


            if              os.clock() > self.spawnTime + 2.5
            and     ( not self.vehicle or Slua.IsNull(self.vehicle) )
            then
                    self.vehicle   = HBU.SpawnVehicle(Vector3(0.0001,-2000,0.0001), Quaternion.identity, self.assetPath)
                    self.spawnTime = 999999999999999999
                    HBU.InitializeVehicle(self.vehicle)
                    return

            elseif  mayControl and not self:Exists(self.vehicle)
            then
                    if     self.keys.lmb.GetKeyDown()
                    then
                            self.dropOnSpawn = not self.dropOnSpawn;
                            local curColor = Color.yellow
                            if not self.dropOnSpawn then curColor = Color.red end
                            self.spawnTime = os.clock()
                            for k,v in pairs(self.Lines) do
                                if v and v.line and not Slua.IsNull(v.line)
                                then
                                    v.line.startColor = curColor
                                    v.line.endColor   = curColor
                                    if self.Lights and self.Lights[k] and self.Lights[k].light and not Slua.IsNull(self.Lights[k].light) then self.Lights[k].light.color = curColor ; end
                                else
                                    self:RemoveLine()
                                    return
                                end
                            end

                    elseif  self.keys.rmb.GetKeyUp() and not self.browser
                    then
                            self:DestroyObjects()
                            self:ResetVars(true,0)
                            return
                    end

            elseif  mayControl and self:Exists(self.vehicle) and self.target
            then

                    if      self.phase < 5
                    then
                            self.phase = self.phase + 1
                            self.vehicle.transform.position = self.target.transform.position
                            self.vehicle.transform.rotation = self.target.transform.rotation
                            if self.debug then print("self.phase = "..tostring(self.phase)) end
                            return

                    elseif  self.phase == 5   and  HBU.InSeat()
                    then
                            HBU.DropVehicle(self.vehicle)
                            self.phase = 11
                            if self.debug then print("self.phase = "..tostring(self.phase).." Drop Vehicle") end
                            return

                    elseif  self.phase == 5   and  self.keys.lmb.GetKeyUp()
                    then
                            HBU.DropVehicle(self.vehicle)
                            self.phase = 6
                            if self.debug then print("self.phase = "..tostring(self.phase).." Drop Vehicle") end
                            return

                    elseif  self.phase == 5   and  self.dropOnSpawn
                    then
                            HBU.DropVehicle(self.vehicle)
                            self.phase = 11
                            return

                    elseif  self.phase >= 6 and self.phase < 10  then  self.phase = self.phase + 1 ; if self.debug then print("self.phase = "..tostring(self.phase)) end ; return

                    elseif  self.phase == 10
                    then
                            self.phase = 11

                            if self.debug then print("self.phase = "..tostring(self.phase)) end

                            local forceMode = 2  --  Force modes from ForceMode table:   0=Force  1=Impulse  2=VelocityChange   5=Acceleration

                            if self.keys.run.GetKey() > 0.1 then self.launchVelocityMult = self.launchVelocityMult*2.0 end

                            if  self.vehicle and not Slua.IsNull(self.vehicle) and self.vehicle.transform.childCount > 0 then
                                for k = 0,self.vehicle.transform.childCount-1
                                do
                                    local v = self.vehicle.transform:GetChild(k)
                                    if v and not Slua.IsNull(v) then
                                          local rb = v:GetComponent("Rigidbody")
                                          if rb and not Slua.IsNull(rb) and rb.AddForce then rb:AddForce( self.launchVelocity*self.launchVelocityMult, 2) ; end
                                          if self.debug then print("Launch Velocity: "..tostring(self.launchVelocity*self.launchVelocityMult)) end
                                    end
                                end
                            end
                            return

                    elseif  self.phase >= 11 and self.phase < 15  then  self.phase = self.phase + 1 ; if self.debug then print("self.phase = "..tostring(self.phase)) end ; return

                    elseif  self.phase == 15
                    then
                            if self.debug then print("self.phase = "..tostring(self.phase)) end 
                            -- HBU.EnableGadgetMouseScroll() ; print("HBU.EnableGadgetMouseScroll()")
                            self.vehicle = false
                            self:DestroyObjects()
                            self:ResetVars(true)
                            HBU.SaveValue( "quantumCubeSave", "targetDistance", tostring(self.targetDistance) )
                            return
                    end


                    if  ( self.keys.rmb.GetKeyUp() and not self.browser ) or ( self.keys.escape.GetKeyUp() )
                    then    --ABORT
                            HBU.SaveValue( "quantumCubeSave", "targetDistance", tostring(self.targetDistance) )
                            self:DestroyObjects()
                            self:ResetVars(true)
                            return
                    end

                    self.vehicle.transform.position = self.target.transform.position
                    self.vehicle.transform.rotation = self.target.transform.rotation

                    for k,v in pairs(self.Lines) do
                        if v and v.line and not Slua.IsNull(v.line)
                        then
                            v.line.startColor = Color.green;
                            v.line.endColor   = Color.green;
                            if self.Lights and self.Lights[k] and self.Lights[k].light and not Slua.IsNull(self.Lights[k].light) then self.Lights[k].light.color = Color.green ; end
                        end
                    end

            end
    end

    return

end

-- function QuantumCube:FixedUpdate()
--     return
-- end

return QuantumCube
