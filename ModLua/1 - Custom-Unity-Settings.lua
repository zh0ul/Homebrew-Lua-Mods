local Mod = {}

------------------------------------------------------------------------------------------------------------

function Mod:Awake()
    print("Custom-Unity-Settings.lua:Awake()")
    Camera.main:GetComponent("TOD_Scattering").enabled = false
    RenderSettings.fog = false
    Camera.main.farClipPlane = 40000
    --Camera.main:GetComponent("PostProcessingBehaviour").enabled=false
end

------------------------------------------------------------------------------------------------------------

function Mod:OnDestroy()
    print("Custom-Unity-Settings.lua:OnDestroy()")
end

------------------------------------------------------------------------------------------------------------

function Mod:Update()
    return
end

------------------------------------------------------------------------------------------------------------

function keys(inp)
    inp = inp or ""
    inp = tostring(inp)
    local tKeyCode = {}
    for k,v in pairs(KeyCode) do tKeyCode[#tKeyCode+1] = k ; end
    table.sort(tKeyCode)
    for k,v in pairs(tKeyCode) do if string.find(string.lower(v),inp) then print( string.format( "KeyCode.%s = %d", v, KeyCode[v] ) ) ; end ; end
end

------------------------------------------------------------------------------------------------------------

function showmeta(...)
    local processed_input = false
    for k,v in pairs({...}) do
        processed_input = true
        local aTab = false
        if    type(v) == "string"
        then
              aTab = getmeta(v)
              if  type(aTab) == "table"
              then
                  for t1k,t1v in pairs(aTab) do
                      if type(t1v) == "table"
                      then
                          for t2k,t2v in pairs(t1v)  do
                              if type(t2v) == "string" then print(t2v) ; end
                          end
                      end
                  end

              end
        end
    end
    if not processed_input
    then
        for k,v in pairs(_G) do if v and v ~= package and v ~= _G and ( not Vector2 or v ~= Vector2 ) and (type(v) == "table" or type(v) == "userdata" ) then showmeta(k) ; end ; end
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
                -- if      k:sub(1,8) == "function"                        then  aTab[#aTab+1] = string.format( "%-20s  %s",tostring(v), name.."."..tostring(k) )
                -- elseif  ( not getmeta_ignore or not getmeta_ignore[k] ) then  aTab[#aTab+1] = string.format( "%-20s  %-50s  %s",tostring(v), name.."."..tostring(k), tostring(element[k]) )
                -- end
                aTab[#aTab+1] = string.format( "%-20s  %s",tostring(v), name.."."..tostring(k) )
            end
        end
        table.sort(aTab)
        return aTab
    end
end

getmeta_ignore = { onPostRender = true, onPreCull = true, onPreRender = true, get_enabled = true, }

------------------------------------------------------------------------------------------------------------

many2one_debug = false

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
  lineCount = lineCount or 100
  forLineIn(dataPath.."/output_log.txt",function(line) dataTab[#dataTab+1] = line  ; end,true,true,true)
  local l,h = #dataTab-lineCount, #dataTab
  if  l < 1 then l = 1 ; end
  for i = #dataTab,#dataTab-lineCount,-1  do  if dataTab[i] then print(dataTab[i]) ; end  end
end

HBConsoleManager.instances[1].OnConnect = { "+=", getLogLines }

------------------------------------------------------------------------------------------------------------

function iter_to_table(obj)
    local  ret = {}
    if  type(obj) == "userdata" and tostring(obj):sub(1,5) == "Array" then  for v in Slua.iter(obj) do ret[#ret+1] = v ; end ; end
    return ret
end

------------------------------------------------------------------------------------------------------------

function GetAllVehicleParts()
  local vehicle_list  = GameObject.FindObjectsOfType("VehiclePiece")
  local vehicle_parts = iter_to_table(vehicle_list)
  return vehicle_parts
end

------------------------------------------------------------------------------------------------------------

function GetAllPlayers()
  local player_list  = HBU.GetPlayers()
  local player_table = iter_to_table(player_list)
  for k,v in pairs(player_table) do  player_table[v.playerName.name] = player_table[k] end
  return player_table
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

function main(go) Mod.gameObject = go ; return Mod ; end


-- >screenObj = GameObject.Find("TutorialScreen")
-- >screenObj.transform.position = screenObj.transform.position + Vector3.right * 2
-- >screenObj.transform.localScale = Vector3.one * 3
-- >screenObj.transform.localScale = Vector3.one
-- >screenObj.transform.localScale = Vector3.one * 0.1
-- >screenObj.transform.localScale = Vector3.one * 0.01
-- >screenObj.transform.localScale = Vector3.one * 0.005
-- >screenObj.transform.localScale = Vector3.one * 0.02
-- >screenObj.transform.position = screenObj.transform.position + Vector3.up * 10
-- >player=screenObj:GetComponent("HBVideoPlayer")
-- >player:LoadURL("https://github.com/mediaelement/mediaelement-files/blob/master/big_buck_bunny.mp4")
-- >>
-- >player:LoadURL("http://github.com/mediaelement/mediaelement-files/blob/master/big_buck_bunny.mp4")
-- >>
-- >player:Play()
-- >player:LoadURL("http://video.webmfiles.org/big-buck-bunny_trailer.webm")
-- >player:Play()
-- >>

