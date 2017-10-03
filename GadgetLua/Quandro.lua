Quandro = {}

------------------------------------------------------------------------------------------------------------

function Quandro:Awake()
    print("Quandro:Awake()")
    if not UI then print("Quandro:Awake()  Could not find Global/Provider UI.") ; return ; end
    --self:Init()
end

------------------------------------------------------------------------------------------------------------

function Quandro:Init()

    -- self.crosshair_path = Application.persistentDataPath.."/Lua/ModLua/crosshair.png"

  --self.gameObject           = GameObject("Quandro")

    self.debug                = true

    self.rmb                  = HBU.GetKey("UseGadgetSecondary")
    self.lmb                  = HBU.GetKey("UseGadget")
    self.wheel                = { KeyUpData = { { tick = 0, }, { tick = 0, }, }, GetKey = function() return ( Input.GetAxis("Mouse ScrollWheel") * -1 ) ; end, GetKeyDown = function() local r = {false,false,false} ; local v = Input.GetAxis("Mouse ScrollWheel") ; if v ~= 0 then r[1] = true end ; if v > 0 then r[2] = true end ; if v < 0 then r[3] = true end ; return unpack(r) ; end,  GetKeyUp = function() if not self or not self.keys or not self.keys.wheel or not self.keys.wheel.KeyUpData or not self.tick then return false ; end ; local a_index,b_index = (self.tick-1)%2+1,(self.tick)%2+1 ; local d = self.keys.wheel.KeyUpData ; if self.tick ~= d[b_index].tick then d[b_index].tick = self.tick ; for k,v in pairs({self.keys.wheel.GetKeyDown()}) do d[b_index][k] = v ; end ; end ; if d[a_index].tick == self.tick - 1 then return d[a_index][1],d[a_index][2],d[a_index][3] ; else return false,false,false  ; end ; end, }
    self.control              = HBU.GetKey("Control")
    self.shift                = HBU.GetKey("Shift")
    self.alt                  = HBU.GetKey("Alt")
    self.move                 = HBU.GetKey("Move")                       -- Default: W / S
    self.strafe               = HBU.GetKey("Strafe")                     -- Default: D / A
    self.jump                 = HBU.GetKey("Jump")                       -- Default: Space
    self.run                  = HBU.GetKey("Run")                        -- Default: Left-Shift
    self.crouch               = HBU.GetKey("Crouch")                     -- Default: C
    self.inv                  = HBU.GetKey("Inventory")
    self.printscreen          = { GetKey = function() if Input.GetKey(KeyCode.SysReq)  then return 1 else return 0 ; end ; end, GetKeyDown = function() return Input.GetKeyDown(KeyCode.SysReq)  ; end,  GetKeyUp = function() return Input.GetKeyDown(KeyCode.SysReq)  ; end, }

    --  User Settings
    self.sphereRadius         = 9
    self.sphereRotation       = 0
    self.sphereRotationTarget = 0
    self.sphereOrgMod         = Vector3( 0.0, -0.0,  0.000 )
    self.rowOrgMod            = Vector3( 0.0,  0.0,  0.000 )
    self.sphereColor          = Color(   0,0,  0.0,  0.995 )
    self.sphereScale          = self.sphereRadius*3
    self.quadScale            = 1
    self.originScale          = Vector3( 0.2, 0.2, 0.2 )
    self.columnCount          = 36
    self.scrollSpeed          = 360/self.columnCount
    self.lightColor           = Color( 1.00,     1.00,   1.00, 0.1 )
    self.lightPosition        = Vector3(   0,    1,   0   )
    self.lightColorDir        = false
    self.lightRange           = 200
    self.lightIntensity       = 1
    self.lightShadows         = LightShadows.None
    self.angleSensitivity     = 3.5
    self.rowVerticalGap       = 7.5
    self.textFontSize         = 13
    self.textPosOffset        = Vector3(0,self.originScale.x*-0.55,0)

    --  Script Variables
    self.tick                 = 0
    self.targetID             = 0
    self.targetPos            = Vector2(Screen.width/2, Screen.height/2)
    self.targetScale          = Vector3.one*self.quadScale
    self.targetScaleMin       = Vector3.one*self.quadScale
    self.targetScaleMax       = Vector3.one*self.quadScale*4
    self.targetQuad           = false
    self.tick                 = 0
    self.makeQuadTick         = 0
    self.TextColors           = { Color(1,0.2,0,1), Color.green, Color.yellow }
    self.shader               = Shader.Find("Legacy Shaders/Transparent/Diffuse")
    self.visible              = false
    self.InBuilder            = false
    self.quads_just_created   = false
    self.filter               = ""
    self.parent               = HBU.menu.transform:Find("Foreground").gameObject

    self:CreateUIOrigin()
    self:CreateSphere()

    if not SharedVars then SharedVars = {} ; end

    QuantumCube = self:GetQuantumCube()
    QuantumCube:Awake()

    return

end


function Quandro:SetupCpuTime()
    self.cpu              = { new = true, tick = 0, startTime = os.clock(), currentTime = os.clock(), totalTime = 0, updateStart = os.clock(), updateEnd = os.clock(), updateTotal = 0, percent = "0%", timeDelta = Time.deltaTime, fps = 1/Time.deltaTime } 
    if not CPU then CPU = {} ; end
    CPU.Quandro = self.cpu
end


function Quandro:SetCpuTime(start)
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
    if not CPU then CPU = {} ; end
    if not CPU.Quandro then CPU.Quandro = self.cpu ; end
    return
end


------------------------------------------------------------------------------------------------------------

function Quandro:CreateUIOrigin()
    if not self then return end
    if self.ui_origin and not Slua.IsNull(self.ui_origin) then return end
    self.ui_origin = GameObject()
    if  self.ui_origin
    then
        GameObject.Destroy(self.ui_origin:GetComponentInChildren("UnityEngine.Rigidbody"))
        self.ui_origin.transform.position   = UI.cam.position
        self.ui_origin.transform.localScale = self.originScale
        self.ui_origin.name = "player_ui"
    end
end

------------------------------------------------------------------------------------------------------------

function Quandro:CreateSphere()

    if  not self then return end

    if  not  self.sphere_texture  or Slua.IsNull(self.sphere_texture)
    then
        if    TextureCache and TextureCache.GetSphereTexture
        then
              self.sphere_texture = TextureCache.GetSphereTexture(self.sphereColor)
              if self.sphere_texture then self.sphere_texture_from_file = false ; end
        end
        -- if    not self.sphere_texture
        -- then
        --       self.sphere_texture_from_file = true
        --       self.sphere_texture = HBU.LoadTexture2D(Application.persistentDataPath .. "/Lua/GadgetLua/sphere.png")
        --       if self.sphere_texture
        --       then
        --           self.sphere_texture.wrapMode   = 1 ---  0 Repeats the texture which bleeds bottom of texture through to top.   1 Clamps the texture.
        --       end
        -- end
    end

    self.sphere                  = GameObject.CreatePrimitive(PrimitiveType.Sphere)
    GameObject.Destroy(self.sphere:GetComponent("Collider"))
    self.sphereCanvasGroup       = self.sphere:AddComponent("UnityEngine.CanvasGroup")
    self.sphereCanvasGroup.alpha = 1
    local sha = self.shader or Shader.Find("Legacy Shaders/Transparent/Diffuse")
    local sp_scale = self.sphereRadius*2 -- this is the important one
    self.sphere.transform.localScale = Vector3.one*sp_scale

    local r = self.sphere:GetComponent("Renderer")
    r.material.mainTexture = self.sphere_texture
    r.material.shader = sha
    r.sortingOrder = 1
    r.material.color = self.sphereColor

    self.sphere.transform:SetParent(self.ui_origin.transform, false)

    self.sphere_light                          = self.ui_origin:AddComponent("UnityEngine.Light")
    self.sphere_light.color                    = self.lightColor
    self.sphere_light.range                    = self.lightRange
    self.sphere_light.intensity                = self.lightIntensity
    self.sphere_light.shadows                  = self.lightShadows
    self.sphere_light.transform.localPosition  = self.lightPosition

    self.sphereAudio                          = self.ui_origin:AddComponent("UnityEngine.AudioSource")

    local mf = self.sphere:GetComponent("MeshFilter")
    if mf then
      local mesh = mf.mesh
      for i = 0, mesh.subMeshCount-1, 1 do
        local triangles = mesh.triangles;
        for t = 1, #triangles, 3 do
          local temp = triangles[t + 0]
          triangles[t + 0] = triangles[t + 1]
          triangles[t + 1] = temp
        end
        mesh.triangles = triangles
      end
    end

end

------------------------------------------------------------------------------------------------------------

function Quandro:ResetTarget()
    self.targetID,self.targetPos,self.targetScale,self.targetQuad = 0,Vector2(Screen.width/2, Screen.height/2), Vector3.one*self.quadScale, false
    self:SetTargetLabel("")
end

------------------------------------------------------------------------------------------------------------

--[[
function Quandro:CreateQuads(filter)

  filter = tostring( filter or "" ) or ""

  if    not self.filter_last then self.filter_last = filter ; end
  if    not self.filter      then self.filter      = filter ; end

  if    ( not self.ImageList  or  self.filter_last ~= self.filter )
  and   TextureCache and TextureCache.GetVehicleImageList and TextureCache.Textures
  then
        self.filter = filter
        self.filter_last = filter
        if    self.filter == ""
        then  self.ImageList = TextureCache.GetVehicleImageList()
        else  self.ImageList = {} ; for k,v in pairs(TextureCache.Textures) do if v.file_name and string.find(string.lower(v.file_name),"/vehicle/.*"..filter) then self.ImageList[#self.ImageList+1] = v.file_name  ; end ; end
        end
        self:ResetTarget()
        if  self.quads and #self.quads > 0  then   for k,v in pairs(self.quads) do  if v and v.obj and not Slua.IsNull(v.obj) then GameObject.Destroy(v.obj) ; end ; end ; self.quads = {}   ; end
  end

  if not self.quads then self.quads = {} ; end

  if #self.quads == #self.ImageList then return ; end

  local sha = self.shader or Shader.Find("Legacy Shaders/Transparent/Diffuse")

  local col_count = self.columnCount -- target column count
  local row_count = math.ceil(#self.ImageList/col_count)
  local cur_index = #self.quads +1
  if self.debug then print("Quandro:CreateQuads() -- Starting at... " .. cur_index .. " per row="..row_count) end
  local last_index = math.min(cur_index + col_count -1, #self.ImageList)

  local col         = 0
  local row         = math.floor(cur_index/row_count)
  local org         = Vector3.zero
  local verticalGap = self.rowVerticalGap -- degrees gap between items 
  for k = cur_index,last_index do
      local v = self.ImageList[k]
      if  TextureCache and TextureCache.TextureNames 
      then

          local go = GameObject.CreatePrimitive(PrimitiveType.Quad)

          if not go then print("failed to make quad! " .. v) ; return ; end

          GameObject.Destroy(go:GetComponent("Collider"))
        --go.transform.position   = self.pointonsphereU( (verticalGap*row)-(verticalGap*(row_count+2)), (360/col_count)*col, self.sphereRadius, org.x+self.rowOrgMod.x, org.y+self.rowOrgMod.y, org.z+self.rowOrgMod.z)
        --go.transform.position   = self.pointonsphereU( (verticalGap*row)-(verticalGap*(row_count/2)), (360/col_count)*col, self.sphereRadius, org.x+self.rowOrgMod.x, org.y+self.rowOrgMod.y, org.z+self.rowOrgMod.z)
          go.transform.position   = self.pointonsphereU( (verticalGap*row)-(verticalGap*(row_count/2)), (360/col_count)*col, self.sphereRadius, org.x+self.rowOrgMod.x, org.y+self.rowOrgMod.y, org.z+self.rowOrgMod.z)
          go.transform.rotation   = Quaternion.LookRotation(go.transform.position)
          go.transform:SetParent(self.ui_origin.transform, false)
          go.transform.localScale = Vector3.one*self.quadScale


          if    TextureCache.TextureNames[v] and TextureCache.TextureNames[v].file_name_short
          then  go.name = "Quandro."..TextureCache.TextureNames[v].file_name_short
          else  go.name = "CreateQuads"
          end

          local r = go:GetComponent("Renderer")

          if      TextureCache.TextureNames[v] and TextureCache.TextureNames[v].texture
          then    r.material.mainTexture = TextureCache.TextureNames[v].texture
          elseif  TextureCache.error_texture
          then    r.material.mainTexture = TextureCache.error_texture
          elseif  TextureCache.TextureNames.error_texture and TextureCache.TextureNames.error_texture.texture
          then    r.material.mainTexture = TextureCache.TextureNames.error_texture.texture
          end

          r.sortingOrder = 2

          if sha then r.material.shader = sha ; end

          local name = string.gsub(v,".*/",""):sub(1,-9)
          if    not self.lastQuadLetter or name:sub(1,1) ~= self.lastQuadLetter
          then  self.lastQuadLetter = name:sub(1,1) ; self.TextColors.selected = ( self.TextColors.selected or 0 )%#self.TextColors+1
          end

          local go2 = GameObject()
          go2.transform:SetParent(go.transform, false)

          local text_mesh = go2:AddComponent(TextMesh)
          text_mesh.name                  = "Quandro.quads.text_mesh"
          text_mesh.text                  = name
          text_mesh.fontSize              = self.textFontSize
          text_mesh.offsetZ               = 0
          text_mesh.anchor                = TextAnchor.MiddleCenter
          text_mesh.transform.localScale  = Vector3.one/10
          text_mesh.transform.position    = text_mesh.transform.position + self.textPosOffset
          text_mesh.color                 = self.TextColors[self.TextColors.selected or 1]
          text_mesh:GetComponent("Renderer").sortingOrder = 3

          self.quads[k] = { obj = go, text_mesh = go2, }

          col = col +1

          if   #self.quads == #self.ImageList
          then
                self.quads_just_created = true
                if self.debug then print("Last quad reached") end
          end
      end
  end


end
--]]

------------------------------------------------------------------------------------------------------------

function Quandro:CreateQuads(filter)

  filter = tostring( filter or "" ) or ""

  if    not self.filter_last then self.filter_last = filter ; end
  if    not self.filter      then self.filter      = filter ; end

  if    ( not self.ImageList  or  self.filter_last ~= self.filter )
  and   TextureCache and TextureCache.GetVehicleImageList and TextureCache.Textures
  then
        self.filter = filter
        self.filter_last = filter
        if    self.filter == ""
        then  self.ImageList = TextureCache.GetVehicleImageList()
        else  self.ImageList = {} ; for k,v in pairs(TextureCache.Textures) do if v.file_name and string.find(string.lower(v.file_name),"/vehicle/.*"..filter) then self.ImageList[#self.ImageList+1] = v.file_name  ; end ; end
        end
        self:ResetTarget()
        if  self.quads and #self.quads > 0  then   for k,v in pairs(self.quads) do  if v and v.obj and not Slua.IsNull(v.obj) then GameObject.Destroy(v.obj) ; end ; end ; self.quads = {}   ; end
        return
  end

  if not self.quads then self.quads = {} ; end

  if #self.quads == #self.ImageList then return ; end

  local sha = self.shader or Shader.Find("Legacy Shaders/Transparent/Diffuse")

  local max_angle = 360
  local col_count = self.columnCount -- target column count
  if    #self.ImageList < col_count*2 then col_count = math.floor(#self.ImageList/8) ; max_angle = 75 ; end
  local best_use  = 0
  for i = col_count-2,col_count+2 do
      if  i > 0 and (#self.ImageList/i)%1 > best_use then best_use=(#self.ImageList/i)%1 ; col_count = i ; end
  end
  local row_count = math.ceil(#self.ImageList/col_count)
  if    row_count >= #self.ImageList then row_count = 1 ; end
  self.scrollSpeed = max_angle/col_count
  local cur_index = #self.quads +1
  local last_index = math.min(cur_index + row_count -1, #self.ImageList)

  if self.debug then print("Quandro:CreateQuads() -- Starting at... " .. cur_index .. "  row_count="..tostring(row_count).."  col_count="..tostring(col_count).."  cur_index="..tostring(cur_index).."  last_index="..tostring(last_index).."  #self.quads="..tostring(#self.quads).."  #self.ImageList="..tostring(#self.ImageList) ) end

  local col         = math.ceil(cur_index/row_count)
  local row         = 0
  local org         = Vector3.zero
  local verticalGap = self.rowVerticalGap -- degrees gap between items 
  for k = cur_index,last_index do

      local v = self.ImageList[k]

      if  TextureCache and TextureCache.TextureNames 
      then

          local go = GameObject.CreatePrimitive(PrimitiveType.Quad)

          if not go then print("failed to make quad! " .. v) ; return ; end

          GameObject.Destroy(go:GetComponent("Collider"))
          go.transform.position   = self.pointonsphereU( (verticalGap*(row_count/2)*-1)+(verticalGap*row), max_angle - ((max_angle/col_count)*col), self.sphereRadius, org.x+self.rowOrgMod.x, org.y+self.rowOrgMod.y, org.z+self.rowOrgMod.z)
          go.transform.rotation   = Quaternion.LookRotation(go.transform.position)
          go.transform:SetParent(self.ui_origin.transform, false)
          go.transform.localScale = Vector3.one*self.quadScale


          if    TextureCache.TextureNames[v] and TextureCache.TextureNames[v].file_name_short
          then  go.name = "Quandro."..TextureCache.TextureNames[v].file_name_short
          else  go.name = "CreateQuads"
          end

          local r = go:GetComponent("Renderer")

          if      TextureCache.TextureNames[v] and TextureCache.TextureNames[v].texture
          then    r.material.mainTexture = TextureCache.TextureNames[v].texture
          elseif  TextureCache.error_texture
          then    r.material.mainTexture = TextureCache.error_texture
          elseif  TextureCache.TextureNames.error_texture and TextureCache.TextureNames.error_texture.texture
          then    r.material.mainTexture = TextureCache.TextureNames.error_texture.texture
          end

          r.sortingOrder = 2

          if sha then r.material.shader = sha ; end

          local name = string.gsub(v,".*/",""):sub(1,-9)
          if    not self.lastQuadLetter or name:sub(1,1) ~= self.lastQuadLetter
          then  self.lastQuadLetter = name:sub(1,1) ; self.TextColors.selected = ( self.TextColors.selected or 0 )%#self.TextColors+1
          end

          local go2 = GameObject()
          go2.transform:SetParent(go.transform, false)

          local text_mesh = go2:AddComponent(TextMesh)
          text_mesh.name                  = "Quandro.quads.text_mesh"
          text_mesh.text                  = name
          text_mesh.fontSize              = self.textFontSize
          text_mesh.offsetZ               = 0
          text_mesh.anchor                = TextAnchor.MiddleCenter
          text_mesh.transform.localScale  = Vector3.one/10
          text_mesh.transform.position    = text_mesh.transform.position + self.textPosOffset
          text_mesh.color                 = self.TextColors[self.TextColors.selected or 1]
          text_mesh:GetComponent("Renderer").sortingOrder = 3

          self.quads[k] = { obj = go, text_mesh = go2, }

          --col = col +1
          row = row + 1

          if   #self.quads == #self.ImageList
          then
                self.quads_just_created = true
                if self.debug then print("Last quad reached") end
          end
      end
  end

end

------------------------------------------------------------------------------------------------------------

function Quandro:SetSelectedVehicleHUD(assetPath)
    assetPath = assetPath or ( QuantumCube and QuantumCube.assetPath ) or (SharedVars and SharedVars.assetPath)
    local imagePath = string.gsub(assetPath,"[.][Hh][Bb][Aa]$","_img.png")
    local imageName = string.gsub(assetPath,".*/","")
          imageName = string.gsub(imageName,"[.][Hh][Bb][Aa]$","")
    if ( not file_exists or not file_exists(imagePath) ) and TextureCache and TextureCache.GetErrorTexture then imagePath = TextureCache.GetErrorTexture() ; end
    local x,y = 0,0
    if self.targetPos and ( self.targetPos.x ~= 0 or self.targetPos.y ~= 0 ) then x,y = self.targetPos.x,self.targetPos.y ; end
    if x == 0 and y == 0 then x = Screen.width/6 ; y = 256 + 16 ; end
    if self.selected_vehicle_hud  and self.selected_vehicle_hud.Destroy then self.selected_vehicle_hud:Destroy() ; self.selected_vehicle_hud = false ; end
    --                    UI.Image:New(            x,      y,    width,   height,         color,        file_name,   label_text,  label_font,   label_fontSize,      label_color,   label_layout,             panel_color        )
    self.selected_vehicle_hud = UI.Image:New(      x,      y,     128,     128,     Color(1,1,1,0.0),   imagePath,   imageName,   "Consolas",         13,           Color(1,1,0,1),        1,              Color(0.1,0.1,0.1,0)  )
    SharedVars.assetPath = assetPath
end

------------------------------------------------------------------------------------------------------------

function Quandro:HandleSelectedVehicleHUD()

    if not self or not self.selected_vehicle_hud then return ; end
    if Slua.IsNull(self.selected_vehicle_hud) then self.selected_vehicle_hud = false ; return ; end
    local x,y = self.selected_vehicle_hud.x,self.selected_vehicle_hud.y
    x =  x + math.max( -10, math.min(10, (Screen.width-64-8)-x ) )
    y =  y + math.max( -10, math.min(10, (64+18)-y ) )
    self.selected_vehicle_hud.x = x
    self.selected_vehicle_hud.y = y
    self.selected_vehicle_hud:SetPosition()
    if  self.selected_vehicle_hud.image and not Slua.IsNull(self.selected_vehicle_hud.image)
    then
        local curComp = self.selected_vehicle_hud.image:GetComponent("RawImage")
        if    curComp
        then
              self.selected_vehicle_hud.image:GetComponent("RawImage").color = Color(1,1,1, math.min (1, curComp.color.a+0.03 ) )
        end
    else
        self:SetSelectedVehicleHUD()
    end

end

------------------------------------------------------------------------------------------------------------

function Quandro:SetCrosshair(toggle)

    if toggle and self.crosshair and not Slua.IsNull(self.crosshair) then return end

    if                        toggle
    or      ( type(toggle) ~= "boolean" and not self.crosshair )
    then
            if    TextureCache.GetCrosshairTexture
            then
                  self.crosshair = HBU.Instantiate("RawImage",nil)
                  HBU.LayoutRect( self.crosshair,  Rect( Screen.width/2, Screen.height/2, TextureCache.crosshair.width, TextureCache.crosshair.height ) )
                  self.crosshair.name = "Crosshair"
                  self.crosshair.transform.pivot = Vector2(0.5,0.5)
                  self.crosshair:GetComponent("RawImage").texture = TextureCache.GetCrosshairTexture()
                  self.crosshair:GetComponent("RawImage").color   = Color(1,0,0,1)
            -- else
            --       if file_exists and file_exists(self.crosshair_path:sub(1,-5).."z.png") then self.crosshair_path = self.crosshair_path:sub(1,-5).."z.png" ; end
            --       if not self.crosshair_id or not TextureCache.Textures[self.crosshair_id] or Slua.IsNull(TextureCache.Textures[self.crosshair_id]) then self.crosshair_id = TextureCache.AddTexture(self.crosshair_path) ; end

            --       self.crosshair                                  = HBU.Instantiate("RawImage",nil)
            --       HBU.LayoutRect( self.crosshair, Rect( Screen.width/2, Screen.height/2, 64, 64 ) )
            --       self.crosshair.name                             = "Crosshair"
            --       self.crosshair.transform.pivot                  = Vector2(0.5,0.5)
            --       self.crosshair:GetComponent("RawImage").texture = TextureCache.Textures[self.crosshair_id].texture
            --       self.crosshair:GetComponent("RawImage").color   = Color(1,0,0,1)
            end

    elseif  self.crosshair
    then
            if not Slua.IsNull(self.crosshair) then GameObject.Destroy( self.crosshair ) ; end
            self.crosshair = false
    end

end

------------------------------------------------------------------------------------------------------------

function Quandro:StressTest()

   local t = {}
   for i = 1,100000 do t[#t+1] = math.random(1000000000,9999999999) end

end

------------------------------------------------------------------------------------------------------------

function Quandro:UpdateQuads()

    local scroll  = self.wheel.GetKey()
  --local shift   = self.shift.GetKey()
  --local alt     = self.alt.GetKey()
  --local control = self.control.GetKey()

    if        not self.visible or self.disabling then return end

    if        self.visible  and  not self.disabling  and  scroll ~= 0
    then      self.sphereRotationTarget = self.sphereRotationTarget+(scroll*self.scrollSpeed*-1)
    end

    self.sphereRotationTarget = self.sphereRotationTarget*0.9525

    if        math.abs(self.sphereRotationTarget) < 0.002  -- make it click into place
    then
              self.sphereRotationTarget = 0
              self.sphereRotation       = 0
    else
              if    math.abs(self.sphereRotation*2) < math.abs(self.sphereRotationTarget)
              then  self.sphereRotation = self.sphereRotationTarget*0.5 --(self.sphereRotationTarget*0.02)+scroll*-1
              else  self.sphereRotation = self.sphereRotationTarget*0.5 --(self.sphereRotationTarget*0.04)
              end
    end

     self.ui_origin.transform:Rotate(Vector3(0,self.sphereRotation,0))
--   self.ui_origin.transform.position = UI.cam.position + self.sphereOrgMod
     self.ui_origin.transform.position = Camera.main.transform.position + self.sphereOrgMod

    local bestAngActual  = 360
    local worstAngActual = 0
    local bestAng        = self.angleSensitivity
    local bestQuad       = false
    local bestID         = 0
    local bestPos        = Vector3.zero


    if self.quads and not self.disabling then
      for k = 1, #self.quads do
          local target = self.quads[k].obj
          if  target  and not Slua.IsNull(target)
          then
              local ang = Vector3.Angle( UI.cam.forward, target.transform.position - UI.cam.position )
              bestAngActual  = math.min( bestAngActual, ang )
              worstAngActual = math.max( worstAngActual, ang )
              if  ang < bestAng then bestAng,bestQuad,bestID = ang, target, k ; end
          end
      end
    end

    self.bestAngActual  = bestAngActual
    self.worstAngActual = worstAngActual

    if bestAngActual > 40 or self.quads_just_created  then self.ui_origin.transform:Rotate(Vector3(0,(worstAngActual+bestAngActual) * -0.5,0))   ; end

    if      bestID ~= self.targetID and self.targetID ~= 0
    then
            if  self.targetQuad then
                self.ShrinkTargets[self.targetID]                     = self.targetScale
                self.targetQuad:GetComponent("Renderer").sortingOrder                     = 7
                self.quads[self.targetID].text_mesh:GetComponent("Renderer").sortingOrder = 8
            end
    end

    if      bestID ~= 0  and  self.targetID ~= bestID
    then
            if    self.ShrinkTargets[bestID]
            then  self.targetScale   =  self.ShrinkTargets[bestID] ; self.ShrinkTargets[bestID] = nil
            else  self.targetScale   =  self.quads[bestID].obj.transform.localScale
            end
            bestQuad:GetComponent("Renderer").sortingOrder = 9
            self.quads[bestID].text_mesh:GetComponent("Renderer").sortingOrder = 10
            self.targetQuad    =  bestQuad
            self.targetID      =  bestID
            if self.crosshair then  self.crosshair:GetComponent("RawImage").color   = Color(0,1,0,1)  ;end

    elseif  bestID ~= 0 and self.targetID == bestID
    then
            self.targetScale = self.targetScale + ( ( self.targetScaleMax - self.targetScale ) * Time.deltaTime * 2 )
            bestQuad.transform.localScale = self.targetScale
            local bestPos = Camera.main:WorldToScreenPoint(bestQuad.transform.position)
            self.targetPos = bestPos

    elseif  bestID == 0
    then
            if self.crosshair then  self.crosshair:GetComponent("RawImage").color   = Color(1,0,0,1)  end
            if self.targetID ~= 0
            then
                self.ShrinkTargets[self.targetID]                     = self.targetScale
                self.targetQuad:GetComponent("Renderer").sortingOrder = 5
                self.quads[self.targetID].text_mesh:GetComponent("Renderer").sortingOrder = 6
                self.targetID = 0
                self.targetQuad = false
                self.targetScale = self.targetScaleMin
                self:SetTargetLabel("")
            end
    end

    if    self.quads_just_created and self.quads
    then
          self.quads_just_created = false
          for k,v in pairs(self.quads) do self.ShrinkTargets[k] = v.obj.transform.localScale end
    end

    for k,v in pairs(self.ShrinkTargets) do
        if    self.quads[k]
        and   not Slua.IsNull(self.quads[k].obj)
        then
              if      v.x > self.targetScaleMin.x+0.001
              then
                      if    v.x > (self.targetScaleMax.x-self.targetScaleMin.x)/2
                      and   v.x - ( ( v.x - self.targetScaleMin.x ) * Time.deltaTime * 1 ) < (self.targetScaleMax.x-self.targetScaleMin.x)/2
                      then
                            self.quads[k].obj:GetComponent("Renderer").sortingOrder = 5
                            self.quads[k].text_mesh:GetComponent("Renderer").sortingOrder = 6
                      end
                      local newScale = v - ( ( v - self.targetScaleMin ) * Time.deltaTime * 1 )
                      if    newScale.x <= self.targetScaleMin.x
                      then  self.quads[k].obj.transform.localScale = self.targetScaleMin
                      else  self.quads[k].obj.transform.localScale = newScale
                      end
                      self.ShrinkTargets[k] = newScale
              else
                      self.quads[k].obj.transform.localScale = self.targetScaleMin
                      self.quads[k].obj:GetComponent("Renderer").sortingOrder = 3
                      self.quads[k].text_mesh:GetComponent("Renderer").sortingOrder = 4
                      self.ShrinkTargets[k] = nil
              end
        else
              self.ShrinkTargets[k] = nil
        end
    end

    if    self.sphere_light and not Slua.IsNull(self.sphere_light) and UI and UI.Cam and UI.cam.position
    then  self.sphere_light.transform.pivot = self.pointoncircleU( self.tick/10%360, 5, Vector2( UI.cam.position.x, UI.cam.position.z ) )
    end

    if      self.targetID ~= 0
    and     self.ImageList[self.targetID]
    and     TextureCache
    and     TextureCache.TextureNames
    and     TextureCache.TextureNames[self.ImageList[self.targetID]]
    and     TextureCache.TextureNames[self.ImageList[self.targetID]].file_name_short
    then    self:SetTargetLabel(TextureCache.TextureNames[self.ImageList[self.targetID]].file_name_short)

    elseif  self.targetID ~= 0 and self.ImageList[self.targetID]
    then
          local file_name_short = string.gsub(self.ImageList[self.targetID],".*/","")
          file_name_short = string.gsub(file_name_short,"_[Ii][Mm][Gg][.][Pp][Nn][Gg]","")
          file_name_short = string.gsub(file_name_short,"[Hh][Bb][Aa]","")
          if not self.disabling then self:SetTargetLabel(file_name_short) end
    end

end


function Quandro:SetTargetLabel(inp1,inp2)

    if not self then return ; end

    if       type(inp1) == "string"
    then
            if      self.target_label  and  self.target_label.label  and not Slua.IsNull(self.target_label.label)
            then    if inp1 == "" then self.target_label:Destroy() ; self.target_label = false ; else self.target_label:SetLabel(inp1) ; end
            elseif  inp1 ~= "" and self.visible and not self.disabling
            then    self.target_label = UI.Label:New( Screen.width/2, Screen.height/2.9,     600,  50,  inp1,  nil,  25,  Color(1,1,0),  6,  Color(0,0,0,0.0) )
            end
    end

    if      type(inp2) == "string"
    then
            inp2 = string.gsub(inp2,"[\x5d\x5b]","")
            inp2 = string.gsub(inp2,"[\x2e][\x2a]","")
            if      self.filter_label  and  self.filter_label.label  and not Slua.IsNull(self.filter_label.label)
            then    if inp2 == "" then self.filter_label:Destroy() ; self.filter_label = false ; else self.filter_label:SetLabel(inp2) ; end
            elseif  inp2 ~= "" and self.visible and not self.disabling
            then    self.filter_label = UI.Label:New( Screen.width/2, Screen.height/2.9-50,  600,  50,  inp2,  nil,  25,  Color(1,1,0),  6,  Color(0,0,0,0.0) )
            end
    end

end

------------------------------------------------------------------------------------------------------------

function Quandro:HandleFilter()

    if not self or not UI or not UI.Input or not UI.Input.Get then return   ; end

    if not self.filter  then  self.filter = ""  ; end

    if not self.filter_id_last or self.filter_id_last == 0  then  self.filter_id_last = UI.Input.index  ; return ; end

    if    not self.visible
    -- or    self.disabling
    or    self.alt.GetKeyDown()
    or    self.control.GetKeyDown()
    or    not HBU.MayControle()
    then
          if    self.filter ~= ""
          then
                self.filter = ""
                self:SetTargetLabel(nil,"")
          end
          self.filter_id_last = UI.Input.index
          return
    end

    if      self.target_label  then self.target_label.panel_color = Color(self.target_label.panel_color.r,self.target_label.panel_color.g,self.target_label.panel_color.b,self.target_label.panel_color.a+0.04)  ; self.target_label.SetPanelColor(self.target_label) ; end
    if      self.filter_label  then self.filter_label.panel_color = Color(self.filter_label.panel_color.r,self.filter_label.panel_color.g,self.filter_label.panel_color.b,self.filter_label.panel_color.a+0.04)  ; self.filter_label.SetPanelColor(self.filter_label) ; end

    local filter_str, filter_id = UI.Input:Get()

    local filter_byte = string.byte(filter_str or "")

    if not filter_str or not filter_id or filter_id == self.filter_id_last then return ; end

    for i = self.filter_id_last+1, filter_id do
        filter_str,filter_id = UI.Input:Get(i)
        local filter_byte = string.byte(filter_str or "\n")
        if  filter_byte ~= 13
        then
            if    filter_byte == 8 then  self.filter = self.filter:sub(1,-6)
                                   else  self.filter = self.filter.."["..string.lower(filter_str).."].*"
            end
        end
    end

    self.filter_id_last = filter_id

    if    self.filter == ""
    then  self:SetTargetLabel(nil,"")
    else  self:SetTargetLabel(nil,"Filter: "..self.filter)
    end

end

------------------------------------------------------------------------------------------------------------

function Quandro:Update()

    if not self then return ; end
    self.tick = ( self.tick or 0 ) + 1
    if self.tick < 10 then return ; end
    self:SetCpuTime(true)

    if not UI or not UI.cam or not UI.cam.position then return ; end
    if not TextureCache or not TextureCache.AddTexture or not TextureCache.Textures or not TextureCache.TextureNames then return ; end

    if    HBU.InBuilder() or HBU.InSeat()
    then  self:OnDestroy(true) ; self.InBuilder = true ; return
    end

    if      HBU.InSeat()
    then
            if self.selected_vehicle_hud then self.selected_vehicle_hud:Destroy() ; self.selected_vehicle_hud = false ; end

    elseif  not self.selected_vehicle_hud and QuantumCube and QuantumCube.assetPath
    then    self:SetSelectedVehicleHUD()
    end

    if self.InBuilder or not ( self.ui_origin ) then self:Init() ; return ; end

    self:CreateQuads(self.filter)

    if  not SharedVars.assetPath and QuantumCube and self.ImageList and self.ImageList.firstFile then local assetPath = string.gsub(self.ImageList.firstFile,"_[Ii][Mm][Gg][.][Pp][Nn][Gg]$","") ; assetPath = assetPath..".hba" ; SharedVars.assetPath = assetPath ; QuantumCube:SetAssetPath(assetPath) ; print("Quandro : Selected : "..assetPath) end

    if  QuantumCube and not QuantumCube.assetPath and SharedVars.assetPath then QuantumCube:SetAssetPath(SharedVars.assetPath) ; print("Quandro : Selected : "..SharedVars.assetPath) end

    self:HandleSelectedVehicleHUD()

    self:HandleFilter()

    if      not self.visible and HBU.MayControle() and ( self.rmb.GetKeyUp() or self.inv.GetKeyUp() ) and not QuantumCube.target
    then
            self.visible = true
            self.disabling = false
            self.ShrinkTargets = {}
            self:SetCrosshair(true)
            self:SetTargetLabel("","")
            HBU.DisableGadgetMouseScroll()
            self.sphere:GetComponent("Renderer").material.color = Color(1,1,1,0)
            self.ui_origin:SetActive(self.visible)
            if QuantumCube then QuantumCube:Update() ; end
            self:SetCpuTime()
            return

    elseif  self.visible
    and     HBU.MayControle()
    and     (    self.rmb.GetKeyUp()  or  ( self.lmb.GetKeyUp()  and self.targetID ~= 0 )   )
    and     not self.disabling
    then
            if    not self.lmb.GetKeyUp()
            and   self.filter and self.filter ~= ""
            then  self.filter_last = self.filter ; self.filter = "" ; self:SetTargetLabel(nil,""); self:SetCpuTime() ; return
            else
                if self.lmb.GetKeyUp() and self.targetID ~= 0 and self.ImageList[self.targetID] and QuantumCube and QuantumCube.SetAssetPath then local assetPath = self.ImageList[self.targetID]:sub(1,-9)..".hba" ; QuantumCube:SetAssetPath(assetPath) ; print("Quandro : Selected : "..assetPath) ; end
                if not self.rmb.GetKeyUp() then self:SetSelectedVehicleHUD() ; end
                self.disabling = true
                --self:SetTargetLabel("","")
                self:SetCpuTime()
                return
            end

    elseif  not self.visible
    then
            if QuantumCube then QuantumCube:Update() ; end
            self:SetCpuTime()
            return
    end

    local   sphereColor = self.sphere:GetComponent("Renderer").material.color

    if      self.disabling and sphereColor.a-0.02 <= 0
    then
            sphereColor.a       = 0
            self.visible        = false
            self.disabling      = false
            self.filter         = ""
            self.filter_id_last = 0
            self:SetCrosshair(false)
            self:SetTargetLabel("","")
            HBU.EnableGadgetMouseScroll()
            self.ui_origin:SetActive(self.visible)
            return

    elseif  self.disabling
    then    sphereColor.a = sphereColor.a - 0.02

    elseif  sphereColor.a + 0.02 < self.sphereColor.a
    then    sphereColor.a = sphereColor.a + 0.02

    else    sphereColor.a = self.sphereColor.a
    end

    if sphereColor.a >= 0 and sphereColor.a <= self.sphereColor.a
    then
        self.sphere:GetComponent("Renderer").material.color = sphereColor
    end

    HBU.DisableGadgetMouseScroll()

    self:UpdateQuads()

    self:SetCpuTime()
end

------------------------------------------------------------------------------------------------------------

function Quandro.pointoncircleU(angle,radius,originX,originY,originZ) -- For Unity / Where Y is the Up/Down Axis
    if not angle then angle = 0 else angle = tonumber(angle) ; end
    if not radius or not angle then print("usage: math.pointoncircle(radius,angle)\n or\nusage: math.pointoncircle(radius,angle,originX,originY)\n or\nusage: math.pointoncircle(radius,angle,originVector)") ; return originX,originY,originZ ; end
    local outType = "number" -- "number", "table", "Vector"
    local localpi = 3.1415926535897932
    if    not originX and not originY and not originZ and Vector3 then outType = "Vector3" end
    if    not originX then originX = 0 end
    if    not originZ then originZ = 0 end
    if  type(originX) == "Vector"
    or  type(originX) == "table"
    then
        if      #originX == 3 and Vector3
        then    originX,originY,originZ = originX.x,originX.y,originX.z ;  outType = "Vector3"
        elseif  #originX == 2 and Vector2
        then    originX,originZ = originX.x,originX.z ; outType = "Vector2"
        elseif  originX.x and originX.y and originX.z
        then    originX,originY,originZ = originX.x,originX.y,originX.z ; if Vector3 then outType = "Vector3" else outType = "Vector" ; end
        elseif  originX.x and originX.y
        then    originX,originZ   = originX.x,originX.z ; if Vector2 then outType = "Vector2" else outType = "Vector" ; end
        end
    end
    if    not originY then originY = 0 end
    local x = radius * math.cos(angle * localpi / 180) + originX;
    local y = originY
    local z = radius * math.sin(angle * localpi / 180) + originZ;
    if ( x > -0.000001 and x < 0.000001 ) then x = 0 ; end
    if ( z > -0.000001 and z < 0.000001 ) then z = 0 ; end
    if      outType == "number"  then if z then return x,y,z ; else return x,y ; end
    elseif  outType == "Vector"
    and     originZ              then return Vector(x,y,z)
    elseif  outType == "Vector"  then return Vector(x,y)
    elseif  outType == "Vector3" then return Vector3(x,y,z)
    elseif  outType == "Vector2" then return Vector2(x,y)
    end
end

------------------------------------------------------------------------------------------------------------

function Quandro.pointonsphereU(...) -- For Unity
  local vars_config = {
          {"alt","number",0,},
          {"azu","number",0,},
          {"rad","number",0,},
          {"orgX","number",0},
          {"orgY","number",0},
          {"orgZ","number",0,},
        }

  local args = {...}
  if #args == 0 then print("usage: math.pointonsphere(altitude,azumuth,radius,orgX,orgY,orgZ)\n or\nusage: math.pointoncircle( Vector3(1,1,1), Vector3(2,2,2) )") ; return ; end
  local v = getvars(vars_config,...)
  local torad = 0.017453292519943
  if Vector3
  then
      return Vector3(
          v.orgX + v.rad * math.sin( v.azu * torad ) * math.cos( v.alt * torad ),
          v.orgY + v.rad * math.sin( v.alt * torad ),
          v.orgZ + v.rad * math.cos( v.azu * torad ) * math.cos( v.alt * torad )
         )
  else
      return Vector(
          v.orgX + v.rad * math.sin( v.azu * torad ) * math.cos( v.alt * torad ),
          v.orgY + v.rad * math.sin( v.alt * torad ),
          v.orgZ + v.rad * math.cos( v.azu * torad ) * math.cos( v.alt * torad )
        )
  end
end

------------------------------------------------------------------------------------------------------------

function Quandro:OnDestroy(partial)
    if   not partial
    then
        print("Quandro:OnDestroy()")
        HBU.EnableGadgetMouseScroll()
    end
    UI:CleanUp()
    if self.quads and #self.quads > 0 then
      local resetQuads = false
      for i,v in ipairs(self.quads) do
        resetQuads = true
        if v and v.obj and not Slua.IsNull(v.obj) then GameObject.Destroy(v.obj) end
      end
      if resetQuads then self.quads = {} ; end
    end
    if self.sphere          then  if not Slua.IsNull(self.sphere)             then GameObject.Destroy(self.sphere)         end ; self.sphere         = false ; end
    if self.sphere_texture  then  if self.sphere_texture_from_file and not Slua.IsNull(self.sphere_texture) then GameObject.Destroy(self.sphere_texture) end ; self.sphere_texture = false ; end
    if self.sphere_light    then  if not Slua.IsNull(self.sphere_light)       then GameObject.Destroy(self.sphere_light)   end ; self.sphere_light   = false ; end
    if self.ui_origin       then  if not Slua.IsNull(self.ui_origin)          then GameObject.Destroy(self.ui_origin)      end ; self.ui_origin      = false ; end
    if self.crosshair       and   self.crosshair and not Slua.IsNull(self.crosshair) then GameObject.Destroy( self.crosshair ) ; self.crosshair = false ; end
    if self.targetQuad      then  self.targetQuad = false ; self.targetID = 0 ; self.targetScale = 0 ; end
    if self.ImageList       then  self.ImageList = false ; end
    if self.selected_vehicle_hud  then  self.selected_vehicle_hud = false  end
    if QuantumCube and QuantumCube.OnDestroy then QuantumCube:OnDestroy() ; QuantumCube = false ; end
    if    not partial
    then  Quandro = {}
    end
end

------------------------------------------------------------------------------------------------------------

function  Quandro:GetQuantumCube()

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

        self.debug             = true

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

        if      Quandro and Quandro.Awake  -- If Quandro exists, and has an Awake function, do not do browser stuffs.
        then    return
        end

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
        if not self.Lines or #self.Lines == 0 then return end
        for k,v in pairs(self.Lines) do
            if v.line and not Slua.IsNull(v.line) then
                for i = 1, v.line.positionCount do
                    local factor = (i - 1.0) * (1.0 / v.line.positionCount)
                    v.line:SetPosition(i - 1, self:Bezier(a, b, c, factor))
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
        print("HBU.EnableMouseLock()") ; HBU.EnableMouseLock()
    end

    function QuantumCube:OnBrowserCancel()
        self:DestroyIfPresent(self, "browser")
        print("HBU.EnableMouseLock()") ; HBU.EnableMouseLock()
    end

    function QuantumCube:OpenBrowser()
        if not self.browserArgs then return end
        return HBU.OpenBrowser(self.browserArgs[1],self.browserArgs[2],self.browserArgs[3],self.browserArgs[4],self.browserArgs[5],self.browserArgs[6],self.browserArgs[7],self.browserArgs[8],self.browserArgs[9])
    end

    function QuantumCube:SetAssetPath(assetPath)
        if not self then return "" ; end
        if    type(assetPath) ~= "string" or assetPath == ""
        then
              assetPath = tostring( HBU.LoadValue("quantumCubeSave", "assetPath") or "" )
              if assetPath == "" then if self.debug then print("QuantumCube:SetAssetPath() : INFO : assetPath was empty after loading from file.") ; end ; return "" ; end
              self.assetPath = assetPath
              if self.debug then print("QuantumCube:SetAssetPath() : INFO : self.assetPath = "..tostring(assetPath)) ; end
              return self.assetPath
        end
        self.assetPath = tostring(assetPath)
        HBU.SaveValue("quantumCubeSave", "assetPath", assetPath)
        if self.debug then print("QuantumCube:SetAssetPath() : INFO : self.assetPath = "..tostring(assetPath)) ; end
        return self.assetPath
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
                        self.spawnTime = 999999999
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

                        elseif  self.phase == 5   and  self.keys.lmb.GetKeyUp()
                        then
                                HBU.DropVehicle(self.vehicle)
                                self.phase = 6
                                if self.debug then print("self.phase = "..tostring(self.phase).." Drop Vehicle") end
                                return

                        elseif  self.phase == 5   and  self.dropOnSpawn  and  self.keys.lmb.GetKey() == 0
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
                                    local childCount = self.vehicle.transform.childCount
                                    for k = 0,childCount - 1
                                    do
                                        local v = self.vehicle.transform:GetChild(k)
                                        if v and not Slua.IsNull(v) then
                                              local rb = v:GetComponent("Rigidbody")
                                              if rb and not Slua.IsNull(rb) and rb.AddForce then rb:AddForce( self.launchVelocity*self.launchVelocityMult, 2) ; end
                                              if self.debug then print("Launch ("..tostring(k+1).."/"..tostring(childCount)..") Velocity: "..tostring(self.launchVelocity*self.launchVelocityMult)) end
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

end


------------------------------------------------------------------------------------------------------------

function main(go) Quandro.gameObject = go ; return Quandro ; end

return Quandro
