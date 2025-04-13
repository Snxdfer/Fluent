--// fix
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

    function InterfaceManager:SetFolder(folder)
        self.Folder = folder
        self:BuildFolderTree()
    end

    function InterfaceManager:SetLibrary(library)
        self.Library = library
    end

    function InterfaceManager:BuildFolderTree()
        local paths = {}
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

    function InterfaceManager:SaveSettings()
        local json = httpService:JSONEncode(self.Settings)
        writefile(self.Folder .. "/options.json", json)
    end

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

    function InterfaceManager:BuildInterfaceSection(tab)
        assert(self.Library, "Must set InterfaceManager.Library before calling BuildInterfaceSection.")
        
        local Library = self.Library
        local Settings = self.Settings

        self:LoadSettings()

        local section = tab:AddSection("Interface")

        local InterfaceTheme = section:AddDropdown("InterfaceTheme", {
            Title = "Theme",
            Description = "Changes the interface theme.",
            Values = Library.Themes,
            Default = Settings.Theme,
            Callback = function(selectedTheme)
                Library:SetTheme(selectedTheme)
                Settings.Theme = selectedTheme
                self:SaveSettings()
            end
        })
        InterfaceTheme:SetValue(Settings.Theme)

        if Library.UseAcrylic then
            section:AddToggle("AcrylicToggle", {
                Title = "Acrylic",
                Description = "Blurred background (requires graphic quality 8+).",
                Default = Settings.Acrylic,
                Callback = function(isAcrylicOn)
                    Library:ToggleAcrylic(isAcrylicOn)
                    Settings.Acrylic = isAcrylicOn
                    self:SaveSettings()
                end
            })
        end

        section:AddToggle("TransparentToggle", {
            Title = "Transparency",
            Description = "Makes the interface transparent.",
            Default = Settings.Transparency,
            Callback = function(isTransparent)
                Library:ToggleTransparency(isTransparent)
                Settings.Transparency = isTransparent
                self:SaveSettings()
            end
        })

        local MenuKeybind = section:AddKeybind("MenuKeybind", {
            Title = "Minimize Bind",
            Default = Settings.MenuKeybind
        })
        MenuKeybind:OnChanged(function()
            Settings.MenuKeybind = MenuKeybind.Value
            self:SaveSettings()
        end)
        
        Library.MinimizeKeybind = MenuKeybind

        while not game:IsLoaded()
            or not game:GetService("CoreGui")
            or not game:GetService("Players").LocalPlayer
            or not game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui") do
            task.wait()
        end

        local player = game:GetService("Players").LocalPlayer
        local mouse = player:GetMouse()

        local defaultCursor = mouse.Icon

        local cursorAssets = {
            ["White Dot"] = "rbxassetid://417446600",
            ["Rodin"]     = "rbxassetid://985035074",
            ["Green Dot"] = "rbxassetid://973825151",
        }

        local cursorSection = tab:AddSection("Custom Cursor")

        local cursorToggle = cursorSection:AddToggle("enableCustomCursor", {
            Title   = "Enable Custom Cursor",
            Default = false,
            Callback = function(_)
                updateCursor()
            end
        })
        
        local cursorDropdown = cursorSection:AddDropdown("CursorsDropdown", {
            Title = "Cursors",
            Values = { "White Dot", "Rodin", "Green Dot" },
            Multi = false,
            Default = nil,
            Callback = function(_)
                updateCursor()
            end
        })

        local function updateCursor()
            if cursorToggle.Value then
                local selection = cursorDropdown.Value
                if selection and cursorAssets[selection] then
                    mouse.Icon = cursorAssets[selection]
                else
                    mouse.Icon = cursorAssets["White Dot"]
                end
            else
                mouse.Icon = defaultCursor
            end
        end

        updateCursor()
        
    end
end

return InterfaceManager
