-- Made By laagginq
-- Edited By Nivex
local tweenService, coreGui = game:GetService("TweenService"), game:GetService("CoreGui")
local insert, find, remove = table.insert, table.find, table.remove
local format = string.format
local newInstance = Instance.new
local fromRGB = Color3.fromRGB
local notificationPositions = {["Middle"] = UDim2.new(0.4, 0, 0.65, 0)}

function protectScreenGui(screenGui)
    if syn and syn.protect_gui then
        syn.protect_gui(screenGui)
        screenGui.Parent = coreGui
    elseif gethui then
        screenGui.Parent = gethui()
    else
        screenGui.Parent = coreGui
    end
end

function createObject(className, properties)
    local instance = newInstance(className)
    for index, value in next, properties do
        instance[index] = value
    end
    return instance
end

function fadeInObject(object, finalPosition)
    object.Position = UDim2.new(-0.3, 0, 0, finalPosition.Y.Offset)
    object.TextTransparency = 1
    object.TextStrokeTransparency = 1

    local tweenIn = tweenService:Create(object, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = finalPosition,
        TextTransparency = 0,
        TextStrokeTransparency = 0
    })
    tweenIn:Play()
end

function fadeOutObject(object, onComplete)
    local tweenOut = tweenService:Create(object, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.new(1.5, 0, 0, object.Position.Y.Offset),
        TextTransparency = 1,
        TextStrokeTransparency = 1
    })
    tweenOut.Completed:Connect(function()
        if onComplete then onComplete() end
    end)
    tweenOut:Play()
end

local notifications = {}

do
    function notifications.new(settings)
        assert(settings and typeof(settings) == "table", "Expected table for settings")
        local self = {
            ui = {
                notificationsFrame = nil,
                activeNotifications = {},
            }
        }

        for k, v in next, settings do
            self[k] = v
        end

        setmetatable(self, { __index = notifications })
        return self
    end

    function notifications:SetNotificationLifetime(number)
        self.NotificationLifetime = number
    end

    function notifications:SetTextColor(color3)
        self.TextColor = color3
    end

    function notifications:SetTextSize(number)
        self.TextSize = number
    end

    function notifications:SetTextStrokeTransparency(number)
        self.TextStrokeTransparency = number
    end

    function notifications:SetTextStrokeColor(color3)
        self.TextStrokeColor = color3
    end

    function notifications:SetTextFont(font)
        self.TextFont = typeof(font) == "string" and Enum.Font[font] or font
    end

    function notifications:BuildNotificationUI()
        if notifications_screenGui then
            notifications_screenGui:Destroy()
        end

        getgenv().notifications_screenGui = createObject("ScreenGui", {
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        })

        protectScreenGui(notifications_screenGui)

        self.ui.notificationsFrame = createObject("Frame", {
            Name = "notificationsFrame",
            Parent = notifications_screenGui,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            Position = notificationPositions["Middle"],
            Size = UDim2.new(0, 320, 0, 400),
            ClipsDescendants = true
        })
    end

    function notifications:UpdateNotificationPositions()
        task.defer(function()
            local yOffset = 0
            for _, notification in ipairs(self.ui.activeNotifications) do
                if notification and notification.Parent then
                    local goal = UDim2.new(0, 10, 0, yOffset)
                    local tween = tweenService:Create(notification, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                        Position = goal
                    })
                    tween:Play()
                    yOffset += notification.AbsoluteSize.Y + 10
                end
            end
        end)
    end

    function notifications:Notify(text)
        local notifHeight = 40
        local yOffset = 0
        for _, n in ipairs(self.ui.activeNotifications) do
            yOffset += n.AbsoluteSize.Y + 10
        end

        local notification = createObject("TextLabel", {
            Name = "notification",
            Parent = self.ui.notificationsFrame,
            BackgroundColor3 = Color3.fromRGB(30, 30, 30),
            BackgroundTransparency = 0,
            Size = UDim2.new(1, -20, 0, notifHeight),
            Position = UDim2.new(0, 10, 0, yOffset),
            Text = text,
            Font = self.TextFont,
            TextColor3 = self.TextColor,
            TextSize = self.TextSize,
            TextStrokeColor3 = self.TextStrokeColor,
            TextStrokeTransparency = self.TextStrokeTransparency,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        local corner = Instance.new("UICorner", notification)
        corner.CornerRadius = UDim.new(0, 6)

        local padding = Instance.new("UIPadding", notification)
        padding.PaddingLeft = UDim.new(0, 10)
        padding.PaddingRight = UDim.new(0, 10)

        insert(self.ui.activeNotifications, notification)

        fadeInObject(notification, notification.Position)

        task.delay(self.NotificationLifetime, function()
            fadeOutObject(notification, function()
                local index = find(self.ui.activeNotifications, notification)
                if index then
                    remove(self.ui.activeNotifications, index)
                end
                notification:Destroy()
                self:UpdateNotificationPositions()
            end)
        end)

        self:UpdateNotificationPositions()
    end
end

return notifications
