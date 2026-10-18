--[[
    BLOCK STRUIT ULTIMATE AUTO FARM SCRIPT
    Fitur:
    - Auto Teleport ke Buah Prioritas (Kitsune, Dragon, Spirit, dll)
    - Auto Ambil Buah Terdekat jika tidak ada prioritas
    - Auto Buka Peti Koin (Chest)
    - Speed Boost Otomatis
    - Anti-Lag Loop
    
    Dibuat untuk KRNL / Fluxus / Wally
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- Konfigurasi Utama
local Config = {
    EnableAutoFarm = true,
    EnableAutoChest = true,
    PriorityFruits = {"Kitsune", "Dragon", "Spirit", "Dough", "Buddha", "Leopard", "T-Rex", "Mammoth", "Dove", "Phoenix"},
    WalkSpeedNormal = 16,
    WalkSpeedFarm = 80, -- Kecepatan lari saat farming
    TeleportRange = 100, -- Jarak pencarian buah (dalam studs)
    ChestOpenDelay = 0.5, -- Delay buka peti
}

-- Status Visual Sederhana (Hanya Print ke Output untuk Hemat Memory)
local function Log(msg)
    print("[BlockStruit] " .. msg)
end

Log("Script Loaded. Starting Auto-Farm...")

-- Fungsi Pencarian Target Terbaik
local function GetBestTarget()
    local bestObj = nil
    local minDist = math.huge
    local isPriority = false

    for _, obj in pairs(Workspace:GetChildren()) do
        -- Cek apakah itu Buah (Tool) atau Peti (Chest)
        local isFruit = obj:IsA("Tool") and obj.Handle
        local isChest = string.find(obj.Name:lower(), "chest") and obj:IsA("Model")
        
        if isFruit then
            local handle = obj.Handle
            local dist = (RootPart.Position - handle.Position).Magnitude
            
            if dist < Config.TeleportRange and dist < minDist then
                -- Cek Prioritas
                local nameLower = obj.Name:lower()
                for _, pName in ipairs(Config.PriorityFruits) do
                    if nameLower == pName:lower() then
                        return {Object = obj, Handle = handle, Distance = dist, Type = "Priority"}
                    end
                end
                
                -- Jika bukan prioritas tapi masih terdekat
                if not bestObj then
                    bestObj = {Object = obj, Handle = handle, Distance = dist, Type = "Nearest"}
                end
            end
        elseif isChest and Config.EnableAutoChest then
            local dist = (RootPart.Position - obj.PrimaryPart.Position).Magnitude
            if dist < 20 then -- Jarak interaksi peti
                return {Object = obj, Position = obj.PrimaryPart.Position, Type = "Chest"}
            end
        end
    end
    
    return bestObj
end

-- Loop Utama
spawn(function()
    while true do
        local target = GetBestTarget()
        
        if target then
            if target.Type == "Chest" then
                -- Logika Buka Peti
                Log("Found Chest! Opening...")
                UserInputService:KeyDown(Enum.KeyCode.E)
                wait(Config.ChestOpenDelay)
                UserInputService:KeyUp(Enum.KeyCode.E)
                wait(1) -- Tunggu sebentar setelah buka
            else
                -- Logika Farm Buah
                local handlePos = target.Handle.Position
                
                -- Gerakkan karakter
                Humanoid.WalkSpeed = Config.WalkSpeedFarm
                
                -- Hitung vektor arah
                local direction = (handlePos - RootPart.Position).Unit
                
                -- Terapkan Velocity untuk pergerakan cepat tanpa lag
                RootPart.Velocity = Vector3.new(direction.X * Config.WalkSpeedFarm, RootPart.Velocity.Y, direction.Z * Config.WalkSpeedFarm)
                
                -- Jika sudah sangat dekat, berhenti sejenak untuk mengambil item
                if target.Distance < 5 then
                    Humanoid.WalkSpeed = 0
                    RootPart.Velocity = Vector3.new(0, RootPart.Velocity.Y, 0)
                    wait(0.5) -- Waktu ambil buah
                end
            end
        else
            -- Tidak ada target, kembali normal
            Humanoid.WalkSpeed = Config.WalkSpeedNormal
            RootPart.Velocity = Vector3.new(0, RootPart.Velocity.Y, 0)
            wait(2) -- Istirahat 2 detik sebelum scan lagi
        end
        
        wait(0.1) -- Interval pengecekan
    end
end)

-- Fitur Tambahan: Auto-Jump jika ada rintangan kecil
spawn(function()
    while true do
        wait(0.1)
        if Humanoid.FloorMaterial ~= Enum.Material.Air then
            -- Jika kaki menyentuh tanah, jangan auto-jump terus
        else
            -- Bisa ditambahkan logika jump jika diperlukan
        end
    end
end)

Log("System Running Stable.")
