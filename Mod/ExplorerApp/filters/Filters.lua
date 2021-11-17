--[[
Title: filters
Author(s):  Big
Date: 2021.3.5
Desc: 
use the lib:
------------------------------------------------------------
local Filters = NPL.load('(gl)Mod/ExplorerApp/filters/Filters.lua')
Filters:Init()
------------------------------------------------------------
]]

local ExplorerApp = commonlib.gettable("Mod.ExplorerApp")

-- pages
local MainPage = NPL.load("(gl)Mod/ExplorerApp/pages/MainPage.lua")

local Filters = NPL.export()

function Filters:Init()
    GameLogic.GetFilters():add_filter(
        'cellar.explorer.show',
        function(...)
            ExplorerApp:Init(...);
        end
    )

    GameLogic.GetFilters():add_filter(
        'cellar.explorer.close',
        function()
            MainPage:Close();
        end
    )
end