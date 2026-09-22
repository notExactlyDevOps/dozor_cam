util.AddNetworkString("Dozor_Cam_Drop")

net.Receive("Dozor_Cam_Drop", function(len, ply)
    if not IsValid(ply) then return end
    
    if ply:GetNWBool("HasDozorCam", false) then
        ply:SetNWBool("HasDozorCam", false)
        
        net.Start("Dozor_Cam_State")
        net.WriteBool(false)
        net.Send(ply)
        
        local cam = ents.Create("ent_dozor_cam")
        if IsValid(cam) then
            local aim = ply:GetAimVector()
            cam:SetPos(ply:GetShootPos() + aim * 30)
            cam:SetAngles(ply:GetAngles())
            cam:Spawn()
            
            local phys = cam:GetPhysicsObject()
            if IsValid(phys) then
                phys:SetVelocity(aim * 150)
            end
        end
        ply:PrintMessage(HUD_PRINTTALK, "[Дозор] Вы сняли и выбросили нательную камеру.")
    else
        ply:PrintMessage(HUD_PRINTTALK, "[Дозор] На вас нет нательной камеры.")
    end
end)
