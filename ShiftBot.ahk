#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook
#Warn All, Off

Persistent

; ──────────────── Version ────────────────
global CurrentVersion := "1.0.4"

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
global ShiftCooldownSeconds := 30
global MyNameEdit := ""
global LogFileEdit := ""
global LastVersionFile := A_ScriptDir "\last_version.txt"
global ChangelogURL := "https://raw.githubusercontent.com/Menethil-MTA/Update/refs/heads/main/changelog.txt"
global UseManualLocation := false
global ManualLocation := ""
global LockedPlayers := Map()
global CurrentLang := "EN"
global Lang := Map()
global LangDropdown := ""
global LocSetEdit := ""

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
CurrentLang := IniRead(ConfigFile, "Settings", "Language", "EN")
Locations := StrSplit(IniRead(ConfigFile, "Settings", "Locations", "Medic,Fish1,Fish2,Civilian,Dadgostari,Masjed,PD,Bank,Paint Ball"), ",")
Ranks := StrSplit(IniRead(ConfigFile, "Settings", "Ranks", "Kar Amooz,Tazekar,KhabarNegar,Dastyar Mojri,Mojri,Sardabir,Moavenat ll,Modiriat"), ",")
CCTVRanks := ["Sardabir", "Modiriat", "Mojri", "Moavenat ll"]

; ──────────────── Language System ────────────────
LoadLanguage(lng) {
    global Lang, CurrentLang
    CurrentLang := lng
    Lang := Map()
    
    if (lng = "FA") {
        Lang["active_shifts"] := "شیفت‌های فعال"
        Lang["locations"] := "لوکیشن‌ها"
        Lang["daily_xp"] := "XP روزانه"
        Lang["settings"] := "تنظیمات"
        Lang["your_name"] := "نام شما:"
        Lang["save_name"] := "ذخیره نام"
        Lang["log_path"] := "مسیر فایل لاگ:"
        Lang["save_path"] := "ذخیره مسیر"
        Lang["total_shifts"] := "کل شیفت‌ها: "
        Lang["clear_selected"] := "حذف انتخاب شده"
        Lang["clear_all"] := "حذف همه"
        Lang["refresh"] := "بروزرسانی"
        Lang["currently_active"] := "شیفت‌های فعال فعلی"
        Lang["location_dist"] := "توزیع لوکیشن‌ها"
        Lang["manual_adjust"] := "تنظیم دستی:"
        Lang["daily_shifts"] := "شیفت‌های امروز هر بازیکن"
        Lang["personal_settings"] := "تنظیمات شخصی"
        Lang["hotkeys"] := "کلیدهای میانبر:"
        Lang["hotkey_insert"] := "Delete  →  روشن/خاموش کردن اسکریپت"
        Lang["hotkey_f10"] := "F10  →  تغییر لوکیشن (شامل Random)"
        Lang["hotkey_f12"] := "F12  →  این منو"
        Lang["check_update"] := "بررسی بروزرسانی"
        Lang["export_csv"] := "خروجی CSV"
        Lang["current_mode"] := "حالت فعلی: "
        Lang["player"] := "بازیکن"
        Lang["type"] := "نوع"
        Lang["location"] := "لوکیشن"
        Lang["end_time"] := "زمان پایان"
        Lang["time_left"] := "زمان باقیمانده"
        Lang["shifts_today"] := "شیفت‌های امروز"
        Lang["language"] := "زبان:"
        Lang["select_language"] := "انتخاب زبان"
        Lang["tooltip_random"] := "لوکیشن: رندوم (انتخاب خودکار با حداکثر ۳ نفر)"
        Lang["tooltip_manual"] := "لوکیشن: "
        Lang["tooltip_manual_suffix"] := " (دستی)"
        Lang["tooltip_on"] := "اسکریپت: روشن"
        Lang["tooltip_off"] := "اسکریپت: خاموش"
        Lang["rejected_active"] := "b Rad "
        Lang["rejected_msg"] := " || R: Shift Shoma Hanoz Tamam Nashode | ET: "
        Lang["rejected_rank"] := "b Rad "
        Lang["rejected_rank_msg"] := " || R: Rank Shoma Kafi Nist!"
        Lang["rejected_cnn"] := "b Rad "
        Lang["rejected_cnn_msg"] := " || R: Shift CNN "
        Lang["rejected_cnn_msg2"] := ":00 Ta 00:00 !"
        Lang["start_gst"] := "b Start GST || "
        Lang["start_cctv"] := "b Start Shift CCTV || "
        Lang["start_cnn"] := "b Start Shift CNN || "
        Lang["start_shift"] := "b Start Shift || "
        Lang["st_now"] := " || ST : Now || Loc : "
        Lang["st_now_no_loc"] := " || ST : Now || ET : "
        Lang["et"] := " || ET : "
        Lang["loc_ls"] := "LS"
        Lang["received"] := "Daryaft Shod"
    } else {
        Lang["active_shifts"] := "Active Shifts"
        Lang["locations"] := "Locations"
        Lang["daily_xp"] := "Daily XP"
        Lang["settings"] := "Settings"
        Lang["your_name"] := "Your Name:"
        Lang["save_name"] := "Save Name"
        Lang["log_path"] := "Log File Path:"
        Lang["save_path"] := "Save Path"
        Lang["total_shifts"] := "Total Shifts: "
        Lang["clear_selected"] := "Clear Selected"
        Lang["clear_all"] := "Clear All"
        Lang["refresh"] := "Refresh"
        Lang["currently_active"] := "Currently Active Shifts"
        Lang["location_dist"] := "Location Distribution"
        Lang["manual_adjust"] := "Manual Adjust:"
        Lang["daily_shifts"] := "Today's Shifts per Player"
        Lang["personal_settings"] := "Personal Settings"
        Lang["hotkeys"] := "Hotkeys:"
        Lang["hotkey_insert"] := "Delete  →  Toggle Script On/Off"
        Lang["hotkey_f10"] := "F10  →  Change Location (includes Random)"
        Lang["hotkey_f12"] := "F12  →  This Menu"
        Lang["check_update"] := "Check for Updates"
        Lang["export_csv"] := "Export CSV"
        Lang["current_mode"] := "Current Mode: "
        Lang["player"] := "Player"
        Lang["type"] := "Type"
        Lang["location"] := "Location"
        Lang["end_time"] := "End Time"
        Lang["time_left"] := "Time Left"
        Lang["shifts_today"] := "Shifts Today"
        Lang["language"] := "Language:"
        Lang["select_language"] := "Select Language"
        Lang["tooltip_random"] := "Location: RANDOM (auto-select with max 3 per loc)"
        Lang["tooltip_manual"] := "Location: "
        Lang["tooltip_manual_suffix"] := " (manual)"
        Lang["tooltip_on"] := "Script: ON"
        Lang["tooltip_off"] := "Script: OFF"
        Lang["rejected_active"] := "b Rad "
        Lang["rejected_msg"] := " || R: Shift Shoma Hanoz Tamam Nashode | ET: "
        Lang["rejected_rank"] := "b Rad "
        Lang["rejected_rank_msg"] := " || R: Rank Shoma Kafi Nist!"
        Lang["rejected_cnn"] := "b Rad "
        Lang["rejected_cnn_msg"] := " || R: Shift CNN "
        Lang["rejected_cnn_msg2"] := ":00 Ta 00:00 !"
        Lang["start_gst"] := "b Start GST || "
        Lang["start_cctv"] := "b Start Shift CCTV || "
        Lang["start_cnn"] := "b Start Shift CNN || "
        Lang["start_shift"] := "b Start Shift || "
        Lang["st_now"] := " || ST : Now || Loc : "
        Lang["st_now_no_loc"] := " || ST : Now || ET : "
        Lang["et"] := " || ET : "
        Lang["loc_ls"] := "LS"
        Lang["received"] := "Daryaft Shod"
    }
}

LoadLanguage(CurrentLang)

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
    EscapedRanks.Push(RegExReplace(rank, "([\\\.\*\+\?\^\$\[\]\(\)\{\|\-])", "\$1"))

for rank in CCTVRanks
    EscapedCCTVRanks.Push(RegExReplace(rank, "([\\\.\*\+\?\^\$\[\]\(\)\{\|\-])", "\$1"))

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
LogDebug("Script initialized. v" CurrentVersion " | LogFile: " LogFile " | Language: " CurrentLang)
ShowChangelog()

; ──────────────── Changelog Function ────────────────
ShowChangelog() {
    global CurrentVersion, LastVersionFile, ChangelogURL
    
    lastVersion := ""
    if FileExist(LastVersionFile)
        lastVersion := Trim(FileRead(LastVersionFile, "UTF-8"))
    
    if (lastVersion != CurrentVersion) {
        try FileDelete(LastVersionFile)
        FileAppend(CurrentVersion, LastVersionFile, "UTF-8")
        
        changelog := "No changelog available."
        try {
            whr := ComObject("WinHttp.WinHttpRequest.5.1")
            whr.Open("GET", ChangelogURL, false)
            whr.SetTimeouts(5000, 5000, 5000, 5000)
            whr.Send()
            if (whr.Status = 200)
                changelog := whr.ResponseText
        }
        
        ChangelogGui := Gui("+AlwaysOnTop", "What's New - v" CurrentVersion)
        ChangelogGui.BackColor := "0D1117"
        ChangelogGui.SetFont("s10 bold c58A6FF", "Segoe UI")
        ChangelogGui.AddText("x20 y20 w500", "Updated to Version " CurrentVersion)
        ChangelogGui.SetFont("s9 norm cCDD6F4", "Segoe UI")
        ChangelogGui.AddEdit("x20 y60 w500 h300 ReadOnly Background161B22 cE6EDF3", changelog)
        ChangelogGui.AddButton("x200 y375 w100 h30", "OK").OnEvent("Click", (*) => ChangelogGui.Destroy())
        ChangelogGui.Show("w540 h420")
    }
}

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
    
    try {
        ; دانلود مستقیم فایل EXE
        exePath := A_ScriptDir "\ShiftBot.exe"
        try FileDelete(exePath)
        
        ; استفاده از UrlDownloadToFile
        URLDownloadToFile("https://raw.githubusercontent.com/Menethil-MTA/Update/refs/heads/main/ShiftBot.exe", exePath)
        
        if FileExist(exePath) {
            ; ساخت فایل BAT
            batchFile := A_ScriptDir "\_update.bat"
            try FileDelete(batchFile)
            
            batContent := "@echo off`r`n"
            batContent .= "timeout /t 2 /nobreak >nul`r`n"
            batContent .= "del /f /q `"" A_ScriptFullPath "`"`r`n"
            batContent .= "start `"`" `"" exePath "`"`r`n"
            batContent .= "del /f /q `"" batchFile "`"`r`n"
            FileAppend(batContent, batchFile, "UTF-8")
            
            Run(batchFile, , "Hide")
            ExitApp()
        } else {
            MsgBox("Download failed!", "Error", "IconX 4096")
        }
    } catch as err {
        MsgBox("Update failed:`n" err.Message, "Error", "IconX 4096")
    }
}

; تابع دانلود
URLDownloadToFile(url, filename) {
    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", url, true)
        whr.Send()
        whr.WaitForResponse()
        
        ; ذخیره با ADODB.Stream
        ado := ComObject("ADODB.Stream")
        ado.Type := 1
        ado.Open()
        ado.Write(whr.ResponseBody)
        ado.SaveToFile(filename, 2)
        ado.Close()
        return true
    } catch {
        return false
    }
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
        result := MsgBox("File not found:`n" newPath "`n`nSave anyway?", "Warning", "YesNo Icon? 4096")
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

; ──────────────── Save Language ────────────────
SaveLanguage(*) {
    global LangDropdown, ConfigFile, CurrentLang
    newLang := LangDropdown.Text
    IniWrite(newLang, ConfigFile, "Settings", "Language")
    LoadLanguage(newLang)
    BuildShiftManagerGui()
    MsgBox("Language changed to: " newLang, "Success", "Iconi 4096")
    LogDebug("Language changed to: " newLang)
}

; ──────────────── Hotkeys ────────────────
*Insert:: {
    global ScriptEnabled, LogFile, LastLogSize, LastVerifySize, PollInterval, Lang
    ScriptEnabled := !ScriptEnabled
    if ScriptEnabled {
        if FileExist(LogFile)
            LastLogSize := FileGetSize(LogFile), LastVerifySize := LastLogSize
        ToolTip(Lang["tooltip_on"], , , 1)
        SetTimer(CheckLog, PollInterval)
        LogDebug("Script ENABLED. PollInterval: " PollInterval "ms")
        PlaySound(SoundEnabledFile, 600, 100)
    } else {
        ToolTip(Lang["tooltip_off"], , , 1)
        SetTimer(CheckLog, 0)
        LogDebug("Script DISABLED")
        PlaySound(SoundDisabledFile, 300, 150)
    }
    SetTimer(() => ToolTip(, , , 1), -3000)
}

*F10:: {
    global CurrentLocIndex, Locations, UseManualLocation, ManualLocation, Lang
    
    extendedLocations := Locations.Clone()
    extendedLocations.Push("Random")
    
    CurrentLocIndex := Mod(CurrentLocIndex, extendedLocations.Length) + 1
    selectedLoc := extendedLocations[CurrentLocIndex]
    
    if (selectedLoc = "Random") {
        UseManualLocation := false
        ManualLocation := ""
        ToolTip(Lang["tooltip_random"], , , 2)
        LogDebug("Location mode set to: RANDOM")
    } else {
        UseManualLocation := true
        ManualLocation := selectedLoc
        ToolTip(Lang["tooltip_manual"] selectedLoc Lang["tooltip_manual_suffix"], , , 2)
        LogDebug("Location manually set to: " selectedLoc)
    }
    
    SetTimer(() => ToolTip(, , , 2), -3000)
}

; ──────────────── GUI: Shift Manager ────────────────
BuildShiftManagerGui() {
    global ShiftManagerGui, ActiveShifts, LocationCount, Locations, LocListView, XpListView, DailyShiftCount, ShiftListView, TotalText, MyNameEdit, MyName, LogFileEdit, LogFile, UseManualLocation, ManualLocation, Lang, CurrentLang, LangDropdown, LocSetEdit
    
    if ShiftManagerGui
        ShiftManagerGui.Destroy()
    
    ShiftManagerGui := Gui("+AlwaysOnTop -Caption +Border", "ShiftBot Manager")
    ShiftManagerGui.BackColor := "0D1117"
    ShiftManagerGui.SetFont("s9", "Segoe UI")
    
    ; ── Title Bar ──
    TitleBar := ShiftManagerGui.AddText("x0 y0 w850 h35 +Background161B22 c58A6FF +Center 0x200", "  ShiftBot Manager v" CurrentVersion)
    TitleBar.SetFont("s11 bold", "Segoe UI")
    
    CloseBtn := ShiftManagerGui.AddText("x820 y5 w25 h25 +Background161B22 cF85149 +Center", "✕")
    CloseBtn.SetFont("s12 bold", "Segoe UI")
    CloseBtn.OnEvent("Click", (*) => ShiftManagerGui.Hide())
    
    ; ── Tabs ──
    Tab := ShiftManagerGui.AddTab3("x10 y40 w830 h510 +Background0D1117", [Lang["active_shifts"], Lang["locations"], Lang["daily_xp"], Lang["settings"]])
    Tab.SetFont("s9", "Segoe UI")
    
    ; ═══════════ TAB 1: Active Shifts ═══════════
    Tab.UseTab(1)
    ShiftManagerGui.SetFont("s10 bold cCDD6F4")
    ShiftManagerGui.AddText("x20 y80 w200", Lang["currently_active"])
    ShiftManagerGui.SetFont("s9 norm c8B949E")
    
    ShiftListView := ShiftManagerGui.AddListView("x20 y110 w790 h240 -ReadOnly Grid cE6EDF3 Background161B22", [Lang["player"], Lang["type"], Lang["location"], Lang["end_time"], Lang["time_left"]])
    ShiftListView.ModifyCol(1, 160), ShiftListView.ModifyCol(2, 80), ShiftListView.ModifyCol(3, 130), ShiftListView.ModifyCol(4, 100), ShiftListView.ModifyCol(5, 100)
    
    BtnClear := ShiftManagerGui.AddButton("x20 y360 w110 h32 +Background21262D", Lang["clear_selected"])
    BtnClear.SetFont("s9 cF85149")
    BtnClearAll := ShiftManagerGui.AddButton("x140 y360 w110 h32 +Background21262D", Lang["clear_all"])
    BtnClearAll.SetFont("s9 cF85149")
    BtnRefresh := ShiftManagerGui.AddButton("x260 y360 w110 h32 +Background21262D", Lang["refresh"])
    BtnRefresh.SetFont("s9 c58A6FF")
    TotalText := ShiftManagerGui.AddText("x390 y365 w200 c8B949E", Lang["total_shifts"] "0")
    
    currentLocText := UseManualLocation ? ManualLocation : "RANDOM"
    ShiftManagerGui.AddText("x390 y390 w400 c58A6FF", Lang["current_mode"] currentLocText)
    
    BtnClear.OnEvent("Click", ClearSelectedShift)
    BtnClearAll.OnEvent("Click", ClearAllShifts)
    BtnRefresh.OnEvent("Click", RefreshShiftList)
    
    ; ═══════════ TAB 2: Locations ═══════════
    Tab.UseTab(2)
    ShiftManagerGui.SetFont("s10 bold cCDD6F4")
    ShiftManagerGui.AddText("x20 y80 w200", Lang["location_dist"])
    ShiftManagerGui.SetFont("s9 norm c8B949E")
    
    LocListView := ShiftManagerGui.AddListView("x20 y110 w400 h280 -ReadOnly Grid cE6EDF3 Background161B22", [Lang["location"], Lang["active_shifts"]])
    LocListView.ModifyCol(1, 250), LocListView.ModifyCol(2, 130)
    
    ShiftManagerGui.AddText("x440 y110 w150 cCDD6F4", Lang["manual_adjust"])
    BtnLocPlus := ShiftManagerGui.AddButton("x440 y140 w45 h32 +Background21262D", "+1")
    BtnLocPlus.SetFont("s10 c3FB950")
    BtnLocMinus := ShiftManagerGui.AddButton("x490 y140 w45 h32 +Background21262D", "-1")
    BtnLocMinus.SetFont("s10 cF85149")
    LocSetEdit := ShiftManagerGui.AddEdit("x440 y185 w70 h28 cE6EDF3 Background21262D", "0")
    BtnLocSet := ShiftManagerGui.AddButton("x515 y185 w55 h28 +Background21262D", "Set")
    BtnLocSet.SetFont("s9 c58A6FF")
    
    BtnLocPlus.OnEvent("Click", (*) => AdjustLocationCount(1))
    BtnLocMinus.OnEvent("Click", (*) => AdjustLocationCount(-1))
    BtnLocSet.OnEvent("Click", SetLocationCount)
    
    ; ═══════════ TAB 3: Daily XP ═══════════
    Tab.UseTab(3)
    ShiftManagerGui.SetFont("s10 bold cCDD6F4")
    ShiftManagerGui.AddText("x20 y80 w250", Lang["daily_shifts"])
    ShiftManagerGui.SetFont("s9 norm c8B949E")
    
    XpListView := ShiftManagerGui.AddListView("x20 y110 w450 h300 -ReadOnly Grid cE6EDF3 Background161B22", [Lang["player"], Lang["shifts_today"]])
    XpListView.ModifyCol(1, 300), XpListView.ModifyCol(2, 130)
    
    ; ═══════════ TAB 4: Settings ═══════════
    Tab.UseTab(4)
    ShiftManagerGui.SetFont("s10 bold cCDD6F4")
    ShiftManagerGui.AddText("x20 y80 w400", Lang["personal_settings"])
    ShiftManagerGui.SetFont("s9 norm c8B949E")
    
    ShiftManagerGui.AddText("x20 y120 w100 cCDD6F4", Lang["your_name"])
    MyNameEdit := ShiftManagerGui.AddEdit("x130 y117 w200 h28 cE6EDF3 Background21262D", MyName)
    BtnSaveName := ShiftManagerGui.AddButton("x340 y117 w100 h28 +Background21262D", Lang["save_name"])
    BtnSaveName.SetFont("s9 c3FB950")
    BtnSaveName.OnEvent("Click", SaveMyName)
    
    ShiftManagerGui.AddText("x20 y165 w100 cCDD6F4", Lang["log_path"])
    LogFileEdit := ShiftManagerGui.AddEdit("x130 y162 w480 h28 cE6EDF3 Background21262D", LogFile)
    BtnSaveLog := ShiftManagerGui.AddButton("x620 y162 w100 h28 +Background21262D", Lang["save_path"])
    BtnSaveLog.SetFont("s9 c3FB950")
    BtnSaveLog.OnEvent("Click", SaveLogFile)
    
    ; Language Selection
    ShiftManagerGui.AddText("x20 y215 w100 cCDD6F4", Lang["language"])
    LangDropdown := ShiftManagerGui.AddDropDownList("x130 y212 w100 cE6EDF3 Background21262D", ["EN", "FA"])
    LangDropdown.Choose(CurrentLang = "FA" ? 2 : 1)
    BtnSaveLang := ShiftManagerGui.AddButton("x240 y212 w100 h28 +Background21262D", Lang["save_name"])
    BtnSaveLang.SetFont("s9 c3FB950")
    BtnSaveLang.OnEvent("Click", SaveLanguage)
    
    ShiftManagerGui.AddText("x20 y265 w400 c8B949E", Lang["hotkeys"])
    ShiftManagerGui.AddText("x20 y290 w400 c58A6FF", Lang["hotkey_insert"])
    ShiftManagerGui.AddText("x20 y315 w400 c58A6FF", Lang["hotkey_f10"])
    ShiftManagerGui.AddText("x20 y340 w400 c58A6FF", Lang["hotkey_f12"])
    
    BtnUpdate := ShiftManagerGui.AddButton("x20 y375 w130 h35 +Background21262D", Lang["check_update"])
    BtnUpdate.SetFont("s9 c58A6FF")
    BtnUpdate.OnEvent("Click", UpdateProgram)
    
    BtnExport := ShiftManagerGui.AddButton("x160 y375 w130 h35 +Background21262D", Lang["export_csv"])
    BtnExport.SetFont("s9 c58A6FF")
    BtnExport.OnEvent("Click", ExportCSV)
    
    ; ── Move Window ──
    TitleBar.OnEvent("Click", (*) => PostMessage(0xA1, 2, , , ShiftManagerGui))
    
    RefreshShiftList()
    ShiftManagerGui.Show("w850 h560")
}

RefreshShiftList(*) {
    global ActiveShifts, ShiftListView, TotalText, LocationCount, Locations, LocListView, DailyShiftCount, XpListView, Lang
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
        TotalText.Text := Lang["total_shifts"] ActiveShifts.Count
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
    if WinExist("ShiftBot Manager")
        ShiftManagerGui.Hide()
    else {
        RefreshShiftList()
        ShiftManagerGui.Show("w850 h560")
    }
}

; ──────────────── Periodic Cleanup ────────────────
SetTimer(CleanExpiredShifts, 30000)
SetTimer(ResetDailyXP, 30000)
SetTimer(CleanupRecentRequests, 60000)
SetTimer(RecalculateLocationCounts, 1000)

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
    static _lastDay := ""
    
    today := FormatTime(A_Now, "yyyyMMdd")
    if (today != _lastDay && A_Hour >= 0) {
        _lastDay := today
        DailyShiftCount := Map()
        try FileDelete(DailyXPFile)
        LogDebug("Daily XP reset for new day: " today)
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

; ──────────────── Recalculate Location Counts ────────────────
RecalculateLocationCounts() {
    global ActiveShifts, LocationCount, Locations
    
    for loc in Locations
        LocationCount[loc] := 0
    
    for player, data in ActiveShifts {
        if (data.type = "Shift" && LocationCount.Has(data.location))
            LocationCount[data.location] += 1
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
    global Locations, LocationCount, UseManualLocation, ManualLocation
    
    if (UseManualLocation && ManualLocation != "") {
        if (LocationCount.Has(ManualLocation) && LocationCount[ManualLocation] < 3) {
            LogDebug("Using manual location: " ManualLocation " (count: " LocationCount[ManualLocation] "->" (LocationCount[ManualLocation]+1) ")")
            return ManualLocation
        } else {
            LogDebug("WARNING: Manual location " ManualLocation " is FULL (3/3), but using it anyway")
            return ManualLocation
        }
    }
    
    availableLocations := []
    for loc in Locations {
        if (LocationCount[loc] < 3)
            availableLocations.Push(loc)
    }
    if (availableLocations.Length = 0)
        return Locations[Random(1, Locations.Length)]
    
    selected := availableLocations[Random(1, availableLocations.Length)]
    LogDebug("Random location selected: " selected " (available: " availableLocations.Length ")")
    return selected
}

; ──────────────── Unlock Player ────────────────
UnlockPlayer(playerLower) {
    global LockedPlayers
    if LockedPlayers.Has(playerLower)
        LockedPlayers.Delete(playerLower)
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
                SendChatMessage(Lang["rejected_active"] playerName Lang["rejected_msg"] et)
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
                SendChatMessage(Lang["rejected_rank"] playerName Lang["rejected_rank_msg"])
                LogDebug("Rejected (rank): " playerName)
                PlaySound(SoundRejectedFile, 400, 80), Sleep(50), PlaySound(SoundRejectedFile, 400, 80)
                continue
            }
            if IsShiftActive(playerName) {
                endTime := ActiveShifts[StrLower(playerName)].endTime
                et := FormatTime(endTime, "HH:mm")
                SendChatMessage(Lang["rejected_active"] playerName Lang["rejected_msg"] et)
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
                SendChatMessage(Lang["rejected_active"] playerName Lang["rejected_msg"] et)
                LogDebug("Rejected (active shift): " playerName)
                PlaySound(SoundRejectedFile, 400, 80), Sleep(50), PlaySound(SoundRejectedFile, 400, 80)
                continue
            }
            if (A_Hour < CNNStartHour) {
                SendChatMessage(Lang["rejected_cnn"] playerName Lang["rejected_cnn_msg"] CNNStartHour Lang["rejected_cnn_msg2"])
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
                SendChatMessage(Lang["rejected_active"] playerName Lang["rejected_msg"] et)
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
    global ScriptEnabled, PendingQueue, ActiveShifts, LocationCount, DailyShiftCount, UseManualLocation, ManualLocation, LockedPlayers, Lang
    if !ScriptEnabled
        return
    if (PendingQueue.Length = 0)
        return
    
    request := PendingQueue[1], success := false
    playerLower := StrLower(request.name)
    
    ; Check if player is locked (previous request being processed)
    if LockedPlayers.Has(playerLower) {
        LogDebug("Rejected (locked/processing): " request.name)
        PendingQueue.RemoveAt(1)
        if (PendingQueue.Length > 0)
            ProcessPending()
        return
    }
    
    ; Lock player before sending
    LockedPlayers[playerLower] := A_Now
    
    ; Double-check: does player already have an active shift?
    if (request.type != "gst" && ActiveShifts.Has(playerLower)) {
        endTime := ActiveShifts[playerLower].endTime
        timeLeft := DateDiff(endTime, A_Now, "Seconds")
        if (timeLeft > ShiftCooldownSeconds) {
            et := FormatTime(endTime, "HH:mm")
            SendChatMessage(Lang["rejected_active"] request.name Lang["rejected_msg"] et)
            LogDebug("Rejected (already active - double check): " request.name)
            PlaySound(SoundRejectedFile, 400, 80)
            LockedPlayers.Delete(playerLower)
            PendingQueue.RemoveAt(1)
            if (PendingQueue.Length > 0)
                ProcessPending()
            return
        }
    }
    
    if (request.type = "gst") {
        t := DateAdd(A_Now, 15, "Minutes"), et := FormatTime(t, "HH:mm")
        msg := Lang["start_gst"] request.name Lang["st_now"] Lang["loc_ls"] Lang["et"] et
        success := SendChatMessage(msg)
        if success {
            ActiveShifts[playerLower] := {endTime: t, location: "LS", type: "GST"}
            LogDebug("GST sent: " request.name " | ET: " et), PlaySound(SoundShiftSentFile, 800, 100)
            LogShiftToCSV(request.name, "GST", "LS", FormatTime(A_Now, "HH:mm"), et)
        }
    } else if (request.type = "cctv") {
        t := DateAdd(A_Now, 15, "Minutes"), et := FormatTime(t, "HH:mm")
        msg := Lang["start_cctv"] request.name Lang["st_now_no_loc"] et
        success := SendChatMessage(msg)
        if success {
            ActiveShifts[playerLower] := {endTime: t, location: "CCTV", type: "CCTV"}
            LogDebug("CCTV sent: " request.name " | ET: " et), PlaySound(SoundShiftSentFile, 800, 100)
            LogShiftToCSV(request.name, "CCTV", "CCTV", FormatTime(A_Now, "HH:mm"), et)
        }
    } else if (request.type = "cnn") {
        t := DateAdd(A_Now, 15, "Minutes"), et := FormatTime(t, "HH:mm")
        msg := Lang["start_cnn"] request.name Lang["st_now_no_loc"] et
        success := SendChatMessage(msg)
        if success {
            ActiveShifts[playerLower] := {endTime: t, location: "CNN", type: "CNN"}
            LogDebug("CNN sent: " request.name " | ET: " et), PlaySound(SoundShiftSentFile, 800, 100)
            LogShiftToCSV(request.name, "CNN", "CNN", FormatTime(A_Now, "HH:mm"), et)
        }
    } else {
        location := GetNextAvailableLocation()
        t := DateAdd(A_Now, 15, "Minutes"), et := FormatTime(t, "HH:mm")
        msg := Lang["start_shift"] request.name Lang["st_now"] location Lang["et"] et
        success := SendChatMessage(msg)
        if success {
            ActiveShifts[playerLower] := {endTime: t, location: location, type: "Shift"}
            LocationCount[location] += 1
            modeText := UseManualLocation ? "Manual" : "Random"
            LogDebug("Shift sent (" modeText "): " request.name " | Loc: " location " | ET: " et), PlaySound(SoundShiftSentFile, 800, 100)
            LogShiftToCSV(request.name, "Shift", location, FormatTime(A_Now, "HH:mm"), et)
        }
    }
    
    ; Unlock player after 2 seconds
    SetTimer(() => UnlockPlayer(playerLower), -2000)
    
    if success {
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
        SendInput("{Esc}"), Sleep(200)
        SendInput("{F8}"), Sleep(250)
        SendInput("b Done"), Sleep(200)
        SendInput("{Enter}"), Sleep(400)
        A_Clipboard := text
        if !ClipWait(1)
            return false
        SendInput("^v"), Sleep(200)
        SendInput("{Enter}"), Sleep(400)
        SendInput("{F8}"), Sleep(250)
        SendInput("{Esc}"), Sleep(200)
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
