--[[

Created by Fanbumbot
01.08.2022

]]

require 'moonloader'
local sampev = require 'lib.samp.events'

local last_x, last_y, last_z
local target_car, local_car, thief_car

function IsNaN(float)
	return float ~= float
end

function IsNaNvector(vector)
	return IsNaN(vector.x) or IsNaN(vector.y) or IsNaN(vector.z)
end

function IsNaNquaternion(quaternion)
	return IsNaN(quaternion[1]) or IsNaN(quaternion[2]) or IsNaN(quaternion[3]) or IsNaN(quaternion[4]) or
	quaternion[1] < -1.0 or quaternion[1] > 1.0 or quaternion[2] < -1.0 or quaternion[2] > 1.0 or
	quaternion[3] < -1.0 or quaternion[3] > 1.0 or quaternion[4] < -1.0 or quaternion[4] > 1.0
end

function IsValidWeapon(weaponid)
	if weaponid < 0 or (weaponid >= 19 and weaponid <= 21) or weaponid > 46 then
		return false
	end
	return true
end

function IsWeaponMustFire(weaponid)
	if weaponid < 22 or (weaponid > 34 and weaponid ~= 38) then
		return false
	end
	return true
end	

function IsValidSpecialAction(actionid)
	if actionid < 0 or actionid == 9 or (actionid >= 14 and actionid <= 19) or (actionid > 25 and actionid ~= 68) then
		return false
	end
	return true
end

function IsValidVehicle(vehicleid)
	if vehicleid == nil or (vehicleid > 2000 or vehicleid <= 0) then
		return false
	end
	return true
end

function IsValidPlayer(playerid)
	return true
end

function sampev.onSendPlayerSync(data)
	local_car = 0
	
	--AntiVCrash | AntiLoading
	if IsNaNvector(data.position) then
		setCharCoordinates(PLAYER_PED, last_x, last_y, last_z)
	else
		last_x = data.position.x
		last_y = data.position.y
		last_z = data.position.z
		
		data.surfingVehicleId = 0
		data.surfingOffsets.x = 0.0
		data.surfingOffsets.y = 0.0
		data.surfingOffsets.z = 0.0
	end
	
	if IsNaNquaternion(data.quaternion) then
		setCharQuaternion(PLAYER_PED, 0.0, 0.0, 0.99996, 0.0086)
		restoreCameraJumpcut()
		
		data.surfingVehicleId = 0
		data.surfingOffsets.x = 0.0
		data.surfingOffsets.y = 0.0
		data.surfingOffsets.z = 0.0
	end
end

function sampev.onSendVehicleSync(data)
	local_car = data.vehicleId
end

function sampev.onSendEnterVehicle(vehicleId, passenger)
	target_car = vehicleId
end

function sampev.onPlayerSync(id, data)
	if IsNaNvector(data.position) or
	IsNaNquaternion(data.quaternion) or
	IsNaNvector(data.moveSpeed) or
	(data.surfingVehicleId ~= nil and (not IsValidVehicle(data.surfingVehicleId)
	or IsNaNvector(data.surfingOffsets))) or
	not IsValidWeapon(data.weapon) or
	not IsValidSpecialAction(data.specialAction)
	then
		return false
	end
end

function sampev.onVehicleSync(id, veh, data)
	if not IsValidVehicle(veh) or
	IsNaNquaternion(data.quaternion) or
	IsNaNvector(data.position) or IsNaNvector(data.moveSpeed) or
	IsNaN(data.vehicleHealth) or
	(data.trailerId ~= nil and not IsValidVehicle(data.trailerId)) or
	not IsValidWeapon(data.currentWeapon) or IsNaN(data.bikeLean) or IsNaN(data.trainSpeed)
	then
		return false
	end
	local result, id
	result, id = sampGetVehicleIdByCarHandle(storeCarCharIsInNoSave(PLAYER_PED))
	if id == veh then
		thief_car = veh
	end
end

function sampev.onPassengerSync(id, data)
	if not IsValidVehicle(data.vehicleId) or not IsValidWeapon(data.currentWeapon) or IsNaNvector(data.position) or
	data.seatId == 0
	then
		return false
	end
end

function sampev.onUnoccupiedSync(id, data)
	if not IsValidVehicle(data.vehicleId) or IsNaNvector(data.roll) or IsNaNvector(data.direction) or
	IsNaNvector(data.position) or IsNaNvector(data.moveSpeed) or IsNaNvector(data.turnSpeed) or
	IsNaN(data.vehicleHealth) or
	data.roll.x > 10.0 or data.roll.y > 10.0 or data.roll.z > 10.0 or
	data.roll.x < -10.0 or data.roll.y < -10.0 or data.roll.z < -10.0
	then
		return false
	end
end

function sampev.onTrailerSync(id, data)
	if not IsValidVehicle(data.trailerId) or IsNaNvector(data.position) or
	IsNaNquaternion(data.quaternion) or
	IsNaNvector(data.moveSpeed) or IsNaNvector(data.turnSpeed) then
		return false
	end
end

function sampev.onAimSync(id, data)
	if IsNaNvector(data.camFront) or IsNaNvector(data.camPos) or
	IsNaN(aimZ) then
		return false
	end
end

function sampev.onBulletSync(id, data)
	if (data.targetType == 1 and not IsValidPlayer(data.targetId)) or
	(data.targetType == 2 and not IsValidVehicle(data.targetId)) or
	(data.targetType == 0 and data.targetId ~= 65535) or
	IsNaNvector(data.origin) or IsNaNvector(data.target) or
	IsNaNvector(data.center) or not IsValidWeapon(data.weaponId) or
	not IsWeaponMustFire(data.weaponId)
	then
		return false
	end
	local result, id
	local ped
	local_car, ped = storeClosestEntities(PLAYER_PED)
	result, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
	if data.targetType == 1 and data.targetId == id and local_car == thief_car and thief_car == target_car then
		return false
	end
end




