if SERVER then
    util.AddNetworkString("Dozor_Cam_State")
    AddCSLuaFile("client/cl_dozor_hud.lua")
end

if CLIENT then
    concommand.Add("dozor_drop", function()
        net.Start("Dozor_Cam_Drop")
        net.SendToServer()
    end)
end
