include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

function ENT:Initialize()
    self:SetModel("models/maxofs2d/camera.mdl") 
    self:SetSolid(SOLID_VPHYSICS)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    
    if activator:GetNWBool("HasDozorCam", false) then
        activator:PrintMessage(HUD_PRINTTALK, "[Дозор] Вы уже носите одну нательную камеру!")
        return
    end
    
    activator:SetNWBool("HasDozorCam", true)
    
    net.Start("Dozor_Cam_State")
    net.WriteBool(true)
    net.Send(activator)
    
    activator:EmitSound("items/ammo_pickup.wav")
    activator:PrintMessage(HUD_PRINTTALK, "[Дозор] Вы закрепили нательную камеру на бронежилет. Чтобы снять её, введите в консоль: dozor_drop")
    
    self:Remove()
end
