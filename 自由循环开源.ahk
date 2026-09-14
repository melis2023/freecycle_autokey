; =====================  依赖  =====================
#NoEnv
#SingleInstance
#Include gdip_all.ahk
; ==================================================
ScriptDir := A_ScriptDir
NewFolder := ScriptDir . "\start_config"
FileCreateDir, %NewFolder%
config_file := A_ScriptDir . "\start_config\config.ini"

SetBatchLines, -1 ; 让脚本以最高速度运行
SetWinDelay, 0 ; 减少窗口操作的延迟
SetKeyDelay, 0 ; 减少按键操作的延迟
SetControlDelay, 0 ; 减少控件操作的延迟

If !pToken := Gdip_Startup()
{
    MsgBox, 48, GDI+ 启动失败
    ExitApp
}
OnExit, ExitSub

; ---------- 全局变量 ----------
Global pFreezeBitmap   ; 保存冻结画面的
Global FreezeHwnd     ; 全屏冻结窗口句柄
Global ScreenW, ScreenH ,MonLeft,MonTop,inifile,option,mainskill
    global running      ; 设为全局变量

SysGet, Mon, Monitor
ScreenW := MonRight - MonLeft
ScreenH := MonBottom - MonTop

; ---------- 写入数据 ----------
IniRead,option,%config_file%,当前职业,职业名称
;识别当前职业配置
inifile:=NewFolder . "\" option . ".ini"
    
if(option=="ERROR")
{
    IniWrite,% "",%config_file%,当前职业,职业名称
    
    IniWrite,Capslock,%config_file%,技能按键,startkey
    
    IniWrite,f9,%config_file%,技能按键,getkey
}

; ---------- 读取数据 ----------

IniRead,startkey,%config_file%,技能按键,startkey

IniRead,getkey,%config_file%,技能按键,getkey

if(startkey=="" or startkey=="ERROR")
{
    startkey:="Capslock"
}

if(getkey=="" or getkey=="ERROR")
{
    getkey:="f9"
}

; ---------- 读取职业数据 ----------
IniRead,mainskill,%inifile%,主循环,循环顺序
    ;读取职业按键
if (InStr(mainskill, ",") > 0)
{
    msgbox 输入错误，技能分割符为中文的逗号
    return
}
;读取配置信息
skill_set:={}
Loop, Parse, mainskill, `，   ; 注意这里是中文逗号
{
    thisSkill := A_LoopField
    if (InStr(thisSkill, "=") > 0)
    {
        parts := StrSplit(thisSkill, "=")
        
        for index, part in parts {
            
            IniRead, skillData, %IniFile%, 技能信息, %part%
                params := StrSplit(skillData, ",")
            skill_set[part] := {key1: params[1], wait1: params[2]}
            
        }
    }
    else
    {
        IniRead, skillData, %IniFile%, 技能信息, %thisSkill%
            params := StrSplit(skillData, ",")
        skill_set[thisSkill] := {key1: params[1], wait1: params[2]}
    }
    ;msgbox %  skill_set[thisSkill].key1 skill_set[thisSkill].wait1
    
}

Loop, Parse, mainskill, `，   ; 注意这里是中文逗号
{
    thisSkill := A_LoopField
    
    if (InStr(thisSkill, "=") > 0)
    {
        
        parts := StrSplit(thisSkill, "=")
        
        for index, part in parts {
            
            IniRead, %part%x, %inifile%,技能信息, %part%x
                IniRead, %part%y, %IniFile%, 技能信息, %part%y
                IniRead, %part%color, %IniFile%, 技能信息, %part%color
            }
    }
    else
    {
        IniRead, %thisSkill%x, %inifile%,技能信息, %thisSkill%x
            IniRead, %thisSkill%y, %IniFile%, 技能信息, %thisSkill%y
            IniRead, %thisSkill%color, %IniFile%, 技能信息, %thisSkill%color
        }
    
    if(xValue=="ERROR" or yValue=="ERROR" or colorValue=="ERROR")
    {
        break
    }
    
    ;MsgBox, % "第" A_Index "个技能：" thisSkill " " xValue " " yValue " " colorValue
    
}

; ---------- 热键 ----------
; 读取启动模式
IniRead, startMode, %config_file%, 启动模式, 模式, 按住启动

Hotkey, %startkey%, start, On
Hotkey, %getkey%, findcolor, On

return

;启动
start:
    if (startMode = "触发启动")
    {
        ; 触发模式：按一次启动，再按一次停止
        if (running)
        {
            ; 停止循环
            SetTimer, startloop, Off
            tooltip
            running := false
        }
        else
        {
            ; 启动循环
            running := true
            SetTimer, startloop, 10
        }
    }
    else
    {
        ; 按住模式：按住时启动，松开时停止
        if (running)
        {
            return
        }
        
        running := true
        
        ; 启动循环，计时器模式
        SetTimer, startloop, 10
            
        ; 等待按键被释放
        KeyWait, %startkey%
        
        ; 按键已释放，停止循环
        SetTimer, startloop, Off
        tooltip
        running := false
    }
return

startloop:
    
    Loop, Parse, mainskill, `，   ; 注意这里是中文逗号
    {
        thisSkill := A_LoopField
        ;包含=号，多重判断
        if (InStr(thisSkill, "=") > 0)
        {
            
            color_ok:=0
            
            parts := StrSplit(thisSkill, "=")
            
            ;获取最后一个判断
            lastparts := parts[parts.MaxIndex()]
            
            maxparts := parts.MaxIndex()
            
            for index, part in parts {
                
                getcolorname:=part . "color"
                getcolor := %getcolorName%
                
                getxname:=part . "x"
                getx:=%getxname%
                
                getyname:=part . "y"
                gety:=%getyname%
                key1 := skill_set[part].key1
                wait1 := skill_set[part].wait1
                
                get_skill:=GetPixelColor(getx,gety)
                
                if (get_skill != getcolor )
                {
                    break
                }
                else
                {
                    color_ok++
                }
                
                if(color_ok>=maxparts )
                {
                    
                    ;按下，弹起
                    Send, {%key1% down}
                    sleep,wait1
                    Send, {%key1% up}
                    
                    ;单次触发
                    send,%key1%
                    ;延迟
                    sleep,wait1
                    
                }
                
            }
            
        }
        ;非多重判断
        else
        {
            getcolorname:=thisSkill . "color"
            getcolor := %getcolorName%
            
            getxname:=thisSkill . "x"
            getx:=%getxname%
            
            getyname:=thisSkill . "y"
            gety:=%getyname%
            
            key1 := skill_set[thisSkill].key1
            wait1 := skill_set[thisSkill].wait1
            
            getskill:=GetPixelColor(getx,gety)
            if(getskill==getcolor)
            {
                ;按下，弹起
                Send, {%key1% down}
                sleep,wait1
                Send, {%key1% up}
                
                ;单次触发
                send,%key1%
                ;延迟
                sleep,wait1
                
            }
            else
            {
                send,1
                sleep,10
            }
            
        }
        
    }
return

;取色 - 列表形式
findcolor:
    
    IfWinExist, getcolor
    {
        WinActivate, getcolor
    }
    {
        ; 重新读取当前配置
        IniRead,mainskill,%inifile%,主循环,循环顺序
        
        Gui, getcolor:New, -SysMenu +Resize , 技能列表
        
        ; 添加ListView显示所有技能
        Gui, getcolor: Add, ListView, x10 y10 w430 h180 +AltSubmit vSkillList gSkillListClick, 序号|技能名称|技能按键|技能延迟(ms)
        
        ; 解析mainskill并填充ListView
        skillIndex := 0
        Loop, Parse, mainskill, `，
        {
            thisSkill := A_LoopField
            if (thisSkill = "")
                continue
            
            skillIndex++
            
            ; 获取技能配置
            IniRead, skillData, %inifile%, 技能信息, %thisSkill%
            params := StrSplit(skillData, ",")
            skillKey := params[1]
            skillWait := params[2]
            
            ; 如果热键为ERROR，默认为空
            if (skillKey = "ERROR" or skillKey = "")
                skillKey := ""
            if (skillWait = "ERROR" or skillWait = "")
                skillWait := ""
            
            ; 添加到ListView
            LV_Add("", skillIndex, thisSkill, skillKey, skillWait)
        }
        
        ; 调整列宽
        LV_ModifyCol(1, 50)    ; 序号
        LV_ModifyCol(2, 150)   ; 技能名称
        LV_ModifyCol(3, 120)   ; 技能按键
        LV_ModifyCol(4, 100)   ; 技能延迟
        
        ; 添加编辑区域
        Gui, getcolor: Add, GroupBox, x10 y200 w430 h70, 编辑选中技能
        Gui, getcolor: Add, Text, x20 y220, 技能名称:
        Gui, getcolor: Add, Edit, x90 y217 w120 vEditName ReadOnly
        Gui, getcolor: Add, Text, x220 y220, 技能热键:
        Gui, getcolor: Add, Hotkey, x290 y217 w80 vEditHotkey
        Gui, getcolor: Add, Text, x20 y250, 延迟(ms):
        Gui, getcolor: Add, Edit, x90 y247 w80 vEditDelay
        
        ; 添加按钮
        Gui, getcolor: Add, Button, x10 y280 w80 gSaveSkill , 保存
        Gui, getcolor: Add, Button, x100 y280 w80 gPickColor , 取色
        Gui, getcolor: Add, Button, x190 y280 w80 gCloseGetColor , 取消
        
        Gui, getcolor: Show, w450 h310
    }
    
return

;ListView点击事件
SkillListClick:
    rowNum := A_EventInfo
    if (rowNum > 0)
    {
        ; 获取选中行的数据
        LV_GetText(selName, rowNum, 2)
        LV_GetText(selKey, rowNum, 3)
        LV_GetText(selWait, rowNum, 4)
        
        ; 填充到编辑框
        GuiControl, getcolor:, EditName, %selName%
        GuiControl, getcolor:, EditHotkey, %selKey%
        GuiControl, getcolor:, EditDelay, %selWait%
    }
return

;保存技能配置
SaveSkill:
    gui, getcolor:Submit, NoHide
    
    ; 获取当前选中的行
    rowNum := LV_GetNext(0)
    if (rowNum = 0)
    {
        MsgBox, 请先选择一个技能
        return
    }
    
    ; 获取选中行的技能名称
    LV_GetText(saveName, rowNum, 2)
    
    ; 组合新配置
    newConfig := EditHotkey . "," . EditDelay
    
    ; 写入INI
    IniWrite, %newConfig%, %inifile%, 技能信息, %saveName%
    
    ; 更新ListView显示
    LV_Modify(rowNum, "", rowNum, saveName, EditHotkey, EditDelay)
 
return

;取色功能
PickColor:
    gui, getcolor:Submit, NoHide
    
    ; 获取当前选中的行
    rowNum := LV_GetNext(0)
    if (rowNum = 0)
    {
        MsgBox, 请先选择一个技能
        return
    }
    
    ; 获取选中行的技能名称
    LV_GetText(pickName, rowNum, 2)
    
    gui, getcolor:Hide
    sleep 300
    
    EnterFreezeMode(pickName)
return

;关闭取色窗口
CloseGetColor:
    Gui, getcolor: Hide
return

F10::
    IfWinExist, config
    {
        WinActivate, config
    }
    {
        Gui, config:New, -SysMenu +Resize , 设置
        
        ; 添加热键设置按钮
        Gui, config: Add, Button, x10 y10 w120 h30 gOpenHotkeySettings , 热键设置
        
        ; 启动模式选择
        Gui, config: Add, Text, x10 y50, 启动模式:
        Gui, config: Add, DropDownList, x10 y70 w120 vstartMode gSaveStartMode, 按住启动||触发启动
        
        Gui,config:   Add, GroupBox, x10 y100 w120 h80, 职业列表
        Gui, config:Add, ComboBox, x15 y120 w110 vbdList gLoadIni
        
        Gui, config: Add, Button, x25 y150 w40 gnew , 新建
        
        Gui,config:   Add, Button, x75 y150 w40 geditskill , 修改
        
        Gui, config: Add, Button, x25 y195 w40 gsave , 保存
        
        Gui,config:   Add, Button, x75 y195 w40 gclose, 取消
        
        ; 读取启动模式设置
        IniRead, savedStartMode, %config_file%, 启动模式, 模式, 按住启动
        GuiControl, Choose, startMode, %savedStartMode%
        
        GuiControl, Choose, bdList, %option%
        
        Gui, config: Show,  w140 h240
        
        Gosub, Scan
        
        GuiControl, Choose, bdList, %option%
    }
    
return

;打开热键设置窗口
OpenHotkeySettings:
    Gui, hotkey:New, -SysMenu +Resize , 热键设置
    
    Gui, hotkey: Add, GroupBox, x10 y10 w180 h55, 启动热键
    Gui, hotkey: Add, Hotkey, x15 y35 w80 vstartkey , %startkey%
    Gui, hotkey: Add, Button, x105 y35 w60 gResetStartKey , 还原
    
    Gui, hotkey: Add, GroupBox, x10 y75 w180 h55, 取色热键
    Gui, hotkey: Add, Hotkey, x15 y100 w80 vgetkey , %getkey%
    Gui, hotkey: Add, Button, x105 y100 w60 gResetGetKey , 还原
    
    Gui, hotkey: Add, Button, x15 y140 w60 gSaveHotkey , 保存
    Gui, hotkey: Add, Button, x85 y140 w60 gCloseHotkey , 取消
    
    Gui, hotkey: Show, w200 h180
return

;还原启动热键为默认值
ResetStartKey:
    GuiControl, hotkey:, startkey, Capslock
return

;还原取色热键为默认值
ResetGetKey:
    GuiControl, hotkey:, getkey, F9
return

;保存热键设置
SaveHotkey:
    gui, hotkey:Submit
    
    ; 更新显示
    GuiControl, config:, startkeyDisplay, %startkey%
    GuiControl, config:, getkeyDisplay, %getkey%
    
    ; 隐藏Hotkey控件，显示文本
    GuiControl, config: Hide, startkey
    GuiControl, config: Show, startkeyDisplay
    GuiControl, config: Hide, getkey
    GuiControl, config: Show, getkeyDisplay
return

;关闭热键设置窗口
CloseHotkey:
    Gui, hotkey: Hide
return

;保存启动模式
SaveStartMode:
    gui, config:Submit, NoHide
    IniWrite, %startMode%, %config_file%, 启动模式, 模式
return

new:
    global fullPath ,FileList
    
    FileList := ""  ; 初始化文件列表变量
    InputBox, FileName, 输入职业名称, 请输入要创建的职业名称:, , 200, 100  ;
    
    if ErrorLevel ; 检查用户是否取消输入框
    {
        
        return
    }
    
    if FileName = ; 检查用户是否输入了文件名
    {
        MsgBox, 名称不能为空白。
        return
    }
    
    FilePath := ScriptDir . "\start_config\" . FileName . ".ini"
    FileEncoding, UTF-16
    if FileExist(FilePath) ; 检查文件是否已存在
    {
        MsgBox, 该循环 `n%FilePath% `n已经存在。
        return
    }
    
    FileAppend,, %FilePath% ; 创建一个空的 ini 文件
    if ErrorLevel
    {
        MsgBox, 创建失败！
    }
    else
    {
        
        skill_rel:="技能1，技能2，技能4，技能4，技能5，用中文的逗号隔开"
        IniWrite,%skill_rel%,%FilePath%,主循环,循环顺序
        
        IniWrite,% "",%FilePath%,技能信息,% ""
        
        MsgBox, 循环 `n%FilePath% `n已成功创建！
        
        Gosub, Scan
    }
    
return

; 加载INI文件点击事件
LoadIni:
    
    GuiControlGet, selectedIni, , bdList  ; 获取用户选择的ini文件
    if (selectedIni != "")
    {
        
        fullPath := NewFolder "\" selectedIni ".ini"  ; 拼接完整的ini文件路径
        
        IniWrite,%selectedIni%,%config_file%,当前职业,职业名称
        
    }
    else
    {
        MsgBox, 请先选择一个配置文件
    }
Return

;/获得下拉菜单的信息
Scan:
    GuiControl, , bdList, |  ; 先清空下拉菜单
    FileList := ""  ; 初始化文件列表变量
    
    Loop, Files, %NewFolder%\*.ini  ; 扫描文件夹下的所有ini文件
    {
        ; 获取当前文件名
        currentFileName := A_LoopFileName
        
        ; 检查文件名是否为config.ini，如果是，则跳过
        if (InStr(currentFileName, "config.ini") > 0)
            continue
        
        ; 去掉 .ini 扩展名并添加到列表
        StringTrimRight, fileNameWithoutExt, currentFileName, 4
        FileList .= fileNameWithoutExt "|"
    }
    
    ; 将扫描到的文件名填充到下拉列表中
    if (FileList != "")
    {
        GuiControl,, bdList, %FileList%
    }
    else
    {
        MsgBox, 未找到任何配置文件!
    }
Return

editskill:
    
    gui Submit,nohide
    inifile:=NewFolder . "\" bdlist . ".ini"
        IniRead,mainskill,%inifile%,主循环,循环顺序
        
    IfWinExist, editskill
    {
        WinActivate, editskill
    }
    {
        Gui, editskill:New, -SysMenu +Resize , 设置
        Gui,editskill: Add, Text, , 主循环
        Gui,editskill: Add, Edit, w430 h60 vmainskill, %mainskill%
        
        ; 帮助文本
        Gui, editskill: Add, Text, x10 y90 w430 h30, 手动输入技能名称，例如：技能1，技能2 用中文逗号隔开
        
        Gui, editskill: Add, Button, x120 y115 w80 geditclick , 确定
        
        Gui, editskill: Add, Button, x220 y115 w80 gclose, 取消
        
        Gui, editskill: Show,  w450 h150
    }
    
return

;确定
save:
    
    gui Submit
    savetype:="技能按键"
    
    IniWrite, %startkey%, %config_file%, %saveType%, startkey
    
    IniWrite, %getkey%, %config_file%, %saveType%, getkey
    
    reload
    
return

;取消
close:
    Gui,  hide
return

;确定
editclick:
    gui Submit
    inifile:=NewFolder . "\" option . ".ini"
        
    IniWrite, %mainskill%, %iniFile%, 主循环, 循环顺序
        
return

;取消
editclose:
    Gui, editskill: hide
return

; 进入冻结模式（全屏截图）
EnterFreezeMode(name)
{
    ; 抓取全屏截图
    pFreezeBitmap := Gdip_BitmapFromScreen(0)
    
    ; 创建全屏无边框窗口
    Gui, Freeze: New, +AlwaysOnTop -Caption +ToolWindow +LastFound +E0x20
    FreezeHwnd := WinExist()
    
    Gui, Freeze: Color, 000000          ; 纯黑背景
    
    Gui, Freeze: Show, x%MonLeft% y%MonTop% w%ScreenW% h%ScreenH%
    
    ; 把全屏截图画上去
    hDC := CreateCompatibleDC()
    obm := SelectObject(hDC, Gdip_CreateHBITMAPFromBitmap(pFreezeBitmap))
    hdcWin := GetDC(FreezeHwnd)
    BitBlt(hdcWin, 0, 0, ScreenW, ScreenH, hDC, 0, 0, 0x00CC0020)
    ReleaseDC(FreezeHwnd, hdcWin)
    SelectObject(hDC, obm)
    DeleteDC(hDC)
    
    ; 记录全屏起始坐标（MonLeft, MonTop）
    freezeX := MonLeft
    freezeY := MonTop
    
    loop {
        
        MouseGetPos,mx,my
        
        ; 计算相对于全屏的坐标
        winx:=mx-freezeX
        winy:=my-freezeY
        
        colors:=GetPixelColor(mx,my)
        
        tooltip % winx " " winy " " colors "`n Esc跳过"
        
        if GetKeyState("RButton", "P") {
            
            IniWrite, %winx%, %inifile%, 技能信息, %Name%x
                IniWrite, %winy%, %inifile%, 技能信息, %Name%y
                IniWrite, %colors%, %inifile%, 技能信息, %Name%color
                
            Gui, Freeze: Destroy
            tooltip 取色完成
            sleep 300
            break
        }
        
        if GetKeyState("ESC", "P") {
            
            ; 清理
            Gui, Freeze: Destroy
            Gdip_DisposeImage(pFreezeBitmap)
            pFreezeBitmap := ""
            tooltip
            sleep 300
            break
        }
        
        sleep 10
        
    }
    
    tooltip
    
}

; 退出脚本

ExitSub:
    If pFreezeBitmap
        Gdip_DisposeImage(pFreezeBitmap)
    Gdip_Shutdown(pToken)
    ExitApp
    
    GetPixelColor(x,y) ;自定义函数GetColor：即用于获取坐标（X，Y）色值
    {
        PixelGetColor, color, x, y, RGB
        StringRight color,color,8
        return color ;返回变量color
        
    }