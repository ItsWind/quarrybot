local CryptoNet = require("cryptoNet")

local sendSocket = nil

function inputLoop()
    print("Send message: ")
    local toSend = io.read()
    CryptoNet.send(sendSocket, toSend)
    print("Sent: " .. toSend)
    
    inputLoop()
end

function netStart()
    print("Enter host: ")
    local hostName = io.read()
    local socket = CryptoNet.connect(hostName)
    print("Enter login name: ")
    local loginName = io.read()
    print("Enter password: ")
    local password = io.read()
    CryptoNet.login(socket, loginName, password)
end

function netEvent(event)
    if event[1] == "login" then
        sendSocket = event[3]
        print("Logged in as " .. event[2])
        inputLoop()
    elseif event[1] == "login_failed" then
        print("Login failed.")
    elseif event[1] == "encrypted_message" then
        print("Bot said: " .. event[2])
    end
end

CryptoNet.startEventLoop(netStart, netEvent)