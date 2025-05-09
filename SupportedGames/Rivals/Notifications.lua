-- Made By laagginq
-- Edited By Nivex
local tweenService, coreGui = game:GetService("TweenService"), game:GetService("CoreGui")
local insert, find, remove = table.insert, table.find, table.remove
local format = string.format
local newInstance = Instance.new
local fromRGB = Color3.fromRGB
local notificationPositions = {["Middle"] = UDim2.new(0.445, 0, 0.7, 0)};

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
    local startPosition, endPosition = originalPosition, originalPosition
    local transparencyGoal = { TextTransparency = 0, TextStrokeTransparency = 0 }

    if direction == "left" then
        startPosition = UDim2.new(-0.3, 0, originalPosition.Y.Scale, originalPosition.Y.Offset)
        object.Position = startPosition
        object.TextTransparency = 1
        object.TextStrokeTransparency = 1
    elseif direction == "right" then
        endPosition = UDim2.new(1.3, 0, originalPosition.Y.Scale, originalPosition.Y.Offset)
        transparencyGoal = { TextTransparency = 1, TextStrokeTransparency = 1 }
    end

    local tweenPosition = tweenService:Create(object, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
        Position = endPosition
    })

    local tweenFade = tweenService:Create(object, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), transparencyGoal)

    tweenPosition:Play()
    tweenFade:Play()

    tweenFade.Completed:Connect(function()
        if onTweenCompleted then onTweenCompleted() end
    end)
end

local notifications = {}

do
    function notifications.new(settings)
        assert(settings and typeof(settings) == "table", "Expected a table for settings")
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

    function notifications:SetNotificationLifetime(seconds)
        self.NotificationLifetime = seconds
    end

    function notifications:SetTextColor(color3)
        self.TextColor = color3
    end

    function notifications:SetTextSize(size)
        self.TextSize = size
    end

    function notifications:SetTextStrokeTransparency(value)
        self.TextStrokeTransparency = value
    end

    function notifications:SetTextStrokeColor(color3)
        self.TextStrokeColor = color3
    end

    function notifications:SetTextFont(font)
        self.TextFont = typeof(font) == "string" and Enum.Font[font] or font
    end

    function notifications:BuildNotificationUI()
        if getgenv().notifications_screenGui then
            getgenv().notifications_screenGui:Destroy()
        end

        getgenv().notifications_screenGui = createObject("ScreenGui", {
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        })

        protectScreenGui(getgenv().notifications_screenGui)

        self.ui.notificationsFrame = createObject("Frame", {
            Name = "notificationsFrame",
            Parent = getgenv().notifications_screenGui,
            BackgroundColor3 = fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 450, 0.7, 0),
            Size = UDim2.new(0, 1000, 0, 300),
            ClipsDescendants = true
        })
    end

    function notifications:UpdateNotificationPositions()
        local yOffset = 0
        for _, notification in ipairs(self.ui.activeNotifications) do
            if notification and notification.Parent then
                local goal = UDim2.new(0, 0, 0, yOffset)
                tweenService:Create(notification, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Position = goal
                }):Play()
                yOffset = yOffset + notification.AbsoluteSize.Y + 8
            end
        end
    end

    function notifications:Notify(text, ...)
        local formatted = text
        if select("#", ...) > 0 then
            formatted = format(text, ...)
        end

        local notification = createObject("TextLabel", {
            Name = "notification",
            Parent = self.ui.notificationsFrame,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -10, 0, 28),
            Position = UDim2.new(0, 0, 0, 0),
            Text = formatted,
            Font = self.TextFont or Enum.Font.SourceSans,
            TextColor3 = self.TextColor or Color3.new(1, 1, 1),
            TextSize = self.TextSize or 16,
            TextStrokeColor3 = self.TextStrokeColor or fromRGB(0, 0, 0),
            TextStrokeTransparency = self.TextStrokeTransparency or 0.5,
            RichText = true,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 10
        })

        insert(self.ui.activeNotifications, notification)

        fadeObject(notification, function()
            task.delay(self.NotificationLifetime or 3, function()
                fadeObject(notification, function()
                    local i = find(self.ui.activeNotifications, notification)
                    if i then
                        remove(self.ui.activeNotifications, i)
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
