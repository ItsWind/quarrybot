local params = {...}
local currentLocation = vector.new(tonumber(params[1]), tonumber(params[2]), tonumber(params[3]))
local facingDirection = params[4]
local turningRight = true
local currentState = "minequarry"

local homeLocation = vector.new(2, 106, 413)
local chestLocation = vector.new(1, 105, 412)
local currentMiningLocation = vector.new(0, 0, 0)
local currentMiningDirection = "n"

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
        turtle.forward()
        orienMoveModifications[facingDirection]()
    elseif turtle[orien] ~= nil then
        turtle[orien]()
        orienMoveModifications[orien]()
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
    if turningRight then
        turtle.turnRight()
        local nextNum = turnDirectionNums[facingDirection] + 1
        if nextNum > 4 then nextNum = 1 end
        facingDirection = numDirectionTurns[nextNum]
    else
        turtle.turnLeft()
        local nextNum = turnDirectionNums[facingDirection] - 1
        if nextNum < 1 then nextNum = 4 end
        facingDirection = numDirectionTurns[nextNum]
    end
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
    local toMove = vector.new(getBlocksFromLocation(location))

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
end

local states = {
    minequarry = function()
        -- Set current mining location to return to
        currentMiningLocation.x, currentMiningLocation.y, currentMiningLocation.z = currentLocation.x, currentLocation.y, currentLocation.z
        currentMiningDirection = facingDirection

        -- This mines a layer 16x16
        for x=1,16,1 do
            for y=1,15,1 do
                turtle.dig()
                turtle.forward()
            end
        
            doTurn()
        
            if x ~= 16 then
                turtle.dig()
                turtle.forward()
            end
        
            doTurn()
        
            if x ~= 16 then
                turningRight = not turningRight
            else
                turtle.digDown()
                turtle.down()
            end
        end

        local botHadToGo = false

        -- Check if going to die
        local distX, distY, distZ = getBlocksFromLocation(homeLocation)
        if turtle.getFuelLevel() < 300 + distX + distY + distZ then
            botHadToGo = true
            goToLocation(homeLocation, true)
            pullFromRefuel()
            -- Give some space before next movement
            for i=1, 4 do doMove("down") end
        end

        -- Check if inventory is full
        if turtle.getItemDetail(16) ~= nil then
            botHadToGo = true
            goToLocation(chestLocation, true)
            dumpIntoChestAbove()
            -- Give some space before next movement
            for i=1, 4 do doMove("down") end
        end

        -- Back to it
        if botHadToGo == true then
            goToLocation(currentMiningLocation, false)
            doTurnTowards(currentMiningDirection)
        end
    end
}

while true do
    states[currentState]()
end