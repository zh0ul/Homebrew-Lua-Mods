HBZ = {}

function HBZ:Awake()
    print("HBZ:Awake()")
    self.debug = true
    if self.SetupPaths  then self:SetupPaths() ; end
    if SetupObjectList  then SetupObjectList() end

    if    HBConsoleManager and HBConsoleManager.instances and HBConsoleManager.instances[1]
    then  HBConsoleManager.instances[1].OnConnect = { "+=", function() getLogLines() ; end, }
    end

end


function HBZ:Update()
    self:ProcessRegisteredTicks()
end


function HBZ:OnDestroy()
    print("HBZ:OnDestroy()")
end

------------------------------------------------------------------------------------------------------------

function HBZ:RegisterTick(name,callback)
    if not self and HBZ and HBZ.RegisterTick then return HBZ:RegisterTick(name,callback) ; end
    if  not self.RegisteredTicks then self.RegisteredTicks = {} end
    name = tostring(  name or tostring(debug.getinfo(0).name).."."..tostring(debug.getinfo(0).what).."/"..tostring(debug.getinfo(1).name).."."..tostring(debug.getinfo(1).what).."/"..tostring(debug.getinfo(2).name).."."..tostring(debug.getinfo(2).what).."/" )
    if type(callback) ~= "function" then  if self.RegisteredTicks[name] then return true ; end ; return false ; end
    if    not self.RegisteredTicks[name]
    then  self.RegisteredTicks[name] = #self.RegisteredTicks+1 ; if self.debug then print("HBZ:RegisterTick : Callback registered for "..name) ; end
    else  if self.debug then print("HBZ:RegisterTick : Callback updated for "..name) ; end
    end
    self.RegisteredTicks[self.RegisteredTicks[name]] = { callback = callback }
    return true
end


function HBZ:UnregisterTick(name)
    if not self and HBZ and HBZ.RegisterTick then return HBZ:UnregisterTick(name) ; end
    name = tostring(  name or tostring(debug.getinfo(1).name)..tostring(debug.getinfo(2).name)  )
    if name == "" or not self.RegisteredTicks[name] then return false ; end
    local newRT = {}
    for k,v in pairs(self.RegisteredTicks) do  if type(k) == "string" then if k ~= name then newRT[k] = #newRT+1 ; newRT[#newRT+1] = v ; end ; end ; end
    if self.debug then print("HBZ:UnregisterTick : Callback unregistered for "..name) ; end
    self.RegisteredTicks = newRT
    return true
end


function HBZ:IsTickRegistered(name)
    if not self or not self.RegisteredTicks then return false ; end
    name = tostring(  name or tostring(debug.getinfo(0).name).."."..tostring(debug.getinfo(0).what).."/"..tostring(debug.getinfo(1).name).."."..tostring(debug.getinfo(1).what).."/"..tostring(debug.getinfo(2).name).."."..tostring(debug.getinfo(2).what).."/" )
    if self.RegisteredTicks[name] then return true ; end
    return false
end


function HBZ:ProcessRegisteredTicks()
    if not self or not self.RegisteredTicks then return end
    for k,v in pairs(self.RegisteredTicks) do 
        if    type(k) == "number" and v and v.callback
        then  v.callback()
        end
    end
end

------------------------------------------------------------------------------------------------------------

function HBZ:ValueBox_Track(targetObjName,targetValueBoxFirstValue)
    targetValueBoxFirstValue = targetValueBoxFirstValue or 9879879
    local targetValueBoxes = {}
    for k,obj in pairs(ObjectGet("value box")) do
        if    ( obj:GetComponent("Part").floats[0] or 0 ) == targetValueBoxFirstValue
        and     obj:GetComponent("Part").floats[1]
        and     obj:GetComponent("Part").floats[2]
        and     obj:GetComponent("Part").floats[3]
        then
              targetValueBoxes[#targetValueBoxes+1] = obj
              print("HBZ:ValueBox_Track : INFO : Found target value box #"..tostring(#targetValueBoxes))
        end
    end
    local targetObj  = false
    if type(targetObjName) == "nil" then targetObjName = "Me" ; targetObj = GameObject.Find("Player") ; end
    if type(targetObjName) == "userdata" and targetObjName.transform then targetObj = targetObjName ; targetObjName = tostring(targetObj) ; end
    if type(targetObjName) == "string" and ( string.lower(targetObjName) == "player"  or  string.lower(targetObjName) == "me"  ) then targetObjName = "Me" ; targetObj = GameObject.Find("Player") ; end
    targetObjName = tostring(targetObjName)
    if  not targetObj then
        for k,v in pairs(GetAllPlayers()) do
            if    not targetObj  and  type(k) == "string" and string.find(string.lower(k),string.lower(targetObjName))
            then  targetObjName = k ; targetObj = v.obj
            end
         end
    end
    if Slua.IsNull(targetObj) or not targetObj.transform then print("ValueBox_Track : ERROR : targetObj is either Null or does not have a .transform sub-key.") ; return false ; end
    print("HBZ:ValueBox_Track : INFO 2/2 : Found target Object: "..targetObjName)
    if not self.ValueBox_Track_Tab then self.ValueBox_Track_Tab = {} ; end
    for k,v in pairs(targetValueBoxes) do
        if not self.ValueBox_Track_Tab[targetObjName] then self.ValueBox_Track_Tab[targetObjName] = {} ; end
        self.ValueBox_Track_Tab[targetObjName][#self.ValueBox_Track_Tab[targetObjName]+1] = { obj1 = targetObj, obj2 = v, [1] = targetObj:GetHashCode(), [2] = v:GetHashCode() }
    end
    local callback_name = "ProcessTrackTab"
    local callback      =  function() HBZ:ProcessTrackTab() ; end
    if not self:IsTickRegistered(callback_name) then self:RegisterTick(callback_name,callback) ; end
 
end

------------------------------------------------------------------------------------------------------------

function HBZ:ProcessTrackTab()

    if not self.ValueBox_Track_Tab then self:UnregisterTick("ProcessTrackTab") ; end
    local c = 0
    for kt,vt in pairs(self.ValueBox_Track_Tab) do
    for k,v in pairs(vt) do
        c=c+1
        if not v or not v.obj1 or Slua.IsNull(v.obj1) or not v.obj2 or Slua.IsNull(v.obj2)
        then
            print("HBZ:ValueBox_Track : INFO : Lost track target: "..tostring(k))
            self.ValueBox_Track_Tab[kt][k] = nil
        else
            local curTra,curPos = false,false
            if v.obj1 then curTra = v.obj1.transform ; end
            if curTra then curPos = curTra.position ; end
            if curPos then
                for i = 1,3 do v.obj2:GetComponent("Part").floats[i] = curPos[i] ; end
            end
        end
    end
    end
    if c == 0 then self:UnregisterTick("ProcessTrackTab") end
end

------------------------------------------------------------------------------------------------------------

function HBZ.ScaleTexture( texIn, nWidth, nHeight, transColor )
    if      HBZ.debug then print("HBZ.ScaleTexture : Enter function.") ; end
    if      type(transColor) == "nil" or ( type(transColor) == "boolean" and transColor ) then transColor = 0.35294118523597717 ; end
    if      type(texIn) == "string" and file_exists and file_exists(texIn)
    then    texIn = HBU.LoadTexture2D(texIn) ; if type(texIn) ~= "userdata" then if HBZ.debug then print("HBZ.ScaleTexture : texIn is not userdata (1) : "..type(texIn)) ; end ; return texIn end
    elseif  type(texIn) ~= "userdata" or not texIn.format or not texIn.height or not texIn.width
    then    if HBZ.debug then print("HBZ.ScaleTexture : texIn is not userdata (2) : "..type(texIn)) ; end ; return texIn
    end
    if      type(nWidth) == "number" then nWidth = nWidth-(nWidth%1)
    elseif  type(nWidth) == "string" and nWidth:sub(-1) == "%" and tonumber(nWidth:sub(1,-2)) and tonumber(nWidth:sub(1,-2)) ~= 0 then nWidth = math.floor( texIn.width / (100/tonumber(nWidth:sub(1,-2))) )
    else    nWidth = 256
    end
    if      type(nHeight) == "number" then nHeight = nHeight-(nHeight%1)
    elseif  type(nHeight) == "string" and nHeight:sub(-1) == "%" and tonumber(nHeight:sub(1,-2)) and tonumber(nHeight:sub(1,-2)) ~= 0 then nHeight = math.floor( texIn.height / (100/tonumber(nHeight:sub(1,-2))) )
    else    nHeight = 256
    end
    nWidth,nHeight = nWidth or 256, nHeight or 256
    local oWidth,oHeight = texIn.width,texIn.height
    local texOut = Texture2D.Instantiate(Texture2D.blackTexture)
    if not texOut or type(texOut) ~= "userdata" then return texIn end
    texOut:Resize(nWidth,nHeight)
    for y = 0,nHeight-1 do
    for x = 0,nWidth-1  do
        local vx,vy = math.min( oWidth, math.floor(oWidth/nWidth*x) ), math.min( oHeight, math.floor(oHeight/nHeight*y) )
        local p = texIn:GetPixel(vx,vy)
        if transColor and p.r == transColor and p.g == transColor and p.b == transColor then   p.a = 0   end
        texOut:SetPixel(x, y, p)
    end
    end
    texOut:Apply()
    GameObject.Destroy(texIn)
    if HBZ.debug then print("HBZ.ScaleTexture : Exit  function.") ; end
    return texOut
end

------------------------------------------------------------------------------------------------------------

    function HBZ.CropTexture( texIn, x1, y1, x2, y2, transColor )

        if      HBZ.debug then print("HBZ.CropTexture : Enter function.") ; end

        if      type(transColor) == "nil" or ( type(transColor) == "boolean" and transColor ) then transColor = 0.35294118523597717 ; end

        if      type(texIn) == "string" and file_exists and file_exists(texIn)
        then    texIn = HBU.LoadTexture2D(texIn) ; if type(texIn) ~= "userdata" then if HBZ.debug then print("HBZ.CropTexture : texIn is not userdata (1) : "..type(texIn)) ; end ; return texIn end
        elseif  type(texIn) ~= "userdata" or not texIn.format or not texIn.height or not texIn.width
        then    if HBZ.debug then print("HBZ.CropTexture : texIn is not userdata (2) : "..type(texIn)) ; end ; return texIn
        end

        if      type(x1) == "number" then x1 = x1-(x1%1)
        elseif  type(x1) == "string" and x1:sub(-1) == "%" and tonumber(x1:sub(1,-2)) and tonumber(x1:sub(1,-2)) ~= 0 then x1 = math.floor( texIn.width / (100/tonumber(x1:sub(1,-2))) )
        else    x1 = 0
        end

        if      type(y1) == "number" then y1 = y1-(y1%1)
        elseif  type(y1) == "string" and y1:sub(-1) == "%" and tonumber(y1:sub(1,-2)) and tonumber(y1:sub(1,-2)) ~= 0 then y1 = math.floor( texIn.height / (100/tonumber(y1:sub(1,-2))) )
        else    y1 = 0
        end

        if      type(x2) == "number" then x2 = x2-(x2%1)
        elseif  type(x2) == "string" and x2:sub(-1) == "%" and tonumber(x2:sub(1,-2)) and tonumber(x2:sub(1,-2)) ~= 0 then x2 = math.floor( texIn.width / (100/tonumber(x2:sub(1,-2))) )
        else    x2 = texIn.width
        end

        if      type(y2) == "number" then y2 = y2-(y2%1)
        elseif  type(y2) == "string" and y2:sub(-1) == "%" and tonumber(y2:sub(1,-2)) and tonumber(y2:sub(1,-2)) ~= 0 then y2 = math.floor( texIn.height / (100/tonumber(y2:sub(1,-2))) )
        else    y2 = texIn.height
        end

        local oWidth,oHeight = texIn.width,texIn.height
        local nWidth,nHeight = math.min(texIn.width-x1, x2 - x1), math.min(texIn.height-y1, y2 - y1)

        if    oWidth < nWidth  or oHeight < nHeight then return texIn ; end

        if    HBZ.debug then print( "HBZ.CropTexture : Original Width/Height: "..tostring(oWidth).."/"..tostring(oHeight) ) ; end
        if    HBZ.debug then print( "HBZ.CropTexture : New      Width/Height: "..tostring(nWidth).."/"..tostring(nHeight) ) ; end

        local texOut = Texture2D.Instantiate(Texture2D.blackTexture)

        if not texOut or type(texOut) ~= "userdata" then return texIn end

        texOut:Resize(nWidth,nHeight)

        texOut:SetPixels(texIn:GetPixels(x1,y1,nWidth,nHeight))

        texOut:Apply()
        GameObject.Destroy(texIn)
        if HBZ.debug then print("HBZ.CropTexture : Exit  function.") ; end
        return texOut
    end

------------------------------------------------------------------------------------------------------------

function string.ToByteArray(str) local rt = {} ; if type(str)  ~= "string" then return rt ; end ; for i = 1,#str do rt[i] = string.byte(str,i) ; end ; return rt ; end
function printmetaitem(itemKey,itemVal,pre,maxWidth) print(string.format("%"..tostring(maxWidth or 40).."s = '%s'   -- %s",(pre or "")..tostring(itemKey),tostring(itemVal),type(itemVal))) ;end
function getmetainfo(tabIn,pre) pre = pre or "" ; local keys,mt,mw={},getmetatable(tabIn),0 ; for k,v in pairs(mt) do keys[#keys+1]=k ; mw=math.max(mw,#tostring(k)) end; table.sort(keys) ; mw=tostring(mw+#pre+2) ; for k,v in pairs(keys) do if v:sub(1,1) ~= "_" then printmetaitem(v,tabIn[v],pre) end;end;end
function HBZ:TakeScreenshot(quality) quality = quality or 1 ; self.screenshotReady = false ; HBU.GetPostProcessingLayer().antialiasingMode = 0 ; self.screenshot = Application.persistentDataPath .. "/screenshots/" .. os.date("screenshot-%Y-%m-%d_%H-%M-%S.png") ; HBU.TakeScreenshot( self.screenshot, function() self.screenshotReady = true  ; end, quality ) ; end
function HBZ:ScaleScreenshot(width,height) width = width or "50%" ; height = height or "50%" ; if not self or not self.screenshot or not self.screenshotReady then return false ; end ; local newTex = HBZ.ScaleTexture(self.screenshot,width,height,false) ; if newTex then HBU.SaveTexture2D(newTex,self.screenshot) ; if not Slua.IsNull(newTex) then GameObject.Destroy(newTex) ; end ; end ; end

function HBZ:SendWWW(  url,  form_data,  form_filename,  form_id,  form_type,  callback  )
    if not url and not form_id and not form_data and not form_filename and not form_type and not callback then print("HBZ:SendWWW(  url,  form_data,  form_filename,  form_id,  form_type,  callback  )") ; return ; end
    local curCount,SendWWWObject,SendWWWQID,SendWWWUID,temp_file = "",false,false,tostring(math.random(10000000000000,99999999999999)), Application.persistentDataPath .. "/userData/SendWWW.png"
    curCount = "" ; if  self.SendWWWQTab then curCount = tostring(#self.SendWWWQTab) ; end
    print("--------------------------------------------------------------------------------")
    print("-- SendWWW : ("..curCount.."/"..curCount..") : Starting transfer with below SendWWWSettings...")
    print("--------------------------------------------------------------------------------")
    url           = tostring( url           or "http://zhoul.gotdns.org/cgi-bin/upload.CMD?upload=true&html=false"  )
    form_id       = tostring( form_id       or "file"  )
    form_filename = tostring( form_filename or "filename.txt"  )
    form_type     = tostring( form_type     or "multipart/form-data" ) -- "application/x-www-form-urlencoded"  )
    form_data     = form_data or "This is a new test of the\n emergency broadcast system?!\nPlease remain clam.\nIf you are not yet a clam\n bark like a clam would bark,\n and you will be turned into one.\n"
    SendWWWObject = {  url = url, form_id = form_id, form_filename = form_filename, form_type = form_type, form_data = form_data,  callback = callback, uid = SendWWWUID, temp_file = temp_file, start_time = os.clock(), }
    for k,v in pairs (SendWWWObject) do  v = string.gsub( tostring(v),  "[\r\n]", "\\n" ) ; print(string.format("%40s = %s", k, v )) end
    if not self.SendWWWQTab then self.SendWWWQTab = {} ; end
    SendWWWQID = #self.SendWWWQTab+1
    self.SendWWWQTab[SendWWWQID] = SendWWWObject
    self:ProcessWWWQ(true)
    return SendWWWUID
end


function HBZ:ProcessWWWQ(startCall)

    if      not self or not self.SendWWW or not self.SendWWWQTab then return end

    local curCount = "" ; if  self.SendWWWQTab then curCount = tostring(#self.SendWWWQTab) ; end

    if      #self.SendWWWQTab ~= 0  and  self.RegisterTick  and  not self:RegisterTick("ProcessWWWQ")  then   self:RegisterTick("ProcessWWWQ", function() self:ProcessWWWQ() ; end )  ; return ; end

    if      startCall  then return  end

    if      #self.SendWWWQTab == 0 then self:UnregisterTick("ProcessWWWQ") ; return ; end

    if      self.SendWWWQTab[1] and not self.SendWWWQTab[1].wwwform
    then
            if      type(self.SendWWWQTab[1].form_data) == "nil"
            then
                    print("-- SendWWW : Detected nil as form_data.  Using default junk data.") 
                    self.SendWWWQTab[1].form_data = Slua.MakeArray("System.Byte",string.ToByteArray( "This is a new test of the\n emergency broadcast system?!\nPlease remain clam.\nIf you are not yet a clam\n bark like a clam would bark,\n and you will be turned into one.\n" ))

            elseif  type(self.SendWWWQTab[1].form_data) == "string"
               and  io and io.exists and io.exists(self.SendWWWQTab[1].form_data)
               and  io.ToByteArray
            then
                    print("-- SendWWW : Detected string(file) as form_data.  Converted to ByteArray table.")
                    self.SendWWWQTab[1].form_data = io.ToByteArray(self.SendWWWQTab[1].form_data)
                    return

            elseif  type(self.SendWWWQTab[1].form_data) == "string"  and  string  and  string.ToByteArray
            then
                    print("-- SendWWW : Detected string(text) as form_data.  Converted to ByteArray table.")
                    self.SendWWWQTab[1].form_data = string.ToByteArray(self.SendWWWQTab[1].form_data)

                    return
            elseif  type(self.SendWWWQTab[1].form_data) == "userdata" and string.find(tostring(self.SendWWWQTab[1].form_data),"Texture2D") and io and io.ToByteArray
            then
                    print("-- SendWWW : Detected Texture2D as form_data.  Saved texture to temporary file.")
                    HBU.SaveTexture2D(self.SendWWWQTab[1].form_data, self.SendWWWQTab[1].temp_file) ; self.SendWWWQTab[1].form_data = self.SendWWWQTab[1].temp_file
                    return

            elseif  type(self.SendWWWQTab[1].form_data) == "userdata" and not string.find(tostring(self.SendWWWQTab[1].form_data),"Array<Byte>")
            then
                    print("-- SendWWW : Detected unknown userdata as form_data.  Set = false")
                    self.SendWWWQTab[1].form_data = false

            elseif  type( self.SendWWWQTab[1].form_data) == "table"  and  #self.SendWWWQTab[1].form_data > 0 and type(self.SendWWWQTab[1].form_data[1]) == "number" and self.SendWWWQTab[1].form_data[1] >= 0 and self.SendWWWQTab[1].form_data[1] <= 255
            then
                    print("-- SendWWW : Detected table(ByteArray) as form_data.  Converted to ByteArray userdata.") 
                    self.SendWWWQTab[1].form_data = Slua.MakeArray("System.Byte",self.SendWWWQTab[1].form_data)

            elseif  type( self.SendWWWQTab[1].form_data) == "table"  and  dumptable  and  string  and  string.ToByteArray
            then
                    print("-- SendWWW : Detected table(data) as form_data.  Converted to string(text).")
                    self.SendWWWQTab[1].form_data = string.ToByteArray(dumptable(self.SendWWWQTab[1].form_data,self.SendWWWQTab[1].form_filename))
                    return
            end

            local   wwwform = WWWForm()
            if      self.SendWWWQTab[1].form_data
            then
                    wwwform:AddBinaryData(  self.SendWWWQTab[1].form_id,  self.SendWWWQTab[1].form_data,  self.SendWWWQTab[1].form_filename,  self.SendWWWQTab[1].form_type )
                    wwwform:AddField( "Post File", "Submit" )
            end
            if      getmetainfo then  getmetainfo(wwwform,"wwwform.")  ; end
            local www = WWW( self.SendWWWQTab[1].url, wwwform )
            self.SendWWWQTab[1].wwwform = wwwform
            self.SendWWWQTab[1].www = www
            return

    elseif  self.SendWWWQTab[1] and self.SendWWWQTab[1].www and self.SendWWWQTab[1].www.isDone
    then
            print("--------------------------------------------------------------------------------")
            getmetainfo(self.SendWWWQTab[1].www,"www.")
            self.SendWWWQTab[1].www:Dispose()
          --self.SendWWWQTab[1].www,self.SendWWWQTab[1].wwwform = false,false
            print( string.format( "%40s = %.4f seconds.", "total_time", os.clock()-self.SendWWWQTab[1].start_time ) )
            print("--------------------------------------------------------------------------------")
            print("-- SendWWW : (".."1".."/"..curCount..") : Transfer complete. Result above.")
            print("--------------------------------------------------------------------------------")
            if    type(self.SendWWWQTab[1].callback) == "function"
            then
                  print("-- SendWWW : Executing callback for "..tostring(self.SendWWWQTab[1].www.uid or ""))
                  local res = self.SendWWWQTab[1]:callback(tostring(self.SendWWWQTab[1].www.text),tonumber(self.SendWWWQTab[1].www.size or 0),tostring(self.SendWWWQTab[1].www.error),tostring(self.SendWWWQTab[1].www.uid))
                  if      type(res) == "nil"                  then print("-- SendWWW : Execution of callback for "..tostring(self.SendWWWQTab[1].www.uid or "").." is complete, and callback did not return any result.")
                  elseif  type(res) == "boolean" and res      then print("-- SendWWW : Execution of callback for "..tostring(self.SendWWWQTab[1].www.uid or "").." is complete, and callback returned successful (true) result.")
                  elseif  type(res) == "boolean" and not res  then print("-- SendWWW : Execution of callback for "..tostring(self.SendWWWQTab[1].www.uid or "").." is complete, and callback returned failed (false) result.")
                  elseif  type(res) == "string"               then print("-- SendWWW : Execution of callback for "..tostring(self.SendWWWQTab[1].www.uid or "").." is complete, and callback returned a string: '"..res.."'")
                  else                                             print("-- SendWWW : Execution of callback for "..tostring(self.SendWWWQTab[1].www.uid or "").." is complete, and callback returned a "..type(res)..".  While I have *no* idea what that even means, I'm sure you, the 'smarter' of us, does...")
                  end
            end
            table.remove(self.SendWWWQTab,1)
            return
    end

    return

end

------------------------------------------------------------------------------------------------------------

function HBZ:SetupPaths()
    if Paths then return end
    Paths = {
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
end

------------------------------------------------------------------------------------------------------------

function TutorialVidControl(vidURL)

    if    vidPlayer
    then
        if    vidURL
        then
            vidPlayer.Screen:LoadURL(vidURL)
            vidPlayer.vidURL = vidURL
            vidPlayer.active = true
            vidPlayer.obj:SetActive(vidPlayer.active)
            return true
        else
          --vidPlayer.Screen:PlayPause() ; return true
            vidPlayer.active = not vidPlayer.active
            vidPlayer.obj:SetActive(vidPlayer.active)
        end
    end

    vidURL = vidURL or "http://zhoul.gotdns.org/p/p1.mp4"

    vidPlayer = { obj = GameObject.Find("TutorialScreen"), URL = vidURL, }

    if not vidPlayer.obj then print("TutorialVidControl : Can't find the TutorialScreen object.  Are you not in builder?") ; return false ; end
    vidPlayer.Screen = vidPlayer.obj:GetComponent("HBVideoPlayer") 
    vidPlayer.Screen.transform.localScale = Vector3.one * 0.04
    vidPlayer.Screen.transform.position   = vidPlayer.Screen.transform.position + Vector3.up * 10 + Vector3.forward*10
    vidPlayer.Screen:LoadURL(vidPlayer.URL)
    vidPlayer.Screen:Play()
    vidPlayer.active = true
    return true
end

------------------------------------------------------------------------------------------------------------

function TexturesToPrimitiveSphere(textures,radius,maxCount)

    if type(textures) ~= "table" then print("TexturesToPrimitiveSphere : ERROR : Whatever you passed in the first argument should have been a table of textures." ) ; return ; end
    radius = radius or 20
    maxCount = maxCount or 360
    local tt = {}
    for k,v in pairs(textures) do
        if #tt < maxCount and tostring(v):sub(-10) == "Texture2D)" then  tt[#tt+1] = v end
    end
    if #tt == 0 then print("TexturesToPrimitiveSphere : ERROR : Whatever you passed in the first argument was a table, but it didnt have any UnityEngine Texture2Ds.  WTF." ) ; return ; end
    local count = 0
    for i = 0,360,360/#tt  do
        count = count + 1
        local vec = math.pointonsphereU(i,i,radius)
        if vec then TextureToPrimitive(tt[(count-1)%#tt+1],nil,vec.x,vec.y,vec.z) ; end
        if vec.x ~= 0 and vec.y ~= 0 and vec.z ~= 0
        then
            count = count + 1
            vec = Vector3(vec.x*-1,vec.y,vec.z)
            TextureToPrimitive(tt[(count-1)%#tt+1],nil,vec.x,vec.y,vec.z)
            count = count + 1
            vec = Vector3(vec.x*-1,vec.y*-1,vec.z)
            TextureToPrimitive(tt[(count-1)%#tt+1],nil,vec.x,vec.y,vec.z)
            count = count + 1
            vec = Vector3(vec.x*-1,vec.y*-1,vec.z*-1)
            TextureToPrimitive(tt[(count-1)%#tt+1],nil,vec.x,vec.y,vec.z)
        end

    end
end

------------------------------------------------------------------------------------------------------------

-- TexturesToPrimitiveCircle(TextureCache,20,1000)
function TexturesToPrimitiveCircle(textures,radius,maxCountPerRow,maxRows)
    if type(textures) ~= "table" then print("TexturesToPrimitiveSphere : ERROR : Whatever you passed in the first argument should have been a table of textures. Douche." ) ; return ; end
    radius = radius or 20
    maxCountPerRow = maxCountPerRow or 50
    maxRows        = maxRows        or maxCountPerRow * 6
    --pPos = GameObject.Find("Player").gameObject:GetComponent("Rigidbody").transform.position
    local tt = {}
    for k,v in pairs(textures) do
        if #tt < maxCountPerRow and tostring(v):sub(-10) == "Texture2D)" then  tt[#tt+1] = v end
    end
    if #tt == 0 then print("TexturesToPrimitiveCircle : ERROR : Whatever you passed in the first argument was a table, but it didnt have any UnityEngine Texture2Ds.  WTF." ) ; return ; end
    local count = 0
    for i = 0,360,360/#tt  do
        count = count + 1
        local vecX,vecY,vecZ = math.pointoncircleU(radius,i)
        if vecX and vecY and vecZ then TextureToPrimitive(tt[(count-1)%#tt+1],PrimitiveType.Quad,vecX,vecY,vecZ) ; end
        print(radius,count,i,pPos,vecX,vecY,vecZ)
    end
end

------------------------------------------------------------------------------------------------------------

function TextureToPrimitive(tex,primType,relForward,relUp,relRight)
  if not string.find(tostring(tex),"Texture2D") then print("TextureToPrimitive : ERROR : variable 'tex' does not appear to be a texture.") ; return ; end
  if not TexturePrimitives then TexturePrimitives = {} ; end
  primType = primType or PrimitiveType.Quad -- Capsule, Cube, Cylinder, Plane, Quad, Sphere
  relForward,relUp,relRight = relForward or 15, relUp or 0, relRight or 0
  local sha = Shader.Find("Legacy Shaders/Transparent/VertexLit") --Legacy Shaders/Transparent/Diffuse -- can also do Legacy Shaders/Transparent/Cutout/VertexLit  that just clips it if alpha is above 0.
  local pri = GameObject.CreatePrimitive(primType)
  local ren = pri:GetComponent("Renderer")
  if ren
  then
      ren.material.mainTexture = tex
      if sha then ren.material.shader = sha ; end
  end
  if pri and Camera and Camera.main
  then
      local curPos = Camera.main.transform.position
      if relForward ~= 0 then curPos = curPos + Camera.main.transform.forward*relForward ; end
      if relRight   ~= 0 then curPos = curPos + Camera.main.transform.right*relRight     ; end
      if relUp      ~= 0 then curPos = curPos + Camera.main.transform.up*relUp           ; end
      pri.transform.position = curPos
      pri.transform.rotation = Camera.main.transform.rotation
      TexturePrimitives[#TexturePrimitives+1] = pri
  end
  return pri
end

------------------------------------------------------------------------------------------------------------

function ClearTexturePrimitives() if not TexturePrimitives then return end ; local resetTab = false ; for k,v in pairs(TexturePrimitives) do if not resetTab then resetTab = true ; end ; if v and not Slua.IsNull(v) then print("GameObject.Destroy("..tostring(v)..")") ; GameObject.Destroy(v) ; end ; end ; if resetTab then TexturePrimitives = {} ; end ; end

------------------------------------------------------------------------------------------------------------

function keys(inp)
    inp = inp or ""
    inp = string.lower(tostring(inp))
    local tKeyCode = {}
    for k,v in pairs(KeyCode) do tKeyCode[#tKeyCode+1] = k ; end
    table.sort(tKeyCode)
    for k,v in pairs(tKeyCode) do if string.find(string.lower(v),inp) then print( string.format( "KeyCode.%s = %d", v, KeyCode[v] ) ) ; end ; end
end

------------------------------------------------------------------------------------------------------------

function findmeta(...)
    for kt,vt in pairs({...}) do
        if not vt or not getmetatable(vt) then return "" ; end
        for k,v in pairs(_G) do   if getmetatable(v) and vt == v then return tostring(k) ; end   ; end
    end
    return ""
end

------------------------------------------------------------------------------------------------------------

function showmeta(...)
    local ignore_list = { ["Color"] = true, ["Vector2"] = true, ["Vector3"] = true, ["Vector4"] = true, ["Quaternion"] = true, ["UnityEngine.Vector2.Instance"] = true, ["UnityEngine.Vector3.Instance"] = true, ["UnityEngine.Vector4.Instance"] = true, ["UnityEngine.Quaternion.Instance"] = true, ["UnityEngine.Color.Instance"] = true, ["OperatingSystemFamily"] = true, ["jit"] = true, ["__main_state"] = true, ["_G"] = true, }
    local processed_input = false
    local gList,gMaxW = {},0
    for k,v in pairs(_G) do if type(k) == "string" and not ignore_list[k] and getmetatable(v) then gList[#gList+1] = k ; gMaxW = math.max(gMaxW,#k)  end ; end
    gMaxW = gMaxW + 2
    table.sort(gList)
    for k,v in pairs({...}) do
        processed_input = true
        local aTab = false
        if    type(v) == "string"
        then
              for k2,v2 in pairs(gList)
              do
                  if  string.find(string.lower(v2),string.lower(v))
                  then
                      aTab = getmeta(v)
                      if    echo then echo(aTab)
                      else  for t1k,t1v in pairs(aTab) do if type(t1v) == "table" then for t2k,t2v in pairs(t1v)  do if type(t2v) == "string" then print(t2v) ; end ; end ; end ; end
                      end
                  end
              end
        end
    end
    if not processed_input
    then
        local s,d,l,f1,f2 = "", math.floor(198/gMaxW), math.ceil(#gList/math.ceil(198/gMaxW)), " %-"..tostring(gMaxW).."s", " %s"
        for i = 1,198 do s=s.."." ; end ; print(s) ; s=""
        for line = 1,l do
        for col  = 0,d-1 do
            local f = f1
            if col == d-1 then f = f2 end
            s = s..string.format( f, gList[line+(col*l)] or "" )
        end ; print( s ) ; s = "" 
        end
    end
end

function getmeta(...)
  local aTab = {}
  for k,name in pairs({...}) do
      local element = _G
      local elementParts = {}
      if    type(name) == "string"
      then
            for part in string.split(name,"[\x5d[\x22\x27.]") do if part and #part ~= 0 and element[part] then elementParts[#elementParts+1] = part ; element = element[part] ; elseif part and #part ~= 0 and tonumber(part) and element[tonumber(part)] then elementParts[#elementParts+1] = tonumber(part) ; element = element[tonumber(part)] ; end ; end
            if type(element) ~= "nil" then aTab[tostring(name)] = getmeta_1( element, name ) end
      end
  end
  return aTab
end

function getmeta_1(element,name)
    local aTab = {}
    if      type(element) == "table"
    then
            if    getmetatable(element) and table.count(getmetatable(element)) > 1
            then  aTab[#aTab+1] = getmeta_2(element,name)
            else  for k,v in pairs(element) do if type(v) == "table" then aTab[#aTab+1] = getmeta_1(v,name.."."..tostring(k)) ; else aTab[#aTab+1] = getmeta_2(v,name.."."..tostring(k)) ; end ; end
            end

    elseif  type(element) == "userdata"
    then    
            aTab[#aTab+1] = getmeta_2(element,name)
    end
    return unpack(aTab)
end

function getmeta_2(element,name)
    if  type(element) == "table" or type(element) == "userdata"
    then
        local aTab = {}
        for k,v in pairs(getmetatable(element)) do
            if  k:sub(1,2) ~= "__" then
                aTab[#aTab+1] = string.format( "%-20s  %s",tostring(v), name.."."..tostring(k) )
            end
        end
        table.sort(aTab)
        return aTab
    end
end

------------------------------------------------------------------------------------------------------------

function many2one_encode(r,a,p,imax)
    if  many2one_debug then
        if   p == 1 then  print("imax = "..tostring(imax) ) ; print("r = 0") ; print("fold 1")
                    else  print("fold "..tostring(p/imax+1))
        end
        print( "  r = r("..tostring(r)..") + ( a("..tostring(a)..") * p("..tostring(p)..")" )
        print( "  p = p("..tostring(p)..") * imax("..tostring(imax)..") == "..tostring(p*imax) )
    end
    return r+a*p,p*imax
end


function many2one(imax,...)
    local _args=({...})
    if not imax and #_args == 0 then return 0 ; end
    if not imax then for ai,a in pairs(_args) do if type(a) == "table" or type(a) == "Vector" or type(a) == "vector" then math.max(unpack(a),imax or 0) ; elseif type(a) == "number" then imax = math.max(imax or 0, (a or 0)); end ; end ; if imax then imax = imax + 1 ; end ; end
    local p = 1
    local r = 0
    for ai,a in pairs(_args) do if type(a) == "table" or type(a) == "Vector" or type(a) == "vector" then for k,v in pairs(a) do r,p = many2one_encode(r,v,p,imax) ; end ; elseif type(a) == "number" then r,p = many2one_encode(r,a,p,imax); end ; end
    local s = ""
    return r,imax
end


function one2many(i,imax)

    imax = (tonumber(imax or 1) or 1)
    i    = (tonumber(i or 1) or 1)
    if not imax or not i then return {i} ; end
    local t = {}
    local p = 1
    while i > 0 do t[#t+1] = i%imax ; i = math.floor(i/imax) ; end
    return t
end

------------------------------------------------------------------------------------------------------------

function Set_Object_Value(obj,key,value,noLogMessage) if not obj or not key or ( not obj[key] and not getmetatable(obj)) then  if not noLogMessage and Log then  Log("Set_Object_Value() Failed",tostring(obj),key,value) ; end ; return false  end  ;  if type(value) == "nil" and type(obj[key]) == "boolean" then value = not obj[key]  end ; obj[key] = value ; if not noLogMessage and Log then  Log(key,"=",value) ; end ; return value ; end

------------------------------------------------------------------------------------------------------------

function Log(...)
    local msgArray = { os.date(), }
    local msg      = ""
    for k,v in pairs({...}) do
        if      type(v) == "table" then for k2,v2 in pairs(v) do msgArray[#msgArray+1] = string.format("%30s %s",tostring(k2), tostring(v2)) ; end
        else    msgArray[#msgArray+1] = tostring(v)
        end
    end
    if #msgArray > 1 then msg = table.concat(msgArray," ") ; end
    Debug.Log( msg )
end

------------------------------------------------------------------------------------------------------------

function getLogLines(lineCount)
  local dataPath =  Application.dataPath
  local dataTab,tempTab = {}, {}
  lineCount = lineCount or 50
  forLineIn(dataPath.."/output_log.txt",function(line) dataTab[#dataTab+1] = line  ; end,true,true,true)
  local l,h = #dataTab-lineCount, #dataTab
  if  l < 1 then l = 1 ; end
  for i = #dataTab,#dataTab-lineCount,-1  do  if dataTab[i] then print(dataTab[i]) ; end  end
end

------------------------------------------------------------------------------------------------------------

function iter_to_table(obj)
    local  ret = {}
    if  type(obj) == "userdata" and string.find(tostring(obj),"Array") then
      for v in Slua.iter(obj) do ret[#ret+1] = v ; end
    end
    return ret
end

------------------------------------------------------------------------------------------------------------


function GetChildren(obj)
    if not type(obj) == "userdata" then print("GetChildren : obj is not userdata") ; return end
    local rt = {}
    local ccount = obj.transform.childCount
    for i = 0,ccount-1 do  rt[#rt+1] = obj.transform:GetChild(i) end
    return rt
end

------------------------------------------------------------------------------------------------------------

function GetAllObjects()  local r = {} ; for kt,t in pairs( { iter_to_table(GameObject.FindObjectsOfType(GameObject)), iter_to_table(GameObject.FindGameObjectsWithTag("Untagged")) } ) do for k,v in pairs(t) do r[#r+1] = v ; end ; end ; return r ; end

------------------------------------------------------------------------------------------------------------

-- function GetAllObjectsOfType(oType) oType = string.lower(tostring(oType or "")) ; local r = {} ; if not GetAllObjects then return r ; end ; for k,v in pairs(GetAllObjects()) do if string.find(string.lower(tostring(v)),oType) then r[#r+1] = v ; end ; end ; return r ; end
function GetAllObjectsOfType(...)
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

ObjectGet = GetAllObjectsOfType
ObjectG   = GetAllObjectsOfType
Objectg   = GetAllObjectsOfType
OG        = GetAllObjectsOfType
GO        = GetAllObjectsOfType

------------------------------------------------------------------------------------------------------------

function DestroyObjectOfType(oType,printEachDestroy) oType = string.lower(tostring(oType or ""))  local r = {} ; if oType == "" then if printEachDestroy then print("DestroyObjectOfType : ERROR : oType is blank.  I will not let you destroy 'ALL' of the objects.") ; end ; return r ; end ; if not GetAllObjects then return r ; end ; for k,v in pairs(GetAllObjects()) do if string.find(string.lower(tostring(v)),oType) then r[#r+1] = tostring(v) ; if printEachDestroy then print("DestroyObjectOfType() : "..tostring(v)) ; end ; GameObject.Destroy(v.gameObject) ; end ; end ; return r ; end

function DestroyObjectsOfType(...) local printEachDestroy,objectsToDestroy,countDestroyed = true,{},0 ;  for k,v in pairs({...}) do if type(v) == "string" then  objectsToDestroy[#objectsToDestroy+1] = v ; elseif type(v) == "boolean" then printEachDestroy = v ; end ; end ; for k,v in pairs(objectsToDestroy) do  countDestroyed = countDestroyed + #DestroyObjectOfType(v,printEachDestroy) ; end ; print(tostring(countDestroyed).." objects destroyed.") ; end

ObjectDestroy = DestroyObjectsOfType
ObjectD       = DestroyObjectsOfType
Objectd       = DestroyObjectsOfType
OD            = DestroyObjectsOfType
DO            = DestroyObjectsOfType

------------------------------------------------------------------------------------------------------------

function SetupObjectList()

    if not ObjectList or ObjectList.reset
    then

        ObjectList = {
            lastUpdate    = os.clock(),
            listWidth     = 200,
            iter_to_table = function(obj) local  ret = {} ; if  type(obj) ~= "userdata" or tostring(obj):sub(1,5) ~= "Array" then return ret ; end ; for v in Slua.iter(obj) do ret[#ret+1] = v ; end ; return ret ; end,
            GetAllObjects = function(self)  local r = {} ; for kt,t in pairs( { self.iter_to_table(GameObject.FindObjectsOfType(GameObject)), self.iter_to_table(GameObject.FindWithTag("Untagged")) } ) do for k,v in pairs(t) do r[#r+1] = v ; end ; end ; return r ; end,
            List          = function(self,...)
                                local st,noPrint = {},false
                                for k,v in pairs({...}) do if type(v) == "string" then st[#st+1] = string.lower(v) ; elseif type(v) == "boolean" then noPrint = v ; end ; end
                                if #st == 0 then st[1] = "" ; end
                                local r,wMax = {},10
                                for k,v in pairs(self:GetAllObjects()) do
                                    local i = 1
                                    while i <= #st do
                                          if  string.find(string.lower(tostring(v)),st[i])
                                          then
                                              i = #st + 1
                                              local s = tostring(v):sub(1,-26)
                                              if s == "" or s == " " then s = "Untagged" ; end
                                              r[#r+1] = s
                                              wMax = math.max(wMax,#r[#r])
                                          else
                                              i = i + 1
                                          end
                                    end
                                end
                                table.sort(r)
                                local eMax,oStr = math.floor((self.listWidth or 180)/wMax),""
                                if noPrint then self.ListLast = r ; return r ; end
                                for k,v in pairs(r) do oStr = string.format("%s  %-"..tostring(wMax).."s", oStr,v) ; if k%eMax == 0 then print(oStr) ; oStr = "" ; end ; end
                                if #oStr > 0 then print(oStr) ; end ;
                                print("  Count:"..tostring(#r))
                                self.ListLast = r
                            end,
            ListLast      = false,
            Grouped       = function(self,...)
                                local r,rkeys,wMax,c,t = {},{},10,0,0 ;
                                for k,v in pairs(self:List(true,...)) do
                                  if not r[v] then rkeys[#rkeys+1] = v ; end
                                  r[v] = (r[v] or 0) + 1 ; wMax = math.max(wMax,#v+6)
                                end
                                local eMax,oStr = math.floor((self.listWidth or 180)/wMax),"" ;
                                if noPrint then self.GroupedLast = r ; return r ; end ;
                                for k,v in pairs(rkeys) do c=c+1 ; t=t+r[v] ; oStr = string.format("%s  %-"..tostring(wMax).."s", oStr, tostring(r[v])..":"..tostring(v) ) ; if c%eMax == 0 then print(oStr) ; oStr = "" ; end ; end
                                print(oStr) ; print("  Count:"..tostring(t))
                                if not self.GroupedLast then self.GroupedLast = r ; return ; end ;
                                local rl = {}
                                for k,v in pairs(self.GroupedLast) do rl[#rl+1] = k ; end
                                table.sort(rl)
                                local cCount = 0
                                print("Changes since last check:")
                                for rk,rv in pairs(rl) do
                                  local k,v = rv, self.GroupedLast[rv]
                                  if     not r[k]      then cCount = cCount + 1 ;       print( string.format( "%2s : %5s   %-5s : %s",   "--", tostring(v), "",             tostring(k) ) )
                                  elseif     r[k] <  v then cCount = cCount + 1 ;       print( string.format( "%2s : %5s > %-5s : %s",   " -", tostring(v), tostring(r[k]), tostring(k)  ) )
                                  elseif     r[k] >  v then cCount = cCount + 1 ;       print( string.format( "%2s : %5s < %-5s : %s",   " +", tostring(v), tostring(r[k]), tostring(k)  ) )
                                  end
                                end
                                for k,v in pairs(rkeys) do
                                  if not self.GroupedLast[v] then cCount = cCount + 1 ; print( string.format( "%2s : %5s   %-5s : %s",   "++", tostring(r[v]), "", tostring(v) ) ) ; end
                                end
                                if cCount == 0 then print("No changes") ; end
                                self.GroupedLast = r 
                            end,
            GroupedLast   = false,
        }
        ObjectList.G = ObjectList.Grouped

        setmetatable(ObjectList, { __call = function(self,...) self:List(...) ; end, } )

    end

    ObjectL = ObjectList
    Objectl = ObjectList
    OL      = ObjectList
    LO      = ObjectList
    OLG     = function(...) ObjectList:Grouped(...) end
end


------------------------------------------------------------------------------------------------------------

function GetAllVehicleParts()  return iter_to_table( GameObject.FindObjectsOfType("VehiclePiece") )  end

------------------------------------------------------------------------------------------------------------

function GetAllVehicles()
    local vehicle_iter_tab = GameObject.FindObjectsOfType("VehicleRoot")
    local vehicle_ret_tab = {}
    if    vehicle_iter_tab and not Slua.IsNull(vehicle_iter_tab)
    then
          for   v1 in Slua.iter(vehicle_iter_tab)
          do
                if    v1 and not Slua.IsNull(v1) and v1.transform.childCount > 0
                then
                      local newID = #vehicle_ret_tab+1
                      vehicle_ret_tab[newID] = { obj = v1, Parts = {}, }
                      for   k2 = 0,v1.transform.childCount-1
                      do
                            local v2    = v1.transform:GetChild(k2)
                            if    v2 and not Slua.IsNull(v2)
                            then
                                local body  = v2:GetComponent("Rigidbody").gameObject.transform
                              --local net   = v2:GetComponent("NetworkBase").gameObject.transform
                                local net   = false
                                vehicle_ret_tab[newID].Parts[#vehicle_ret_tab[newID].Parts+1] = { obj = v2, net = net, body = body }
                            end
                      end
                end
          end
    end
    return vehicle_ret_tab
end

------------------------------------------------------------------------------------------------------------

function GetMyVehicles()
  local vehicles = GameObject.FindObjectsOfType("VehicleRoot")
  local ret = {}
  if  not vehicles  or  Slua.IsNull(vehicles) then return ret end
  for t in Slua.iter(vehicles) do
    local nc = t:GetComponent("NetworkBase")
    if nc and not Slua.IsNull(nc) then --make sure networkbase isn't nil
      if nc.Owner then --make sure you're the owner of the vehicle
        table.insert(ret, t) --insert it into your return table
      end
    end
  end
  return ret
end

------------------------------------------------------------------------------------------------------------

function GetCurrentVehiclePart()
    if    not HBU.InSeat() then return false end
    local lowDist = 10000000
    local ret     = false
    for k,v in pairs(GetAllVehicleParts()) do if v and not Slua.IsNull(v) then local curDist = Vector3.Distance( GameObject.Find("Player").gameObject:GetComponent("Rigidbody").transform.position, v.transform.position ) ; if curDist < lowDist then lowDist = curDist ; ret = v ; end ; end ; end
    if ret then return ret ; else return false ; end
end

------------------------------------------------------------------------------------------------------------

function GetVehicleImages(filter)
  filter = string.lower(tostring(filter or ""))
  local path = Application.persistentDataPath.."/userData"
  local file = path.."/ref.hbr"
  local r    = {}
  local func = function(inp) inp = string.gsub(inp,"<[^>]*>","") ; if not string.find(inp,"[.][Pp][Nn][Gg]") or not string.find(inp,"Vehicle/") or ( filter and filter ~= "" and not string.find(string.lower(inp),filter) ) then return ; end ; r[#r+1] = path.."/"..inp ; end
--forLineIn(file,func,suppressBlankLines,trimEdgeWhiteSpace,trimAllWhiteSpace)
  forLineIn(file,func,true,true,false)
  table.sort(r)
  for k,v in ipairs(r) do local name = string.gsub(v,".*/","") ; name = string.gsub(name,"_[Ii][Mm][Gg][.][Pp][Nn][Gg]","") ; r[name] = v end
  return r
end

------------------------------------------------------------------------------------------------------------

function GetAllPlayers()
  local player_table     = iter_to_table(HBU.GetPlayers())
  local player_me        = GameObject.Find("Player")
  local player_table_ret = { }
  if    player_me and not Slua.IsNull(player_me)
  -- then  player_table_ret[1] = { obj = player_me, net = player_me.gameObject:GetComponent("NetworkBase"), body = player_me.gameObject:GetComponent("Rigidbody").transform, }
  then  player_table_ret[1] = { obj = player_me, body = player_me.gameObject:GetComponent("Rigidbody").transform, }
  end
  -- for k,v in pairs(player_table) do  if  ( v and not Slua.IsNull(v) )  and  ( not player_me or player_me ~= v )  then  local newID = #player_table_ret+1 ; player_table_ret[newID] = { obj = v, net = v.gameObject:GetComponent("NetworkBase") , body = v.gameObject:GetComponent("Rigidbody").transform } ; player_table_ret[v.playerName.name] = player_table_ret[newID] ; end ; end
  for k,v in pairs(player_table) do  if  ( v and not Slua.IsNull(v) )  and  ( not player_me or player_me ~= v )  then  local newID = #player_table_ret+1 ; player_table_ret[newID] = { obj = v, body = v.gameObject:GetComponent("Rigidbody").transform } ; player_table_ret[v.playerName.name] = player_table_ret[newID] ; end ; end
  return player_table_ret
end

------------------------------------------------------------------------------------------------------------

function GetAllTeleportLocations()
  local tlocs = {}
  for v in Slua.iter( HBU.GetTeleportLocations() ) do
      tlocs[#tlocs+1] = { name = v.locationName, color = v.color, position = v.transform.position }
  end
  return tlocs
end

------------------------------------------------------------------------------------------------------------

function GetPlayerPosition() return GameObject.Find("Player").gameObject:GetComponent("Rigidbody").transform.position ; end

------------------------------------------------------------------------------------------------------------

function SetPlayerMovement(toggle)
   local charmotor = Camera.main:GetComponentInParent("rigidbody_character_motor")
   if not charmotor or Slua.IsNull(charmotor) then return ; end
   if type(toggle) ~= "boolean" then toggle = true ; end
   charmotor.enabled = toggle
end

------------------------------------------------------------------------------------------------------------

function tp(...)
    local x,y,z = false,false,false
    local kr,vr = false,false
    local players = GetAllPlayers()
    for k,v in pairs({...}) do
        if      ( type(v) == "table" or type(v) == "Vector" ) and v[1] then x,y,z = v[1], v[2], v[3]
        elseif  ( type(v) == "table" or type(v) == "Vector" ) and v.x  then x,y,z = v.x,  v.y,  v.z
        elseif  ( type(v) == "number" or tonumber(v)        )          then if not x then x = tonumber(v) ; elseif not y then y = tonumber(v) ; elseif not z then z = tonumber(v) ; end
        elseif  ( type(v) == "string"                       )
        then
                kr,vr = table.has_key_value(players,v,nil,true,false,false)
                if not kr then kr,vr = table.has_key_value(players,v,nil,true,true,false) ; end
                if kr then local pos = vr.transform.position ; if pos then x,y,z = pos.x,pos.y,pos.z ; end ; end
        end
    end
    if not x or not y or not z then if #players > 0 then for k,v in pairs(players) do if type(v) == "string" then print("tp( \""..tostring(v).."\" )") ; end ; end ; end ; return ; end
    HBU.TeleportPlayer(Vector3(x,y,z))
end

------------------------------------------------------------------------------------------------------------

function GetDynamicFontList(filter) if not Font then return ; end ; filter = string.lower(filter or "") ; local rt = {}   ; for v in Slua.iter(Font.GetOSInstalledFontNames()) do if filter == "" or string.find(v,filter) then rt[#rt+1] = v ; end ; end ; return rt ; end

------------------------------------------------------------------------------------------------------------

function GetDynamicFonts(filter) filter = string.lower( filter or "" ) ; if not DynamicFonts then DynamicFonts = {} ; end ; for v in Slua.iter(Font.GetOSInstalledFontNames()) do if DynamicFonts[v] then DynamicFonts[DynamicFonts[v]] = Font.CreateDynamicFontFromOSFont(v, 19) ; else DynamicFonts[v] = #DynamicFonts + 1 ;  DynamicFonts[DynamicFonts[v]] = Font.CreateDynamicFontFromOSFont(v, 19) ; end ; end ; return DynamicFonts ; end

------------------------------------------------------------------------------------------------------------

function  testFunc2(count,func)
  --[[ Examples
    testFunc(1000000,function() local x,y   = 1.2, -10.3          ; local z = x ; end)
    testFunc(1000000,function() local w,x,y = 1.2, -10.3, 100.234 ; local z = math.max(w,x,y) ; end)
    testFunc(1000000,function() local model = "BIG_ASS_BUS" ; if ( string.find(model,"BUS") ) then ; end ; end)
  --]]

    count = tonumber(count or 1) or 1

    if    ( type(func) == "string"   ) then func = loadstring(func) ; end

    if    ( type(func) ~= "function" ) then print("# usage: testFunc( testCount, testFunc )") ; return nil ; end

    local start_clock,ret = os.clock(), false

    local gc_before = collectgarbage("count")*1024

    for i = 1,count do ret = func() end

    local gc_after         = collectgarbage("count")*1024
    local end_clock        = os.clock()
    local gc_diff          = gc_after - gc_before
    local timeElapsed      = end_clock - start_clock + 0.00000000001
    local timePerExec      = count/timeElapsed
    local printProvider    = echo or print
    local exec_time        = tostring(math.floor((end_clock-start_clock)*1000)*0.001)
    local execs_per_second = tostring(math.floor(1/timeElapsed*count))
    local mem_before       = tostring(gc_before)
    local mem_after      = tostring(gc_after)
    local mem_diff       = tostring(gc_diff)

    if  convert and convert.number and convert.number.separator
    then
        execs_per_second   = convert.number.separator(execs_per_second)
        mem_before         = convert.number.separator(mem_before)
        mem_after          = convert.number.separator(mem_after)
        mem_diff           = convert.number.separator(mem_diff)
    end

    printProvider( string.format( "  %16s = %s\n  %16s = %s\n  %16s = %s\n  %16s = %s\n  %16s = %s", "exec_time", exec_time, "execs_per_second", execs_per_second, "mem_before", mem_before, "mem_after", mem_after, "mem_diff", mem_diff  ) )
    return exec_time, execs_per_second, mem_before, mem_after, mem_diff
end


------------------------------------------------------------------------------------------------------------

function math.pointoncircleU(radius,angle,originX,originY,originZ) -- For Unity
    if not angle then angle = 0 else angle = tonumber(angle) ; end
    if not radius or not angle then print("usage: math.pointoncircle(radius,angle)\n or\nusage: math.pointoncircle(radius,angle,originX,originY)\n or\nusage: math.pointoncircle(radius,angle,originVector)") ; return originX,originY,originZ ; end
    local outType = "number" -- "number", "table", "Vector"
    local localpi = 3.1415926535897932
    if    not originX then originX = 0 end
    if    not originZ then originZ = 0 end
    if  type(originX) == "Vector"
    or  type(originX) == "table"
    then
        if      originX.x and originX.y and originX.z
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

function math.pointonsphereU(...) -- For Unity
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

function  io.exists(name)
  if not name then return false ; end
  local f = io.open(name,"r")
  if    f ~= nil  then  io.close(f)  ;  return true  ;  else  return false  ;  end
end

------------------------------------------------------------------------------------------------------------

function  io.create(name)
  local f = io.open(name,"w")
  if    f ~= nil  then  io.close(f) ;  return true  ;  else  return false  ;  end
end

------------------------------------------------------------------------------------------------------------

function io.ToByteArray(file,debug)
    local f,fsize,current,membefore = false,false,false,false
    local rt, st, blank = {}, os.clock(), string.char(0)
    if type(file) ~= "string" then return rt ; end
    f = io.open(file,"rb")
    if not f then return rt ; end
    current = f:seek()
    fsize = f:seek("end")
    f:seek("set",current)
    if debug then print(  string.format(  "%20s = %s\n%20s = %s", "File", file, "Size", tostring(fsize) ) ) ; end
    membefore = collectgarbage("count")*1024
    for i = 1,fsize do rt[i] = string.byte( f:read(1) or blank ) ; end
    if  debug then
        print(
          string.format(  string.rep("%20s = %s\n",4):sub(1,-2),
            "Byte/Table Count", tostring( #rt ),
            "Mem Use",          tostring( collectgarbage("count")*1024-membefore ),
            "Mem VS File Size", tostring( math.floor( (collectgarbage("count")*1024-membefore) / fsize ) ),
            "Run Time",         tostring( os.clock() - st )
          )
        )
    end
    f:close()
    return rt
end

--- HBZ:SendWWW(nil,TextureCache.Textures[17].texture,"a-texture-test.png")
------------------------------------------------------------------------------------------------------------

function  grep(inputStr,findStr,suppressBlankLines,trimEdgeWhiteSpace,trimAllWhiteSpace)
    local grepOutput = ""
    if type(inputStr) ~= "string" then return grepOutput ; end
    findStr = tostring( findStr or "" )
    if findStr == "" then findStr = false ; end
    local gt = {}
    local le = "\n"
    if string.find(inputStr,"\r") then le = "\r\n" ; end
    for lineNum,line in pairs( string.split3(inputStr,"\r\n",suppressBlankLines,trimEdgeWhiteSpace,trimAllWhiteSpace) )
    do
        if  not findStr  or  string.find(line,findStr)  then gt[#gt+1] = line  ; end
    end
    return table.concat( gt, le )
end

------------------------------------------------------------------------------------------------------------

function GetRandomUUID()  local random = math.random ; return string.format("%08X%08X%08X%08X",random(0,4228250625),random(0,4228250625),random(0,4228250625),random(0,4228250625))  end

------------------------------------------------------------------------------------------------------------

function string.compare_score(s1,s2)
    s1 = tostring(s1 or "")
    s2 = tostring(s2 or "")
    if #s1 == 0 and #s2 == 0 then return 1 ; end
    if #s1 == #s2 and s1 == s2 then return 1 ; end
    local cscore1 = 0
    local cscore2 = 0
    for i = 1, math.min(#s1,#s2) do    if s1:sub(i,i) == s2:sub(i,i) then cscore1 = cscore1 + 1 ; cscore2 = cscore2 + 1 ; else  if string.find(s2,s1:sub(i,i)) then cscore1 = cscore1 + 0.5 ; end ; if string.find(s1,s2:sub(i,i)) then cscore2 = cscore2 + 0.5 ; end ; end ; end
    return ( 100/(#s1+#s2)*(cscore1+cscore2) )
end

------------------------------------------------------------------------------------------------------------

function lua_fix_root_level_missing_type_functions()
    -- Auto-fix root-level(_G) missing __type functions.
    for k,v in pairs(_G) do
        local success,err = pcall(loadstring("local curType = type("..tostring(k)..")"))
        if (err ~= nil) then print("Adding __type to "..tostring(k)) ; pcall(loadstring("function "..tostring(k)..":__type()  return \""..tostring(k).."\" ; end")) ; end
    end
end

-- lua_fix_root_level_missing_type_functions()

------------------------------------------------------------------------------------------------------------

function  ls2(input,filter,...)

  --[[
        To list all keys in the root of lua (_G), try:

        ls("/")

        To drill down further, just keep adding keys.

        ls("/math")

  --]]

  input  = input   or  ""
  input  = tostring(input)
  filter = filter  or  ""
  args   = {...}

  input  = string.gsub(  input,"[.][*]", "*"  )
  input  = string.gsub(  input,"[.]",    "/"  )
  input  = string.gsub(  input,"[*]",    ".*" )
  filter = string.gsub( filter,"[.][*]", "*"  )
  filter = string.gsub( filter,"[*]",    ".*" )

  local path,pathTmp,pathAsStr,printProvider = {},{},"",echo or print

--if lua_fix_root_level_missing_type_functions then lua_fix_root_level_missing_type_functions() ; end

  input = string.gsub( input, "\\\\*",       "\\" )
  input = string.gsub( input, "[/][/]*",     "/"  )
  input = string.gsub( input, "^\\",         ""   )
--input = string.gsub( input, "^/",          ""   )

  if      ( string.sub(input,1,3) ~= "_G/"    )  then  if ( string.sub(input,1,1)  ~= "/" )  then input = "_G/"..input ; else input = "_G"..input ; end ; end
  if      string.byte(input,#input) == 47 and #input > 1 then input = string.sub(input,1,#input-1) ; end
  if      string.byte(input,1)      ~= 47 then input = "/"..input ; end
  if      input == "" then input = "/" end


  if ls_debug then print("input:",input,"filter:",filter) ; end

  while ( #input > 0 ) do

        local curPath = string.gsub(input,"[/].*","")

        if    ( #curPath ~= 0 )
        then
              pathTmp[#pathTmp+1] = curPath
              if    ( string.gsub(input,"^[^/][^/]*[/]","") == input )
              then  input = ""
              else  input = string.gsub(input,"^[^/][^/]*[/]","")
              end

        else
            --pathTmp[#pathTmp+1] = "/"
              input = string.gsub(input,"^[^/][^/]*","")
              if (string.byte(input) == 47) then input = string.sub(input,2) ; end
        end
  end

  local curPath = _G

  if ls_debug then print("input:",input,"filter:",filter) ; if echo then echo(pathTmp) ; end ; end

  while ( pathTmp ~= nil ) do
        local pathFound = false
        for k,v in pairs(curPath) do
            if    not pathFound
            and   pathTmp  and  pathTmp[1]
            and   ( tostring(pathTmp[1]) == tostring(k) )
            then
                if      tonumber(pathTmp[1])  and  curPath[tonumber(pathTmp[1])]
                then    curPath = curPath[tonumber(pathTmp[1])]
                elseif  curPath[pathTmp[1]]
                then    curPath = curPath[pathTmp[1]]
                end
                table.insert(path,pathTmp[1])
                if      ( tostring(pathTmp[1]) == "_G" )
                then    pathAsStr = "/"
                else    pathAsStr = pathAsStr.."/"..tostring(pathTmp[1])
                end
                pathFound = true
            end
        end
        table.remove(pathTmp,1)
        if ( #pathTmp == 0 ) then pathTmp = nil ; end
        pathAsStr = string.gsub(pathAsStr,"^[/][/]","/")
  end

  -- if curPath[filter] then curPath = curPath[filter] ; pathAsStr = pathAsStr.."/"..filter ; table.insert(path,filter) ; filter = ".*" ; else filter = "^"..filter ; end

  pathAsStr = string.gsub(pathAsStr,"^[/][/]*","")
  pathAsStr = string.gsub(pathAsStr,"[/][/]*$","")
  pathAsStr = "/"..pathAsStr

  if not ls_path or ls_path == "" then ls_path = "/" ; end

  if pathAsStr == "" then pathAsStr = ls_path ; else ls_path = pathAsStr ; end

  if  #args > 0 and type(args[#args] or nil) == "boolean" and args[#args] then  printProvider(pathAsStr) ; return true ; end

  local pathKeysNum,pathKeysStr,pathKeysMaxLen = {},{},0
  local tabKeyTypes,tabKeyTypesCount        = {},0
  local varTypesMaxLen                      = 12

  if  type(curPath or nil) == "table"
  then
      for k,v in pairs(curPath) do
          if    ( type(k or nil) == "number" )
          then  pathKeysNum[#pathKeysNum+1] = k
          else  pathKeysStr[#pathKeysStr+1] = tostring(k)
          end
          if ( string.len(pathAsStr..tostring(k)) > pathKeysMaxLen ) then pathKeysMaxLen = string.len(pathAsStr..tostring(k)) ; end
      end
  else
      pathKeysStr[#pathKeysStr+1] = tostring(curPath)
      if ( string.len(pathAsStr..tostring(curPath)) > pathKeysMaxLen ) then pathKeysMaxLen = string.len(pathAsStr..tostring(curPath)) ; end
  end

  pathKeysMaxLen = tostring(pathKeysMaxLen+1)

  table.sort(pathKeysNum)
  table.sort(pathKeysStr)

  local ret = {}

  for k,v in pairs(pathKeysNum) do
      local curType = type(curPath[v] or nil)
      if ( curType == "nil" ) then curType = "Unknown" ; end
      local lineData = pathAsStr.."/"..tostring(v).." "..curType.." = "..tostring(curPath[v])
      if  filter == ".*"
      or  ( string.find(v,filter)  )
      or  ( string.find(curType,filter)  )
      or  ( string.find(string.lower(v),string.lower(filter))  )
      or  ( string.find(string.lower(curType),string.lower(filter))  )
      then
          ret[#ret+1] = string.format( "%-"..pathKeysMaxLen.."s %-"..varTypesMaxLen.."s = %s", pathAsStr.."/"..tostring(v), curType,  tostring(curPath[v]) ) 
          ret[#ret]   = string.gsub(ret[#ret],"^[/][/]*","/")
          printProvider( ret[#ret] )
      end
  end

  for k,v in pairs(pathKeysStr) do
      local curType = ""
      if curPath[v] then curType = type(curPath[v] or nil) ; end
      if ( curType == "nil" ) then curType = "Unknown" ; end
      -- local lineData = pathAsStr.."/"..tostring(v or "").." "..curType.." = "..tostring(curPath[v] or "")
      local lineData1 = pathAsStr.."/"
      local lineData2 = tostring(v or "") or ""
      local lineData3 = " "..curType.." = "
      local lineData4 = ""
      if curPath[v] and curType ~= "table" then lineData4 = tostring(curPath[v] or "") or "" ; end
      local lineData  = lineData1..lineData2..lineData3..lineData4
      if  filter == ".*"
      or  ( string.find(v,filter)  )
      or  ( string.find(curType,filter)  )
      or  ( string.find(string.lower(v),string.lower(filter))  )
      or  ( string.find(string.lower(curType),string.lower(filter))  )
      then
          if      curType ~= "table"
          then    ret[#ret+1] = string.format( "%-"..pathKeysMaxLen.."s %-"..varTypesMaxLen.."s = %s", pathAsStr.."/"..tostring(v), curType,  tostring(curPath[v]) ) 
          elseif  curType == "table"
          then    ret[#ret+1] = string.format( "%-"..pathKeysMaxLen.."s %-"..varTypesMaxLen.."s = %s", pathAsStr.."/"..tostring(v), curType,  tostring( table.count(curPath[v]) ).." entries." ) 
          end
          ret[#ret]   = string.gsub(ret[#ret],"^[/][/]*","/")
          printProvider( ret[#ret] )
      end
  end

  return ret

end

------------------------------------------------------------------------------------------------------------

function  echo2(...) -- Requires   dumptable

    for k,v in pairs({...})
    do
        local typev = type(v) or ""
        local retCur = ""
        if      ( typev == "table"  )  then  retCur = dumptable2(v,k)
        elseif  ( typev == "string" )  then  retCur = v
        elseif  ( typev == "number" )  then  retCur = tostring(v)
        elseif  ( typev == "Vector" )  then  if v.x and v.y and v.z then retCur = string.format( "Vector( %.6f, %.6f, %.6f )", v.x, v.y, v.z ) ; elseif v.x and v.y then retCur = string.format( "Vector( %.6f, %.6f )", v.x, v.y ) ; end
        else    retCur = tostring(v)
        end
        print(retCur)
    end

    return

end

------------------------------------------------------------------------------------------------------------

function  dumptable2( inp , inp_name , inp_depth )

    inp_depth = ( tonumber(inp_depth or 0) or 0 )

    inp_name = tostring(inp_name)

    local dumptable_spaces = "                                                                      "

    if    ( inp_name == "nil" ) or ( inp_name == "" )
    then  inp_name = ""
    else  inp_name = inp_name .. " = "
    end

    if   ( type(inp) == "table" )
    then
            if  isvector and isvector(inp) then return varAsPrintable(inp) ; end
            inp_depth = inp_depth + 4
            local inpTable = inp
            if getmetatable(inp) then inpTable = getmetatable(inp) end
            local s = inp_name .. '{\n'
            local tcountNum = #inp
            local tKeys     = {  ["number"] = {}, ["string"] = {}, }
            
            local tcountAll = 0 ; for k,v in pairs(inp)  do local kType = type(k) ; tcountAll = tcountAll + 1 ; if kType == "string" then tKeys["string"][#tKeys["string"]+1] = k ; elseif kType == "number" then tKeys["number"][#tKeys["number"]+1] = k ; end ; end
            table.sort(tKeys.number) ; table.sort(tKeys.string)
            local cur_depth = tostring(inp_depth)
            local rem_depth = 35 - inp_depth  ; if  rem_depth < 1  then rem_depth = "" ; else rem_depth = tostring(rem_depth) ; end
            if  #inp > 0 and #inp == tcountNum and tcountNum == tcountAll
            then
                for i = 1,#inp do
                    s = s .. string.format( "%"..cur_depth.."s%-"..rem_depth.."s%s%s,\n" , "" , '['..tostring(i)..']' ,' = ' , dumptable2(inp[i],nil,inp_depth) )
                end
            else
                for _,k in pairs(tKeys.number) do
                    local v = inp[k]
                    s = s .. string.format( "%"..cur_depth.."s%-"..rem_depth.."s%s%s,\n" , "" , '['..tostring(k)..']' ,' = ' , dumptable2(v,nil,inp_depth) )
                end

                for _,k in pairs(tKeys.string) do
                    local v = inp[k]
                    k = "'"..string.gsub( tostring( k ),"'","\\\'" ).."'"
                    s = s .. string.format( "%"..cur_depth.."s%-"..rem_depth.."s%s%s,\n" , "" , '['..k..']' ,' = ' , dumptable2(v,nil,inp_depth) )
                end
            end
            inp_depth = inp_depth - 4
            s = s .. string.sub(dumptable_spaces,0,inp_depth) .. '}'
            return s
    else
            if      ( type( inp ) == "function" ) or ( type(inp) == "Vector" )
            then    return varAsPrintable(inp)

            elseif  ( type( inp ) ~= "number" ) and ( type ( inp ) ~= "boolean" )
            then    return "'" .. string.gsub(tostring(inp),"'","\\'" ) .. "'"

            else    return tostring(inp)
            end
    end

    return nil
end

------------------------------------------------------------------------------------------------------------

function whatsit2(obj1,obj2,keyPath,whatsitDebug)

    if obj1 == nil then return "nil" ; end;

    local obj1_type = type(obj1 or nil)
    local ret       = ""

    if      not keyPath
    then
            for k,obj2 in pairs(_G) do
                if ( k ~= "package" ) and ( k ~= "_G" ) then
                    local   obj2_type = type(obj2 or nil)
                    if      obj1_type == obj2_type
                    and     obj1 == obj2
                  --and     tostring(obj1) == tostring(obj2)
                    then
                            local keyPathPart = tostring(k)
                            if type(k) == "string" then keyPathPart = string.gsub(keyPathPart,"\\","\\\\"); keyPathPart = string.gsub(keyPathPart,"'","\\'"); keyPathPart = "'"..keyPathPart.."'"; end;
                            keyPathPart = "["..keyPathPart.."]"
                            if whatsitDebug then print( "Object is "..tostring(k) ) ; end

                    elseif  obj2_type == "table"
                    then
                            keyPath = tostring(k)
                            if whatsitDebug then print("whatsit("..tostring(obj1)..","..tostring(obj2)..",\"\")") ; end
                            whatsit(obj1,obj2,keyPath,whatsitDebug)
                    end
                end
            end

    elseif  keyPath  and  ( type(obj2 or nil) == "table" ) and obj2 ~= _G  and obj2 ~= _G._G
    then
            for k,v in pairs(obj2) do
                local keyPathPart = tostring(k)
                if type(k) == "string" then keyPathPart = string.gsub(keyPathPart,"\\","\\\\"); keyPathPart = string.gsub(keyPathPart,"'","\\'"); keyPathPart = "'"..keyPathPart.."'"; end;
                keyPathPart = "["..keyPathPart.."]"
                if whatsitDebug then print("whatsit("..tostring(obj1)..","..tostring(v)..",\""..keyPath..keyPathPart.."\")") ;end
                whatsit(obj1,v,keyPath..keyPathPart,whatsitDebug);
            end;

    elseif  keyPath
    and     obj1_type      == type(obj2 or nil)
    and     tostring(obj1) == tostring(obj2)
    then
            if whatsitDebug then print( "Object is "..keyPath ) ; end
            ret = keyPath
    end;
    return ret
end;

------------------------------------------------------------------------------------------------------------

--[[
--------------------------------------------------------------------------------
--                              BMP2LUA                                       --
--------------------------------------------------------------------------------

bmp2lua = {}

setmetatable(bmp2lua,
    {
        __call = function(self,...) bmp2lua.bmp2lua(...) ; end,
    }
)

bmp2lua.debug = false

bmp2lua.help = {
        '    bmp2lua.bmp2lua(',
        '                      bmp_filename,      -- bmp_filename',
        '                      scalemod,          -- scalemod           Default:  1 (is a divisor, so 2 is 1/2 the number of pixels, 3 is 1/3rd, etc)',
        '                      x1,                -- x1',
        '                      y1,                -- y1',
        '                      x2,                -- x2',
        '                      y2,                -- y2',
        '                      greenscreen_color  -- greenscreen_color  Default: -1 (which is not a color in most cases)',
        '                    )',
        '    --',
        '    --  5 tables are returned (you usually only want 1 of them), in the following order:',
        '    --',
        '    --   [1] table_dec_rgb',
        '    --   [2] table_dec_rgba',
        '    --   [3] table_float_rgba',
        '    --   [4] table_dec_ansi',
        '    --   [5] table_hex_ansi',
        '    --',
        '    --   example: Lets retrieve the 3rd table,  table_float_rgba  into  rgba_data,  then print contents of rgba_data',
        '    --',
        '    --',
        '    local  bmp_file          = "8-bit-mario-24bit-2.bmp";',
        '    local  _,_,rgba_data,_,_ = bmp2lua.bmp2lua( bmp_file )',
        '    for  x  =  1, #rgba_data     do',
        '    for  y  =  1, #rgba_data[x]  do',
        '         local   d  =  rgb_data[x][y]',
        '         print( string.format( "%5s,%-5s  r = %3s, g = %3s, b = %3s", x, y, d.r, d.g, d.b ) )',
        '    end',
        '    end',
}

function bmp2lua.bmp2lua(
                    bmp_filename,
                    scalemod,
                    x1offset,
                    y1offset,
                    x2offset,
                    y2offset,
                    greenscreen_color
                )

    --               [1]            [2]              [3]              [4]             [5]
--  returns     table_dec_rgb, table_dec_rgba, table_float_rgba, table_dec_ansi, table_hex_ansi

    if not bmp_filename then if bmp2lua.help then for k,v in pairs(bmp2lua.help) do print(v) ; end ; end ; return ; end

    local x_min,y_min       = 1,1
    local x_max,y_max       = 2048,2048

    scalemod          = tonumber(scalemod           or  1)  or  1
    x1                = tonumber(x1                 or  0)  or  0
    y1                = tonumber(y1                 or  0)  or  0
    x2                = tonumber(x2                 or  0)  or  0
    y2                = tonumber(y2                 or  0)  or  0
    greenscreen_color = tonumber(greenscreen_color  or -1)  or -1

    bmp_filename = tostring(bmp_filename or "") or "8-bit-mario-24bit.bmp"

    if ( bmp_filename == "" ) then bmp_filename = "8-bit-mario-24bit.bmp" ; end

    local b,g,r,a                           = 0,0,0,255
    local line_dec_rgb,table_dec_rgb,table_dec_rgb_flat      = "",{},{}
    local line_dec_rgba,table_dec_rgba,table_dec_rgba_flat   = "",{},{}
    local line_float_rgba,table_float_rgba,table_float_flat  = "",{},{}
    local line_dec_ansi,table_dec_ansi,table_dec_ansi_flat   = "",{},{}
    local line_hex_ansi,table_hex_ansi,table_hex_ansi_flat   = "",{},{}


    local f = io.open(bmp_filename,"rb")

    if ( f == nil ) then print("Error trying to open "..bmp_filename.."  Could not find?" ) ; return ; end

    -----------------------------------------------
    -- Get BMP Header Info (width,height,depth,etc)
    -----------------------------------------------

    local bmp_header      = string.byte(f:read(1))+string.byte(f:read(1))*256
    f:seek("set",10)
    local bmp_data_starts = string.byte(f:read(1))+string.byte(f:read(1))*256+string.byte(f:read(1))*256*256+string.byte(f:read(1))*256*256*256
    f:seek("set",18)
    local bmp_width       = string.byte(f:read(1))+string.byte(f:read(1))*256+string.byte(f:read(1))*256*256+string.byte(f:read(1))*256*256*256
    local bmp_height      = string.byte(f:read(1))+string.byte(f:read(1))*256+string.byte(f:read(1))*256*256+string.byte(f:read(1))*256*256*256
    f:seek("set",28)
    local bmp_depth       = string.byte(f:read(1))+string.byte(f:read(1))*256+string.byte(f:read(1))*256*256+string.byte(f:read(1))*256*256*256
    local bmp_bpp         = bmp_depth / 8
    local bmp_field_size  = bmp_width*bmp_height

    if x2 <= x1 then if x2 < 0 then x2 = bmp_width  + x2 ; elseif x2 >= 0 then x2 = bmp_width  - x2 ; end ; end
    if y2 <= y1 then if y2 < 0 then y2 = bmp_height + y2 ; elseif y2 >= 0 then y2 = bmp_height - y2 ; end ; end
    if x2 < x1 then x1,x2 = x2,x1 end
    if y2 < y1 then y1,y2 = y2,y1 end

    if  bmp2lua.debug  then  print("bmp_filename='"..tostring(bmp_filename).."'\nbmp_data_starts="..tostring(bmp_data_starts).."\nbmp_field_size="..tostring(bmp_field_size).."\nbmp_width="..tostring(bmp_width).."\nbmp_height="..tostring(bmp_height).."\nbmp_depth="..tostring(bmp_depth).."\nbmp_bpp="..tostring(bmp_bpp).."\nx1,y1="..tostring(x1)..","..tostring(y1).."\nx2,y2="..tostring(x2)..","..tostring(y2))  end

    f:seek("set",bmp_data_starts)

    for   y   = bmp_height, 1, -1  do

        table_dec_rgb[y]    = {} ; table_dec_rgb_flat[y]  = {}
        table_dec_rgba[y]   = {} ; table_dec_rgba_flat[y] = {}
        table_float_rgba[y] = {}
        table_dec_ansi[y]   = {}
        table_hex_ansi[y]   = {}

    for   x   = 1, bmp_width, 1  do

        -- local x_val = ( math.floor ( x / scalemod + ( xoffset - ( xoffset / scalemod ) ) ) )
        -- local y_val = ( math.floor ( y / scalemod + ( yoffset - ( yoffset / scalemod ) ) ) )
        local x_val = ( math.floor ( x / scalemod ) )
        local y_val = ( math.floor ( y / scalemod ) )

        if      ( bmp_bpp == 3 )
        then
                b,g,r   = string.byte(f:read(1)),string.byte(f:read(1)),string.byte(f:read(1))

        elseif  ( bmp_bpp == 4 )
        then
                b,g,r,a = string.byte(f:read(1)),string.byte(f:read(1)),string.byte(f:read(1)),string.byte(f:read(1))

        elseif  ( bmp_bpp == 1 )
        then
                b =   string.byte(f:read(1))
                r =   math.floor( r / 8 / 4 % 4 )
                g =   math.floor( r / 4 % 8 )
                b =   math.floor( r % 8 )
        end

        local color_4_bytes_fullalpha =  r + g*256 + b*256*256 + 255*256*256*256
        local color_4_bytes           =  r + g*256 + b*256*256 + a*256*256*256
        local color_4_bytes_hex       =  string.format("%08X",color_4_bytes)
        local color_3_bytes           =  r + g*256 + b*256*256
        local color_3_bytes_hex       =  string.format("%06X",color_3_bytes)
        local color_ansi              =  16 + math.floor((r+6)/51) + math.floor((g+6)/51)*6 + math.floor((b+6)/51)*6*6
        local color_ansi_hex          =  string.format("%02X",color_ansi)

        table_dec_rgb[y][x]    = { r = r, g = g, b = b, }                                         ;  table_dec_rgb_flat[y]  = { x = x, y = y, r = r, g = g, b = b, }
        table_dec_rgba[y][x]   = { r = r, g = g, b = b, a = a, }                                  ;  table_dec_rgba_flat[y] = { x = x, y = y, r = r, g = g, b = b, a = a, }
        table_float_rgba[y][x] = { r = 1.0/255*r, g = 1.0/255*g, b = 1.0/255*b, a = 1.0/255*a, }
        table_dec_ansi[y][x]   = color_ansi
        table_hex_ansi[y][x]   = color_ansi_hex

    end
        for  z = 1, bmp_width%4    do    f:read(1)   ; end  --  Munch any extra data if width is not even.
    end

    io.close(f)

    if  bmp2lua.debug and bmp2lua.help
    then
        print( bmp2lua.help )
    end

    --               [1]            [2]              [3]              [4]             [5]               [6]                [7]
    return     table_dec_rgb, table_dec_rgba, table_float_rgba, table_dec_ansi, table_hex_ansi, table_dec_rgb_flat, table_dec_rgba_flat

end

--------------------------------------------------------------------------------

function bmp2lua.table_dec_rgb(...)

    local table_dec_rgb  = bmp2lua.bmp2lua(...)

    for k,y in pairs(table_dec_rgb) do
        
    for k,x in pairs(y)             do
        print( "x,y,r,g,b = "..tostring(x)..","..tostring(y)..","..tostring(r)..","..tostring(g)..","..tostring(b) )
    end
        line_hex_ansi = "printf %b '"..line_hex_ansi.."\\e[0m\\n".."'"
        print(line_hex_ansi)
    end

    return table_dec_rgb

end

--------------------------------------------------------------------------------

function bmp2lua.bmp2ansi_executable(...)

    local _,_,_,table_dec_ansi = bmp2lua.bmp2lua(...)

    local line_hex_ansi  = ""

    for k,y in pairs(table_dec_ansi) do
        line_hex_ansi = ""
    for k,x in pairs(y)              do
        line_hex_ansi = line_hex_ansi..string.format("\\e[48;5;%dm  ",x)
    end
        line_hex_ansi = "printf %b '"..line_hex_ansi.."\\e[0m\\n".."'"
        print(line_hex_ansi)
    end

    return table_dec_ansi

end

--------------------------------------------------------------------------------

bmp2lua.args = {...}

if    ( #bmp2lua.args > 0 )
then
      print("# "..table.concat(bmp2lua.args," "))
      local command = loadstring(table.concat(bmp2lua.args,"\n"))
      if    ( command ~= nil )
      then  command()
      else  print("loadstring returned nil, meaning your command is invalid.  Good Day Sir, Good day...")
      end
else  return bmp2lua
end

--------------------------------------------------------------------------------

--]]


setmetatable( HBZ,
              {
                 __call = function(self,...) for k,v in pairs(self) do if type(v or nil) == "function" then print( string.format( "%35s  HBZ:%s()", tostring(v), tostring(k) ) ) else  print( string.format( "%35s  HBZ.%s", tostring(v), tostring(k) ) ) ; end ; end ; end,
              }
            )

-- function main(g) HBZ.gameObject = g ; return HBZ ; end

function main(go) HBZ.gameObject = go ; return HBZ ; end

return HBZ
