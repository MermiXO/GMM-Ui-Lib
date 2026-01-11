# GMM UI Library (GTA-Style Menu)

## Quick Start (Copy/Paste)

```lua
local GmmUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/MermiXO/GMM-Ui-Lib/refs/heads/main/src.lua?t=" .. tick()))()

local ui = GmmUI.new({ Title = "MY MENU" })

local home = ui:NewMenu("HOME")
local player = ui:NewMenu("PLAYER")

home:Submenu("Player Options", "Options that affect your player.", player)

player:Button("Heal Player", "Restores your health to 100%.", function()
	print("Player Healed!")
end)

player:Toggle("God Mode", "Makes the player invincible.", false, function(on)
	print("God Mode:", on)
end)

ui:PushMenu(home)
```

## Creating Menus

```lua
local menu = ui:NewMenu("MENU NAME")
```

## Linking Menus (Submenus)

```lua
home:Submenu("Open Player Menu", "Opens player options.", player)
```

## Menu Items (API)

```lua
menu:Button(label, description, callback)
menu:Toggle(label, description, defaultValue, callback)
menu:Slider(label, description, min, max, step, defaultValue, callback)
menu:List(label, description, valuesTable, defaultIndex, callback)
menu:Submenu(label, description, childMenu)
```

## Showing the Menu

```lua
ui:PushMenu(home)
```

## Controls

- **Toggle Menu**: `F4` or `Insert`
- **Up / Down**: `Up Arrow` / `Down Arrow` or `Numpad 8` / `Numpad 2` or `I` / `K`
- **Left / Right**: `Left Arrow` / `Right Arrow` or `Numpad 4` / `Numpad 6` or `J` / `L`
- **Select**: `Enter` or `Numpad 5` or `O`
- **Back / Close**: `Backspace` or `Numpad 0` or `U`
- **Page Up / Down**: `PageUp` / `PageDown` or `Numpad 9` / `Numpad 3`

## Troubleshooting

If arrow keys / numpad don’t work while you’re holding movement keys, that can be **keyboard ghosting** (your keyboard never sends the key press). Try the alternate keys: `IJKL` + `U` + `O`.
