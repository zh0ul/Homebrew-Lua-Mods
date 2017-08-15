local Gadget = {}
function main(go) Gadget.gameObject = go ; return Gadget ; end

--[[
    local browser   = GameObject("bro")
    local broScript = HBU.AddComponentLua(browser,"Browser.lua")
    broScript.self:Init( path , assetType , function(v) end , function(v) end )
--]]

function Gadget:Init( path , assetType , onReturn , onCancel )
  
  self.curPath = path
  self.onReturn = onReturn
  self.onCancel = onCancel

  --create ui
  self.uiRoot = HBU.Instantiate("Vertical",HBU.menu.transform:Find("Foreground").gameObject)
  HBU.LayoutRect(self.uiRoot,Rect(100,100,Screen.width-200,Screen.height-200))
  
  local scroll = HBU.Instantiate("Scroll",self.uiRoot)
  scroll:GetComponent("Image").color = Color(0.1,0.1,0.1,1)
  HBU.LayoutFlexible(scroll,0,9)
  self.scrollContent = scroll.transform:Find("Content").gameObject
  local gridLayout = self.scrollContent:AddComponent("UnityEngine.UI.GridLayoutGroup")
  gridLayout.cellSize = Vector2(100,150)
  
  local footer = HBU.Instantiate("Panel",self.uiRoot)
  footer:GetComponent("Image").color = Color(0.2,0.2,0.2,1)
  HBU.LayoutFlexible(footer,0,1)

  local hor = footer:AddComponent("UnityEngine.UI.HorizontalLayoutGroup")
  hor.childAlignment = TextAnchor.MiddleRight
  hor.childForceExpandWidth = false

  local cancelButton = HBU.Instantiate("Button",footer)
  cancelButton:GetComponent("Button").onClick:AddListener(function() self:Cancel() end)
  cancelButton:GetComponent("Image").color = Color(0.3,0.3,0.3,1)
  cancelButton.transform:Find("Text"):GetComponent("Text").color = Color.white
  cancelButton.transform:Find("Text"):GetComponent("Text").text = "Cancel"  
  HBU.LayoutMin(cancelButton,120,0)

  --grab files and dirs async 
  HBU.GetAssetsAsync(path,function(files) self:CreateFileItems(files) end)
  --HBU.GetDirectoriesAsync(path,"",function(dirs) self.dirs = dirs self.dirsLoading = false end)
  
end

function Gadget:CreateFileItems( files )
  local p
  
  local cc = 1
  for p in Slua.iter(files) do
    local item = self:CreateItem(p)
    cc = cc+1
    if( cc > 10 ) then break end
  end
  --for p in Slua.iter(self.dirs) do
  --  local item = self:CreateItem(p)
  --end
  
end

function Gadget:ObjExists(obj)  if obj and not Slua.IsNull(obj) then return true ; end ; return false ; end

function Gadget:OnDestroy()
  if self:ObjExists(self.uiRoot) then GameObject.Destroy(self.uiRoot) end
end

function Gadget:CreateItem(path)
  local ret = HBU.Instantiate("Button",self.scrollContent)
  ret:GetComponent("Image").color = Color(0.4,0.4,0.4,1)
  ret:GetComponent("Button").onClick:AddListener(function() self:SelectItem(path) end)
  ret:AddComponent("UnityEngine.UI.VerticalLayoutGroup")

  
  local text = ret.transform:Find("Text").gameObject
  HBU.LayoutFlexible(text,0,1000)
  text:GetComponent("Text").text = HBU.GetAssetName(path)
  text:GetComponent("Text").color = Color.white

  local img = HBU.Instantiate("RawImage",ret)
  HBU.LayoutMin(img,0,100)
  img.transform:SetSiblingIndex(0)
  img.transform.anchorMin = Vector2(0,0)
  img.transform.anchorMax = Vector2(1,1)
  img.transform.offsetMin = Vector2(0,0)
  img.transform.offsetMax = Vector2(0,0)
  
  img:GetComponent("RawImage").texture = HBU.GetAssetImage(path)
  return ret
end

function Gadget:SelectItem(path)
  Debug.Log("select "..path)
  self.onReturn(HBU.GetAssetFile(path))
end

function Gadget:Cancel()
  self.onCancel()
end

return Browser
