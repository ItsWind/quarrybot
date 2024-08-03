local params = {...}
local currentLocation = vector3.new(tonumber(params[1]), tonumber(params[2]), tonumber(params[3]))
local facingDirection = params[4]
local turningRight = true
local currentState = "minequarry"

local homeLocation = vector3.new(2, 413, 106)
local chestLocation = vector3.new(1, 412, 105)

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
    1 = n,
    2 = e,
    3 = s,
    4 = w
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

local function getBlocksFromHome()
    --local currentLocation = vector3.new(gps.locate(5))
    local diff = currentLocation - homeLocation
    return math.abs(diff.x) + math.abs(diff.y) + math.abs(diff.z)
end

local states = {
    minequarry = function() {
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
    }
}

--while true do
    --states[currentState]()
--end

print(currentLocation)

doMove()
doMove("up")
doTurn()
doMove()
doMove()
doMove("up")
doMove()
doTurn()
doMove()
doMove("down")

print(currentLocation)