-- Launch Hammerspoon at login
hs.autoLaunch(true)

-- Quake-style WezTerm toggle
hs.hotkey.bind({}, "F12", function()
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

-- Cmd-Tab to an app whose windows are all minimized: restore one
appWatcher = hs.application.watcher.new(function(name, event, app)
  if event ~= hs.application.watcher.activated or not app then return end
  local wins = app:allWindows()
  if #wins == 0 then return end
  for _, w in ipairs(wins) do
    if w:isStandard() and not w:isMinimized() and w:isVisible() then return end
  end
  -- every window is minimized: restore the most recent one
  for _, w in ipairs(wins) do
    if w:isMinimized() then w:unminimize(); w:focus(); return end
  end
end)
appWatcher:start()
