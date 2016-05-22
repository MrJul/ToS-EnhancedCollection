# Enhanced Collection
This is an add-on for the game Tree of Savior that revamps the collection window.

![Enhanced Collection screenshot](https://raw.githubusercontent.com/MrJul/ToS-EnhancedCollection/master/Screenshot.png)

## Features
 - Displays the collections as a list: no more cropped names.
 - Can optionally display unknown collections.
 - Displays the number of items in a collection, including how many can be added from the inventory.
 - Ability to filter complete, incomplete or unknown collections.
 - Can sort collections by game order, name, or status (collections with missing items present in the inventory are listed first).
 - Quickly find a collection by name using the search box.
 - Clearly displays which items are inside the collection or can be added from the inventory.
 

## Installation

1. Download and install either [Excrulon's Lua Mods](https://github.com/Excrulon/Tree-of-Savior-Lua-Mods) or [fiote's cwLibrary](https://github.com/fiote/treeofsavior-addons).
2. Download the [latest release of Enhanced Collection](https://github.com/MrJul/ToS-EnhancedCollection/releases).
3. Extract the downloaded zip into your Tree of Savior `addons` folder (under *&lt;steam folder&gt;\steamapps\common\TreeOfSavior\addons*).
4. If you're using Excrulon's addons, add the following line to `addonloader.lua` under the `[[ADDONS]]` section:

```lua
dofile("../addons/enhancedcollection/enhancedcollection.lua");
```

The final file should look like this:

```lua
--[[ADDONS]]
dofile("../addons/betterquest/betterquest.lua");
dofile("../addons/channelsurfer/channelsurfer.lua");
dofile("../addons/contextmenuadditions/contextmenuadditions.lua");
dofile("../addons/expcardcalculator/expcardcalculator.lua");
dofile("../addons/expviewer/expviewer.lua");
dofile("../addons/guildmates/guildmates.lua");
dofile("../addons/hidemaxedattributes/hidemaxedattributes.lua");
dofile("../addons/mapfogviewer/mapfogviewer.lua");
dofile("../addons/monsterframes/monsterframes.lua");
dofile("../addons/monstertracker/monstertracker.lua");
dofile("../addons/showinvestedstatpoints/showinvestedstatpoints.lua");
-- add the following line:
dofile("../addons/enhancedcollection/enhancedcollection.lua");
```

## Misc

If you're encountering any problems while using the add-on, please [open an issue](https://github.com/MrJul/ToS-EnhancedCollection/issues)!

If you're interested in collection management, you should probably also install [Xanaxiel's Tooltip Helper](https://github.com/Xanaxiel/ToS-Addons) if you haven't already!
