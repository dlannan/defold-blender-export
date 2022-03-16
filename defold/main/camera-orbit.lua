
-- A camera controller so I can pan and move around the scene. 
-- Enable/Disable using keys
--------------------------------------------------------------------------------

-- Soft start and stop - all movements should be softened to make a nice movement
--   experience. Camera motion should also be dampened.

local move_dampen 	= 0.89
local look_dampen 	= 0.89

local cameraorbit = {}

--------------------------------------------------------------------------------

local function newcamera()

	local cameraorbit = {

		playerheight 	= 1.3, 
		cameraheight 	= 0.0,

		-- Where the look focus is in the distance
		lookdistance 	= 4.0,

		looklimityaw 	= math.pi * 0.5,
		looklimitpitch 	= math.pi * 0.5,

		lookvec 		= vmath.vector3(),
		pos				= vmath.vector3(),
		movevec 		= vmath.vector3(),

		xangle 			= 0.0,
		yangle			= 0.0,
	}
	return cameraorbit
end 

--------------------------------------------------------------------------------
-- A simple handler, can be easily replaced
local function defaulthandler( self, delta )

	local pitch		= -self.xangle
	local yaw		= self.yangle

	if (yaw > math.pi) then yaw = -math.pi; self.yangle = -math.pi end 
	if (yaw < -math.pi) then yaw = math.pi; self.yangle = math.pi end 
	if (pitch > math.pi * 0.5) then pitch = math.pi * 0.5; self.xangle = math.pi * 0.5 end 
	if (pitch < -math.pi * 0.5) then pitch = -math.pi * 0.5; self.xangle = -math.pi * 0.5 end 

	local camrot = vmath.quat_rotation_y( yaw )
	camrot = camrot * vmath.quat_rotation_x( pitch )

	local camrotinv = vmath.quat_rotation_y( yaw)
	camrotinv = camrotinv * vmath.quat_rotation_x( pitch)

	local campos 	 = vmath.matrix4_from_quat(camrot) * vmath.vector4(0, 0, self.distance, 0)
	local tpos 		 = (self.tPos or go.get_world_position(self.target) )

	self.pos = tpos + vmath.vector3(campos.x, campos.y, campos.z) + vmath.vector3(0, self.cameraheight, 0)
	self.rot = camrotinv

	go.set_rotation( self.rot, self.cameraobj )		
	go.set_position( self.pos, self.cameraobj )
end

--------------------------------------------------------------------------------

cameraorbit.init = function( cameraobj, target, distance, handler )

	local newcam = newcamera()
	newcam.cameraobj 	= cameraobj 
	newcam.target 		= target
	newcam.handler 		= handler or defaulthandler

	newcam.distance 	= distance
	newcam.smooth 		= 0.98
	newcam.speed 		= 1.0
	newcam.flat 		= true 		-- define if the camera rolls

	newcam.pos = go.get_position(cameraobj)
	newcam.rot = go.get_rotation(cameraobj)

	newcam.enabled = true 		-- enabled by default
	newcam.update = function( self, delta )

		if(newcam.enabled ~= true) then return end
		if(newcam.handler) then newcam.handler( newcam, delta ) end
	end

	return newcam
end 

--------------------------------------------------------------------------------

return cameraorbit

--------------------------------------------------------------------------------