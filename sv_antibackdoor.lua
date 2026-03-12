local BLACKLISTED_STRINGS = {
    Chiper = "cipher-panel",
    EnhancedTabs = "Enchanced_Tabs",
    HelperServer = "helperServer",
    Ketamin = "ketamin.cc",
    CipherPanel = "cipher-panel.me",
    KetamineCC = "ketamin.cc",
    BlacklistVariable_1 = "MpWxwQeLMRJaDFLKmxVIFNeVfzVKaTBiVRvjBoePYciqfpJzxjNPIXedbOtvIbpDxqdoJR",
    BlacklistVariable_2 = "TLImKtRoJdFNIILofWtYMBsxzcyWGyBvPkibXoYpKxuQwrmWFabzrUUDbYfFfQMpiGDPzp",
    BlacklistVariable_3 = "HhnjTAuwhcnBmdFODmrhYpjigMOzhKGDVQFiXyAdRcAvhfabblQtJeCWnHeRXItyvpptDU",
    LoadAssert = "assert%(load%(",
    HelpCode = "helpCode"
}

local HEX_PATTERNS = {
    HexPattern = "\\x[%x][%x]"
}

local Melon = {
    ignoreResources = {},
    myWebhook = "WEBHOOK_BURAYA_KOY",
    stopServer = true
}

local function decodeHex(hexString)
    local result = ""
    for i = 1, #hexString, 2 do
        local hexCode = hexString:sub(i, i + 1)
        local charCode = tonumber(hexCode, 16)
        
        if charCode and charCode >= 32 and charCode <= 126 then
            result = result .. string.char(charCode)
        end
    end
    return result
end

local function decodeHexPatterns(sourceString)
    local decodedParts = {}
    for hexCode in sourceString:gmatch(HEX_PATTERNS.HexPattern) do
        local decodedPart = decodeHex(hexCode:sub(3))
        
        if decodedPart ~= "" then
            table.insert(decodedParts, decodedPart)
        end
    end
    return table.concat(decodedParts)
end

local function scanForBackdoors()
    local detectedBackdoors = {}
    
    local numResources = GetNumResources()
    for i = 0, numResources - 1 do
        local resourceName = GetResourceByFindIndex(i)
        
        local isIgnored = false
        for _, ignoredResource in ipairs(Melon.ignoreResources) do
            if resourceName == ignoredResource then
                isIgnored = true
                break
            end
        end
        if isIgnored then
            goto continue
        end
        
        if resourceName == GetCurrentResourceName() then
            goto continue
        end
        
        local numServerScripts = GetNumResourceMetadata(resourceName, "server_script")
        
        for j = 0, numServerScripts - 1 do
            local scriptPath = GetResourceMetadata(resourceName, "server_script", j)
            
            if scriptPath and scriptPath:match("%.lua$") then
                local filePaths = { scriptPath }
                local basePath, wildcard = scriptPath:match("(.-)%*(.-)%.lua$")
                
                if basePath and wildcard then
                    filePaths = {}
                    local commonNames = { "main", "server", "functions", "en", "es", "cs", "fr", "sl", "sr", "sv", "it", "tr", "pl", "nl", "zh-cn", "id" }
                    for _, name in ipairs(commonNames) do
                        table.insert(filePaths, basePath .. name .. wildcard .. ".lua")
                    end
                end
                
                for _, filePath in ipairs(filePaths) do
                    local fileContent = LoadResourceFile(resourceName, filePath)
                    
                    if fileContent then
                        local lineNumber = 1
                        for stringName, pattern in pairs(BLACKLISTED_STRINGS) do
                            for line in fileContent:gmatch("[^\r\n]+") do
                                if line:find(pattern) then
                                    table.insert(detectedBackdoors, {
                                        resource = resourceName .. "/" .. filePath,
                                        stringFound = stringName,
                                        lineNumber = lineNumber
                                    })
                                end
                                lineNumber = lineNumber + 1
                            end
                        end
                        
                        for _, pattern in pairs(HEX_PATTERNS) do
                            lineNumber = 1
                            for line in fileContent:gmatch("[^\r\n]+") do
                                if line:find(pattern) then
                                    local decodedString = decodeHexPatterns(line)
                                    if decodedString and #decodedString > 3 then
                                        table.insert(detectedBackdoors, {
                                            resource = resourceName .. "/" .. filePath,
                                            stringFound = decodedString,
                                            lineNumber = lineNumber
                                        })
                                    end
                                end
                                lineNumber = lineNumber + 1
                            end
                        end
                    end
                end
            end
        end
        ::continue::
    end
    
    return detectedBackdoors
end

local function sendToDiscord(backdoorsTable)
    local descriptionText = ""
    for _, backdoor in pairs(backdoorsTable) do
        descriptionText = descriptionText .. string.format(
            "In Resource: **%s** Line: **%s** We Detected string: ```%s```\n",
            backdoor.resource, backdoor.lineNumber, backdoor.stringFound
        )
    end
    
    local embed = {
        color = 16711680,
        title = "🔴[Melon Anti-Backdoor][Huge Risk] - Backdoor Detected!",
        description = descriptionText,
        footer = {
            text = " • MelonAC Best Fivem Anticheat! • ",
            icon_url = "https://i.postimg.cc/CM7rmMSx/0-02-05-d5dc3a0ccabf262329e1d2fc931a9670601e1d04ff782e2d4eebabd95e1065c5-1f8fc5c80ca47b.png"
        },
        image = {
            url = "https://i.postimg.cc/ZnpPBpN5/YrdHXMG.jpg"
        }
    }
    
    local payload = {
        username = "MelonAC",
        avatar_url = "https://i.postimg.cc/CM7rmMSx/0-02-05-d5dc3a0ccabf262329e1d2fc931a9670601e1d04ff782e2d4eebabd95e1065c5-1f8fc5c80ca47b.png",
        embeds = { embed }
    }
    
    PerformHttpRequest(Melon.myWebhook, function() end, "POST", json.encode(payload), { ["Content-Type"] = "application/json" })
end

AddEventHandler("onResourceStart", function(resourceName)
    if resourceName == "MelonAC" then
        Citizen.Wait(2500)
        print("^7[ ^1Melon Anti-Backdoor ^7] MelonAC already installed... you don't need me, boy, I am already in there <3")
        return
    end
    
    if GetCurrentResourceName() == "MelonAntiBackdoor" and resourceName == "MelonAntiBackdoor" then
        Citizen.Wait(2500)
        print("^7[ ^1Melon Anti-Backdoor ^7]^2(SETUP): ^0Anti Malware is performing a quick check...")
        Citizen.Wait(2500)
        
        local detectedBackdoors = scanForBackdoors()
        
        if #detectedBackdoors > 0 then
            print("^5------------------------------------------------------------------------------------------^0")
            print("^7[ ^1Melon Anti-Backdoor ^7]⚠️ 🔴 ^4(DANGER): ^1 WE FOUND A BACKDOOR!")
            print(" ")
            
            for _, backdoor in pairs(detectedBackdoors) do
                print(string.format(
                    "^0 ^1[INFO]^0 Resource: ^3%s^0, Detected String: ^2%s^0, In Line: ^2%s",
                    backdoor.resource, backdoor.stringFound, backdoor.lineNumber
                ))
            end
            
            print(" ")
            print("^7[ ^1Melon Anti-Backdoor ^7]⚠️ 🔴 ^4(DANGER): ^1 PLEASE STOP YOUR SERVER AND CHECK THESE FILES!!")
            print("^5------------------------------------------------------------------------------------------^0")
            
            sendToDiscord(detectedBackdoors)
            
            Citizen.Wait(5000)
            if Melon.stopServer then
                os.exit()
            end
        else
            print("No backdoors found. Your server is safe. 😎")
        end
    end
end)