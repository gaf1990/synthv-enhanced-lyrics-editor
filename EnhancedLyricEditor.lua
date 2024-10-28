SCRIPT_TITLE = "Enhanced Lyric Editor"

function getClientInfo()
    return {
        name = "Enhanced Lyric Editor",
        category = "GAF Utilities",
        author = "Giuseppe Andrea Ferraro",
        versionNumber = 1,
        minEditorVersion = 2
    }
end

function main()
    local OS = determine_OS()
    local script_folder_name = determine_scriptFolder(OS)
    fileName = script_folder_name .. "\\" .. "enhanced-lyric-editor.log"
    log("OS: " .. OS)

    log("Start processing notes")
    local selection = SV:getMainEditor():getSelection()
    local selectedNotes = selection:getSelectedNotes()
    local realNoteCounter = 1;
    local selectedLyrics = ""
    while realNoteCounter <= #selectedNotes do
        local originalNote = selectedNotes[realNoteCounter]
        local lyric = originalNote:getLyrics()
        selectedLyrics = selectedLyrics .. " " .. originalNote:getLyrics()
        realNoteCounter = realNoteCounter + 1;
    end

    local lyricEditor = {
        title = "Lyrics Editor",
        message = "Please choose operation!",
        buttons = "OkCancel",
        widgets = {
            {
                name = "op", type = "ComboBox",
                label = "Operation",
                choices = {"Sillabate words"},
                default = 2
            },
            {
                name = "le", type = "TextArea",
                label = "Editor",
                height = 200,
                default = "Enter some more text here.\nAnother line.\nYet another line!",
            }
        }
    }
    lyricEditor.widgets[2].default = selectedLyrics

    local result = SV:showCustomDialog(lyricEditor)
    SV:finish()
end

function determine_OS()
    local hostinfo = SV:getHostInfo()
    return hostinfo.osType
end

function determine_scriptFolder(OS)
    if OS ~= "Windows" then
        local path = "/Library/Application Support/Dreamtonics/Synthesizer V Studio/scripts/"
        if folder_exists(path, OS) then
            return path
        end
    else
        local userProfile = os.getenv("USERPROFILE")
        if userProfile then
            local docfolder = userProfile .. "\\Documenti\\Dreamtonics\\Synthesizer V Studio\\scripts\\Utilities\\"
            if folder_exists(docfolder, OS) then
                return docfolder
            else
                docfolder = userProfile .. "\\OneDrive\\Documenti\\Dreamtonics\\Synthesizer V Studio\\scripts\\Utilities\\"
                if folder_exists(docfolder, OS) then
                    return docfolder
                else
                    return SV:showInputBox("Script path", "Cannot find automatically the script path. Please insert the full path here:", "Script path")
                end
            end
        else
            return SV:showInputBox("Script path", "Cannot find user profile. Please insert the full path here:", "Script path")
        end
    end
end

function logElement(t)
    local result = ""
    for key, value in pairs(t) do
        if type(value) == "table" then
            result = result .. key .. ": {"
            result = result .. logElement(value) .. "} "
        else
            result = result .. key .. ": " .. tostring(value) .. " "
        end
    end
    return result;
end

function log(msg)
    local fp = io.open(fileName, "a")
    local str = string.format("[%-6s%s] %s - %s\n",
            "Logger ", os.date(), "INFO ", msg)
    fp:write(str)
    fp:close()
end

function exists(file)
    local isok, errstr, errcode = os.rename(file, file)
    if isok == nil then
        if errcode == 13 then
            return true -- Permission denied, but it exists
        end
        return false
    end
    return true
end

function folder_exists(foldername, OS)
    if OS ~= "Windows" then
        if foldername:sub(-1) ~= "/" then
            foldername = foldername .. "/"
        end
    else
        if foldername:sub(-1) ~= "\\" then
            foldername = foldername .. "\\"
        end
    end
    return exists(foldername)
end

function file_exists(name)
    local f = io.open(name, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

function file_is_writable(name)
    local f = io.open(name, "w")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

function lines_from(file)
    if not file_exists(file) then
        return {}
    end
    local filelines = {}
    for line in io.lines(file) do
        filelines[#filelines + 1] = line
    end
    return filelines
end

function split(inputstr, sep)
    if sep == nil then
        sep = "%s" -- Se il separatore non è specificato, utilizza gli spazi
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end