xpCutter = {};

xpCutter.debug = false --true --

-- Prevent combine threshing to start when starting the cutter if turnedOnByAttacherVehicle is true
function xpCutter:onLoad(superFunc, savegame)
    if xpCutter.debug then print("xpCutter:onLoad") end
    superFunc(self, savegame)
    local spec = self.spec_turnOnVehicle
    if spec then
        spec.turnedOnByAttacherVehicle = false
    end
end
Cutter.onLoad = Utils.overwrittenFunction(Cutter.onLoad, xpCutter.onLoad)

-- Store multiplier to compute yield depending on threshed area
function xpCutter:onEndWorkAreaProcessing(superFunc, dt, hasProcessed)
    -- if xpCutter.debug then print("xpCutter:onEndWorkAreaProcessing") end
    superFunc(self, dt, hasProcessed)
    if self.isServer then
        local spec = self.spec_cutter
		local lastArea = spec.workAreaParameters.lastArea
        local lastMultiplierArea = spec.workAreaParameters.lastMultiplierArea -- * 0.1
		local lastLiters = 0
        if spec.workAreaParameters.combineVehicle ~= nil then
            lastLiters = spec.workAreaParameters.combineVehicle[("spec_%s.xpCombine"):format(xpCombine.modName)].lastLiters
        end
        if spec.workAreaParameters.combineVehicle then
            local spec_xpCombine = spec.workAreaParameters.combineVehicle.spec_xpCombine
            if lastArea > 0 then
                spec_xpCombine.lastLiters = lastLiters
                spec_xpCombine.lastArea = lastArea
                spec_xpCombine.lastMultiplier = lastMultiplierArea / lastArea
            else
                spec_xpCombine.lastRealArea = 0
                spec_xpCombine.lastMultiplier = 0
                spec_xpCombine.lastArea = 0
                spec_xpCombine.lastLiters = 0
            end
        end
    end
end
Cutter.onEndWorkAreaProcessing = Utils.overwrittenFunction(Cutter.onEndWorkAreaProcessing, xpCutter.onEndWorkAreaProcessing)
