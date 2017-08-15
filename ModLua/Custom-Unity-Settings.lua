local Mod = {}
function main(go) Mod.gameObject = go ; return Mod ; end

function Mod:Awake()
    Camera.main:GetComponent("TOD_Scattering").enabled = false
    RenderSettings.fog = false
    Camera.main.farClipPlane = 40000
end

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


function Set_Object_Value(obj,key,value) if not obj or not key or ( not obj[key] and not getmetatable(obj)) then  Log("AntyFog:Set_Object_Value() Failed",tostring(obj),key,value) ; return false  end  ;  if type(value) == "nil" and type(obj[key]) == "boolean" then value = not obj[key]  end ; obj[key] = value ; Log(key,"=",value) ; return value ; end

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
