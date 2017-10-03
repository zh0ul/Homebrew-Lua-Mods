BuilderTools = {}
BT = BuilderTools


function BuilderTools:Awake()
    print("BuilderTools:Awake()")

  --self.parent              = HBU.menu.transform:Find("Foreground").gameObject

  --HBU.EnableGadgetMouseScroll()     (ex: when placing a vehicle, use Disable so ZoomIn/ZoomOut can be used to change spawn distance)
  --HBU.DisableGadgetMouseScroll()    Use these to disable/enable Gadget Selection.

    self.lmb                 = HBU.GetKey("UseGadget")
    self.rmb                 = HBU.GetKey("UseGadgetSecondary")
    self.ctrl                = HBU.GetKey("Control")
    self.control             = HBU.GetKey("Control")
    self.shift               = HBU.GetKey("Shift")
    self.zoomIn              = HBU.GetKey("ZoomIn")
    self.zoomOut             = HBU.GetKey("ZoomOut")
    self.escape              = HBU.GetKey("Escape")
    self.alt                 = HBU.GetKey("Alt")
    self.submit              = HBU.GetKey("Submit")                       -- Default: Enter
    self.move                = HBU.GetKey("Move")                         -- Default: W / S
    self.strafe              = HBU.GetKey("Strafe")                       -- Default: D / A
    self.jump                = HBU.GetKey("Jump")                         -- Default: Space
    self.run                 = HBU.GetKey("Run")                          -- Default: Left-Shift
    self.crouch              = HBU.GetKey("Crouch")                       -- Default: C
    self.ChangeCameraView    = HBU.GetKey("ChangeCameraView")             -- Default: V
    self.ChangeThirdView     = HBU.GetKey("ChangeThirdPersonCameraMode")  -- Default: B
    self.navback             = HBU.GetKey("NavigateBack")                 -- Default: Escape
    self.action              = HBU.GetKey("Action")                       -- Default: F
    self.inventory           = HBU.GetKey("Inventory")                    -- Default: I
    self.showcontrols        = HBU.GetKey("ShowControls")                 -- Default: F1
    self.flipvehicle         = HBU.GetKey("flipVehicle")                  -- Default: L
    self.tilde               = { GetKey = function() if Input.GetKey(KeyCode.BackQuote)  then return 1 else return 0 ; end ; end, GetKeyDown = function() return Input.GetKeyDown(KeyCode.BackQuote)  ; end,  GetKeyUp = function() return Input.GetKeyDown(KeyCode.BackQuote)  ; end, }
    self.arrowl              = { GetKey = function() if Input.GetKey(KeyCode.LeftArrow)  then return 1 else return 0 ; end ; end, GetKeyDown = function() return Input.GetKeyDown(KeyCode.LeftArrow)  ; end,  GetKeyUp = function() return Input.GetKeyDown(KeyCode.LeftArrow)  ; end, }
    self.arrowr              = { GetKey = function() if Input.GetKey(KeyCode.RightArrow) then return 1 else return 0 ; end ; end, GetKeyDown = function() return Input.GetKeyDown(KeyCode.RightArrow) ; end,  GetKeyUp = function() return Input.GetKeyDown(KeyCode.RightArrow) ; end, }
    self.arrowu              = { GetKey = function() if Input.GetKey(KeyCode.UpArrow)    then return 1 else return 0 ; end ; end, GetKeyDown = function() return Input.GetKeyDown(KeyCode.UpArrow)    ; end,  GetKeyUp = function() return Input.GetKeyDown(KeyCode.UpArrow)    ; end, }
    self.arrowd              = { GetKey = function() if Input.GetKey(KeyCode.DownArrow)  then return 1 else return 0 ; end ; end, GetKeyDown = function() return Input.GetKeyDown(KeyCode.DownArrow)  ; end,  GetKeyUp = function() return Input.GetKeyDown(KeyCode.DownArrow)  ; end, }
    self.wheel               = { KeyUpData = { { tick = 0, }, { tick = 0, }, }, GetKey = function() return ( Input.GetAxis("Mouse ScrollWheel") * -1 ) ; end, GetKeyDown = function() local r = {false,false,false} ; local v = Input.GetAxis("Mouse ScrollWheel") ; if v ~= 0 then r[1] = true end ; if v > 0 then r[2] = true end ; if v < 0 then r[3] = true end ; return unpack(r) ; end,  GetKeyUp = function() if not self or not self.keys or not self.keys.wheel or not self.keys.wheel.KeyUpData or not self.tick then return false ; end ; local a_index,b_index = (self.tick-1)%2+1,(self.tick)%2+1 ; local d = self.keys.wheel.KeyUpData ; if self.tick ~= d[b_index].tick then d[b_index].tick = self.tick ; for k,v in pairs({self.keys.wheel.GetKeyDown()}) do d[b_index][k] = v ; end ; end ; if d[a_index].tick == self.tick - 1 then return d[a_index][1],d[a_index][2],d[a_index][3] ; else return false,false,false  ; end ; end, }

    self.thickness           = 0.035
    self.sides               = 8
    self.pipe_segments       = 14
    self.qualityBias         = 0.0
    self.state               = {}
    self.timer               = 0
    self.debug               = true

    self.cp_img_path         = Application.persistentDataPath.."/Lua/ModLua/BuilderTools/colour_picker_sm.png"
    self.crosshair_path      = Application.persistentDataPath.."/Lua/ModLua/BuilderTools/selector.png"

    self.cp_size             = Vector2(312, 160)
    self.window_pos          = Vector2(500,200)
    self.window_size         = Vector2(320,500)
    self.uv_grey_pixel       = Vector2(553, 1977)
    self.uv_grey             = Vector2( 1/(4096/self.uv_grey_pixel.x), 1/(4096/self.uv_grey_pixel.y))
    self.uv_grey             = self.uv_grey_pixel/4096
    self.uv_grey.y           = 1- self.uv_grey.y
    self.colours             = {silver = Vector2(0.315, 0.7), chrome=Vector2(0.315, 0.68), met_purple=Vector2(0.302, 0.65), met_pink = Vector2(0.290, 0.65)}
    self.uv_col              = self.colours.silver
    self.color_sq            = Vector2(12,15)
    self.detail              = 0
    self.spec                = 0.6
    self.smoothness          = 0.6
    self.brightness          = 0.6
    self.type                = 2
    self.current_tab         = 0
    self.selectedObjects     = {}
    self.cube_radius         = 0.05
    self.c_verts             = {
      Vector3(0-self.cube_radius, 0-self.cube_radius, 0-self.cube_radius), -- 1
      Vector3(0+self.cube_radius, 0-self.cube_radius, 0-self.cube_radius), -- 2
      Vector3(0-self.cube_radius, 0+self.cube_radius, 0-self.cube_radius), -- 3
      Vector3(0+self.cube_radius, 0+self.cube_radius, 0-self.cube_radius), -- 4
      Vector3(0-self.cube_radius, 0-self.cube_radius, 0+self.cube_radius), -- 5
      Vector3(0+self.cube_radius, 0-self.cube_radius, 0+self.cube_radius), -- 6
      Vector3(0-self.cube_radius, 0+self.cube_radius, 0+self.cube_radius), -- 7
      Vector3(0+self.cube_radius, 0+self.cube_radius, 0+self.cube_radius), -- 8
    }
    self.ui_visible          = false
    self.LayerUI             = 5
    self.canvas              = false
    self.setup               = false
    self.chat                = GameObject.FindObjectOfType("HBChat")
    self.debugMsg            = function(self,msg) self.chat:AddMessage("[DEBUG]",msg) end
    self.btn_clicked         = false
    self.onClicks            = {
       Ok = function() print("hi")  ; end,
    }
    self.tick                = 0
    self:SetupUI()

end


function BuilderTools:OnDestroy()

    -- UI:CleanUp()

    if self.destroyables then
        for i=0, #self.destroyables do if self.destroyables[i] and not Slua.IsNull(self.destroyables[i]) then  GameObject.Destroy(self.destroyables[i]) end ; end
        self.destroyables = false
    end

    -- HBU.EnableMouseLock()

    if self.selectedObjects
    then
        for i,v in pairs(self.selectedObjects) do
            if    v and not Slua.IsNull(v)
            then  v:GetComponentInChildren("AdjustablePart"):HideCurves()
            end
        end
        self.selectedObjects = false
    end

end


function BuilderTools:Update()

    self:SetCpuTime(true)

    self.tick = ( self.tick or 0 ) + 1

    if not self.setup then self:SetCpuTime() ; return ; end

    if    not HBU.InBuilder()
    then
          if    self.ui_visible
          then
                self.ui_visible = false
                self:ToggleUI(self.ui_visible)
                HBU.EnableMouseLock()
          end
          self:SetCpuTime()
          return
    end

    self:CleanupSelected()

    if Input.GetKeyDown(KeyCode.F5) then self.ui_visible = not self.ui_visible; self:ToggleUI(self.ui_visible) ; end

    if self.lmb:GetKey() ~= 0 then self:LeftClickDown() end

    if self.lmb:GetKeyUp()    then self:LeftClickUp() end

    if self.window.values.UpdateAll then self:UpdateAll() end
    if self.window.values.UpdateSelected then self:UpdateSelected() end
    if self.ui_visible then HBU.DisableMouseLock() end

    self:SetCpuTime()

end


function BuilderTools:UpdateAll()
    if self.current_tab == 1 or self.current_tab == 2 then -- pipes or pipecubes
        self:ScanForPipes()
    elseif self.current_tab == 0 then
        self:ScanForPlates()
    end

end


function BuilderTools:CleanupSelected()

    if not self.selectedObjects or #self.selectedObjects == 0 then return ; end

    local newSelectedObjects = {}

    for k,v in pairs(self.selectedObjects) do if v  and not Slua.IsNull(v) then newSelectedObjects[#newSelectedObjects+1] = v ; end ; end

    self.selectedObjects = newSelectedObjects

end


function BuilderTools:UpdateSelected()
    if #self.selectedObjects <1 then return end
    for i = 1, #self.selectedObjects, 1 do
        if self.current_tab == 0 then
            if string.find( string.lower( tostring( self.selectedObjects[i] ) ),"adjustable.*plate" ) then
                self:GeneratePlate(self.selectedObjects[i])
            end
        else
            if string.find( string.lower( tostring( self.selectedObjects[i] ) ),"adjustable.*pipe.*") then
                self:GeneratePipe(self.selectedObjects[i])
            end
        end
    end
end


function BuilderTools:LeftClickUp()
    local pos = Input.mousePosition
    pos.y = Screen.height - pos.y
    if HBU.InBuilder() and self.ui_visible and not self.window.rect:Contains(pos) then self:RaycastForPart(self.shift:GetKey() >0.1) end
end


function BuilderTools:RaycastForPart(multi)
    local add = self.shift:GetKey() >0.1
    local remove = self.ctrl:GetKey() >0.1

    local multi = add or remove

    if #self.selectedObjects > 0 and not multi then 
        for k,v in pairs(self.selectedObjects) do
            v:GetComponentInChildren("AdjustablePart"):HideCurves()
        end
        self.selectedObjects = {} 
    end

    local ray = Camera.main:ScreenPointToRay(Input.mousePosition)
    local results = self:RaycastAll(ray.origin,ray.direction,100)
    local selectedObject = false
    for k, obj in pairs(results) do
        if obj.transform.gameObject:GetComponentInChildren(MeshFilter) ~= nil then
            local ap = obj.transform.gameObject:GetComponentInChildren("AdjustablePart")
            if ap ~= nil then
                if self:AdvancedRayCast(ray, obj.transform.gameObject) then selectedObject = obj.transform.gameObject end
            end
        end
    end
    
    if selectedObject then 
        if add or remove then
            if remove then 
                for i = 1, #self.selectedObjects do
                    if self.selectedObjects[i] == selectedObject then 
                        self.selectedObjects[i] = nil
                    end
                    selectedObject:GetComponentInChildren("AdjustablePart"):HideCurves()
                end
            end
            if add then 
                self.selectedObjects[#self.selectedObjects+1] = selectedObject 
                selectedObject:GetComponentInChildren("AdjustablePart"):ShowCurves()
            end
        else
            self.selectedObjects = {selectedObject}
            selectedObject:GetComponentInChildren("AdjustablePart"):ShowCurves() 
        end
    end

end

------------------------------------------------------------------------------------------------------------


function BuilderTools:PasteScheme()

end


function BuilderTools:CopyScheme()
    local scheme = self.schemeslookup[self.current_tab]

    if #self.selectedObjects > 0 then
        local new_scheme = self:GetSchemeFromObject(self.selectedObjects[1])
        scheme.color = new_scheme.color
        scheme.mat_type = new_scheme.mat_type
        scheme.smoothness = new_scheme.smoothness
    end
end

------------------------------------------------------------------------------------------------------------

function BuilderTools:GetSchemeFromObject(obj)
    local mf = obj:GetComponentInChildren(MeshFilter)
    local uv = mf.mesh.uv[1]
    local scheme = self:GetSchemeFromUV(uv)
    return scheme
end


function BuilderTools:AdvancedRayCast(ray, object)
    local go = GameObject()
    go.transform.position = object.transform.position
    go.transform.rotation = object.transform.rotation
    local mc = go:AddComponent(MeshCollider)
    local mf = object:GetComponentInChildren(MeshFilter)
    mc.sharedMesh = mf.mesh
    mc.convex = false
    local rh = RaycastHit()
    local hit = mc:Raycast(ray, rh, 100000)
    GameObject.Destroy(go)
    return hit
end


function BuilderTools:LeftClickDown()
    if not self.ui_visible then return end
    -- check if click is inside our color picker
    local pos = Vector2(Input.mousePosition.x, Screen.height - Input.mousePosition.y)
    local rect = Rect(Vector2(self.window.cp_rect.x + self.window.rect.x, self.window.cp_rect.y + self.window.rect.y), Vector2(self.window.cp_rect.width, self.window.cp_rect.height))
    if rect:Contains(pos) then
        local target = self.schemeslookup[self.current_tab]
        local tmp = Rect.PointToNormalized(rect, pos)
        target.color = Vector2(math.floor(tmp.x*self.cp_size.x/8)+0.5, math.floor(tmp.y*self.cp_size.y/8)+0.5 )
    end
end


function BuilderTools:GetSchemeFromUV(uv)
    local scheme = {}

    local uvImg = Vector2(uv.x, 1-uv.y)*256
    scheme.mat_type = math.floor(uvImg.x/(39))
    scheme.smoothness = math.floor(uvImg.y / 20)/5
    local max = 1
    if scheme.mat_type == 4 then max = 0.8 elseif scheme.mat_type == 3 then max = 0.6 end
    scheme.smoothness = math.min(scheme.smoothness, max)
    scheme.color = Vector2(math.floor(uvImg.x - scheme.mat_type*39), math.floor(uvImg.y - scheme.smoothness*20*5)  )
    return scheme
end


function BuilderTools:GetUVColorFromScheme(scheme)
    local uv_col = scheme.color*16/4096
    local max = 1;
    if scheme.mat_type == 4 then max = 0.8 elseif scheme.mat_type == 3 then max = 0.6 end
    local smoothness = math.min(scheme.smoothness, max)
    uv_col.y = 1 - uv_col.y
    uv_col.y = uv_col.y - (2*self.cp_size.y/4096)*(smoothness*5)
    uv_col.x = uv_col.x + (2*self.cp_size.x/4096)*(scheme.mat_type)
    return uv_col
end


function BuilderTools:SaveSettings()
--string2file(  dumptable(  someTable,  "TheTableNameYouWantToShow" ),  someFile,  "w" )
--local  func = loadstring(  file2string(  someLuaFile ) )
--if  func   then  func()   end
end


function BuilderTools:SetupUI()
    self.destroyables = {}
    self.colour_picker = HBU.LoadTexture2D( self.cp_img_path)
    self.crosshair = HBU.LoadTexture2D( self.crosshair_path)


    self.schemes = {
        plates = {color = Vector2(20,10), smoothness = 0.6, thickness = 20,     mat_type = 3                  },
        pipes =  {color = Vector2(14,13), smoothness = 0.8, thickness = 0.035,  mat_type = 2,   detail=false  },
        cubes =  {color = Vector2(18,16), smoothness = 0.2, enabled = 0,        mat_type = 4                  },
    }

    self.schemeslookup = {}
    self.schemeslookup[0] = self.schemes.plates
    self.schemeslookup[1] = self.schemes.pipes
    self.schemeslookup[2] = self.schemes.cubes

    self.setup = true
end


function BuilderTools:ToggleUI(mode)
    self.ui_visible = mode
    if self.ui_visible then 
        HBU.DisableMouseLock()
    elseif not (HBU.InBuilder() or HBU.InMainMenu() ) then
        HBU.EnableMouseLock()
    end

    if self.ui_visible then 
        for i = 1, #self.selectedObjects do
            self.selectedObjects[i]:GetComponentInChildren("AdjustablePart"):ShowCurves()
        end        
    else
        for i = 1, #self.selectedObjects do
            self.selectedObjects[i]:GetComponentInChildren("AdjustablePart"):HideCurves()
        end        
    end

end


function BuilderTools:Start()
  self.window = {
    id = 1338,
    rect = Rect( (Screen.width - BuilderTools.window_size.x)/2, (Screen.height - BuilderTools.window_size.y)/2 , BuilderTools.window_size.x, BuilderTools.window_size.y), --x,y,width,height
    update = function(self,...) return BuilderTools:UpdateWindow(self,...)     ; end,
    values = {
        UpdatePipes = false,
        Toggle = false,
        TextField = "" ,
        PasswordField = "" ,
        TextArea = "" ,
        Toolbar = 0,
        SelectionGrid = 0 ,
        HorizontalSlider = 0 ,
        BeginScrollView = Vector2(0,0) ,
        Box = false
    }
  }
end


function BuilderTools:OnGUI()
    if self.ui_visible then
        self.window.rect = GUILayout.Window(self.window.id, self.window.rect, self.window.update, "")
    end
end


function BuilderTools:UpdateWindow(id)
    GUILayout.DragWindow(Rect(0,0,self.window.rect.width,30)) --makes top part of window draggable
    local s = BuilderTools.window.values
    local l = function(title, content)
        GUILayout.BeginHorizontal()
        GUILayout.Label(title)
        GUILayout.Space(15)
        content()
        GUILayout.EndHorizontal()
    end
    GUILayout.Label("")
    GUILayout.BeginVertical()

    GUILayout.BeginHorizontal()    
    self.current_tab = GUILayout.SelectionGrid(self.current_tab,{"Plates", "Pipes", "Pipe Cubes"}, 3)
    GUILayout.EndHorizontal()

    local imgsize = self.cp_size
    local start = Vector2(0,60)
    self.window.cp_rect = Rect(start, imgsize)

    local target = self.schemeslookup[self.current_tab]
    local coords = self.schemeslookup[self.current_tab].color*8 - Vector2(4,4)

    GUILayout.BeginArea(self.window.cp_rect, self.colour_picker);
    GUILayout.EndArea(); 
    GUILayout.BeginArea(Rect(start + coords, Vector2(8, 8)), self.crosshair);
    GUILayout.EndArea(); 

    GUILayout.Space(200)


    GUILayout.BeginHorizontal()
    target.mat_type = GUILayout.SelectionGrid(target.mat_type,{"Plastic", "Painted", "Metal", "Rubber", "Emmisive"}, 5)
    GUILayout.EndHorizontal()
    
    GUILayout.Space(8)

    GUILayout.BeginHorizontal()
    GUILayout.Label("Smoothness/Emmisive")
    GUILayout.Space(16)
    local br = GUILayout.HorizontalSlider(target.smoothness, 0, 1)
    GUILayout.Label(string.format(" %.1f", target.smoothness))
    GUILayout.Space(16)
    GUILayout.EndHorizontal()

    GUILayout.Space(16)
    target.smoothness = math.floor(br*5)/5

    if self.current_tab == 1 then
        GUILayout.BeginHorizontal()
        GUILayout.Label(string.format("Thickness"))
        GUILayout.Space(16)
        target.thickness = GUILayout.HorizontalSlider(target.thickness, 0.015, 1.0 )
        GUILayout.Label(string.format(" %.4f",target.thickness))
        GUILayout.Space(16)
        GUILayout.EndHorizontal()
        GUILayout.Space(16)

        GUILayout.Label("Use Cube color on cubes:")
        GUILayout.BeginHorizontal()
        self.schemes.cubes.enabled = GUILayout.SelectionGrid(self.schemes.cubes.enabled,{"Default grey", "Cube color", "Match pipe color"}, 3)
        GUILayout.EndHorizontal()
    end
    
    GUILayout.FlexibleSpace()

    if GUILayout.Button("Copy selected color to current palette") then 
        self:CopyScheme()
    end

    GUILayout.BeginHorizontal()
    s.UpdateSelected = GUILayout.Button("Apply on selected")
    s.UpdateAll = GUILayout.Button("Apply all")
    local closeme = GUILayout.Button("Cancel")
    GUILayout.EndHorizontal()
    -- GUILayout.Space(32)
    
    if closeme then self:ToggleUI(false) end
    GUILayout.Space(16)

    GUILayout.EndVertical()
    
end


function BuilderTools:ScanForPlates()
    for k, obj in pairs(self:GetAllObjectsOfType("adjustable.*plate")) do
        if obj:GetComponent("MeshFilter") then
            self:GeneratePlate(obj)
        end
    end
end


function BuilderTools:GeneratePlate(obj)
    local uvs = self:GetUVColorFromScheme(self.schemes.plates)
    obj:GetComponentInChildren("AdjustablePart").UVCoords = uvs
    obj:GetComponentInChildren("AdjustablePart").doit = true
end


function BuilderTools:ScanForPipes()
    for k, obj in pairs(self:GetAllObjectsOfType("adjustable.*pipe")) do
        if obj:GetComponent("MeshFilter") then
            self:GeneratePipe(obj)
        end
    end
end


function BuilderTools:GatherPipeNodes( ... )
    local pipes = self:GetAllObjectsOfType("adjustable.*plate") -- need to do better filter
    local nodes = {}
    for k, obj in pairs(pipes) do
        -- if not obj:GetComponent("MeshFilter") then break end
        -- echo(obj:GetComponent("MeshFilter")) -- maybe just remove (Clone)'s
        local mnodes = obj:GetComponentsInChildren("MovableNode")
        if mnodes then
            for i=1, mnodes.Length, 1 do
                nodes[#nodes+1] = mnodes[i].transform.position
            end
        end
    end
    -- echo(nodes)

    -- local pipes = Object.FindObjectsOfType("AdjustablePart")
end


function BuilderTools:FindNeighbours()
    
end


function BuilderTools:GeneratePipe(obj)

    if( self.debug ) then
        print("Gen Pipe")
    end
    local tforms = obj:GetComponentsInChildren("MovableNode")
    local nodes = {}
    for i = 1, tforms.Length, 1 do
        nodes[#nodes+1] = tforms[i]
    end
    local points = {}
    if #nodes < 4 then
        local s, e = nodes[1].transform.position, nodes[2].transform.position
        local dir = (s- e).normalized
        local adj_a = s-dir/10
        local adj_b = e+dir/10
        points = {s, adj_a, adj_b, e}
    else
        for i,v in ipairs(nodes) do
            points[i] = v.transform.position
        end
    end

    local segs = self.pipe_segments 

    local spline = {}
    local direction = {}
    local node_start = points[1]
    local node_end = points[4]
    for i = 0,segs do
        
        local f = i*(1.0/segs)
        local fup = (i+1)*(1.0/segs)
        local fdown = (i-1)*(1.0/segs)
    
        spline[i] = Spline.BezierPoint(points,f)
    
        if( i == 0 ) then
            direction[i] = (spline[i]-Spline.BezierPoint(points,fup)).normalized
        end
        if( i > 0 and i < segs ) then
            direction[i] = (Spline.BezierPoint(points,fdown) - Spline.BezierPoint(points,fup)).normalized
        end
        if( i == segs ) then
            direction[i] =  (Spline.BezierPoint(points,fdown)-spline[i]).normalized
        end
    end


    local uv_col = self:GetUVColorFromScheme(self.schemes.pipes)
    local thickness = self.schemes.pipes.thickness
    local uv_det_start = Vector2(0.75,1)
    local uv_det_end = Vector2(0.875,0.875)

    local verts = {}
    local norms = {}
    local tris = {}
    local uv = {}
    local uv2 = {}
    for j = 0, segs do
        for i = 0, self.sides-1 do
            local a = i * (360.0/self.sides)
            local ma = Matrix4x4.TRS(spline[j],Quaternion.LookRotation(direction[j])*Quaternion.Euler(0,0,a),Vector3.one)
            verts[#verts+1] = obj.transform:InverseTransformPoint(ma:MultiplyPoint(Vector3.right*thickness))
            norms[#norms+1] = obj.transform:InverseTransformDirection(ma:MultiplyVector(Vector3.right))
            uv[#uv+1] = Vector2(uv_col.x, uv_col.y)
            local x = Mathf.Lerp(uv_det_start.x, uv_det_end.x, i/(self.sides-1))
            local y = uv_det_start.y
            if j%2 == 0 then 
                y = uv_det_end.y; 
                -- y = Mathf.Lerp(uv_det_end.y, uv_det_start.y, i/(self.sides-1))
            end
            uv2[#uv2+1] = Vector2(x, y)

        end
    end        

    local ip = 0
    for i=0, segs-1, 1 do
        for j=0, (self.sides)-1, 1 do
            local p = i*(self.sides)+j
            tris[#tris+1] = p+1
            tris[#tris+1] = p
            tris[#tris+1] = p+self.sides

            if j == (self.sides)-1 then
                tris[#tris+1] = p
                tris[#tris+1] = i*(self.sides)+self.sides
                tris[#tris+1] = i*(self.sides)
            else
                tris[#tris+1] = p+1
                tris[#tris+1] = p+self.sides
                tris[#tris+1] = p+self.sides+1
            end
        end
    end

    local dirs = {Vector3.up, Vector3.down, Vector3.left, Vector3.right, Vector3.back, Vector3.forward}

    local rad = 0.05

    local offsets = {node_start, node_end}
    local ve = self.c_verts
    for c= 1, 2 do
        local offset = obj.transform:InverseTransformPoint(offsets[c])
        local start = #verts
        local offset = obj.transform:InverseTransformPoint(offsets[c])
        local start = #verts


        -- top/bottom
        verts[#verts+1] = offset + ve[3]
        verts[#verts+1] = offset + ve[4]
        verts[#verts+1] = offset + ve[8]
        verts[#verts+1] = offset + ve[7]
        tris[#tris+1]   = start  + 1
        tris[#tris+1]   = start  + 0
        tris[#tris+1]   = start  + 2
        tris[#tris+1]   = start  + 3
        tris[#tris+1]   = start  + 2
        tris[#tris+1]   = start  + 0
        start=#verts
        verts[#verts+1] = offset + ve[1]
        verts[#verts+1] = offset + ve[2]
        verts[#verts+1] = offset + ve[6]
        verts[#verts+1] = offset + ve[5]
        tris[#tris+1]   = start  + 0
        tris[#tris+1]   = start  + 1
        tris[#tris+1]   = start  + 2
        tris[#tris+1]   = start  + 2
        tris[#tris+1]   = start  + 3
        tris[#tris+1]   = start  + 0

        -- sides
        start=#verts
        verts[#verts+1] = offset + ve[3]
        verts[#verts+1] = offset + ve[7]
        verts[#verts+1] = offset + ve[5]
        verts[#verts+1] = offset + ve[1]
        tris[#tris+1]   = start  + 1
        tris[#tris+1]   = start  + 0
        tris[#tris+1]   = start  + 2
        tris[#tris+1]   = start  + 3
        tris[#tris+1]   = start  + 2
        tris[#tris+1]   = start  + 0
        start=#verts
        verts[#verts+1] = offset + ve[4]
        verts[#verts+1] = offset + ve[8]
        verts[#verts+1] = offset + ve[6]
        verts[#verts+1] = offset + ve[2]
        tris[#tris+1]   = start  + 0
        tris[#tris+1]   = start  + 1
        tris[#tris+1]   = start  + 2
        tris[#tris+1]   = start  + 2
        tris[#tris+1]   = start  + 3
        tris[#tris+1]   = start  + 0

        -- front/back
        start=#verts
        verts[#verts+1] = offset + ve[7]
        verts[#verts+1] = offset + ve[8]
        verts[#verts+1] = offset + ve[6]
        verts[#verts+1] = offset + ve[5]
        tris[#tris+1]   = start  + 1
        tris[#tris+1]   = start  + 0
        tris[#tris+1]   = start  + 2
        tris[#tris+1]   = start  + 3
        tris[#tris+1]   = start  + 2
        tris[#tris+1]   = start  + 0
        start=#verts
        verts[#verts+1] = offset + ve[3]
        verts[#verts+1] = offset + ve[4]
        verts[#verts+1] = offset + ve[2]
        verts[#verts+1] = offset + ve[1]
        tris[#tris+1]   = start  + 0
        tris[#tris+1]   = start  + 1
        tris[#tris+1]   = start  + 2
        tris[#tris+1]   = start  + 2
        tris[#tris+1]   = start  + 3
        tris[#tris+1]   = start  + 0

    end
    local tmp = {  }
    for i=#tris-5, #tris, 1 do tmp[#tmp+1] = tris[i] end
    -- echo(tmp)

    local cube_uv = self.uv_grey
    if self.schemes.cubes.enabled == 1 or self.current_tab == 2 then 
        cube_uv = self:GetUVColorFromScheme(self.schemes.cubes) 
    elseif self.schemes.cubes.enabled == 2 then  -- match pipe colour
        cube_uv = uv_col
    end

    for i=#norms+1, #verts do norms[i] = Vector3.one end
    for i=#uv+1, #verts do uv[i] = cube_uv end
    for i=#uv2+1, #verts do uv2[i] = Vector2.zero end

    --apply
    local mf =obj:GetComponentInChildren(MeshFilter) 
    local m = mf.mesh
    if( m == nil ) then 
        print("resetting mesh!")
    end
    m = Mesh()
    m.vertices = verts
    m.normals = norms
    m.triangles = tris
    m.uv = uv
    if self.detail ~= 0 then m.uv2 = uv2 end
    m:RecalculateNormals()
    mf.mesh = m
end

------------------------------------------------------------------------------------------------------------

function BuilderTools:SetupCpuTime()
    self.cpu              = { new = true, tick = 0, startTime = os.clock(), currentTime = os.clock(), totalTime = 0, updateStart = os.clock(), updateEnd = os.clock(), updateTotal = 0, percent = "0%", timeDelta = Time.deltaTime, fps = 1/Time.deltaTime } 
    if not CPU then CPU = {} ; end
    CPU.BuilderTools = self.cpu
end


function BuilderTools:SetCpuTime(start)
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
    if not CPU.BuilderTools then CPU.BuilderTools = self.cpu ; end
    return
end

------------------------------------------------------------------------------------------------------------

function BuilderTools:findNearestInTable(findVal,inTab,matchLimit)

    if type(inTab) ~= "table" or type(findVal) == "nil" then return ; end

    local findValType  = type(findVal)
    local nearMatchVal = false
    local nearMatchID  = false

    if type(matchLimit) ~= "number" then  matchLimit = false ; end

    for k,v in pairs(inTab) do
        if  type(v or nil) == findValType
        then
            if      v == findVal then return v,k ; end
            local   nearVal = false
            if      findValType == "string" then if string.find(string.lower(v),string.lower(findVal)) and ( not nearMatchVal or math.abs(#v-#findVal) < math.abs(#nearMatchVal-#findVal) ) and ( not matchLimit or math.abs(#v-#findVal) <= matchLimit ) then nearMatchVal = v ; nearMatchID = k ; end
            elseif  findValType == "number" then if ( not nearMatchVal or math.abs(v-findVal) < math.abs(nearMatchVal-findVal) ) and  ( not matchLimit or math.abs(v-findVal) <= matchLimit )  then nearMatchVal = v ; nearMatchID = k ; end
            end
        end
    end

    return nearMatchVal, nearMatchID
end

------------------------------------------------------------------------------------------------------------

function BuilderTools:iter_to_table(obj)
    local  ret = {}
    if  type(obj) == "userdata" and string.find(tostring(obj),"Array") then
      for v in Slua.iter(obj) do ret[#ret+1] = v ; end
    end
    return ret
end


function BuilderTools:GetAllObjects()  local r = {} ; for kt1,t1 in pairs( { { self:iter_to_table(GameObject.FindObjectsOfType(GameObject)) }, { self:iter_to_table(GameObject.FindGameObjectsWithTag("Untagged")) }, } ) do for kt2,t2 in pairs( t1 ) do for k,v in pairs(t2) do r[#r+1] = v ; end ; end ; end ; return r ; end


function BuilderTools:GetAllObjectsOfType(...)
    local st,alsoPrint = {},false
    for k,v in pairs({...}) do if type(v) == "string" then st[#st+1] = string.lower(v) ; elseif type(v) == "boolean" then alsoPrint = v ; end ; end
    if #st == 0 then st[1] = "" ; end
    local r = {}
    for k,v in pairs(GetAllObjects()) do
        local i = 1
        while i <= #st do
              if  string.find(string.lower(tostring(v)),st[i])
              then
                  i = #st + 1
                  if alsoPrint then print("Get: "..tostring(v)) ; end
                  r[#r+1] = v
              else
                  i = i + 1
              end
        end
    end
    return r
end

------------------------------------------------------------------------------------------------------------

function BuilderTools:RaycastAll(fromPosition,forwardDirection,castDistance)
  fromPosition     = fromPosition     or Camera.main.transform.position
  forwardDirection = forwardDirection or Camera.main.transform.forward
  castDistance     = castDistance     or 100000
  local rt = {}
  for v in Slua.iter(Physics.RaycastAll(fromPosition, forwardDirection, castDistance)) do rt[#rt+1] = v ; end
  return rt
end

------------------------------------------------------------------------------------------------------------

return BuilderTools
