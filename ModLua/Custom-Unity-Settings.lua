local Mod = {}
function main(go) Mod.gameObject = go ; return Mod ; end

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
        for k,v in pairs(getmetatable(element)) do if k:sub(1,2) ~= "__" then aTab[#aTab+1] = string.format( "  %-20s  %s",type(v), name.."."..tostring(k) ) ; end ; end
        table.sort(aTab)
        return aTab
    end
end

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

function  forLineIn(file,func,suppressBlankLines,trimEdgeWhiteSpace,trimAllWhiteSpace)
  if type(func) == "string" then func = loadstring(func) ; end
  if type(file) ~= "string" or type(func) ~= "function" then return 0,0 ; end
  local fd = io.open( file, "r" )
  if ( not fd ) then print("forLineIn: Could not open file "..tostring(file)) ; return 0,0 ; end
  local lcount,lexec = 0,0
  for line in fd:lines() do
      lcount = lcount + 1
      if    trimEdgeWhiteSpace or trimAllWhiteSpace
      then
            line = string.gsub(line, string.char(0x0d), "")
            line = string.gsub(line,"^"..string.char(0x09).."*","")
            line = string.gsub(line,"^"..string.char(0x20).."*","")
            line = string.gsub(line,string.char(0x09).."*$","")
            line = string.gsub(line,string.char(0x20).."*$","")
      end
      if    trimAllWhiteSpace
      then
            line = string.gsub(line,string.char(0x09)," ")
            line = string.gsub(line,string.char(0x20)," ")
      end
      if    not suppressBlankLines or #line > 0
      then
            lexec = lexec + 1
            func(line)
      end
  end
  fd:close()
  return lcount,lexec
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

function  varAsPrintable( var, printFunctions )
    if       printFunctions then printFunctions = true ; else printFunctions = false ; end
    if      ( var == nil              ) then  return "nil", "nil"
    elseif  isvector and isvector(var)  then  return tostring(var)
    elseif  ( type(var) == "number"   ) then  return tostring(var) --if ( var % 1 == 0 )  then  return string.format("0x%08x",var), "number"  else  return tostring(var), "number"  end
    elseif  ( type(var) == "string"   ) then  return "\"" .. string.gsub( var, "\"", "\\\"" ) .. "\"", "string"
    elseif  ( type(var) == "function" ) then  if printFunctions then  return function2string(var,nil,true)  ;else  return "--[[ "..tostring(var).." --]]"  ;end
    elseif  ( type(var) == "boolean"  ) then  return tostring(var), "boolean"
    elseif  ( type(var) == "Vector"   ) then  return "Vector("..tostring(var.x)..","..tostring(var.y)..","..tostring(var.z)..")", "Vector"
    elseif  ( type(var) == "Vector2"  ) then  return "Vector2("..tostring(var.x)..","..tostring(var.y)..")", "Vector2"
    elseif  ( type(var) == "Vector3"  ) then  return "Vector3("..tostring(var.x)..","..tostring(var.y)..","..tostring(var.z)..")", "Vector3"
    elseif  ( type(var) == "nil"      ) then  return "nil", "nil"
                                        else  return "\""..tostring(var).."\"", "string/unknown"
    end
end

------------------------------------------------------------------------------------------------------------

function  dumptable_structure(t,curPath,disableDotNotation,ownCall)

  local printProvoder = echo or original_print or print

  if    ( ownCall == nil ) and ( type(t) == "string" ) and ( _G[t] ~= nil )
  then  curPath = t ; t = _G[t]
  end

  if    ( type(curPath) ~= "string" )              then  curPath = tostring(curPath) or ""    end

  if    disableDotNotation then disableDotNotation = true ; else disableDotNotation = false ; end

  if    ( ownCall == nil ) then addressListSeen = {} ; end

  local subTables, subVars = {}, {}

  if    ( curPath ~= "" ) then printProvoder( curPath.." = {}" ) ; end

  if    ( type(t) == "nil" )
  then  printProvoder( curPath .. " = nil" ) ; return nil
  end

  local prevPath = tostring(curPath)

  local vCount = 0

  if ( type(t) ~= "table" ) then t = {t} ; end

  for   k,v in pairs(t) do

      if      ( type(k) == "number" )
      then    curPath = prevPath.."["..tostring(k).."]"
      elseif  ( type(k) == "string" )
      then
          if    ( disableDotNotation == false )
          then  curPath = prevPath.."."..k
          else  curPath = prevPath.."["..varAsPrintable(k).."]"
          end
      end

      if      ( dumptable_structure_isIgnored(curPath) == false ) and ( dumptable_structure_isIgnored(k) == false ) and ( v ~= nil )
      then
          vCount = vCount + 1

          if    ( type(v) == "table" )
          then
            local   tAddress = tonumber( "0x"..string.gsub( tostring(t), ".*[x ]", "" ) ) or 1

            if      ( addressListSeen[tAddress] == nil )
            then
                if    ( curPath ~= "_G.package" )
                and   ( ( curPath == "_G" ) or ( curPath:sub(1,2)..curPath:sub(#curPath-1) ~= "_G_G" )  )
                then  addressListSeen[tAddress] = prevPath  ;  dumptable_structure(v,curPath,disableDotNotation,true)  -- subTables[#subTables+1] = {k,v}
                end

            elseif  ( addressListSeen[tAddress] == prevPath )
            and     ( string.find(curPath,"_G[^a-zA-Z]") )
            then    printProvoder("-- Skipping "..curPath.." because we've already seen it.")
            else    dumptable_structure(v,curPath,disableDotNotation,true) -- subTables[#subTables+1] = {k,v}
            end
          else
            printProvoder( curPath.." = "..varAsPrintable(v) )
          end
      else
        printProvoder(curPath.." = {} -- Ignoring rest-of-contents due to dumptable filter.")
      end
  end

  for   k,v in pairs(subTables) do
      dumptable_structure(v[2], curPath, disableDotNotation, true)
  end

end ; dump = dumptable_structure

--[[
  human={

    [1]={body={arms={
      l={upper={fore={wrist={fingers={pinky={ attached = true,  jointForce = 1.0000, model = "white_male_42_fingers_pinky_l_attached", },},},},},},
      r={upper={fore={wrist={fingers={pinky={ attached = false, jointForce = 0.0000, model = "white_male_42_fingers_pinky_r_deattached", },},},},},},
      },    },    },

    [2]={body={arms={
      l={upper={fore={wrist={fingers={pinky={ attached = false, jointForce = 0.0000, model = "black_female_69_fingers_pinky_l_deattached", },},},},},},
      r={upper={fore={wrist={fingers={pinky={ attached = true,  jointForce = 1.0000, model = "black_female_69_fingers_pinky_r_attached",   },},},},},},
      },    },    },
  }

  dump("human")
--]]

------------------------------------------------------------------------------------------------------------

dumptable_structure_ignore = {}

function  dumpIgnore(toIgnoreStr,verbose)
  if    verbose    then  verbose = true    else  verbose = false    end
  if ( type(toIgnoreStr) ~= "string" ) then print(unpack(dumptable_structure_ignore)) ; return nil ; end
  local intFound,i = -1,1
  while ( i <= #dumptable_structure_ignore ) do
      if    ( dumptable_structure_ignore[i] == toIgnoreStr )
      then  strFound = true ; intFound = i
      end
      i = i + 1
  end

  if ( intFound == -1 )
  then
    if verbose  then  print("dumptable_structure : Add Ignore String : "..toIgnoreStr)  ; end
    dumptable_structure_ignore[#dumptable_structure_ignore+1] = toIgnoreStr
  else
    if verbose  then  print("dumptable_structure : Remove Ignore String : "..dumptable_structure_ignore[intFound])  ; end
    table.remove(dumptable_structure_ignore,intFound)
  end
end

------------------------------------------------------------------------------------------------------------

function  dumptable_structure_isIgnored(strQuery)
  strQuery = tostring(strQuery)
  for   k,v in pairs(dumptable_structure_ignore or {}) do
      if    ( string.upper(strQuery) ~= string.gsub( string.upper(strQuery), string.upper(v), "" ) )
      then  return true
      end
  end
  return false
end

------------------------------------------------------------------------------------------------------------

--if not echo_outputFile      then echo_outputFile      = "" ; end

function  echo(...) -- Requires   string2file  ,  dumptable

    local ret,retStr,cur_echo_outputFile = {}, "", echo_outputFile

    if          echo_outputFile_once_clear                           then  echo_outputFile_once_clear = nil  ; if echo_outputFile_once then echo_outputFile_once = nil ; end
    elseif  not echo_outputFile_once_clear and echo_outputFile_once  then  echo_outputFile_once_clear = true
    elseif      echo_outputFile_once                                 then  cur_echo_outputFile = echo_outputFile_once
    end

    local inp = ({...})
    for k,v in pairs(inp)
    do
        local typev = type(v) or ""
        local retCur = ""
        if      ( typev == "table"  )  then  if #ret > 0 then retCur = "\n"..dumptable(v) ;  else  retCur = dumptable(v)  ; end
        elseif  ( typev == "string" )  then  retCur = v
        elseif  ( typev == "number" )  then  retCur = tostring(v)
        elseif  ( typev == "Vector" )  then  if v.x and v.y and v.z then retCur = string.format( "Vector( %.6f, %.6f, %.6f )", v.x, v.y, v.z ) ; elseif v.x and v.y then retCur = string.format( "Vector( %.6f, %.6f )", v.x, v.y ) ; end
        else    retCur = tostring(v)
        end
        print(retCur)
        ret[#ret+1] = retCur
    end

    if    ( #ret > 0 )
    then  retStr = table.concat(ret,"\n")
    end

    if  ( #ret > 0 ) and string2file and cur_echo_outputFile and cur_echo_outputFile ~= ""
    then
        string2file(retStr,cur_echo_outputFile,"a")
    end

    return retStr

end

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
  return player_table
end

------------------------------------------------------------------------------------------------------------

function tp(...)
    local x,y,z = false,false,false
    for k,v in pairs({...}) do
        if      ( type(v) == "table" or type(v) == "Vector" ) and v[1] then x,y,z = v[1], v[2], v[3]
        elseif  ( type(v) == "table" or type(v) == "Vector" ) and v.x  then x,y,z = v.x,  v.y,  v.z
        elseif  ( type(v) == "number" or tonumber(v)        )          then if not x then x = tonumber(v) ; elseif not y then y = tonumber(v) ; elseif not z then z = tonumber(v) ; end
        end
    end
    if not x or not y or not z then return ; end
    HBU.TeleportPlayer(Vector3(x,y,z))
end

------------------------------------------------------------------------------------------------------------
