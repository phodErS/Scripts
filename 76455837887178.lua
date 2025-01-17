--local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/phodErS/Scripts/refs/heads/main/MainUI.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local LocalCharacter = LocalPlayer.Character
local HumanoidRootPart = LocalCharacter:FindFirstChild("HumanoidRootPart")
local ActiveFolder = Workspace:FindFirstChild("active")
local PlayerGUI = LocalPlayer:FindFirstChildOfClass("PlayerGui")
local GuiService = game:GetService('GuiService')
local IYMouse = Players.LocalPlayer:GetMouse()
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local PlayerGui = LocalPlayer.PlayerGui
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local StarterGui = game:GetService("StarterGui")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local Network = ReplicatedStorage:WaitForChild("Source"):WaitForChild("Network")
local RemoteFunctions = Network:WaitForChild("RemoteFunctions")
local RemoteEvents = Network:WaitForChild("RemoteEvents")

local CollectedRewards = {}
local AutoDig = false
local AutoCreatePiles = false
local AutoSell = false
local autowalkafterdig = false
local boxamouttopurchase = 1
local FLYING = false
local iyflyspeed = 30

local MenuTitle = "Nixius.xyz |"
local GameTitle = game:GetService("MarketplaceService"):GetProductInfo("76455837887178").Name

local Window = Fluent:CreateWindow({
    Title = MenuTitle,
    SubTitle = GameTitle,
    TabWidth = 130,
    Size = UDim2.fromOffset(650, 450),
    Acrylic = false,
    Theme = "Amethyst",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    AutoFarm = Window:AddTab({ Title = "-  Auto Farm", Icon = "target" }),
    Misc = Window:AddTab({ Title = "-  Misc", Icon = "cog" }),
    Character = Window:AddTab({ Title = "-  Character", Icon = "user" }),
    Teleports = Window:AddTab({ Title = "-  Teleports", Icon = "compass" }),
    Settings = Window:AddTab({ Title = "-  Settings", Icon = "settings" })
}

local autodigSection = Tabs.AutoFarm:AddSection("Auto Dig")

local function LegitDig()
    if not AutoDig then
        return
    end

    local DigMinigame = LocalPlayer.PlayerGui.Main:FindFirstChild("DigMinigame")

    if not DigMinigame then
        return
    end

    local LegitDigCoroutine = coroutine.create(function()
        local Connection
        Connection = game:GetService("RunService").Heartbeat:Connect(function()
            if not LocalPlayer.PlayerGui.Main:FindFirstChild("DigMinigame") or not AutoDig then
                Connection:Disconnect()
                return
            end

            DigMinigame.Cursor.Position = DigMinigame.Area.Position
        end)
    end)

    coroutine.resume(LegitDigCoroutine)
end

autodigSection:AddToggle("AutoCollectSalaryRewards", {
    Title = "Auto Dig",
    Description = "",
    Default = false,
    Callback = function(Value)
        AutoDig = Value
        if AutoDig then
            LegitDig()
        end
    end
})

game:GetService("RunService").Heartbeat:Connect(LegitDig)

local autopilesSection = Tabs.AutoFarm:AddSection("Auto Create Piles")

autopilesSection:AddToggle("AutoCollectSalaryRewards", {
    Title = "Auto Create Piles",
    Description = "",
    Default = false,
    Callback = function(Value)
        AutoCreatePiles = Value
		while AutoCreatePiles and task.wait() do	
			local Tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
			
			if not Tool or Tool:GetAttribute("Type") ~= "Shovel" then
				continue
			end
			
			Tool:Activate()
		end
    end
})

local autofarmextraSection = Tabs.AutoFarm:AddSection("Extra")

autofarmextraSection:AddToggle("AutoCollectSalaryRewards", {
    Title = "Auto Walk After Dig",
    Description = "",
    Default = false,
    Callback = function(Value)
        autowalkafterdig = Value
        while autowalkafterdig and task.wait() do
            if LocalPlayer:GetAttribute("IsDigging") then
                continue
            end
            
            local Character = LocalPlayer.Character
            local WalkZoneSizeFlag = 25
            local ZoneSize = Vector3.new(WalkZoneSizeFlag, 1, WalkZoneSizeFlag)
            local Humanoid = Character and Character:FindFirstChild("Humanoid")
            if not Humanoid then
                continue
            end
            
            local FoundPile = false

            for _, Pile in workspace.Map.TreasurePiles:GetChildren() do
                if Pile:GetAttribute("Owner") ~= LocalPlayer.UserId then
                    continue
                end

                FoundPile = true

                for _, Descendant in Pile:GetDescendants() do
                    if Descendant:IsA("BasePart") then
                        Descendant.CanCollide = false
                    end
                end

                Humanoid:MoveTo(Pile:GetPivot().Position)
                break
            end

            if FoundPile then
                continue
            end

            if not ChosenPosition then
                ChosenPosition = Character.HumanoidRootPart.Position + Vector3.new(
                    math.random(-WalkZoneSizeFlag, WalkZoneSizeFlag),
                    0,
                    math.random(-WalkZoneSizeFlag, WalkZoneSizeFlag)
                )
            end

            Humanoid:MoveTo(ChosenPosition)
            Humanoid.MoveToFinished:Once(function()
                ChosenPosition = nil
            end)
        end

        if not Value then
            ChosenPosition = nil
            if LocalPlayer.Character then
                local Humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
                if Humanoid then
                    Humanoid:MoveTo(LocalPlayer.Character.HumanoidRootPart.Position)
                end
            end
        end
    end
})

autofarmextraSection:AddToggle("AutoCollectSalaryRewards", {
    Title = "Auto Collect Salary Rewards",
    Description = "",
    Default = false,
    Callback = function(Value)
		while Value and task.wait() do
			local TierTimers = RemoteFunctions.TimeRewards:InvokeServer({
				Command = "GetSessionTimers"
			})
			
			for Tier, Timer in TierTimers do
				if Timer ~= 0 then
					CollectedRewards[Tier] = false
					continue
				end
				
				if CollectedRewards[Tier] then
					continue
				end
				
				RemoteFunctions.TimeRewards:InvokeServer({
					Command = "RedeemTier",
					Tier = Tier
				})
				
				CollectedRewards[Tier] = true
			end
			
			task.wait(5)
		end
    end
})

autofarmextraSection:AddToggle("AutoCollectSalaryRewards", {
    Title = "Auto Open Magnet Boxes",
    Description = "",
    Default = false,
    Callback = function(Value)
		while Value and task.wait() do
			for _, Tool in LocalPlayer.Backpack:GetChildren() do
				if not Tool.Name:find("Magnet Box") then
					continue
				end
				
				RemoteEvents.Treasure:FireServer({
					Command = "RedeemContainer",
					Container = Tool
				})
			end
		end
    end
})

local miscSection = Tabs.Misc:AddSection("Misc")

miscSection:AddToggle("EnableSpeedChanger", {
    Title = "Hide Game UIs",
    Description = "",
    Default = false,
    Callback = function(state)
        local player = game.Players.LocalPlayer
        local playerGui = player:WaitForChild("PlayerGui")
        local mainUI = playerGui:FindFirstChild("Main")
        if mainUI then
            mainUI.Enabled = not state
        end
    end
})

miscSection:AddToggle("EnableSpeedChanger", {
    Title = "Hide Performance UI",
    Description = "",
    Default = false,
    Callback = function(state)
        local player = game.Players.LocalPlayer
        local playerGui = player:WaitForChild("PlayerGui")
        local mainUI = playerGui:WaitForChild("Main")
        local CoreUI = mainUI:WaitForChild("Core")
        local performanceUI = CoreUI:FindFirstChild("Performance")
        if performanceUI then
            performanceUI.Visible = not state
        end
    end
})

miscSection:AddToggle("EnableSpeedChanger", {
    Title = "Hide Next Shovel Progress UI",
    Description = "",
    Default = false,
    Callback = function(state)
        local player = game.Players.LocalPlayer
        local playerGui = player:WaitForChild("PlayerGui")
        local mainUI = playerGui:WaitForChild("Main")
        local CoreUI = mainUI:WaitForChild("Core")
        local NextShovelProgressUI = CoreUI:FindFirstChild("NextShovelProgress")
        if NextShovelProgressUI then
            NextShovelProgressUI.Visible = not state
        end
    end
})

local sellSection = Tabs.Misc:AddSection("Sell")

local SellEnabled = false

local function SellInventory()
	SellEnabled = true
	LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	local Capacity = LocalPlayer.PlayerGui.Main.Core.Inventory.Disclaimer.Capacity

	local Inventory = RemoteFunctions.Player:InvokeServer({
 	   Command = "GetInventory"
	})

	local AnyObjects = false
	for _, Object in Inventory do
		if not Object.Attributes.Weight then
			continue
		end

		AnyObjects = true
		break
	end

	if not AnyObjects then
		task.wait(5)
		return
	end

	for i,v: TextLabel in workspace.Map.Islands:GetDescendants() do
		if v.Name ~= "Title" or not v:IsA("TextLabel") or v.Text ~= "Merchant" then
			continue
		end

		local Merchant = v.Parent.Parent
		local PreviousPosition = LocalPlayer.Character:GetPivot()
		local PreviousText = Capacity.Text

		repeat
			LocalPlayer.Character:PivotTo(Merchant:GetPivot())

			RemoteEvents.Merchant:FireServer({
				Command = "SellAllTreasures",
				Merchant = Merchant
			})

			task.wait(0.1)
		until Capacity.Text ~= PreviousText or not SellEnabled
		LocalPlayer.Character:PivotTo(PreviousPosition)
		break
	end
    SellEnabled = false
end

sellSection:AddButton({
    Title = "Sell Inventory",
    Description = "",
    Callback = SellInventory,
})

sellSection:AddToggle("EnableSpeedChanger", {
    Title = "Auto Sell Inventory When Full",
    Description = "",
    Default = false,
    Callback = function(state)
        AutoSell = state
		while AutoSell and task.wait() do
			local Capacity = LocalPlayer.PlayerGui.Main.Core.Inventory.Disclaimer.Capacity
			local Current = tonumber(Capacity.Text:split("(")[2]:split("/")[1])
			local Max = tonumber(Capacity.Text:split(")")[1]:split("/")[2])

			if Current < Max then
				continue
			end
			
			SellInventory()
		end
    end
})

local PurchaseSection = Tabs.Misc:AddSection("Purchase")

PurchaseSection:AddButton({
    Title = "Purchase Magnet Boxes",
    Description = "",
	Callback = function()
		RemoteFunctions.Shop:InvokeServer({
			Command = "Buy",
			Type = "Item",
			Product = "Magnet Box",
			Amount = boxamouttopurchase
		})
	end,
})

PurchaseSection:AddSlider("SpeedSlider", {
    Title = "Amount of Magnet Boxes to Purchase",
    Description = "",
    Min = 1,
    Max = 100,
    Default = 1,
    Rounding = 0,
    Callback = function(value)
        boxamouttopurchase = value
    end
})

local fpssection = Tabs.Misc:AddSection("FPS")

fpssection:AddToggle("NoClip", {
    Title = "Disable 3D Rendering",
    Default = false,
    Callback = function(Value)
       if Value then
           RunService:Set3dRenderingEnabled(false)
       else
           RunService:Set3dRenderingEnabled(true)
       end
    end
})

fpssection:AddButton({
    Title = "Load FPS Boost",
    Description = "",
    Callback = function()
        Window:Dialog({
            Title = "Confirmation",
            Content = "Are you sure you want to run FPS Boost? It may cause lag for a few seconds.",
            Buttons = {
                {
                    Title = "Yes",
                    Callback = function()
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/phodErS/Scripts/refs/heads/main/FpsBoost.lua"))()
                    end
                },
                {
                    Title = "No",
                    Callback = function()
                    end
                }
            }
        })
    end
})

local flysection = Tabs.Character:AddSection("Fly")

local function getRoot(character)
    return character:FindFirstChild("HumanoidRootPart")
end

function sFLY()
    repeat wait() until Players.LocalPlayer and Players.LocalPlayer.Character and getRoot(Players.LocalPlayer.Character) and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    
    local T = getRoot(Players.LocalPlayer.Character)
    local CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
    local SPEED = 0

    local function FLY()
        FLYING = true
        local BG = Instance.new('BodyGyro')
        local BV = Instance.new('BodyVelocity')
        BG.P = 9e4
        BG.Parent = T
        BV.Parent = T
        BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        BG.CFrame = T.CFrame
        BV.Velocity = Vector3.new(0, 0, 0)
        BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)

        local humanoid = Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        humanoid.PlatformStand = true

        task.spawn(function()
            repeat wait()
                if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0 then
                    SPEED = iyflyspeed
                else
                    SPEED = 0
                end

                BV.Velocity = ((workspace.CurrentCamera.CFrame.LookVector * (CONTROL.F + CONTROL.B)) + ((workspace.CurrentCamera.CFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p) - workspace.CurrentCamera.CFrame.p)) * SPEED
                BG.CFrame = workspace.CurrentCamera.CFrame
            until not FLYING

            CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
            SPEED = 0
            BG:Destroy()
            BV:Destroy()
            humanoid.PlatformStand = false
        end)
    end

    local flyKeyDown, flyKeyUp
    flyKeyDown = IYMouse.KeyDown:Connect(function(KEY)
        if not FLYING then return end
        if KEY:lower() == 'w' then
            CONTROL.F = 1
        elseif KEY:lower() == 's' then
            CONTROL.B = -1
        elseif KEY:lower() == 'a' then
            CONTROL.L = -1
        elseif KEY:lower() == 'd' then 
            CONTROL.R = 1
        elseif KEY:lower() == 'e' then
            CONTROL.Q = 1
        elseif KEY:lower() == 'q' then
            CONTROL.E = -1
        end
    end)

    flyKeyUp = IYMouse.KeyUp:Connect(function(KEY)
        if not FLYING then return end
        if KEY:lower() == 'w' then
            CONTROL.F = 0
        elseif KEY:lower() == 's' then
            CONTROL.B = 0
        elseif KEY:lower() == 'a' then
            CONTROL.L = 0
        elseif KEY:lower() == 'd' then
            CONTROL.R = 0
        elseif KEY:lower() == 'e' then
            CONTROL.Q = 0
        elseif KEY:lower() == 'q' then
            CONTROL.E = 0
        end
    end)

    FLY()
end

function NOFLY()
    FLYING = false
    if flyKeyDown or flyKeyUp then flyKeyDown:Disconnect() flyKeyUp:Disconnect() end
    if Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid') then
        Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
    end
end

local FlyToggle = flysection:AddToggle("FlyToggle", { Title = "Enable Fly", Default = false })

local SpeedSlider = flysection:AddSlider("FlySpeed", {
    Title = "Fly Speed",
    Description = "Adjust the speed of flying",
    Default = 30,
    Min = 30,
    Max = 300,
    Rounding = 1,
    Callback = function(value)
        iyflyspeed = value
    end
})

local FlyKeybind = flysection:AddKeybind("FlyKeybind", {
    Title = "Fly Keybind",
    Default = "F",
    Mode = "Toggle",
    Callback = function(value)
        if FlyToggle.Value then
            if FLYING then
                NOFLY()
            else
                sFLY()
            end
        end
    end
})

local SpeedChangerSection = Tabs.Character:AddSection("Speed Changer")

local SpeedChangerToggle = Tabs.Character:AddToggle("EnableSpeedChanger", {
    Title = "Enable Speed Changer",
    Description = "",
    Default = false,
    Callback = function(state)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        if state then
            humanoid.WalkSpeed = SpeedSliderValue
        else
            humanoid.WalkSpeed = 16
        end
    end
})

local speedSlider = Tabs.Character:AddSlider("SpeedSlider", {
    Title = "Speed",
    Description = "",
    Min = 16,
    Max = 200,
    Default = 16,
    Rounding = 1,
    Callback = function(value)
        SpeedSliderValue = value
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        if SpeedChangerToggle.Value then
            humanoid.WalkSpeed = value
        end
    end
})

local JumpPowerChangerSection = Tabs.Character:AddSection("Jump Power Changer")

local JumpPowerChangerToggle = Tabs.Character:AddToggle("EnableJumpPowerChanger", {
    Title = "Enable Jump Power Changer",
    Description = "",
    Default = false,
    Callback = function(state)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        if state then
            humanoid.JumpPower = JumpPowerValue
        else
            humanoid.JumpPower = 50
        end
    end
})

local jumpPowerSlider = Tabs.Character:AddSlider("JumpPowerSlider", {
    Title = "Jump Power",
    Description = "",
    Min = 50,
    Max = 200,
    Default = 50,
    Rounding = 1,
    Callback = function(value)
        JumpPowerValue = value
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        if JumpPowerChangerToggle.Value then
            humanoid.JumpPower = value
        end
    end
})

local FOVChangerSection = Tabs.Character:AddSection("FOV Changer")

local FOVChangerToggle = Tabs.Character:AddToggle("EnableFOVChanger", {
    Title = "Enable FOV Changer",
    Description = "",
    Default = false,
    Callback = function(state)
        local player = game.Players.LocalPlayer
        if state then
            game.Workspace.CurrentCamera.FieldOfView = FOVValue
        else
            game.Workspace.CurrentCamera.FieldOfView = 70
        end
    end
})

local fovSlider = Tabs.Character:AddSlider("FOVSlider", {
    Title = "Field of View",
    Description = "",
    Min = 70,
    Max = 120,
    Default = 70,
    Rounding = 1,
    Callback = function(value)
        FOVValue = value
        local player = game.Players.LocalPlayer
        if FOVChangerToggle.Value then
            game.Workspace.CurrentCamera.FieldOfView = value
        end
    end
})

RunService.Heartbeat:Connect(function()
    local player = game.Players.LocalPlayer
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            if SpeedChangerToggle.Value then
                humanoid.WalkSpeed = SpeedSliderValue
            end
            if JumpPowerChangerToggle.Value then
                humanoid.JumpPower = JumpPowerValue
            end
        end
        
        if FOVChangerToggle.Value then
            game.Workspace.CurrentCamera.FieldOfView = FOVValue
        end
    end
end)

local Islands = {}

for i,v in workspace.Map.Islands:GetChildren() do
	table.insert(Islands, v.Name)
end

for i,v in ReplicatedStorage.Assets.Sounds.Soundtrack.Locations:GetChildren() do
	if v.Name == "Ocean" then
		continue
	end

	if not table.find(Islands, v.Name) then
		table.insert(Islands, v.Name)
	end
end

table.sort(Islands)

local IslandTPDropdown = Tabs.Teleports:AddDropdown("TeleportAreas", {
    Title = "Teleport to Island",
    Description = "",
    Values = Islands,
    Multi = false,
    Default = '',
})

IslandTPDropdown:OnChanged(function(CurrentOption)
    if CurrentOption == "" or CurrentOption == nil then
        return
    end

    local Island = workspace.Map.Islands:FindFirstChild(CurrentOption)

    if not Island then
        Fluent:Notify({
            Title = "Teleport Error",
            Content = "That island doesn't currently exist.",
            Duration = 5
        })
        IslandTPDropdown:SetValue(nil)
        return
    end

    if Island:FindFirstChild("LocationSpawn") then
        LocalPlayer.Character:PivotTo(Island.LocationSpawn.CFrame)
    else
        LocalPlayer.Character:PivotTo(Island:GetAttribute("Pivot") + Vector3.yAxis * Island:GetAttribute("Size") / 2)
    end

    IslandTPDropdown:SetValue(nil)
end)

local Watermark = {}

Watermark["1"] = Instance.new("ScreenGui", game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"))
Watermark["1"]["Name"] = [[Watermark]]
Watermark["1"]["ZIndexBehavior"] = Enum.ZIndexBehavior.Sibling
Watermark["1"].Enabled = true

Watermark["2"] = Instance.new("Frame", Watermark["1"])
Watermark["2"]["BorderSizePixel"] = 0
Watermark["2"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
Watermark["2"]["Size"] = UDim2.new(0, 316, 0, 50)
Watermark["2"]["Position"] = UDim2.new(0, 0, 0.33951, 0)
Watermark["2"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
Watermark["2"]["Name"] = [[MainFrame]]
Watermark["2"]["BackgroundTransparency"] = 1

Watermark["3"] = Instance.new("ImageLabel", Watermark["2"])
Watermark["3"]["BorderSizePixel"] = 0
Watermark["3"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
Watermark["3"]["Image"] = [[http://www.roblox.com/asset/?id=96418561036855]]
Watermark["3"]["Size"] = UDim2.new(0, 55, 0, 55)
Watermark["3"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
Watermark["3"]["BackgroundTransparency"] = 1
Watermark["3"]["Name"] = [[LogoImage]]
Watermark["3"]["Position"] = UDim2.new(0.01899, 0, 0.02157, 0)

Watermark["4"] = Instance.new("TextLabel", Watermark["2"])
Watermark["4"]["TextStrokeTransparency"] = 0.78
Watermark["4"]["BorderSizePixel"] = 0
Watermark["4"]["TextStrokeColor3"] = Color3.fromRGB(64, 64, 64)
Watermark["4"]["TextXAlignment"] = Enum.TextXAlignment.Left
Watermark["4"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
Watermark["4"]["TextSize"] = 14
Watermark["4"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal)
Watermark["4"]["TextColor3"] = Color3.fromRGB(171, 143, 255)
Watermark["4"]["BackgroundTransparency"] = 1
Watermark["4"]["Size"] = UDim2.new(0, 70, 0, 24)
Watermark["4"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
Watermark["4"]["Text"] = [[Nixius.xyz]]
Watermark["4"]["Name"] = [[Title]]
Watermark["4"]["Position"] = UDim2.new(0.19304, 0, 0.02, 0)

Watermark["5"] = Instance.new("TextLabel", Watermark["2"])
Watermark["5"]["TextStrokeTransparency"] = 0.78
Watermark["5"]["BorderSizePixel"] = 0
Watermark["5"]["TextStrokeColor3"] = Color3.fromRGB(64, 64, 64)
Watermark["5"]["TextXAlignment"] = Enum.TextXAlignment.Left
Watermark["5"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
Watermark["5"]["TextSize"] = 14
Watermark["5"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal)
Watermark["5"]["TextColor3"] = Color3.fromRGB(239, 239, 239)
Watermark["5"]["BackgroundTransparency"] = 1
Watermark["5"]["Size"] = UDim2.new(0, 92, 0, 24)
Watermark["5"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
Watermark["5"]["Text"] = [[Fps: ... | Ping : ...]]
Watermark["5"]["Name"] = [[Info]]
Watermark["5"]["Position"] = UDim2.new(0.19304, 0, 0.32, 0)

local function updateWatermarkInfo()
    local fps = math.floor(1 / RunService.RenderStepped:Wait())
    local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())  -- Getting Ping
    Watermark["5"]["Text"] = "Fps: " .. fps .. " | Ping: " .. ping
end

RunService.RenderStepped:Connect(updateWatermarkInfo)

Watermark["6"] = Instance.new("TextLabel", Watermark["2"])
Watermark["6"]["TextStrokeTransparency"] = 0.78
Watermark["6"]["BorderSizePixel"] = 0
Watermark["6"]["TextStrokeColor3"] = Color3.fromRGB(64, 64, 64)
Watermark["6"]["TextXAlignment"] = Enum.TextXAlignment.Left
Watermark["6"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
Watermark["6"]["TextSize"] = 14
Watermark["6"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal)
Watermark["6"]["TextColor3"] = Color3.fromRGB(239, 239, 239)
Watermark["6"]["BackgroundTransparency"] = 1
Watermark["6"]["Size"] = UDim2.new(0, 92, 0, 24)
Watermark["6"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
Watermark["6"]["Text"] = game:GetService("MarketplaceService"):GetProductInfo("76455837887178").Name
Watermark["6"]["Name"] = [[Game]]
Watermark["6"]["Position"] = UDim2.new(0.19304, 0, 0.64, 0)

local MobileToggle = {}

MobileToggle["1"] = Instance.new("ScreenGui", game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"))
MobileToggle["1"].Name = "UIToggleButtonMobile"
MobileToggle["1"].ZIndexBehavior = Enum.ZIndexBehavior.Sibling
MobileToggle["1"].Enabled = true

MobileToggle["2"] = Instance.new("Frame", MobileToggle["1"])
MobileToggle["2"].BorderSizePixel = 0
MobileToggle["2"].BackgroundColor3 = Color3.fromRGB(138, 122, 255)
MobileToggle["2"].Size = UDim2.new(0, 65, 0, 65)
MobileToggle["2"].Position = UDim2.new(0.03591, 0, 0.66204, 0)
MobileToggle["2"].BorderColor3 = Color3.fromRGB(0, 0, 0)
MobileToggle["2"].Name = "ButtonFrame"
MobileToggle["2"].BackgroundTransparency = 0.65

MobileToggle["3"] = Instance.new("UICorner", MobileToggle["2"])
MobileToggle["3"].CornerRadius = UDim.new(1, 16)

MobileToggle["4"] = Instance.new("UIStroke", MobileToggle["2"])
MobileToggle["4"].Color = Color3.fromRGB(160, 147, 255)

MobileToggle["5"] = Instance.new("ImageLabel", MobileToggle["2"])
MobileToggle["5"].BorderSizePixel = 0
MobileToggle["5"].BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MobileToggle["5"].Image = "http://www.roblox.com/asset/?id=96418561036855"
MobileToggle["5"].Size = UDim2.new(0, 55, 0, 55)
MobileToggle["5"].BorderColor3 = Color3.fromRGB(0, 0, 0)
MobileToggle["5"].BackgroundTransparency = 1
MobileToggle["5"].Name = "LogoImage"
MobileToggle["5"].Position = UDim2.new(0.06514, 0, 0.06773, 0)

local WindowHidden = false
local dragging
local dragInput
local dragStart
local startPos

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
-- SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("Nixius.xyz")
SaveManager:SetFolder("Nixius.xyz/Digit")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)

Tabs.Settings:AddToggle("WatermarkToggle", {
    Title = "Show Watermark",
    Default = true,
    Callback = function(state)
        Watermark["1"].Enabled = state
    end
})

Tabs.Settings:AddSlider("WatermarkPositionY", {
    Title = "Watermark Y Position",
    Description = "",
    Min = 300,
    Max = 800,
    Default = 350,
    Rounding = 1,
    Callback = function(value)
        Watermark["2"].Position = UDim2.new(0, 0, 0, value)
    end
})

Tabs.Settings:AddToggle("moblikeToggle", {
    Title = "UI Toggle Button",
    Default = true,
    Callback = function(state)
        MobileToggle["1"].Enabled = state
    end
})

Window:SelectTab(1)
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

MobileToggle["2"].InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if WindowHidden then
            Window:Minimize()
            WindowHidden = false
        else
            Window:Minimize()
            WindowHidden = true
        end
    end
end)

MobileToggle["2"].InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MobileToggle["2"].Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

MobileToggle["2"].InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MobileToggle["2"].Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)
