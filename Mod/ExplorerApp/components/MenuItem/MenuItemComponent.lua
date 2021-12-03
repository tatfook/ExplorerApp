--[[
Title: Menu Item Component
Author(s): big
CreateDate: 2021.12.2
Desc:
Place: Foshan
use the lib:
------------------------------------------------------------
local MenuItemComponent = NPL.load('(gl)Mod/ExplorerApp/components/MenuItem/MenuItemComponent.lua')
------------------------------------------------------------
]]

-- pages
local MainPage = NPL.load('(gl)Mod/ExplorerApp/pages/MainPage.lua')

local MenuItemComponent = NPL.export()

local self = MenuItemComponent

local selectedItem = commonlib.Array:new()

function MenuItemComponent.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
    self.width = width
    self.height = height
    self.parentLayout = parentLayout
    self.level = mcmlNode:GetAttributeWithCode('level')
    self.index = mcmlNode:GetAttributeWithCode('index')

    return mcmlNode:DrawDisplayBlock(
            rootName,
            bindingContext,
            _parent,
            left,
            top,
            width,
            height,
            parentLayout,
            style,
            self.RenderCallback
           )
end

function MenuItemComponent.RenderCallback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
    if self.level and self.level > 1 then
        local button = ParaUI.CreateUIObject(
                        'button',
                        'testtest',
                        '_rt',
                        -35,
                        16,
                        14,
                        8)
    
        button.background = 'Texture/Aries/Creator/keepwork/rank/btn_qiehuan2_14X8_32bits.png#0 0 14 8'
        button.zorder = 1

        if self:IsSelectedItem(self.index) then
            button.rotation = 3.14
        end

        local curIndex = self.index

        button:SetScript('onclick', function()
            if self:IsSelectedItem(curIndex) then
                for key, item in ipairs(selectedItem) do
                    if item == curIndex then
                        selectedItem:remove(key)
                        break
                    end
                end
            else
                selectedItem:push_back(curIndex)
            end

            mcmlNode:GetPageCtrl():Refresh(0.01)
        end)

        _parent:AddChild(button)
    end

    local xmlRoot

    if not self.xmlRoot then
        self.xmlRoot = ParaXML.LuaXML_ParseFile('Mod/ExplorerApp/components/MenuItem/MenuItemComponent.html')
        xmlRoot = commonlib.copy(self.xmlRoot)
    else
        xmlRoot = commonlib.copy(self.xmlRoot)
    end

    if self.level and self.level > 1 then
        if self:IsSelectedItem(self.index) then
            local children = MainPage.categoryTree[self.index].children or {}
            local childrenItems = {}

            for key, item in ipairs(children) do
                childrenItems[key] = {
                    {
                        attr = {
                            type = 'button',
                            onclick = 'select_category_by_id()',
                            name = item.id,
                            value = item.tagname,
                            align = 'center',
                            width = '100%',
                            style = 'background: url(Texture/Aries/Creator/keepwork/RedSummerCamp/works/works_32bits.png#205 112 86 46:10 10 10 10);\
                                     height: 35px;',
                        },
                        name = 'input'
                    },
                    attr = {
                        style = 'margin-top: 3px;\
                                 margin-bottom: -3px;'
                    },
                    name = 'div'
                }
            end

            local containerHeight = #children * 35 + 10

            xmlRoot[1][1][#xmlRoot[1][1] + 1] = {
                [1] = childrenItems,
                attr = {
                    style='height: ' .. containerHeight .. 'px;\
                           width: 140px;\
                           margin-left: 4px;\
                           margin-top: -1px;\
                           margin-bottom: 8px;\
                           background-color: #B7B7B7;'
                },
                name='div'
            }
        end
    end

    local buildClassXmlRoot = Map3DSystem.mcml.buildclass(xmlRoot)    
    local MenuItemComponentMcmlNode = commonlib.XPath.selectNode(buildClassXmlRoot, '//pe:mcml')
    MenuItemComponentMcmlNode:SetAttribute('page_ctrl', mcmlNode:GetPageCtrl())

    local ParacraftWorld = Map3DSystem.mcml_controls.create(
        'menu_item',
        MenuItemComponentMcmlNode,
        nil,
        _parent,
        0,
        0,
        self.width,
        self.height,
        nil,
        self.parentLayout
    )
end

function MenuItemComponent:IsSelectedItem(index)
    for key, item in ipairs(selectedItem) do
        if item == index then
            return true
        end
    end

    return false
end

function MenuItemComponent:ClearAllSelectedItems()

end

