Name = "categories"
NamePretty = "Categories"
HideFromProviderlist = true
FixedOrder = true

function GetEntries()
  return {
    { Text = "Games",    Icon = "applications-games",        SubMenu = "games",    Keywords = {"game","play","steam"} },
    { Text = "Internet", Icon = "applications-internet",     SubMenu = "internet", Keywords = {"browser","web","chat","discord"} },
    { Text = "Media",    Icon = "applications-multimedia",   SubMenu = "media",    Keywords = {"music","video","audio","spotify","obs"} },
    { Text = "Dev",      Icon = "applications-development",  SubMenu = "dev",      Keywords = {"code","editor","development","neovim","vscode"} },
    { Text = "System",    Icon = "preferences-system",           SubMenu = "system",    Keywords = {"settings","system","config","bluetooth"} },
    { Text = "Wallpaper", Icon = "preferences-desktop-wallpaper", SubMenu = "wallpaper", Keywords = {"wallpaper","background","image"} },
  }
end
