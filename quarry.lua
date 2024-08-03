local turningRight = true

local function doTurn()
    if turningRight then
        turtle.turnRight()
    else
        turtle.turnLeft()
    end
end

local function doLoop()
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
            doLoop()
        end
    end
end
doLoop()