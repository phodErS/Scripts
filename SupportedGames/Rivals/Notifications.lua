-- Made By laagginq
-- Edited By Nivex
local tweenService, coreGui = game:GetService("TweenService"), game:GetService("CoreGui")
local insert, find, remove = table.insert, table.find, table.remove
local format = string.format
local newInstance = Instance.new
local fromRGB = Color3.fromRGB

local notificationPositions = {
    ["Middle"] = UDim2.new(0.445, 0, 0.7, 0),
}

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

function fadeObject(object, onTweenCompleted, direction)
    local originalPosition = object.Position
    local startPosition = originalPosition
    local endPosition = originalPosition
    local transparencyGoal = { TextTransparency = 0, TextStrokeTransparency = 0 }

    if direction == "left" then
        startPosition = UDim2.new(-0.2, 0, originalPosition.Y.Scale, originalPosition.Y.Offset)
        endPosition = originalPosition
        object.Position = startPosition
        object.TextTransparency = 1
        object.TextStrokeTransparency = 1
        transparencyGoal = { TextTransparency = 0, TextStrokeTransparency = 0 }
    elseif direction == "right" then
        endPosition = UDim2.new(1.5, 0, originalPosition.Y.Scale, originalPosition.Y.Offset)
        transparencyGoal = { TextTransparency = 1, TextStrokeTransparency = 1 }
    end

    local tweenPosition = tweenService:Create(object, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
        Position = endPosition
    })
    local tweenFade = tweenService:Create(object, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), transparencyGoal)

    tweenPosition:Play()
    tweenFade:Play()

    tweenPosition.Completed:Connect(function()
        if onTweenCompleted then onTweenCompleted() end
    end)
end

local notifications = {}

do
    function notifications.new(settings)
        assert(settings, "missing argument #1 in function notifications.new(settings)")
        assert(typeof(settings) == "table", format("expected table for argument #1 in function notifications.new(settings), got %s", typeof(settings)))

        local notificationSettings = {
            ui = {
                notificationsFrame = nil,
                activeNotifications = {},
            }
        }

        for setting, value in next, settings do
            notificationSettings[setting] = value
        end

        setmetatable(notificationSettings, { __index = notifications })
        return notificationSettings
    end

    function notifications:SetNotificationLifetime(number)
        assert(typeof(number) == "number", format("expected number, got %s", typeof(number)))
        self.NotificationLifetime = number
    end

    function notifications:SetTextColor(color3)
        assert(typeof(color3) == "Color3", format("expected Color3, got %s", typeof(color3)))
        self.TextColor = color3
    end

    function notifications:SetTextSize(number)
        assert(typeof(number) == "number", format("expected number, got %s", typeof(number)))
        self.TextSize = number
    end

    function notifications:SetTextStrokeTransparency(number)
        assert(typeof(number) == "number", format("expected number, got %s", typeof(number)))
        self.TextStrokeTransparency = number
    end

    function notifications:SetTextStrokeColor(color3)
        assert(typeof(color3) == "Color3", format("expected Color3, got %s", typeof(color3)))
        self.TextStrokeColor = color3
    end

    function notifications:SetTextFont(font)
        assert(font, "missing argument #1 in function SetTextFont(Font)")
        assert(typeof(font) == "string" or typeof(font) == "EnumItem", "Font must be string or EnumItem")
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
            BackgroundTransparency = 1.000,
            Position = notificationPositions["Middle"],
            Size = UDim2.new(0, 236, 0, 215),
            ClipsDescendants = true
        })
    end

    function notifications:UpdateNotificationPositions()
        task.defer(function()
            local yOffset = 0
            for i, notification in ipairs(self.ui.activeNotifications) do
                if notification and notification.Parent then
                    local goal = UDim2.new(0, 0, 0, yOffset)
                    local tween = tweenService:Create(notification, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                        Position = goal
                    })
                    tween:Play()
                    yOffset = yOffset + notification.AbsoluteSize.Y + 4
                end
            end
        end)
    end

    function notifications:Notify(text)
        local notification = createObject("TextLabel", {
            Name = "notification",
            Parent = self.ui.notificationsFrame,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1.000,
            Size = UDim2.new(0, 222, 0, 20),
            Position = UDim2.new(0, 0, 0, 0),
            Text = text,
            Font = self.TextFont,
            TextColor3 = self.TextColor,
            TextSize = self.TextSize,
            TextStrokeColor3 = self.TextStrokeColor,
            TextStrokeTransparency = self.TextStrokeTransparency,
            RichText = true
        })

        insert(self.ui.activeNotifications, notification)

        fadeObject(notification, function()
            task.delay(self.NotificationLifetime, function()
                fadeObject(notification, function()
                    local index = find(self.ui.activeNotifications, notification)
                    if index then
                        remove(self.ui.activeNotifications, index)
                    end
                    notification:Destroy()
                    self:UpdateNotificationPositions()
                end, "right")
            end)
        end, "left")

        self:UpdateNotificationPositions()
    end
end

return notifications
