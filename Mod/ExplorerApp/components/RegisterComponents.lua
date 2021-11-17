--[[
Title: Register Components
Author(s): big
CreateDate: 2021.11.17
Desc:
Place: Foshan
use the lib:
------------------------------------------------------------
local RegisterComponents = NPL.load('(gl)Mod/ExplorerApp/components/RegisterComponents.lua')
------------------------------------------------------------
]]

local ParacraftWorldComponent = NPL.load('(gl)Mod/ExplorerApp/components/ParacraftWorld/ParacraftWorldComponent.lua')

local RegisterComponents = NPL.export()

function RegisterComponents:Init()
    Map3DSystem.mcml_controls.RegisterUserControl('pe:paracraft_world', ParacraftWorldComponent)
end
