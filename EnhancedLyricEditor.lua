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
    script_folder_name = determine_scriptFolder(OS)
    fileName = script_folder_name .. "\\" .. "enhanced-lyric-editor.log"
    log("OS: " .. OS)

    log("Start processing notes")
    local lyricEditor = {
        title = "Lyrics Editor",
        message = "Please choose operation!",
        buttons = "OkCancel",
        widgets = {
            {
                name = "op", type = "ComboBox",
                label = "Operation",
                choices = {"Sillabate words (from combination to com-bi-na-tion)", "Wrap words (from com-bi-na-tion to combination + + + )"},
                default = 0
            },
            {
                name = "la", type = "ComboBox",
                label = "Target Language",
                choices = {"English", "Japanese", "Spanish", "Mandarine","Cantonese"},
                default = 0
            },
            {
                name = "pr", type = "CheckBox",
                text = "Show preview",
                default = false
            },
            {
                name = "le", type = "TextArea",
                label = "Editor",
                height = 200,
                default = "Enter some more text here.\nAnother line.\nYet another line!",
            }

        }
    }
    local currentLyrics = retrieveLyrics()
    log("Selected lyrics is " .. currentLyrics)
    showRecursivelyCustomDialog(lyricEditor, currentLyrics)
end

function showRecursivelyCustomDialog(lyricEditor,text)
    lyricEditor.widgets[4].default = text
    local result = SV:showCustomDialog(lyricEditor)
    if tostring(result.status) == "true" then
        local originalLyrics = result.answers.le
        local newLyrics = originalLyrics
        if result.answers.op == 0 then
            local langCodes = { "EN","JAP","SPA","MAN","CAN" }
            local language = langCodes[result.answers.la + 1]
            if string.find(text, "%+") then
                SV:showOkCancelBox("Sillabation",
                        "Found \"+\" inside text. Please remove it before sillabating");
            else
                newLyrics = tokenizeLyrics(language, originalLyrics)
            end
        else
            if result.answers.op == 1 then
                newLyrics = wrapLyrics(originalLyrics)
            end
        end

        local cleanedLyrics = newLyrics:gsub("\n", "")
        log("New lyrics are " .. cleanedLyrics)

        local showPreview = result.answers.pr
        if showPreview == true then
            showRecursivelyCustomDialog(lyricEditor, newLyrics)
        else
            applyLyrics(cleanedLyrics)
            SV:finish()
        end
        else
            log ("End script")
            SV:finish()
        end
    end


function tokenizeLyrics(language, lyrics)
    log("Target language is " ..language)
    local sillRules = loadSillRules(script_folder_name, language, OS)
    local sillabateLyrics = ""
    local rows = split(lyrics, "\n")
    local rowCounter = 1
    while rowCounter <= #rows do
        local row = rows[rowCounter]
        local words = split(row, " ")
        local wordCounter = 1
        while wordCounter <= #words do
            local word = words[wordCounter]
            word = string.lower(word)
            local sillabes = convertToSillabe(sillRules, word)
            local sillabeCounter = 1
            while sillabeCounter <= #sillabes do
                local sillabe = sillabes[sillabeCounter]
                if sillabeCounter > 1 then
                    sillabateLyrics = sillabateLyrics .. "-" .. sillabe
                else
                    sillabateLyrics = sillabateLyrics .. " " .. sillabe
                end
                sillabeCounter = sillabeCounter + 1
            end
            sillabateLyrics = sillabateLyrics .. " "
            wordCounter = wordCounter + 1
        end
        sillabateLyrics = sillabateLyrics .. "\n"
        rowCounter = rowCounter + 1
    end
    return sillabateLyrics
end

function wrapLyrics(lyrics)
    local wrappedLyrics = ""
    local rows = split(lyrics, "\n")
    local rowCounter = 1
    while rowCounter <= #rows do
        local row = rows[rowCounter]
        local words = split(row, " ")
        local wordCounter = 1
        while wordCounter <= #words do
            local word = words[wordCounter]
            word = string.lower(word)
            local sillabes = split(word, "-")
            local cleanedWord = word:gsub("%-", "")
            for index, sillabe in ipairs(sillabes) do
                if index > 1 then
                    cleanedWord = cleanedWord .. " + "
                end
            end
            wordCounter = wordCounter + 1
            wrappedLyrics = wrappedLyrics .. " " .. cleanedWord
        end
        wrappedLyrics = wrappedLyrics .. "\n"
        rowCounter = rowCounter + 1
    end
    return wrappedLyrics
end

function retrieveLyrics()
    local selection = SV:getMainEditor():getSelection()
    local selectedNotes = selection:getSelectedNotes()
    local realNoteCounter = 1;
    local selectedLyrics = ""
    local carriageCounter = 0;
    while realNoteCounter <= #selectedNotes do
        local originalNote = selectedNotes[realNoteCounter]
        selectedLyrics = selectedLyrics .. " " .. originalNote:getLyrics()
        if  carriageCounter == 10 then
            selectedLyrics = selectedLyrics .. "\n"
            carriageCounter = 0
        end
        carriageCounter = carriageCounter + 1
        realNoteCounter = realNoteCounter + 1
    end
    return selectedLyrics
end

function applyLyrics(cleanedLyrics)
    local selection = SV:getMainEditor():getSelection()
    local selectedNotes = selection:getSelectedNotes()
    local realNoteCounter = 1;
    local newLyrics = split(cleanedLyrics," ")
    while realNoteCounter <= #selectedNotes do
        local originalNote = selectedNotes[realNoteCounter]
        originalNote:setLyrics(newLyrics[realNoteCounter])
        realNoteCounter = realNoteCounter + 1
    end
end

function loadSillRules(folder, language, OS)
    local sillRules = {}
    local separator = OS == "Windows" and "\\" or "/"
    local filePath = folder .. "languages" .. separator .. language .. "-syl.dic"
    local file = io.open(filePath, "r")
    log("Open Sillabe rule file " .. filePath)
    if file then
        for line in file:lines() do
            if not line:find("^//") and line:match("%S") then
                local ruleElement = {}
                for word in line:gmatch("%S+") do
                    table.insert(ruleElement, word)
                end
                local sillRule = {
                    ruleType = ruleElement[1],
                    pattern = ruleElement[2],
                    count = tonumber(ruleElement[3])
                }
                log("Load sillabation rule " .. logElement(sillRule))
                table.insert(sillRules, sillRule)
            end
        end
        file:close()
    else
        error("Error loading rules file: " .. tostring(filePath))
    end
    return sillRules
end

function convertToSillabe(sillRules,word)
    local sillabes = {}
    local charCounter = 1

    while charCounter <= #word do
        local appliedRule = false
        for _, sillRule in ipairs(sillRules) do
            if word:match(sillRule.pattern) then
                log("\tWord: " .. word .. " match with " .. logElement(sillRule))
                word, sillabes = updateWord(word, charCounter, sillRule.count, sillabes)
                appliedRule = true
                break
            end
        end

        if not appliedRule then
            table.insert(sillabes, word:sub(charCounter, charCounter))
            charCounter = charCounter + 1
        end
    end
    return sillabes
end


function updateWord(word, i, x, sillabes)
    local lastCharIndex= i + x -1
    local extracted = word:sub(i, lastCharIndex)
    log("\t\tExtracted: " .. extracted .. " (" .. i .. " --> ".. lastCharIndex ..")")
    table.insert(sillabes, extracted)
    return word:sub(i + x), sillabes
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