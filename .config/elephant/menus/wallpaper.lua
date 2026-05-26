Name = "wallpaper"
NamePretty = "Wallpaper"
HideFromProviderlist = true
FixedOrder = false
RefreshOnChange = { os.getenv("HOME") .. "/Pictures/Wallpapers" }

local EXTS = { jpg=true, jpeg=true, png=true, webp=true, gif=true }

function GetEntries()
  local entries = {}
  local dir = os.getenv("HOME") .. "/Pictures/Wallpapers"
  local h = io.popen("find '" .. dir .. "' -maxdepth 1 -type f 2>/dev/null | sort")
  if not h then return entries end

  for path in h:lines() do
    local ext = path:match("%.([^%.]+)$")
    if ext and EXTS[ext:lower()] then
      local name = path:match(".*/(.+)%.[^%.]+$") or path
      table.insert(entries, {
        Text        = name,
        Preview     = path,
        PreviewType = "file",
        Actions = {
          activate = "awww img '" .. path .. "' --transition-type any --transition-duration 2 && ~/.config/viegphunt/wallpaper_effects.sh",
        },
      })
    end
  end

  h:close()
  return entries
end
