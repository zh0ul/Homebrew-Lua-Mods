local Mod = {}
function main(go) Mod.gameObject = go ; return Mod ; end

------------------------------------------------------------------------------------------------------------

function Mod:Awake()
    print("Custom-Unity-Settings.lua:Awake()")
    Camera.main:GetComponent("TOD_Scattering").enabled = false
    RenderSettings.fog = false
    Camera.main.farClipPlane = 40000
end

------------------------------------------------------------------------------------------------------------

function Mod:OnDestroy()
    print("Custom-Unity-Settings.lua:OnDestroy()")
end

------------------------------------------------------------------------------------------------------------

function Mod:Update()
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

function Set_Object_Value(obj,key,value) if not obj or not key or ( not obj[key] and not getmetatable(obj)) then  Log("Set_Object_Value() Failed",tostring(obj),key,value) ; return false  end  ;  if type(value) == "nil" and type(obj[key]) == "boolean" then value = not obj[key]  end ; obj[key] = value ; Log(key,"=",value) ; return value ; end

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

function log()
  local dataPath =  Application.dataPath  --  D:/Games/Steam/steamapps/common/Homebrew - Vehicle Sandbox/HB146_Data
  local dataTab  = {}
  forLineIn(dataPath.."/output_log.txt",function(line) dataTab[#dataTab+1] = line  ; end,true,true,true)
  local tempTab = {}
  local l,h = #dataTab-100, #dataTab
  if  l < 1 then l = 1 ; end
  for i = #dataTab,#dataTab-100,-1  do  if dataTab[i] then print(dataTab[i]) ; end  end
end

HBConsoleManager.instances[1].OnConnect = { "+=", log }

------------------------------------------------------------------------------------------------------------
