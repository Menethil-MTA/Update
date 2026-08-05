#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook
#Warn All, Off

Persistent

; ──────────────── Version ────────────────
global CurrentVersion := "1.0.1"

; ──────────────── Force Init ALL Globals ────────────────
global ScriptEnabled := false
global Processing := false
global LastLogSize := 0
global LastVerifySize := 0
global DebugLogFile := ""
global ConfigFile := ""
global LogFile := ""
global PollInterval := 250
global SoundEnabled := "true"
global SoundDisabledFile := ""
global SoundEnabledFile := ""
global SoundShiftSentFile := ""
global SoundRejectedFile := ""
global SoundClearShiftFile := ""
global SoundClearAllFile := ""
global SoundErrorFile := ""
global SoundsDir := ""
global PendingQueue := []
global MyName := "Unknown"
global ShiftManagerGui := ""
global ShiftListView := ""
global ActiveShifts := Map()
global LocListView := ""
global XpListView := ""
global DailyShiftCount := Map()
global LocationCount := Map()
global TotalText := ""
global RecentRequests := Map()
global EscapedRanks := []
global EscapedCCTVRanks := []
global ShiftLogFile := ""
global DailyXPFile := ""
global CNNStartHour := 12
global Locations := []
global Ranks := []
global CCTVRanks := []
global CurrentLocIndex := 1
global ShiftCooldownSeconds := 120
global MyNameEdit := ""
global LogFileEdit := ""

; ──────────────── Registration System ────────────────
global RegFile := A_ScriptDir "\registered.key"
global RegURL := "https://rentry.co/shiftbot-users"

; ──────────────── Assign Real Values ────────────────
ConfigFile := A_ScriptDir "\shiftbot.ini"
DebugLogFile := A_ScriptDir "\shiftbot_debug.log"
ShiftLogFile := A_ScriptDir "\shifts_log.csv"
DailyXPFile := A_ScriptDir "\daily_xp.ahk"
LogFile := IniRead(ConfigFile, "Settings", "LogFile", "K:\MTA San Andreas 1.6\MTA\logs\console.log")
PollInterval := IniRead(ConfigFile, "Settings", "PollInterval", 250)
SoundEnabled := IniRead(ConfigFile, "Sound", "Enabled", "true")
SoundsDir := A_ScriptDir "\sounds"
SoundErrorFile := SoundsDir "\error.wav"
MyName := IniRead(ConfigFile, "Settings", "MyName", "Unknown")
CNNStartHour := IniRead(ConfigFile, "Settings", "CNNStartHour", 12)
Locations := StrSplit(IniRead(ConfigFile, "Settings", "Locations", "Medic,Fish1-2,Civilian,Dadgostari,Masjed,PD,Bank,Paint Ball"), ",")
Ranks := StrSplit(IniRead(ConfigFile, "Settings", "Ranks", "Kar Amooz,Tazekar,KhabarNegar,Dastyar Mojri,Mojri,Sardabir,Moavenat ll,Modiriat"), ",")
CCTVRanks := ["Sardabir", "Modiriat", "Mojri", "Moavenat ll"]

GetHWID() {
    return A_ComputerName . "-" . A_UserName
}

CheckActivation(hwid) {
    global RegURL
    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", RegURL, false)
        whr.SetTimeouts(5000, 5000, 5000, 5000)
        whr.Send()
        if (whr.Status = 200) {
            response := whr.ResponseText
            if InStr(response, Trim(hwid) . "=true")
                return true
        }
    } catch {
        return true
    }
    return true
}

ShowRegisterWindow() {
    hwid := GetHWID()
    RegisterGui := Gui("+AlwaysOnTop", "Register - ShiftBot")
    RegisterGui.BackColor := "1A1A1A"
    RegisterGui.SetFont("s10", "Consolas")
    
    RegisterGui.AddText("x20 y20 w400 cFFFFFF", "HWID:")
    RegisterGui.AddEdit("x20 y50 w400 h30 ReadOnly c00FF00", hwid)
    RegisterGui.AddText("x20 y90 w400 cAAAAAA", "Send this code to admin.")
    RegisterGui.AddText("x20 y110 w400 cAAAAAA", "After activation, click Check.")
    
    BtnCheck := RegisterGui.AddButton("x20 y150 w100 h35", "Check")
    BtnCopy := RegisterGui.AddButton("x130 y150 w100 h35", "Copy HWID")
    StatusText := RegisterGui.AddText("x20 y200 w400 cFFFF00", "")
    
    BtnCopy.OnEvent("Click", (*) => (A_Clipboard := hwid, StatusText.Text := "Copied! Send to admin."))
    BtnCheck.OnEvent("Click", (*) => CheckAndRegister(hwid, StatusText, RegisterGui))
    
    RegisterGui.Show("w440 h250")
    return true
}

CheckAndRegister(hwid, StatusText, RegisterGui) {
    StatusText.Text := "Checking..."
    Sleep(500)
    if CheckActivation(hwid) {
        FileAppend(hwid, RegFile)
        StatusText.Text := "Activated! Restarting..."
        Sleep(1500)
        RegisterGui.Destroy()
        Reload()
    } else {
        StatusText.Text := "Not activated! Contact admin."
    }
}

; ──────────────── Sound Player ────────────────
PlaySound(filePath, fallbackFreq := 500, fallbackDur := 100) {
    global SoundEnabled
    if (SoundEnabled != "true")
        return
    if FileExist(filePath)
        SoundPlay(filePath)
    else
        SoundBeep(fallbackFreq, fallbackDur)
}

; ──────────────── Check Registration on Every Startup ────────────────
if !FileExist(RegFile) {
    PlaySound(SoundErrorFile, 200, 300)
    ShowRegisterWindow()
    MsgBox("Registration required!`nRun the program again.", "Not Registered", "Icon! 4096")
    ExitApp()
}

storedHWID := Trim(FileRead(RegFile, "UTF-8"))

if (storedHWID = "") {
    PlaySound(SoundErrorFile, 200, 300)
    FileDelete(RegFile)
    MsgBox("Registration file is invalid. Please re-register.", "Invalid License", "IconX 4096")
    ExitApp()
}

if (storedHWID != GetHWID()) {
    PlaySound(SoundErrorFile, 200, 300)
    FileDelete(RegFile)
    MsgBox("Hardware changed! Please re-register.", "Security", "IconX 4096")
    ExitApp()
}

if !CheckActivation(storedHWID) {
    PlaySound(SoundErrorFile, 200, 300)
    FileDelete(RegFile)
    MsgBox("Access revoked! Contact admin.", "License Revoked", "IconX 4096")
    ExitApp()
}

; ──────────────── Sound Settings ────────────────
SoundEnabledFile := SoundsDir "\enabled.wav"
SoundDisabledFile := SoundsDir "\disabled.wav"
SoundShiftSentFile := SoundsDir "\shift_sent.wav"
SoundRejectedFile := SoundsDir "\rejected.wav"
SoundClearShiftFile := SoundsDir "\clear_shift.wav"
SoundClearAllFile := SoundsDir "\clear_all.wav"

; ──────────────── Init ────────────────
for rank in Ranks
    EscapedRanks.Push(RegExReplace(rank, "([\\\.\*\+\?\^\$\[\]\(\)\{\}\|\-])", "\$1"))

for rank in CCTVRanks
    EscapedCCTVRanks.Push(RegExReplace(rank, "([\\\.\*\+\?\^\$\[\]\(\)\{\}\|\-])", "\$1"))

for loc in Locations
    LocationCount[loc] := 0

if FileExist(LogFile) {
    LastLogSize := FileGetSize(LogFile)
    LastVerifySize := LastLogSize
} else {
    LogDebug("WARNING: Log file not found: " LogFile)
}

if !FileExist(ShiftLogFile)
    FileAppend("Date,Player,Type,Location,StartTime,EndTime`n", ShiftLogFile, "UTF-8")

CleanExpiredShiftsOnStartup()
LoadDailyXP()
LogDebug("Script initialized. v" CurrentVersion " | LogFile: " LogFile)

; ──────────────── Daily XP Functions ────────────────
SaveDailyXP() {
    global DailyXPFile, DailyShiftCount
    content := ""
    for player, count in DailyShiftCount
        content .= player . "=" . count . "`n"
    try FileDelete(DailyXPFile)
    FileAppend(content, DailyXPFile, "UTF-8")
}

LoadDailyXP() {
    global DailyXPFile, DailyShiftCount
    if !FileExist(DailyXPFile)
        return
    txt := FileRead(DailyXPFile, "UTF-8")
    for line in StrSplit(txt, "`n", "`r") {
        if line = ""
            continue
        parts := StrSplit(line, "=")
        if parts.Length >= 2
            DailyShiftCount[parts[1]] := Integer(parts[2])
    }
}

; ──────────────── Cleanup on Startup ────────────────
CleanExpiredShiftsOnStartup() {
    global ActiveShifts, LocationCount
    now := A_Now, cleaned := 0, expiredPlayers := []
    for player, data in ActiveShifts {
        if (now >= data.endTime)
            expiredPlayers.Push(player)
    }
    for player in expiredPlayers {
        data := ActiveShifts[player]
        if (data.type = "Shift" && LocationCount.Has(data.location))
            LocationCount[data.location] := Max(0, LocationCount[data.location] - 1)
        ActiveShifts.Delete(player)
        LogDebug("Startup: Shift expired for " player), cleaned += 1
    }
    if (cleaned > 0)
        LogDebug("Startup cleanup complete: " cleaned " expired shifts removed")
    else
        LogDebug("Startup cleanup: No expired shifts found")
}

; ──────────────── Self Checker ────────────────
IsSelfRequest(playerName) {
    global MyName
    if (MyName = "Unknown" || MyName = "")
        return false
    return StrLower(playerName) = StrLower(MyName)
}

; ──────────────── Log Shift to CSV ────────────────
LogShiftToCSV(playerName, shiftType, location, startTime, endTime) {
    global ShiftLogFile
    date := FormatTime(A_Now, "yyyy-MM-dd")
    FileAppend(date "," playerName "," shiftType "," location "," startTime "," endTime "`n", ShiftLogFile, "UTF-8")
}

; ──────────────── Update Checker ────────────────
CheckForUpdate() {
    global CurrentVersion
    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", "https://raw.githubusercontent.com/Menethil-MTA/Update/refs/heads/main/version.txt", false)
        whr.SetTimeouts(5000, 5000, 5000, 5000)
        whr.Send()
        if (whr.Status = 200) {
            latest := Trim(whr.ResponseText)
            if (latest != CurrentVersion)
                return latest
        }
    } catch {
    }
    return false
}

UpdateProgram(*) {
    latest := CheckForUpdate()
    if !latest {
        MsgBox("You already have the latest version.`nCurrent: " CurrentVersion, "Up to Date", "Iconi 4096")
        return
    }
    result := MsgBox("New version " latest " found!`nCurrent: " CurrentVersion "`n`nUpdate now?", "Update Available", "YesNo Icon? 4096")
    if (result != "Yes")
        return
    
    FileCopy(A_ScriptDir "\Updater.exe", A_ScriptDir "\_updater_temp.exe", 1)
    Run(A_ScriptDir "\_updater_temp.exe")
    ExitApp()
}

; ──────────────── Save MyName ────────────────
SaveMyName(*) {
    global MyNameEdit, MyName, ConfigFile
    
    newName := Trim(MyNameEdit.Value)
    if (newName = "") {
        MsgBox("Please enter your name.", "Error", "Icon! 4096")
        return
    }
    
    MyName := newName
    IniWrite(newName, ConfigFile, "Settings", "MyName")
    
    MsgBox("Your name has been saved: " newName, "Success", "Iconi 4096")
    LogDebug("MyName set to: " newName)
}

; ──────────────── Save LogFile ────────────────
SaveLogFile(*) {
    global LogFileEdit, LogFile, ConfigFile, LastLogSize, LastVerifySize
    
    newPath := Trim(LogFileEdit.Value)
    if (newPath = "") {
        MsgBox("Please enter the log file path.", "Error", "Icon! 4096")
        return
    }
    
    if !FileExist(newPath) {
        result := MsgBox("File not found:`n" newPath "`n`nSave anyway?", "Warning", "YesNo Icon! 4096")
        if (result != "Yes")
            return
    }
    
    LogFile := newPath
    IniWrite(newPath, ConfigFile, "Settings", "LogFile")
    
    if FileExist(LogFile) {
        LastLogSize := FileGetSize(LogFile)
        LastVerifySize := LastLogSize
    }
    
    MsgBox("Log path saved!`n" newPath, "Success", "Iconi 4096")
    LogDebug("LogFile set to: " newPath)
}

; ──────────────── Hotkeys ────────────────
*Delete:: {
    global ScriptEnabled, LogFile, LastLogSize, LastVerifySize, PollInterval
    ScriptEnabled := !ScriptEnabled
    if ScriptEnabled {
        if FileExist(LogFile)
            LastLogSize := FileGetSize(LogFile), LastVerifySize := LastLogSize
        ToolTip("Script: ON", , , 1)
        SetTimer(CheckLog, PollInterval)
        LogDebug("Script ENABLED. PollInterval: " PollInterval "ms")
        PlaySound(SoundEnabledFile, 600, 100)
    } else {
        ToolTip("Script: OFF", , , 1)
        SetTimer(CheckLog, 0)
        LogDebug("Script DISABLED")
        PlaySound(SoundDisabledFile, 300, 150)
    }
    SetTimer(() => ToolTip(, , , 1), -3000)
}

*F10:: {
    global CurrentLocIndex, Locations
    CurrentLocIndex := Mod(CurrentLocIndex, Locations.Length) + 1
    ToolTip("Location: " Locations[CurrentLocIndex], , , 2)
    SetTimer(() => ToolTip(, , , 2), -3000)
    LogDebug("Location changed to: " Locations[CurrentLocIndex])
}

; ──────────────── GUI: Shift Manager ────────────────
BuildShiftManagerGui() {
    global ShiftManagerGui, ActiveShifts, LocationCount, Locations, LocListView, XpListView, DailyShiftCount, ShiftListView, TotalText, MyNameEdit, MyName, LogFileEdit, LogFile
    
    if ShiftManagerGui
        ShiftManagerGui.Destroy()
    ShiftManagerGui := Gui("+AlwaysOnTop", "Shift Manager")
    ShiftManagerGui.BackColor := "1A1A1A"
    ShiftManagerGui.SetFont("s8", "Consolas")
    ShiftManagerGui.AddText("x10 y10 w780 c00FF00", "Active Shifts")
    ShiftListView := ShiftManagerGui.AddListView("x10 y35 w780 h180 -ReadOnly cWhite Background2D2D2D", ["Player", "Type", "Location", "End Time", "Time Left"])
    ShiftListView.ModifyCol(1, 140), ShiftListView.ModifyCol(2, 80), ShiftListView.ModifyCol(3, 100), ShiftListView.ModifyCol(4, 100), ShiftListView.ModifyCol(5, 100)
    ShiftManagerGui.AddText("x10 y225 w380 c00FF00", "Location Counts")
    ShiftManagerGui.AddText("x400 y225 w380 c00FF00", "Daily XP (Shift Count)")
    LocListView := ShiftManagerGui.AddListView("x10 y250 w380 h130 -ReadOnly cWhite Background2D2D2D", ["Location", "Count"])
    LocListView.ModifyCol(1, 200), LocListView.ModifyCol(2, 160)
    XpListView := ShiftManagerGui.AddListView("x400 y250 w380 h130 -ReadOnly cWhite Background2D2D2D", ["Player", "Shifts Today"])
    XpListView.ModifyCol(1, 200), XpListView.ModifyCol(2, 160)
    BtnLocPlus := ShiftManagerGui.AddButton("x10 y390 w40 h25", "+")
    BtnLocMinus := ShiftManagerGui.AddButton("x55 y390 w40 h25", "-")
    LocSetEdit := ShiftManagerGui.AddEdit("x100 y390 w50 h25", "0")
    BtnLocSet := ShiftManagerGui.AddButton("x155 y390 w50 h25", "Set")
    TotalText := ShiftManagerGui.AddText("x220 y395 w200 cFFFF00", "")
    BtnClear := ShiftManagerGui.AddButton("x400 y390 w90 h25", "Clear Shift")
    BtnClearAll := ShiftManagerGui.AddButton("x495 y390 w90 h25", "Clear All")
    BtnRefresh := ShiftManagerGui.AddButton("x590 y390 w90 h25", "Refresh")
    BtnExport := ShiftManagerGui.AddButton("x685 y390 w90 h25", "Export CSV")
    
    ; My Name row
    ShiftManagerGui.AddText("x10 y430 w60 c00FF00", "My Name:")
    MyNameEdit := ShiftManagerGui.AddEdit("x75 y427 w120 h22", MyName)
    BtnSaveName := ShiftManagerGui.AddButton("x200 y425 w50 h25", "Save")
    BtnSaveName.OnEvent("Click", SaveMyName)
    
    ; Log Path row
    ShiftManagerGui.AddText("x10 y460 w60 c00FF00", "Log Path:")
    LogFileEdit := ShiftManagerGui.AddEdit("x75 y457 w500 h22", LogFile)
    BtnSaveLog := ShiftManagerGui.AddButton("x580 y455 w50 h25", "Save")
    BtnSaveLog.OnEvent("Click", SaveLogFile)
    
    BtnUpdate := ShiftManagerGui.AddButton("x10 y490 w100 h25", "Update")
    BtnClose := ShiftManagerGui.AddButton("x120 y490 w100 h25", "Close")
    BtnClear.OnEvent("Click", ClearSelectedShift)
    BtnClearAll.OnEvent("Click", ClearAllShifts)
    BtnRefresh.OnEvent("Click", RefreshShiftList)
    BtnClose.OnEvent("Click", (*) => ShiftManagerGui.Hide())
    BtnExport.OnEvent("Click", ExportCSV)
    BtnUpdate.OnEvent("Click", UpdateProgram)
    BtnLocPlus.OnEvent("Click", (*) => AdjustLocationCount(1))
    BtnLocMinus.OnEvent("Click", (*) => AdjustLocationCount(-1))
    BtnLocSet.OnEvent("Click", SetLocationCount)
    RefreshShiftList()
}

RefreshShiftList(*) {
    global ActiveShifts, ShiftListView, TotalText, LocationCount, Locations, LocListView, DailyShiftCount, XpListView
    if !ShiftListView
        return
    ShiftListView.Delete()
    now := A_Now
    for player, data in ActiveShifts {
        timeLeft := DateDiff(data.endTime, now, "Seconds")
        timeLeftText := FormatSeconds(timeLeft)
        endTimeText := FormatTime(data.endTime, "HH:mm")
        displayLoc := (data.type != "Shift") ? "-" : data.location
        ShiftListView.Add(, player, data.type, displayLoc, endTimeText, timeLeftText)
    }
    if LocListView {
    LocListView.Delete()
    for loc in Locations {
        if !LocationCount.Has(loc)
            LocationCount[loc] := 0
        LocListView.Add(, loc, LocationCount[loc])
    }
}
    if XpListView {
        XpListView.Delete()
        for player, count in DailyShiftCount
            XpListView.Add(, player, count)
    }
    if TotalText
        TotalText.Text := "Total Shifts: " . ActiveShifts.Count
}

ExportCSV(*) {
    global ShiftLogFile
    Run("explorer /select," . ShiftLogFile)
    LogDebug("CSV export opened")
}

AdjustLocationCount(delta) {
    global LocListView, LocationCount
    selected := LocListView.GetNext()
    if (selected = 0) {
        MsgBox("Select a location first.", "No Selection", "Icon! 4096")
        return
    }
    locName := LocListView.GetText(selected, 1)
    LocationCount[locName] := Max(0, LocationCount[locName] + delta)
    RefreshShiftList()
}

SetLocationCount(*) {
    global LocListView, LocationCount, LocSetEdit
    selected := LocListView.GetNext()
    if (selected = 0) {
        MsgBox("Select a location first.", "No Selection", "Icon! 4096")
        return
    }
    locName := LocListView.GetText(selected, 1)
    try
        newCount := Integer(LocSetEdit.Value)
    catch
        newCount := 0
    LocationCount[locName] := Max(0, newCount)
    RefreshShiftList()
}

FormatSeconds(seconds) {
    if (seconds < 0)
        return "Expired"
    mins := Floor(seconds / 60)
    secs := Mod(seconds, 60)
    return mins . "m " . secs . "s"
}

ClearSelectedShift(*) {
    global ShiftListView, ActiveShifts, LocationCount
    selected := ShiftListView.GetNext()
    if (selected = 0) {
        MsgBox("Select a shift first.", "No Selection", "Icon! 4096")
        return
    }
    playerName := ShiftListView.GetText(selected, 1)
    if ActiveShifts.Has(StrLower(playerName)) {
        data := ActiveShifts[StrLower(playerName)]
        if (data.type = "Shift" && LocationCount.Has(data.location))
            LocationCount[data.location] := Max(0, LocationCount[data.location] - 1)
        ActiveShifts.Delete(StrLower(playerName))
        LogDebug("Manual clear: " playerName)
        PlaySound(SoundClearShiftFile, 500, 80)
    }
    RefreshShiftList()
}

ClearAllShifts(*) {
    global ActiveShifts, LocationCount, Locations
    result := MsgBox("Clear ALL active shifts?", "Confirm", "YesNo Icon? 4096")
    if (result != "Yes")
        return
    for loc in Locations
        LocationCount[loc] := 0
    ActiveShifts.Clear()
    LogDebug("All shifts manually cleared")
    PlaySound(SoundClearAllFile, 300, 200)
    RefreshShiftList()
}

*F12:: {
    global ShiftManagerGui
    if !ShiftManagerGui
        BuildShiftManagerGui()
    if WinExist("Shift Manager")
        ShiftManagerGui.Hide()
    else {
        RefreshShiftList()
        ShiftManagerGui.Show("w800 h560")
    }
}

; ──────────────── Periodic Cleanup ────────────────
SetTimer(CleanExpiredShifts, 30000)
SetTimer(ResetDailyXP, 3600000)
SetTimer(CleanupRecentRequests, 60000)

CleanupRecentRequests() {
    global RecentRequests
    now := A_Now
    for player, timestamp in RecentRequests.Clone() {
        if (DateDiff(now, timestamp, "Seconds") > 300)
            RecentRequests.Delete(player)
    }
}

ResetDailyXP() {
    global DailyShiftCount, DailyXPFile
    if (A_Hour = 0 && A_Min < 5) {
        DailyShiftCount := Map()
        FileDelete(DailyXPFile)
        LogDebug("Daily XP reset")
    }
}

CleanExpiredShifts() {
    global ActiveShifts, LocationCount
    now := A_Now, expiredPlayers := []
    for player, data in ActiveShifts {
        if (now >= data.endTime)
            expiredPlayers.Push(player)
    }
    for player in expiredPlayers {
        data := ActiveShifts[player]
        if (data.type = "Shift" && LocationCount.Has(data.location))
            LocationCount[data.location] := Max(0, LocationCount[data.location] - 1)
        ActiveShifts.Delete(player)
        LogDebug("Shift expired: " player)
    }
}

; ──────────────── Active Shift Checker ────────────────
IsShiftActive(playerName) {
    global ActiveShifts, ShiftCooldownSeconds
    if !ActiveShifts.Has(StrLower(playerName))
        return false
    endTime := ActiveShifts[StrLower(playerName)].endTime
    timeLeft := DateDiff(endTime, A_Now, "Seconds")
    return timeLeft > ShiftCooldownSeconds
}

; ──────────────── CCTV Rank Checker ────────────────
CanRequestCCTV(line) {
    global EscapedCCTVRanks
    for rank in EscapedCCTVRanks {
        if RegExMatch(line, rank . " ([^:]+):.*\bShift Me\b CCTV")
            return true
    }
    return false
}

; ──────────────── Location Manager ────────────────
GetNextAvailableLocation() {
    global Locations, LocationCount
    availableLocations := []
    for loc in Locations {
        if (LocationCount[loc] < 3)
            availableLocations.Push(loc)
    }
    if (availableLocations.Length = 0)
        return Locations[Random(1, Locations.Length)]
    return availableLocations[Random(1, availableLocations.Length)]
}

; ──────────────── Log Reader ────────────────
ReadNewLines(filePath) {
    global LastLogSize
    if !FileExist(filePath)
        return ""
    fileSize := FileGetSize(filePath)
    if (fileSize < LastLogSize)
        LastLogSize := 0
    if (fileSize <= LastLogSize)
        return ""
    file := FileOpen(filePath, "r", "UTF-8")
    if !file
        return ""
    file.Seek(LastLogSize)
    newContent := file.Read()
    LastLogSize := fileSize
    file.Close()
    return newContent
}

; ──────────────── Request Collector ────────────────
CollectRequests(lines) {
    global RecentRequests
    requests := []
    
    for line in lines {
        if (line = "")
            continue
        
        if RegExMatch(line, "\bGST Me\b") {
            playerName := ExtractPlayerNameGST(line)
            if (playerName = "")
                continue
            playerLower := StrLower(playerName)
            if RecentRequests.Has(playerLower) {
                if (DateDiff(A_Now, RecentRequests[playerLower], "Seconds") < 5)
                    continue
            }
            RecentRequests[playerLower] := A_Now
            if IsSelfRequest(playerName)
                continue
            if IsShiftActive(playerName) {
                endTime := ActiveShifts[StrLower(playerName)].endTime
                et := FormatTime(endTime, "HH:mm")
                SendChatMessage("b Rad " playerName " || R: Shift Shoma Hanoz Tamam Nashode | ET: " et)
                LogDebug("Rejected (active shift): " playerName)
                PlaySound(SoundRejectedFile, 400, 80), Sleep(50), PlaySound(SoundRejectedFile, 400, 80)
                continue
            }
            LogDebug("GST request detected: " playerName)
            requests.Push({name: playerName, type: "gst"})
            continue
        }
        
        if RegExMatch(line, "\bShift Me\b") && InStr(line, "CCTV") {
            playerName := ExtractPlayerName(line)
            if (playerName = "")
                continue
            playerLower := StrLower(playerName)
            if RecentRequests.Has(playerLower) {
                if (DateDiff(A_Now, RecentRequests[playerLower], "Seconds") < 5)
                    continue
            }
            RecentRequests[playerLower] := A_Now
            if IsSelfRequest(playerName)
                continue
            if !CanRequestCCTV(line) {
                SendChatMessage("b Rad " playerName " || R: Rank Shoma Kafi Nist!")
                LogDebug("Rejected (rank): " playerName)
                PlaySound(SoundRejectedFile, 400, 80), Sleep(50), PlaySound(SoundRejectedFile, 400, 80)
                continue
            }
            if IsShiftActive(playerName) {
                endTime := ActiveShifts[StrLower(playerName)].endTime
                et := FormatTime(endTime, "HH:mm")
                SendChatMessage("b Rad " playerName " || R: Shift Shoma Hanoz Tamam Nashode | ET: " et)
                LogDebug("Rejected (active shift): " playerName)
                PlaySound(SoundRejectedFile, 400, 80), Sleep(50), PlaySound(SoundRejectedFile, 400, 80)
                continue
            }
            LogDebug("CCTV request detected: " playerName)
            requests.Push({name: playerName, type: "cctv"})
            continue
        }
        
        if RegExMatch(line, "\bShift Me\b") && InStr(line, "CNN") {
            playerName := ExtractPlayerName(line)
            if (playerName = "")
                continue
            playerLower := StrLower(playerName)
            if RecentRequests.Has(playerLower) {
                if (DateDiff(A_Now, RecentRequests[playerLower], "Seconds") < 5)
                    continue
            }
            RecentRequests[playerLower] := A_Now
            if IsSelfRequest(playerName)
                continue
            if IsShiftActive(playerName) {
                endTime := ActiveShifts[StrLower(playerName)].endTime
                et := FormatTime(endTime, "HH:mm")
                SendChatMessage("b Rad " playerName " || R: Shift Shoma Hanoz Tamam Nashode | ET: " et)
                LogDebug("Rejected (active shift): " playerName)
                PlaySound(SoundRejectedFile, 400, 80), Sleep(50), PlaySound(SoundRejectedFile, 400, 80)
                continue
            }
            if (A_Hour < CNNStartHour) {
                SendChatMessage("b Rad " playerName " || R: Shift CNN " CNNStartHour ":00 Ta 00:00 !")
                LogDebug("Rejected (CNN time): " playerName)
                PlaySound(SoundRejectedFile, 400, 80), Sleep(50), PlaySound(SoundRejectedFile, 400, 80)
                continue
            }
            LogDebug("CNN request detected: " playerName)
            requests.Push({name: playerName, type: "cnn"})
            continue
        }
        
        if RegExMatch(line, "\bShift Me\b") && !InStr(line, "CNN") && !InStr(line, "CCTV") {
            playerName := ExtractPlayerName(line)
            if (playerName = "")
                continue
            playerLower := StrLower(playerName)
            if RecentRequests.Has(playerLower) {
                if (DateDiff(A_Now, RecentRequests[playerLower], "Seconds") < 5)
                    continue
            }
            RecentRequests[playerLower] := A_Now
            if IsSelfRequest(playerName)
                continue
            if IsShiftActive(playerName) {
                endTime := ActiveShifts[StrLower(playerName)].endTime
                et := FormatTime(endTime, "HH:mm")
                SendChatMessage("b Rad " playerName " || R: Shift Shoma Hanoz Tamam Nashode | ET: " et)
                LogDebug("Rejected (active shift): " playerName)
                PlaySound(SoundRejectedFile, 400, 80), Sleep(50), PlaySound(SoundRejectedFile, 400, 80)
                continue
            }
            LogDebug("Shift request detected: " playerName)
            requests.Push({name: playerName, type: "shift"})
            continue
        }
    }
    return requests
}

; ──────────────── Main Check ────────────────
CheckLog() {
    global ScriptEnabled, Processing, PendingQueue, LogFile
    if !ScriptEnabled || Processing
        return
    Processing := true
    try {
        if (PendingQueue.Length > 0) {
            ProcessPending()
            return
        }
        newContent := ReadNewLines(LogFile)
        if (newContent = "")
            return
        lines := StrSplit(newContent, "`n")
        requests := CollectRequests(lines)
        for req in requests
            PendingQueue.Push(req)
        if (PendingQueue.Length > 0)
            ProcessPending()
    } finally {
        Processing := false
    }
}

ProcessPending() {
    global ScriptEnabled, PendingQueue, ActiveShifts, LocationCount, DailyShiftCount
    if !ScriptEnabled
        return
    if (PendingQueue.Length = 0)
        return
    request := PendingQueue[1], success := false
    if (request.type = "gst") {
        t := DateAdd(A_Now, 15, "Minutes"), et := FormatTime(t, "HH:mm")
        msg := "b Start GST || " . request.name . " || ST : Now || Loc : LS || ET : " . et
        success := SendChatMessage(msg)
        if success {
            ActiveShifts[StrLower(request.name)] := {endTime: t, location: "LS", type: "GST"}
            LogDebug("GST sent: " request.name " | ET: " et), PlaySound(SoundShiftSentFile, 800, 100)
            LogShiftToCSV(request.name, "GST", "LS", FormatTime(A_Now, "HH:mm"), et)
        }
    } else if (request.type = "cctv") {
        t := DateAdd(A_Now, 15, "Minutes"), et := FormatTime(t, "HH:mm")
        msg := "b Start Shift CCTV || " . request.name . " || ST : Now || ET : " . et
        success := SendChatMessage(msg)
        if success {
            ActiveShifts[StrLower(request.name)] := {endTime: t, location: "CCTV", type: "CCTV"}
            LogDebug("CCTV sent: " request.name " | ET: " et), PlaySound(SoundShiftSentFile, 800, 100)
            LogShiftToCSV(request.name, "CCTV", "CCTV", FormatTime(A_Now, "HH:mm"), et)
        }
    } else if (request.type = "cnn") {
        t := DateAdd(A_Now, 15, "Minutes"), et := FormatTime(t, "HH:mm")
        msg := "b Start Shift CNN || " . request.name . " || ST : Now || ET : " . et
        success := SendChatMessage(msg)
        if success {
            ActiveShifts[StrLower(request.name)] := {endTime: t, location: "CNN", type: "CNN"}
            LogDebug("CNN sent: " request.name " | ET: " et), PlaySound(SoundShiftSentFile, 800, 100)
            LogShiftToCSV(request.name, "CNN", "CNN", FormatTime(A_Now, "HH:mm"), et)
        }
    } else {
        location := GetNextAvailableLocation()
        t := DateAdd(A_Now, 15, "Minutes"), et := FormatTime(t, "HH:mm")
        msg := "b Start Shift || " . request.name . " || ST : Now || Loc : " . location . " || ET : " . et
        success := SendChatMessage(msg)
        if success {
            ActiveShifts[StrLower(request.name)] := {endTime: t, location: location, type: "Shift"}
            LocationCount[location] += 1
            LogDebug("Shift sent: " request.name " | Loc: " location " | ET: " et), PlaySound(SoundShiftSentFile, 800, 100)
            LogShiftToCSV(request.name, "Shift", location, FormatTime(A_Now, "HH:mm"), et)
        }
    }
    if success {
        playerLower := StrLower(request.name)
        if !DailyShiftCount.Has(playerLower)
            DailyShiftCount[playerLower] := 0
        DailyShiftCount[playerLower] += 1
        SaveDailyXP()
    }
    if (PendingQueue.Length = 0)
        return
    PendingQueue.RemoveAt(1)
    if !success {
        LogDebug("Send FAILED: " request.name)
        PlaySound(SoundErrorFile, 200, 300)
    }
    if (PendingQueue.Length > 0)
    ProcessPending()
}

; ──────────────── Unified Message Sender ────────────────
SendChatMessage(text) {
    global LastVerifySize, LogFile
    if !WinExist("MTA: San Andreas")
        return false
    WinActivate("MTA: San Andreas")
    if !WinWaitActive("MTA: San Andreas", , 2)
        return false
    prevClipboard := ClipboardAll(), success := false
    try {
        BlockInput true
        Sleep(150)
        SendInput("{LButton up}{RButton up}{MButton up}{XButton1 up}{XButton2 up}{Tab up}{CapsLock up}{Shift up}{LShift up}{RShift up}{Ctrl up}{LCtrl up}{RCtrl up}{Alt up}{LAlt up}{RAlt up}{LWin up}{RWin up}{Space up}{Enter up}{Backspace up}{Esc up}{Insert up}{Delete up}{Home up}{End up}{PgUp up}{PgDn up}{Up up}{Down up}{Left up}{Right up}{ScrollLock up}{Pause up}{PrintScreen up}{AppsKey up}{0 up}{1 up}{2 up}{3 up}{4 up}{5 up}{6 up}{7 up}{8 up}{9 up}{a up}{b up}{c up}{d up}{e up}{f up}{g up}{h up}{i up}{j up}{k up}{l up}{m up}{n up}{o up}{p up}{q up}{r up}{s up}{t up}{u up}{v up}{w up}{x up}{y up}{z up}{F1 up}{F2 up}{F3 up}{F4 up}{F5 up}{F6 up}{F7 up}{F8 up}{F9 up}{F10 up}{F11 up}{F12 up}{Numpad0 up}{Numpad1 up}{Numpad2 up}{Numpad3 up}{Numpad4 up}{Numpad5 up}{Numpad6 up}{Numpad7 up}{Numpad8 up}{Numpad9 up}{NumpadAdd up}{NumpadSub up}{NumpadMult up}{NumpadDiv up}{NumpadDot up}{NumpadEnter up}{`` up}{- up}{= up}{[ up}{] up}{\ up}{; up}{' up}{, up}{. up}{/ up}")
        Sleep(150)
        SendInput("{Esc}"), Sleep(150)
        SendInput("{F8}"), Sleep(170)
        SendInput("b Done"), Sleep(150), SendInput("{Enter}"), Sleep(300)
        A_Clipboard := text
        if !ClipWait(1)
            return false
        SendInput("^v"), Sleep(150), SendInput("{Enter}"), Sleep(350)
        SendInput("{F8}"), Sleep(150)
        SendInput("{Esc}"), Sleep(150)
        success := true
    } finally {
        BlockInput false
        RestoreClipboard(prevClipboard)
    }
    return success
}

; ──────────────── Name Extractors ────────────────
ExtractPlayerName(line) {
    global EscapedRanks
    for rank in EscapedRanks {
        if RegExMatch(line, rank . " ([^:]+):.*\bShift Me\b", &match)
            return Trim(match[1])
        if RegExMatch(line, rank . " ([^:]+):.*\bShift Me\b CCTV", &match)
            return Trim(match[1])
        if RegExMatch(line, rank . " ([^:]+):.*\bShift Me\b CNN", &match)
            return Trim(match[1])
    }
    if RegExMatch(line, "\)\s*\(\s*(?:[^)]+)\s+([^:]+):\s*\bShift Me\b", &match)
        return Trim(match[1])
    if RegExMatch(line, "\)\s*\(\s*(?:[^)]+)\s+([^:]+):\s*\bShift Me\b CCTV", &match)
        return Trim(match[1])
    return ""
}

ExtractPlayerNameGST(line) {
    global EscapedRanks
    for rank in EscapedRanks {
        if RegExMatch(line, rank . " ([^:]+):.*\bGST Me\b", &match)
            return Trim(match[1])
    }
    if RegExMatch(line, "\)\s*\(\s*(?:[^)]+)\s+([^:]+):\s*\bGST Me\b", &match)
        return Trim(match[1])
    return ""
}

; ──────────────── Debug Logger ────────────────
LogDebug(message) {
    global DebugLogFile
    timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    FileAppend("[" timestamp "] " message "`n", DebugLogFile, "UTF-8")
}

; ──────────────── Clipboard Restore ────────────────
RestoreClipboard(clipData) {
    A_Clipboard := clipData
}
test
