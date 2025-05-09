-- Made By laagginq
-- Edited By Nivex
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local insert, remove, find = table.insert, table.remove, table.find
local newInstance = Instance.new

local notificationPosition = UDim2.new(0.4, 0, 0.65, 0)

function protectScreenGui(screenGui)
    if syn and syn.protect_gui then
        syn.protect_gui(screenGui)
        screenGui.Parent = CoreGui
    elseif gethui then
        screenGui.Parent = gethui()
    else
        screenGui.Parent = CoreGui
    end
end

function createObject(className, properties)
    local instance = newInstance(className)
    for k, v in pairs(properties) do
        instance[k] = v
    end
    return instance
end

function fadeIn(notification, targetPosition)
    notification.Position = UDim2.new(-0.3, 0, 0, targetPosition.Y.Offset)
    notification.TextTransparency = 1
    notification.TextStrokeTransparency = 1

    local tween = TweenService:Create(notification, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
        Position = targetPosition,
        TextTransparency = 0,
        TextStrokeTransparency = 0
    })
    tween:Play()
end

function fadeOut(notification, onComplete)
    local tween = TweenService:Create(notification, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
        Position = UDim2.new(1.3, 0, 0, notification.Position.Y.Offset),
        TextTransparency = 1,
        TextStrokeTransparency = 1
    })
    tween.Completed:Connect(function()
        if onComplete then onComplete() end
    end)
    tween:Play()
end

local notifications = {}

do
    function notifications.new(settings)
        assert(typeof(settings) == "table", "Expected settings table")
        local self = {
            NotificationLifetime = 4,
            TextColor = Color3.new(1, 1, 1),
            TextSize = 18,
            TextStrokeTransparency = 0.5,
            TextStrokeColor = Color3.new(0, 0, 0),
            TextFont = Enum.Font.SourceSansBold,
            ui = {
                activeNotifications = {}
            }
        }

        for k, v in pairs(settings) do
            self[k] = v
        end

        setmetatable(self, { __index = notifications })
        return self
    end

    function notifications:SetNotificationLifetime(num)
        self.NotificationLifetime = num
    end

    function notifications:SetTextColor(color)
        self.TextColor = color
    end

    function notifications:SetTextSize(size)
        self.TextSize = size
    end

    function notifications:SetTextStrokeTransparency(val)
        self.TextStrokeTransparency = val
    end

    function notifications:SetTextStrokeColor(color)
        self.TextStrokeColor = color
    end

    function notifications:SetTextFont(font)
        self.TextFont = typeof(font) == "string" and Enum.Font[font] or font
    end

    function notifications:BuildNotificationUI()
        if getgenv().notifications_screenGui then
            getgenv().notifications_screenGui:Destroy()
        end

        getgenv().notifications_screenGui = createObject("ScreenGui", {
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            ResetOnSpawn = false
        })

        protectScreenGui(getgenv().notifications_screenGui)

        self.ui.notificationsFrame = createObject("Frame", {
            Parent = getgenv().notifications_screenGui,
            BackgroundTransparency = 1,
            Position = notificationPosition,
            Size = UDim2.new(0, 300, 0, 500),
            ClipsDescendants = false,
            Visible = true
        })
    end

    function notifications:UpdateNotificationPositions()
        task.defer(function()
            local yOffset = 0
            for _, notif in ipairs(self.ui.activeNotifications) do
                if notif and notif.Parent then
                    local goal = UDim2.new(0, 0, 0, yOffset)
                    local tween = TweenService:Create(notif, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                        Position = goal
                    })
                    tween:Play()
                    yOffset += notif.AbsoluteSize.Y + 10
                end
            end
        end)
    end

    function notifications:Notify(text)
        local notifHeight = 32
        local yOffset = 0
        for _, n in ipairs(self.ui.activeNotifications) do
            yOffset += n.AbsoluteSize.Y + 10
        end

        local notification = createObject("TextLabel", {
            Name = "notification",
            Parent = self.ui.notificationsFrame,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, notifHeight),
            Position = UDim2.new(0, 0, 0, yOffset),
            Text = text,
            Font = self.TextFont,
            TextColor3 = self.TextColor,
            TextSize = self.TextSize,
            TextStrokeColor3 = self.TextStrokeColor,
            TextStrokeTransparency = self.TextStrokeTransparency,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        insert(self.ui.activeNotifications, notification)
        fadeIn(notification, notification.Position)

        task.delay(self.NotificationLifetime, function()
            fadeOut(notification, function()
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
