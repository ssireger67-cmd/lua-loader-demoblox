-- =======================================================================
-- FIXED INSTANT FRUIT SNIPER + AUTO STORE + BACKUP SERVER HOP
-- Solusi: Buah tidak akan hilang lagi karena otomatis disimpan sebelum pindah server
-- =======================================================================

local WAKTU_TUNGGU_HOP = 3 -- Detik nunggu sebelum ganti server jika dari awal tidak ada buah
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Fungsi Teleportasi Instan ke posisi buah
local function TeleportInstan(targetCFrame)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")
    
    local humanoid = char:WaitForChild("Humanoid")
    humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    
    root.CFrame = targetCFrame + Vector3.new(0, 2, 0)
    task.wait(0.5) -- Delay singkat memastikan buah tersentuh dan terambil
end

-- FUNGSI OTOMATIS MENYIMPAN BUAH KE DALAM INVENTORY (TAS)
local function SimpanBuahKeTas()
    pcall(function()
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        -- Mencari apakah ada buah yang sedang dipegang di tangan karakter
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:find("Fruit") or tool:FindFirstChild("Handle")) then
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "📦 MENYIMPAN BUAH 📦",
                    Text = "Menyimpan " .. tool.Name .. " ke inventory...",
                    Duration = 3
                })
                -- Menembakkan Remote Event resmi Blox Fruits untuk menyimpan buah
                local remote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_")
                remote:InvokeServer("StoreFruit", tool.Name, tool)
                task.wait(1.5) -- Memberikan jeda waktu agar server Roblox mencatat penyimpanan
            end
        end
    end)
end

-- Fungsi Server Hop (Tiga lapis pengaman anti-stuck)
local function PindahServer()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "🔄 SERVER HOP 🔄",
        Text = "Mencari server baru...",
        Duration = 3
    })
    task.wait(1)
    
    local berhasilPindah = pcall(function()
        local sfUrl = "https://roblox.com" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local req = http_request or request or (syn and syn.request)
        if req then
            local res = req({Url = sfUrl})
            local body = HttpService:JSONDecode(res.Body)
            if body and body.data then
                for _, server in pairs(body.data) do
                    if server.playing < server.maxPlayers and server.id ~= game.JobId then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                        task.wait(3)
                        return true
                    end
                end
            end
        end
    end)
    
    if not berhasilPindah then
        pcall(function()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
            task.wait(3)
        end)
    end
    
    pcall(function()
        TeleportService:TeleportToSpawnPage(game.PlaceId)
    end)
end

-- Fungsi Utama memindai buah
local function CekDanAmbilBuah()
    local buahDitemukan = false
    
    for _, item in pairs(game.Workspace:GetChildren()) do
        if item:IsA("Tool") and (item.Name:find("Fruit") or item:FindFirstChild("Handle")) then
            buahDitemukan = true
            
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "⚡ FRUIT FOUND! ⚡",
                Text = "Mendapatkan: " .. item.Name .. ". Teleport!",
                Duration = 4
            })
            
            -- 1. Teleport ke lokasi buah
            TeleportInstan(item.Handle.CFrame)
            task.wait(1) -- Nunggu animasi memegang buah selesai
            
            -- 2. Amankan buah ke dalam Tas sebelum pindah server
            SimpanBuahKeTas()
        end
    end
    
    return buahDitemukan
end

-- Eksekusi Utama saat masuk permainan
task.spawn(function()
    repeat task.wait() until game:IsLoaded() and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    task.wait(2)
    
    local adaBuah = CekDanAmbilBuah()
    
    if adaBuah then
        task.wait(1)
        PindahServer()
    else
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "❌ TIDAK ADA BUAH ❌",
            Text = "Server kosong. Mencari server lain...",
            Duration = 3
        })
        task.wait(WAKTU_TUNGGU_HOP)
        PindahServer()
    end
end)
