
---@class CombineSettings
CombineSettings = {}

CombineSettings.name = g_currentModName
local modSettingsDir = g_modSettingsDirectory
CombineSettings.debug = false --true --
local xpCombineSettings_mt = Class(CombineSettings)

---Creates a new instance of the CombineSettings.
---@return CombineSettings
function CombineSettings:new(modTitle)
    if CombineSettings.debug then print("CombineSettings:new") end
    local instance = setmetatable({}, xpCombineSettings_mt)

    CombineSettings.modTitle = modTitle

    return instance
end

function CombineSettings:delete()
    if CombineSettings.debug then print("CombineSettings:delete") end
    if self.main ~= nil then
        self.main:delete()
    end
end

function CombineSettings:load()
    if CombineSettings.debug then print("CombineSettings:load") end

    -- SaveSettings
    FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, CombineSettings.saveSettings)
end

function CombineSettings:initGameSettingsGui()
    if CombineSettings.debug then print("CombineSettings:initGameSettingsGui") end
    if self.combineGameplay == nil then

        -- Validate required GUI elements exist
        if self.gameSettingsLayout == nil then
            return
        end

        if self.economicDifficulty == nil then
            return
        end

        if self.checkTraffic == nil then
            return
        end

        -- Section Header
        local numElements = #self.gameSettingsLayout.elements
        local headerIndex = math.min(7, numElements)
        if headerIndex < 1 then
            return
        end
        local title = self.gameSettingsLayout.elements[headerIndex]:clone()
        title:applyProfile("fs25_settingsSectionHeader", true)
        title:setText(CombineSettings.modTitle)
        title.focusChangeData={}
        title.focusId = FocusManager.serveAutoFocusId()

        self.gameSettingsLayout:addElement(title)

        local target = g_combinexp

        --- Create Gameplay Element
        local settingsCloneIndex = math.min(5, numElements)

        local optionClone = self.economicDifficulty:clone()
        optionClone.target = target
        optionClone.onClickCallback = CombineSettings.onSettingsStateChanged
        optionClone.buttonLRChange = CombineSettings.onSettingsStateChanged
        optionClone.texts[1] = CombineSettings:getText("gameplayArcade")
        optionClone.texts[2] = CombineSettings:getText("gameplayNormal")
        optionClone.texts[3] = CombineSettings:getText("gameplayRealistic")

        self.combineGameplay = optionClone:clone()
        CombineSettings:addOptionToLayout(
            self.gameSettingsLayout,
            self.combineGameplay,
            "combineGameplay",
            "combineGameplaySetting",
            self.gameSettingsLayout.elements[settingsCloneIndex]
        )
        local gameplay = 1
        if g_combinexp.powerBoost == xpCombine.powerBoostNormal then
            gameplay = 2
        elseif g_combinexp.powerBoost == xpCombine.powerBoostRealistic then
            gameplay = 3
        end
        self.combineGameplay:setState(gameplay)

        --- Create PowerSetting Element
        optionClone = self.checkTraffic:clone()
        optionClone.target = target
        optionClone.onClickCallback = CombineSettings.onSettingsStateChanged
        optionClone.buttonLRChange = CombineSettings.onSettingsStateChanged
        optionClone.texts[1] = g_i18n:getText("ui_off")
        optionClone.texts[2] = g_i18n:getText("ui_on")
        self.combinePower = optionClone:clone()
        CombineSettings:addOptionToLayout(
            self.gameSettingsLayout,
            self.combinePower,
            "combinePower",
            "combinePowerSetting",
            self.gameSettingsLayout.elements[settingsCloneIndex]
        )
        self.combinePower:setIsChecked(g_combinexp.powerDependantSpeed.isActive, true)
        self.combinePower:updateSelection() -- Required to prevent GUI misbehavior when initialized to true

        --- Create Daytime Setting Element
        optionClone = self.checkTraffic:clone()
        optionClone.target = target
        optionClone.onClickCallback = CombineSettings.onSettingsStateChanged
        optionClone.buttonLRChange = CombineSettings.onSettingsStateChanged
        optionClone.texts[1] = g_i18n:getText("ui_off")
        optionClone.texts[2] = g_i18n:getText("ui_on")
        self.combineDaytime = optionClone:clone()
        CombineSettings:addOptionToLayout(
            self.gameSettingsLayout,
            self.combineDaytime,
            "combineDaytime",
            "combineDaytimeSetting",
            self.gameSettingsLayout.elements[settingsCloneIndex]
        )
        self.combineDaytime:setIsChecked(g_combinexp.timeDependantSpeed.isActive, true)
        self.combineDaytime:updateSelection() -- Required to prevent GUI misbehavior when initialized to true

        self.gameSettingsLayout:invalidateLayout()
    end
end

function CombineSettings:saveSettings()
    if CombineSettings.debug then print("CombineSettings:saveSettings") end
    -- First load from data xmlFile
    if xpCombine.myCurrentModDirectory then
        local xmlFile = nil
        if xpCombine.myCurrentModDirectory then
            local xmlFilePath = modSettingsDir.."combineXP.xml"
            if fileExists(xmlFilePath) then
                xmlFile = XMLFile.load("combineXP", xmlFilePath);
            else
                print("Error: Cannot save settings to "..xmlFilePath)
            end
            xmlFile:setInt("combineXP.vehicles"..string.format("#powerBoost"), g_combinexp.powerBoost)
            xmlFile:setBool("combineXP.powerDependantSpeed" .. string.format("#isActive"), g_combinexp.powerDependantSpeed.isActive)
            xmlFile:setBool("combineXP.timeDependantSpeed" .. string.format("#isActive"), g_combinexp.timeDependantSpeed.isActive)
            xmlFile:save()
        end
    end
end

function CombineSettings:onSettingsStateChanged(state, element, isChangedUp)
    if CombineSettings.debug then print("CombineSettings:onSettingsStateChanged") end

    if element.id == "combineGameplay" then
        if CombineSettings.debug then print("Gameplay state: " .. tostring(state)) end
        if state == 1 then
            g_combinexp.powerBoost = xpCombine.powerBoostArcade
        elseif state == 2 then
            g_combinexp.powerBoost = xpCombine.powerBoostNormal
        elseif state == 3 then
            g_combinexp.powerBoost = xpCombine.powerBoostRealistic
        end
    end
    if element.id == "combinePower" then
        if CombineSettings.debug then print("Power state: " .. tostring(state)) end
        g_combinexp.powerDependantSpeed.isActive = element:getIsChecked()
    end
    if element.id == "combineDaytime" then
        if CombineSettings.debug then print("Daytime state: " .. tostring(state)) end
        g_combinexp.timeDependantSpeed.isActive = element:getIsChecked()
    end
    g_client:getServerConnection():sendEvent(xpCombineEvent.new(g_combinexp.powerBoost, g_combinexp.powerDependantSpeed.isActive, g_combinexp.timeDependantSpeed.isActive))
end


function CombineSettings:addOptionToLayout(gameSettingsLayout, cloneElement, id, textId, settingsClone)
    cloneElement.id = id

    local toolTip = cloneElement.elements[1]

    toolTip.text = CombineSettings:getText(string.gsub(textId, "Setting", "Tooltip"))
    toolTip.sourceText = CombineSettings:getText(string.gsub(textId, "Setting", "Tooltip"))

    local optionTitle = settingsClone.elements[2]:clone()
    optionTitle.id = id.."Title"
    optionTitle:applyProfile("fs25_settingsMultiTextOptionTitle", true)
    optionTitle:setText(CombineSettings:getText(textId))

    local optionContainer = settingsClone:clone()
    optionContainer.id = id.."Container"

    optionContainer:applyProfile("fs25_multiTextOptionContainer", true)
    for key, v in pairs(optionContainer.elements) do
        optionContainer.elements[key] = nil
    end

    optionContainer:addElement(optionTitle)
    optionContainer:addElement(cloneElement)
    gameSettingsLayout:addElement(optionContainer)
end

function CombineSettings:getText(key)
    return g_i18n.modEnvironments[CombineSettings.name].texts[key]
end

-- Hook at source time (before other mods can overwrite onFrameOpen during mission load)
InGameMenuSettingsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuSettingsFrame.onFrameOpen, CombineSettings.initGameSettingsGui)
