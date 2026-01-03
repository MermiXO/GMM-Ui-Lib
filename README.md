# GMM UI Library Setup Tutorial

This is a tutorial on how to use the GMM UI Library in your Roblox scripts. This library allows you to easily create a GTA-style mod menu.

## 1. Setup

First, you need to load the library into your script using `loadstring` and `game:HttpGet`. It's recommended to add a cache-busting parameter to the URL to ensure you always have the latest version.

```lua
local GmmUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/MermiXO/GMM-Ui-Lib/refs/heads/main/src.lua?t="))()
```

## 2. Initialization

Once the library is loaded, you can create a new UI instance. You can pass a `Title` for your menu in the options table.

```lua
local ui = GmmUI.new({ Title = "MY MENU" })
```

## 3. Creating Menus

Menus are the containers for your options. You can create as many as you need.

```lua
local home = ui:NewMenu("HOME")
local playerMenu = ui:NewMenu("PLAYER")
local settingsMenu = ui:NewMenu("SETTINGS")
```

### Submenus

To link menus together, you use the `Submenu` function. This creates a navigation point from a parent menu to a child menu.

```lua
-- This will add an option in the 'home' menu called "Player Options"
-- that opens the 'playerMenu' when selected.
home:Submenu("Player Options", "Options that affect your player.", playerMenu)
home:Submenu("Settings", "UI and miscellaneous settings.", settingsMenu)
```

## 4. Adding UI Components

All components are added to a menu object. Here are the available components:

### Button

A simple button that executes a function when pressed.

**Usage:** `menu:Button(label, description, callback)`

```lua
playerMenu:Button("Heal Player", "Restores your health to 100%.", function()
    print("Player Healed!")
end)
```

### Toggle

A switch that can be turned ON or OFF. The callback function receives the new boolean state (`true` for ON, `false` for OFF).

**Usage:** `menu:Toggle(label, description, defaultValue, callback)`

```lua
playerMenu:Toggle("God Mode", "Makes the player invincible.", false, function(isGodMode)
    print("God Mode is now:", isGodMode)
end)
```

### Slider

A slider that allows selecting a number within a range. The callback receives the new numeric value.

**Usage:** `menu:Slider(label, description, min, max, step, defaultValue, callback)`

```lua
playerMenu:Slider("WalkSpeed", "Changes the player's walk speed.", 16, 100, 1, 16, function(speed)
    print("WalkSpeed set to:", speed)
end)
```

### List

A list of options to choose from. The callback receives the selected value and its index in the list.

**Usage:** `menu:List(label, description, valuesTable, defaultIndex, callback)`

```lua
settingsMenu:List("Theme", "Changes the UI theme.", { "Classic", "Dark", "High Contrast" }, 1, function(themeName, index)
    print("Theme changed to:", themeName, "at index", index)
end)
```

## 5. Displaying the Menu

To make the menu appear, you must push the initial menu you want to display.

```lua
-- Push the 'home' menu to make it the starting point
ui:PushMenu(home)
```

## 6. Controls

-   **Toggle Menu**: `F4` or `Insert`
-   **Navigate Up/Down**: `Up Arrow` / `Down Arrow` or `Numpad 8` / `Numpad 2`
-   **Select Option**: `Enter` or `Numpad 5`
-   **Go Back / Close**: `Backspace` or `Numpad 0`
-   **Change Value (Sliders/Lists)**: `Left Arrow` / `Right Arrow` or `Numpad 4` / `Numpad 6`
