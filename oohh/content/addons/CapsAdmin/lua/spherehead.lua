local ent = utilities.RemoveOldObject(Entity("BasicEntity"))
ent:SetModel("default/primitive_sphere.cgf")
ent:Spawn()
ent:SetScale(Vec3()+0.1)
ent:EnablePhysics(false)

function ent:OnUpdate()
	local pos, ang = bones.GetPosAng(me, "head")
	
	ent:SetPos(me:GetPos() + pos)
	ent:SetAngles(me:GetEyeAngles() + ang)
end


