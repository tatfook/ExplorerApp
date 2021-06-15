--[[
Title: Explorer App Page
Author(s):  big
Date: 2019.01.21
Place: Foshan
use the lib:
------------------------------------------------------------
local MainPage = NPL.load("(gl)Mod/ExplorerApp/components/MainPage.lua")
------------------------------------------------------------
]]

-- pkg libs
NPL.load("(gl)Mod/WorldShare/service/FileDownloader/FileDownloader.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/DownloadWorld.lua")

local FileDownloader = commonlib.gettable("Mod.WorldShare.service.FileDownloader.FileDownloader")
local DownloadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.DownloadWorld")
local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld")
local RemoteWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteWorld")
local Screen = commonlib.gettable("System.Windows.Screen")
local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
local Translation = commonlib.gettable("MyCompany.Aries.Game.Common.Translation")

-- databse
local Wallet = NPL.load("(gl)Mod/ExplorerApp/database/Wallet.lua")
local ProjectsDatabase = NPL.load("../database/Projects.lua")

-- service
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Session.lua')
local KeepworkServiceProject = NPL.load("../service/KeepworkService/KeepworkServiceProject.lua")
local KeepworkEsServiceProject = NPL.load("../service/KeepworkEsService/Project.lua")
local WorldShareKeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Project.lua')
local KeepworkServiceSchoolAndOrg = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/SchoolAndOrg.lua')

-- UI
local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/Main.lua")
local Toast = NPL.load("./Toast/Toast.lua")
local Password = NPL.load("./Password/Password.lua")
local GameOver = NPL.load("./GameProcess/GameOver/GameOver.lua")
local TimeUp = NPL.load("./GameProcess/TimeUp/TimeUp.lua")
local ProactiveEnd = NPL.load("./GameProcess/ProactiveEnd/ProactiveEnd.lua")

local MainPage = NPL.export()

MainPage.categorySelected = {}
MainPage.categoryTree = {}
MainPage.worksTree = {}
MainPage.downloadedGame = "all"
MainPage.curPage = 1
MainPage.mainId = 0
MainPage.curSelected = 1
MainPage.sortList = {
    recommend = { value = L'推荐', key = 'recommend' },
    synthesize = { value = L'综合', key = 'synthesize' },
    updatedAt = { value = L'最新', key = 'updated_at' },
    score = { value = L"热门", key = 'score' },
}

function MainPage:ShowPage(callback, classId)
    if callback and type(callback) == 'function' then
        self.CloseCallback = callback
    end

    local params = Mod.WorldShare.Utils.ShowWindow(
        1150,
        650,
        "Mod/ExplorerApp/components/Theme/MainPage.html",
        "Mod.ExplorerApp.MainPage"
    )

    params._page.OnClose = function()
        self.worksTree = {}
        self.downloadedGame = "all"
        self.curPage = 1
        self.mainId = 0
    end

    local MainPagePage = Mod.WorldShare.Store:Get("page/MainPage")

    if MainPagePage then
        if classId and type(classId) == 'number' then
            self:SetCategoryTree(true)
            self.curPage = 1
            self:SetMyClassListWorksTree(classId)
        else
            self:SetCategoryTree()     
        end

        self:GetMyClassList() 
    end
end

function MainPage:SetPage()
    Mod.WorldShare.Store:Set("page/MainPage", document:GetPageCtrl())
end

function MainPage:Refresh(times)
    local MainPagePage = Mod.WorldShare.Store:Get("page/MainPage")

    if MainPagePage then
        MainPagePage:Refresh(times or 0.01)
    end
end

function MainPage:Close()
    local MainPagePage = Mod.WorldShare.Store:Get("page/MainPage")

    if MainPagePage then
        if type(self.CloseCallback) == 'function' then
            self.CloseCallback()
        end

        MainPagePage:CloseWindow()
    end
end

function MainPage.OnScreenSizeChange()
    local MainPage = Mod.WorldShare.Store:Get("page/MainPage")

    if not MainPage then
        return false
    end

    local height = math.floor(Screen:GetHeight())
    local width = math.floor(Screen:GetWidth())

    local areaNode = MainPage:GetNode("area")
    areaNode:SetCssStyle("height", height)
    areaNode:SetCssStyle("width", width)

    local stripNode = MainPage:GetNode("strip")
    stripNode:SetCssStyle("margin-left", (width - 960) / 2)

    local areaContentNode = MainPage:GetNode("area_content")
    areaContentNode:SetCssStyle("height", (height - 45))
    areaContentNode:SetCssStyle("margin-left", (width - 960) / 2)

    MainPage:Refresh(0)
end

function MainPage:UpdateCoins()
    self.playerBalance = Wallet:GetPlayerBalance()
    self:Refresh()
end

function MainPage:UpdateSort()
    self:SetWorksTree(self.categorySelected, Mod.WorldShare.Store:Getter('explorer/GetSortKey'))
end

function MainPage:GetMyClassList()
    local MainPagePage = Mod.WorldShare.Store:Get("page/MainPage")

    if not MainPagePage then
        return false
    end

    KeepworkServiceSchoolAndOrg:GetUserAllSchools(function(data, err)
        if not data or not data.id then
            return
        end

        self.classList = {
            {
                id = -1,
                name = L'全校'
            }
        }

        KeepworkServiceSchoolAndOrg:GetMyClassList(data.id, function(data, err)
            if data and type(data) == 'table' then
                for key, item in ipairs(data) do
                    self.classList[#self.classList + 1] = {
                        id = item.id,
                        name = item.name
                    }
                end

                MainPagePage:GetNode('class_list'):SetUIAttribute("DataSource", self.classList)
            end
        end)
    end)
end

function MainPage:SetCategoryTree(notGetWorks)
    local MainPagePage = Mod.WorldShare.Store:Get("page/MainPage")

    if not MainPagePage then
        return false
    end

    KeepworkServiceProject:GetAllTags(
        function(data, err)
            if err ~= 200 or type(data) ~= "table" or not data.rows then
                return
            end

            self.categoryTree = {
                { id = -1, value = L'热门', color = 'YELLOW' },
                { id = -2, value = L'最新', color = 'YELLOW' },
            }

            self.categorySelected = { id = -1, value = L'热门', color = 'YELLOW' }

            for key, item in ipairs(data.rows) do
                if item and item.tagname ~= "paracraft专用" then
                    local curItem = { id = item.id, value = item.tagname or "" }

                    if item and item.extra and item.extra.enTagname and self:IsEnglish() then
                        curItem.enValue = item.extra.enTagname
                    end

                    -- filter yellow button
                    -- local value = ''

                    if curItem and curItem.value == '大赛作品' then
                        curItem.color = 'YELLOW'
                    elseif curItem and curItem.value == '我的学校' then
                        curItem.color = 'YELLOW'
                    elseif curItem and curItem.value == '编程' then
                        curItem.color = 'BLACK'
                    elseif curItem and curItem.value == '短片' then
                        curItem.color = 'BLACK'
                    elseif curItem and curItem.value == '场景' then
                        curItem.color = 'BLACK'
                    elseif curItem and curItem.value == '机器人' then
                        curItem.color = 'BLACK'
                    elseif curItem and curItem.value == '计算机' then
                        curItem.color = 'BLACK'
                    elseif curItem and curItem.value == '互动' then
                        curItem.color = 'BLACK'
                    elseif curItem and curItem.value == '科学' then
                        curItem.color = 'BLACK'
                    elseif curItem and curItem.value == '语文' then
                        curItem.color = 'BLACK'
                    elseif curItem and curItem.value == '人文' then
                        curItem.color = 'BLACK'
                    elseif curItem and curItem.value == '艺术' then
                        curItem.color = 'BLACK'
                    elseif curItem and curItem.value == '数学' then
                        curItem.color = 'BLACK'
                    elseif curItem and curItem.value == '生物' then
                        curItem.color = 'BLACK'
                    elseif curItem and curItem.value == '设计' then
                        curItem.color = 'BLACK'
                    end

                    self.categoryTree[#self.categoryTree + 1] = curItem
                else
                    self.mainId = item.id
                end
            end

            MainPagePage:GetNode('categoryTree'):SetUIAttribute("DataSource", self.categoryTree)

            if not notGetWorks then
                self:SetWorksTree(self.categorySelected)
            end
        end
    )
end

function MainPage:SetMyClassListWorksTree(classId)
    local MainPagePage = Mod.WorldShare.Store:Get("page/MainPage")

    if not MainPagePage then
        return false
    end

    if not classId then
        classId = self.classId
    else
        self.classId = classId
        self.worksTree = {}
        self.curSelected = 1
        self.isSearching = false
        self.isFavorite = false
        self.isClassList = true
        self.categorySelected = {}
    end

    if classId == -1 then
        classId = nil
    end

    KeepworkServiceProject:GetMySchoolProjects(
        classId,
        { page = self.curPage },
        function(data, err)
        if not data or
            type(data) ~= 'table' or
            not data.rows or
            type(data.rows) ~= 'table' or
            err ~= 200 then
            return
        end

        local mapData = {}

        -- map data struct
        for key, item in ipairs(data.rows) do
            local isVipWorld = false

            if item.extra and item.extra.isVipWorld == 1 then
                isVipWorld = true
            end

            mapData[#mapData + 1] = {
                id = item.id,
                name = item.extra and type(item.extra.worldTagName) == 'string' and item.extra.worldTagName or item.name or "",
                cover = item.extra and type(item.extra.imageUrl) == 'string' and item.extra.imageUrl or "",
                username = item.user and type(item.user.username) == 'string' and item.user.username or "",
                updated_at = item.updatedAt and type(item.updatedAt) == 'string' and item.updatedAt or "",
                user = item.user and type(item.user) == 'table' and item.user or {},
                isVipWorld = isVipWorld,
                total_view = item.visit,
                total_like = item.star,
                total_mark = item.favorite,
                total_comment = item.comment
            }
        end

        local rows = mapData

        if self.curPage ~= 1 then
            self:HandleWorldsTree(rows, function(rows)
                for key, item in ipairs(rows) do
                    self.worksTree[#self.worksTree + 1] = item
                end

                MainPagePage:GetNode("worksTree"):SetUIAttribute("DataSource", self.worksTree)
            end)
        else
            self:HandleWorldsTree(rows, function(rows)
                self.worksTree = rows

                MainPagePage:GetNode("worksTree"):SetUIAttribute("DataSource", self.worksTree)
            end)
        end
    end)
end

function MainPage:SetMyFavoriteWorksTree()
    if not KeepworkServiceSession:IsSignedIn() then
        return
    end
    
    local MainPagePage = Mod.WorldShare.Store:Get("page/MainPage")

    if not MainPagePage then
        return false
    end

    Mod.WorldShare.MsgBox:Show(L"请稍候...", nil, nil, nil, nil, 10)

    self.curSelected = 1
    self.isSearching = false
    self.isClassList = false
    self.isFavorite = true
    self.categorySelected = {}
    MainPagePage:SetValue("search_value", "")

    KeepworkServiceProject:GetMyFavoriteProjects({ page = self.curPage }, function(data, err)
        Mod.WorldShare.MsgBox:Close()

        if not data or
            type(data) ~= 'table' or
            not data.rows or
            type(data.rows) ~= 'table' or
            err ~= 200 then
            return
        end

        local mapData = {}

        -- map data struct
        for key, item in ipairs(data.rows) do
            local isVipWorld = false

            if item.extra and item.extra.isVipWorld == 1 then
                isVipWorld = true
            end

            mapData[#mapData + 1] = {
                id = item.id,
                name = item.extra and type(item.extra.worldTagName) == 'string' and item.extra.worldTagName or item.name or "",
                cover = item.extra and type(item.extra.imageUrl) == 'string' and item.extra.imageUrl or "",
                username = item.user and type(item.user.username) == 'string' and item.user.username or "",
                updated_at = item.updatedAt and type(item.updatedAt) == 'string' and item.updatedAt or "",
                user = item.user and type(item.user) == 'table' and item.user or {},
                isVipWorld = isVipWorld,
                total_view = item.visit,
                total_like = item.star,
                total_mark = item.favorite,
                total_comment = item.comment
            }
        end

        local rows = mapData

        if self.curPage ~= 1 then
            self:HandleWorldsTree(rows, function(rows)
                for key, item in ipairs(rows) do
                    self.worksTree[#self.worksTree + 1] = item
                end

                MainPagePage:GetNode("worksTree"):SetUIAttribute("DataSource", self.worksTree)
            end)
        else
            self:HandleWorldsTree(rows, function(rows)
                self.worksTree = rows

                MainPagePage:GetNode("worksTree"):SetUIAttribute("DataSource", self.worksTree)
            end)
        end
    end)
end

function MainPage:SetWorksTree(categoryItem)
    local MainPagePage = Mod.WorldShare.Store:Get("page/MainPage")

    if not MainPagePage then
        return false
    end

    if not categoryItem or type(categoryItem) ~= 'table' or not categoryItem.id then
        return false
    end

    Mod.WorldShare.MsgBox:Show(L"请稍候...", nil, nil, nil, nil, 10)

    self.curSelected = 1
    self.isSearching = false
    self.isClassList = false
    self.isFavorite = false
    MainPagePage:SetValue("search_value", "")

    if categoryItem.id ~= -1 and categoryItem.id ~= -2 then
        KeepworkServiceProject:GetRecommandProjects(
            categoryItem.id,
            self.mainId,
            { page = self.curPage },
            function(data, err)
                Mod.WorldShare.MsgBox:Close()

                if not data or
                   type(data) ~= 'table' or
                   not data.rows or
                   type(data.rows) ~= 'table' or
                   err ~= 200 then
                    return
                end

                self.categorySelected = categoryItem

                local mapData = {}

                -- map data struct
                for key, item in ipairs(data.rows) do
                    local isVipWorld = false

                    if item.extra and item.extra.isVipWorld == 1 then
                        isVipWorld = true
                    end

                    mapData[#mapData + 1] = {
                        id = item.id,
                        name = item.extra and type(item.extra.worldTagName) == 'string' and item.extra.worldTagName or item.name or "",
                        cover = item.extra and type(item.extra.imageUrl) == 'string' and item.extra.imageUrl or "",
                        username = item.user and type(item.user.username) == 'string' and item.user.username or "",
                        updated_at = item.updatedAt and type(item.updatedAt) == 'string' and item.updatedAt or "",
                        user = item.user and type(item.user) == 'table' and item.user or {},
                        isVipWorld = isVipWorld,
                        total_view = item.visit,
                        total_like = item.star,
                        total_mark = item.favorite
                    }
                end

                local rows = mapData

                if self.curPage ~= 1 then
                    self:HandleWorldsTree(rows, function(rows)
                        for key, item in ipairs(rows) do
                            self.worksTree[#self.worksTree + 1] = item
                        end

                        MainPagePage:GetNode("worksTree"):SetUIAttribute("DataSource", self.worksTree)
                    end)
                else
                    self:HandleWorldsTree(rows, function(rows)
                        self.worksTree = rows

                        MainPagePage:GetNode("worksTree"):SetUIAttribute("DataSource", self.worksTree)
                    end)
                end
            end
        )

        return
    else
        -- hotest and newest
        local sort = ''

        if categoryItem.id == -1 then
            sort = self.sortList.score.key
        elseif categoryItem.id == -2 then
            sort = self.sortList.updatedAt.key
        else
            return
        end
    
        KeepworkEsServiceProject:GetEsProjectsByFilter(
            { 'paracraft专用' },
            sort,
            { page = self.curPage },
            function(data, err)
                if not data or type(data) ~= 'table' or not data.hits or type(data.hits) ~= 'table' or err ~= 200  then
                    return false
                end

                local usernames = {}
    
                for key, item in ipairs(data.hits) do
                    if item and type(item) == 'table' and item.username and type(item.username) == 'string' then
                        local beExisted = false
    
                        for uKey, uItem in ipairs(usernames) do
                            if uItem and type(uItem) == 'string' and uItem == item.username then
                                beExisted = true
                            end
                        end
    
                        if not beExisted then
                            usernames[#usernames + 1] = item.username
                        end
                    end
                end

                KeepworkServiceSession:GetUsersByUsernames(usernames, function(usersData, usersErr)
                    if not usersData or type(usersData) ~= 'table' or not usersData.rows or type(usersData.rows) ~= 'table' or err ~= 200  then
                        return false
                    end
                    
                    self.categorySelected = categoryItem
        
                    for key, item in pairs(data.hits) do
                        if item and type(item) == 'table' then
                            for uKey, uItem in ipairs(usersData.rows) do
                                if uItem and type(uItem) == 'table' then
                                    if uItem.username == item.username then
                                        item.user = commonlib.copy(uItem)
                                    end
                                end
                            end
    
                            if item.world_tag_name then
                                item.name = item.world_tag_name
                            end
                        end
                    end

                    local rows = data.hits
        
                    if self.curPage ~= 1 then
                        self:HandleWorldsTree(rows, function(rows)
                            for key, item in ipairs(rows) do
                                self.worksTree[#self.worksTree + 1] = item
                            end
    
                            MainPagePage:GetNode("worksTree"):SetUIAttribute("DataSource", self.worksTree)
                            Mod.WorldShare.MsgBox:Close()
                        end)
                    else
                        self:HandleWorldsTree(rows, function(rows)
                            self.worksTree = rows
    
                            MainPagePage:GetNode("worksTree"):SetUIAttribute("DataSource", self.worksTree)
                            Mod.WorldShare.MsgBox:Close()
                        end)
                    end
                end)
            end
        )
    end
end

function MainPage:Search()
    local MainPagePage = Mod.WorldShare.Store:Get("page/MainPage")

    if not MainPagePage then
        return false
    end

    if not self.isSearching then
        self.curSelected = 1
        self.isSearching = true
        self.searchValue = MainPagePage:GetValue("search_value")
    end

    local searchValue = self.searchValue

    if not searchValue or (type(searchValue) ~= 'string' and type(searchValue) ~= 'number') then
        return false
    end

    KeepworkEsServiceProject:Search(searchValue, { page = self.curPage }, function(data, err)
        if not data or not data.hits then
            return false
        end

        Mod.WorldShare.Store:Set('explorer/selectSortIndex', 1)
        self.categorySelected = {}
        
        if self.curPage ~= 1 then
            self:HandleWorldsTree(data.hits, function(rows)
                for key, item in ipairs(rows) do
                    self.worksTree[#self.worksTree + 1] = item
                end

                MainPagePage:GetNode("worksTree"):SetAttribute("DataSource", self.worksTree)
                MainPagePage:SetValue("search_value", searchValue)

                self:Refresh()
            end)
        else
            self:HandleWorldsTree(data.hits, function(rows)
                self.worksTree = rows

                MainPagePage:GetNode("worksTree"):SetAttribute("DataSource", self.worksTree)
                MainPagePage:SetValue("search_value", searchValue)

                self:Refresh()
            end)
        end
    end)
end

function MainPage:HandleWorldsTree(rows, callback)
    if not rows or type(rows) ~= "table" then
        return false
    end

    local projectIds = {}

    for key, item in ipairs(rows) do
        if ProjectsDatabase:IsProjectDownloaded(item.id) then
            item.downloaded = true
        else
            item.downloaded = false
        end

        item.isFavorite = false
        item.isStar = false

        projectIds[#projectIds + 1] = item.id
    end

    if KeepworkServiceSession:IsSignedIn() then
        keepwork.project.favorite_search({
            objectType = 5,
            objectId = {
                ["$in"] = projectIds,
            }, 
            userId = Mod.WorldShare.Store:Get('user/userId'),
        }, function(status, msg, data)
            if data and
               type(data) == 'table' and
               data.rows and
               type(data.rows) == 'table' and
               #data.rows ~= 0 then
                for key, item in ipairs(rows) do
                    for dKey, dItem in ipairs(data.rows) do
                        if tonumber(item.id) == tonumber(dItem.objectId) then
                            item.isFavorite = true
                        end
                    end
                end
            end

            WorldShareKeepworkServiceProject:GetStaredProjects(projectIds, function(data, err)
                for key, item in ipairs(rows) do
                    for dKey, dItem in ipairs(data.rows) do
                        if tonumber(item.id) == tonumber(dItem.projectId) then
                            item.isStar = true
                        end
                    end
                end

                if callback and type(callback) == 'function' then
                    callback(rows)
                end
            end)
        end)
    else
        if callback and type(callback) == 'function' then
            callback(rows)
        end
    end
end

function MainPage:DownloadWorld(index)
    Toast:ShowPage(L"开始下载")
    local curItem = self.worksTree[index]

    if not curItem or not curItem.id then
        return false
    end

    KeepworkServiceProject:GetProjectDetailById(
        curItem.id,
        function(data, err)
            if not data or not data.world or not data.world.archiveUrl or err ~= 200 then
                Toast:ShowPage(L"网络不太稳定")
                return false
            end

            local archiveUrl = data.world.archiveUrl
            local downloadFileName = string.match(archiveUrl, "(.+)%.zip")

            if type(downloadFileName) ~= 'string' then
                Toast:ShowPage(L"数据错误")
                return false
            end

            downloadFileName = format(LocalLoadWorld.GetWorldFolder() .. "/userworlds/%s_r.zip", downloadFileName:gsub("[%W%s]+", "_"))

            DownloadWorld.ShowPage(
                format("【%s%d】 %s %s%s", L"项目ID:", curItem.id, curItem.name, L"作者：", curItem.username)
            )
            FileDownloader:new():Init(
                "official_texture_package",
                archiveUrl,
                downloadFileName,
                function(bSuccess, downloadPath)
                    if bSuccess then
                        Toast:ShowPage(L"下载成功")
                        ProjectsDatabase:SetDownloadedProject(data)
                        self:SelectProject(index)
                    else
                        Toast:ShowPage(L"文件下载失败，请确认世界是否存在")
                    end

                    DownloadWorld.Close()
                end,
                "access plus 5 mins",
                true
            )
        end,
        0
    )
end

function MainPage:SetFavorite(index)
    local curItem = self.worksTree[index]

    if not curItem or not curItem.id then
        return false
    end

    if not ProjectsDatabase:IsFavoriteProject(curItem.id) then
        Toast:ShowPage(L"收藏成功")
        ProjectsDatabase:SetFavoriteProject(curItem.id)
    else
        Toast:ShowPage(L"取消收藏")
        ProjectsDatabase:RemoveFavoriteProject(curItem.id)
    end

    self:HandleWorldsTree(self.worksTree, function()
        self:Refresh()
    end)
end

function MainPage:SetCoins()
    Password:ShowPage()
end

function MainPage:CheckoutNewVersion(worldInfo, callback)
    if not worldInfo or
       not worldInfo.archiveUrl or
       not worldInfo.revision or
       not worldInfo.projectId then
        return false
    end

    local function Handle(data)
        if not data or not data.world or not data.world.revision then
            return false
        end

        if type(callback) ~= 'function' then
            return false
        end

        local remoteRevision = tonumber(data.world.revision)
        local localRevision = tonumber(worldInfo.revision)

        if remoteRevision > localRevision then
            callback(true)
        else
            callback(false)
        end
    end

    KeepworkServiceProject:GetProjectDetailById(worldInfo.projectId, Handle)
end

function MainPage:SelectProject(index)
    self.curProjectIndex = index

    local curItem = self.worksTree[index]

    if not curItem or not curItem.id then
        return false
    end

    if not ProjectsDatabase:IsProjectDownloaded(curItem.id) then
        self:DownloadWorld(index)
        return false
    end

    local projectInfo = ProjectsDatabase:GetDownloadedProject(curItem.id)

    if not projectInfo or not projectInfo.world then
        return false
    end

    local function Handle(result)
        if result then
            _guihelper.MessageBox(L"发现新版本，重新下载世界")
            self:DownloadWorld(index)
            return false
        end

        local function Handle()
            local world = RemoteWorld.LoadFromHref(projectInfo.world.archiveUrl, "self")
            world:GetLocalFileName()

            Mod.WorldShare.Store:Set('world/currentRemoteFile', projectInfo.world.archiveUrl)

            local mytimer =
                commonlib.Timer:new(
                {
                    callbackFunc = function(timer)
                        -- add rice
                        KeepworkServiceSession:AddRice('explorer')

                        InternetLoadWorld.LoadWorld(
                            world,
                            nil,
                            "never",
                            function(bSucceed, localWorldPath)
                                if bSucceed then
                                    -- if not Mod.WorldShare.Store:Get("world/personalMode") then
                                    --     self.playerBalance = self.playerBalance - 1
                                    --     self.balance = self.balance - 1
                                    --     Wallet:SetPlayerBalance(self.playerBalance)
                                    --     Wallet:SetUserBalance(self.balance)
                                    --     Mod.WorldShare.Store:Remove("explorer/reduceRemainingTime")
                                    --     Mod.WorldShare.Store:Remove("explorer/warnReduceRemainingTime")
                                    --     self:HandleGameProcess()
                                    -- end

                                    MainPage:Close()
                                end
                            end
                        )
                    end
                }
            )

            -- prevent recursive calls.
            mytimer:Change(2, nil)
            Mod.WorldShare.Store:Set("explorer/mode", "recommend")
        end
    
        local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')
    
        if currentEnterWorld then
            Mod.WorldShare.MsgBox:Show(L"请稍候...")
            WorldShareKeepworkServiceProject:GetProject(curItem.id, function(data, err)
                Mod.WorldShare.MsgBox:Close()
                if err ~= 200 or not data or type(data) ~='table' or not data.name then
                    GameLogic.AddBBS(nil, L"无法找到该资源", 300, '255 0 0')
                    return
                end

                _guihelper.MessageBox(
                    format(L"即将离开【%s】进入【%s】", currentEnterWorld.text, data.name),
                    function(res)
                        if res and res == _guihelper.DialogResult.Yes then
                            Handle()
                        end
                    end,
                    _guihelper.MessageBoxButtons.YesNo
                )
            end)
        end
    end

    self:CheckoutNewVersion(projectInfo.world, Handle)
end

function MainPage:HandleGameProcess()
    if not Mod.WorldShare.Store:Get("explorer/warnReduceRemainingTime") then
        Mod.WorldShare.Store:Set("explorer/warnReduceRemainingTime", (1000 * 60 * 10) - (60 * 1000))
    end

    if not Mod.WorldShare.Store:Get("explorer/reduceRemainingTime") then
        Mod.WorldShare.Store:Set("explorer/reduceRemainingTime", 1000 * 60 * 10)
    end

    Mod.WorldShare.Utils.SetTimeOut(
        function()
            local reduceRemainingTime = Mod.WorldShare.Store:Get("explorer/reduceRemainingTime")
            local warnReduceRemainingTime = Mod.WorldShare.Store:Get("explorer/warnReduceRemainingTime")

            if warnReduceRemainingTime == 1000 then
                if self.playerBalance > 0 then
                    Toast:ShowPage(L"即将消耗一个金币")
                end

                Mod.WorldShare.Store:Set("explorer/warnReduceRemainingTime", warnReduceRemainingTime - 1000)
            elseif warnReduceRemainingTime > 0 then
                Mod.WorldShare.Store:Set("explorer/warnReduceRemainingTime", warnReduceRemainingTime - 1000)
            end

            if reduceRemainingTime == 1000 then
                if self.playerBalance > 0 then
                    Toast:ShowPage(L"消耗一个金币")
                    self.playerBalance = self.playerBalance - 1
                    self.balance = self.balance - 1
                    Wallet:SetPlayerBalance(self.playerBalance)
                    Wallet:SetUserBalance(self.balance)

                    Mod.WorldShare.Store:Set("explorer/reduceRemainingTime", reduceRemainingTime - 1000)
                    Mod.WorldShare.Store:Remove("explorer/reduceRemainingTime")
                    Mod.WorldShare.Store:Remove("explorer/warnReduceRemainingTime")
                    self:HandleGameProcess()
                else
                    TimeUp:ShowPage()
                end
            elseif reduceRemainingTime > 0 then
                Mod.WorldShare.Store:Set("explorer/reduceRemainingTime", reduceRemainingTime - 1000)
                self:HandleGameProcess()
            end
        end,
        1000
    )
end

function MainPage:SelectDownloadedCategory(value)
    local MainPagePage = Mod.WorldShare.Store:Get("page/MainPage")

    if not MainPagePage or not value then
        return false
    end

    self.curPage = 1
    self.downloadedGame = value
    self:SetWorksTree(self.categorySelected, Mod.WorldShare.Store:Getter('explorer/GetSortKey'))
end

function MainPage:GetSortIndex()
    return Mod.WorldShare.Store:Get("explorer/selectSortIndex")
end

function MainPage:GetSortList()
    return Mod.WorldShare.Store:Get("explorer/sortList")
end

function MainPage:OnWorldLoad()
    local personalMode = Mod.WorldShare.Store:Get("world/personalMode")

    if not personalMode then
        Mod.WorldShare.Utils.SetTimeOut(
            function()
                Toast:ShowPage(L"消耗一个金币")
            end,
            1000
        )
    end
end

function MainPage:CanGoBack()
    local canGoBack = Mod.WorldShare.Store:Get("explorer/canGoBack")

    if canGoBack == false then
        return false
    end

    MainPage:Close()
end

function MainPage:OpenProject(id)
    if type(id) ~= "number" then
        return false
    end

    ParaGlobal.ShellExecute("open", format("%s/pbl/project/%d/", KeepworkService:GetKeepworkUrl(), id), "", "", 1)
end

function MainPage:GetPage()
    return Mod.WorldShare.Store:Get("page/MainPage")
end

function MainPage:IsEnglish()
    if Translation.GetCurrentLanguage() == 'enUS' then
        return true
    else
        return false
    end
end
