local imgui = {}

function imgui:Start()
  self.window = {
    id = 1338,
    rect = Rect(400,400,200,1), --x,y,width,height
    update = self.UpdateWindow,
    values = {
      -- play_sound = false,
      TextField = "" ,
      PasswordField = "" ,
      TextArea = "" ,
      Toolbar = 0,
      SelectionGrid = 0 ,
      HorizontalSlider = 0 ,
      BeginScrollView = Vector2(0,0) ,
      vehicle_count = 1,
      play_sound = true,
      orientation = 3
    }
  }
end

function imgui:OnGUI()
  self.window.rect = GUILayout.Window(self.window.id, self.window.rect, self.window.update, "")
end

function imgui.UpdateWindow(id)
  GUILayout.DragWindow(Rect(0,0,imgui.window.rect.width,20)) --makes top part of window draggable
  local s = imgui.window.values
  local l = function(title, content)
    GUILayout.BeginHorizontal()
    GUILayout.Label(title)
    GUILayout.Space(15)
    content()
    GUILayout.EndHorizontal()
  end

  s.title = GUILayout.Box("Settings")
  GUILayout.Label("")

  GUILayout.BeginHorizontal()
  s.play_sound = GUILayout.Toggle(s.play_sound, "Play Sound")
  GUILayout.EndHorizontal()
  GUILayout.Label("")

  GUILayout.BeginVertical()
  GUILayout.Label("Number of vehicles to display:")
  GUILayout.BeginHorizontal()
  s.vehicle_count = GUILayout.Toolbar(s.vehicle_count, {"5","7","9"})
  GUILayout.EndHorizontal()
  GUILayout.EndVertical()
  GUILayout.Label("")

  GUILayout.BeginVertical()
  GUILayout.Label("Carousel orientation:")

  GUILayout.BeginHorizontal()
  s.orientation = GUILayout.SelectionGrid(s.orientation,{"Left","Right","Top","Bottom"}, 4)
  GUILayout.EndHorizontal()
  GUILayout.Label("")
  GUILayout.EndVertical()

end

return imgui
