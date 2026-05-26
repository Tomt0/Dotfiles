Name = "system"
NamePretty = "System"
HideFromProviderlist = true
FixedOrder = true

-- Exclude terminal emulators and file managers (they live in the main search)
local EXCLUDE_CATS = { TerminalEmulator=true, FileManager=true }
-- Exclude low-level or redundant entries
local BLACKLIST = {
  ["YAD settings"]=true, ["Menu Editor"]=true, ["Desktop Session Settings"]=true,
  ["Default applications for LXSession"]=true, ["Print Settings"]=true,
  ["Avahi Zeroconf Browser"]=true, ["GTK Settings"]=true,
}

local function parse_desktop(path)
  local e, in_sec = {}, false
  local f = io.open(path, "r")
  if not f then return nil end
  for line in f:lines() do
    line = line:gsub("\r$", "")
    if line == "[Desktop Entry]" then in_sec = true
    elseif line:match("^%[") and in_sec then break
    elseif in_sec and not line:match("^#") then
      local k, v = line:match("^([^=]+)=(.*)")
      if k then e[k:match("^%s*(.-)%s*$")] = v:match("^%s*(.-)%s*$") end
    end
  end
  f:close()
  return e
end

local function has_cat(cats_str, ...)
  for _, c in ipairs({...}) do
    if cats_str:find(c, 1, true) then return true end
  end
  return false
end

local function has_exclude_cat(cats_str)
  for cat in (cats_str .. ";"):gmatch("([^;]*);") do
    if EXCLUDE_CATS[cat] then return true end
  end
  return false
end

function GetEntries()
  local apps, seen = {}, {}

  table.insert(apps, {
    Text    = "SDDM Theme",
    Icon    = "preferences-desktop-theme",
    Subtext = "Change login screen theme",
    SubMenu = "sddm",
  })
  table.insert(apps, {
    Text    = "SDDM Wallpaper",
    Icon    = "preferences-desktop-wallpaper",
    Subtext = "Change login screen wallpaper",
    SubMenu = "sddm_wallpaper",
  })

  for _, dir in ipairs({ os.getenv("HOME") .. "/.local/share/applications", "/usr/share/applications" }) do
    local h = io.popen("find '" .. dir .. "' -maxdepth 1 -name '*.desktop' 2>/dev/null | sort")
    if h then
      for path in h:lines() do
        local e = parse_desktop(path)
        if e and e.Type == "Application"
          and (e.NoDisplay or "false"):lower() ~= "true"
          and (e.Hidden  or "false"):lower() ~= "true"
        then
          local name = (e.Name or ""):match("^%s*(.-)%s*$")
          local cats = e.Categories or ""
          if name ~= "" and not seen[name] and not BLACKLIST[name]
            and not has_exclude_cat(cats)
            and has_cat(cats, "Settings", "DesktopSettings", "HardwareSettings", "System", "Monitor")
          then
            seen[name] = true
            table.insert(apps, {
              Text    = name,
              Icon    = e.Icon or "preferences-system",
              Subtext = e.Comment or e.GenericName or "",
              Actions = { activate = "gio launch " .. path },
            })
          end
        end
      end
      h:close()
    end
  end
  return apps
end
