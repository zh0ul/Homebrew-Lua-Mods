UI = {}

function UI:Awake()
    print("UI:Awake()")
    self.parent = HBU.menu.transform:Find("Foreground").gameObject
    self.ObjectsToDestroy = {}
    self.error_image_file   = Application.persistentDataPath .. "/Lua/GadgetLua/Quandro.png"
    self.TextureCache = {}
    self.useTextureCacheTable = true
end    

function UI:Update()
end

function UI:OnDestroy()
    print("UI:OnDestroy()")
end

function UI:AddImage(x, y, w, h, path )
    if type(path) ~= "string" then return false ; end
    local owner = tostring(debug.getinfo(2).short_src)
    local img = {
        owner = owner,
        height = h,
        width = w,
        name = "An Image",
        path = path,
        image = false,
        UpdateRect = function (img)
            HBU.LayoutRect( img.image, Rect( img.x - math.floor(img.width/2), img.y - math.floor(img.height/2), img.width, img.height ) )
        end
    }
    img.x = x
    img.y = y       
    img.id = HBU.GetRandomID()

    local GetID = function ()
        return img.id
    end

    local SetPosition = function (x,y)
        img.x = x
        img.y = y       
        img.UpdateRect(img)
    end

    local GetPosition = function ()
        return img.x, img.y
    end

    local SetDimensions = function (x,y)
        img.width = x
        img.height = y
        img.UpdateRect(img)
    end

    local GetDimensions = function ()
        return img.width, img.height
    end

    local GetName = function()
        return img.name
    end
    local GetOwner = function()
        return img.owner
    end
    local GetPath = function()
        return img.path
    end
    
    local SetImage = function(path)
        local texture = false
        if  self.useTextureCacheTable and self.TextureCache[path]
        then    
            texture = self.TextureCache[path]
            print("UI : Using texture from TextureCache")
        else
            texture = HBU.LoadTexture2D(path)
            self.TextureCache[path] = texture
            if not texture then print("UI : ERROR : texture is empty for file "..path) ; return false ; end
        end
        if not self.useTextureCacheTable then GameObject.Destroy(img.texture) end
        img.texture = texture
        HBU.LayoutRect( img.image, Rect( x, y, w, h ) )
        img.image:GetComponent("RawImage").texture = img.texture
        img.UpdateRect(img)
        img.path = path
    end

    local Destroy = function () 
        print("destroy called on image " .. img.id)
        GameObject.Destroy(img.image)
        if not self.useTextureCacheTable then 
            GameObject.Destroy(img.texture)  
            self.TextureCache[img.path] = nil
        end
        self.ObjectsToDestroy[img.owner][img.id] = nil
    end

    img.texture    = false
    local texture = false
    
    if  self.useTextureCacheTable and self.TextureCache[path]
    then    
        texture = self.TextureCache[path]
        print("UI : Using texture from TextureCache")
    else    
        texture = HBU.LoadTexture2D(path)
        self.TextureCache[path] = texture
        if not texture then print("UI : ERROR : texture is empty for file "..path) ; return false ; end
    end
    img.texture = texture

    img.image = HBU.Instantiate("RawImage",self.parent)
    HBU.LayoutRect( img.image, Rect( x, y, w, h ) )
    img.image:GetComponent("RawImage").texture = img.texture
    img.image:GetComponent("RawImage").color   = Color(1,1,1,1)
    img.image.transform.pivot                  = Vector2(0.5,0.5)

    if not self.ObjectsToDestroy[owner] then self.ObjectsToDestroy[owner] = {} end
    self.ObjectsToDestroy[owner][img.id] = img

    return {
        GetID = GetID,
        SetPosition = SetPosition,
        GetPosition = GetPosition,
        SetDimensions = SetDimensions,
        GetDimensions = GetDimensions,
        GetName = GetName,
        GetOwner = GetOwner,
        GetPath = GetPath,
        SetImage = SetImage,
        Destroy = Destroy
    }

end



function UI:CleanUp()
    local owner = tostring(debug.getinfo(2).short_src)
    print("Destroying objects created by " .. owner)
    if  self and self.ObjectsToDestroy  and self.ObjectsToDestroy[owner]
    then
        for k, v in pairs(self.ObjectsToDestroy[owner])
        do
            echo("deleting key: " .. k)
            if    self.ObjectsToDestroy[owner][k]
            then
                -- local v = self.ObjectsToDestroy[owner][i]
                if v and not Slua.IsNull(v)
                then
                    if      v.owner == owner
                    then    
                        if not self.useTextureCacheTable then GameObject.Destroy(v.texture) end
                        GameObject.Destroy(v.image)
                    else    print("mismatched owner!")
                    end
                end
            end
        end
    end
    self.ObjectsToDestroy[owner] = {}
end

return UI