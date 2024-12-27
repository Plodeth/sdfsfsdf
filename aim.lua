local player = game.Players.LocalPlayer
local range = 50 -- Range for aim assist
local aimAssistEnabled = false -- Toggle state
local ignoreSameTeam = false -- Toggle state for ignoring players on the same team
local aimHead = true

-- Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera -- Reference to the player's camera
local teams = game:GetService("Teams")

local currentHighlight = nil -- Store the current target's highlight

-- Function to find the nearest target
local function getNearestTarget()
    local nearest = nil
    local shortestDistance = range

    for _, obj in pairs(workspace:GetChildren()) do
        -- Only check models with Humanoid and are not the player
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj ~= player.Character then
            local humanoid = obj:FindFirstChild("Humanoid")
            local humanRootPart = obj:FindFirstChild("HumanoidRootPart")
            if humanoid and humanRootPart then
                -- Ignore dead players (health <= 0)
                if humanoid.Health > 0 then
                    -- Ignore players on the same team if toggle is enabled
                    local targetPlayer = game.Players:GetPlayerFromCharacter(obj)
                    if ignoreSameTeam and targetPlayer and targetPlayer.Team == player.Team then
                        -- Skip this iteration if the player is on the same team
                        continue
                    end

                    local distance = (humanRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        nearest = obj
                    end
                end
            end
        end
    end

    return nearest
end

-- Function to update the camera to follow the target
local function updateCamera()
    if aimAssistEnabled then
        local target = getNearestTarget()
        if target then
            local humanRootPart = target:FindFirstChild("HumanoidRootPart")
            local head = target:FindFirstChild("Head")
            if humanRootPart and head then
                local targetPosition
                if aimHead then
                    targetPosition = head.Position -- Aim at the head
                else
                    targetPosition = humanRootPart.Position + Vector3.new(0, 0.5, 0) -- Aim at the body
                end

                -- Update the camera's CFrame to look at the target position
                local cameraPosition = camera.CFrame.Position
                camera.CFrame = CFrame.lookAt(cameraPosition, targetPosition)

                -- Highlight the target player
                if currentHighlight then
                    currentHighlight.Enabled = false
                end

                -- Create and enable the highlight
                local highlight = target:FindFirstChildOfClass("Highlight")
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Parent = target
                    highlight.Adornee = target
                    highlight.FillColor = Color3.fromRGB(255, 0, 0) -- Red highlight
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 0) -- Yellow outline
                end
                highlight.Enabled = true
                currentHighlight = highlight
            end
        end
    else
        -- Disable highlight when aim assist is turned off
        if currentHighlight then
            currentHighlight.Enabled = false
            currentHighlight = nil
        end
    end
end

-- Toggle aim assist on/off
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        -- Toggle Aim Assist
        if input.KeyCode == Enum.KeyCode.E then
            aimAssistEnabled = not aimAssistEnabled
        end
        
        -- Toggle Ignore Same Team
        if input.KeyCode == Enum.KeyCode.T then
            ignoreSameTeam = not ignoreSameTeam
        end
    end
end)

-- Continuously update the camera when aim assist is enabled
RunService.RenderStepped:Connect(function()
    updateCamera()
end)

-- UI Setup
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "AimAssistGUI"

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 200, 0, 100)
frame.Position = UDim2.new(0.5, -100, 0.8, 0)
frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
frame.BorderSizePixel = 0

local toggleButton = Instance.new("TextLabel", frame)
toggleButton.Size = UDim2.new(1, 0, 1, 0)
toggleButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Font = Enum.Font.SourceSans
toggleButton.TextSize = 16
toggleButton.TextWrapped = true

-- Update the UI text based on the current toggle state
local function updateUIText()
    if aimAssistEnabled == false and ignoreSameTeam == false then
        toggleButton.Text = "Press E to turn on Aim Assist\nPress T to turn on Same Team Ignore"
    elseif aimAssistEnabled == true and ignoreSameTeam == false then
        toggleButton.Text = "Press E to turn off Aim Assist\nPress T to turn on Same Team Ignore"
    elseif aimAssistEnabled == true and ignoreSameTeam == true then
        toggleButton.Text = "Press E to turn off Aim Assist\nPress T to turn off Same Team Ignore"
    end
end

-- Continuously update the UI text based on the current toggle state
RunService.RenderStepped:Connect(function()
    updateUIText()
end)
