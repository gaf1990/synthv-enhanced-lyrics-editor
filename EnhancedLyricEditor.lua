SCRIPT_TITLE = "Enhanced Lyric Editor"

function getClientInfo()
    return {
        name = "Enhanced Lyric Editor",
        category = "GAF Utilities",
        author = "Giuseppe Andrea Ferraro",
        versionNumber = 2,
        minEditorVersion = 0
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
        message = "Enhanced Mode",
        buttons = "OkCancel",
        widgets = {
            {
                name = "mo", type = "ComboBox",
                label = "Mode",
                choices = {"Lyrics","Phonemes"},
                default = 0
            },
            {
                name = "le", type = "TextArea",
                label = "Editor",
                height = 300,
                default = "Enter some more text here.\nAnother line.\nYet another line!",
            },
            {
                name = "op", type = "ComboBox",
                label = "Lyrics Operation (applicable only on Lyrics View}",
                choices = {"Nothing","Words to dreamtonics format", "Words to classic syllabes", "Syllabes to dreamtonics format"},
                default = 0
            },
            {
                name = "la", type = "ComboBox",
                label = "Target Language",
                choices = {"English", "Japanese", "Spanish", "Mandarine","Cantonese","Italiano"},
                default = 0
            },
            {
                name = "from", type = "TextBox",
                label = "From",
                default = ""
            },
            {
                name = "to", type = "TextBox",
                label = "To",
                default = ""
            },
            {
                name = "pr", type = "CheckBox",
                text = "Only preview",
                default = true
            },


        }
    }
    local currentLyrics = retrieveLyrics(0,0,0)
    log("Selected lyrics is " .. currentLyrics)
    showRecursivelyCustomDialog(lyricEditor, currentLyrics)
end

function showRecursivelyCustomDialog(lyricEditor,text,mode,language)
    lyricEditor.widgets[1].default = mode
    lyricEditor.widgets[2].default = text
    lyricEditor.widgets[3].default = language
    local result = SV:showCustomDialog(lyricEditor)
    if tostring(result.status) == "true" then
        local originalLyrics = result.answers.le
        local newMode = result.answers.mo
        log("Result answer mode is " .. newMode)
        if newMode == 1 then
            log("Load Phonemes")
            originalLyrics = retrieveLyrics(newMode)
        end

        local newLyrics = originalLyrics

        if result.answers.op == 1 then
            if newMode == 0 then
                local langCodes = { "EN","JAP","SPA","MAN","CAN","IT"}
                local newLanguage = langCodes[result.answers.la + 1]
                if string.find(text, "%+") then
                    SV:showOkCancelBox("Sillabation",
                            "Found \"+\" inside text. Please remove it before sillabating");
                else
                    newLyrics = wrapLyrics(tokenizeLyrics(newLanguage, originalLyrics))
                end
            else
                SV:showOkCancelBox("Sillabation",
                        "Please switch to lyrics view before sillabate");
            end
        end

        if result.answers.op == 2 then
            if newMode == 0 then
                local langCodes =  { "EN","JAP","SPA","MAN","CAN","IT"}
                local newLanguage = langCodes[result.answers.la + 1]
                if string.find(text, "%+") then
                    SV:showOkCancelBox("Sillabation",
                            "Found \"+\" inside text. Please remove it before sillabating");
                else
                    newLyrics = tokenizeLyrics(newLanguage, originalLyrics)
                end
            else
                SV:showOkCancelBox("Sillabation",
                        "Please switch to lyrics view before sillabate");
            end
        end

        if result.answers.op == 3 then
            if newMode == 0 then
                newLyrics = wrapLyrics(originalLyrics)
            else
                SV:showOkCancelBox("Wrapper",
                        "Please switch to lyrics view before wrap world");
            end
        end

        newLyrics = replaceLyrics(newLyrics, result.answers.from, result.answers.to)
        local cleanedLyrics = newLyrics:gsub("\n", "")
        log("New lyrics are " .. cleanedLyrics)

        local showPreview = result.answers.pr
        if showPreview == true then
            showRecursivelyCustomDialog(lyricEditor, newLyrics,newMode,result.answers.la)
        else
            applyLyrics(cleanedLyrics, newMode)
        end
    else
        log ("End script")
    end
    SV:finish()
end

function tokenizeLyrics(language, lyrics)
    log("Target language is " .. language)
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
                    cleanedWord = cleanedWord .. " +"
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

function retrieveLyrics(mode)
    local selection = SV:getMainEditor():getSelection()
    local selectedNotes = selection:getSelectedNotes()
    local scope = SV:getMainEditor():getCurrentGroup();
    local phonemes = SV:getPhonemesForGroup(scope);
    local realNoteCounter = 1;
    local selectedLyrics = ""
    local carriageCounter = 0;
    while realNoteCounter <= #selectedNotes do
        local originalNote = selectedNotes[realNoteCounter]
        if mode == 0 then
            selectedLyrics = selectedLyrics .. originalNote:getLyrics() .. " "
        end
        if mode == 1 then
            selectedLyrics = selectedLyrics .. "{" .. phonemes[realNoteCounter + selectedNotes[1]:getIndexInParent() - 1] .. "} "
        end
        if  carriageCounter == 10 then
            selectedLyrics = selectedLyrics .. "\n"
            carriageCounter = 0
        end
        carriageCounter = carriageCounter + 1
        realNoteCounter = realNoteCounter + 1
    end
    return selectedLyrics
end

function applyLyrics(cleanedLyrics, mode)
    local selection = SV:getMainEditor():getSelection()
    local selectedNotes = selection:getSelectedNotes()
    local realNoteCounter = 1;
    local newLyrics = split(cleanedLyrics," ")
    if mode == 1 then
        newLyrics = split(cleanedLyrics,"{")
    end

    while realNoteCounter <= #selectedNotes do
        local originalNote = selectedNotes[realNoteCounter]
        if mode == 0 then
            originalNote:setLyrics(newLyrics[realNoteCounter])
        end
        if mode == 1 then
            local cleanedPhonemes = replaceLyrics(replaceLyrics(newLyrics[realNoteCounter],"{",""),"}","")
            log("cleanPhonemes is " ..  cleanedPhonemes )
            originalNote:setPhonemes(cleanedPhonemes)
        end
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

function replaceLyrics(lyrics, from, to)
    return string.gsub(lyrics, from,to)
end

function ltrim(s)
    return s:match'^%s*(.*)'
end


function updateWord(word, i, x, sillabes)
    local lastCharIndex= i + x -1
    local extracted = word:sub(i, lastCharIndex)
    log("\t\tExtracted: " .. extracted .. " (" .. i .. " --> ".. lastCharIndex ..")")
    table.insert(sillabes, extracted)
    return word:sub(i + x), sillabes
end

function getLanguageOverride(language)
    if language == "cantonese" then
        return "CAN"
    end
    if language == "spanish" then
        return "SPA"
    end
    if language == "japanese" then
        return "GIA"
    end
    if language == "english" then
        return "ENG"
    end
    if language == "mandarine" then
        return "MAN"
    end
    return "GIA"
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