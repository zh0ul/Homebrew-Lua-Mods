Camera.main:GetComponent("TOD_Scattering").enabled = false
RenderSettings.fog = false

function getmeta(name)
  local element = _G
  if    type(name) == "string"
  then  for part in string.split("Camera.main","[.]") do if element[part] then element = element[part] ; end ; end
  end
  return getmeta_1( element, name )

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
    return aTab
end

function getmeta_2(element,name)
    if  type(element) == "userdata"
    then
        local aTab = {}
        for k,v in pairs(getmetatable(element)) do aTab[#aTab+1] = string.format( "%15s %s",type(v), name..tostring(k) ) ; end
        table.sort(aTab)
        return aTab
    end
end
