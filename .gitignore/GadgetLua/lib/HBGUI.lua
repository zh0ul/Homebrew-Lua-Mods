--[[
    Button
    Container
    GridList
    HorizontalList
    HorizontalScroll
    HPBar
    Image
    ImageButton
    ImageHPBar
    IntInput
    Label
    ListItem
    NumberInput
    OutlinedLabel
    Panel
    PasswordInput
    RadialHPBar
    RotationKnob
    Scroll
    Slider
    TextButton
    TextInput
    VerticalList
    VerticalScroll
--]]

local HBGUI = {}

HBGUI                    = {}
HBGUI.IndicatorBars      = {}
HBGUI.PctBars            = {}
HBGUI.TextBars           = {}
HBGUI.IndicatorBarsNext  = { posX = 0.01, posY = 0.1, sizeX = 0.05, sizeY = 0.01, }
HBGUI.IndicatorBarsCount = 0


function HBGUI:Destroy(name)
    local toDestroy = {}
    name = name or "*"
    name = tostring(name)
    for k,v in pairs(self.IndicatorBars)
    do
        if name == "*" or string.find(v,name)
        then
            toDestroy[#toDestroy+1] = k
            if not Slua.IsNull(self.TextBars[k])      then GameObject.Destroy(self.TextBars[k])      ; end
            if not Slua.IsNull(self.PctBars[k].obj)   then GameObject.Destroy(self.PctBars[k].obj)   ; end
            if not Slua.IsNull(self.IndicatorBars[k]) then GameObject.Destroy(self.IndicatorBars[k]) ; end
        end
    end
    for k,v in pairs(toDestroy) do if self.IndicatorBars[v] then self.IndicatorBars[v] = nil ; end ; if self.PctBars[v] then self.PctBars[v] = nil ; end ; if self.TextBars[v] then self.TextBars[v] = nil ; end ; end
    if #toDestroy > 0 then self.IndicatorBarsCount = self.IndicatorBarsCount - #toDestroy ; end
end


function HBGUI:AddIndicatorBar(name,posX,posY,sizeX,sizeY,text,pct)

  if    not name or type(name) ~= "string" or name == "" or self.IndicatorBars[name]
  then  return
  end

  -- posX,posY, sizeX,sizeY are percentages from 0 to 1.
  local multX,multY = Screen.width, Screen.height

  if not sizeX then sizeX = self.IndicatorBarsNext.sizeX ; end
  if not sizeY then sizeY = self.IndicatorBarsNext.sizeY ; end

  if not posX then posX = self.IndicatorBarsNext.posX ; end
  if not posY then posY = self.IndicatorBarsNext.posY ; self.IndicatorBarsNext.posY = self.IndicatorBarsNext.posY + self.IndicatorBarsNext.sizeY ; end

  text = text or ""
  pct  = pct  or 0

  self.IndicatorBarsCount = self.IndicatorBarsCount + 1

  --create a background panel
  self.IndicatorBars[name] = HBU.Instantiate("Panel", HBU.menu.gameObject.transform:Find("Foreground").gameObject)
  HBU.LayoutRect(self.IndicatorBars[name], Rect((multX*posX), (multY*posY), multX*sizeX, multY*sizeY))
  self.IndicatorBars[name]:GetComponent("Image").color = Color(0.2, 0.2, 0.2, 1)
  self.IndicatorBars[name].posX    = posX
  self.IndicatorBars[name].posY    = posY
  self.IndicatorBars[name].sizeX   = sizeX
  self.IndicatorBars[name].sizeY   = sizeY

  --create a panel in the background will serve as loading bar
  self.PctBars[name]                                  = {}
  self.PctBars[name].obj                              = HBU.Instantiate("Panel", self.IndicatorBars[name])
  self.PctBars[name].obj.transform.pivot              = Vector2(0, 1)
  self.PctBars[name].obj.transform.anchorMin          = Vector2(0, 1)
  self.PctBars[name].obj.transform.anchorMax          = Vector2(0, 1)
  self.PctBars[name].obj.transform.anchoredPosition   = Vector2.zero
  self.PctBars[name].obj.transform.offsetMin          = Vector2(3, -3)
  self.PctBars[name].obj.transform.offsetMax          = Vector2(3, -3)
  self.PctBars[name].obj:GetComponent("Image").color  = Color(1, 0.5, 0, 1)
  self.PctBars[name].pct                              = pct
  Debug.Log("Pct:"..tostring(self.PctBars[name].pct))

  --create text object
  self.TextBars[name]                                = HBU.Instantiate("Text", self.IndicatorBars[name])
--self.TextBars[name].transform.pivot                = Vector2(0, 1)
  self.TextBars[name].transform.anchorMin            = Vector2(0, 0)
  self.TextBars[name].transform.anchorMax            = Vector2(1, 1)
  self.TextBars[name].transform.offsetMin            = Vector2.zero
  self.TextBars[name].transform.offsetMax            = Vector2.zero
  self.TextBars[name]:GetComponent("Text").text      = text
  self.TextBars[name]:GetComponent("Text").color     = Color.white
  self.TextBars[name]:GetComponent("Text").alignment = TextAnchor.MiddleCenter
  self.TextBars[name]:AddComponent("UnityEngine.UI.Outline")

end


function HBGUI:UpdateIndicatorBar(name,text,pct)
  if      not name or type(name) ~= "string" then return false
  elseif  not self.IndicatorBars[name]       then HBGUI:AddIndicatorBar(name,nil,nil,nil,nil,text,pct) ; return true
  end
  -- posX,posY, sizeX,sizeY are percentages from 0 to 1.
  local multX,multY = Screen.width, Screen.height
  text = text or self.IndicatorBars[name].text:GetComponent("Text").text or ""
  if not pct or type(pct) ~= "number" then pct = self.PctBars[name].pct ; end
  --set size of the loading bar
  self.PctBars[name].obj.transform.sizeDelta = Vector2( multX*pct - (self.IndicatorBars[name].sizeX/100*6), multY*0.96 )
  self.IndicatorBars[name].text:GetComponent("Text").text = text
  return true
end

return HBGUI
