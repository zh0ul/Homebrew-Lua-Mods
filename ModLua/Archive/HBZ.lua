local HBZlocal = {}

function HBZlocal:Awake()
    print("HBZ:Awake()")
end

function HBZlocal:Update()
end

function HBZlocal:OnDestroy()
    print("HBZ:OnDestroy()")
end

function HBZlocal:TutorialVidControl()
    local screenObjJustSet = false
    if not self or self ~= HBZlocal                      then print("HBZ:TutorialVidControl : ERROR : self is not HBZlocal : Try HBZ:TutorialVidControl(args)") ; return false ; end
    if not self.screenObj or Slua.IsNull(self.screenObj) then self.screenObj = GameObject.Find("TutorialScreen") ; screenObjJustSet = true ; end
    if not self.screenObj or Slua.IsNull(self.screenObj) then print("HBZ:TutorialVidControl : ERROR : self.screenObj is nil : Not in Build Mode?") ; return false ; end
    local screenObj = self.screenObj
    if screenObjJustSet
    then
        self.vidPlayer                 = screenObj:GetComponent("HBVideoPlayer") 
        screenObj.transform.localScale = Vector3.one * 0.02
        screenObj.transform.position   = screenObj.transform.position + Vector3.up * 10 + Vector3.forward*10
    end
    local vidPlayer = self.vidPlayer
    self.vidURL = "http://zhoul.gotdns.org/p/p1.mp4"
    vidPlayer:LoadURL(self.vidURL)
    vidPlayer:Play()
end

HBZ = HBZlocal

setmetatable( HBZ,
              {
                 __call = function(self,...) for k,v in pairs(self) do if type(v) == "function" then print( string.format( "%35s  HBZ:%s()", tostring(v), tostring(k) ) ) else  print( string.format( "%35s  HBZ.%s", tostring(v), tostring(k) ) ) ; end ; end ; end,
              }
            )

function main(g) HBZlocal.gameObject = g ; return HBZlocal ; end
