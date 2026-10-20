-- Launch Hammerspoon at login
hs.autoLaunch(true)

-- Toggle Tern visibility
hs.hotkey.bind({}, "F12", function()
  local app = hs.application.find("Tern")
  if app then
    if app:isFrontmost() then
      app:hide()
    else
      app:activate()
    end
  else
    hs.application.launchOrFocus("Tern")
  end
end)

-- When an app is activated by any means (Cmd-Tab, Dock click, notification)
-- and all of its standard windows are minimized, restore one of them
appWatcher = hs.application.watcher.new(function(name, event, app)
  if event ~= hs.application.watcher.activated or not app then return end
  local wins = app:allWindows()
  if #wins == 0 then return end
  for _, w in ipairs(wins) do
    if w:isStandard() and not w:isMinimized() and w:isVisible() then return end
  end
  -- Every standard window is minimized: restore the first one allWindows()
  -- lists. That order is not guaranteed to be recency (ranking them would need
  -- hs.window.filter's focus history).
  for _, w in ipairs(wins) do
    if w:isStandard() and w:isMinimized() then w:unminimize(); w:focus(); return end
  end
end)
appWatcher:start()
