Name = "sddm_wallpaper"
NamePretty = "SDDM Wallpaper"
HideFromProviderlist = true
FixedOrder = false

local EXTS = { png=true, jpg=true, jpeg=true, webp=true, gif=true, mp4=true, mkv=true }

local function add_images(entries, dir, label_prefix)
  local h = io.popen("find '" .. dir .. "' -maxdepth 1 -type f 2>/dev/null | sort")
  if not h then return end
  for path in h:lines() do
    local ext = path:match("%.([^%.]+)$")
    if ext and EXTS[ext:lower()] then
      local name = path:match(".*/(.+)%.[^%.]+$") or path
      local entry = {
        Text    = label_prefix .. name,
        Icon    = "preferences-desktop-wallpaper",
        Actions = {
          activate = string.format("~/.config/viegphunt/set_sddm_wallpaper.sh '%s'", path),
        },
      }
      -- only show image previews (not video)
      local img_ext = { png=true, jpg=true, jpeg=true, webp=true, gif=true }
      if img_ext[ext:lower()] then
        entry.Preview     = path
        entry.PreviewType = "file"
      end
      table.insert(entries, entry)
    end
  end
  h:close()
end

function GetEntries()
  local entries = {}
  add_images(entries, os.getenv("HOME") .. "/Pictures/Wallpapers", "")
  return entries
end
