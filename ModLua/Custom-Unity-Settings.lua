Camera.main:GetComponent("TOD_Scattering").enabled = false
RenderSettings.fog = false

function showmeta(...)
    
    for k,v in pairs({...}) do
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
    if type(element) == "table"
    then
            for k,v in pairs(element) do if type(v) == "table" then aTab[tostring(k)] = getmeta_1(v,name.."."..tostring(k)) ; else aTab[tostring(k)] = getmeta_2(v,name.."."..tostring(k)) ; end ; end

    elseif  type(element) == "userdata"
    then    
            aTab[#aTab+1] = getmeta_2(element,name)
    end
    return unpack(aTab)
end

function getmeta_2(element,name)
    if  type(element) == "userdata"
    then
        local aTab = {}
        for k,v in pairs(getmetatable(element)) do aTab[#aTab+1] = string.format( "  %-20s  %s",type(v), name..tostring(k) ) ; end
        table.sort(aTab)
        return aTab
    end
end
