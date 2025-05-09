-- Made By laagginq
-- Edited By Nivex
local tweenService, coreGui = game:GetService("TweenService"), game:GetService("CoreGui");
local insert, find, remove = table.insert, table.find, table.remove
local format = string.format
local newInstance = Instance.new
local fromRGB = Color3.fromRGB
local notificationPositions = {
    ["Middle"] = UDim2.new(0.445, 0, 0.7, 0),
};
function protectScreenGui(screenGui)
    if syn and syn.protect_gui then
        syn.protect_gui(screenGui);
        screenGui.Parent = coreGui
    elseif gethui then
        screenGui.Parent = gethui();
    else
        screenGui.Parent = coreGui;
    end
end
function createObject(className, properties)
    local instance = newInstance(className);
    for index, value in next, properties do
        instance[index] = value
    end
    return instance
end
function fadeObject(object, onTweenCompleted, direction)
    local endPosition = object.Position
    local startPosition = endPosition
    local fadeOut = false
    if direction == "right" then
        startPosition = UDim2.new(1.5, 0, endPosition.Y.Scale, endPosition.Y.Offset)
        fadeOut = true
    elseif direction == "left" then
        startPosition = UDim2.new(-0.2, 0, endPosition.Y.Scale, endPosition.Y.Offset)
        fadeOut = false
    elseif direction == "none" then
        startPosition = endPosition
        fadeOut = false
    end
    object.Position = startPosition;
    local tweenInformation = tweenService:Create(object, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
        Position = endPosition,
        TextTransparency = (fadeOut) and 1 or 0,
        TextStrokeTransparency = (fadeOut) and 1 or 0
    });
    tweenInformation.Completed:Connect(onTweenCompleted);
    tweenInformation:Play();
end
local notifications = {};
do
    function notifications.new(settings)
        assert(settings, "missing argument #1 in function notifications.new(settings)");
        assert(typeof(settings) == "table", format("expected table for argument #1 in function notifications.new(settings), got %s", typeof(settings)));
        local notificationSettings = { ui = { notificationsFrame = nil, notificationsFrame_UIListLayout = nil } };
        for setting, value in next, settings do
            notificationSettings[setting] = value
        end
        setmetatable(notificationSettings, { __index = notifications });
        return notificationSettings
    end
    function notifications:SetNotificationLifetime(number)
        assert(number, "missing argument #1 in function SetNotificationLifetime(number)");
        assert(typeof(number) == "number", format("expected number for argument #1 in function SetNotificationLifetime, got %s", typeof(number)));
        self.NotificationLifetime = number
    end
    function notifications:SetTextColor(color3)
        assert(color3, "missing argument #1 in function SetTextColor(Color3)");
        assert(typeof(color3) == "Color3", format("expected Color3 for argument #1 in function SetTextColor, got %s", typeof(color3)));
        self.TextColor = color3
    end
    function notifications:SetTextSize(number)
        assert(number, "missing argument #1 in function SetTextSize(number)");
        assert(typeof(number) == "number", format("expected number for argument #1 in function SetTextSize, got %s", typeof(number)));
        self.TextSize = number
    end
    function notifications:SetTextStrokeTransparency(number)
        assert(number, "missing argument #1 in function SetTextStrokeTransparency(number)");
        assert(typeof(number) == "number", format("expected number for argument #1 in function SetTextStrokeTransparency, got %s", typeof(number)));
        self.TextStrokeTransparency = number
    end
    function notifications:SetTextStrokeColor(color3)
        assert(color3, "missing argument #1 in function SetTextStrokeColor(Color3)");
        assert(typeof(color3) == "Color3", format("expected Color3 for argument #1 in function SetTextStrokeColor, got %s", typeof(color3)));
        self.TextStrokeColor = color3
    end
    function notifications:SetTextFont(font)
        assert(font, "missing argument #1 in function SetTextFont(Font)");
        assert((typeof(font) == "string" or typeof(font) == "EnumItem"))
        self.TextFont = Enum.Font[font];
    end
    function notifications:BuildNotificationUI()
        if notifications_screenGui then
            notifications_screenGui:Destroy();
        end
        getgenv().notifications_screenGui = createObject("ScreenGui", {
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        });
        protectScreenGui(notifications_screenGui);
        self.ui.notificationsFrame = createObject("Frame", {
            Name = "notificationsFrame",
            Parent = notifications_screenGui,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1.000,
            Position = notificationPositions["Middle"],
            Size = UDim2.new(0, 236, 0, 215)
        });
        self.ui.notificationsFrame_UIListLayout = createObject("UIListLayout", {
            Name = "notificationsFrame_UIListLayout",
            Parent = self.ui.notificationsFrame,
            Padding = UDim.new(0, 1),
            SortOrder = Enum.SortOrder.LayoutOrder
        });
    end
    function notifications:Notify(text)
        local notification = createObject("TextLabel", {
            Name = "notification",
            Parent = self.ui.notificationsFrame,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1.000,
            Size = UDim2.new(0, 222, 0, 14),
            Text = text,
            Font = self.TextFont,
            TextColor3 = self.TextColor,
            TextSize = self.TextSize,
            TextStrokeColor3 = self.TextStrokeColor,
            TextStrokeTransparency = self.TextStrokeTransparency
        });
        fadeObject(notification, function()
            task.delay(self.NotificationLifetime, function()
                fadeObject(notification, function()
                    notification:Destroy();
                end, "right");
            end);
        end, "left");
    end
end
return notifications
