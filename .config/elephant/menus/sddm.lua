Name = "sddm"
NamePretty = "SDDM Theme"
HideFromProviderlist = true
FixedOrder = false
RefreshOnChange = { "/usr/share/sddm/themes" }

local PREVIEW_CANDIDATES = {
  "preview.png", "preview.jpg",
}

local function read_pretty_name(dir)
  local f = io.open(dir .. "/metadata.desktop", "r")
  if not f then return nil end
  local name
  for line in f:lines() do
    local k, v = line:match("^([^=]+)=(.*)")
    if k == "Name" then name = v; break end
  end
  f:close()
  return name
end

local function find_preview(dir)
  for _, name in ipairs(PREVIEW_CANDIDATES) do
    local f = io.open(dir .. "/" .. name, "r")
    if f then f:close(); return dir .. "/" .. name end
  end
  for _, subdir in ipairs({ "Previews", "screenshots", "images" }) do
    local h = io.popen(
      "find '" .. dir .. "/" .. subdir ..
      "' -maxdepth 1 -type f \\( -name '*.png' -o -name '*.jpg' \\) 2>/dev/null | sort | head -1"
    )
    if h then
      local p = h:read("*l")
      h:close()
      if p and p ~= "" then return p end
    end
  end
  -- fallback: any image directly in the theme dir
  local h = io.popen(
    "find '" .. dir .. "' -maxdepth 1 -type f \\( -name '*.png' -o -name '*.jpg' \\) 2>/dev/null | sort | head -1"
  )
  if h then
    local p = h:read("*l")
    h:close()
    if p and p ~= "" then return p end
  end
  return nil
end

function GetEntries()
  local entries = {}
  local h = io.popen("find /usr/share/sddm/themes -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort")
  if not h then return entries end

  for dir in h:lines() do
    local id = dir:match(".*/(.+)$")
    local pretty = read_pretty_name(dir) or id
    local preview = find_preview(dir)

    local entry = {
      Text    = pretty,
      Subtext = id,
      Icon    = "preferences-desktop-theme",
      Actions = {
        activate = string.format("~/.config/viegphunt/set_sddm_theme.sh '%s'", id),
      },
    }
    if preview then
      entry.Preview     = preview
      entry.PreviewType = "file"
    end
    table.insert(entries, entry)
  end

  h:close()
  return entries
end
