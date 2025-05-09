-- Made By laagginq
-- Edited By Nivex
local tweenService, coreGui = game:GetService("TweenService"), game:GetService("CoreGui")
local insert, find, remove = table.insert, table.find, table.remove
local format = string.format
local newInstance = Instance.new
local fromRGB = Color3.fromRGB

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

function fadeObject(object, onTweenCompleted, direction, screenWidth)
    local originalPosition = object.Position
    local startPosition, endPosition = originalPosition, originalPosition
    local transparencyGoal = { TextTransparency = 0, TextStrokeTransparency = 0 }
    local startX, endX = -1, 2

    if screenWidth then
        startX = -1 * (screenWidth / 460)
        endX = 1 + (screenWidth / 460)
    end

    if direction == "left" then
        startPosition = UDim2.new(startX, 0, originalPosition.Y.Scale, originalPosition.Y.Offset)
        object.Position = startPosition
        object.TextTransparency = 1
        object.TextStrokeTransparency = 1
    elseif direction == "right" then
        endPosition = UDim2.new(endX, 0, originalPosition.Y.Scale, originalPosition.Y.Offset)
        transparencyGoal = { TextTransparency = 1, TextStrokeTransparency = 1 }
    end

    local tweenPosition = tweenService:Create(object, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
        Position = endPosition
    })

    local tweenFade = tweenService:Create(object, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), transparencyGoal)

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
                notificationHolder = nil,
                screenWidth = 0,
                screenHeight = 0
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
        if notifications_screenGui then
            notifications_screenGui:Destroy()
        end

        getgenv().notifications_screenGui = createObject("ScreenGui", {
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        })

        protectScreenGui(notifications_screenGui)

        self.ui.screenWidth = getgenv().notifications_screenGui.AbsoluteSize.X
        self.ui.screenHeight = getgenv().notifications_screenGui.AbsoluteSize.Y

        self.ui.notificationHolder = createObject("Frame", {
            Name = "notificationHolder",
            Parent = notifications_screenGui,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            ZIndex = 1
        })

        self.ui.notificationsFrame = createObject("Frame", {
            Name = "notificationsFrame",
            Parent = self.ui.notificationHolder,
            AnchorPoint = Vector2.new(0.5, 0.5),  -- Center the frame
            Position = UDim2.new(0.5, 0, 0.5, 0),      -- Position in the center
            Size = UDim2.new(1, 0, 0, 28), -- Make the frame full width, and only tall enough for one line of text
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            ZIndex = 2
        })
    end

    function notifications:UpdateNotificationPositions()
        local yOffset = 0
        for _, notification in ipairs(self.ui.activeNotifications) do
            if notification and notification.Parent then
                local goal = UDim2.new(0.5, 0, 0.5, yOffset) -- Keep it centered
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
            local args = {...}
            local allStrings = true
            for i, arg in ipairs(args) do
                if type(arg) ~= "string" then
                    allStrings = false
                    break
                end
            end
            if allStrings then
                formatted = format(text, unpack(args))
            else
                formatted = text
            end
        end

        local notification = createObject("TextLabel", {
            Name = "notification",
            Parent = self.ui.notificationsFrame,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 1), -- Full size of the frame.
            Position = UDim2.new(0.5, 0, 0.5, 0),  -- center
            Text = formatted,
            Font = self.TextFont or Enum.Font.SourceSans,
            TextColor3 = self.TextColor or Color3.new(1, 1, 1),
            TextSize = self.TextSize or 16,
            TextStrokeColor3 = self.TextStrokeColor or fromRGB(0, 0, 0),
            TextStrokeTransparency = self.TextStrokeTransparency or 0.5,
            RichText = true,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center, -- center
            TextScaled = true
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
                end, "right", self.ui.screenWidth)
            end)
        end, "left", self.ui.screenWidth)

        self:UpdateNotificationPositions()
    end
end

return notifications
