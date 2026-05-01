-- Quake-style WezTerm toggle
hs.hotkey.bind({"ctrl"}, "`", function()
  local app = hs.application.find("wezterm")
  if app then
    if app:isFrontmost() then
      app:hide()
    else
      app:activate()
    end
  else
    hs.application.launchOrFocus("WezTerm")
  end
end)
