local Config = {}

Config.Train = {
	MaxSpeed = 90,          -- stud/sn
	AccelTime = 2.4,        -- hizlanma suresi (buyuk = agir kalkis)
	CoastTime = 1.6,        -- gaz birakinca yavaslama suresi
	BrakeTime = 0.7,        -- acil fren (Space)
	ReverseFraction = 0.35, -- geri viteste max hizin orani
	DismountSpeed = 2,      -- bu hizin altinda Space koltuktan indirir
	StartFuel = 45,
	FuelCapacity = 100,
	IdleDrain = 0.03,       -- dururken %/sn yakit
	MovingDrain = 3.4,      -- tam hizda eklenen %/sn yakit
	MetersPerStud = 0.28,   -- mesafe gostergesi icin
}


Config.FuelItems = {
	Coal = 25,
	Fuel = 15,
}

Config.Shovel = {
	Damage = 25,
	Cooldown = 0.9,     
	RagdollTime = 1.6,  
	Knockback = 22,
	KnockUp = 10,
}

Config.Zombie = {
	Damage = 30, 
}

Config.Items = {
	DropDistance = 2.8,   
	ThrowSpeed = 6,
	PickupCooldown = 0.7, 
}

Config.Rails = {
	SpawnAhead = 500,    
	CleanupBehind = 800,
}

Config.Dashboard = {
	SpeedGaugeMax = 125, 
	NeedleMin = 120,     
	NeedleMax = 420,     
	NeedleLerp = 8,
	DistanceRefresh = 0.25,
}

return Config
