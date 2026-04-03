--[[ 
    Integrated Aim Assist with FOV Circle
    Controls:
    [L] - Toggle Aim Assist
    [T] - Toggle Team Ignore
    [P] - Toggle Menu Visibility
]]

local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Configuration
local range = 100 -- This is the FOV Circle Radius
local aimAssistEnabled = false
local ignoreSameTeam = false
local aimHead = true
local uiVisible = true
local currentHighlight = nil

-- FOV Circle Drawing
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = true
fovCircle.Radius = range
fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Thickness = 1
fovCircle.Filled = false
fovCircle.Transparency = 1
fovCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

-- Function to find target closest to the center of the FOV
local function getTargetInFOV()
    local nearest = nil
    local shortestMouseDistance = range -- Max distance is the radius of the circle

    local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj ~= player.Character then
            local humanoid = obj:FindFirstChild("Humanoid")
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            
            if humanoid and hrp and humanoid.Health > 0 then
                -- Team Check
                local targetPlayer = game.Players:GetPlayerFromCharacter(obj)
                if ignoreSameTeam and targetPlayer and targetPlayer.Team == player.Team then
                    continue
                end

                -- Convert 3D position to 2D Screen position
                local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)

                if onScreen then
                    local mouseDistance = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    
                    if mouseDistance < shortestMouseDistance then
                        shortestMouseDistance = mouseDistance
                        nearest = obj
                    end
                end
            end
        end
    end
    return nearest
end

-- Update Loop
local function update()
    -- Sync Circle to Screen Center and Range Slider
    fovCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    fovCircle.Radius = range
    fovCircle.Visible = uiVisible

    if aimAssistEnabled then
        local target = getTargetInFOV()
        if target then
            local head = target:FindFirstChild("Head")
            local hrp = target:FindFirstChild("HumanoidRootPart")
            
            if hrp and head then
                local targetPosition = aimHead and head.Position or (hrp.Position + Vector3.new(0, 0.5, 0))

                -- Lock Camera
                camera.CFrame = CFrame.lookAt(camera.CFrame.Position, targetPosition)

                -- Highlight logic
                if currentHighlight and currentHighlight.Parent ~= target then
                    currentHighlight.Enabled = false
                end

                local highlight = target:FindFirstChildOfClass("Highlight")
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Parent = target
                    highlight.FillColor = Color3.fromRGB(255, 0, 0)
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                end
                highlight.Enabled = true
                currentHighlight = highlight
            end
        else
            if currentHighlight then currentHighlight.Enabled = false end
        end
    else
        if currentHighlight then
            currentHighlight.Enabled = false
            currentHighlight = nil
        end
    end
end

-- UI Setup
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "AimAssistGUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = uiVisible

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 220, 0, 160)
frame.Position = UDim2.new(0.5, -110, 0.75, 0)
frame.BackgroundColor3 = Color3.new(0.05, 0.05, 0.05)
frame.BorderSizePixel = 0

local toggleButton = Instance.new("TextLabel", frame)
toggleButton.Size = UDim2.new(1, 0, 0.4, 0)
toggleButton.BackgroundTransparency = 1
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 14
toggleButton.TextWrapped = true

local rangeSlider = Instance.new("Frame", frame)
rangeSlider.Size = UDim2.new(0.9, 0, 0.1, 0)
rangeSlider.Position = UDim2.new(0.05, 0, 0.5, 0)
rangeSlider.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

local sliderButton = Instance.new("Frame", rangeSlider)
sliderButton.Size = UDim2.new(0, 15, 1.5, 0)
sliderButton.AnchorPoint = Vector2.new(0.5, 0.15)
sliderButton.Position = UDim2.new(range/300, 0, 0, 0) -- Scaled to 300 max
sliderButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)

local sliderValue = Instance.new("TextLabel", frame)
sliderValue.Size = UDim2.new(1, 0, 0.2, 0)
sliderValue.Position = UDim2.new(0, 0, 0.7, 0)
sliderValue.BackgroundTransparency = 1
sliderValue.TextColor3 = Color3.new(1, 1, 1)
sliderValue.TextSize = 16
sliderValue.Text = "FOV Radius: " .. range

-- Slider Logic
local isDragging = false
sliderButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = true end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = false end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local relativeX = math.clamp((input.Position.X - rangeSlider.AbsolutePosition.X) / rangeSlider.AbsoluteSize.X, 0, 1)
        sliderButton.Position = UDim2.new(relativeX, 0, 0, 0)
        range = math.floor(relativeX * 300) -- Max FOV of 300
        sliderValue.Text = "FOV Radius: " .. range
    end
end)

-- UI Text Update
local function updateUIText()
    local assistText = aimAssistEnabled and "ON" or "OFF"
    local teamText = ignoreSameTeam and "ON" or "OFF"
    toggleButton.Text = string.format("AIM ASSIST: %s [L]\nIGNORE TEAMS: %s [T]\nHIDE MENU: [P]", assistText, teamText)
end

-- Input Handling
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.L then
        aimAssistEnabled = not aimAssistEnabled
    elseif input.KeyCode == Enum.KeyCode.T then
        ignoreSameTeam = not ignoreSameTeam
    elseif input.KeyCode == Enum.KeyCode.P then
        uiVisible = not uiVisible
        screenGui.Enabled = uiVisible
    end
end)

-- Main Loop Connections
RunService.RenderStepped:Connect(function()
    update()
    updateUIText()
end)
