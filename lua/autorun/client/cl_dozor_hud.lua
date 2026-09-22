local LOGO_CONFIG = {
    TextScale       = 0.55,  
    TextOffsetY     = -20,   
    PupilScale      = 0.15,  
    PupilOffsetY    = 0,     
    EyeOffsetY      = 5,     
    FrontRadius     = 17,    
    FrontThickness  = 4,     
    FrontOpening    = 4,     
    BackRadius      = 16,    
    BackThickness   = 4,     
    BackOpening     = 2,     
}

local cv_enabled    = CreateClientConVar("dozor_hud_enabled", "0", true, false) 
local cv_recording  = CreateClientConVar("dozor_hud_recording", "1", true, false) 
local cv_draw_bg    = CreateClientConVar("dozor_hud_draw_bg", "1", true, false)
local cv_scale      = CreateClientConVar("dozor_hud_scale", "1.0", true, false)
local cv_color_r    = CreateClientConVar("dozor_hud_color_r", "255", true, false)
local cv_color_g    = CreateClientConVar("dozor_hud_color_g", "255", true, false)
local cv_color_b    = CreateClientConVar("dozor_hud_color_b", "255", true, false)

local cv_rank       = CreateClientConVar("dozor_hud_rank", "Офицер", true, false)
local cv_name       = CreateClientConVar("dozor_hud_name", "Сотрудник", true, false)
local cv_device     = CreateClientConVar("dozor_hud_device", "ДОЗОР-77 [№0842]", true, false)

local DozorSessionStartTime = DozorSessionStartTime or CurTime()
local DozorRecordedTimeBeforePause = 0 

local function UpdateDozorFonts()
    local scale = cv_scale:GetFloat() or 1.0
    local target_font = "Trebuchet MS" 

    surface.CreateFont("Dozor_Main", {
        font = target_font,
        size = math.max(12, math.Round(ScreenScale(6.5) * scale)),
        weight = 900,
        antialias = true,
        shadow = true,
    })
    surface.CreateFont("Dozor_Rec", {
        font = target_font,
        size = math.max(10, math.Round(ScreenScale(5.5) * scale)),
        weight = 900,
        antialias = true,
        shadow = true,
    })
    surface.CreateFont("Dozor_LogoText", {
        font = "Courier New",
        size = math.max(6, math.Round((45 * LOGO_CONFIG.TextScale) * scale)),
        weight = 900,
        antialias = true,
    })
end

hook.Add("InitPostEntity", "Dozor_Fonts_Init", UpdateDozorFonts)
UpdateDozorFonts()
cvars.AddChangeCallback("dozor_hud_scale", function() UpdateDozorFonts() end, "DozorScaleUpdate")

local function DrawAbsoluteCircle(cx, cy, radius, r, g, b)
    surface.SetDrawColor(r, g, b, 255)
    for i = -radius, radius do
        local line_w = math.Round(math.sqrt(radius * radius - i * i))
        surface.DrawLine(cx - line_w, cy + i, cx + line_w + 1, cy + i)
    end
end

local function DrawEyeArc(cx, cy, radius, start_ang, end_ang, thickness)
    local segments = 32
    local last_x, last_y
    for i = 0, segments do
        local ang = math.rad(start_ang + (end_ang - start_ang) * (i / segments))
        local px = cx + math.cos(ang) * radius
        local py = cy + math.sin(ang) * radius
        if last_x and last_y then
            for t = -math.floor(thickness/2), math.ceil(thickness/2) do
                surface.DrawLine(last_x, last_y + t, px, py + t)
            end
        end
        last_x, last_y = px, py
    end
end

local function DrawDozorLogo(x, y, size)
    local r, g, b = cv_color_r:GetInt(), cv_color_g:GetInt(), cv_color_b:GetInt()
    local scale = cv_scale:GetFloat() or 1.0
    local center_x = x + size / 2
    local center_y = y + size / 2 + (LOGO_CONFIG.EyeOffsetY * scale)
    local bg_r, bg_g, bg_b = math.Round(r * 0.35), math.Round(g * 0.35), math.Round(b * 0.35)

    draw.SimpleText("DOZOR", "Dozor_LogoText", center_x, y + (LOGO_CONFIG.TextOffsetY * scale), Color(r, g, b, 240), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    draw.NoTexture()

    surface.SetDrawColor(bg_r, bg_g, bg_b, 255)
    local b_rad = LOGO_CONFIG.BackRadius * scale
    local b_thick = math.max(1, math.Round(LOGO_CONFIG.BackThickness * scale))
    local b_open = LOGO_CONFIG.BackOpening * scale
    DrawEyeArc(center_x, center_y - b_open, b_rad, 200, 340, b_thick)
    DrawEyeArc(center_x, center_y + b_open, b_rad, 20, 160, b_thick)

    local p_radius = math.max(2, math.Round(size * LOGO_CONFIG.PupilScale))
    DrawAbsoluteCircle(center_x, center_y + (LOGO_CONFIG.PupilOffsetY * scale), p_radius, r, g, b)

    surface.SetDrawColor(r, g, b, 255)
    local f_rad = LOGO_CONFIG.FrontRadius * scale
    local f_thick = math.max(1, math.Round(LOGO_CONFIG.FrontThickness * scale))
    local f_open = LOGO_CONFIG.FrontOpening * scale
    DrawEyeArc(center_x, center_y - f_open, f_rad, 200, 340, f_thick)
    DrawEyeArc(center_x, center_y + f_open, f_rad, 20, 160, f_thick)
end

hook.Add("HUDPaint", "DrawDozorHUD_V4", function()
    if not cv_enabled:GetBool() then return end
    if not IsValid(LocalPlayer()) then return end

    local ply = LocalPlayer()
    local custom_color = Color(cv_color_r:GetInt(), cv_color_g:GetInt(), cv_color_b:GetInt(), 255)
    local text_line1 = string.upper(cv_device:GetString())
    
    local rp_name = ply.getDarkRPVar and ply:getDarkRPVar("rpname") or ply:Nick()
    local text_line2 = string.upper(cv_rank:GetString() .. " | " .. rp_name)
    
    local date_time  = os.date("%d/%m/%Y | %H:%M:%S")
    local rec_text   = "ЗАПИСЬ"

    local session_time = DozorRecordedTimeBeforePause
    if cv_recording:GetBool() then
        session_time = math.floor(CurTime() - DozorSessionStartTime)
    end
    
    local s_hours   = string.format("%02d", math.floor(session_time / 3600))
    local s_minutes = string.format("%02d", math.floor((session_time % 3600) / 60))
    local s_seconds = string.format("%02d", math.floor(session_time % 60))
    local session_text = "С НАЧАЛА: " .. s_hours .. ":" .. s_minutes .. ":" .. s_seconds

    local scale = cv_scale:GetFloat() or 1.0
    local scrW, scrH = ScrW(), ScrH()
    local pad_x, pad_y = scrW * 0.03, scrH * 0.03

    surface.SetFont("Dozor_Main")
    local tw1, th1 = surface.GetTextSize(text_line2)
    local tw2, th2 = surface.GetTextSize(date_time)
    local tw3, th3 = surface.GetTextSize(text_line1)
    
    surface.SetFont("Dozor_Rec")
    local r_tw, r_th = surface.GetTextSize(rec_text)
    local s_tw, s_th = surface.GetTextSize(session_text)

    local max_text_w = math.max(tw1, tw2, tw3, (r_tw + s_tw + 30))
    local logo_size  = math.Round(42 * scale)
    local gap        = math.Round(16 * scale)
    local box_w      = max_text_w + logo_size + (gap * 3) + math.Round(35 * scale)
    local box_h      = (th1 * 3) + r_th + math.Round(32 * scale)
    local box_x, box_y = scrW - box_w - pad_x, pad_y

    if cv_draw_bg:GetBool() then
        draw.RoundedBox(math.Round(2 * scale), box_x, box_y, box_w, box_h, Color(15, 15, 15, 180))
    end

    local rec_x, rec_y = box_x + gap, box_y + math.Round(12 * scale)
    
    if cv_recording:GetBool() then
        if math.floor(CurTime()) % 2 == 0 then
            draw.RoundedBox(6, rec_x, rec_y + (r_th / 2) - 4, 8, 8, Color(230, 0, 0, 255))
        end
        draw.SimpleText(rec_text, "Dozor_Rec", rec_x + 14, rec_y, Color(230, 230, 230), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    else
        draw.SimpleText("[ПАУЗА]", "Dozor_Rec", rec_x, rec_y, Color(150, 150, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    
    draw.SimpleText(session_text, "Dozor_Rec", rec_x + r_tw + math.Round(30 * scale), rec_y, Color(200, 200, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    local text_x, text_y = box_x + gap, rec_y + r_th + math.Round(10 * scale)
    draw.SimpleText(text_line1, "Dozor_Main", text_x, text_y, custom_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(text_line2, "Dozor_Main", text_x, text_y + th1 + 4, custom_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(date_time, "Dozor_Main", text_x, text_y + (th1 * 2) + 8, Color(255, 180, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    local logo_x = box_x + box_w - logo_size - math.Round(15 * scale)
    local logo_y = box_y + (box_h / 2) - (logo_size / 2) + math.Round(4 * scale)
    DrawDozorLogo(logo_x, logo_y, logo_size)
end)

net.Receive("Dozor_Cam_State", function()
    local state = net.ReadBool()
    RunConsoleCommand("dozor_hud_enabled", state and "1" or "0")
    if state then
        DozorSessionStartTime = CurTime()
        DozorRecordedTimeBeforePause = 0
        RunConsoleCommand("dozor_hud_recording", "1")
    end
end)

concommand.Add("dozor_style_menu", function()
    if IsValid(DozorMenu) then DozorMenu:Remove() end

    DozorMenu = vgui.Create("DFrame")
    DozorMenu:SetSize(380, 440)
    DozorMenu:SetTitle("Управление Нательной Камерой «Дозор»")
    DozorMenu:Center()
    DozorMenu:MakePopup()
    DozorMenu.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(25, 25, 25, 245))
        draw.RoundedBoxEx(8, 0, 0, w, 24, Color(40, 40, 40, 255), true, true, false, false)
    end

    local scroll = vgui.Create("DScrollPanel", DozorMenu)
    scroll:Dock(FILL)
    scroll:DockMargin(8, 5, 8, 5)

    local function CreateInputLabel(text)
        local lbl = scroll:Add("DLabel")
        lbl:Dock(TOP)
        lbl:DockMargin(0, 8, 0, 2)
        lbl:SetText(text)
        lbl:SetTextColor(Color(135, 206, 250))
        lbl:SetFont("DermaDefaultBold")
    end

    CreateInputLabel("Модель и номер устройства:")
    local ent_device = scroll:Add("DTextEntry")
    ent_device:Dock(TOP)
    ent_device:SetConVar("dozor_hud_device")

    CreateInputLabel("Звание сотрудника (для вывода на HUD):")
    local ent_rank = scroll:Add("DTextEntry")
    ent_rank:Dock(TOP)
    ent_rank:SetConVar("dozor_hud_rank")

    local btn_panel = scroll:Add("DPanel")
    btn_panel:Dock(TOP)
    btn_panel:DockMargin(0, 15, 0, 5)
    btn_panel:SetHeight(32)
    btn_panel.Paint = function() end

    local btn_rec = btn_panel:Add("DButton")
    btn_rec:Dock(LEFT)
    btn_rec:SetWidth(240)
    
    local is_rec = cv_recording:GetBool()
    btn_rec:SetText(is_rec and "Остановить запись" or "Начать запись")
    btn_rec:SetTextColor(Color(255, 255, 255))
    btn_rec.Paint = function(self, w, h)
        local active_rec = cv_recording:GetBool()
        local col = active_rec and Color(180, 40, 40) or Color(40, 150, 40)
        if self:IsHovered() then col = active_rec and Color(220, 50, 50) or Color(50, 180, 50) end
        draw.RoundedBox(4, 0, 0, w, h, col)
    end
    btn_rec.DoClick = function()
        local active_rec = cv_recording:GetBool()
        if active_rec then
            DozorRecordedTimeBeforePause = math.floor(CurTime() - DozorSessionStartTime)
            RunConsoleCommand("dozor_hud_recording", "0")
            btn_rec:SetText("Начать запись")
        else
            DozorSessionStartTime = CurTime() - DozorRecordedTimeBeforePause
            RunConsoleCommand("dozor_hud_recording", "1")
            btn_rec:SetText("Остановить запись")
        end
        surface.PlaySound("axon_speed.wav")
    end

    local btn_reset = btn_panel:Add("DButton")
    btn_reset:Dock(RIGHT)
    btn_reset:SetWidth(110)
    btn_reset:SetText("Сброс")
    btn_reset:SetTextColor(Color(255, 255, 255))
    btn_reset.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and Color(30, 144, 255) or Color(70, 130, 180))
    end
    btn_reset.DoClick = function()
        DozorSessionStartTime = CurTime()
        DozorRecordedTimeBeforePause = 0
        surface.PlaySound("common/bugedit.wav")
    end

    local line = scroll:Add("DPanel")
    line:Dock(TOP)
    line:DockMargin(0, 10, 0, 10)
    line:SetHeight(1)
    line.Paint = function(self, w, h) surface.SetDrawColor(60, 60, 60) surface.DrawRect(0, 0, w, h) end

    local check_bg = scroll:Add("DCheckBoxLabel")
    check_bg:Dock(TOP)
    check_bg:DockMargin(0, 5, 0, 10)
    check_bg:SetText("Отрисовывать темную подложку (задний фон)")
    check_bg:SetConVar("dozor_hud_draw_bg")
    check_bg:SetTextColor(Color(255, 255, 255))

    local slider_scale = scroll:Add("DNumSlider")
    slider_scale:Dock(TOP)
    slider_scale:DockMargin(0, 5, 0, 10)
    slider_scale:SetText("Масштаб HUD (Безопасный)")
    slider_scale:SetMin(0.8)
    slider_scale:SetMax(2.0)
    slider_scale:SetDecimals(2)
    slider_scale:SetConVar("dozor_hud_scale")
    slider_scale.Label:SetTextColor(Color(255, 255, 255))

    local color_label = scroll:Add("DLabel")
    color_label:Dock(TOP)
    color_label:SetText("Цвет элементов текста и логотипа:")
    color_label:SetTextColor(Color(255, 255, 255))
    color_label:SetFont("DermaDefaultBold")

    local colors = { 
        {"Красный (R)", "dozor_hud_color_r"}, 
        {"Зеленый (G)", "dozor_hud_color_g"}, 
        {"Синий (B)", "dozor_hud_color_b"} 
    }
    for _, colData in ipairs(colors) do
        local slider_col = scroll:Add("DNumSlider")
        slider_col:Dock(TOP)
        slider_col:DockMargin(0, 2, 0, 2)
        slider_col:SetText(colData[1]) 
        slider_col:SetMin(0)
        slider_col:SetMax(255)
        slider_col:SetDecimals(0)
        slider_col:SetConVar(colData[2]) 
        slider_col.Label:SetTextColor(Color(200, 200, 200))
    end
end)
