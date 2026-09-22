include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    
    if LocalPlayer():GetPos():DistToSqr(self:GetPos()) < 40000 then
        local Ang = LocalPlayer():GetAngles()
        Ang:RotateAroundAxis(Ang:Forward(), 90)
        Ang:RotateAroundAxis(Ang:Right(), 90)
        
        cam.Start3D2D(self:GetPos() + Vector(0, 0, 8), Ang, 0.1)
            draw.SimpleText("БОДИКАМЕРА «ДОЗОР»", "DermaDefaultBold", 0, 0, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("[Нажмите E, чтобы надеть]", "DermaDefault", 0, 12, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
end
