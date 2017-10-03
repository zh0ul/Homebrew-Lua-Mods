local Quandro = {}


function Quandro:Awake()

  print("Quandro:Awake()")

  self.debug                = false

  self.userDataPath         = HBU.GetUserDataPath()

  self.useTextureCache      = true

  self.tick                 = 0

  self.keys                 = {

      -- HBU.DisableGadgetMouseScroll()    Use these to disable/enable Gadget Selection.
      -- HBU.EnableGadgetMouseScroll()     (ex: when placing a vehicle, use Disable so ZoomIn/ZoomOut can be used to change spawn distance)
      -- HBU.DisableMouseLock()
      -- HBU.EnableMouseLock()
      -- HBU.GetMouseLock()

      lmb              = HBU.GetKey("UseGadget"),
      rmb              = HBU.GetKey("UseGadgetSecondary"),
      mmb              = { GetKey = function() if Input.GetKey(KeyCode.Mouse2)       then return 1 else return 0 ; end ; end, GetKeyDown = function() return Input.GetKeyDown(KeyCode.Mouse2)     ; end,  GetKeyUp = function() return Input.GetKeyDown(KeyCode.Mouse2)     ; end, },
      mouse3           = { GetKey = function() if Input.GetKey(KeyCode.Mouse3)       then return 1 else return 0 ; end ; end, GetKeyDown = function() return Input.GetKeyDown(KeyCode.Mouse3)     ; end,  GetKeyUp = function() return Input.GetKeyDown(KeyCode.Mouse3)     ; end, },
      mouse4           = { GetKey = function() if Input.GetKey(KeyCode.Mouse4)       then return 1 else return 0 ; end ; end, GetKeyDown = function() return Input.GetKeyDown(KeyCode.Mouse4)     ; end,  GetKeyUp = function() return Input.GetKeyDown(KeyCode.Mouse4)     ; end, },
      wheel            = { KeyUpData = { { tick = 0, }, { tick = 0, }, }, GetKey = function() return ( Input.GetAxis("Mouse ScrollWheel") * -1 ) ; end, GetKeyDown = function() local r = {false,false,false} ; local v = Input.GetAxis("Mouse ScrollWheel") ; if v ~= 0 then r[1] = true end ; if v > 0 then r[2] = true end ; if v < 0 then r[3] = true end ; return unpack(r) ; end,  GetKeyUp = function() if not self or not self.keys or not self.keys.wheel or not self.keys.wheel.KeyUpData or not self.tick then return false ; end ; local a_index,b_index = (self.tick-1)%2+1,(self.tick)%2+1 ; local d = self.keys.wheel.KeyUpData ; if self.tick ~= d[b_index].tick then d[b_index].tick = self.tick ; for k,v in pairs({self.keys.wheel.GetKeyDown()}) do d[b_index][k] = v ; end ; end ; if d[a_index].tick == self.tick - 1 then return d[a_index][1],d[a_index][2],d[a_index][3] ; else return false,false,false  ; end ; end, },
      control          = HBU.GetKey("Control"),
      shift            = HBU.GetKey("Shift"),
      run              = HBU.GetKey("Run"),                         -- Default: Left-Shift

      --[[   Disabled keys here
      escape           = HBU.GetKey("Escape"),
      alt              = HBU.GetKey("Alt"),
      submit           = HBU.GetKey("Submit"),                      -- Default: Enter
      move             = HBU.GetKey("Move"),                        -- Default: W / S
      strafe           = HBU.GetKey("Strafe"),                      -- Default: D / A
      jump             = HBU.GetKey("Jump"),                        -- Default: Space
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
      zoomIn           = HBU.GetKey("ZoomIn"),   -- Only works when in vehicle, so pretty pointless.
      zoomOut          = HBU.GetKey("ZoomOut"),  -- Only works when in vehicle, so pretty pointless.
      --]]
  }

  self.vehicle_select_image_file =  Application.persistentDataPath .. "/Lua/GadgetLua/vehicle_select.png"

  self.textureCacheTick   = 3

  self.ObjectsToDestroy   = {}

  self.visible            = false

  self.columnCountDefault  = 7
  self.lineCountDefault    = 3
  self.imageRadiusDefault  = 128
  self.columnCount         = self.columnCountDefault
  self.lineCount           = self.lineCountDefault
  self.imageRadius         = self.imageRadiusDefault
  self.imageColor          = Color(1,1,1,1)

  self.limits             = {Screen.width, Screen.height, Screen.width, Screen.height}
  self.padding            = 100 -- Padding in pixels
  self.images = {} -- our array of images
  self.displayCounts = {1,3,5,21,27,55,119}
  if    not QuandroData
  then  QuandroData = { zoomLevel = 4, }
  end
  self.zoomLevel = QuandroData.zoomLevel or 4


  if     self.columnCount  * (self.imageRadius*2) > Screen.width
  then
        self.imageRadius  = math.floor((Screen.width-(self.padding*2))/self.columnCount/2)
        print("Quandro : INFO : self.imageRadius adjusted to Screen.width("..tostring(Screen.width)..") / self.columnCount("..tostring(self.columnCount)..") / 2 = "..tostring(self.imageRadius))
  end

  self.updateClockStart   = os.clock()
  self.updateClockEnd     = os.clock()
  self.updateClockTotal   = self.updateClockEnd - self.updateClockStart

  if    not TextureCache
  then  TextureCache = { all_vehicle_images_cached = false, }
  end

  if TextureCache and TextureCache.SelectedHBA    then self.SelectedHBA   = TextureCache.SelectedHBA   ; end
  if TextureCache and TextureCache.SelectedImage  then self.SelectedImage = TextureCache.SelectedImage ; end
  if TextureCache and TextureCache.SID            then self.SID           = TextureCache.SID           ; end
  if TextureCache and TextureCache.columnCount    then self.columnCount   = TextureCache.columnCount   ; end
  if TextureCache and TextureCache.lineCount      then self.lineCount     = TextureCache.lineCount     ; end
  if TextureCache and TextureCache.imageRadius    then self.imageRadius   = TextureCache.imageRadius   ; end

  HBU.CreateDirectory(self.userDataPath.."/img_cache/")

  QuantumCube = self:GetQuantumCube()

  QuantumCube:Awake()

end


function Quandro:GetVehicleImageList(filter)
  filter = string.lower(tostring(filter or ""))
  local path = Application.persistentDataPath.."/userData"
  local file = path.."/ref.hbr"
  local r    = {}
  local func = function(inp) inp = string.gsub(inp,"<[^>]*>","") ; if not string.find(inp,"[.][Pp][Nn][Gg]") or not string.find(inp,"Vehicle/") or ( filter and filter ~= "" and not string.find(string.lower(inp),filter) ) then return ; end ; r[#r+1] = path.."/"..inp ; end
--forLineIn(file,func,suppressBlankLines,trimEdgeWhiteSpace,trimAllWhiteSpace)
  forLineIn(file,func,true,true,false)
  table.sort(r)
  return r
end


function Quandro:GetImageHash(file)
    local r = ""
    if type(file) ~= "string" then return r ; end
    if not file_exists(file) then print("Quandro:GetImageHash() : ERROR : File does not exist: "..file) ; return r ; end
    local f = io.open(file,"rb")
    if not f then print("Quandro:GetImageHash() : ERROR : Could not open file: "..file)  ; return r ; end
    for j = 1,4 do
    if  f:seek("set",64*j-1) then
        for i = 1,4 do r = r..string.format( "%02X", string.byte(f:read(1)) ) ; end
    end
    end
    io.close(f)
    return r
end


function Quandro:ScaleTexture(texIn,nWidth,nHeight,transColor)
  if not texIn or Slua.IsNull(texIn) or not texIn.format or not texIn.height or not texIn.width then return texIn ; end
  nWidth,nHeight = nWidth or 256, nHeight or 256
  local oWidth,oHeight,texOut = texIn.width,texIn.height,Texture2D.Instantiate(Texture2D.blackTexture)
  if not texOut or Slua.IsNull(texOut) then return texIn end
  texOut:Resize(nWidth,nHeight)
  for y = 0,nHeight do
  for x = 0,nWidth  do
      local vx,vy = math.floor(oWidth/nWidth*x),math.floor(oHeight/nHeight*y)
      local p = texIn:GetPixel(vx,vy)
      if p and transColor and p.r == transColor and p.g == transColor and p.b == transColor then
        p.a = 0
      end
      if p then texOut:SetPixel(x, y, p) end
  end
  end
  texOut:Apply()
  GameObject.Destroy(texIn)
  return texOut
end


function Quandro:SetTextureColorTransparent(texture,transColor)
  if not texture or Slua.IsNull(texture) or not texture.format or not texture.height or not texture.width then return texture ; end
  transColor = transColor or 0.35294118523597717
  for y = 0, texture.height, 1 do
  for x = 0, texture.width,  1 do
      local p = texture:GetPixel(x,y)
      if p and p.r == transColor and p.g == transColor and p.b == transColor then
        p.a = 0
        texture:SetPixel(x, y, p)
      end
  end
  end
  texture:Apply(true,false)
  return texture
end


function Quandro:SelectImage(imageID)
    if type(imageID) ~= "number" or not self.ImageList or #self.ImageList == 0 then return ; end
    if not self.ImageList.Image then self.ImageList.Image = {} ; end
    self:DestroyObjects()

    local oldSID = self.SID
    local diffSID = self.SID - imageID

    self.SID = (imageID-1)%(#self.ImageList)+1

    local file_hba = self.ImageList[self.SID]
    file_hba = string.gsub(file_hba,"_[Ii][Mm][Gg].[Pp][Nn][Gg]",".hba")
    self.SelectedHBA   = file_hba
    self.SelectedImage = self.ImageList[self.SID]
    if TextureCache then TextureCache.SelectedHBA = file_hba ; TextureCache.SelectedImage = self.ImageList[self.SID] ; TextureCache.SID = self.SID ; end
    if QuantumCube and QuantumCube.SetAssetPath then QuantumCube:SetAssetPath(file_hba) ; end

    local totalOnDisplay = self.columnCount*self.lineCount
    local oldTotal = #self.images; if oldTotal == 0 then oldTotal = totalOnDisplay end
    local diffDisplay = (totalOnDisplay - oldTotal)/2

    local toDestroy = {}

    if oldSID ~= self.SID then --- In this case we are shifting our image arrays left/right by either one at a time, or a row at a time
      for i=1, math.abs(diffSID), 1 do
        if diffSID < 0 then 
          table.insert(self.images, false)
          table.insert(toDestroy, table.remove(self.images,1))
        else
          table.insert(self.images, 1, false)
          table.insert(toDestroy, table.remove(self.images))
        end
      end
    end

    if oldTotal ~= totalOnDisplay and #self.images > 0 then -- In this case we're reforming our array because we changed row/column count
      for i=1, math.abs(diffDisplay), 1 do
        if diffDisplay < 0 then -- we are removing
          table.insert(toDestroy, table.remove(self.images,1)  )
          table.insert(toDestroy, table.remove(self.images) )
        else
          table.insert(self.images, false)
          table.insert(self.images, 1, false)
        end

      end
    end
    for i = 1, #toDestroy, 1 do
      if(toDestroy[i]) then
        toDestroy[i]:Destroy()
      end
      toDestroy[i] = nil
    end
    local cRow = math.floor(self.lineCount/2)*-1
    local cCol = math.floor(self.columnCount/2)*-1

    for i = 1, totalOnDisplay, 1
    do
        local height, width = Screen.height, Screen.width
        local locali  = cCol + (self.columnCount*cRow)
        local actuali = self.SID + locali
        if self.SID - #self.ImageList <= 0 and actuali + #self.ImageList <= #self.ImageList  then actuali = actuali + #self.ImageList end
        if actuali > #self.ImageList then actuali = actuali - #self.ImageList end
        local s = ""
        if locali == 0 then s = "<-----" end

        local vPad, hPad = self.imageRadius, self.imageRadius/2
        local x,y,w,h = (width*0.5)+(cCol*self.imageRadius*2) + hPad*cCol, (height*0.5)+(cRow*self.imageRadius*2) +vPad*cRow, self.imageRadius*2, self.imageRadius*2

        local label_text = string.gsub(self.ImageList[actuali],".*/","")
        label_text       = string.gsub(label_text,"_img[.][Pp][Nn][Gg]","")        
        local texturepath = self.ImageList[actuali] 
        local label_fontSize = 10 + math.floor(40 / self.columnCount)
        local label_color = Color.white
        local label_position = 1
        if locali == 0 then 
          label_color = Color.yellow
          label_fontSize = label_fontSize + 4
        end
        if  not self.images[i]
        then
            self.images[i] = UI.Image:New(x,y,w,h, self.imageColor, texturepath, label_text, label_fontSize, label_color, label_position )
        else  
          self.images[i]:SetPosAndDim(x,y,w,h)
          self.images[i]:SetLabel(label_text, label_fontSize, label_color, label_position )
        end
        cCol = cCol + 1
        if cCol > math.floor(self.columnCount/2) then cCol = math.floor(self.columnCount/2)*-1; cRow = cRow +1; end
    end

end


function Quandro:DestroyObjects()
    if UI then UI:CleanUp() ; end
    if self.images and #self.images > 0 then self.images = {} ; end
    if not self.ObjectsToDestroy or #self.ObjectsToDestroy == 0 then return ; end
    for i = #self.ObjectsToDestroy,1,-1
    do
        if    self.ObjectsToDestroy[i]
        then
            local v = self.ObjectsToDestroy[i]
            if    v and not Slua.IsNull(v)
            then
                  if      string.sub(tostring(v),-23) == "(UnityEngine.Texture2D)"
                  then    GameObject.Destroy(v)
                  elseif  v.gameObject
                  then    GameObject.Destroy(v.gameObject)
                  else    GameObject.Destroy(v)
                  end
            end
        end
    end
    self.ObjectsToDestroy = {}
end

function Quandro:ChangecolumnCount(count)
    count = count or self.columnCountDefault
    count = math.max( 5,  count )
    count = math.min(count, 31)
    local radius = self.imageRadiusDefault
    radius = math.floor((Screen.width-(self.padding*4))/(count))/2
    if radius > Screen.height/6 then radius = math.floor(Screen.height/6 ) end

    local lines = math.ceil((Screen.height - self.padding*2)/(radius*3))

    if lines%2 == 0 and lines >= 2 then lines = lines -1 end
    if      lines < 1 then lines = 1 end

    if self.debug then print("Quandro : ChangecolumnCount : self.columnCount = "..tostring(count).."  self.lineCount = "..tostring(lines).."  self.radius = "..tostring(radius)) ; end
    self.columnCount  = count
    self.lineCount    = lines
    self.imageRadius  = radius
    if    TextureCache
    then
        TextureCache.columnCount  = count
        TextureCache.lineCount    = lines
        TextureCache.imageRadius  = radius
    end
    if self.SID and self.SID > 0 then self:SelectImage(self.SID) ; end
end


function Quandro:Update()

  self.updateClockStart = os.clock()

  self.tick = self.tick + 1

  if self.tick < 2 then return ; end

  if not UI or not UI.CleanUp then return ; end

  -- if  HBU.GetMouseLock() then
      QuantumCube:Update()
  -- end

  if HBU.InBuilder() or HBU.InSeat() then self:DestroyObjects() ; return ; end

  if      self.keys.rmb.GetKey() > 0.1  and  ( not QuantumCube or not QuantumCube.target )
  then    if not self.visible then self.visible = true ; end

  elseif  self.visible
  then 
          self.visible   = false
          self.ImageList = false
          HBU.EnableGadgetMouseScroll()
  end

  if      self.visible
  then
          if    not self.ImageList
          then
                HBU.DisableGadgetMouseScroll()
                self.ImageList = self:GetVehicleImageList()
                if not self.ImageList or not self.ImageList[1] then print("Quandro : ERROR : Unable to get image list for some reason.") ; return ; end
                if not self.SID then self.SID = 1 ; end
                if self.ImageList and self.ImageList[self.SID] then self:SelectImage(self.SID) ; end
                return
          end

          if self.keys.control.GetKey() > 0.1  then  if self.keys.wheel.GetKey() < 0 then 
              self:ChangecolumnCount(self.columnCount+2) 
          elseif self.keys.wheel.GetKey() > 0 then 
              self:ChangecolumnCount(self.columnCount-2)
          end
          elseif  self.keys.wheel.GetKey()   < 0    then  
            if ( self.keys.run.GetKey() > 0 or self.keys.shift.GetKey() > 0 ) then self:SelectImage(self.SID-self.columnCount) ; else self:SelectImage(self.SID-1) ; end ;  if self.debug then print ("Quandro : Selected : "..tostring(self.SID).." : "..tostring(self.SelectedImage) ); print("Quandro : Update Time : "..tostring(self.updateClockTotal)) end
          elseif  self.keys.wheel.GetKey()   > 0    then  
            if ( self.keys.run.GetKey() > 0 or self.keys.shift.GetKey() > 0 ) then self:SelectImage(self.SID+self.columnCount) ; else self:SelectImage(self.SID+1) ; end ;  if self.debug then print ("Quandro : Selected : "..tostring(self.SID).." : "..tostring(self.SelectedImage) ); print("Quandro : Update Time : "..tostring(self.updateClockTotal)) end
          elseif  self.keys.mouse3.GetKeyDown()     then  self:ChangecolumnCount(self.columnCount-2)
          elseif  self.keys.mouse4.GetKeyDown()     then  self:ChangecolumnCount(self.columnCount+2)
          end

  elseif  not self.visible
  then
          self:DestroyObjects()
  end

  self.updateClockEnd   = os.clock()
  self.updateClockTotal = self.updateClockEnd - self.updateClockStart

end

function Quandro:OnDestroy()
  print("Quandro:OnDestroy()")
  self:DestroyObjects()
  QuantumCube:OnDestroy()
  HBU.EnableGadgetMouseScroll()
end


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

              self.ResetVarsComplete = false

              self:ResetVars()

              self.debug = false

          end

          function QuantumCube:ResetVars(override)
              if self.ResetVarsComplete and not override then return end
              self.ResetVarsComplete = true
              self.spawnTime         = 0.0
              self.distanceSpeed     = 0.2
              self.lastScrollTime    = 0.0
              self.phase             = 0
              self.dropOnSpawn       = false
              self.freezePosition    = false
              self.freezeRotation    = false
              self.rotationMod       = false
              if not self.targetDistance         then self.targetDistance = 10;            end
              if not self.targetDistanceFromSave then self.targetDistanceFromSave = false; end
          end

          function QuantumCube:Null(obj)   if not obj or      Slua.IsNull(obj) then return true end return false end
          function QuantumCube:Exists(obj) if     obj and not Slua.IsNull(obj) then return true end return false end


          function QuantumCube:DestroyIfPresent(parent, gameObjectName, doNotNilLuaObject)
              if      not parent or type(gameObjectName) ~= "string" or not parent[gameObjectName] then return false; end
              local   gameObject = parent[gameObjectName].gameObject or false
              if      gameObject and not Slua.IsNull(gameObject)
              then    if self.debug == true then print("GameObject.Destroy("..gameObjectName..")") ; end ; GameObject.Destroy(gameObject);
              elseif  not Slua.IsNull(parent[gameObjectName])
              then    if self.debug == true then print("GameObject.Destroy("..gameObjectName..")") ; end ; GameObject.Destroy(parent[gameObjectName]);
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
              Debug.Log("QuantumCube:OnDestroy()")
              self:DestroyObjects()
              HBU.EnableGadgetMouseScroll()
              -- if self.flyGadget and self.flyGadget.OnDestroy then self.flyGadget:OnDestroy() ; end
          end


          function QuantumCube:HandleBrowser()

              if true then return end -- Skip in game browser due to Quandro.

              if not self.browser and ( self.keys.rmb.GetKeyUp() or self.keys.inv.GetKey() > 0.5 )
              then
                  self:DestroyIfPresent(self, "disabled")
                  self.browser = self:OpenBrowser()
                  return
              end

          end


          function QuantumCube:UpdateTarget()
              if not self.target then return; end
              if Time.time > self.lastScrollTime + 0.07 then --position target infront of camera and handle distance via scroll
                  local scroll = Input.GetAxis("Mouse ScrollWheel")
                  if scroll == 0 then scroll = self.keys.zoomIn.GetKey() - self.keys.zoomOut.GetKey() end
                  if scroll ~= 0 then
                      self.lastScrollTime = Time.time
                      local speedMult = 1.0
                      if self.keys.run.GetKey() > 0.5 then speedMult = 2.0 end
                      if (scroll > 0) then
                          self.targetDistance = self.targetDistance * (speedMult + self.distanceSpeed)
                      end
                      if (scroll < 0) then
                          self.targetDistance = self.targetDistance * (1.0 / (speedMult + self.distanceSpeed))
                      end
                  end
              end

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
              local aa = Vector3.Lerp(a, b, f)
              local bb = Vector3.Lerp(b, c, f)
              return Vector3.Lerp(aa, bb, f)
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
              if not self.Lines then return ; end
              if not name then name = "" ; end
              local toRemove = {}
              for k,v in pairs(self.Lines) do
                  if      v and v.name and name == "ALL"
                  then    toRemove[#toRemove+1] = k ; if v.line and not Slua.IsNull(v.line) then self:DestroyIfPresent(self.Lines[k],"line",true) ; end ; if self.Lights[k] and self.Lights[k].light and not Slua.IsNull(self.Lights[k].light) then  self:DestroyIfPresent(self.Lines[k],"light",true)   ; end
                  elseif  ( name == "" and ( not v.line or Slua.IsNull(v.line) ) )
                  then    toRemove[#toRemove+1] = k
                  elseif  ( name ~= "" and string.find(v.name,name) )  or  ( v.line and Slua.IsNull(v.line) )
                  then    toRemove[#toRemove+1] = k ; if v.line and not Slua.IsNull(v.line) then self:DestroyIfPresent(self.Lines[k],"line",true) ; end ; if self.Lights[k] and self.Lights[k].light and not Slua.IsNull(self.Lights[k].light) then  self:DestroyIfPresent(self.Lights[k],"light",true)  ; end
                  end
              end
              for i = #toRemove,1,-1 do
                  table.remove(self.Lines, toRemove[i])
                  table.remove(self.Lights,toRemove[i])
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
              if not assetPath or type(assetPath) ~= "string" or assetPath == "" then return; end
              self.assetPath = assetPath
          end

          function QuantumCube:OnBrowserCancel()
              self:DestroyIfPresent(self, "browser")
          end

          function QuantumCube:SetAssetPath(assetPath)
              if type(assetPath) == "string" then self.assetPath = assetPath ; else return ; end
              if self.debug then print("QuantumCube:SetAssetPath() : INFO : self.assetPath = "..tostring(assetPath)) ; end
          end

          function QuantumCube:OpenBrowser()
              if not self.browserArgs then return end
              return HBU.OpenBrowser(unpack(self.browserArgs))
          end


          function QuantumCube:Update()

              -- if self.flyGadget and self.flyGadget.Update then self.flyGadget:Update() ; end
              if not HBU.MayControle()
                  or HBU.InSeat()
                  or HBU.InBuilder()
              then
                  self:DestroyObjects("browser")
                  self:ResetVars()
                  return
              end

              if  self.phase and self.phase == 0
              and not self.browser
              then
                  if self.target then self:DestroyIfPresent(self, "target"); return; end
                  if self.disabled and self.tick % 5 == 0 and HBU.CanSpawnVehicle(self.assetPath) then self:DestroyIfPresent(self, "disabled") ; end

                  self:HandleBrowser()

                  if self.keys.lmb.GetKeyUp() then

                      self:DestroyIfPresent(self,"disabled")

                      if not self.assetPath then
                          self.assetPath = HBU.LoadValue("quantumCubeSave", "assetPath") or ""
                      end

                      if  self.assetPath and self.assetPath ~= "" and HBU.CanSpawnVehicle(self.assetPath)
                      then
                          HBU.SaveValue("quantumCubeSave", "assetPath", self.assetPath)
                          if self.debug == true then print("Spawn: "..tostring(self.assetPath)) end
                          self.phase = 1
                          HBU.DisableGadgetMouseScroll() ; if self.debug == true then print("HBU.DisableGadgetMouseScroll()") end
                          self:DestroyIfPresent(self, "disabled")
                          self:CreateTarget()
                          self.spawnTime = Time.time
                          return
                      else
                          self:CreateCantSpawn()
                      end
                  end

              elseif self.phase and self.phase > 0
              then

                  HBU.DisableGadgetMouseScroll()

                  if self.keys.control.GetKey() > 0.5 then self.freezePosition = true ; elseif self.freezePosition and self.keys.control.GetKey() == 0 then self.freezePosition = false ; end

                  if  not self:Exists(self.vehicle)
                  then
                      if     self.keys.lmb.GetKeyDown()
                      then
                              self.spawnTime = Time.time
                              local newColor = Color.yellow
                              if    not self.dropOnSpawn
                              then  self.dropOnSpawn = true
                              else  self.dropOnSpawn = false ; newColor = Color.red
                              end
                              for k,v in pairs(self.Lines) do
                                  if v and v.line and not Slua.IsNull(v.line)
                                  then
                                      v.line.startColor = newColor;
                                      v.line.endColor   = newColor;
                                      if self.Lights and self.Lights[k] and self.Lights[k].light and not Slua.IsNull(self.Lights[k].light) then self.Lights[k].light.color = newColor ; end
                                  end
                              end

                      elseif self.keys.rmb.GetKeyUp()
                      then
                            self:DestroyObjects()
                            self:ResetVars(true)
                            return
                      end

                  elseif  self:Exists(self.vehicle) then

                      self.phase = self.phase + 1

                      if not self.target then self:ResetVars(true); return; end

                      if ( self.dropOnSpawn or self.keys.lmb.GetKeyUp() )
                      and self.phase > 6
                      then
                          self.vehicle.transform.position = self.target.transform.position
                          self.vehicle.transform.rotation = self.target.transform.rotation
                          HBU.DropVehicle(self.vehicle)
                          self.vehicle = nil --don't care about this anymore
                          HBU.SaveValue( "quantumCubeSave", "targetDistance", tostring(self.targetDistance) )
                          HBU.EnableGadgetMouseScroll() ; if self.debug == true then print("HBU.EnableGadgetMouseScroll()") end
                          self:DestroyObjects()
                          self:ResetVars(true)
                          return
                      end
                      if  self.keys.rmb.GetKeyUp() then --ABORT
                          self:DestroyObjects()
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
                  self:UpdateTarget()
                  if    Time.time > self.spawnTime + 2.5
                  and   ( not self.vehicle or Slua.IsNull(self.vehicle) )
                  then
                      self.vehicle = HBU.SpawnVehicle(Vector3(0, 0, 0), Quaternion.identity, self.assetPath)
                      if not self.vehicle or self:Null(self.vehicle) then
                          self:ResetVars(true)
                          self:DestroyIfPresent(self, "target")
                          return
                      end
                      HBU.InitializeVehicle(self.vehicle)
                  end
              end

              return

          end

          -- function QuantumCube:FixedUpdate()
          --     return
          -- end

          return QuantumCube

end


return Quandro

