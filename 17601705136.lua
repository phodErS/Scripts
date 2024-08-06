repeat wait() until game:IsLoaded()

local SYC = {
    Modules = {
        UI = {}
    }
}

local guiService = game:GetService("CoreGui")
local existingGUI = guiService:FindFirstChild("nixius.xyz")

if not getgenv().SYC then
    getgenv().SYC = SYC
end

if not isfolder("nixius.xyz") then
    makefolder("nixius.xyz")
end

if not isfolder("nixius.xyz/configs") then
    makefolder("nixius.xyz/configs")
end

if not isfolder("nixius.xyz/configs/tycoonrng") then
    makefolder("nixius.xyz/configs/tycoonrng")
end

local cubeNames = {
    "Luck Cube",
    "Speed Cube",
    "Glitch Cube",
    "Haste Cube",
    "Fortune Cube",
    "Pastel Cube",
    "Golden Cube",
    "Inferno Cube",
    "Wealth Cube",
    "Multitude of Rain",
    "Fortune of Wind",
    "Silent Speed of Snow",
    "Spore Blossom",
    "Technosphere",
    "Event Horizon",
    "Burger",
    "Arctic Frost",
    "Dragon`s Gem",
    "Midas Touch",
    "Lumitree",
    "Shooting Star",
    "Glitch Anomaly",
    "Roll of Glitch",
    "Stellar Nebula"
}

local cubeRarities = {
    ["Luck Cube"] = "Common",
    ["Speed Cube"] = "Common",
    ["Multitude of Rain"] = "Common",
    ["Fortune of Wind"] = "Common",
    ["Silent Speed of Snow"] = "Common",
    ["Haste Cube"] = "Uncommon",
    ["Fortune Cube"] = "Uncommon",
    ["Wealth Cube"] = "Rare",
    ["Pastel Cube"] = "Epic",
    ["Golden Cube"] = "Epic",
    ["Glitch Cube"] = "Legendary",
    ["Inferno Cube"] = "Legendary",
    ["Spore Blossom"] = "Mythic",
    ["Technosphere"] = "Mythic",
}

local cubeColors = {
    ["Luck Cube"] = "#05ff3b",
    ["Speed Cube"] = "#6397ff",
    ["Inferno Cube"] = "#fc6330",
    ["Glitch Cube"] = "#440345",
    ["Haste Cube"] = "#0558ff",
    ["Fortune Cube"] = "#288000",
    ["Pastel Cube"] = "#cc96ff",
    ["Golden Cube"] = "#fab546",
    ["Wealth Cube"] = "#ffec59",
    ["Spore Blossom"] = "#ed4aff",
    ["Technosphere"] = "#5c4aff",
    ["Event Horizon"] = "#6854ff",
    ["Fortune of Wind"] = "#8cf19b",
    ["Silent Speed of Snow"] = "#acecff",
    ["Multitude of Rain"] = "#3bb8ff",
    ["Stellar Nebula"] = "#ffffff"
}

local ignorcubenames = ""

local pingme = false
local usewebhook = false
local usewebhookwhenobbycompleted = false

local notifiedCubes = {}
local webhookUrl = ''
local notificationCooldown = 0.86

local function hexToRGB(hex)
    hex = hex:gsub("#", "")
    return tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))
end

local function RGBToDecimal(r, g, b)
    return (r * 256 * 256) + (g * 256) + b
end

local function sendDiscordNotification(cubeName)
    local currentTime = tick()

    if notifiedCubes[cubeName] and currentTime - notifiedCubes[cubeName] < notificationCooldown then
        return
    end

    notifiedCubes[cubeName] = currentTime

    local OSTime = os.time()
    local Time = os.date('!*t', OSTime)
    local colorHex = cubeColors[cubeName] or "#1F40FF"
    local rarity = cubeRarities[cubeName] or "Unknown"
    local r, g, b = hexToRGB(colorHex)
    local mention = pingme and "@everyone" or ""
    local Embed = {
        title = 'Tycoon RNG Notification',
        description = mention .. ' A cube has been collected in the game!',
        color = RGBToDecimal(r, g, b),
        footer = {
            text = 'Job ID: ' .. game.JobId,
        },
        fields = {
            {
                name = 'Cube Name',
                value = "`" .. cubeName .. "`",
                inline = true
            },
            {
                name = 'Status',
                value = '`Collected`',
                inline = true
            },
            {
                name = 'Rarity',
                value = "`" .. rarity .. "`",
                inline = false
            }
        },
        timestamp = string.format('%d-%d-%dT%02d:%02d:%02dZ', Time.year, Time.month, Time.day, Time.hour, Time.min, Time.sec)
    }

    local Body = {
        content = mention, 
        embeds = { Embed }
    }

    (syn and syn.request or http_request) {
        Url = webhookUrl,
        Method = 'POST',
        Headers = {
            ['Content-Type'] = 'application/json'
        },
        Body = game:GetService('HttpService'):JSONEncode(Body)
    }
end

local function sendObbyEndNotification()
    local OSTime = os.time()
    local Time = os.date('!*t', OSTime)
    local mention = pingme and "@everyone" or ""
    local Embed = {
        title = 'Tycoon RNG Notificationt',
        description = 'The player has been successfully teleported to the end of the Luck Obby.',
        color = RGBToDecimal(144, 214, 254),
        footer = { text = game.JobId },
        fields = {
            {
                name = 'Luck Obby Status',
                value = '`Completed`'
            }
        },
        timestamp = string.format('%d-%d-%dT%02d:%02d:%02dZ', Time.year, Time.month, Time.day, Time.hour, Time.min, Time.sec)
    }

    local Body = {
        content = mention, 
        embeds = { Embed }
    }

    (syn and syn.request or http_request) {
        Url = webhookUrl,
        Method = 'POST',
        Headers = {
            ['Content-Type'] = 'application/json'
        },
        Body = game:GetService('HttpService'):JSONEncode(Body)
    }
end

local function teleportPlayer()
    local player = game.Players.LocalPlayer

    if player and player.Character then
        local character = player.Character

        for _, cubeName in ipairs(cubeNames) do
            local cubeModel = game.Workspace:FindFirstChild(cubeName)

            if cubeModel and cubeModel:IsA("Model") then
                local modelCenter = cubeModel:GetModelCFrame().p
                character:SetPrimaryPartCFrame(CFrame.new(modelCenter))
                local rarity = cubeRarities[cubeName] or "Unknown"
                if usewebhook and not table.find(ignorcubenames, rarity) then
                    sendDiscordNotification(cubeName)
                end
                break
            end
        end
    else
        print("Error : Player or their character not found.")
    end
end

local function fireTouchDetectors()
    for _, cubeName in ipairs(cubeNames) do
        local cubeModel = game.Workspace:FindFirstChild(cubeName)

        if cubeModel and cubeModel:IsA("Model") then
            for _, child in ipairs(cubeModel:GetDescendants()) do
                if child:IsA("TouchTransmitter") then
                    firetouchinterest(game.Players.LocalPlayer.Character.PrimaryPart, child.Parent, 0)
                    firetouchinterest(game.Players.LocalPlayer.Character.PrimaryPart, child.Parent, 1)
                    local rarity = cubeRarities[cubeName] or "Unknown"
                    if usewebhook and not table.find(ignorcubenames, rarity) then
                        sendDiscordNotification(cubeName)
                    end
                end
            end
        end
    end
end

local Players = game:service("Players")
local Player = Players.LocalPlayer

if existingGUI then
    existingGUI:Destroy()
end

getgenv().playerService = game:GetService("Players")
getgenv().coreguiService = game:GetService("CoreGui")
getgenv().tweenService = game:GetService("TweenService")
getgenv().inputService = game:GetService("UserInputService")
getgenv().rsService = game:GetService("RunService")
getgenv().replicatedStorage = game:GetService("ReplicatedStorage")
getgenv().textService = game:GetService("TextService")
getgenv().httpService = game:GetService("HttpService")
getgenv().userSettings = UserSettings()
getgenv().userGameSettings = userSettings:GetService("UserGameSettings")
getgenv().inputManager = game:GetService("VirtualInputManager")

local LocalPlayer = playerService.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local MathHuge, MathAbs, MathAcos, MathAsin, MathAtan, MathAtan2, MathCeil, MathCos, MathCosh, MathDeg, MathExp, MathFloor, MathFmod, MathFrexp, MathLdexp, MathLog, MathLog10, MathMax, MathMin, MathModf, MathPi, MathPow, MathRad, MathRandom, MathRandomseed, MathSin, MathSinh, MathSqrt, MathTan, MathTanh = math.huge, math.abs, math.acos, math.asin, math.atan, math.atan2, math.ceil, math.cos, math.cosh, math.deg, math.exp, math.floor, math.fmod, math.frexp, math.ldexp, math.log, math.log10, math.max, math.min, math.modf, math.pi, math.pow, math.rad, math.random, math.randomseed, math.sin, math.sinh, math.sqrt, math.tan, math.tanh
local TableConcat, TableInsert, TablePack, TableRemove, TableSort, TableUnpack, TableClear, TableFind = table.concat, table.insert, table.pack, table.remove, table.sort, table.unpack, table.clear, table.find
local Vector2New, Vector2Zero, Vector2New = Vector2.new, Vector2.zero, Vector2.new
local Vector3New, Vector3Zero, Vector3One, Vector3FromNormalId, Vector3FromAxis = Vector3.new, Vector3.zero, Vector3.one, Vector3.FromNormalId, Vector3.FromAxis
local UDim2New = UDim2.new
local CFrameNew, CFrameAngles, CFrameFromAxisAngle, CFrameFromEulerAnglesXYZ, CFrameFromMatrix, CFrameFromOrientation, CFrameFromQuaternion = CFrame.new, CFrame.Angles, CFrame.fromAxisAngle, CFrame.fromEulerAnglesXYZ, CFrame.fromMatrix, CFrame.fromOrientation, CFrame.fromQuaternion
local Color3New, Color3FromRGB, Color3FromHSV = Color3.new, Color3.fromRGB, Color3.fromHSV
local InstanceNew = Instance.new
local TaskDelay, TaskSpawn, TaskWait = task.delay, task.spawn, task.wait
local RaycastParamsNew = RaycastParams.new
local DrawingNew = Drawing.new

local ModuleHandler = (function()
    
    local ModuleHandler = {}
    
    function ModuleHandler:include(ModuleName)
        if not SYC then return end
        if not SYC.Modules then return end
    
        if not type(ModuleName) == "string" then return end
    
        local Modules = SYC.Modules
        return Modules[ModuleName]
    end
    
    getgenv().include = function (modname) return ModuleHandler:include(modname) end 
    return ModuleHandler
end)()

do -- src/Lua/Modules/Base/
    do -- src/Lua/Modules/Base/Connection.lua
        function SYC.Modules.Connect(onething, secondthing)
            local connection = onething:Connect(secondthing)
            return connection
        end
    end
    do -- src/Lua/Modules/Base/Draw.lua
        local DrawingClass = {}
        DrawingClass.__index = DrawingClass
        DrawingClass.Objects = {}
        
        local DrawingMeta = {}
        
        DrawingMeta.__call = function (self, Arguments)
            if Arguments then
                local newObject = Drawing.new(Arguments[1])
                
                for property, value in next, Arguments[2] do
                    newObject[property] = value
                end
        
                table.insert(self.Objects, newObject)
                return newObject
            end
        end
        
        setmetatable(DrawingClass, DrawingMeta)
        
        SYC.Modules.DrawingClass = DrawingClass
    end
    do -- src/Lua/Modules/Base/Lerp.lua
        function SYC.Modules.lerp(a, b, t)
            return a + (b - a) * t
        end
    end
    do -- src/Lua/Modules/Base/Loops.lua
        local Loops = {Heartbeat = {}, RenderStepped = {}}
        function Loops:AddToHeartbeat(Name, Function)
            if Loops["Heartbeat"][Name] == nil then
                Loops["Heartbeat"][Name] = rsService.Heartbeat:Connect(Function)
            end
        end
        function Loops:RemoveFromHeartbeat(Name)
            if Loops["Heartbeat"][Name] then
                Loops["Heartbeat"][Name]:Disconnect()
                Loops["Heartbeat"][Name] = nil
            end
        end
        function Loops:AddToRenderStepped(Name, Function)
            if Loops["RenderStepped"][Name] == nil then
                Loops["RenderStepped"][Name] = rsService.RenderStepped:Connect(Function)
            end
        end
        function Loops:RemoveFromRenderStepped(Name)
            if Loops["RenderStepped"][Name] then
                Loops["RenderStepped"][Name]:Disconnect()
                Loops["RenderStepped"][Name] = nil
            end
        end
        
        SYC.Modules.Loops = Loops
    end
    do -- src/Lua/Modules/Base/PerlinNoise.lua
        -- useful shit for legit ig
        function SYC.Modules.PerlinNoise(offset, speed, time)
            local value = math.noise(time * speed + offset)
            return math.clamp(value, -0.5, 0.5)
        end
    end
    do -- src/Lua/Modules/Base/UI - Rich to Plain.lua
        -- @https://devforum.roblox.com/t/how-to-ensure-a-plain-text-string-when-using-rich-text-field/1640202
        function SYC.Modules.UI.RichTextToNormalText(str)
            local output_string = str
            while true do 
                if not output_string:find("<") and not output_string:find(">") then break end -- If not found  any <...>
                if (output_string:find("<") and not output_string:find(">")) or (output_string:find(">") and not output_string:find("<")) then return error("Invalid RichText") end -- if found only "<..." or "...>"
                output_string = output_string:gsub(output_string:sub(output_string:find("<"),output_string:find(">")),"",1) -- Removing this "<...>"
                TaskWait()
            end
            return output_string
        end
    end
    do -- src/Lua/Modules/Base/UI -GetTextBoundary.lua
        function SYC.Modules.UI:GetTextBoundary(Text, Font, Size, Resolution)
            local Bounds = textService:GetTextSize(Text, Size, Font, Resolution or Vector2New(1920, 1080))
            return Bounds.X, Bounds.Y
        end
    end
end

local UserInterface = (function() -- src/Lua/Interface/Interface.Lua
    local UserInterface = {
        Instances = {},
        Popup = nil,
        KeybindsListObjects = {},
        KeybindList = nil,
    
        Flags = {},
        ConfigFlags = {}
    }
    getgenv().uishit = UserInterface
    
    getgenv().theme = {
        accent = Color3FromRGB(167, 140, 255)
    }
    
    getgenv().theme_event = Instance.new('BindableEvent')
    
    getgenv().UI = UserInterface.Instances
    local UIModule = include "UI"
    
    local dragging, dragInput, dragStart, startPos, dragObject
    
    local Keys = {
        [Enum.KeyCode.LeftShift] = "LS",
        [Enum.KeyCode.RightShift] = "RS",
        [Enum.KeyCode.LeftControl] = "LC",
        [Enum.KeyCode.RightControl] = "RC",
        [Enum.KeyCode.LeftAlt] = "LA",
        [Enum.KeyCode.RightAlt] = "RA",
        [Enum.KeyCode.CapsLock] = "CAPS",
        [Enum.KeyCode.Return] = "ENT",
        [Enum.KeyCode.PageDown] = "PGD",
        [Enum.KeyCode.PageUp] = "PGU",
        [Enum.KeyCode.ScrollLock] = "SCL",
        [Enum.KeyCode.One] = "1",
        [Enum.KeyCode.Two] = "2",
        [Enum.KeyCode.Three] = "3",
        [Enum.KeyCode.Four] = "4",
        [Enum.KeyCode.Five] = "5",
        [Enum.KeyCode.Six] = "6",
        [Enum.KeyCode.Seven] = "7",
        [Enum.KeyCode.Eight] = "8",
        [Enum.KeyCode.Nine] = "9",
        [Enum.KeyCode.Zero] = "0",
        [Enum.KeyCode.KeypadOne] = "1",
        [Enum.KeyCode.KeypadTwo] = "2",
        [Enum.KeyCode.KeypadThree] = "3",
        [Enum.KeyCode.KeypadFour] = "4",
        [Enum.KeyCode.KeypadFive] = "5",
        [Enum.KeyCode.KeypadSix] = "6",
        [Enum.KeyCode.KeypadSeven] = "7",
        [Enum.KeyCode.KeypadEight] = "8",
        [Enum.KeyCode.KeypadNine] = "9",
        [Enum.KeyCode.KeypadZero] = "0",
        [Enum.KeyCode.Minus] = "-",
        [Enum.KeyCode.Equals] = "=",
        [Enum.KeyCode.Tilde] = "~",
        [Enum.KeyCode.LeftBracket] = "[",
        [Enum.KeyCode.RightBracket] = "]",
        [Enum.KeyCode.RightParenthesis] = ")",
        [Enum.KeyCode.LeftParenthesis] = "(",
        [Enum.KeyCode.Semicolon] = ",",
        [Enum.KeyCode.Quote] = "'",
        [Enum.KeyCode.BackSlash] = "\\",
        [Enum.KeyCode.Comma] = ",",
        [Enum.KeyCode.Period] = ".",
        [Enum.KeyCode.Slash] = "/",
        [Enum.KeyCode.Asterisk] = "*",
        [Enum.KeyCode.Plus] = "+",
        [Enum.KeyCode.Period] = ".",
        [Enum.KeyCode.Backquote] = "`",
        [Enum.KeyCode.Insert] = "INS",
        [Enum.UserInputType.MouseButton1] = "MB1",
        [Enum.UserInputType.MouseButton2] = "MB2",
        [Enum.UserInputType.MouseButton3] = "MB3",
        [Enum.KeyCode.Backspace] = "BS",
        [Enum.KeyCode.Escape] = "ESC",
        [Enum.KeyCode.Space] = "SPC",
    }
    
    local FlagCount = 0
    function UserInterface:GetNextFlag()
        FlagCount = FlagCount + 1
        return tostring(FlagCount)
    end
    
    function UserInterface:Create(OptionsLaughtOutLouds)
        local Configuration = {
            Tabs = {},
            Title = OptionsLaughtOutLouds.title or 'syndicate<font color="rgb(129, 127, 127)">.club</font>'
        }
    
        local Texts = {
            "Tycoon RNG Script",
        }
    
        local function ChangeText(Object, NewText) -- this is for the thing in the top-right in the ui what
            tweenService:Create(Object, TweenInfo.new(0.2), {TextTransparency = 0.5}):Play()
            Object.Text = NewText
            TaskWait(0.1)
    
            tweenService:Create(Object, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
        end
        
        UI["1"] = InstanceNew("ScreenGui", coreguiService)
        UI["1"]["Name"] = [[nixius.xyz]]
        UI["1"]["ZIndexBehavior"] = Enum.ZIndexBehavior.Global
    
        UI["2"] = InstanceNew("Frame", UI["1"])
        UI["2"]["BorderSizePixel"] = 0
        UI["2"]["BackgroundColor3"] = Color3FromRGB(24, 24, 24)
        UI["2"]["Size"] = UDim2New(0, 562, 0, 459)
        UI["2"]["Position"] = UDim2New(0, 527, 0, 168)
        UI["2"]["BorderColor3"] = Color3FromRGB(0, 0, 0)
        UI["2"]["Name"] = [[BackgroundFrame]]
        
        UI["3"] = InstanceNew("UICorner", UI["2"])
        UI["3"]["Name"] = [[BackgroundCorner]]
        
        UI["4"] = InstanceNew("UIStroke", UI["2"])
        UI["4"]["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border
        UI["4"]["Name"] = [[BackgroundStroke]]
        UI["4"]["Thickness"] = 2
        UI["4"]["Color"] = Color3FromRGB(31, 33, 31)
        
        UI["5"] = InstanceNew("TextLabel", UI["2"])
        UI["5"]["TextStrokeTransparency"] = 0
        UI["5"]["BorderSizePixel"] = 0
        UI["5"]["BackgroundColor3"] = Color3FromRGB(255, 255, 255)
        UI["5"]["TextSize"] = 16
        UI["5"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        UI["5"]["TextColor3"] = Color3FromRGB(255, 255, 255)
        UI["5"]["BackgroundTransparency"] = 1
        UI["5"]["Size"] = UDim2New(0, 81, 0, 20)
        UI["5"]["BorderColor3"] = Color3FromRGB(0, 0, 0)
        UI["5"]["Text"] = Configuration.Title
        UI["5"]["Name"] = [[MainTitle]]
        UI["5"]["Position"] = UDim2New(0, 15, 0, 12)
        UI["5"]["RichText"] = true
        UI["5"]["TextXAlignment"] = Enum.TextXAlignment.Left
    
        UI["6"] = InstanceNew("Frame", UI["2"])
        UI["6"]["BackgroundColor3"] = Color3FromRGB(255, 255, 255)
        UI["6"]["Size"] = UDim2New(0, 1, 0, 16)
        UI["6"]["Position"] = UDim2New(0, 98, 0, 14)
        UI["6"]["BorderColor3"] = Color3FromRGB(0, 0, 0)
        UI["6"]["Name"] = [[BackgroundAccent]]
    
        UI["7"] = InstanceNew("Frame", UI["2"])
        UI["7"]["BorderSizePixel"] = 0
        UI["7"]["BackgroundColor3"] = Color3FromRGB(255, 255, 255)
        UI["7"]["Size"] = UDim2New(0, 456, 0, 16)
        UI["7"]["Position"] = UDim2New(0, 105, 0, 14)
        UI["7"]["BorderColor3"] = Color3FromRGB(0, 0, 0)
        UI["7"]["Name"] = [[TabsList]]
        UI["7"]["BackgroundTransparency"] = 1
    
        UI["9"] = InstanceNew("UIListLayout", UI["7"])
        UI["9"]["Padding"] = UDim.new(0, 5)
        UI["9"]["SortOrder"] = Enum.SortOrder.LayoutOrder
        UI["9"]["Name"] = [[TabsListLayout]]
        UI["9"]["FillDirection"] = Enum.FillDirection.Horizontal
    
        UI["a"] = InstanceNew("TextLabel", UI["2"])
        UI["a"]["TextWrapped"] = false
        UI["a"]["TextStrokeTransparency"] = 0
        UI["a"]["BorderSizePixel"] = 0
        UI["a"]["TextXAlignment"] = Enum.TextXAlignment.Right
        UI["a"]["TextScaled"] = false
        UI["a"]["BackgroundColor3"] = Color3FromRGB(255, 255, 255)
        UI["a"]["TextSize"] = 16
        UI["a"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        UI["a"]["TextColor3"] = Color3FromRGB(255, 255, 255)
        UI["a"]["BackgroundTransparency"] = 1
        UI["a"]["Size"] = UDim2New(0, 452, 0, 19)
        UI["a"]["BorderColor3"] = Color3FromRGB(0, 0, 0)
        UI["a"]["Text"] = [[Tycoon RNG Script]]
        UI["a"]["Name"] = [[CreditTitle]]
        UI["a"]["Position"] = UDim2New(0, 96, 0, 428)
    
        UI["b"] = InstanceNew("Frame", UI["2"])
        UI["b"]["BorderSizePixel"] = 0
        UI["b"]["BackgroundColor3"] = Color3FromRGB(17, 17, 17)
        UI["b"]["Size"] = UDim2New(0, 533, 0, 378)
        UI["b"]["Position"] = UDim2New(0.027, 0,0.095, 0)
        UI["b"]["BorderColor3"] = Color3FromRGB(0, 0, 0)
        UI["b"]["Name"] = [[MainFrame]]
    
        local MainFrameShadow1 = Instance.new("Frame")
        local MF_SHADOW1 = Instance.new("UIGradient")
        
        MainFrameShadow1.Name = "MainFrameShadow1"
        MainFrameShadow1.Parent = UI["b"]
        MainFrameShadow1.ZIndex = 2
        MainFrameShadow1.Size = UDim2.new(1, 0, 0.039682541, 0)
        MainFrameShadow1.BorderColor3 = Color3.fromRGB(0, 0, 0)
        MainFrameShadow1.Position = UDim2.new(0, 0, 0.960317433, 0)
        MainFrameShadow1.BorderSizePixel = 0
        MainFrameShadow1.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        
        MF_SHADOW1.Name = "MF_SHADOW1"
        MF_SHADOW1.Parent = MainFrameShadow1
        MF_SHADOW1.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.004552352242171764, 0.11475414037704468), NumberSequenceKeypoint.new(0.030349012464284897, 0.3606557846069336), NumberSequenceKeypoint.new(0.6358118057250977, 1), NumberSequenceKeypoint.new(0.9998999834060669, 1), NumberSequenceKeypoint.new(1, 0)})
        MF_SHADOW1.Rotation = -90
    
        local MainFrameShadow2 = Instance.new("Frame")
        local MF_SHADOW2 = Instance.new("UIGradient")
        
        MainFrameShadow2.Name = "MainFrameShadow2"
        MainFrameShadow2.Parent = UI["b"]
        MainFrameShadow2.ZIndex = 2
        MainFrameShadow2.Size = UDim2.new(1, 0, 0.0399999991, 0)
        MainFrameShadow2.BorderColor3 = Color3.fromRGB(0, 0, 0)
        MainFrameShadow2.BorderSizePixel = 0
        MainFrameShadow2.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        
        MF_SHADOW2.Name = "MF_SHADOW2"
        MF_SHADOW2.Parent = MainFrameShadow2
        MF_SHADOW2.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.004552352242171764, 0.11475414037704468), NumberSequenceKeypoint.new(0.030349012464284897, 0.3606557846069336), NumberSequenceKeypoint.new(0.6358118057250977, 1), NumberSequenceKeypoint.new(0.9998999834060669, 1), NumberSequenceKeypoint.new(1, 0)})
        MF_SHADOW2.Rotation = 90
    
        UI["c"] = InstanceNew("UICorner", UI["b"])
        UI["c"]["Name"] = [[MainFrameCorner]]
    
        UI["d"] = InstanceNew("UIStroke", UI["b"])
        UI["d"]["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border
        UI["d"]["Name"] = [[MainFrameStroke]]
        UI["d"]["Color"] = Color3FromRGB(29, 29, 29)
    
        UI["e"] = InstanceNew("Folder", UI["2"])
        UI["e"]["Name"] = [[Sections]]
    
        local Shadow1 = Instance.new("ImageLabel")
    
        Shadow1.Name = "Shadow1"
        Shadow1.Parent = UI["2"]
        Shadow1.AnchorPoint = Vector2.new(0.5, 0.5)
        Shadow1.ZIndex = 0
        Shadow1.Size = UDim2.new(1.7, 0,2.843, 0)
        Shadow1.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Shadow1.Rotation = 90
        Shadow1.BackgroundTransparency = 1
        Shadow1.Position = UDim2.new(0.468, 0,0.495, 0)
        Shadow1.BorderSizePixel = 0
        Shadow1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Shadow1.ImageColor3 = Color3.fromRGB(0, 0, 0)
        Shadow1.ScaleType = Enum.ScaleType.Tile
        Shadow1.Image = "rbxassetid://8992230677"
        Shadow1.SliceCenter = Rect.new(Vector2.new(0, 0), Vector2.new(99, 99))
    
        local text_coroutine = coroutine.create(function ()
            while TaskWait() do
                for i = 1, #Texts do
                    TaskWait(2)
                    ChangeText(UI["a"], Texts[i])
                end
            end
        end)
        coroutine.resume(text_coroutine)
    
        function Configuration:Tab( Tab_Name )
            if not type(Tab_Name) == "string" then return end
    
            local TabConfiguration = { Sections = {} }
    
            local X = UIModule:GetTextBoundary(Tab_Name, Enum.Font.SourceSans, 16)
            UI["8"] = InstanceNew("TextButton", UI["7"])
            UI["8"]["TextStrokeTransparency"] = 0
            UI["8"]["BorderSizePixel"] = 0
            UI["8"]["TextSize"] = 16
            UI["8"]["TextColor3"] = Color3FromRGB(137, 137, 139)
            UI["8"]["BackgroundColor3"] = Color3FromRGB(255, 255, 255)
            UI["8"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            UI["8"]["Size"] = UDim2New(0, X, 1, 0)
            UI["8"]["BackgroundTransparency"] = 1
            UI["8"]["Name"] = [[TabButton]]
            UI["8"]["BorderColor3"] = Color3FromRGB(0, 0, 0)
            UI["8"]["Text"] = Tab_Name
    
            UI["f"] = InstanceNew("Frame", UI["e"])
            UI["f"]["Active"] = true
            UI["f"]["BorderSizePixel"] = 0
            UI["f"]["BackgroundColor3"] = Color3FromRGB(255, 255, 255)
            UI["f"]["Name"] = [[MainSectionFrame]]
            UI["f"]["Position"] = UDim2New(0.028, 0,0.142, 0)
            UI["f"]["Size"] = UDim2New(0, 530, 0, 378)
            UI["f"]["BorderColor3"] = Color3FromRGB(0, 0, 0)
            UI["f"]["BackgroundTransparency"] = 1
            UI["f"]["Position"] = UDim2New(0.027, 0, 0.095, 0)
    
            local MSFrame = UI["f"]
    
            local leftblah = InstanceNew("ScrollingFrame", UI["f"])
            leftblah["Active"] = true
            leftblah["BorderSizePixel"] = 0
            leftblah["BackgroundColor3"] = Color3FromRGB(255, 255, 255)
            leftblah["Name"] = [[Left]]
            leftblah["ScrollBarImageTransparency"] = 0
            leftblah["Size"] = UDim2New(0, 265, 1, 0)
            leftblah["ScrollBarImageColor3"] = Color3FromRGB(167, 140, 255)
            leftblah["BorderColor3"] = Color3FromRGB(0, 0, 0)
            leftblah["ScrollBarThickness"] = 3
            leftblah["BackgroundTransparency"] = 1
            leftblah.AutomaticCanvasSize = Enum.AutomaticSize.Y
            leftblah["Position"] = UDim2New(0, 0, 0, 0)
            leftblah.BottomImage = ""
            leftblah.TopImage = ""
    
            theme_event.Event:Connect(function ()
                leftblah.ScrollBarImageColor3 = theme.scroll
            end)
    
            UI["11"] = InstanceNew("UIPadding", leftblah)
            UI["11"]["PaddingTop"] = UDim.new(0, 18)
            UI["11"]["Name"] = [[LeftColumnPadding]]
            UI["11"]["PaddingLeft"] = UDim.new(0, 7)
    
            local rightblahInstance = InstanceNew("ScrollingFrame", UI["f"])
            rightblahInstance["Active"] = true
            rightblahInstance["BorderSizePixel"] = 0
            rightblahInstance["BackgroundColor3"] = Color3FromRGB(255, 255, 255)
            rightblahInstance["Name"] = [[Right]]
            rightblahInstance["ScrollBarImageTransparency"] = 0
            rightblahInstance["Size"] = UDim2New(0, 265, 1, 0)
            rightblahInstance["ScrollBarImageColor3"] = Color3FromRGB(0, 255, 255)
            rightblahInstance["BorderColor3"] = Color3FromRGB(0, 0, 0)
            rightblahInstance["ScrollBarThickness"] = 3
            rightblahInstance["BackgroundTransparency"] = 1
            rightblahInstance.AutomaticCanvasSize = Enum.AutomaticSize.Y
            rightblahInstance["Position"] = UDim2New(0, 265, 0, 0)
            rightblahInstance.BottomImage = ""
            rightblahInstance.TopImage = ""
    
            theme_event.Event:Connect(function ()
                rightblahInstance.ScrollBarImageColor3 = theme.scroll
            end)
    
            UI["20"] = InstanceNew("UIPadding", rightblahInstance)
            UI["20"]["PaddingTop"] = UDim.new(0, 18)
            UI["20"]["PaddingRight"] = UDim.new(0, 7)
            UI["20"]["PaddingLeft"] = UDim.new(0, 6)
            UI["20"]["Name"] = [[RightColumnPadding]]
    
            UI["LISTLAYOUT_LEFT"] = InstanceNew("UIListLayout")
            UI["LISTLAYOUT_LEFT"].Name = "LeftColumnList"
            UI["LISTLAYOUT_LEFT"].Parent = leftblah
            UI["LISTLAYOUT_LEFT"].SortOrder = Enum.SortOrder.LayoutOrder
            UI["LISTLAYOUT_LEFT"].Padding = UDim.new(0, 19)
    
            UI["LISTLAYOUT_RIGHT"] = InstanceNew("UIListLayout")
            UI["LISTLAYOUT_RIGHT"].Name = "RightColumnList"
            UI["LISTLAYOUT_RIGHT"].Parent = rightblahInstance
            UI["LISTLAYOUT_RIGHT"].SortOrder = Enum.SortOrder.LayoutOrder
            UI["LISTLAYOUT_RIGHT"].Padding = UDim.new(0, 19)
    
            local localization = UI['LISTLAYOUT_LEFT']
            local localization2 = UI["LISTLAYOUT_RIGHT"]
    
            localization.Changed:Connect(function ()
                leftblah.CanvasSize = UDim2New(0, 0, 0, 100 + localization.AbsoluteContentSize.Y)
            end)
    
            localization2.Changed:Connect(function ()
                rightblahInstance.CanvasSize = UDim2New(0, 0, 0, 100 + localization2.AbsoluteContentSize.Y)
            end)
    
            TabConfiguration.Button = UI["8"]
            TabConfiguration.MainSectionFrame = MSFrame
            TabConfiguration.Left = leftblah
            TabConfiguration.Right = rightblahInstance
    
            function TabConfiguration:Select()
                for i, v in next, UI["e"]:GetChildren() do
                    if v:IsA("UIListLayout") then return end
                    v.Visible = false
                end
                for i, v in next, UI["7"]:GetChildren() do
                    if v:IsA("TextButton") then
                        v.TextColor3 = Color3FromRGB(137, 137, 139)
                    end
                end
                TabConfiguration.Button.TextColor3 = Color3FromRGB(255,255,255)
                TabConfiguration.MainSectionFrame.Visible = true
            end
            
            TabConfiguration.Button.MouseButton1Click:Connect(function ()
                TabConfiguration:Select()
            end)
    
            function TabConfiguration:Section( Section_Name, Side )
                if not type(Section_Name) == "string" then return end
                if not type(Side) == "string" then return end
    
                local SectionSide = Side == "right" and TabConfiguration.Right or TabConfiguration.Left
                local Options = {}
    
                local MainFrameThingy = InstanceNew("Frame", SectionSide)
                MainFrameThingy["BorderSizePixel"] = 0
                MainFrameThingy["BackgroundColor3"] = Color3FromRGB(28, 28, 28)
                MainFrameThingy["Size"] = UDim2New(0, 247, 0, 20)
                MainFrameThingy["Position"] = UDim2New(0, 6, 0, 0)
                MainFrameThingy["BorderColor3"] = Color3FromRGB(0, 0, 0)
                MainFrameThingy["Name"] = [[Column]]
    
                local MFSTROKE = InstanceNew("UIStroke", MainFrameThingy)
                MFSTROKE["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border
                MFSTROKE["Name"] = [[ColumnStroke]]
                MFSTROKE["Color"] = Color3FromRGB(37, 37, 37)
    
                local uicornerthingyy = InstanceNew("UICorner", MainFrameThingy)
                uicornerthingyy["Name"] = [[ColumnCorner]]
    
                local titlethinggyy = InstanceNew("TextLabel", MainFrameThingy)
                titlethinggyy["TextStrokeTransparency"] = 0
                titlethinggyy["BorderSizePixel"] = 0
                titlethinggyy["TextXAlignment"] = Enum.TextXAlignment.Left
                titlethinggyy["BackgroundColor3"] = Color3FromRGB(255, 255, 255)
                titlethinggyy["TextSize"] = 14
                titlethinggyy["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                titlethinggyy["TextColor3"] = Color3FromRGB(255, 255, 255)
                titlethinggyy["BackgroundTransparency"] = 1
                titlethinggyy["Size"] = UDim2New(0, 229, 0, -4)
                titlethinggyy["BorderColor3"] = Color3FromRGB(0, 0, 0)
                titlethinggyy["Text"] = Section_Name
                titlethinggyy["Name"] = [[ColumnTitle]]
                titlethinggyy["Position"] = UDim2New(0, 8, 0, 0)
    
                local uilistlayoutthingy = InstanceNew("UIListLayout", MainFrameThingy)
                uilistlayoutthingy["Padding"] = UDim.new(0, 13)
                uilistlayoutthingy["SortOrder"] = Enum.SortOrder.LayoutOrder
                uilistlayoutthingy["Name"] = [[ColumnListLayout]]
    
                local paddingthingy = InstanceNew("UIPadding", MainFrameThingy)
                paddingthingy["Name"] = [[ColumnPadding]]
                paddingthingy["PaddingLeft"] = UDim.new(0, 9)
    
                local SectionColumnComponents = InstanceNew("Frame", MainFrameThingy)
                SectionColumnComponents["BorderSizePixel"] = 0
                SectionColumnComponents["BackgroundColor3"] = Color3FromRGB(255, 255, 255)
                SectionColumnComponents["Size"] = UDim2New(0, 229, 0, 0)
                SectionColumnComponents["Position"] = UDim2New(0, 0, 0, 13)
                SectionColumnComponents["BorderColor3"] = Color3FromRGB(0, 0, 0)
                SectionColumnComponents["Name"] = tostring(math.random(10000,16384))
                SectionColumnComponents["BackgroundTransparency"] = 1
    
                local aujodnousnd = InstanceNew("UIListLayout", SectionColumnComponents)
                aujodnousnd["Padding"] = UDim.new(0, 4)
                aujodnousnd["SortOrder"] = Enum.SortOrder.LayoutOrder
                aujodnousnd["Name"] = [[ColumnComponentsList]]
    
                local function increaseYSize(sizeY, Custom)
                    SectionColumnComponents["Size"] += UDim2New(0, 0, 0, sizeY)
                    MainFrameThingy.Size = UDim2New(0, 247, 0, 22 + aujodnousnd.AbsoluteContentSize.Y)
                end
    
                do -- src/Lua/Interface/Components/
                    do -- src/Lua/Interface/Components/BoneSelector.lua
                        function Options:BoneSelector(Configuration)
                            local BoneSelectorOptions = {
                                Type = Configuration.type or "R15",
                                Callback = Configuration.callback or function() end,
                                Default = Configuration.default or nil,
                                Flag = UserInterface:GetNextFlag(),
                                Multi = Configuration.multi or false
                            }
                        
                            local BoneSelector = {
                                FValues = {},
                                FValue = BoneSelectorOptions.Multi and {} or "",
                            }
                        
                            local BoneSelectorHolder = InstanceNew("Frame")
                            local BSHStroke = InstanceNew("UIStroke")
                            local BSHCorner = InstanceNew("UICorner")
                            local R15 = InstanceNew("Frame")
                            local Head = Instance.new("TextButton")
                            local HumanoidRootPart = Instance.new("TextButton")
                            local LeftHand = Instance.new("TextButton")
                            local LeftLowerArm = Instance.new("TextButton")
                            local LowerTorso = Instance.new("TextButton")
                            local LeftUpperArm = Instance.new("TextButton")
                            local RightHand = Instance.new("TextButton")
                            local RightUpperArm = Instance.new("TextButton")
                            local RightLowerArm = Instance.new("TextButton")
                            local UpperTorso = Instance.new("TextButton")
                            local LeftUpperLeg = Instance.new("TextButton")
                            local LeftLowerLeg = Instance.new("TextButton")
                            local LeftFoot = Instance.new("TextButton")
                            local RightFoot = Instance.new("TextButton")
                            local RightUpperLeg = Instance.new("TextButton")
                            local RightLowerLeg = Instance.new("TextButton")
                            local R6 = InstanceNew("Frame")
                            local Head_2 = InstanceNew("TextButton")
                            local LeftArm_2 = InstanceNew("TextButton")
                            local RightArm_2 = InstanceNew("TextButton")
                            local RightLeg_2 = InstanceNew("TextButton")
                            local LeftLeg_2 = InstanceNew("TextButton")
                            local Torso_3 = InstanceNew("TextButton")
                            local HumanoidRootPart_2 = InstanceNew("TextButton")
                            
                            BoneSelectorHolder.Name = "BoneSelectorHolder"
                            BoneSelectorHolder.Parent = SectionColumnComponents
                            BoneSelectorHolder.Size = UDim2.new(1, 0, 0, 316)
                            BoneSelectorHolder.BorderColor3 = Color3.fromRGB(0, 0, 0)
                            BoneSelectorHolder.Position = UDim2.new(0, 0, -1.17375305e-06, 0)
                            BoneSelectorHolder.BorderSizePixel = 0
                            BoneSelectorHolder.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
                            
                            BSHStroke.Name = "BSHStroke"
                            BSHStroke.Parent = BoneSelectorHolder
                            BSHStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                            BSHStroke.Color = Color3.fromRGB(36, 36, 36)
                            
                            BSHCorner.Name = "BSHCorner"
                            BSHCorner.Parent = BoneSelectorHolder
                            
                            R15.Name = "R15"
                            R15.Parent = BoneSelectorHolder
                            R15.Size = UDim2.new(0, 217, 0, 308)
                            R15.Visible = true
                            R15.BorderColor3 = Color3.fromRGB(0, 0, 0)
                            R15.BackgroundTransparency = 1
                            R15.Position = UDim2.new(0.0262008738, 0, 0.0187500007, 0)
                            R15.BorderSizePixel = 0
                            R15.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                            
                            Head.Name = "Head"
                            Head.Parent = R15
                            Head.Size = UDim2.new(0, 60, 0, 68)
                            Head.BorderColor3 = Color3.fromRGB(36, 36, 36)
                            Head.Position = UDim2.new(0.358999997, 0, 0.0579999983, 0)
                            Head.BorderSizePixel = 2
                            Head.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
                            Head.TextColor3 = Color3.fromRGB(0, 0, 0)
                            Head.Text = ""
                            Head.TextSize = 14
                            Head.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                        
                            HumanoidRootPart.Name = "HumanoidRootPart"
                            HumanoidRootPart.Parent = R15
                            HumanoidRootPart.ZIndex = 2
                            HumanoidRootPart.Size = UDim2.new(0, 22, 0, 25)
                            HumanoidRootPart.BorderColor3 = Color3.fromRGB(36, 36, 36)
                            HumanoidRootPart.Position = UDim2.new(0.446557671, 0, 0.402155876, 0)
                            HumanoidRootPart.BorderSizePixel = 2
                            HumanoidRootPart.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
                            HumanoidRootPart.TextColor3 = Color3.fromRGB(0, 0, 0)
                            HumanoidRootPart.Text = ""
                            HumanoidRootPart.TextSize = 14
                            HumanoidRootPart.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                        
                            LeftHand.Name = "LeftHand"
                            LeftHand.Parent = R15
                            LeftHand.Size = UDim2.new(0, 53, 0, 20)
                            LeftHand.BorderColor3 = Color3.fromRGB(36, 36, 36)
                            LeftHand.Position = UDim2.new(0.0778940767, 0, 0.548259795, 0)
                            LeftHand.BorderSizePixel = 2
                            LeftHand.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
                            LeftHand.TextColor3 = Color3.fromRGB(0, 0, 0)
                            LeftHand.Text = ""
                            LeftHand.TextSize = 14
                            LeftHand.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                        
                            LeftLowerArm.Name = "LeftLowerArm"
                            LeftLowerArm.Parent = R15
                            LeftLowerArm.Size = UDim2.new(0, 53, 0, 44)
                            LeftLowerArm.BorderColor3 = Color3.fromRGB(36, 36, 36)
                            LeftLowerArm.Position = UDim2.new(0.0778940767, 0, 0.405238956, 0)
                            LeftLowerArm.BorderSizePixel = 2
                            LeftLowerArm.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
                            LeftLowerArm.TextColor3 = Color3.fromRGB(0, 0, 0)
                            LeftLowerArm.Text = ""
                            LeftLowerArm.TextSize = 14
                            LeftLowerArm.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                        
                            LowerTorso.Name = "LowerTorso"
                            LowerTorso.Parent = R15
                            LowerTorso.Size = UDim2.new(0, 76, 0, 20)
                            LowerTorso.BorderColor3 = Color3.fromRGB(36, 36, 36)
                            LowerTorso.Position = UDim2.new(0.32213372, 0, 0.54809612, 0)
                            LowerTorso.BorderSizePixel = 2
                            LowerTorso.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
                            LowerTorso.TextColor3 = Color3.fromRGB(0, 0, 0)
                            LowerTorso.Text = ""
                            LowerTorso.TextSize = 14
                            LowerTorso.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                        
                            LeftUpperArm.Name = "LeftUpperArm"
                            LeftUpperArm.Parent = R15
                            LeftUpperArm.Size = UDim2.new(0, 53, 0, 38)
                            LeftUpperArm.BorderColor3 = Color3.fromRGB(36, 36, 36)
                            LeftUpperArm.Position = UDim2.new(0.0778940767, 0, 0.278615594, 0)
                            LeftUpperArm.BorderSizePixel = 2
                            LeftUpperArm.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
                            LeftUpperArm.TextColor3 = Color3.fromRGB(0, 0, 0)
                            LeftUpperArm.Text = ""
                            LeftUpperArm.TextSize = 14
                            LeftUpperArm.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                        
                            RightHand.Name = "RightHand"
                            RightHand.Parent = R15
                            RightHand.Size = UDim2.new(0, 51, 0, 19)
                            RightHand.BorderColor3 = Color3.fromRGB(36, 36, 36)
                            RightHand.Position = UDim2.new(0.679, 0, 0.548259795, 0)
                            RightHand.BorderSizePixel = 2
                            RightHand.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
                            RightHand.TextColor3 = Color3.fromRGB(0, 0, 0)
                            RightHand.Text = ""
                            RightHand.TextSize = 14
                            RightHand.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                        
                            RightUpperArm.Name = "RightUpperArm"
                            RightUpperArm.Parent = R15
                            RightUpperArm.Size = UDim2.new(0, 53, 0, 38)
                            RightUpperArm.BorderColor3 = Color3.fromRGB(36, 36, 36)
                            RightUpperArm.Position = UDim2.new(0.672364116, 0, 0.278615594, 0)
                            RightUpperArm.BorderSizePixel = 2
                            RightUpperArm.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
                            RightUpperArm.TextColor3 = Color3.fromRGB(0, 0, 0)
                            RightUpperArm.Text = ""
                            RightUpperArm.TextSize = 14
                            RightUpperArm.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                        
                            RightLowerArm.Name = "RightLowerArm"
                            RightLowerArm.Parent = R15
                            RightLowerArm.Size = UDim2.new(0, 53, 0, 44)
                            RightLowerArm.BorderColor3 = Color3.fromRGB(36, 36, 36)
                            RightLowerArm.Position = UDim2.new(0.672364116, 0, 0.405238956, 0)
                            RightLowerArm.BorderSizePixel = 2
                            RightLowerArm.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
                            RightLowerArm.TextColor3 = Color3.fromRGB(0, 0, 0)
                            RightLowerArm.Text = ""
                            RightLowerArm.TextSize = 14
                            RightLowerArm.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                        
                            UpperTorso.Name = "UpperTorso"
                            UpperTorso.Parent = R15
                            UpperTorso.Size = UDim2.new(0, 76, 0, 82)
                            UpperTorso.BorderColor3 = Color3.fromRGB(36, 36, 36)
                            UpperTorso.Position = UDim2.new(0.32213372, 0, 0.279000014, 0)
                            UpperTorso.BorderSizePixel = 2
                            UpperTorso.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
                            UpperTorso.TextColor3 = Color3.fromRGB(0, 0, 0)
                            UpperTorso.Text = ""
                            UpperTorso.TextSize = 14
                            UpperTorso.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                        
                            LeftUpperLeg.Name = "LeftUpperLeg"
                            LeftUpperLeg.Parent = R15
                            LeftUpperLeg.Size = UDim2.new(0, 38, 0, 62)
                            LeftUpperLeg.BorderColor3 = Color3.fromRGB(36, 36, 36)
                            LeftUpperLeg.Position = UDim2.new(0.32213372, 0, 0.613031149, 0)
                            LeftUpperLeg.BorderSizePixel = 2
                            LeftUpperLeg.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
                            LeftUpperLeg.TextColor3 = Color3.fromRGB(0, 0, 0)
                            LeftUpperLeg.Text = ""
                            LeftUpperLeg.TextSize = 14
                            LeftUpperLeg.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                        
                            LeftLowerLeg.Name = "LeftLowerLeg"
                            LeftLowerLeg.Parent = R15
                            LeftLowerLeg.Size = UDim2.new(0, 38, 0, 32)
                            LeftLowerLeg.BorderColor3 = Color3.fromRGB(36, 36, 36)
                            LeftLowerLeg.Position = UDim2.new(0.32213372, 0, 0.814329863, 0)
                            LeftLowerLeg.BorderSizePixel = 2
                            LeftLowerLeg.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
                            LeftLowerLeg.TextColor3 = Color3.fromRGB(0, 0, 0)
                            LeftLowerLeg.Text = ""
                            LeftLowerLeg.TextSize = 14
                            LeftLowerLeg.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                        
                            LeftFoot.Name = "LeftFoot"
                            LeftFoot.Parent = R15
                            LeftFoot.Size = UDim2.new(0, 38, 0, 9)
                            LeftFoot.BorderColor3 = Color3.fromRGB(36, 36, 36)
                            LeftFoot.Position = UDim2.new(0.32213372, 0, 0.918225944, 0)
                            LeftFoot.BorderSizePixel = 2
                            LeftFoot.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
                            LeftFoot.TextColor3 = Color3.fromRGB(0, 0, 0)
                            LeftFoot.Text = ""
                            LeftFoot.TextSize = 14
                            LeftFoot.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                        
                            RightFoot.Name = "RightFoot"
                            RightFoot.Parent = R15
                            RightFoot.Size = UDim2.new(0, 38, 0, 9)
                            RightFoot.BorderColor3 = Color3.fromRGB(36, 36, 36)
                            RightFoot.Position = UDim2.new(0.497248918, 0, 0.918225944, 0)
                            RightFoot.BorderSizePixel = 2
                            RightFoot.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
                            RightFoot.TextColor3 = Color3.fromRGB(0, 0, 0)
                            RightFoot.Text = ""
                            RightFoot.TextSize = 14
                            RightFoot.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                        
                            RightUpperLeg.Name = "RightUpperLeg"
                            RightUpperLeg.Parent = R15
                            RightUpperLeg.Size = UDim2.new(0, 38, 0, 62)
                            RightUpperLeg.BorderColor3 = Color3.fromRGB(36, 36, 36)
                            RightUpperLeg.Position = UDim2.new(0.497248918, 0, 0.613031149, 0)
                            RightUpperLeg.BorderSizePixel = 2
                            RightUpperLeg.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
                            RightUpperLeg.TextColor3 = Color3.fromRGB(0, 0, 0)
                            RightUpperLeg.Text = ""
                            RightUpperLeg.TextSize = 14
                            RightUpperLeg.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                        
                            RightLowerLeg.Name = "RightLowerLeg"
                            RightLowerLeg.Parent = R15
                            RightLowerLeg.Size = UDim2.new(0, 38, 0, 32)
                            RightLowerLeg.BorderColor3 = Color3.fromRGB(36, 36, 36)
                            RightLowerLeg.Position = UDim2.new(0.497248918, 0, 0.814329863, 0)
                            RightLowerLeg.BorderSizePixel = 2
                            RightLowerLeg.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
                            RightLowerLeg.TextColor3 = Color3.fromRGB(0, 0, 0)
                            RightLowerLeg.Text = ""
                            RightLowerLeg.TextSize = 14
                            RightLowerLeg.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                            
                            R6.Name = "R6"
                            R6.Parent = BoneSelectorHolder
                            R6.Size = UDim2.new(0, 217, 0, 308)
                            R6.Visible = false
                            R6.BorderColor3 = Color3.fromRGB(0, 0, 0)
                            R6.BackgroundTransparency = 1
                            R6.Position = UDim2.new(0.0262008738, 0, 0.0187500007, 0)
                            R6.BorderSizePixel = 0
                            R6.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                            
                            Head_2.Name = "Head"
                            Head_2.Parent = R6
                            Head_2.Size = UDim2.new(0, 76, 0, 68)
                            Head_2.BorderColor3 = Color3.fromRGB(36, 36, 36)
                            Head_2.Position = UDim2.new(0.322580636, 0, 0.058441557, 0)
                            Head_2.BorderSizePixel = 2
                            Head_2.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
                            Head_2.TextColor3 = Color3.fromRGB(0, 0, 0)
                            Head_2.Text = ""
                            Head_2.TextSize = 14
                            Head_2.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                            
                            LeftArm_2.Name = "Left Arm"
                            LeftArm_2.Parent = R6
                            LeftArm_2.Size = UDim2.new(0, 53, 0, 103)
                            LeftArm_2.BorderColor3 = Color3.fromRGB(36, 36, 36)
                            LeftArm_2.Position = UDim2.new(0.0783410147, 0, 0.27922079, 0)
                            LeftArm_2.BorderSizePixel = 2
                            LeftArm_2.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
                            LeftArm_2.TextColor3 = Color3.fromRGB(0, 0, 0)
                            LeftArm_2.Text = ""
                            LeftArm_2.TextSize = 14
                            LeftArm_2.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                            
                            RightArm_2.Name = "Right Arm"
                            RightArm_2.Parent = R6
                            RightArm_2.Size = UDim2.new(0, 53, 0, 103)
                            RightArm_2.BorderColor3 = Color3.fromRGB(36, 36, 36)
                            RightArm_2.Position = UDim2.new(0.672811031, 0, 0.27922079, 0)
                            RightArm_2.BorderSizePixel = 2
                            RightArm_2.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
                            RightArm_2.TextColor3 = Color3.fromRGB(0, 0, 0)
                            RightArm_2.Text = ""
                            RightArm_2.TextSize = 14
                            RightArm_2.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                            
                            RightLeg_2.Name = "Right Leg"
                            RightLeg_2.Parent = R6
                            RightLeg_2.Size = UDim2.new(0, 38, 0, 103)
                            RightLeg_2.BorderColor3 = Color3.fromRGB(36, 36, 36)
                            RightLeg_2.Position = UDim2.new(0.497695863, 0, 0.613636374, 0)
                            RightLeg_2.BorderSizePixel = 2
                            RightLeg_2.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
                            RightLeg_2.TextColor3 = Color3.fromRGB(0, 0, 0)
                            RightLeg_2.Text = ""
                            RightLeg_2.TextSize = 14
                            RightLeg_2.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                            
                            LeftLeg_2.Name = "Left Leg"
                            LeftLeg_2.Parent = R6
                            LeftLeg_2.Size = UDim2.new(0, 38, 0, 103)
                            LeftLeg_2.BorderColor3 = Color3.fromRGB(36, 36, 36)
                            LeftLeg_2.Position = UDim2.new(0.322580636, 0, 0.613636374, 0)
                            LeftLeg_2.BorderSizePixel = 2
                            LeftLeg_2.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
                            LeftLeg_2.TextColor3 = Color3.fromRGB(0, 0, 0)
                            LeftLeg_2.Text = ""
                            LeftLeg_2.TextSize = 14
                            LeftLeg_2.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                            
                            Torso_3.Name = "Torso"
                            Torso_3.Parent = R6
                            Torso_3.Size = UDim2.new(0, 76, 0, 103)
                            Torso_3.BorderColor3 = Color3.fromRGB(36, 36, 36)
                            Torso_3.Position = UDim2.new(0.322580636, 0, 0.27922079, 0)
                            Torso_3.BorderSizePixel = 2
                            Torso_3.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
                            Torso_3.TextColor3 = Color3.fromRGB(0, 0, 0)
                            Torso_3.Text = ""
                            Torso_3.TextSize = 14
                            Torso_3.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                            
                            HumanoidRootPart_2.Name = "HumanoidRootPart"
                            HumanoidRootPart_2.Parent = R6
                            HumanoidRootPart_2.Size = UDim2.new(0, 31, 0, 30)
                            HumanoidRootPart_2.BorderColor3 = Color3.fromRGB(36, 36, 36)
                            HumanoidRootPart_2.Position = UDim2.new(0.42396313, 0, 0.373376638, 0)
                            HumanoidRootPart_2.BorderSizePixel = 2
                            HumanoidRootPart_2.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
                            HumanoidRootPart_2.TextColor3 = Color3.fromRGB(0, 0, 0)
                            HumanoidRootPart_2.Text = ""
                            HumanoidRootPart_2.TextSize = 14
                            HumanoidRootPart_2.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                        
                            local function R15_function()
                                for _, bodypart in pairs(R15:GetChildren()) do
                                    bodypart.AutoButtonColor = false
                        
                                    local name = bodypart.Name
                                    --if string.find(name, "frame") then continue end
                        
                                    local self_conn = nil
                                    local function ButtonClick()
                                        tweenService:Create(bodypart, TweenInfo.new(0.2), { BackgroundColor3 = theme.accent }):Play()
                                        BoneSelector["FValues"][name].Selected = true
                        
                                        if not self_conn then
                                            self_conn = theme_event.Event:Connect(function ()
                                                if BoneSelector["FValues"][name].Selected then
                                                    bodypart.BackgroundColor3 = theme.accent
                                                end
                                            end)
                                        end
                                    end
                        
                                    local function ButtonUnClick()
                                        tweenService:Create(bodypart, TweenInfo.new(0.2), { BackgroundColor3 = Color3FromRGB(27, 27, 27) }):Play()
                                        BoneSelector["FValues"][name].Selected = false
                        
                                        if self_conn then
                                            self_conn:Disconnect(); self_conn = nil
                                        end
                                    end
                        
                                    bodypart.MouseButton1Click:Connect(function ()
                                        BoneSelectorOptions:Set(name)
                                    end)
                        
                                    BoneSelector["FValues"][name] = {
                                        Click = ButtonClick,
                                        UnClick = ButtonUnClick,
                                        Selected = false,
                                    }
                                end
                            end
                        
                            local function R6_FUNCTION()
                                for _, bodypart in pairs(R6:GetChildren()) do
                                    local name = bodypart.Name
                        
                                    local self_conn = nil
                                    local function ButtonClick()
                                        bodypart.BackgroundColor3 = theme.accent
                                        BoneSelector["FValues"][name].Selected = true
                        
                                        if not self_conn then
                                            self_conn = theme_event.Event:Connect(function ()
                                                if BoneSelector["FValues"][name].Selected then
                                                    bodypart.BackgroundColor3 = theme.accent
                                                end
                                            end)
                                        end
                                    end
                        
                                    local function ButtonUnClick()
                                        bodypart.BackgroundColor3 = Color3FromRGB(27, 27, 27)
                                        BoneSelector["FValues"][name].Selected = false
                        
                                        if self_conn then
                                            self_conn:Disconnect(); self_conn = nil
                                        end
                                    end
                        
                                    bodypart.MouseButton1Click:Connect(function ()
                                        BoneSelectorOptions:Set(name)
                                    end)
                        
                                    BoneSelector["FValues"][name] = {
                                        Click = ButtonClick,
                                        UnClick = ButtonUnClick,
                                        Selected = false,
                                    }
                        
                        
                                end
                            end
                        
                            R15_function()
                        
                            function BoneSelectorOptions:Update()
                                for _, v in pairs(BoneSelector.FValues) do
                                    if BoneSelector.FValue == _ then
                                        v.Click()
                                    else
                                        v.UnClick()
                                    end
                                end
                        
                                return BoneSelector
                            end
                        
                            function BoneSelectorOptions:Set(value)
                                if BoneSelectorOptions.Multi then
                                    if type(value) == "table" then
                                        BoneSelectorOptions:Refresh()
                            
                                        for _,v in pairs(value) do
                                            if not table.find(BoneSelector.FValue, _) then
                                                BoneSelectorOptions:Set(v)
                                            end
                                        end
                            
                                        local RemovedButtons = {}
                            
                                        for _,v in pairs(BoneSelector.FValue) do
                                            if not table.find(value, _) then
                                                RemovedButtons[#RemovedButtons + 1] = v
                                            end
                                        end
                            
                                        pcall(BoneSelectorOptions.Callback, BoneSelector.FValue)
                                        UserInterface.Flags[BoneSelectorOptions.Flag] = BoneSelector.FValue
                                        UserInterface.Flags[BoneSelectorOptions.Flag .. "f"] = { [1] = function(value)  end, [2] = function(value) BoneSelectorOptions:Set(value) end }
                            
                                        return
                                    end
                            
                                    local Index = table.find(BoneSelector.FValue, value)
                            
                                    if Index then
                                        table.remove(BoneSelector.FValue, Index)
                            
                                        BoneSelector.FValues[value].UnClick()
                            
                                        pcall(BoneSelectorOptions.Callback, BoneSelector.FValue)
                                        UserInterface.Flags[BoneSelectorOptions.Flag] = BoneSelector.FValue
                                        UserInterface.Flags[BoneSelectorOptions.Flag .. "f"] = { [1] = function() BoneSelectorOptions:Refresh() end, [2] = function(value) BoneSelectorOptions:Set(value) end }
                                    else
                                        BoneSelector.FValue[#BoneSelector.FValue + 1] = value
                            
                                        BoneSelector.FValues[value].Click()
                            
                                        pcall(BoneSelectorOptions.Callback, BoneSelector.FValue)
                                        UserInterface.Flags[BoneSelectorOptions.Flag] = BoneSelector.FValue
                                        UserInterface.Flags[BoneSelectorOptions.Flag .. "f"] = { [1] = function() BoneSelectorOptions:Refresh() end, [2] = function(value) BoneSelectorOptions:Set(value) end }
                                    end
                                else
                                    BoneSelector.FValue = value
                        
                                    for _, v in pairs(BoneSelector.FValues) do
                                        v.UnClick()
                                    end
                                    BoneSelector["FValues"][BoneSelector.FValue].Click()
                        
                                    pcall(BoneSelectorOptions.Callback, BoneSelector.FValue)
                                    UserInterface.Flags[BoneSelectorOptions.Flag] = BoneSelector.FValue
                                    UserInterface.Flags[BoneSelectorOptions.Flag .. "f"] = { [1] = function() BoneSelectorOptions:Refresh() end, [2] = function(value) BoneSelectorOptions:Set(value) end }
                                end 
                            end
                        
                            function BoneSelectorOptions:GetValues()
                                return BoneSelector.FValue
                            end
                        
                            function BoneSelectorOptions:Refresh()
                                for i, v in next, BoneSelector.FValues do
                                    if v.UnClick then
                                        v.UnClick()
                                    end
                                end
                            end
                        
                            function BoneSelectorOptions:SetMulti(bool)
                                if BoneSelectorOptions.Multi == bool then return end
                                self:Refresh()
                                BoneSelectorOptions.Multi = bool
                                BoneSelector.FValue = bool and {} or ""
                            end
                        
                            UserInterface.ConfigFlags[BoneSelectorOptions.Flag] = function(state) BoneSelectorOptions:Set(state) end
                            increaseYSize(308)
                            return BoneSelectorOptions
                        end
                    end
                    do -- src/Lua/Interface/Components/Button.lua
                        function Options:Button(Configuration)
                            local ButtonOptions = {
                                title = Configuration.title or "button",
                                callback = Configuration.callback or function () end
                            }
                            
                            local Button = InstanceNew("TextButton")
                            local ButtonCorner = InstanceNew("UICorner")
                        
                            Button.Name = "Button"
                            Button.Parent = SectionColumnComponents
                            Button.BackgroundColor3 = Color3FromRGB(21, 21, 21)
                            Button.BorderColor3 = Color3FromRGB(0, 0, 0)
                            Button.BorderSizePixel = 0
                            Button.Size = UDim2New(0, 159, 0, 23)
                            Button.AutoButtonColor = false
                            Button.FontFace = Font.new([[rbxasset://fonts/families/SourceSansPro.json]])
                            Button.Text = ButtonOptions.title
                            Button.TextColor3 = Color3FromRGB(255, 255, 255)
                            Button.TextSize = 14
                            Button.TextStrokeTransparency = 0
                            Button.TextWrapped = true
                        
                            ButtonCorner.CornerRadius = UDim.new(0, 2)
                            ButtonCorner.Name = "ButtonCorner"
                            ButtonCorner.Parent = Button
                        
                            local ButtonStroke = InstanceNew("UIStroke", Button)
                            ButtonStroke["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border
                            ButtonStroke["Name"] = [[ButtonStroke]]
                            ButtonStroke["Color"] = Color3FromRGB(37, 37, 37)
                            
                            local Tweens = {
                                OnClick = function ()
                                    local ButtonTween, ButtonStrokeTween = 
                                    tweenService:Create(Button, TweenInfo.new(0), {BackgroundColor3 = Color3FromRGB(36, 36, 36)}),
                                    tweenService:Create(ButtonStroke, TweenInfo.new(0), {Color = Color3FromRGB(45, 43, 46)})
                                    ButtonTween:Play();ButtonStrokeTween:Play()
                                end,
                                OnHover = function ()
                                    local ButtonTween, ButtonStrokeTween = 
                                    tweenService:Create(Button, TweenInfo.new(0), {BackgroundColor3 = Color3FromRGB(28, 28, 28)}),
                                    tweenService:Create(ButtonStroke, TweenInfo.new(0), {Color = Color3FromRGB(36, 36, 36)})
                                    ButtonTween:Play();ButtonStrokeTween:Play()
                                end,
                                OnMouseLeave = function ()
                                    local ButtonTween, ButtonStrokeTween = 
                                    tweenService:Create(Button, TweenInfo.new(0), {BackgroundColor3 = Color3FromRGB(21, 21, 21)}),
                                    tweenService:Create(ButtonStroke, TweenInfo.new(0), {Color = Color3FromRGB(40, 40, 40)})
                                    ButtonTween:Play();ButtonStrokeTween:Play()
                                end
                            }
                        
                            local function OnClick()
                                Tweens.OnClick()
                                pcall(ButtonOptions.callback)
                        
                                TaskWait(0.1)
                                Tweens.OnHover()
                            end
                        
                            Button.MouseButton1Click:Connect(OnClick)
                            Button.MouseEnter:Connect(Tweens.OnHover)
                            Button.MouseLeave:Connect(Tweens.OnMouseLeave)
                        
                            increaseYSize(23)
                        end
                    end
                    do -- src/Lua/Interface/Components/Colorpicker.lua
                        function Options:Colorpicker(Configuration, ToggleOption)
                            local ColorpickerOptions = {
                                Title = Configuration.title or "colorpicker",
                                Default = Configuration.default or Color3FromRGB(255,255,255),
                                Transparency = Configuration.transparency or 0,
                                Callback = Configuration.callback or function() end,
                                Flag = UserInterface:GetNextFlag()
                            }
                        
                            local Colorpicker = {
                                TransparencyValue = 0,
                        		ColorValue = nil,
                        		HuePosition = 0,
                                SlidingSat = false,
                        		SlidingHue = false,
                        		SlidingAlpha = false,
                            }
                        
                            local ColorpickerHolder = InstanceNew("Frame")
                            local ColorpickerTitle = InstanceNew("TextLabel")
                            local ColorpickerButton = InstanceNew("TextButton")
                            local ColorpickerStatus = InstanceNew("Frame")
                            local ColorpickerInline = InstanceNew("Frame")
                            local CPInlineCorner = InstanceNew("UICorner")
                            local ColorpickerContent = InstanceNew("Frame")
                            local Accent = InstanceNew("Frame")
                            local HueBackground = InstanceNew("Frame")
                            local CPHueGradient = InstanceNew("UIGradient")
                            local HuePicker = InstanceNew("ImageLabel")
                            local TextButton = InstanceNew("TextButton")
                            local SaturationBackground = InstanceNew("Frame")
                            local SaturationImage = InstanceNew("ImageLabel")
                            local SaturationPicker = InstanceNew("ImageLabel")
                            local SaturationButton = InstanceNew("TextButton")
                            local TransparencyBackground = InstanceNew("Frame")
                            local TransparencyGradient = InstanceNew("UIGradient")
                            local TransparencyPicker = InstanceNew("ImageLabel")
                            local TransparencyButton = InstanceNew("TextButton")
                        
                            ColorpickerHolder.Name = tostring(math.random(1000, 16384))
                            ColorpickerHolder.Parent = ToggleOption == nil and SectionColumnComponents or ToggleOption
                            ColorpickerHolder.BackgroundColor3 = Color3FromRGB(255, 255, 255)
                            ColorpickerHolder.BackgroundTransparency = 1.000
                            ColorpickerHolder.BorderColor3 = Color3FromRGB(0, 0, 0)
                            ColorpickerHolder.BorderSizePixel = 0
                            ColorpickerHolder.Size = UDim2New(0, 229, 0, 13)
                            
                            if ToggleOption == nil then
                                ColorpickerTitle.Name = "ColorpickerTitle"
                                ColorpickerTitle.Parent = ColorpickerHolder
                                ColorpickerTitle.BackgroundColor3 = Color3FromRGB(255, 255, 255)
                                ColorpickerTitle.BackgroundTransparency = 1.000
                                ColorpickerTitle.BorderColor3 = Color3FromRGB(0, 0, 0)
                                ColorpickerTitle.BorderSizePixel = 0
                                ColorpickerTitle.Size = UDim2New(0, 216, 0, 13)
                                ColorpickerTitle.Font = Enum.Font.SourceSans
                                ColorpickerTitle.Text = ColorpickerOptions.Title
                                ColorpickerTitle.TextColor3 = Color3FromRGB(255, 255, 255)
                                ColorpickerTitle.TextSize = 14.000
                                ColorpickerTitle.TextXAlignment = Enum.TextXAlignment.Left 
                            end
                            
                            ColorpickerButton.Name = "ColorpickerButton"
                            ColorpickerButton.Parent = ColorpickerHolder
                            ColorpickerButton.BackgroundColor3 = Color3FromRGB(255, 255, 255)
                            ColorpickerButton.BackgroundTransparency = 1.000
                            ColorpickerButton.BorderColor3 = Color3FromRGB(0, 0, 0)
                            ColorpickerButton.BorderSizePixel = 0
                            ColorpickerButton.Position = UDim2New(0.943231463, 0, 0, 0)
                            ColorpickerButton.Size = UDim2New(0, 13, 0, 13)
                            ColorpickerButton.Font = Enum.Font.SourceSans
                            ColorpickerButton.Text = ""
                            ColorpickerButton.TextColor3 = Color3FromRGB(0, 0, 0)
                            ColorpickerButton.TextSize = 14.000
                            
                            ColorpickerStatus.Name = "ColorpickerStatus"
                            ColorpickerStatus.Parent = ColorpickerHolder
                            ColorpickerStatus.BackgroundColor3 = Color3FromRGB(170, 170, 255)
                            ColorpickerStatus.BorderColor3 = Color3FromRGB(0, 0, 0)
                            ColorpickerStatus.BorderSizePixel = 0
                            ColorpickerStatus.Position = UDim2New(0.943231463, 0, 0, 0)
                            ColorpickerStatus.Size = UDim2New(0, 13, 0, 13)
                            
                            ColorpickerInline.Name = "ColorpickerInline"
                            ColorpickerInline.Parent = ColorpickerHolder
                            ColorpickerInline.BackgroundColor3 = Color3FromRGB(170, 170, 255)
                            ColorpickerInline.BackgroundTransparency = 1.000
                            ColorpickerInline.BorderColor3 = Color3FromRGB(0, 0, 0)
                            ColorpickerInline.BorderSizePixel = 0
                            ColorpickerInline.Position = UDim2New(0.943231463, 0, 0, 0)
                            ColorpickerInline.Size = UDim2New(0, 13, 0, 13)
                            ColorpickerInline.Visible = false
                            ColorpickerInline.ZIndex = 3
                            
                            CPInlineCorner.CornerRadius = UDim.new(0, 2)
                            CPInlineCorner.Name = "CPInlineCorner"
                            CPInlineCorner.Parent = ColorpickerInline
                        
                            local ColorpickerStatusCorner = InstanceNew("UICorner")
                            ColorpickerStatusCorner.CornerRadius = UDim.new(0, 4)
                            ColorpickerStatusCorner.Name = "ColorpickerStatusCorner"
                            ColorpickerStatusCorner.Parent = ColorpickerStatus
                            
                            ColorpickerContent.Name = "ColorpickerContent"
                            ColorpickerContent.Parent = ColorpickerInline
                            ColorpickerContent.BackgroundColor3 = Color3FromRGB(23, 23, 23)
                            ColorpickerContent.BorderColor3 = Color3FromRGB(0, 0, 0)
                            ColorpickerContent.Position = UDim2New(-9.46153831, 0, 0, 0)
                            ColorpickerContent.Size = UDim2New(0, 136, 0, 139)
                            ColorpickerContent.ZIndex = 3
                        
                            Accent.Name = "Accent"
                            Accent.Parent = ColorpickerContent
                            Accent.BackgroundColor3 = Color3FromRGB(168, 157, 159)
                            Accent.BorderColor3 = Color3FromRGB(0, 0, 0)
                            Accent.Size = UDim2New(1, 0, 0, 1)
                            
                            HueBackground.Name = "HueBackground"
                            HueBackground.Parent = ColorpickerContent
                            HueBackground.BackgroundColor3 = Color3FromRGB(255, 255, 255)
                            HueBackground.BorderColor3 = Color3FromRGB(0, 0, 0)
                            HueBackground.BorderSizePixel = 0
                            HueBackground.Position = UDim2New(0.879000008, 0, 0.0680000037, 0)
                            HueBackground.Size = UDim2New(0, 9, 0, 106)
                            
                            CPHueGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3FromRGB(255, 0, 0)), ColorSequenceKeypoint.new(0.17, Color3FromRGB(255, 0, 255)), ColorSequenceKeypoint.new(0.33, Color3FromRGB(0, 0, 255)), ColorSequenceKeypoint.new(0.50, Color3FromRGB(0, 255, 255)), ColorSequenceKeypoint.new(0.67, Color3FromRGB(0, 255, 0)), ColorSequenceKeypoint.new(0.83, Color3FromRGB(255, 255, 0)), ColorSequenceKeypoint.new(1.00, Color3FromRGB(255, 0, 0))}
                            CPHueGradient.Rotation = 90
                            CPHueGradient.Name = "CPHueGradient"
                            CPHueGradient.Parent = HueBackground
                            
                            HuePicker.Name = "HuePicker"
                            HuePicker.Parent = HueBackground
                            HuePicker.BackgroundColor3 = Color3FromRGB(255, 255, 255)
                            HuePicker.BackgroundTransparency = 1
                            HuePicker.BorderColor3 = Color3FromRGB(0, 0, 0)
                            HuePicker.BorderSizePixel = 0
                            HuePicker.Position = UDim2New(0, -4, 0, -2)
                            HuePicker.Size = UDim2New(0, 17, 0, 5)
                            HuePicker.Image = "rbxassetid://13900818694"
                            
                            TextButton.Parent = HueBackground
                            TextButton.BackgroundColor3 = Color3FromRGB(255, 255, 255)
                            TextButton.BackgroundTransparency = 1.000
                            TextButton.BorderColor3 = Color3FromRGB(0, 0, 0)
                            TextButton.BorderSizePixel = 0
                            TextButton.Size = UDim2New(1, 0, 1, 0)
                            TextButton.Font = Enum.Font.SourceSans
                            TextButton.Text = ""
                            TextButton.TextColor3 = Color3FromRGB(0, 0, 0)
                            TextButton.TextSize = 14.000
                            
                            SaturationBackground.Name = "SaturationBackground"
                            SaturationBackground.Parent = ColorpickerContent
                            SaturationBackground.BackgroundColor3 = Color3FromRGB(255, 255, 255)
                            SaturationBackground.BorderColor3 = Color3FromRGB(0, 0, 0)
                            SaturationBackground.Position = UDim2New(0.0661764741, 0, 0.0676691756, 0)
                            SaturationBackground.Size = UDim2New(0, 102, 0, 106)
                            
                            SaturationImage.Name = "SaturationImage"
                            SaturationImage.Parent = SaturationBackground
                            SaturationImage.BackgroundColor3 = Color3FromRGB(255, 255, 255)
                            SaturationImage.BackgroundTransparency = 1.000
                            SaturationImage.BorderColor3 = Color3FromRGB(0, 0, 0)
                            SaturationImage.Size = UDim2New(1, 0, 1, 0)
                            SaturationImage.Image = "rbxassetid://13901004307"
                            
                            SaturationPicker.Name = "SaturationPicker"
                            SaturationPicker.Parent = SaturationBackground
                            SaturationPicker.BackgroundColor3 = Color3FromRGB(255, 255, 255)
                            SaturationPicker.BackgroundTransparency = 1.000
                            SaturationPicker.BorderColor3 = Color3FromRGB(0, 0, 0)
                            SaturationPicker.Position = UDim2New(0, -1, 0, -1)
                            SaturationPicker.Size = UDim2New(0, 5, 0, 5)
                            SaturationPicker.Image = "rbxassetid://13900819741"
                            
                            SaturationButton.Name = "SaturationButton"
                            SaturationButton.Parent = SaturationBackground
                            SaturationButton.BackgroundColor3 = Color3FromRGB(255, 255, 255)
                            SaturationButton.BackgroundTransparency = 1.000
                            SaturationButton.BorderColor3 = Color3FromRGB(0, 0, 0)
                            SaturationButton.BorderSizePixel = 0
                            SaturationButton.Size = UDim2New(1, 0, 1, 0)
                            SaturationButton.Font = Enum.Font.SourceSans
                            SaturationButton.Text = ""
                            SaturationButton.TextColor3 = Color3FromRGB(0, 0, 0)
                            SaturationButton.TextSize = 14.000
                            
                            TransparencyBackground.Name = "TransparencyBackground"
                            TransparencyBackground.Parent = ColorpickerContent
                            TransparencyBackground.BackgroundColor3 = Color3FromRGB(255, 255, 255)
                            TransparencyBackground.BorderColor3 = Color3FromRGB(0, 0, 0)
                            TransparencyBackground.BorderSizePixel = 0
                            TransparencyBackground.Position = UDim2New(0.0441176482, 0, 0.880901992, 0)
                            TransparencyBackground.Size = UDim2New(0, 123, 0, 6)
                            
                            TransparencyGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3FromRGB(255, 255, 255)), ColorSequenceKeypoint.new(0.57, Color3FromRGB(150, 150, 150)), ColorSequenceKeypoint.new(1.00, Color3FromRGB(0, 0, 0))}
                            TransparencyGradient.Name = "TransparencyGradient"
                            TransparencyGradient.Parent = TransparencyBackground
                            
                            TransparencyPicker.Name = "TransparencyPicker"
                            TransparencyPicker.Parent = TransparencyBackground
                            TransparencyPicker.BackgroundColor3 = Color3FromRGB(255, 255, 255)
                            TransparencyPicker.BackgroundTransparency = 1.000
                            TransparencyPicker.BorderColor3 = Color3FromRGB(0, 0, 0)
                            TransparencyPicker.BorderSizePixel = 0
                            TransparencyPicker.Position = UDim2New(0, -2, 0, -2)
                            TransparencyPicker.Size = UDim2New(0, 5, 0, 17)
                            TransparencyPicker.Image = "rbxassetid://14248606745"
                            
                            TransparencyButton.Name = "TransparencyButton"
                            TransparencyButton.Parent = TransparencyBackground
                            TransparencyButton.BackgroundColor3 = Color3FromRGB(255, 255, 255)
                            TransparencyButton.BackgroundTransparency = 1.000
                            TransparencyButton.BorderColor3 = Color3FromRGB(0, 0, 0)
                            TransparencyButton.BorderSizePixel = 0
                            TransparencyButton.Size = UDim2New(1, 0, 1, 0)
                            TransparencyButton.Font = Enum.Font.SourceSans
                            TransparencyButton.Text = ""
                            TransparencyButton.TextColor3 = Color3FromRGB(0, 0, 0)
                            TransparencyButton.TextSize = 14.000
                        
                            for _, object in next, ColorpickerContent:GetDescendants() do
                                if object:IsA("UIGradient") then continue end
                        
                                if object.ZIndex then
                                    object.ZIndex = 3
                                end
                            end
                        
                            local Hue, Sat, Val = ColorpickerOptions.Default:ToHSV()
                        
                            local contentAnimations = {
                                Open = function ( self )
                                    ColorpickerContent.Visible = true
                                    ColorpickerInline.Visible = true
                        
                                    local ContentTween = tweenService:Create(ColorpickerContent, TweenInfo.new(0.15), { BackgroundTransparency = 0,  Position = UDim2New(-10.923, 0,0, 0) })
                                    ContentTween:Play()
                                    self:FadeIn()
                                end,
                                FadeIn = function ()
                                    for _, object in pairs( ColorpickerContent:GetDescendants() ) do
                                        if object:IsA("Frame") then
                                            tweenService:Create(object, TweenInfo.new(0.15), { BackgroundTransparency = 0 }):Play()
                                        elseif object:IsA("ImageLabel") then
                                            tweenService:Create(object, TweenInfo.new(0.15), { ImageTransparency = 0 }):Play()
                                        end
                                    end
                                end,
                                FadeOut = function ()
                                    for _, object in pairs( ColorpickerContent:GetDescendants() ) do
                                        if object:IsA("Frame") then
                                            tweenService:Create(object, TweenInfo.new(0.15), { BackgroundTransparency = 1 }):Play()
                                        elseif object:IsA("ImageLabel") then
                                            tweenService:Create(object, TweenInfo.new(0.15), { ImageTransparency = 1 }):Play()
                                        end
                                    end
                                end
                            }
                        
                            -- to those who code, they will understand why I did this.
                            function contentAnimations:Close()
                                local ContentTween = tweenService:Create(ColorpickerContent, TweenInfo.new(0.15), { BackgroundTransparency = 1, Position = UDim2New(-9.46153831, 0,0, 0) })
                                ContentTween:Play()
                        
                                contentAnimations:FadeOut()
                        
                                TaskWait(0.15)
                        
                                ColorpickerContent.Visible = false
                                ColorpickerInline.Visible = false
                            end
                        
                            local function FromRGBA (r, g, b)
                                local rgb = Color3FromRGB(r, g, b)
                            
                                return rgb
                            end
                        
                            function ColorpickerOptions:Set(color, trans, ignore)
                                if not ColorpickerOptions.Transparency then
                                    Colorpicker.TransparencyValue = 1
                                end
                        
                                trans = trans or Colorpicker.TransparencyValue
                        
                                if typeof(color) == "table" then
                                    local OldColor = color
                        
                                    color = Color3.fromHex(OldColor[1])
                                    --trans = OldColor[2]
                                end
                        
                                Hue, Sat, Val = color:ToHSV()
                        
                                Colorpicker.ColorValue = color
                                Colorpicker.TransparencyValue = trans
                        
                                SaturationBackground.BackgroundColor3 = Color3.fromHSV(Colorpicker.HuePosition, 1, 1)
                                
                                ColorpickerStatus.BackgroundColor3 = color
                                
                                if not ignore then
                                    SaturationPicker.Position = UDim2New(0, math.clamp(Sat * SaturationBackground.AbsoluteSize.X, 0, SaturationBackground.AbsoluteSize.X - 3), 0, math.clamp(SaturationBackground.AbsoluteSize.Y - Val * SaturationBackground.AbsoluteSize.Y, 0, SaturationBackground.AbsoluteSize.Y - 3))
                                    Colorpicker.HuePosition = Hue
                                    HuePicker.Position = UDim2New(0, -2, 1 - Hue, -2)
                                end
                                pcall(ColorpickerOptions.Callback, FromRGBA(color.R * 255, color.G * 255, color.B * 255), trans)
                                UserInterface.Flags[ColorpickerOptions.Flag] = FromRGBA(color.R * 255, color.G * 255, color.B * 255)
                            end
                            ColorpickerOptions:Set(ColorpickerOptions.Default, ColorpickerOptions.Transparency)
                            
                            local function SlideSaturation(input)
                                local SizeX = math.clamp((input.Position.X - SaturationBackground.AbsolutePosition.X) / SaturationBackground.AbsoluteSize.X, 0, 1)
                                local SizeY = 1 - math.clamp((input.Position.Y - SaturationBackground.AbsolutePosition.Y) / SaturationBackground.AbsoluteSize.Y, 0, 1)
                                local PosY = math.clamp(((input.Position.Y - SaturationBackground.AbsolutePosition.Y) / SaturationBackground.AbsoluteSize.Y) * SaturationBackground.AbsoluteSize.Y, 0, SaturationBackground.AbsoluteSize.Y - 3)
                                local PosX = math.clamp(((input.Position.X - SaturationBackground.AbsolutePosition.X) / SaturationBackground.AbsoluteSize.X) * SaturationBackground.AbsoluteSize.X, 0, SaturationBackground.AbsoluteSize.X - 3)
                                
                                SaturationPicker.Position = UDim2New(0, PosX, 0, PosY)
                                ColorpickerOptions:Set(Color3.fromHSV(Colorpicker.HuePosition, SizeX, SizeY), Colorpicker.TransparencyValue, true)
                            end
                        
                            SaturationButton.MouseButton1Down:Connect(function (input)
                                Colorpicker.SlidingSat = true
                        
                                SlideSaturation({ Position = game.UserInputService:GetMouseLocation() - Vector2New(0, 36) })
                            end)
                        
                            local function SlideHue(input)
                                local SizeY = 1 - math.clamp((input.Position.Y - HueBackground.AbsolutePosition.Y) / HueBackground.AbsoluteSize.Y, 0, 1)
                                local PosY = math.clamp(((input.Position.Y - HueBackground.AbsolutePosition.Y) / HueBackground.AbsoluteSize.Y) * HueBackground.AbsoluteSize.Y, 0, HueBackground.AbsoluteSize.Y - 2)
                            
                                HuePicker.Position = UDim2New(0, -2, 0, PosY - 2)
                                Colorpicker.HuePosition = SizeY
                        
                                ColorpickerOptions:Set(Color3.fromHSV(SizeY, Sat, Val), Colorpicker.TransparencyValue, true)
                            end
                        
                            TextButton.MouseButton1Down:Connect(function (input)
                                Colorpicker.SlidingHue = true
                        
                                SlideHue({ Position = game.UserInputService:GetMouseLocation() - Vector2New(0, 36) })
                            end)
                        
                            local function SlideTrans(input)
                                local SizeX = 1 - math.clamp((input.Position.X - TransparencyBackground.AbsolutePosition.X) / TransparencyBackground.AbsoluteSize.X, 0, 1)
                                local PosX = math.clamp(((input.Position.X - TransparencyBackground.AbsolutePosition.X) / TransparencyBackground.AbsoluteSize.X) * TransparencyBackground.AbsoluteSize.X, 0, TransparencyBackground.AbsoluteSize.X - 3)
                        
                                TransparencyPicker.Position = UDim2New(0, PosX, 0, -2)
                        
                                ColorpickerOptions:Set(Color3.fromHSV(Colorpicker.HuePosition, Sat, Val), SizeX, true)
                            end
                        
                            TransparencyButton.MouseButton1Down:Connect(function (input)
                                Colorpicker.SlidingAlpha = true
                        
                                SlideTrans({ Position = game.UserInputService:GetMouseLocation() - Vector2New(0, 36) })
                            end)
                        
                            inputService.InputEnded:Connect(function (input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                    Colorpicker.SlidingSat, Colorpicker.SlidingHue, Colorpicker.SlidingAlpha = false, false, false
                                end
                            end)
                        
                            inputService.InputChanged:Connect(function (input)
                                if input.UserInputType == Enum.UserInputType.MouseMovement then
                                    if Colorpicker.SlidingSat then
                                        SlideSaturation(input)
                                    elseif Colorpicker.SlidingHue then
                                        SlideHue(input)
                                    elseif Colorpicker.SlidingAlpha then
                                        SlideTrans(input)
                                    end
                                end
                            end)
                        
                            ColorpickerButton.MouseButton1Click:Connect(function ()
                                if UserInterface.Popup and UserInterface.Popup.ID ~= ColorpickerHolder.Name then
                                    UserInterface:RemovePopups()
                                end
                                if ColorpickerInline.Visible then
                                    contentAnimations:Close()
                                else
                                    UserInterface:NewPopup({ Remove = contentAnimations.Close, ID = ColorpickerHolder.Name })
                                    contentAnimations:Open()
                                end
                            end)
                        
                            increaseYSize(13)
                        
                            UserInterface.ConfigFlags[ColorpickerOptions.Flag] = function(value) ColorpickerOptions:Set(value) end
                        
                            return ColorpickerOptions
                        end
                    end
                    do -- src/Lua/Interface/Components/Dropdowns.lua
                        function Options:Dropdown(Configuration)
                            local DropdownOptions = {
                                Title = Configuration.title or "",
                                Content = Configuration.values or {},
                                Default = Configuration.default or "-",
                                Multi = Configuration.multi or false,
                                Callback = Configuration.callback or function () end,
                                Flag = UserInterface:GetNextFlag()
                            }
                        
                            local Dropdown = {
                                FValues = {},
                                FValue = DropdownOptions.Multi and {} or "",
                            }
                        
                            local DropdownHolder = InstanceNew("Frame")
                            local DropdownTitle = InstanceNew("TextLabel")
                        
                            DropdownHolder.Name = tostring(math.random(100, 16030))
                            DropdownHolder.Parent = SectionColumnComponents
                            DropdownHolder.BackgroundColor3 = Color3FromRGB(255, 255, 255)
                            DropdownHolder.BackgroundTransparency = 1.000
                            DropdownHolder.BorderColor3 = Color3FromRGB(0, 0, 0)
                            DropdownHolder.BorderSizePixel = 0
                            DropdownHolder.Size = UDim2New(0, 229, 0, 40)
                            
                            DropdownTitle.Name = "DropdownTitle"
                            DropdownTitle.Parent = DropdownHolder
                            DropdownTitle.BackgroundColor3 = Color3FromRGB(255, 255, 255)
                            DropdownTitle.BackgroundTransparency = 1.000
                            DropdownTitle.BorderColor3 = Color3FromRGB(0, 0, 0)
                            DropdownTitle.BorderSizePixel = 0
                            DropdownTitle.Size = UDim2New(0, 164, 0, 13)
                            DropdownTitle.Font = Enum.Font.SourceSans
                            DropdownTitle.Text = DropdownOptions.Title
                            DropdownTitle.TextColor3 = Color3FromRGB(255, 255, 255)
                            DropdownTitle.TextSize = 14.000
                            DropdownTitle.TextXAlignment = Enum.TextXAlignment.Left
                        
                            local xcxcxcxcxc = InstanceNew("UIListLayout", DropdownHolder)
                            xcxcxcxcxc["Padding"] = UDim.new(0, 5)
                            xcxcxcxcxc["SortOrder"] = Enum.SortOrder.LayoutOrder
                            xcxcxcxcxc["Name"] = [[ColumnListLayout]]
                            
                            local OpenButton = InstanceNew("TextButton")
                        	local OpenButtonCorner = InstanceNew("UICorner")
                        	local OpenButtonStroke = InstanceNew("UIStroke")
                        	local DropdownImage = InstanceNew("ImageLabel")
                        	local DropdownText = InstanceNew("TextLabel")
                        
                            OpenButton.Name = "OpenButton"
                            OpenButton.Parent = DropdownHolder
                            OpenButton.ZIndex = 2
                            OpenButton.Size = UDim2New(0, 230, 0, 22)
                            OpenButton.BorderColor3 = Color3FromRGB(34, 34, 34)
                            OpenButton.Position = UDim2New(0, 0, 0.576923072, 0)
                            OpenButton.BackgroundColor3 = Color3FromRGB(21, 21, 21)
                            OpenButton.AutoButtonColor = false
                            OpenButton.TextColor3 = Color3FromRGB(255, 255, 255)
                            OpenButton.Text = ""
                            OpenButton.TextXAlignment = Enum.TextXAlignment.Left
                            OpenButton.TextSize = 14
                            OpenButton.TextTruncate = Enum.TextTruncate.AtEnd
                            OpenButton.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                            
                            OpenButtonCorner.Name = "OpenButtonCorner"
                            OpenButtonCorner.Parent = OpenButton
                            OpenButtonCorner.CornerRadius = UDim.new(0, 3)
                            
                            OpenButtonStroke.Name = "OpenButtonStroke"
                            OpenButtonStroke.Parent = OpenButton
                            OpenButtonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                            OpenButtonStroke.Color = Color3FromRGB(15, 15, 15)
                            
                            DropdownImage.Name = "DropdownImage"
                            DropdownImage.Parent = OpenButton
                            DropdownImage.ZIndex = 3
                            DropdownImage.Size = UDim2New(0, 9, 0, 6)
                            DropdownImage.BorderColor3 = Color3FromRGB(0, 0, 0)
                            DropdownImage.BackgroundTransparency = 1
                            DropdownImage.Position = UDim2New(0.939999938, 0, 0.342727214, 0)
                            DropdownImage.BorderSizePixel = 0
                            DropdownImage.BackgroundColor3 = Color3FromRGB(255, 255, 255)
                            DropdownImage.Image = "rbxassetid://17830630301"
                            
                            DropdownText.Name = "DropdownText"
                            DropdownText.Parent = OpenButton
                            DropdownText.ZIndex = 3
                            DropdownText.Size = UDim2New(0, 204, 0, 22)
                            DropdownText.BorderColor3 = Color3FromRGB(0, 0, 0)
                            DropdownText.BackgroundTransparency = 1
                            DropdownText.Position = UDim2New(0.0130434781, 0, 0, 0)
                            DropdownText.BorderSizePixel = 0
                            DropdownText.BackgroundColor3 = Color3FromRGB(255, 255, 255)
                            DropdownText.TextColor3 = Color3FromRGB(255, 255, 255)
                            DropdownText.Text = DropdownOptions.Default
                            DropdownText.TextXAlignment = Enum.TextXAlignment.Left
                            DropdownText.TextSize = 14
                            DropdownText.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                            DropdownText.TextTruncate = "AtEnd"
                        
                            local Inline = InstanceNew("Frame")
                            local InlineCorner = InstanceNew("UICorner")
                            local InlineStroke = InstanceNew("UIStroke")
                            local InlineList = InstanceNew("UIListLayout")
                        
                            Inline.Name = "Inline"
                            Inline.Parent = OpenButton
                            Inline.Size = UDim2New(0, 229, 0, 0)
                            Inline.BorderColor3 = Color3FromRGB(0, 0, 0)
                            Inline.Position = UDim2New(0, 0, 1, 0)
                            Inline.BorderSizePixel = 0
                            Inline.BackgroundColor3 = Color3FromRGB(15, 15, 15)
                            Inline.Visible = false
                            Inline.ZIndex = 3
                            
                            InlineCorner.Name = "InlineCorner"
                            InlineCorner.Parent = Inline
                            InlineCorner.CornerRadius = UDim.new(0, 3)
                            
                            InlineStroke.Name = "InlineStroke"
                            InlineStroke.Parent = Inline
                            InlineStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                            InlineStroke.Color = Color3FromRGB(37, 37, 37)
                            
                            InlineList.Name = "InlineList"
                            InlineList.Parent = Inline
                        
                            local contentAnimations = {
                                Open = function ( self )
                                    Inline.Visible = true
                        
                                    local ImageRotation = tweenService:Create(DropdownImage, TweenInfo.new(0.15), { Rotation = 180 })
                                    ImageRotation:Play()
                        
                                    local ContentTween = tweenService:Create(Inline, TweenInfo.new(0.15), { BackgroundTransparency = 0 })
                                    ContentTween:Play()
                                    self:FadeIn()
                                end,
                                FadeIn = function ()
                                    for _, object in pairs( Inline:GetDescendants() ) do
                                        if object:IsA("Frame") then
                                            tweenService:Create(object, TweenInfo.new(0.15), { BackgroundTransparency = 0 }):Play()
                                        elseif object:IsA("TextButton") then
                                            tweenService:Create(object, TweenInfo.new(0.15), { TextTransparency = 0 }):Play()
                                        elseif object:IsA("UIStroke") then
                                            tweenService:Create(object, TweenInfo.new(0.15), { Transparency = 0 }):Play()
                                        elseif object:IsA("TextLabel") then
                                            tweenService:Create(object, TweenInfo.new(0.15), { TextTransparency = 0 }):Play()
                                        end
                                    end
                                end,
                                FadeOut = function ()
                                    for _, object in pairs( Inline:GetDescendants() ) do
                                        if object:IsA("Frame") then
                                            tweenService:Create(object, TweenInfo.new(0.15), { BackgroundTransparency = 1 }):Play()
                                        elseif object:IsA("TextButton") then
                                            tweenService:Create(object, TweenInfo.new(0.15), { TextTransparency = 1 }):Play()
                                        elseif object:IsA("TextLabel") then
                                            tweenService:Create(object, TweenInfo.new(0.15), { TextTransparency = 1 }):Play()
                                        elseif object:IsA("UIStroke") then
                                            tweenService:Create(object, TweenInfo.new(0.15), { Transparency = 1 }):Play()
                                        end
                                    end
                                end
                            }
                            
                            function contentAnimations:Close()
                                local ContentTween = tweenService:Create(Inline, TweenInfo.new(0.15), { BackgroundTransparency = 1 })
                                ContentTween:Play()
                        
                                local ImageRotation = tweenService:Create(DropdownImage, TweenInfo.new(0.15), { Rotation = 0 })
                                ImageRotation:Play()
                        
                                contentAnimations:FadeOut()
                        
                                TaskWait(0.15)
                        
                                Inline.Visible = false
                            end
                        
                            local Count = 0
                        
                            function Dropdown:CreateValue(name)
                                if not Dropdown.FValues[name] then
                                    local Objects = {}
                        
                                    local DropdownButton = InstanceNew("TextButton")
                                    local DBStroke = InstanceNew("UIStroke")
                                    local DBCorner = InstanceNew("UICorner")
                                    local DBName = InstanceNew("TextLabel")
                        
                                    DropdownButton.Name = "DropdownButton"
                                    DropdownButton.Parent = Inline
                                    DropdownButton.Size = UDim2.new(1, 0, 0, 14)
                                    DropdownButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
                                    DropdownButton.BackgroundTransparency = 1
                                    DropdownButton.Position = UDim2.new(0.0131004369, 0, 0, 0)
                                    DropdownButton.BorderSizePixel = 0
                                    DropdownButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                                    DropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                                    DropdownButton.Text = ""
                                    DropdownButton.TextXAlignment = Enum.TextXAlignment.Left
                                    DropdownButton.TextSize = 14
                                    DropdownButton.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                                    DropdownButton.TextTransparency = 1
                                    DropdownButton.ZIndex = 4
                        
                                    DBStroke.Name = "DBStroke"
                                    DBStroke.Parent = DropdownButton
                                    DBStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                                    DBStroke.Color = Color3.fromRGB(24, 24, 24)
                                    
                                    DBCorner.Name = "DBCorner"
                                    DBCorner.Parent = DropdownButton
                                    DBCorner.CornerRadius = UDim.new(0, 3)
                                    
                                    DBName.Name = "DBName"
                                    DBName.Parent = DropdownButton
                                    DBName.Size = UDim2.new(0, 226, 1, 0)
                                    DBName.BorderColor3 = Color3.fromRGB(0, 0, 0)
                                    DBName.BackgroundTransparency = 1
                                    DBName.Position = UDim2.new(0.0131004369, 0, 0, 0)
                                    DBName.BorderSizePixel = 0
                                    DBName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                                    DBName.TextColor3 = Color3.fromRGB(129, 129, 127)
                                    DBName.TextXAlignment = Enum.TextXAlignment.Left
                                    DBName.TextSize = 14
                                    DBName.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                                    DBName.Text = name
                                    DBName.ZIndex = 4
                        
                                    Objects.Name = DropdownButton
                        
                                    Inline.Size += UDim2.new(0, 0, 0, 14)
                        
                                    local function Click()
                                        DBName.TextColor3 = theme.accent
                                        Dropdown.FValues[name].Selected = true
                                    end
                        
                                    local function Unclick()
                                        DBName.TextColor3 = Color3.fromRGB(129, 129, 127)
                                        Dropdown.FValues[name].Selected = false
                                    end
                        
                                    DropdownButton.MouseButton1Down:Connect(function ()
                                        Dropdown:Set(name)
                                    end)
                                    
                                    Count += 1
                        
                                    Dropdown.FValues[name] = {
                                        Click = Click,
                                        Unclick = Unclick,
                                        Objects = Objects,
                                        Selected = false,
                                    }
                        
                                    theme_event.Event:Connect(function ()
                                        if Dropdown["FValues"][name].Selected then
                                            DBName.TextColor3 = theme.accent
                                        end
                                    end)
                                end
                        
                                return Dropdown
                            end
                        
                            function Dropdown:Update()
                                for _, v in pairs(Dropdown.FValues) do
                                    if Dropdown.FValue == _ then
                                        v.Click()
                                    else
                                        v.Unclick()
                                    end
                                end
                        
                                return Dropdown
                            end
                        
                            function Dropdown:Display()
                                if DropdownOptions.Multi then
                                    local CurrentText = {}
                        
                                    if #Dropdown.FValue > 0 then
                                        for _,v in pairs(Dropdown.FValue) do
                                            CurrentText[#CurrentText + 1] = v
                        
                                            local Text = table.concat(CurrentText, ", ")
                                            DropdownText.Text = Text
                                        end
                                    else
                                        DropdownText.Text = "-"
                                    end
                                else
                                    DropdownText.Text = Dropdown.FValue ~= "" and Dropdown.FValue or "-"
                                end
                        
                                return Dropdown
                            end
                        
                            function Dropdown:Set(value)
                                if DropdownOptions.Multi then
                                    if typeof(value) == "table" then
                                        for _,v in pairs(value) do
                                            if not table.find(Dropdown.FValue, _) then
                                                Dropdown:Set(v)
                                            end
                                        end
                        
                                        local RemovedButtons = {}
                        
                                        for _,v in pairs(Dropdown.FValue) do
                                            if not table.find(value, _) then
                                                RemovedButtons[#RemovedButtons + 1] = v
                                            end
                                        end
                        
                                        pcall(DropdownOptions.Callback, Dropdown.FValue)
                                        UserInterface.Flags[DropdownOptions.Flag] = Dropdown.FValue
                                        UserInterface.Flags[DropdownOptions.Flag .. "f"] = { [1] = function(value) Dropdown:Refresh(value) end, [2] = function(value) Dropdown:Set(value) end }
                        
                                        return
                                    end
                        
                                    local Index = table.find(Dropdown.FValue, value)
                        
                                    if Index then
                                        table.remove(Dropdown.FValue, Index)
                        
                                        Dropdown:Display()
                        
                                        Dropdown.FValues[value].Unclick()
                        
                                        pcall(DropdownOptions.Callback, Dropdown.FValue)
                                        UserInterface.Flags[DropdownOptions.Flag] = Dropdown.FValue
                                        UserInterface.Flags[DropdownOptions.Flag .. "f"] = { [1] = function(value) Dropdown:Refresh(value) end, [2] = function(value) Dropdown:Set(value) end }
                                    else
                                        Dropdown.FValue[#Dropdown.FValue + 1] = value
                        
                                        Dropdown:Display()
                        
                                        Dropdown.FValues[value].Click()
                        
                                        pcall(DropdownOptions.Callback, Dropdown.FValue)
                                        UserInterface.Flags[DropdownOptions.Flag] = Dropdown.FValue
                                        UserInterface.Flags[DropdownOptions.Flag .. "f"] = { [1] = function(value) Dropdown:Refresh(value) end, [2] = function(value) Dropdown:Set(value) end }
                                    end
                                else
                                    Dropdown.FValue = value
                        
                                    self:Update()
                        
                                    Dropdown:Display()
                                    pcall(DropdownOptions.Callback, Dropdown.FValue)
                                    UserInterface.Flags[DropdownOptions.Flag] = Dropdown.FValue
                                    UserInterface.Flags[DropdownOptions.Flag .. "f"] = { [1] = function(value) Dropdown:Refresh(value) end, [2] = function(value) Dropdown:Set(value) end }
                                end
                        
                                return Dropdown
                            end
                        
                            function Dropdown:Refresh(tbl)
                                for _,v in pairs(Dropdown.FValues) do
                                    v.Objects.Name:Destroy()
                                    v = nil
                                end
                        
                                Inline.Size = UDim2New(0, 229, 0, 0)
                                table.clear(Dropdown.FValues)
                        
                                if DropdownOptions.Multi then
                                    table.clear(Dropdown.FValue)
                                    Count = 0
                        
                                    for _,v in pairs(tbl) do
                                        Dropdown:CreateValue(v)
                                    end
                        
                                    Dropdown:Display()
                        
                                    pcall(DropdownOptions.Callback, Dropdown.FValue)
                                    UserInterface.Flags[DropdownOptions.Flag] = Dropdown.FValue
                                    UserInterface.Flags[DropdownOptions.Flag .. "f"] = { [1] = function(value) Dropdown:Refresh(value) end, [2] = function(value) Dropdown:Set(value) end }
                                else
                                    Count = 0
                        
                                    for _,v in pairs(tbl) do
                                        Dropdown:CreateValue(v)
                                    end
                        
                                    Dropdown.FValue = nil
                        
                                    Dropdown:Update()
                                    Dropdown:Display()
                        
                                    pcall(DropdownOptions.Callback, Dropdown.FValue)
                                    UserInterface.Flags[DropdownOptions.Flag] = Dropdown.FValue
                                    UserInterface.Flags[DropdownOptions.Flag .. "f"] = { [1] = function(value) Dropdown:Refresh(value) end, [2] = function(value) Dropdown:Set(value) end }
                                end
                        
                                for _, v in pairs(tbl) do
                                    Dropdown:CreateValue(v)
                                end
                            
                                Dropdown:Set(DropdownOptions.Default)
                        
                                return Dropdown
                            end
                        
                            for _, v in pairs(DropdownOptions.Content) do
                                Dropdown:CreateValue(v)
                            end
                        
                            Dropdown:Set(DropdownOptions.Default)
                        
                            OpenButton.MouseButton1Click:Connect(function ()
                                if UserInterface.Popup and UserInterface.Popup.ID ~= DropdownHolder.Name then
                                    UserInterface:RemovePopups()
                                end
                                if Inline.Visible then
                                    contentAnimations:Close()
                                    Inline.ZIndex = 3
                                else
                                    UserInterface:NewPopup({ Remove = contentAnimations.Close, ID = DropdownHolder.Name })
                                    Inline.ZIndex = 4
                                    contentAnimations:Open()
                                end
                            end)
                        
                            UserInterface.ConfigFlags[DropdownOptions.Flag] = function(state) Dropdown:Set(state) end
                        
                            increaseYSize(40)
                            return DropdownOptions, Dropdown
                        end
                    end
                    do -- src/Lua/Interface/Components/Keybind.lua
                        function Options:Keybind(Configuration, toggle)
                            
                            local KeybindOptions = {
                                Title = Configuration.title or "",
                                Mode = Configuration.mode or "Toggle",
                                Key = Configuration.key or "",
                                Callback = Configuration.callback or function() end,
                                KeybindsList = Configuration.keybindlist or false,
                                KeybindListName = Configuration.keybindname or self.Title,
                                Flag = UserInterface:GetNextFlag()
                            }
                        
                            local Keybind = {
                                FMode = KeybindOptions.Mode,
                                FKey = KeybindOptions.Key,
                                Toggled = false,
                                Picking = false,
                                Modes = {},
                            }
                        
                            local KeybindHolder = InstanceNew("Frame")
                            local KeybindButton = InstanceNew("TextButton")
                        
                            KeybindHolder.Name = tostring(math.random(1000, 16384))
                            KeybindHolder.Parent = toggle == nil and SectionColumnComponents or toggle
                            KeybindHolder.BackgroundColor3 = Color3FromRGB(255, 255, 255)
                            KeybindHolder.BackgroundTransparency = 1.000
                            KeybindHolder.BorderColor3 = Color3FromRGB(0, 0, 0)
                            KeybindHolder.BorderSizePixel = 0
                            KeybindHolder.Size = UDim2New(0, 229, 0, 14)
                            
                            if toggle == nil then
                                local KeybindTitle = InstanceNew("TextLabel")
                                KeybindTitle.Name = "KeybindTitle"
                                KeybindTitle.Parent = KeybindHolder
                                KeybindTitle.BackgroundColor3 = Color3FromRGB(255, 255, 255)
                                KeybindTitle.BackgroundTransparency = 1.000
                                KeybindTitle.BorderColor3 = Color3FromRGB(0, 0, 0)
                                KeybindTitle.BorderSizePixel = 0
                                KeybindTitle.Size = UDim2New(0, 161, 0, 14)
                                KeybindTitle.Font = Enum.Font.SourceSans
                                KeybindTitle.Text = KeybindOptions.Title
                                KeybindTitle.TextColor3 = Color3FromRGB(255, 255, 255)
                                KeybindTitle.TextSize = 14.000
                                KeybindTitle.TextXAlignment = Enum.TextXAlignment.Left
                            end
                        
                            KeybindButton.Name = "KeybindButton"
                            KeybindButton.Parent = KeybindHolder
                            KeybindButton.BackgroundColor3 = Color3FromRGB(21, 21, 21)
                            KeybindButton.BorderColor3 = Color3FromRGB(34, 34, 34)
                            KeybindButton.Position = UDim2New(0.703056753, 0, 0, 0)
                            KeybindButton.Size = UDim2New(0, 68, 0, 14)
                            KeybindButton.Font = Enum.Font.SourceSans
                            KeybindButton.Text = "key : NONE"
                            KeybindButton.TextColor3 = Color3FromRGB(255, 255, 255)
                            KeybindButton.TextSize = 14.000
                            KeybindButton.ZIndex = 2
                            KeybindButton.AutoButtonColor = false
                        
                            local KeybindInline = InstanceNew("Frame")
                            local KeybindContent = InstanceNew("Frame")
                            local KBContent = InstanceNew("UIListLayout")
                        
                            KeybindInline.Name = "KeybindInline"
                            KeybindInline.Parent = KeybindHolder
                            KeybindInline.BackgroundColor3 = Color3FromRGB(170, 170, 255)
                            KeybindInline.BackgroundTransparency = 1.000
                            KeybindInline.BorderColor3 = Color3FromRGB(0, 0, 0)
                            KeybindInline.BorderSizePixel = 0
                            KeybindInline.Position = UDim2New(0.943231463, 0, 0, 0)
                            KeybindInline.Size = UDim2New(0, 13, 0, 13)
                            KeybindInline.Visible = false
                            
                            KeybindContent.Name = "KeybindContent"
                            KeybindContent.Parent = KeybindInline
                            KeybindContent.BackgroundColor3 = Color3FromRGB(21, 21, 21)
                            KeybindContent.BorderColor3 = Color3FromRGB(34, 34, 34)
                            KeybindContent.Position = UDim2New(-4.23076916, 0, 1.2, 0)
                            KeybindContent.Size = UDim2New(0, 68, 0, 0)
                            KeybindContent.ZIndex = 3
                        
                            KBContent.Name = "KBContent"
                            KBContent.Parent = KeybindContent
                            KBContent.SortOrder = Enum.SortOrder.LayoutOrder
                        
                            local contentAnimations = {
                                Open = function ( self )
                                    KeybindContent.Visible = true
                                    KeybindInline.Visible = true
                        
                                    self:FadeIn()
                                end,
                                FadeIn = function ()
                                    for _, object in pairs( KeybindContent:GetDescendants() ) do
                                        if object:IsA("Frame") then
                                            tweenService:Create(object, TweenInfo.new(0.1), { BackgroundTransparency = 0 }):Play()
                                        elseif object:IsA("TextButton") then
                                            tweenService:Create(object, TweenInfo.new(0.1), { TextTransparency = 0 }):Play()
                                        end
                                    end
                                end,
                                FadeOut = function ()
                                    for _, object in pairs( KeybindContent:GetDescendants() ) do
                                        if object:IsA("Frame") then
                                            tweenService:Create(object, TweenInfo.new(0.1), { BackgroundTransparency = 1 }):Play()
                                        elseif object:IsA("TextButton") then
                                            tweenService:Create(object, TweenInfo.new(0.1), { TextTransparency = 1 }):Play()
                                        end
                                    end
                                end
                            }
                            
                            function contentAnimations:Close()
                                contentAnimations:FadeOut()
                        
                                TaskWait(0.05)
                        
                                KeybindContent.Visible = false
                                KeybindInline.Visible = false
                            end
                        
                            function Keybind:UpdateList()
                                if UserInterface.KeybindList and KeybindOptions.KeybindsList then
                                    UserInterface.KeybindList:Add(KeybindOptions.KeybindListName, Keybind.FMode)
                                    UserInterface.KeybindList:SetVisibility(KeybindOptions.KeybindListName, KeybindOptions:GetState())
                                    UserInterface.KeybindList:SetMode(KeybindOptions.KeybindListName, Keybind.FMode)
                                end
                            end
                        
                            function Keybind:Value(info)
                                if info then
                                    if info[1] then
                                        local Key = info[1]
                                        KeybindButton.Text = "key : " .. (Key == "NONE" or Key == "" and "NONE" or Key)
                                        Keybind.FKey = Key
                                    else
                                        KeybindButton.Text = "key : NONE"
                                    end
                        
                                    if info[2] then
                                        Keybind.Modes[info[2]]:Click(info[2] == "Toggle" and true or false)
                                    end
                        
                                    Keybind:UpdateList()
                                end
                        
                                return Keybind
                            end
                        
                            function KeybindOptions:GetState()
                                if Keybind.FMode == "Always" then
                                    return true
                                elseif Keybind.FMode == "Hold" then
                                    if Keybind.FKey == "NONE" then
                                        return false
                                    end
                        
                                    return Keybind.Toggled
                                else
                                    if Keybind.FKey == "NONE" then
                                        return false
                                    end
                        
                                    return Keybind.Toggled
                                end
                            end
                        
                            for _, v in pairs({ "Toggle", "Hold", "Always" }) do
                                local Button = {}
                                local KB_Button = InstanceNew("TextButton")
                                KB_Button.Name = "KB_Button"
                                KB_Button.Parent = KeybindContent
                                KB_Button.BackgroundColor3 = Color3FromRGB(21, 21, 21)
                                KB_Button.BackgroundTransparency = 0
                                KB_Button.BorderColor3 = Color3FromRGB(34, 34, 34)
                                KB_Button.BorderSizePixel = 0
                                KB_Button.Position = UDim2New(0, 0, 0.0416666679, 0)
                                KB_Button.Size = UDim2New(0, 68, 0, 14)
                                KB_Button.ZIndex = 3
                                KB_Button.Font = Enum.Font.SourceSans
                                KB_Button.Text = tostring(v)
                                KB_Button.TextColor3 = Color3FromRGB(129, 129, 127)
                                KB_Button.TextSize = 14.000
                                
                                local TextBoundY = KB_Button.TextBounds.Y
                                KeybindContent.Size += UDim2New(0, 0, 0, TextBoundY)
                        
                                function Button:Click(igr)
                                    for _,v in pairs(Keybind.Modes) do
                                        v:Unclick()
                                    end
                        
                                    Keybind.FMode = v
                                    KeybindInline.Visible = false
                                    Keybind:UpdateList()
                        
                                    KB_Button.TextColor3 = theme.accent
                        
                                    if not igr then
                                        pcall(KeybindOptions.Callback, KeybindOptions:GetState())
                                    end
                                end
                        
                                function Button:Unclick()
                                    KB_Button.TextColor3 = Color3FromRGB(129, 129, 127)
                                end
                                    
                                if v == Keybind.FMode then
                                    Button:Click()
                                end
                        
                                KB_Button.MouseButton1Down:Connect(Button.Click)
                        
                                theme_event.Event:Connect(function ()
                                    if v == Keybind.FMode then
                                        KB_Button.TextColor3 = theme.accent
                                    end
                                end)
                                
                                Keybind.Modes[v] = Button
                            end
                        
                            KeybindButton.InputBegan:Connect(function (input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                    Keybind.Picking = true
                        
                                    KeybindButton.Text = "..."
                        
                                    TaskWait(0.02)
                        
                                    local Event; Event = inputService.InputBegan:Connect(function (input)
                                        local Key
                                        local KeyName = input.KeyCode.Name == "Escape" and "NONE" or Keys[input.KeyCode] or Keys[input.UserInputType] or input.KeyCode.Name
                        
                                        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == "Escape" then
                                            Keybind.FKey = "NONE"
                                        elseif input.UserInputType == Enum.UserInputType.Keyboard then
                                            Keybind.FKey = input.KeyCode.Name
                                        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                                            Keybind.FKey = "MB1"
                                        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                                            Keybind.FKey = "MB2"
                                        end
                        
                                        Break = true
                                        Keybind.Picking = false
                        
                                        KeybindButton.Text = "key : " .. KeyName
                        
                                        pcall(KeybindOptions.Callback, KeybindOptions:GetState())
                                        UserInterface.Flags[KeybindOptions.Flag] = KeybindOptions:GetState()
                                        UserInterface.Flags[KeybindOptions.Flag .. "_info"] = {Keybind.FKey, Keybind.FMode}
                                        Keybind:UpdateList()
                        
                                        Event:Disconnect()
                                    end)
                                end
                                
                                if input.UserInputType == Enum.UserInputType.MouseButton2 then
                                    if UserInterface.Popup and UserInterface.Popup.ID ~= KeybindHolder.Name then
                                        UserInterface:RemovePopups()
                                    end
                                    if KeybindInline.Visible then
                                        contentAnimations:Close()
                                    else
                                        UserInterface:NewPopup({ Remove = contentAnimations.Close, ID = KeybindHolder.Name })
                                        contentAnimations:Open()
                                    end
                                end
                            end)
                        
                            inputService.InputBegan:Connect(function ( input, gameprocessing )
                                if gameprocessing then return end
                        
                                -- mousebutton niggassss
                                local mb = Keybind.FKey == "MB2" and "MouseButton2" or Keybind.FKey == "MB1" and "MouseButton1"
                                if input.KeyCode.Name == Keybind.FKey or input.UserInputType.Name == mb then
                                    if Keybind.FMode == 'Toggle' then
                                        Keybind.Toggled = not Keybind.Toggled
                                    elseif Keybind.FMode == 'Hold' then
                                        Keybind.Toggled = true
                        
                                        local c; c = inputService.InputEnded:Connect(function ( input )
                                            if input.KeyCode.Name == Keybind.FKey or input.UserInputType.Name == mb then
                                                c:Disconnect()
                                                Keybind.Toggled = false
                                                pcall(KeybindOptions.Callback, KeybindOptions:GetState())
                                                Keybind:UpdateList()
                                            end
                                        end)
                                    end
                                    
                                    pcall(KeybindOptions.Callback, KeybindOptions:GetState())
                                    UserInterface.Flags[KeybindOptions.Flag] = KeybindOptions:GetState()
                                    UserInterface.Flags[KeybindOptions.Flag .. "_info"] = {Keybind.FKey, Keybind.FMode}
                                    Keybind:UpdateList()
                                end
                            end)
                        
                            if Keybind.FKey ~= "" then
                                Keybind:Value({ Keybind.FKey, Keybind.FMode })
                            end
                        
                            increaseYSize(14)
                        
                            UserInterface.Flags[KeybindOptions.Flag] = KeybindOptions:GetState()
                            UserInterface.Flags[KeybindOptions.Flag .. "_info"] = {Keybind.FKey, Keybind.FMode}
                        
                            UserInterface.ConfigFlags[KeybindOptions.Flag .. "_info"] = function(info) Keybind:Value(info) end
                        
                            return KeybindOptions
                        end
                    end
                    do -- src/Lua/Interface/Components/Label.lua
                        function Options:Label(text, richtext)
                            local LabelOptions = {}
                        
                            local RichTextEnabled = richtext ~= nil and richtext == true and true or false
                        
                            local Label = InstanceNew("TextLabel")
                            Label.Name = "Label"
                            Label.Parent = SectionColumnComponents
                            Label.BackgroundColor3 = Color3FromRGB(255, 255, 255)
                            Label.BackgroundTransparency = 1.000
                            Label.BorderColor3 = Color3FromRGB(0, 0, 0)
                            Label.BorderSizePixel = 0
                            Label.Size = UDim2New(0, 229, 0, 14)
                            Label.Font = Enum.Font.SourceSans
                            Label.Text = text
                            Label.TextColor3 = Color3FromRGB(255, 255, 255)
                            Label.TextSize = 14.000
                            Label.TextXAlignment = Enum.TextXAlignment.Left
                            Label.RichText = RichTextEnabled
                            Label.TextTruncate = "AtEnd"
                        
                            function LabelOptions:ChangeText(newtext)
                                if not type(newtext) == "string" then return end
                                local new = tostring(newtext)
                                Label.Text = new
                            end
                            
                            increaseYSize(14)
                        
                            return LabelOptions
                        end
                    end
                    do -- src/Lua/Interface/Components/Playerlist.lua
                        function Options:PlayerList()
                            local PlayerlistHolder = InstanceNew("Frame")
                            local SearchBar = InstanceNew("TextBox")
                            local SearchTitle = InstanceNew("TextLabel")
                            local Players = InstanceNew("ScrollingFrame")
                            local ListLayout = InstanceNew("UIListLayout")
                        
                            PlayerlistHolder.Name = "PlayerlistHolder"
                            PlayerlistHolder.Parent = SectionColumnComponents
                            PlayerlistHolder.Size = UDim2New(1, 0, 0, 316)
                            PlayerlistHolder.BorderColor3 = Color3FromRGB(0, 0, 0)
                            PlayerlistHolder.BackgroundTransparency = 1
                            PlayerlistHolder.Position = UDim2New(0, 0, -1.17375305e-06, 0)
                            PlayerlistHolder.BorderSizePixel = 0
                            PlayerlistHolder.BackgroundColor3 = Color3FromRGB(255, 255, 255)
                            
                            SearchBar.Name = "SearchBar"
                            SearchBar.Parent = PlayerlistHolder
                            SearchBar.Size = UDim2New(0, 160, 0, 17)
                            SearchBar.BorderColor3 = Color3FromRGB(31, 31, 31)
                            SearchBar.BackgroundColor3 = Color3FromRGB(21, 21, 21)
                            SearchBar.TextSize = 14
                            SearchBar.TextColor3 = Color3FromRGB(255, 255, 255)
                            SearchBar.Text = ""
                            SearchBar.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                            SearchBar.TextXAlignment = Enum.TextXAlignment.Left
                            
                            SearchTitle.Name = "SearchTitle"
                            SearchTitle.Parent = SearchBar
                            SearchTitle.Size = UDim2New(0, 63, 0, 17)
                            SearchTitle.BorderColor3 = Color3FromRGB(0, 0, 0)
                            SearchTitle.BackgroundTransparency = 1
                            SearchTitle.Position = UDim2New(1.03750002, 0, 0, 0)
                            SearchTitle.BorderSizePixel = 0
                            SearchTitle.BackgroundColor3 = Color3FromRGB(255, 255, 255)
                            SearchTitle.TextColor3 = Color3FromRGB(255, 255, 255)
                            SearchTitle.Text = "search"
                            SearchTitle.TextXAlignment = Enum.TextXAlignment.Left
                            SearchTitle.TextSize = 14
                            SearchTitle.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                            
                            Players.Name = "Players"
                            Players.Parent = PlayerlistHolder
                            Players.Active = true
                            Players.Size = UDim2New(0, 229, 0, 300)
                            Players.BorderColor3 = Color3FromRGB(0, 0, 0)
                            Players.BackgroundTransparency = 1
                            Players.Position = UDim2New(0, 0, 0.075000003, 0)
                            Players.BorderSizePixel = 0
                            Players.BackgroundColor3 = Color3FromRGB(255, 255, 255)
                            Players.ScrollBarImageColor3 = theme.accent
                            Players.AutomaticCanvasSize = Enum.AutomaticSize.Y
                            Players.ScrollBarThickness = 5
                            
                            ListLayout.Name = "ListLayout"
                            ListLayout.Parent = Players
                            ListLayout.Padding = UDim.new(0, 7)
                        
                            ListLayout.Changed:Connect(function ()
                                Players.CanvasSize = UDim2New(0, 0, 0, 8 + ListLayout.AbsoluteContentSize.Y)
                            end)
                        
                            local PlayerOptions = {
                                CurrentPlayer = ""
                            }
                        
                            function PlayerOptions:Clear()
                                for _, child in ipairs(Players:GetChildren()) do
                                    if child:IsA("Frame") then
                                        child:Destroy()
                                    end
                                end
                            end
                        
                            function PlayerOptions:Add(player, player_name)
                                local PlayerFrame = InstanceNew("Frame")
                                local PlayerImage = InstanceNew("ImageLabel")
                                local PlayerName = InstanceNew("TextButton")
                        
                                local DisplayName
                                if player.Character then
                                    local hum = player.Character:FindFirstChild("Humanoid")
                                    if hum then
                                        DisplayName = player.Character.Humanoid.DisplayName
                                    else
                                        DisplayName = player_name
                                    end
                                else
                                    DisplayName = player_name
                                end
                        
                                PlayerFrame.Name = player_name .. " " .. DisplayName
                                PlayerFrame.Parent = Players
                                PlayerFrame.Size = UDim2New(1, 0, 0, 19)
                                PlayerFrame.BorderColor3 = Color3FromRGB(0, 0, 0)
                                PlayerFrame.BackgroundTransparency = 1
                                PlayerFrame.BorderSizePixel = 0
                                PlayerFrame.BackgroundColor3 = Color3FromRGB(255, 255, 255)
                                
                                PlayerImage.Name = "PlayerImage"
                                PlayerImage.Parent = PlayerFrame
                                PlayerImage.Size = UDim2New(0, 19, 0, 19)
                                PlayerImage.BorderColor3 = Color3FromRGB(0, 0, 0)
                                PlayerImage.BorderSizePixel = 0
                                PlayerImage.BackgroundColor3 = Color3FromRGB(255, 255, 255)
                                PlayerImage.BackgroundTransparency = 1
                                PlayerImage.Image = "https://www.roblox.com/bust-thumbnail/image?userId=" .. player.UserId .. "&width=19&height=19&format=png"
                                
                                PlayerName.Name = "PlayerName"
                                PlayerName.Parent = PlayerImage
                                PlayerName.Size = UDim2New(0, 205, 0, 19)
                                PlayerName.BorderColor3 = Color3FromRGB(0, 0, 0)
                                PlayerName.BackgroundTransparency = 1
                                PlayerName.Position = UDim2New(1.26315784, 0, 0, 0)
                                PlayerName.BorderSizePixel = 0
                                PlayerName.BackgroundColor3 = Color3FromRGB(255, 255, 255)
                                PlayerName.TextColor3 = Color3FromRGB(129, 129, 127)
                                PlayerName.Text = string.format("%s (@%s)", player_name, DisplayName)
                                PlayerName.TextXAlignment = Enum.TextXAlignment.Left
                                PlayerName.TextSize = 14
                                PlayerName.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                                PlayerName.TextTruncate = "AtEnd"
                        
                                local self_conn = nil
                                local function fucking_click()
                                    if PlayerOptions.CurrentPlayer == player_name then
                                        PlayerName.TextColor3 = Color3FromRGB(129, 129, 127)
                                        PlayerOptions.CurrentPlayer = nil
                        
                                        if self_conn then
                                            self_conn:Disconnect(); self_conn = nil
                                        end
                                    else
                                        for i, v in ipairs(Players:GetDescendants()) do
                                            if v.Name == "PlayerName" then
                                                v.TextColor3 = Color3FromRGB(129, 129, 127)
                                            end
                                        end
                                        PlayerName.TextColor3 = theme.accent
                                        PlayerOptions.CurrentPlayer = player_name
                        
                                        if not self_conn then
                                            self_conn = theme_event.Event:Connect(function ()
                                                if PlayerOptions.CurrentPlayer == player_name then
                                                    PlayerName.TextColor3 = theme.accent
                                                end
                                            end)
                                        end
                                    end
                                end
                        
                                PlayerName.MouseButton1Click:Connect(fucking_click)
                            end
                        
                            function PlayerOptions:Refresh()
                                PlayerOptions:Clear()
                        
                                for _, player in ipairs(playerService:GetPlayers()) do
                                    if player == LocalPlayer then continue end
                        
                                    local name = player.Name
                                    PlayerOptions:Add(player, name)
                                end
                            end
                        
                            function PlayerOptions:GetPlayers()
                                return Players:GetChildren()
                            end
                        
                            function PlayerOptions:Search()
                                local search = string.lower(SearchBar.Text)
                                for i, v in pairs(Players:GetChildren()) do
                                    if v:IsA("Frame") then
                                        if search ~= "" then
                                            local commanditemlist = string.lower(v.Name)
                                            if string.find(commanditemlist, search) then
                                                v.Visible = true
                                            else
                                                v.Visible = false
                                            end
                                        else
                                            v.Visible = true
                                        end
                                    end
                                end
                            end
                        
                            function PlayerOptions:GetCurrentPlayer()
                                return PlayerOptions.CurrentPlayer
                            end
                        
                            function PlayerOptions:Init()
                                -- init
                                PlayerOptions:Refresh()
                        
                                SearchBar.Changed:Connect(PlayerOptions.Search)
                                playerService.PlayerAdded:Connect(PlayerOptions.Refresh)
                                playerService.PlayerRemoving:Connect(PlayerOptions.Refresh)
                            end
                        
                            PlayerOptions:Init()
                        
                            increaseYSize(310)
                            return PlayerOptions
                        end
                    end
                    do -- src/Lua/Interface/Components/Slider.lua
                        function Options:Slider(Configuration)
                            local SliderOptions = {
                                 Title = Configuration.title or "slider",
                                 Min = Configuration.min or 1,
                                 Max = Configuration.max or 10,
                                 Float = Configuration.float or 1,
                                 Default = Configuration.default or 0,
                                 Value = 0,
                                 Callback = Configuration.callback or function() end,
                                 Sliding = false,
                                 Suffix = Configuration.suffix or "",
                                 Flag = UserInterface:GetNextFlag(),
                            }
                            SliderOptions.MinText = Configuration.mintext or tostring(SliderOptions.Min)
                            SliderOptions.MaxText = Configuration.maxtext or tostring(SliderOptions.Max)
                        
                            local Slider = InstanceNew("Frame")
                            local SliderInline = InstanceNew("Frame")
                            local InlineCorner = InstanceNew("UICorner")
                            local SliderBackground = InstanceNew("Frame")
                            local BackgroundCorner = InstanceNew("UICorner")
                            local SliderFill = InstanceNew("Frame")
                            local FillCorner = InstanceNew("UICorner")
                            local SliderDrag = InstanceNew("Frame")
                            local DragCorner = InstanceNew("UICorner")
                            local SliderName = InstanceNew("TextLabel")
                            local SliderValue = InstanceNew("TextLabel")
                        
                            Slider.Name = "Slider"
                            Slider.Parent = SectionColumnComponents
                            Slider.BackgroundColor3 = Color3FromRGB(255, 255, 255)
                            Slider.BackgroundTransparency = 1.000
                            Slider.BorderColor3 = Color3FromRGB(0, 0, 0)
                            Slider.BorderSizePixel = 0
                            Slider.Size = UDim2New(0, 229, 0, 30)
                        
                            SliderInline.Name = "SliderInline"
                            SliderInline.Parent = Slider
                            SliderInline.BackgroundColor3 = Color3FromRGB(21, 21, 21)
                            SliderInline.BorderColor3 = Color3FromRGB(0, 0, 0)
                            SliderInline.BorderSizePixel = 0
                            SliderInline.Position = UDim2New(0, 0, 0.766666651, 0)
                            SliderInline.Size = UDim2New(0, 160, 0, 7)
                            
                            InlineCorner.CornerRadius = UDim.new(0, 2)
                            InlineCorner.Name = "InlineCorner"
                            InlineCorner.Parent = SliderInline
                            
                            SliderBackground.Name = "SliderBackground"
                            SliderBackground.Parent = SliderInline
                            SliderBackground.BackgroundColor3 = Color3FromRGB(21, 21, 21)
                            SliderBackground.BorderColor3 = Color3FromRGB(0, 0, 0)
                            SliderBackground.BorderSizePixel = 0
                            SliderBackground.Position = UDim2New(0, 0, -0.00999999978, 0)
                            SliderBackground.Size = UDim2New(0, 160, 1, 0)
                            
                            BackgroundCorner.CornerRadius = UDim.new(0, 2)
                            BackgroundCorner.Name = "BackgroundCorner"
                            BackgroundCorner.Parent = SliderBackground
                            
                            SliderFill.Name = "SliderFill"
                            SliderFill.Parent = SliderBackground
                            SliderFill.BackgroundColor3 = Color3FromRGB(172, 153, 159)
                            SliderFill.BorderColor3 = Color3FromRGB(0, 0, 0)
                            SliderFill.BorderSizePixel = 0
                            SliderFill.Position = UDim2New(0, 0, 0, 0)
                            SliderFill.Size = UDim2New(0, 0, 1, 0)
                            
                            FillCorner.CornerRadius = UDim.new(0, 2)
                            FillCorner.Name = "FillCorner"
                            FillCorner.Parent = SliderFill
                            
                            SliderDrag.Name = "SliderDrag"
                            SliderDrag.Parent = SliderBackground
                            SliderDrag.BackgroundColor3 = Color3FromRGB(21, 21, 21)
                            SliderDrag.BackgroundTransparency = 1.000
                            SliderDrag.BorderColor3 = Color3FromRGB(0, 0, 0)
                            SliderDrag.BorderSizePixel = 0
                            SliderDrag.Position = UDim2New(0, 0, -0.00999999978, 0)
                            SliderDrag.Size = UDim2New(1, 0, 1, 0)
                            
                            DragCorner.CornerRadius = UDim.new(0, 2)
                            DragCorner.Name = "DragCorner"
                            DragCorner.Parent = SliderDrag
                        
                            local X = UIModule:GetTextBoundary(SliderOptions.Title, Enum.Font.SourceSans, 14)
                            SliderName.Name = "SliderName"
                            SliderName.Parent = Slider
                            SliderName.BackgroundColor3 = Color3FromRGB(255, 255, 255)
                            SliderName.BackgroundTransparency = 1.000
                            SliderName.BorderColor3 = Color3FromRGB(0, 0, 0)
                            SliderName.BorderSizePixel = 0
                            SliderName.Size = UDim2New(0, 28, 0, 20)
                            SliderName.FontFace = Font.new([[rbxasset://fonts/families/SourceSansPro.json]])
                            SliderName.Text = SliderOptions.Title
                            SliderName.TextColor3 = Color3FromRGB(255, 255, 255)
                            SliderName.TextSize = 14.000
                            SliderName.TextXAlignment = Enum.TextXAlignment.Left
                        
                            SliderValue.Name = "SliderValue"
                            SliderValue.Parent = Slider
                            SliderValue.BackgroundColor3 = Color3FromRGB(255, 255, 255)
                            SliderValue.BackgroundTransparency = 1.000
                            SliderValue.BorderColor3 = Color3FromRGB(0, 0, 0)
                            SliderValue.BorderSizePixel = 0
                            SliderValue.Position = UDim2New(0, X + 3, 0, 0)
                            SliderValue.Size = UDim2New(0, SliderValue.TextBounds.X, 0, 20)
                            SliderValue.Font = Enum.Font.SourceSans
                            SliderValue.Text = SliderOptions.Value .. SliderOptions.Suffix
                            SliderValue.TextColor3 = Color3FromRGB(124, 124, 124)
                            SliderValue.TextSize = 14.000
                            SliderValue.TextXAlignment = Enum.TextXAlignment.Left
                        
                            local INLINESTROKE = InstanceNew("UIStroke", SliderInline)
                            INLINESTROKE["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border
                            INLINESTROKE["Name"] = [[INLINESTROKE]]
                            INLINESTROKE["Color"] = Color3FromRGB(32, 32, 32)
                        
                            local SliderBackgroundStroke = InstanceNew("UIStroke", SliderBackground)
                            SliderBackgroundStroke["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border
                            SliderBackgroundStroke["Name"] = [[SliderBackgroundStroke]]
                            SliderBackgroundStroke["Color"] = Color3FromRGB(32, 32, 32)
                        
                            local SliderFillStroke = InstanceNew("UIStroke", SliderFill)
                            SliderFillStroke["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border
                            SliderFillStroke["Name"] = [[SliderFillStroke]]
                            SliderFillStroke["Color"] = Color3FromRGB(172, 153, 159)
                            SliderFillStroke["Transparency"] = 0.5
                        
                            theme_event.Event:Connect(function ()
                                SliderFill.BackgroundColor3 = theme.accent
                                SliderFillStroke.Color = theme.accent
                            end)
                            
                            local function Round(number, float)
                                return float * math.round(number / float)
                            end
                        
                            function SliderOptions:Set(value)
                                value = math.clamp(Round(value, SliderOptions.Float), SliderOptions.Min, SliderOptions.Max)
                        
                                local Size = (value - SliderOptions.Min) / (SliderOptions.Max - SliderOptions.Min)
                        
                                SliderOptions.Value = value
                        
                                tweenService:Create(SliderFill, TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2New(Size, 0, 1, 0)}):Play()
                        
                                SliderOptions.Callback(value)
                                UserInterface.Flags[SliderOptions.Flag] = SliderOptions.Value
                        
                                local text = SliderOptions.Value == SliderOptions.Min and SliderOptions.MinText or SliderOptions.Value == SliderOptions.Max and SliderOptions.MaxText or string.format("%.14g%s", SliderOptions.Value, SliderOptions.Suffix)
                                SliderValue.Text = text
                            end
                        
                            function SliderOptions:Slide(input)
                                local Size = (input.Position.X - SliderBackground.AbsolutePosition.X) / SliderBackground.AbsoluteSize.X
                                local Value = math.clamp((SliderOptions.Max - SliderOptions.Min) * Size + SliderOptions.Min, SliderOptions.Min, SliderOptions.Max)
                        
                                self:Set(Value)
                            end
                        
                            SliderOptions:Set(SliderOptions.Default)
                        
                            SliderDrag.MouseEnter:Connect(function ()
                                tweenService:Create(SliderBackgroundStroke, TweenInfo.new(0.2), {Color = Color3FromRGB(255,255,255) }):Play()
                            end)
                        
                            SliderDrag.MouseLeave:Connect(function ()
                                tweenService:Create(SliderBackgroundStroke, TweenInfo.new(0.2), {Color = Color3FromRGB(32, 32, 32) }):Play()
                            end)
                        
                            SliderDrag.InputBegan:Connect(function (input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                    SliderOptions.Sliding = true
                                    SliderOptions:Slide(input)
                                end
                            end)
                        
                            SliderDrag.InputEnded:Connect(function (input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                    SliderOptions.Sliding = false
                                    SliderOptions:Slide(input)
                                end
                            end)
                        
                            SliderDrag.InputChanged:Connect(function (input)
                                if input.UserInputType == Enum.UserInputType.MouseMovement and SliderOptions.Sliding then
                                    SliderOptions:Slide(input)
                                end
                            end)
                        
                            UserInterface.ConfigFlags[SliderOptions.Flag] = function(value) SliderOptions:Set(value) end
                        
                            increaseYSize(30)
                            return SliderOptions
                        end
                    end
                    do -- src/Lua/Interface/Components/Textbox.lua
                        function Options:TextBox(Configuration)
                            local TextBoxOptions = {
                                Title = Configuration.title or "textbox",
                                Default = Configuration.default or "",
                                Placeholder = Configuration.placeholder or "",
                                ClearTextOnFocus = Configuration.cleartextonfocus or Configuration.ctf or true,
                                Callback = Configuration.callback or function() end,
                                Text = "",
                                Flag = UserInterface:GetNextFlag()
                            }
                        
                            if TextBoxOptions.Title ~= "NO TITLE" then
                                self:Label(TextBoxOptions.Title)
                            end
                        
                            local TextBox = InstanceNew("TextBox")
                            local TextboxCorner = InstanceNew("UICorner")
                            TextBox.Parent = SectionColumnComponents
                            TextBox.BackgroundColor3 = Color3FromRGB(23, 23, 23)
                            TextBox.BorderColor3 = Color3FromRGB(0, 0, 0)
                            TextBox.BorderSizePixel = 0
                            TextBox.Size = UDim2New(0, 229, 0, 14)
                            TextBox.Font = Enum.Font.SourceSans
                            TextBox.PlaceholderText = TextBoxOptions.Placeholder
                            TextBox.Text = ""
                            TextBox.TextColor3 = Color3FromRGB(255, 255, 255)
                            TextBox.TextSize = 14.000
                            TextBox.TextXAlignment = Enum.TextXAlignment.Left
                            TextBox.TextTruncate = "AtEnd"
                            TextBox.ClearTextOnFocus = TextBoxOptions.ClearTextOnFocus
                        
                            TextboxCorner.CornerRadius = UDim.new(0, 4)
                            TextboxCorner.Name = "TextboxCorner"
                            TextboxCorner.Parent = TextBox
                            
                            local TextBoxStroke = InstanceNew("UIStroke", TextBox)
                            TextBoxStroke["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border
                            TextBoxStroke["Name"] = [[TextBoxStroke]]
                            TextBoxStroke["Color"] = Color3FromRGB(37, 37, 37)
                        
                            function TextBoxOptions:Set(Text)
                                Text = Text or ""
                                
                                TextBox.Text = Text
                                TextBoxOptions.Text = TextBox.Text
                                UserInterface.Flags[TextBoxOptions.Flag] = TextBoxOptions.Text
                                UserInterface.Flags[TextBoxOptions.Flag .. "f"] = function(value) TextBoxOptions:Set(value) end
                                pcall(TextBoxOptions.Callback, TextBoxOptions.Text)
                            end
                        
                            local function OnFocusLost()
                                TextBoxOptions.Text = TextBox.Text
                                UserInterface.Flags[TextBoxOptions.Flag] = TextBoxOptions.Text
                                UserInterface.Flags[TextBoxOptions.Flag .. "f"] = function(value) TextBoxOptions:Set(value) end
                                pcall(TextBoxOptions.Callback, TextBoxOptions.Text)
                            end
                        
                            TextBox.FocusLost:Connect(OnFocusLost)
                        
                            increaseYSize(14)
                            UserInterface.ConfigFlags[TextBoxOptions.Flag] = function(text) TextBoxOptions:Set(text) end
                        
                            return TextBoxOptions
                        end
                    end
                    do -- src/Lua/Interface/Components/Toggle.lua
                        function Options:Toggle(Configuration)
                            local ToggleOptions = { 
                                title = Configuration.title or "toggle",
                                default = Configuration.default or false,
                                state = false,
                                callback = Configuration.callback or function() end,
                                Flag = UserInterface:GetNextFlag()
                            }
                            
                            UI["19"] = InstanceNew("TextButton", SectionColumnComponents)
                            UI["19"]["BorderSizePixel"] = 0
                            UI["19"]["TextTransparency"] = 1
                            UI["19"]["TextSize"] = 14
                            UI["19"]["TextColor3"] = Color3FromRGB(255, 255, 255)
                            UI["19"]["BackgroundColor3"] = Color3FromRGB(255, 255, 255)
                            UI["19"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                            UI["19"]["Size"] = UDim2New(0, 229, 0, 15)
                            UI["19"]["BackgroundTransparency"] = 1
                            UI["19"]["Name"] = [[ToggleButton]]
                            UI["19"]["BorderColor3"] = Color3FromRGB(0, 0, 0)
                            UI["19"]["Text"] = [[Toggle]]
                        
                            UI["1a"] = InstanceNew("Frame", UI["19"])
                            UI["1a"]["BorderSizePixel"] = 0
                            UI["1a"]["BackgroundColor3"] = Color3FromRGB(20, 20, 17)
                            UI["1a"]["Size"] = UDim2New(0, 13, 0, 13)
                            UI["1a"]["BorderColor3"] = Color3FromRGB(0, 0, 0)
                            UI["1a"]["Position"] = UDim2New(0, 0, 0.077, 0)
                            UI["1a"]["Name"] = [[ToggleStatus]]
                        
                            UI["1b"] = InstanceNew("UICorner", UI["1a"])
                            UI["1b"]["Name"] = [[ToggleStatusCorner]]
                            UI["1b"]["CornerRadius"] = UDim.new(0, 4)
                        
                            UI["1c"] = InstanceNew("UIStroke", UI["1a"])
                            UI["1c"]["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border
                            UI["1c"]["Name"] = [[ToggleUIStroke]]
                            UI["1c"]["Color"] = Color3FromRGB(37, 37, 37)
                        
                            UI["1d"] = InstanceNew("TextLabel", UI["19"])
                            UI["1d"]["TextStrokeTransparency"] = 1
                            UI["1d"]["BorderSizePixel"] = 0
                            UI["1d"]["TextXAlignment"] = Enum.TextXAlignment.Left
                            UI["1d"]["BackgroundColor3"] = Color3FromRGB(255, 255, 255)
                            UI["1d"]["TextSize"] = 14
                            UI["1d"].FontFace = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Thin, Enum.FontStyle.Normal)
                            UI["1d"]["TextColor3"] = Color3FromRGB(129, 129, 127)
                            UI["1d"]["BackgroundTransparency"] = 1
                            UI["1d"]["Size"] = UDim2New(1, 0, 0, 13)
                            UI["1d"]["BorderColor3"] = Color3FromRGB(0, 0, 0)
                            UI["1d"]["Text"] = ToggleOptions.title
                            UI["1d"]["Name"] = [[ToggleName]]
                            UI["1d"]["Position"] = UDim2New(0, 18, 0, 0)
                        
                            local Button = UI["19"]
                            local ToggleStatus = UI["1a"]
                            local ToggleName = UI["1d"]
                        
                            local TS_ON = tweenService:Create(ToggleStatus, TweenInfo.new(0.2), {
                                BackgroundColor3 = Color3FromRGB(168, 157, 159)
                            })
                            local TN_ON = tweenService:Create(ToggleName, TweenInfo.new(0.2), {
                                TextColor3 = Color3FromRGB(255, 255, 255)
                            })
                            local TS_OFF = tweenService:Create(ToggleStatus, TweenInfo.new(0.2), {
                                BackgroundColor3 = Color3FromRGB(20, 20, 17)
                            })
                            local TN_OFF = tweenService:Create(ToggleName, TweenInfo.new(0.2), {
                                TextColor3 = Color3FromRGB(129, 129, 127)
                            })
                        
                            theme_event.Event:Connect(function ()
                                TS_ON = tweenService:Create(ToggleStatus, TweenInfo.new(0.2), {
                                    BackgroundColor3 = theme.accent
                                })
                        
                                if ToggleOptions.state then
                                    ToggleStatus.BackgroundColor3 = theme.accent
                                end
                            end)
                        
                            local function ToggleOn()
                                TS_ON:Play();TN_ON:Play()
                            end
                        
                            local function ToggleOff()
                                TS_OFF:Play();TN_OFF:Play()
                            end
                        
                            function ToggleOptions:Set(boolean)
                                ToggleOptions.state = boolean
                                pcall(ToggleOptions.callback, ToggleOptions.state)
                                UserInterface.Flags[ToggleOptions.Flag] = ToggleOptions.state
                                if ToggleOptions.state == true then
                                    ToggleOn()
                                elseif not ToggleOptions.state then
                                    ToggleOff()
                                end
                            end
                        
                            function ToggleOptions:Keybind(Configuration)
                                Options:Keybind(Configuration, Button)
                            end
                        
                            function ToggleOptions:Colorpicker(Configuration)
                                Options:Colorpicker(Configuration, Button)
                            end
                            
                            local function OnClick()
                                ToggleOptions.state = not ToggleOptions.state
                                ToggleOptions:Set(ToggleOptions.state)
                            end
                        
                            Button.MouseButton1Click:Connect(OnClick)
                        
                            ToggleOptions:Set(ToggleOptions.default)
                            increaseYSize(15)     
                        
                            UserInterface.ConfigFlags[ToggleOptions.Flag] = function(state) ToggleOptions:Set(state) end
                        
                            return ToggleOptions
                        end
                    end
                end
    
                return Options
            end
    
            if #Configuration.Tabs > 0 then
                Configuration.Tabs[1]:Select()
            end
    
            table.insert(Configuration.Tabs, #Configuration.Tabs + 1, TabConfiguration)
            return TabConfiguration
        end
    
        local function isMouseInFrame()
            local framePosition = UI["b"].AbsolutePosition
            local frameSize = UI["b"].AbsoluteSize
    
            local player = playerService.LocalPlayer
            local mouse = player:GetMouse()
            
            local mouseX, mouseY = mouse.X, mouse.Y
            
            if mouseX >= framePosition.X and mouseX <= framePosition.X + frameSize.X and
               mouseY >= framePosition.Y and mouseY <= framePosition.Y + frameSize.Y then
                return true
            else
                return false
            end
        end
    
        UI["2"].InputBegan:Connect(function (input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and not isMouseInFrame() then
                dragObject = UI["2"]
                dragging = true
                dragStart = input.Position
                startPos = dragObject.Position
            end
        end)
        UI["2"].InputEnded:Connect(function (input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        UI["2"].InputChanged:Connect(function (input)
            if dragging and input.UserInputType.Name == "MouseMovement" then
                dragInput = input
            end
        end)
    
        inputService.InputChanged:Connect(function (input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                local yPos = (startPos.Y.Offset + delta.Y) < -36 and -36 or startPos.Y.Offset + delta.Y
                dragObject:TweenPosition(UDim2New(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, yPos), "Out", "Quad", .15, true)
            end
        end)
    
        do -- src/Lua/Interface/Others/
            do -- src/Lua/Interface/Others/CloseOpen.lua
                inputService.InputBegan:Connect(function(input, gameproc)
                    if gameproc then return end
                
                    if input.KeyCode == Enum.KeyCode.RightShift then
                        UI["2"].Visible = not UI["2"].Visible
                    end
                end)
            end
            do -- src/Lua/Interface/Others/Config.lua
                function UserInterface:GetConfig()
                    local ConfigTable = {}
                
                    for _, v in pairs(UserInterface.ConfigFlags) do
                        local Value = UserInterface.Flags[_]
                
                        if typeof(Value) == "EnumItem" then
                            ConfigTable[_] = Value
                		elseif typeof(Value) == "Color3" then
                			ConfigTable[_] = { Value:ToHex() }
                        else
                            ConfigTable[_] = Value
                        end
                    end
                
                    return httpService:JSONEncode(ConfigTable)
                end
                
                function UserInterface:LoadConfig(config)
                    local Config = httpService:JSONDecode(config)
                    
                    for _, v in pairs(Config) do
                        local Func = UserInterface.ConfigFlags[_]
                
                        if Func then
                            Func(v)
                        end
                    end
                end
            end
            
            do -- src/Lua/Interface/Others/Popups.lua
                function UserInterface:RemovePopups()
                    if UserInterface.Popup then
                        UserInterface.Popup:Remove()
                        UserInterface.Popup = nil
                    end
                end
                
                function UserInterface:NewPopup(Configuration)
                    UserInterface.Popup = {
                        Remove = Configuration.Remove,
                        ID = Configuration.ID
                    }
                end
            end
            do -- src/Lua/Interface/Others/Watermark.lua
                function UserInterface:Watermark(text)
                    -- add more customization to this shit please.
                
                    --[[
                        Adding Soon : 
                            Watermark Text Triggers
                    ]]
                
                    local Watermark = InstanceNew("Frame")
                    local WatermarkCorner = InstanceNew("UICorner")
                    local WatermarkTitle = InstanceNew("TextLabel")
                
                    local TextBoundX = UIModule:GetTextBoundary("syndicate.club", Enum.Font.Code, 13)
                    Watermark.Name = "Watermark"
                    Watermark.Parent = UI["1"]
                    Watermark.BackgroundColor3 = Color3FromRGB(23, 21, 21)
                    Watermark.BorderColor3 = Color3FromRGB(0, 0, 0)
                    Watermark.BorderSizePixel = 0
                    Watermark.Position = UDim2New(0, 10, 0, 10)
                    Watermark.Size = UDim2New(0, TextBoundX + 10, 0, 20)
                
                    WatermarkCorner.CornerRadius = UDim.new(0, 4)
                    WatermarkCorner.Name = "WatermarkCorner"
                    WatermarkCorner.Parent = Watermark
                
                    WatermarkTitle.Name = "WatermarkTitle"
                    WatermarkTitle.Parent = Watermark
                    WatermarkTitle.BackgroundColor3 = Color3FromRGB(255, 255, 255)
                    WatermarkTitle.BackgroundTransparency = 1.000
                    WatermarkTitle.BorderColor3 = Color3FromRGB(0, 0, 0)
                    WatermarkTitle.BorderSizePixel = 0
                    WatermarkTitle.Size = UDim2New(1, 0, 1, 0)
                    WatermarkTitle.Font = Enum.Font.Code
                    WatermarkTitle.Text = text
                    WatermarkTitle.TextColor3 = Color3FromRGB(255, 255, 255)
                    WatermarkTitle.TextSize = 13.000
                    WatermarkTitle.RichText = true
                
                    local WatermarkOptions = {}
                
                    function WatermarkOptions:ChangeText(newtext)
                        if type(newtext) ~= "string" then return end
                        WatermarkTitle.Text = tostring(newtext)
                
                        local TBX = UIModule:GetTextBoundary(newtext, Enum.Font.Code, 13)
                        Watermark.Size = UDim2New(0, TBX + 10, 0, 20)
                    end
                
                    function WatermarkOptions:SetVisibility(visibility)
                        Watermark.Visible = visibility
                    end
                
                    function WatermarkOptions:SetPosition(v2Pos)
                        Watermark.Position = UDim2New(0, v2Pos.X, 0, v2Pos.Y)
                    end
                
                    return WatermarkOptions
                end
            end
        end
    
        return Configuration
    end
    
    return UserInterface
end)()

local nigga = (function() -- src/Lua/loader.lua
    local loaderOptions = {}
    loaderOptions.Completed = Instance.new("BindableEvent")
    loaderOptions.AutoLoadStop = Instance.new("BindableEvent")
    loaderOptions.Exit = false
    
    local function hasProperty(object, propertyName)
        local success, _ = pcall(function() 
            object[propertyName] = object[propertyName]
        end)
        return success
    end
    
    local function Tween(object, tweenInfo, property_Table)
        local newTween = game:GetService("TweenService"):Create(object, tweenInfo, property_Table)
        newTween:Play()
        return newTween
    end
    
    function loaderOptions:new()
        local Loader = Instance.new("ScreenGui")
        Loader.Name = "Loader"
        Loader.Parent = coreguiService
        
        local LoaderBackground = Instance.new("Frame")
        local BackgroundCorner = Instance.new("UICorner")
        local BackgroundStroke = Instance.new("UIStroke")
        local MainTitle = Instance.new("TextLabel")
        local InfoFrame = Instance.new("Frame")
        local InfoFrameStroke = Instance.new("UIStroke")
        local InfoFrameCorner = Instance.new("UICorner")
        local InfoTitle = Instance.new("TextLabel")
        local Information = Instance.new("TextLabel")
        local InfoGame = Instance.new("ImageLabel")
        local OptionsFrame = Instance.new("Frame")
        local OptionsFrameStroke = Instance.new("UIStroke")
        local OptionsFrameCorner = Instance.new("UICorner")
        local OptionsTitle = Instance.new("TextLabel")
        local Load_2 = Instance.new("TextButton")
        local LoadBCorner = Instance.new("UICorner")
        local LoadBStroke = Instance.new("UIStroke")
        local Exit = Instance.new("TextButton")
        local ExitBCorner = Instance.new("UICorner")
        local ExitBStroke = Instance.new("UIStroke")
        local Shadow1 = Instance.new("ImageLabel")
    
        LoaderBackground.Name = "LoaderBackground"
        LoaderBackground.Parent = Loader
        LoaderBackground.Size = UDim2.new(0, 345, 0, 194)
        LoaderBackground.BorderColor3 = Color3.fromRGB(0, 0, 0)
        LoaderBackground.AnchorPoint = Vector2.new(0.5, 0.5)
        LoaderBackground.Position = UDim2.new(0.5, 0, 0.5, 0)
        LoaderBackground.BorderSizePixel = 0
        LoaderBackground.BackgroundColor3 = Color3.fromRGB(23, 23, 23)
    
        BackgroundCorner.Name = "BackgroundCorner"
        BackgroundCorner.Parent = LoaderBackground
    
        BackgroundStroke.Name = "BackgroundStroke"
        BackgroundStroke.Parent = LoaderBackground
        BackgroundStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        BackgroundStroke.Color = Color3.fromRGB(30, 32, 30)
        BackgroundStroke.Thickness = 2
    
        MainTitle.Name = "MainTitle"
        MainTitle.Parent = LoaderBackground
        MainTitle.Size = UDim2.new(0, 81, 0, 20)
        MainTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
        MainTitle.BackgroundTransparency = 1
        MainTitle.Position = UDim2.new(0, 6, 0, 6)
        MainTitle.BorderSizePixel = 0
        MainTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        MainTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        MainTitle.Text = "          Nixius.xyz | Loader"
        MainTitle.TextStrokeTransparency = 0
        MainTitle.TextSize = 16
        MainTitle.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    
        InfoFrame.Name = "InfoFrame"
        InfoFrame.Parent = LoaderBackground
        InfoFrame.Size = UDim2.new(0, 332, 0, 103)
        InfoFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        InfoFrame.Position = UDim2.new(0.0173913036, 0, 0.164948449, 0)
        InfoFrame.BorderSizePixel = 0
        InfoFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
    
        InfoFrameStroke.Name = "InfoFrameStroke"
        InfoFrameStroke.Parent = InfoFrame
        InfoFrameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        InfoFrameStroke.Color = Color3.fromRGB(28, 28, 28)
    
        InfoFrameCorner.Name = "InfoFrameCorner"
        InfoFrameCorner.Parent = InfoFrame
    
        InfoTitle.Name = "InfoTitle"
        InfoTitle.Parent = InfoFrame
        InfoTitle.Size = UDim2.new(0, 326, 0, 16)
        InfoTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
        InfoTitle.BackgroundTransparency = 1
        InfoTitle.Position = UDim2.new(0.0180722885, 0, 0, 0)
        InfoTitle.BorderSizePixel = 0
        InfoTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        InfoTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        InfoTitle.Text = "Information"
        InfoTitle.TextXAlignment = Enum.TextXAlignment.Left
        InfoTitle.TextSize = 16
        InfoTitle.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    
        Information.Name = "Information"
        Information.Parent = InfoFrame
        Information.Size = UDim2.new(0, 233, 0, 87)
        Information.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Information.BackgroundTransparency = 1
        Information.Position = UDim2.new(0.026192769, 0, 0.255339807, 0)
        Information.BorderSizePixel = 0
        Information.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Information.TextYAlignment = Enum.TextYAlignment.Top
        Information.TextColor3 = Color3.fromRGB(255, 255, 255)
        Information.Text = ""
        Information.TextXAlignment = Enum.TextXAlignment.Left
        Information.TextSize = 14
        Information.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    
        OptionsFrame.Name = "OptionsFrame"
        OptionsFrame.Parent = LoaderBackground
        OptionsFrame.Size = UDim2.new(0, 332, 0, 47)
        OptionsFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        OptionsFrame.Position = UDim2.new(0.0173913036, 0, 0.726804137, 0)
        OptionsFrame.BorderSizePixel = 0
        OptionsFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
    
        OptionsFrameStroke.Name = "OptionsFrameStroke"
        OptionsFrameStroke.Parent = OptionsFrame
        OptionsFrameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        OptionsFrameStroke.Color = Color3.fromRGB(28, 28, 28)
    
        OptionsFrameCorner.Name = "OptionsFrameCorner"
        OptionsFrameCorner.Parent = OptionsFrame
    
        OptionsTitle.Name = "OptionsTitle"
        OptionsTitle.Parent = OptionsFrame
        OptionsTitle.Size = UDim2.new(0, 326, 0, 16)
        OptionsTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
        OptionsTitle.BackgroundTransparency = 1
        OptionsTitle.Position = UDim2.new(0.0180722885, 0, 0, 0)
        OptionsTitle.BorderSizePixel = 0
        OptionsTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        OptionsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        OptionsTitle.Text = "Options"
        OptionsTitle.TextXAlignment = Enum.TextXAlignment.Left
        OptionsTitle.TextSize = 16
        OptionsTitle.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    
        Load_2.Name = "Load"
        Load_2.Parent = OptionsFrame
        Load_2.ZIndex = 2
        Load_2.Size = UDim2.new(0, 153, 0, 17)
        Load_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Load_2.Position = UDim2.new(0.036144577, 0, 0.46808511, 0)
        Load_2.BorderSizePixel = 0
        Load_2.BackgroundColor3 = Color3.fromRGB(21, 21, 21)
        Load_2.AutoButtonColor = false
        Load_2.TextColor3 = Color3.fromRGB(255, 255, 255)
        Load_2.Text = "load"
        Load_2.TextStrokeTransparency = 1.0099999904632568
        Load_2.TextSize = 14
        Load_2.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    
        LoadBCorner.Name = "LoadBCorner"
        LoadBCorner.Parent = Load_2
        LoadBCorner.CornerRadius = UDim.new(0, 4)
    
        LoadBStroke.Name = "LoadBStroke"
        LoadBStroke.Parent = Load_2
        LoadBStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        LoadBStroke.Color = Color3.fromRGB(37, 37, 37)
    
        Exit.Name = "Exit"
        Exit.Parent = OptionsFrame
        Exit.ZIndex = 2
        Exit.Size = UDim2.new(0, 153, 0, 17)
        Exit.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Exit.Position = UDim2.new(0.515060246, 0, 0.46808511, 0)
        Exit.BorderSizePixel = 0
        Exit.BackgroundColor3 = Color3.fromRGB(21, 21, 21)
        Exit.AutoButtonColor = false
        Exit.TextColor3 = Color3.fromRGB(255, 255, 255)
        Exit.Text = "exit"
        Exit.TextStrokeTransparency = 1.0099999904632568
        Exit.TextSize = 14
        Exit.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    
        ExitBCorner.Name = "ExitBCorner"
        ExitBCorner.Parent = Exit
        ExitBCorner.CornerRadius = UDim.new(0, 4)
    
        ExitBStroke.Name = "ExitBStroke"
        ExitBStroke.Parent = Exit
        ExitBStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        ExitBStroke.Color = Color3.fromRGB(37, 37, 37)
    
        Shadow1.Name = "Shadow1"
        Shadow1.Parent = LoaderBackground
        Shadow1.AnchorPoint = Vector2.new(0.5, 0.5)
        Shadow1.ZIndex = 0
        Shadow1.Size = UDim2.new(1.20727181, 0, 3.67960405, 0)
        Shadow1.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Shadow1.Rotation = 90
        Shadow1.BackgroundTransparency = 1
        Shadow1.Position = UDim2.new(0.542648137, 0, 0.600463212, 0)
        Shadow1.BorderSizePixel = 0
        Shadow1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Shadow1.ImageColor3 = Color3.fromRGB(0, 0, 0)
        Shadow1.ScaleType = Enum.ScaleType.Tile
        Shadow1.Image = "rbxassetid://8992230677"
        Shadow1.SliceCenter = Rect.new(Vector2.new(0, 0), Vector2.new(99, 99))
    
        for i, v in pairs(Loader:GetDescendants()) do
            if hasProperty(v, "BackgroundTransparency") then v.BackgroundTransparency = 1 end
            if hasProperty(v, "TextTransparency") then v.TextTransparency = 1 end
            if hasProperty(v, "ImageTransparency") then v.ImageTransparency = 1 end
            if hasProperty(v, "Transparency") then v.Transparency = 1 end
        end
    
        local names_to_look_and_ignore = {
            "Information",
            "MainTitle",
            "InfoTitle",
            "OptionsTitle",
            "Shadow1"
        }
    
        function loaderOptions:FadeIn()
            for i, v in pairs(Loader:GetDescendants()) do
                if hasProperty(v, "BackgroundTransparency") and not table.find(names_to_look_and_ignore, v.Name) then Tween(v, TweenInfo.new(0.2), {BackgroundTransparency = 0}) end
                if hasProperty(v, "TextTransparency") then Tween(v, TweenInfo.new(0.2), {TextTransparency = 0}) end
                if hasProperty(v, "ImageTransparency") then Tween(v, TweenInfo.new(0.2), {ImageTransparency = 0}) end
                if hasProperty(v, "Transparency") and v:IsA("UIStroke") then Tween(v, TweenInfo.new(0.2), {Transparency = 0}) end
            end
        end
    
        function loaderOptions:FadeOut()
            for i, v in pairs(Loader:GetDescendants()) do
                if hasProperty(v, "BackgroundTransparency") then Tween(v, TweenInfo.new(0.2), {BackgroundTransparency = 1}) end
                if hasProperty(v, "TextTransparency") then Tween(v, TweenInfo.new(0.2), {TextTransparency = 1}) end
                if hasProperty(v, "ImageTransparency") then Tween(v, TweenInfo.new(0.2), {ImageTransparency = 1}) end
                if hasProperty(v, "Transparency") then Tween(v, TweenInfo.new(0.2), {Transparency = 1}) end
            end
        end
    
        function loaderOptions:ChangeInfoText(newInfoText)
            Information.Text = newInfoText
        end
    
        function loaderOptions:Load()
            loaderOptions:FadeOut()
            task.wait(0.2)
            loaderOptions.Completed:Fire()
            Loader:Destroy()
    
            loaderOptions.Exit = true
        end
        
        local function exit()
            loaderOptions:FadeOut()
            task.wait(0.2)
            Loader:Destroy()
    
            loaderOptions.Exit = true
        end
    
        local function init()
            Load_2.MouseButton1Click:Connect(loaderOptions.Load)
            Exit.MouseButton1Click:Connect(exit)
        
            loaderOptions:FadeIn()
        end
        
        init()
    end
    
    function loaderOptions.on_completed(script)
        loaderOptions.Completed.Event:Connect(script)
    end
    
    function loaderOptions.on_auto_load_stop(script)
        loaderOptions.AutoLoadStop.Event:Connect(script)
    end
    
    loaderOptions:new()
    
    local info_text_table = {
        "Welcome " .. LocalPlayer.DisplayName,
        "This Game is not Supported",
        "Loaded Universal Script - 1.0"
    }
    local info_text = table.concat(info_text_table, "\n")
    
    loaderOptions:ChangeInfoText(info_text)
    
    local function my_script()
        if true then
            (function()
                local AuxScan = { Objects = {} }
                
                function AuxScan:NewFunction(Name, Func)
                	AuxScan.Objects[Name] = Func
                end
                
                function AuxScan:Run()
                	for i, v in next, AuxScan.Objects do
                		if v then
                			v()
                		end
                	end
                end
                
                function AuxScan:ChangeText(TextObject, FuncName)
                    TextObject.Text = FuncName
                end
                
                local da_hood = {
                    functions = {}
                }
                
                local camera = workspace.CurrentCamera
                
                local connect = include "Connect"
                local Lerp = include "lerp"
                local Loops = include "Loops"
                local DrawingClass = include "DrawingClass"
                
                local function capitalizeFirst(str)
                    return str:sub(1,1):upper() .. str:sub(2):lower()
                end
                
                local on_character_silentaim_shit_whatever_nigga = Instance.new("BindableEvent")
                
                local aimassist = {
                    is_firing = false,
                
                    enabled = false,
                    keybind = false,
                    smoothness = {
                        smoothing_start = 0,
                        smoothing_end = 0,
                        smoothing_boost = 0
                    },
                    fieldofview = 100,
                    closest_mode = "none",
                    bones = nil,
                    character = nil,
                    
                    lock_target = false,
                
                    configuration = {
                        visibility = false,
                        wallcheck = false,
                        team = false,
                        friends = false,
                    },
                
                    jitter = {
                        x = 0,
                        y = 0,
                        z = 0
                    },
                
                    use_mouse_sensitivity = false,
                    use_camera = true,
                
                    lock_target_state = false,
                
                    prediction = 0,
                
                    smoothingtype = "Linear",
                
                    custom_calculation = false,
                
                    auto_prediction = false,
                
                    enable_on_move = false
                }
                
                local silentaim = {
                    enabled = false,
                    keybind = false,
                    smoothness = 1000,
                    fieldofview = 100,
                    closest_mode = "none",
                    bones = nil,
                    character = nil,
                    
                    lock_target = false,
                
                    configuration = {
                        visibility = false,
                        wallcheck = false,
                        team = false,
                        friends = false,
                    },
                
                    lock_target_state = false,
                
                    prediction = 0,
                
                    smoothingtype = "Linear",
                
                    custom_calculation = false,
                
                    auto_prediction = false,
                
                    position = nil,
                
                    look_at = false,
                
                    sync_with_aim_assist = false,
                
                    update_time = 60,
                    old_frame = tick(),
                
                    fov_calculation = "pixels"
                }
                
                local Characters = {
                    Prediction = {
                        JumpTimes = {},
                        LandTimes = {},
                        AirTimes = {},
                        VerticalPositions = {},
                        VerticalVelocity = {},
                        AirPrediction = {},
                        PeakTimes = {},
                        OldHorizontalVelocity = {}
                    }
                }
                
                local current_mouse_arg = "UpdateMousePosI"
                
                local mouse_arg = {
                    -- dahood
                	[2788229376] = current_mouse_arg or nil,
                	[16033173781] = current_mouse_arg or nil,
                
                    -- der hood
                	[17895097441] = "UpdateMousePosition" or nil,
                    [17895262040] = "UpdateMousePosition" or nil,
                
                    [9825515356] = "MousePosUpdate" or nil
                }
                
                local bullet_support = {
                    [4312377180] = {
                        path = workspace:FindFirstChild("MAP") and workspace.MAP:FindFirstChild("Ignored") or nil,
                    },
                    [1008451066] = {
                        path = workspace:FindFirstChild("Ignored") and workspace.Ignored:FindFirstChild("Siren") and workspace.Ignored.Siren:FindFirstChild("Radius") or nil,
                    },
                    [6133219615] = {
                        path = workspace:FindFirstChild("Ignored") and workspace.Ignored:FindFirstChild("Siren") and workspace.Ignored.Siren:FindFirstChild("Radius") or nil,
                    },
                    [3985694250] = {
                        path = workspace and workspace:FindFirstChild("Ignored") or nil
                    }
                }
                
                local gun_is_firing = false
                local gun_conn = nil
                local previousammo = math.huge
                
                local please_load = true
                
                if please_load then
                    do
                        (function() -- src/Lua/Scripts/da_hood/things.lua
                            function da_hood.functions:is_alive(player)
                            	return player
                            			and player.Character
                            			and player.Character:FindFirstChildOfClass("Humanoid")
                            			and player.Character:FindFirstChildOfClass("Humanoid").Health > 0
                            			and true
                            		or false
                            end
                            
                            function da_hood.functions:is_localplayer_alive()
                            	return self:is_alive(LocalPlayer)
                            end
                            
                            function da_hood.functions:is_moving(player)
                            	if player then
                            		if self:is_alive(player) then
                            			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                            			return humanoid.MoveDirection.magnitude > 0
                            		end
                            	end
                            	return false
                            end
                            
                            function da_hood.functions:is_localplayer_moving()
                            	return self:is_moving(LocalPlayer)
                            end
                            
                            function da_hood.functions:wall_check(Character)
                                local Ray = Ray.new(camera.CFrame.Position, (Character.PrimaryPart.Position - camera.CFrame.Position))
                                local IgnoreList = {camera, LocalPlayer.Character, Character, Character.Parent}
                                local PartHit = workspace:FindPartOnRayWithIgnoreList(Ray, IgnoreList)
                                if not PartHit then
                                    return true
                                end
                                return false
                            end
                            
                            -- hahahaha, actually did this due to me being lazy to do something like player.Character in getnearestplayertomouse so I did this little shit 😀😀
                            function da_hood.functions:getentities()
                            	local entities = {}
                            	for _, player in ipairs(playerService:GetPlayers()) do
                            		if player == LocalPlayer then
                            			continue
                            		end
                                    
                            		if not da_hood.functions:is_alive(player) then
                            			continue
                            		end
                                    
                            		if table.find(entities, player.Character) then
                            			continue
                            		end
                            
                            		local character = player.Character
                            		table.insert(entities, character)
                            	end
                            	return entities
                            end
                            
                            function da_hood.functions:getnearestplayertomouse(distance, settings)
                            	local entity = nil
                            	local distance = distance
                            	for i, v in next, self:getentities() do
                                    if settings.friends and playerService[v.Name]:IsFriendsWith(LocalPlayer.UserId) then
                                        continue 
                                    end
                            
                                    if settings.team and playerService[v.Name].Team == LocalPlayer.Team then
                                        continue 
                                    end
                            
                                    local humanoidrootpart = v:FindFirstChild("HumanoidRootPart")
                                    if not humanoidrootpart then
                                        continue
                                    end
                            
                                    local humanoid = v:FindFirstChild("Humanoid")
                                    if not humanoid then
                                        continue
                                    end
                            
                            		local head = v:FindFirstChild("Head")
                            		if not head then
                            			continue
                            		end
                            
                                    if humanoid.Health == 0 then
                                        continue
                                    end
                            
                            		local hitbox_pos = v:FindFirstChild("Head").Position
                            		local v2_pos, onscreen = camera:WorldToViewportPoint(hitbox_pos)
                            
                            		if settings.visibility and not onscreen then
                            			continue
                            		end
                            
                                    if settings.wallcheck and not self:wall_check(v) then
                                        continue
                                    end
                            
                            		local magnitude = (Vector2New(v2_pos.X, v2_pos.Y) - inputService:GetMouseLocation()).Magnitude
                            		if magnitude < distance then
                            			entity = v
                            			distance = magnitude
                            		end
                            	end
                            	return entity
                            end
                            
                            -- HAD TO FUCKING MAKE ANOTHER ONE FOR SILENT AIM
                            function da_hood.functions:custom_getnearestplayertomouse(distance, settings)
                            	local entity = nil
                            	local distance = distance
                            	for i, v in next, self:getentities() do
                                    if settings.friends and playerService[v.Name]:IsFriendsWith(LocalPlayer.UserId) then
                                        continue 
                                    end
                            
                                    if settings.team and playerService[v.Name].Team == LocalPlayer.Team then
                                        continue 
                                    end
                            
                                    local humanoidrootpart = v:FindFirstChild("HumanoidRootPart")
                                    if not humanoidrootpart then
                                        continue
                                    end
                            
                                    local humanoid = v:FindFirstChild("Humanoid")
                                    if not humanoid then
                                        continue
                                    end
                            
                            		local head = v:FindFirstChild("Head")
                            		if not head then
                            			continue
                            		end
                            
                                    if humanoid.Health == 0 then
                                        continue
                                    end
                            
                            		local hitbox_pos = v:FindFirstChild("Head").Position
                            		local v2_pos, onscreen = camera:WorldToViewportPoint(hitbox_pos)
                            
                            		if settings.visibility and not onscreen then
                            			continue
                            		end
                            
                                    if settings.wallcheck and not self:wall_check(v) then
                                        continue
                                    end
                            
                            		local magnitude = (Vector2New(v2_pos.X, v2_pos.Y) - inputService:GetMouseLocation()).Magnitude
                            		if magnitude < distance then
                            			entity = v
                            			distance = magnitude
                            		end
                            	end
                            	return entity
                            end
                            
                            function da_hood.functions:getclosestpart(character, config)
                            	local Distance = MathHuge
                            	local MousePosition = inputService:GetMouseLocation()
                            	local ClosestPart
                            	for i, v in ipairs(character:GetChildren()) do
                            		if #config == 0 then
                            			continue
                            		end
                            
                            		if v:IsA("Part") or v:IsA("MeshPart") then
                            			if TableFind(config, v.Name) then
                            				local Point, OnScreen = camera:WorldToViewportPoint(v.Position)
                            				if not OnScreen then
                            					ClosestPart = character.HumanoidRootPart
                            					continue
                            				end
                            				local Magnitude = (MousePosition - Vector2New(Point.X, Point.Y)).Magnitude
                            				if Magnitude < Distance then
                            					Distance = Magnitude
                            					ClosestPart = v
                            				end
                            			end
                            		end
                            	end
                            
                            	return ClosestPart
                            end
                            
                            function da_hood.functions:closestpoint(part)
                            	local RaycastParamsClosestPoint = RaycastParamsNew()
                            	RaycastParamsClosestPoint.FilterType = Enum.RaycastFilterType.Whitelist
                            	RaycastParamsClosestPoint.FilterDescendantsInstances = { part }
                            
                            	local MouseRay = Mouse.UnitRay
                            	MouseRay = MouseRay.Origin + (MouseRay.Direction * (part.Position - MouseRay.Origin).Magnitude)
                            	local Origin = (MouseRay.Y >= (part.Position - part.Size / 2).Y and MouseRay.Y <= (part.Position + part.Size / 2).Y)
                            			and (part.Position + Vector3New(0, -part.Position.Y + MouseRay.Y, 0))
                            		or part.Position
                            
                            	local Raycast = workspace:Raycast(MouseRay, (Origin - MouseRay), RaycastParamsClosestPoint)
                            	return Raycast and Raycast.Position or Mouse.Hit.Position
                            end
                            
                            -- this is so fucking retarded.
                            function da_hood.functions:mouse_aim(arguments)
                            	if not type(arguments) == "table" then
                            		return
                            	end
                            
                            	local smoothness = arguments.smoothness
                            	local position = arguments.position
                            	local use_mouse_sensitivity = arguments.use_mouse_sensitivity
                            	local jitter = arguments.jitter
                            	local use_camera = arguments.use_camera
                            
                            	if use_camera then
                            		return
                            	end
                            
                            	if not position then
                            		return
                            	end
                            
                            	local CalculateJitter = function(vector1)
                            		if vector1 == 0 then
                            			return 0
                            		end
                            		return rng(vector1 * -1, vector1)
                            	end
                            
                            	local screen_pos, on_screen = camera:WorldToViewportPoint(position)
                            
                            	if not on_screen then
                            		return
                            	end
                            
                            	if use_mouse_sensitivity then
                            		smoothness = smoothness / (userGameSettings.MouseSensitivity / 0.20016)
                            	end
                            
                            	local mousepos = inputService:GetMouseLocation()
                            	local X, Y = screen_pos.X, screen_pos.Y
                            	local AimPosX, AimPosY = X - mousepos.X, Y - mousepos.Y
                            	
                            	mousemoverel(AimPosX / 10, AimPosY/10)
                            end
                            
                            -- da hood custom prediction
                            -- taken from fatality.
                            function da_hood.functions:custom_prediction(HitPosition, Vel, BulletTravel, Configuration)
                            	local Character = Configuration.Character
                                local Prediction = Configuration.Prediction
                                local AutoPrediction = Configuration.AutoPrediction
                                local Resolver = Configuration.Resolver
                                local ResolvedVelocity = Configuration.ResolverValue
                                local PredictionValue = ((AutoPrediction == true) and (BulletTravel / 1000)) or Prediction;
                            	
                                local Offsets = {X = 0.111, Y = 0.03}
                                local OffsetX = PredictionValue + Offsets.X
                                local OffsetY = PredictionValue + Offsets.Y
                            
                                local HitVelocity = Vel
                            
                                local timeSinceJump = Characters.Prediction.JumpTimes;
                                local timeToLand = Characters.Prediction.LandTimes;
                                local timeInAir = Characters.Prediction.AirTimes;
                                local initialHeight = Characters.Prediction.VerticalPositions
                                local initialVelocity = Characters.Prediction.VerticalVelocity
                            
                                timeSinceJump[Character] = timeSinceJump[Character] or 0;
                                timeToLand[Character] = timeToLand[Character] or 0;
                                timeInAir[Character] = timeInAir[Character] or 0;
                                initialHeight[Character] = initialHeight[Character] or HitPosition.Y;
                            
                                if tick() - timeSinceJump[Character] > timeToLand[Character] then
                                    initialHeight[Character] = HitPosition.Y;
                                    timeInAir[Character] = 0;
                                    timeToLand[Character] = 0;
                                    timeSinceJump[Character] = 0;
                            
                                    if HitVelocity.Y > 10 then
                                        timeSinceJump[Character] = tick();
                            
                                        local g = workspace.Gravity;
                                        local u = 50;
                                        local t_land = (2 * u) / g;
                            
                                        initialVelocity[Character] = u;
                                        initialHeight[Character] = HitPosition.Y;
                                        timeToLand[Character] = t_land;
                                    end
                                else
                                    timeInAir[Character] = tick() - timeSinceJump[Character];
                                end
                            
                                local vertical = HitPosition.Y
                                local height = initialHeight[Character]
                                local horizontal = (HitPosition + HitVelocity * OffsetX) * Vector3.new(1, 0, 1);
                            
                                if timeInAir[Character] > 0 then
                                    local g = workspace.Gravity
                                    local u = initialVelocity[Character]
                                    local y = height
                            
                                    local t_air = timeInAir[Character]
                                    local t_ping = OffsetY
                            
                                    local t = t_air + t_ping
                                    local t_2 = t*t
                                    vertical = y + u * t - 0.48 * g * t_2
                                end
                            
                                return Vector3.new(horizontal.X, math.max(height, vertical) , horizontal.Z);
                            end
                            
                            function da_hood.functions:camera_aim(arguments)
                            	-- oh my loving dear programming life.
                            	-- too much things in arguments 😐
                            
                            	if not type(arguments) == "table" then
                            		return
                            	end -- dev would be a nigger if this actually happens.
                            
                            	local smoothness = arguments.smoothness
                            	local position = arguments.position
                            	local use_mouse_sensitivity = arguments.use_mouse_sensitivity
                            	local use_camera = arguments.use_camera
                            	local character = arguments.character
                            	local prediction = arguments.prediction
                            
                            	local smoothtype = arguments.smoothingtype
                            
                            	local jitter = arguments.jitter
                            	local jitterx = jitter.x
                            	local jittery = jitter.y
                            	local jitterz = jitter.z
                            
                            	local custom_calculation = arguments.custom_calculation
                            	local auto_prediction = arguments.auto_prediction
                            
                            	if not use_camera then
                            		self:mouse_aim(arguments)
                            		return
                            	end
                            
                            	if not position then
                            		return
                            	end
                            
                            	if use_mouse_sensitivity then
                            		smoothness = smoothness / (userGameSettings.MouseSensitivity / 0.20016)
                            	end
                            
                            	local CalculateJitter = function(vector1)
                            		if vector1 == 0 then
                            			return 0
                            		end
                            		return rng(vector1 * -1, vector1)
                            	end
                            
                            	local jitterNum1 = CalculateJitter(jitterx)
                            	local jitterNum2 = CalculateJitter(jittery)
                            	local jitterNum3 = CalculateJitter(jitterz)
                            
                            	local jFinal = Vector3New(jitterNum1, jitterNum2, jitterNum3)
                            
                            	-- pov, you avoid else in if statements 🤣🤣🤣
                            	local function calculateNormal()
                            		local player_velocity = character.HumanoidRootPart.Velocity
                            
                            		local normal = arguments.position + player_velocity * prediction
                            		position = CFrameNew(camera.CFrame.Position, normal + jFinal )
                            	end
                            
                            	if custom_calculation then
                            		-- thanks..
                            		local ping = tonumber(game:GetService("Stats"):FindFirstChild("PerformanceStats").Ping:GetValue())
                            		ping = math.floor(ping)
                            
                            		local player_jump = character.Humanoid:GetState() == "Freefall" and true or false
                            		local player_velocity = character.HumanoidRootPart.Velocity
                            
                            		local prediction_value = player_jump and pred_y or pred_x
                            
                            		local aimpos = self:custom_prediction(arguments.position, player_velocity, ping, {
                            			Character = character,
                            			Prediction = prediction_value,
                            			AutoPrediction = auto_prediction,
                            			Resolver = false,
                            			ResolverValue = nil
                            		})
                            		position = CFrame.new(camera.CFrame.Position, aimpos)
                            	else calculateNormal()
                            	end
                            	
                            
                            	camera.CFrame = camera.CFrame:Lerp(position, smoothness, Enum.EasingStyle[smoothtype], Enum.EasingDirection.InOut)
                            
                            	-- might add more shit soon
                            end
                            
                            function da_hood.functions:get_main_event()
                            	local main_event = replicatedStorage:FindFirstChild("MainEvent")
                            	if main_event then
                            		return main_event
                            	end
                            	return nil
                            end
                            
                            -- @getgun
                            -- does not have "is_localplayer_alive" func
                            -- must be run after "is_localplayer_alive" func
                            function da_hood.functions:get_gun()
                            	local gun
                            	for index, object in pairs(LocalPlayer.Character:GetChildren()) do
                            		if object:IsA("Tool") then
                            			if (object:FindFirstChild("Script") or object:FindFirstChild("GunScript") or object:FindFirstChild("weaponInfo")) then
                            				gun = object
                            				break
                            			end
                            		end
                            	end
                            	return gun
                            end
                            
                            function da_hood.functions:get_gun_2(player)
                            	local info = {
                            		isgunequipped = false,
                            		ammo = nil,
                            		tool = nil
                            	}
                            
                            	local tool = player.Character:FindFirstChildWhichIsA("Tool")
                            
                            	if not tool then return end
                            
                            	if game.GameId == 1958807588 then
                            		local ArmoryGun = player.Information.Armory:FindFirstChild(tool.Name)
                            		if ArmoryGun then
                            			info.tool = tool
                            			info.ammo = ArmoryGun.Ammo.Normal
                            			info.isgunequipped = true
                            		end
                            	elseif game.GameId == 3634139746 then
                            		local ammo = tool.Script:FindFirstChild("Ammo")
                            		if ammo then
                            			info.tool = tool
                            			info.ammo = ammo
                            			info.isgunequipped = true
                            		end
                            	elseif game.GameId == 5743758816 then
                            		local ammo = tool:FindFirstChild("AMMO")
                            		if ammo then
                            			info.tool = tool
                            			info.ammo = ammo
                            			info.isgunequipped = true
                            		end
                            	else
                            		for _, obj in pairs(tool:GetChildren()) do
                            			if obj.Name:lower():find("ammo") and not obj.Name:lower():find("max") then
                            				info.tool = tool
                            				info.ammo = obj
                            				info.isgunequipped = true
                            			end
                            		end
                            	end
                            	return info
                            end
                            
                            function da_hood.functions:get_gun_from_character(character)
                            	local gun
                            	for index, object in pairs(character:GetChildren()) do
                            		if object:IsA("Tool") then
                            			if (object:FindFirstChild("Script") or object:FindFirstChild("GunScript") or object:FindFirstChild("weaponInfo")) then
                            				gun = object
                            				break
                            			end
                            		end
                            	end
                            	return gun
                            end
                            
                            function mouse_arg:Get()
                            	if not mouse_arg[game.PlaceId] then
                            		return "UpdateMousePos"
                            	end
                            	return mouse_arg[game.PlaceId]
                            end
                            
                            function da_hood.functions:get_aim_arg() -- shitty
                            	return mouse_arg:Get()
                            end
                        end)()
                    end
                    
                    local Interface = UserInterface:Create{title = '    Nixius<font color="rgb(167, 140, 255)">.xyz</font>',}
                    
                    do
                        do
                            local update_time = 60
                            local old_frame = tick()
                            local current_smoothing = 1
                            local smoothing_animation = "Linear"
                            
                            local function clamp(a, lowerNum, higher)
                            	if a > higher then
                            		return higher
                            	elseif a < lowerNum then
                            		return lowerNum
                            	else
                            		return a
                            	end
                            end
                            
                            local value = Instance.new("NumberValue")
                            value.Name = "TweenValue"
                            value.Value = 0
                            
                            value:GetPropertyChangedSignal("Value"):Connect(function()
                                current_smoothing = value.Value
                            end)
                            
                            local changed = {
                                start = Instance.new("BindableEvent"),
                                end_value = Instance.new("BindableEvent"),
                                boost_value = Instance.new("BindableEvent")
                            }
                            
                            task.spawn(function ()
                                while task.wait() do
                                    local start_value = aimassist.smoothness.smoothing_start
                                    local end_value = aimassist.smoothness.smoothing_end
                                    local boost_value = aimassist.smoothness.smoothing_boost
                                
                                    local tweeninfo = TweenInfo.new(
                                        boost_value,
                                        Enum.EasingStyle[smoothing_animation],
                                        Enum.EasingDirection.Out
                                    )
                                
                                    local tween1 = tweenService:Create(value, tweeninfo, {Value = end_value})
                                    local tween2 = tweenService:Create(value, tweeninfo, {Value = start_value})
                            
                                    tween1:Play()
                                    task.wait(aimassist.smoothness.smoothing_boost)
                                    tween2:Play()
                                    task.wait(aimassist.smoothness.smoothing_boost)
                                end
                            end)
                            
                            function aimassist:get_position()
                                local position
                                local bone = aimassist.bones:GetValues()
                            
                                local closest_mode = aimassist.closest_mode
                                local character = aimassist.character
                            
                                if type(bone) == "table" and #bone > 0 then
                                    if closest_mode ~= "None" then
                                        if closest_mode == "Closest Part" then
                                            local newBone = tostring(da_hood.functions:getclosestpart(character, bone))
                                            if type(newBone) == "string" and newBone ~= "" and character:FindFirstChild(newBone) then -- very superior check 😎 could do a better one but meh
                                                position = character[newBone].Position
                                            end
                                        elseif closest_mode == "Closest Point" then
                                            local newBone = tostring(da_hood.functions:getclosestpart(character, bone))
                                            if type(newBone) == "string" and newBone ~= "" and character:FindFirstChild(newBone) then
                                                position = da_hood.functions:closestpoint(character[newBone])
                                            end
                                        end
                                    end
                                end
                            
                                if type(bone) == "string" and bone ~= "" and character:FindFirstChild(bone) then
                                    position = character[bone].Position
                                end
                            
                                return position
                            end
                            
                            function aimassist:aim()
                                da_hood.functions:camera_aim({
                                    smoothness = current_smoothing,
                                    use_mouse_sensitivity = aimassist.use_mouse_sensitivity,
                                    jitter = aimassist.jitter,
                                    position = aimassist:get_position(),
                                    use_camera = aimassist.use_camera,
                                    prediction = aimassist.prediction,
                                    character = aimassist.character,
                                    smoothingtype = aimassist.smoothingtype,
                                    custom_calculation = aimassist.custom_calculation,
                                    auto_prediction = aimassist.auto_prediction
                                })
                            end
                            
                            function aimassist:enable()
                                if ((tick() - old_frame) >= (1/update_time)) then
                                    if not aimassist.enabled then
                                        return end
                                
                                    if not aimassist.keybind then
                                        return end
                            
                                    if not aimassist.character then
                                        return end
                            
                                    if aimassist.enable_on_move then
                                        if not da_hood.functions:is_localplayer_moving() then return end
                                        aimassist:aim()
                                    else
                                        aimassist:aim()
                                    end
                                end
                            end
                            
                            local run_gac = false
                            
                            local function get_aim_assist_character()
                                if aimassist.lock_target then
                                    local char = da_hood.functions:getnearestplayertomouse(aimassist.fieldofview, aimassist.configuration)
                                    if char ~= nil and aimassist.lock_target_state == false then
                                        aimassist.lock_target_state = true
                                        aimassist.character = char
                                    end
                                else
                                    aimassist.character = da_hood.functions:getnearestplayertomouse(aimassist.fieldofview, aimassist.configuration)
                                end
                            end
                            
                            local g_a_c = function ()
                                while run_gac do
                                    TaskWait(0.01)
                            
                                    get_aim_assist_character()
                                end
                                aimassist.character = nil
                            end
                            
                            local gacHandlers = {}
                            gacHandlers.stop = function() run_gac = false end
                            gacHandlers.resume = function() run_gac = true coroutine.wrap(g_a_c)() end
                            
                            local maintabhere = Interface:Tab( "Main" )
                            
                            local cubesetion = maintabhere:Section("Cubes", "left")

                            local selectedValue = "Tp to Cubes"

                            cubesetion:Toggle({ title = "Collect Cubes", default = false, callback = function (bool)
                                if bool then
                                    if selectedValue == "Tp to Cubes" then
                                        teleportConnection = game:GetService("RunService").Stepped:Connect(function()
                                            teleportPlayer()
                                            wait(0.2)
                                        end)
                                    elseif selectedValue == "Bring Cubes" then
                                        fireTouchConnection = game:GetService("RunService").Stepped:Connect(function()
                                            fireTouchDetectors()
                                            wait(1.5)
                                        end)
                                    end
                                else
                                    if teleportConnection then
                                        teleportConnection:Disconnect()
                                    end
                                    if fireTouchConnection then
                                        fireTouchConnection:Disconnect()
                                    end
                                end
                            end })

                            cubesetion:Dropdown({ title = "Method", values = {"Tp to Cubes", "Bring Cubes"}, default = "Tp to Cubes", multi = false, callback = function (value)
                                selectedValue = value
                            end })

                            local webhooksection = maintabhere:Section("Webhook Notifications", "left")

                            webhooksection:TextBox({ title = "Webhook", default = "", placeholder = "Your Webhook Here", ClearTextOnFocus = false, callback = function (value)
                                webhookUrl = value
                            end })

                            webhooksection:Toggle({ title = "Ping Me", default = false, callback = function (bool)
                                pingme = bool
                            end })

                            webhooksection:Toggle({ title = "Notify When Luck Obby is Completed", default = false, callback = function (bool)
                                usewebhookwhenobbycompleted = bool
                            end })

                            webhooksection:Toggle({ title = "Notify Cube Collection", default = false, callback = function (bool)
                                usewebhook = bool
                            end })

                            webhooksection:Dropdown({ title = "Select Cube Rarities to Ignore", values = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"}, default = "Common", multi = true, callback = function (value)
                                ignorcubenames = value
                            end })

                            local miscsectioninmaintab = maintabhere:Section("Misc", "right")

                            miscsectioninmaintab:Toggle({ title = "Anti-Afk", default = false, callback = function (bool)
                                if bool then
                                    antiAfkConnection = game:GetService("RunService").Stepped:Connect(function()
                                        local player = game.Players.LocalPlayer
                                        local character = player.Character or player.CharacterAdded:Wait()

                                        local function simulateMovement()
                                            local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
                                            if humanoidRootPart then
                                                humanoidRootPart.CFrame = humanoidRootPart.CFrame * CFrame.new(0, 0.091, -0.082)
                                                wait(0.05)
                                                humanoidRootPart.CFrame = humanoidRootPart.CFrame * CFrame.new(0, 0, 0.082)
                                            end
                                        end

                                        simulateMovement()
                                        wait(60)
                                    end)
                                else
                                    if antiAfkConnection then
                                        antiAfkConnection:Disconnect()
                                    end
                                end
                            end })

                            local isToggled = false
                            local isOnCooldown = false

                            local function FinishObby()
                                if game.Players.LocalPlayer.Character and workspace:FindFirstChild("ObbyEnd") then
                                    game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(workspace.ObbyEnd.CFrame)
                                end
                            end

                            local function StartCooldown()
                                isOnCooldown = true
                                if usewebhookwhenobbycompleted then
                                    sendObbyEndNotification()
                                end
                                wait(182)
                                isOnCooldown = false
                            end

                            miscsectioninmaintab:Toggle({ title = "Auto Complete Luck Obby", default = false, callback = function (bool)
                                isToggled = bool
                                if bool then
                                    spawn(function()
                                        while isToggled do
                                            if not isOnCooldown then
                                                FinishObby()
                                                StartCooldown()
                                            end
                                            wait(1)
                                        end
                                    end)
                                end
                            end })

                            miscsectioninmaintab:Button({ title = "Complete Luck Obby", callback = function ()
                                if game.Players.LocalPlayer.Character and workspace:FindFirstChild("ObbyEnd") then
                                    game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(workspace.ObbyEnd.CFrame)
                                end
                            end })

                            miscsectioninmaintab:Button({ title = "Teleport To Luckboost Circle", callback = function ()
                                game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-2268.0419921875, 203.78335571289062, 1774.6248779296875)
                            end })
                            
                            local in_game = maintabhere:Section("Game", "right")
                            
                            local Rejoin = function ()
                                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
                            end
                            
                            local JoinAnotherServer = function ()
                                game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer) 
                            end
                            
                            in_game:Button({ title = "Rejoin", callback = function ()
                                pcall(Rejoin)
                            end })
                            
                            in_game:Button({ title = "Server Hop", callback = function ()
                                  pcall(JoinAnotherServer)
                            end })

                            local extratab = maintabhere:Section("Extra", "right")

                            extratab:Button({ title = "Reset Character", callback = function ()
                                game.Players.LocalPlayer.Character.Head:Destroy()
                            end })

                            extratab:Button({ title = "Teleport To Testing Area", callback = function ()
                                game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(673.0811767578125, 2.9999992847442627, -258.77239990234375)
                            end })

                        end
                        
                        do -- src/Lua/Scripts/da_hood/components/c_render.lua
                            -- this part of the code is really dirty.
                            
                            local notification = {
                                objects = {}
                            }
                            
                            function notification:new_text(text, time)
                                local NotificationTable = {
                                    Text = text,
                                    Time = os.clock() + time,
                                    Lerp = 2,
                                    Offset = 2,
                                    Object = DrawingClass({"Text", {Visible = false, Font = 2, Size = 16, Outline = true, Color = Color3.fromRGB(255,255,255)}})
                                }
                            
                                table.insert(notification.objects, NotificationTable)
                            end
                            
                            function notification:update()
                                local YOffset = 0
                                local Position = Vector2.new(20, 70)
                            
                                for index, v in next, notification.objects do
                                    if os.clock() >= v.Time then
                                        v.Lerp = Lerp(v.Lerp, 0, 1 / 12)
                                    else
                                        v.Lerp = Lerp(v.Lerp, 255, 1 / 12)
                                        v.Offset = Lerp(v.Offset, 255, 1 / 12)
                                    end
                            
                                    local Object = v.Object
                            
                                    Object.Visible = true
                                    Object.Transparency = v.Lerp / 255
                                    Object.Text = v.Text
                            
                                    Object.Position = Vector2.new(Position.X, Position.Y + YOffset) - Vector2.new(Object.TextBounds.X - (Object.TextBounds.X * (v.Lerp / 255)), 0)
                            
                                    YOffset += (Object.TextBounds.Y + 3) * (v.Offset / 255)
                            
                                    if v.Lerp <= 1 then
                                        v.Offset = Lerp(v.Offset, 0, 1 / 12)
                                    end
                            
                                    if v.Offset <= 1 then
                                        v.Object:Remove()
                            
                                        table.remove(notification.objects, index)
                                    end
                                end
                            end
                            
                            Loops:AddToHeartbeat("render_notification", function ()
                                notification:update()
                            end)
                        end

                        do
                            local players_tab = Interface:Tab( "Players" )
                            
                            local players_list = players_tab:Section("Player List", "left")
                            local advanced = players_tab:Section("Actions", "right")
                            
                            local playerlist = players_list:PlayerList()
                            
                            local player_name = advanced:Label("player name : ...")
                            local index = advanced:Label("player index : ...")
                            
                            local mark = DrawingClass({"Circle", {Visible = false, Transparency = 1, Radius = 5, Color = Color3.fromRGB(255,255,255), Filled = true}})
                            
                            advanced:Button({ title = "Copy Player Profile", callback = function ()
                                local current_player = playerlist:GetCurrentPlayer()
                                if current_player then
                                    local player_userid = playerService[current_player].UserId
                                    local link = ("https://www.roblox.com/users/%s/profile"):format(tostring(player_userid))
                                    setclipboard(link)
                                end
                            end })
                            advanced:Button({ title = "Copy Player UserID", callback = function ()
                                local current_player = playerlist:GetCurrentPlayer()
                                if current_player then
                                    local player_userid = playerService[current_player].UserId
                                    setclipboard(player_userid)
                                end
                            end })
                                                        advanced:Button({ title = "Teleport to Player", callback = function ()
                                local current_player = playerlist:GetCurrentPlayer()
                                if current_player then
                                    local player = playerService[current_player]
                                    if da_hood.functions:is_alive(player) then
                                        local character = player.Character
                                        if not character then return end
                                        
                                        local tp_pos = nil
                            
                                        local humanoidrootpart = character:FindFirstChild("HumanoidRootPart")
                                        if not humanoidrootpart then return end
                            
                                        tp_pos = humanoidrootpart.CFrame
                            
                                        if da_hood.functions:is_localplayer_alive() then
                                            local local_hum = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                            if not local_hum then return end
                            
                                            local_hum.CFrame = tp_pos
                                        end
                                    end
                                end
                            end })
                            advanced:Toggle({ title = "Spectate", default = false, callback = function (bool)
                                if bool then
                                    Loops:AddToRenderStepped("SpectatePlayer", function ()
                                        local current_player = playerlist:GetCurrentPlayer()
                                        if current_player then
                                            local player = playerService[current_player]
                                            if not player then
                                                return
                                            end

                                            if da_hood.functions:is_alive(player) then
                                                local character = player.Character
                                                if not character then
                                                    return
                                                end

                                                camera.CameraSubject = character.Humanoid
                                            else
                                                camera.CameraSubject = nil
                                            end
                                        else
                                            camera.CameraSubject = nil
                                        end
                                    end)
                                else
                                    Loops:RemoveFromRenderStepped("SpectatePlayer")
                                    camera.CameraSubject = game.Players.LocalPlayer.Character.Humanoid
                                end
                            end })
                            advanced:Toggle({ title = "Mark Player", default = false, callback = function (bool)
                                if bool then
                                    Loops:AddToRenderStepped("RenderMarkPLayer", function ()
                                        local current_player = playerlist:GetCurrentPlayer()
                                        if current_player then
                                            local player = playerService[current_player]
                                            if not player then
                                                mark.Visible = false
                                                return
                                            end
                                    
                                            if da_hood.functions:is_alive(player) then
                                                local character = player.Character
                                                if not character then
                                                    mark.Visible = false
                                                    return
                                                end
                                                
                                                local headpos = nil
                                    
                                                local head = character:FindFirstChild("Head")
                                                if not head then mark.Visible = false return end
                                    
                                                headpos = head.Position
                                    
                                                local screenpos, onscreen = camera:WorldToViewportPoint(headpos)
                                                mark.Visible = onscreen
                                    
                                                local v2pos = Vector2.new(screenpos.X, screenpos.Y)
                                                mark.Position = v2pos
                                            else
                                                mark.Visible = false
                                            end
                                        else
                                            mark.Visible = false
                                        end
                                    end)
                                else
                                    mark.Visible = false
                                    Loops:RemoveFromRenderStepped("RenderMarkPLayer")
                                end
                            end })
                            
                            local function update_thing()
                                local current_player = playerlist:GetCurrentPlayer()
                                if not current_player then 
                                    player_name:ChangeText("Player Name : ...")
                                    index:ChangeText("Player Index : ...")
                                    return
                                end
                            
                                local playersinlist = playerlist:GetPlayers()
                                local indexinlist = 0
                                for i, v in next, playersinlist do
                                    if string.find(v.Name, current_player) then
                                        indexinlist = i
                                    end
                                end
                            
                                player_name:ChangeText("Player Name : " .. tostring(current_player))
                                index:ChangeText("Player Index : " .. tostring(indexinlist))
                            end
                            
                            local loop_update_thing = coroutine.create(function()
                                while wait() do
                                    update_thing()
                                end
                            end)
                            coroutine.resume(loop_update_thing)
                        end
                        do -- src/Lua/Scripts/da_hood/components/f_settings.lua
                            local config = {
                                path = "nixius.xyz/configs/tycoonrng/",
                                file = "",
                                config_name = ""
                            }
                            function config:get_list()
                                local config_list = {}
                            
                                if #listfiles("nixius.xyz/configs/tycoonrng") > 0 then
                                    for i, v in next, listfiles("nixius.xyz/configs/tycoonrng") do
                                        local ext = '.'..v:split('.')[#v:split('.')];
                                        if ext == '.txt' then
                                            table.insert(config_list, v:split('\\')[#v:split('\\')]:sub(1,-#ext-1))
                                        end
                                    end
                                else
                                    config_list = {}
                                end
                            
                                return config_list
                            end
                            
                            local settingsTab = Interface:Tab( "Settings" )
                            
                            local loading_config = false
                            
                            local profiles = settingsTab:Section("Configuration", "left")
                            
                            profiles:TextBox({ title = "NO TITLE", default = "", placeholder = "config name", ClearTextOnFocus = true, callback = function (value)
                                config.config_name = value
                            end })
                            
                            local configs_list, funcs = profiles:Dropdown({ title = "configs", values = config:get_list(), default = "--", multi = false, callback = function (value)
                                config.file = value
                            end })
                            
                            profiles:Button({ title = "Load Config", callback = function ()
                                if config.file == nil then return end
                                if not isfile(config.path .. config.file .. ".txt") then return end
                            
                                loading_config = true
                                local config_to_load = readfile(config.path .. config.file .. ".txt")
                                UserInterface:LoadConfig(config_to_load)
                                funcs:Refresh(config:get_list())
                                loading_config = false
                            end })
                            
                            profiles:Button({ title = "Save Config", callback = function ()
                                if config.config_name ~= "" then
                                    writefile(config.path .. config.config_name .. ".txt", UserInterface:GetConfig())
                                    funcs:Refresh(config:get_list())
                                end
                            end })
                            
                            profiles:Button({ title = "Delete Config", callback = function ()
                                if config.file ~= nil then
                                    local config_to_delete = config.path .. config.file .. ".txt"
                                    delfile(config_to_delete)
                                    funcs:Refresh(config:get_list())
                                end
                            end })
                            
                            profiles:Button({ title = "Refresh List", callback = function ()
                                funcs:Refresh(config:get_list())
                            end })
                            
                            local menu_misc = settingsTab:Section("Menu", "right")
                            
                            menu_misc:Keybind({title = "Menu Keybind", keybindlist = false, keybindname = "menu:", key = "RightAlt", callback = function (bool)
                                if not loading_config then
                                    UI["2"].Visible = not UI["2"].Visible
                                end
                            end })

                            local theme_section = settingsTab:Section("Theme", "right")
                            
                            getgenv().theme = {
                                accent = Color3FromRGB(167, 140, 255),
                                scroll = Color3FromRGB(167, 140, 255)
                            }
                            
                            local old_theme = table.clone(getgenv().theme)
                            local theme_objects = {}
                            
                            theme_objects["accent"] = theme_section:Colorpicker({ title = "Accent", default = Color3.fromRGB(167, 140, 255), transparency = 1, callback = function (value, transparency)
                                theme.accent = value
                                theme_event:Fire()
                            end })
                            
                            theme_objects["scroll"] = theme_section:Colorpicker({ title = "Scrollbar", default = Color3.fromRGB(167, 140, 255), transparency = 1, callback = function (value, transparency)
                                theme.scroll = value
                                theme_event:Fire()
                            end })
                            
                            theme_section:Button({ title = "Default Theme", callback = function ()
                                for i1, v1 in next, old_theme do
                                    for i2, v2 in next, theme_objects do
                                        if not i1 == i2 then continue end
                                        v2:Set(v1)
                                    end
                                end
                            end })
                            
                            UI["2"].Visible = true
                        end
                    end
                    
                    UserInterface:KeybindsList()
                end
            end)()
        end
    end
    
    loaderOptions.on_completed(my_script)
end)()
