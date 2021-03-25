--[[
Title: Keepwork Projects Api
Author(s):  big
Date:  2021.3.23
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkProjectsApi = NPL.load("(gl)Mod/Explorer/api/Keepwork/KeepworkProjectsApi.lua")
------------------------------------------------------------
]]

local KeepworkBaseApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/BaseApi.lua')

local KeepworkProjectsApi = NPL.export()

-- url: /projects/favorite
-- method: GET
--[[
    x-per-page int necessary
    x-page int int necessary
]]
-- return object
function KeepworkProjectsApi:Favorite(xPage, xPerPage, success, error)
    local params = {
        ['x-per-page'] = xPerPage,
        ['x-page'] = xPage
    }

    KeepworkBaseApi:Get('/projects/favorite', params, nil, success, error)
end

-- url:/projects/mySchools
-- method: GET
-- params:
--[[
    x-per-page int necessary
    x-page int int necessary
    classId int schoolId not necessary
]]
-- return:
--[[
]]
function KeepworkProjectsApi:MySchools(classId, xPage, xPerPage, success, error)
    local params = {
        ['x-per-page'] = xPerPage,
        ['x-page'] = xPage,
        classId = classId
    }

    KeepworkBaseApi:Get('/projects/mySchools', params, nil, success, error)
end