local fileParams = {...}

local fileParamX = tonumber(fileParams[1])
local fileParamY = tonumber(fileParams[2])
local fileParamZ = tonumber(fileParams[3])

if fileParamX == nil or fileParamY == nil or fileParamZ == nil then
    print("ERROR: Your start coordinates are invalid.\nProper usage: quarry {startX} {startY} {startZ} {facing}")
    return
end
local currentLocation = vector.new(fileParamX, fileParamY, fileParamZ)

local facingDirection = fileParams[4]
if facingDirection ~= "n" and facingDirection ~= "e" and facingDirection ~= "s" and facingDirection ~= "w" then
    print("ERROR: Your facing direction is invalid. Try n, e, s, or w.\nProper usage: quarry {startX} {startY} {startZ} {facing}")
    return
end

local turningRight = true
local currentState = "minequarry"

local homeLocation = vector.new(2, 106, 413)
local chestLocation = vector.new(1, 105, 412)

local currentMiningData = {
    location = vector.new(0,0,0),
    direction = "n",
    turningRight = true,
    rows = 1, -- Rows
    blocksInRow = 1 -- Blocks in row
}
local miningSafeYPadding = 4

local orienMoveModifications = {
    up = function()
        currentLocation.y = currentLocation.y + 1
    end,
    down = function()
        currentLocation.y = currentLocation.y - 1
    end,
    -- -Z
    n = function()
        currentLocation.z = currentLocation.z - 1
    end,
    -- +X
    e = function()
        currentLocation.x = currentLocation.x + 1
    end,
    -- +Z
    s = function()
        currentLocation.z = currentLocation.z + 1
    end,
    -- -X
    w = function()
        currentLocation.x = currentLocation.x - 1
    end
}
local function doMove(orien)
    if orien == nil then
        local _, blockDataForward = turtle.inspect()
        if blockDataForward.name ~= "computercraft:turtle" and blockDataForward.name ~= "computercraft:turtle_advanced" then
            turtle.dig()
            turtle.forward()
            orienMoveModifications[facingDirection]()
        end
    elseif turtle[orien] ~= nil then
        local funcName = orien:sub(1, 1):upper() .. orien:sub(2)

        local _, blockDataOrien = turtle["inspect" .. funcName]
        if blockDataOrien.name ~= "computercraft:turtle" and blockDataOrien.name ~= "computercraft:turtle_advanced" then
            turtle["dig" .. funcName]()
            turtle[orien]()
            orienMoveModifications[orien]()
        end
    end
end

local turnDirectionNums = {
    n = 1,
    e = 2,
    s = 3,
    w = 4
}
local numDirectionTurns = {
    [1] = "n",
    [2] = "e",
    [3] = "s",
    [4] = "w"
}
local function doTurn()
    local modMult = 1

    if turningRight == false then
        modMult = -1
        turtle.turnLeft()
    else
        turtle.turnRight()
    end

    local nextNum = turnDirectionNums[facingDirection] + (1 * modMult)
    if nextNum > 4 then nextNum = 1 elseif nextNum < 1 then nextNum = 4 end

    facingDirection = numDirectionTurns[nextNum]
end

local function doTurnTowards(orien)
    while facingDirection ~= orien do
        doTurn()
    end
end

local function getBlocksFromLocation(location)
    local diff = currentLocation - location
    return math.abs(diff.x), math.abs(diff.y), math.abs(diff.z)
end

local function goToLocation(location, isUpwards)
    -- Move downwards
    if isUpwards == false then
        while currentLocation.y > location.y do
            doMove("down")
        end
    end

    -- Move towards X
    if currentLocation.x < location.x then
        doTurnTowards("e")
    else
        doTurnTowards("w")
    end
    while currentLocation.x ~= location.x do
        doMove()
    end

    -- Move towards Z
    if currentLocation.z < location.z then
        doTurnTowards("s")
    else
        doTurnTowards("n")
    end
    while currentLocation.z ~= location.z do
        doMove()
    end

    -- Move upwards
    if isUpwards == true then
        while currentLocation.y < location.y do
            doMove("up")
        end
    end
end

local function pullFromRefuel()
    -- TODO
end

local function dumpIntoChestAbove()
    for i=1, 16 do
        turtle.select(i)
        turtle.refuel()
        turtle.dropUp()
    end
    turtle.select(1)
end

local function checkFuelAndInventoryWhileMining()
    local botHadToGo = false

    -- Check if going to die
    local distX, distY, distZ = getBlocksFromLocation(homeLocation)
    if turtle.getFuelLevel() < 300 + distX + distY + distZ then
        botHadToGo = true
        goToLocation(homeLocation, true)
        pullFromRefuel()
        -- Give some space before next movement
        for i=1, miningSafeYPadding do doMove("down") end
    end

    -- Check if inventory is full
    if turtle.getItemDetail(16) ~= nil then
        botHadToGo = true
        goToLocation(chestLocation, true)
        dumpIntoChestAbove()
        -- Give some space before next movement
        for i=1, miningSafeYPadding do doMove("down") end
    end

    return botHadToGo
end

local function saveCurrentMiningData(x, y)
    currentMiningData.location.x, currentMiningData.location.y, currentMiningData.location.z = currentLocation.x, currentLocation.y, currentLocation.z
    currentMiningData.direction = facingDirection
    currentMiningData.turningRight = turningRight
    currentMiningData.rows = x
    currentMiningData.blocksInRow = y

    -- Check fuel and inventory, and if needed; get back to it
    if checkFuelAndInventoryWhileMining() then
        goToLocation(currentMiningData.location, false)
        doTurnTowards(currentMiningData.direction)
        turningRight = currentMiningData.turningRight
        return true
    end
    return false
end

local states = {
    minequarry = function()
        local _, blockDataDown = turtle.inspectDown()
        if currentLocation.y > math.min(homeLocation.y, chestLocation.y) - miningSafeYPadding then
            print("ERROR: Current location is UNSAFE for mining quarry. Aborting.")
            currentState = "idle"
            return
        elseif currentLocation.y <= -60 or (currentLocation.y == 59 and blockDataDown.name == "minecraft:bedrock") then
            print("Bedrock level reached. Going home.")
            goToLocation(homeLocation)
            currentState = "idle"
            return
        end

        -- This mines a layer 16x16
        for x=currentMiningData.rows,16 do
            for y=currentMiningData.blocksInRow,15 do
                doMove()

                -- Set current mining location to return to
                if saveCurrentMiningData(x, y+1) then return end
            end
        
            doTurn()
        
            if x ~= 16 then
                doMove()
            end
        
            doTurn()
        
            if x ~= 16 then
                turningRight = not turningRight

                -- Set current mining location to return to
                if saveCurrentMiningData(x+1, 1) then return end
            else
                doMove("down")
            end
        end

        -- Set current mining location to return to
        if saveCurrentMiningData(1, 1) then return end
    end,
    idle = function()
        sleep(1)
    end
}

while true do
    states[currentState]()
end