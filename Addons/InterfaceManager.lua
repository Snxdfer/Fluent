--// InterfaceManager Module
local httpService = game:GetService("HttpService")

local InterfaceManager = {}
do
    InterfaceManager.Folder = "FluentSettings"
    InterfaceManager.Settings = {
        Theme = "Kami",
        Acrylic = false,
        Transparency = true,
        MenuKeybind = "LeftControl"
    }
    
    -- Set the folder path and build any missing directories.
    function InterfaceManager:SetFolder(folder)
        self.Folder = folder
        self:BuildFolderTree()
    end

    -- Allow setting the UI library reference (e.g., your custom UI library)
    function InterfaceManager:SetLibrary(library)
        self.Library = library
    end

    -- Build the folder tree for settings storage.
    function InterfaceManager:BuildFolderTree()
        local paths = {}
        -- Roblox has a built-in string.split() so we can use that.
        local parts = self.Folder:split("/")
        for idx = 1, #parts do
            paths[#paths + 1] = table.concat(parts, "/", 1, idx)
        end

        table.insert(paths, self.Folder)
        table.insert(paths, self.Folder .. "/settings")

        for i = 1, #paths do
            local path = paths[i]
            if not isfolder(path) then
                makefolder(path)
            end
        end
    end

    -- Save the current settings as a JSON file.
    function InterfaceManager:SaveSettings()
        local json = httpService:JSONEncode(self.Settings)
        writefile(self.Folder .. "/options.json", json)
    end

    -- Load settings from the JSON file and override defaults.
    function InterfaceManager:LoadSettings()
        local path = self.Folder .. "/options.json"
        if isfile(path) then
            local data = readfile(path)
            local success, decoded = pcall(function()
                return httpService:JSONDecode(data)
            end)
            if success and decoded then
                for key, value in pairs(decoded) do
                    self.Settings[key] = value
                end
            end
        end
    end

    -- Build the Interface section in the provided tab.
    function InterfaceManager:BuildInterfaceSection(tab)
        assert(self.Library, "Must set InterfaceManager.Library")
        local Library = self.Library
        local Settings = self.Settings

        -- Load settings from file if they exist.
        self:LoadSettings()

        local section = tab:AddSection("Interface")

        local InterfaceTheme = section:AddDropdown("InterfaceTheme", {
            Title = "Theme",
            Description = "Changes the interface theme.",
            Values = Library.Themes, -- Assumes Library.Themes contains the available themes.
            Default = Settings.Theme,
            Callback = function(Value)
                Library:SetTheme(Value)
                Settings.Theme = Value
                InterfaceManager:SaveSettings()
            end
        })
        InterfaceTheme:SetValue(Settings.Theme)
    
        if Library.UseAcrylic then
            section:AddToggle("AcrylicToggle", {
                Title = "Acrylic",
                Description = "The blurred background requires graphic quality 8+",
                Default = Settings.Acrylic,
                Callback = function(Value)
                    Library:ToggleAcrylic(Value)
                    Settings.Acrylic = Value
                    InterfaceManager:SaveSettings()
                end
            })
        end
    
        section:AddToggle("TransparentToggle", {
            Title = "Transparency",
            Description = "Makes the interface transparent.",
            Default = Settings.Transparency,
            Callback = function(Value)
                Library:ToggleTransparency(Value)
                Settings.Transparency = Value
                InterfaceManager:SaveSettings()
            end
        })
    
        local MenuKeybind = section:AddKeybind("MenuKeybind", { Title = "Minimize Bind", Default = Settings.MenuKeybind })
        MenuKeybind:OnChanged(function()
            Settings.MenuKeybind = MenuKeybind.Value
            InterfaceManager:SaveSettings()
        end)
        
        Library.MinimizeKeybind = MenuKeybind

        while not game:IsLoaded() or 
              not game:GetService("CoreGui") or 
              not game:GetService("Players").LocalPlayer or 
              not game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui") do
            wait()
        end

        local player = game:GetService("Players").LocalPlayer
        local mouse = player:GetMouse()

        local defaultCursor = mouse.Icon

        local cursorAssets = {
            ["White Dot"] = "rbxassetid://417446600",
            ["Rodin"]    = "rbxassetid://985035074",
            ["Green Dot"] = "rbxassetid://973825151",
        }

        local Toggle = Tabs.Main:AddToggle("enableCustomCursor", {
            Title = "Enable Custom Cursor",
            Default = false
        })

        local Dropdown = Tabs.Main:AddDropdown("CursorsDropdown", {
            Title = "Cursors",
            Values = {"White Dot", "Rodin", "Green Dot"},
            Multi = false,
            Default = nil,
        })

        local function updateCursor()
            if Toggle.Value then
                local selection = Dropdown.Value
                if selection and cursorAssets[selection] then
                    mouse.Icon = cursorAssets[selection]
                else
                    mouse.Icon = cursorAssets["White Dot"]
                end
            else
                mouse.Icon = defaultCursor
            end
        end

        Toggle:OnChanged(function(newValue)
            if newValue then
                updateCursor()
            else
                mouse.Icon = defaultCursor
            end
        end)

        Dropdown:OnChanged(function(newValue)
            updateCursor()
        end)
    end
end

return InterfaceManager
