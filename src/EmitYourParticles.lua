--!strict
-- You can chain stuff with this btw
-- For a better UX (user experience), only use methods to modify values.
-- Please try not to manually edit something yourself (something might break or it will run slower)
-- EX: use ``ParticleEmitter:SetSpeed(x)`` instead of ``ParticleEmitter.Speed = x``

local runSv = game:GetService('RunService')

local signalModule = require(script.Signal) -- Feel free to change to whatever signal module you have

local emitYourParticleModule = {}

-- I wanted to shorten the index chain for cleaner code
local emitterMethods, particleMethods = {}, {}
emitYourParticleModule.EmitterMethods = emitterMethods
emitYourParticleModule.ParticleMethods = particleMethods

local emitterMetatable = { __index = emitYourParticleModule.EmitterMethods }
local particleMetatable = { __index = emitYourParticleModule.ParticleMethods }

export type ParticleEmitter2D = typeof(setmetatable({} :: {
	
	GuiObject: GuiObject;
	TemplateParticle: GuiObject?;
	Particles: { Particle2D };
	PropertyTransitions: { PropertyTransition };
	
	AllPropertiesSet: boolean;
	DoUpdateSize: boolean;
	
	ParticleCreated: signalModule.Signal<Particle2D>;
	ParticleUpdated: signalModule.Signal<Particle2D, number, number>;
	
	Rate: number;				-- Objects spawned per second
	RateTick: number;			
	
	Speed: NumberRange;			-- Pixels per second
	RotationSpeed: NumberRange; -- Rotations (in degrees) per second
	Rotation: NumberRange;		-- Degrees
	Lifetime: NumberRange; 		-- Seconds
	SpreadAngle: NumberRange; 	-- From 0 degrees to 360 degrees
	
	Acceleration: Vector2;		-- How much (or by what vector) a particle will speed up or slows down over time
	Drag: number;				-- Speed at which the object slows down (the drag coefficient)
	
	EmitShape: 'area' | 'point';
	
	-- These progress, like a normal particle emitter
	Scale: NumberSequence;							-- 1 will be normal size of frame, 0 will be equivalent UDim2.new()
	BackgroundTransparency: NumberSequence;			-- Self Explanatory
	BackgroundColor: (ColorSequence | typeof(-1));	-- Self Explanatory, set to -1 to disable this
	
	PreRenderConnection: RBXScriptConnection;
	
}, emitterMetatable))

export type Particle2D = typeof(setmetatable({} :: {
	
	EmittedBy: ParticleEmitter2D;
	GuiObject: GuiObject;
	
	Origin: UDim2;
	InitialSize: UDim2;
	
	Position: Vector2;
	VelocityDirection: Vector2;
	Velocity: Vector2;
	
	DeterminedLifetime: number;
	DeterminedRotationSpeed: number;
	
	CurrentAge: number; -- in seconds
	
}, particleMetatable))

export type PropertyTransition = {
	
	Name: string;
	SequenceFixed: boolean;
	IsColorSequence: boolean;
	IsNumberSequence: boolean;
	Value: ColorSequence | NumberSequence;
	
}

-- Constants

local default_emitter_values = {

	Particles = {};
	PropertyTransitions = {};

	Rate = 5;
	RateTick = 0;
	
	DoUpdateBackgroundColor = false;
	DoUpdateSize = false;
	DoUpdateTransparency = false;

	Speed = NumberRange.new(30, 70);
	RotationSpeed = NumberRange.new(0);
	Rotation = NumberRange.new(0);
	Lifetime = NumberRange.new(5, 10); 	
	SpreadAngle = NumberRange.new(0); 

	Acceleration = Vector2.new();
	Drag = 0;				

	Scale = NumberSequence.new(1, 1);					

	EmitShape = 'point';
}

local not_correct_type_err = `Recieved invalid type when executing "%a1." Value: %a2`
local range_not_number_err = `Recieved an invalid type for a range. Min: %a1. Max: %a2.`
local not_number_err = `Recieved an argument that was not a number! Argument: %a1`

-- Local Functions

local function formatString(ERROR_STRING: string, ...)
	local args = {...}
	local errString = ERROR_STRING
	
	for index, arg in args do
		errString = string.gsub(errString, `%a{tostring(index)}`, tostring(arg))
	end
	
	return errString
end

local random = Random.new()
local function getRandomNonInt(MIN: number, MAX: number)
	return (random:NextNumber() * (MAX - MIN)) + MIN
end

local function getNumFromNumRange(NUMBER_RANGE: NumberRange)
	if NUMBER_RANGE.Min == NUMBER_RANGE.Max then
		return NUMBER_RANGE.Min
	end
	
	return getRandomNonInt(NUMBER_RANGE.Min, NUMBER_RANGE.Max)
end

-- Thank you roblox for this (https://create.roblox.com/docs/reference/engine/datatypes/NumberSequence)
local function evalNumberSequence(SEQUENCE: NumberSequence, TIME: number): number
	if TIME == 0 then
		return SEQUENCE.Keypoints[1].Value
	elseif TIME == 1 then
		return SEQUENCE.Keypoints[#SEQUENCE.Keypoints].Value
	end

	for i = 1, #SEQUENCE.Keypoints - 1 do
		local currentKeypoint = SEQUENCE.Keypoints[i]
		local nextKeypoint = SEQUENCE.Keypoints[i + 1]
		if TIME >= currentKeypoint.Time and TIME < nextKeypoint.Time then
			local alpha = (TIME - currentKeypoint.Time) / (nextKeypoint.Time - currentKeypoint.Time)
			return currentKeypoint.Value + (nextKeypoint.Value - currentKeypoint.Value) * alpha
		end
	end
	
	return 0
end

-- Thank you roblox again for this (https://create.roblox.com/docs/reference/engine/datatypes/NumberSequence)
local function evalColorSequence(SEQUENCE: ColorSequence, TIME: number): Color3
	if TIME == 0 then
		return SEQUENCE.Keypoints[1].Value
	elseif TIME == 1 then
		return SEQUENCE.Keypoints[#SEQUENCE.Keypoints].Value
	end

	-- Otherwise, step through each sequential pair of keypoints
	for i = 1, #SEQUENCE.Keypoints - 1 do
		local thisKeypoint = SEQUENCE.Keypoints[i]
		local nextKeypoint = SEQUENCE.Keypoints[i + 1]
		if TIME >= thisKeypoint.Time and TIME < nextKeypoint.Time then
			-- Calculate how far alpha lies between the points
			local alpha = (TIME - thisKeypoint.Time) / (nextKeypoint.Time - thisKeypoint.Time)
			-- Evaluate the real value between the points using alpha
			return Color3.new(
				(nextKeypoint.Value.R - thisKeypoint.Value.R) * alpha + thisKeypoint.Value.R,
				(nextKeypoint.Value.G - thisKeypoint.Value.G) * alpha + thisKeypoint.Value.G,
				(nextKeypoint.Value.B - thisKeypoint.Value.B) * alpha + thisKeypoint.Value.B
			)
		end
	end
	
	return Color3.new()
end

local function isSequenceFixed(SEQUENCE: NumberSequence | ColorSequence): boolean
	local lastKeypointValue
	
	for i, keypoint in SEQUENCE.Keypoints :: any do		
		if keypoint.Value ~= lastKeypointValue and i ~= 1 then
			return false
		end
		lastKeypointValue = keypoint.Value
	end
	
	return true
end

local function multiplyUDim2ByFactor(UDIM2: UDim2, FACTOR: number)
	return UDim2.new(UDIM2.X.Scale * FACTOR, UDIM2.X.Offset * FACTOR, UDIM2.Y.Scale * FACTOR, UDIM2.Y.Offset * FACTOR)
end

-- Its kinda dumb how we have to use this workaround
local function instanceHasProperty(INSTANCE: Instance, PROPERTY_NAME: string): (boolean, any | string)
	return pcall(function()
		return (INSTANCE :: any)[PROPERTY_NAME]
	end)
end

-- Note that you can use the methods normally (you can do ParticleEmitter:Method())
-- Basically just ignore the argument "self: ParticleEmitter2D" and replace the dot
-- that goes before the method name with a colon (:)

--- Emitter Methods ---

-- Unless said otherwise, we are setting the default properties of particles
-- ex: :SetSpeed() sets the PARTICLE'S speed


function emitterMethods.GetPropertyTransition(self: ParticleEmitter2D, PROPERTY_NAME: string): (PropertyTransition?, number?)
	for index, propertyTransition in self.PropertyTransitions do
		if propertyTransition.Name == PROPERTY_NAME then
			return propertyTransition, index
		end
	end
	return nil
end

function emitterMethods.SetEmitterParticle(self: ParticleEmitter2D, PARTICLE: GuiObject?): ParticleEmitter2D
	if PARTICLE ~= nil and (typeof(PARTICLE) ~= 'Instance' or not PARTICLE:IsA('GuiObject')) then
		error(formatString(not_correct_type_err, 'SetEmitterParticle', PARTICLE))
	end
	
	self.TemplateParticle = PARTICLE
	
	if PARTICLE == nil and self.PreRenderConnection ~= nil then
		self.PreRenderConnection:Disconnect()
		self.PreRenderConnection = nil :: any
		
		self:ClearParticles()
		self:ClearPropertyTransitions()
	else
		-- Remove all property transitions that dont belong
		local propertyTransitionsToRemove = {}
		
		for _, propertyTransition in self.PropertyTransitions do
			if instanceHasProperty(PARTICLE :: GuiObject, propertyTransition.Name) then continue end
			table.insert(propertyTransitionsToRemove, propertyTransition.Name)
		end
		
		local i, propTransition = next(propertyTransitionsToRemove)
		while propTransition do
			self:RemovePropertyTransition(propTransition)
			table.remove(propertyTransitionsToRemove, i)
			i, propTransition = next(propertyTransitionsToRemove)
		end
		
		self.PreRenderConnection = runSv.RenderStepped:Connect(function(DELTA_TIME)
			self:Update(DELTA_TIME)
		end)
	end
	
	return self
end

function emitterMethods.SetEmitterRate(self: ParticleEmitter2D, NEW_RATE: number): ParticleEmitter2D
	if type(NEW_RATE) ~= 'number' then
		error(formatString(not_number_err, NEW_RATE))
	end
	
	if math.sign(NEW_RATE) == -1 then error('Rate can not be negative!') end
	
	if NEW_RATE >= 100 then warn('Setting the emission rate to high values might cause performance issues.') end
	
	self.Rate = NEW_RATE
	
	return self
end

function emitterMethods.SetEmissionShape(self: ParticleEmitter2D, NEW_EMISSION_SHAPE: 'point' | 'area'): ParticleEmitter2D
	NEW_EMISSION_SHAPE = NEW_EMISSION_SHAPE:lower() :: 'point' | 'area'
	
	if NEW_EMISSION_SHAPE ~= 'point' and NEW_EMISSION_SHAPE ~= 'area' then 
		error(`Invalid emission shape: {tostring(NEW_EMISSION_SHAPE)}`)
	end
	
	self.EmitShape = NEW_EMISSION_SHAPE
	
	return self
end

-- If there is no max, then the value will be the same every time
-- This rule is consistant for the following four methods

function emitterMethods.SetSpeed(self: ParticleEmitter2D, MIN_SPEED: number, MAX_SPEED: number?): ParticleEmitter2D
	if type(MIN_SPEED) ~= 'number' or (MAX_SPEED and type(MAX_SPEED) ~= 'number') then
		error(formatString(range_not_number_err, MIN_SPEED, MAX_SPEED)) 
	end
	
	self.Speed = NumberRange.new(MIN_SPEED, MAX_SPEED :: any)

	return self
end

function emitterMethods.SetRotationSpeed(self: ParticleEmitter2D, MIN_ROT_SPEED: number, MAX_ROT_SPEED: number?): ParticleEmitter2D
	if type(MIN_ROT_SPEED) ~= 'number' or (MAX_ROT_SPEED and type(MAX_ROT_SPEED) ~= 'number') then
		error(formatString(range_not_number_err, MIN_ROT_SPEED, MAX_ROT_SPEED)) 
	end

	self.RotationSpeed = NumberRange.new(MIN_ROT_SPEED, MAX_ROT_SPEED :: any)

	return self
end

function emitterMethods.SetLifetime(self: ParticleEmitter2D, MIN_LIFETIME: number, MAX_LIFETIME: number?): ParticleEmitter2D
	if type(MIN_LIFETIME) ~= 'number' or (MAX_LIFETIME and type(MAX_LIFETIME) ~= 'number') then
		error(formatString(range_not_number_err, MIN_LIFETIME, MAX_LIFETIME)) 
	end

	self.Lifetime = NumberRange.new(MIN_LIFETIME, MAX_LIFETIME :: any)

	return self
end

function emitterMethods.SetSpreadAngle(self: ParticleEmitter2D, MIN_SPREAD_ANGLE: number, MAX_SPREAD_ANGLE: number?): ParticleEmitter2D
	if type(MIN_SPREAD_ANGLE) ~= 'number' or (MAX_SPREAD_ANGLE and type(MAX_SPREAD_ANGLE) ~= 'number') then
		error(formatString(range_not_number_err, MIN_SPREAD_ANGLE, MAX_SPREAD_ANGLE)) 
	end
	
	if MAX_SPREAD_ANGLE ~= nil then
		local oldMin = MIN_SPREAD_ANGLE
		MIN_SPREAD_ANGLE = -MAX_SPREAD_ANGLE
		MAX_SPREAD_ANGLE = -oldMin
	else
		MIN_SPREAD_ANGLE = -MIN_SPREAD_ANGLE
	end

	self.SpreadAngle = NumberRange.new(MIN_SPREAD_ANGLE, MAX_SPREAD_ANGLE :: any)

	return self
end

function emitterMethods.SetRotation(self: ParticleEmitter2D, MIN_ROTATION: number, MAX_ROTATION: number?): ParticleEmitter2D
	if type(MIN_ROTATION) ~= 'number' or (MAX_ROTATION and type(MAX_ROTATION) ~= 'number') then
		error(formatString(range_not_number_err, MIN_ROTATION, MAX_ROTATION)) 
	end

	self.Rotation = NumberRange.new(MIN_ROTATION, MAX_ROTATION :: any)

	return self
end

-- SEQ is short for sequence

function emitterMethods.SetPropertyTransition(self: ParticleEmitter2D, PROPERTY_NAME: string, TRANSITION_SEQ: ColorSequence | NumberSequence): ParticleEmitter2D
	if type(PROPERTY_NAME) ~= 'string' then error('Property name must be a string!') end
	if self.TemplateParticle == nil then error('Cannot set value! Template particle must be set first.') end
	
	local isColorSequence = typeof(TRANSITION_SEQ) == 'ColorSequence'
	local isNumberSequence= typeof(TRANSITION_SEQ) == 'NumberSequence'
	
	if not isColorSequence and not isNumberSequence then error('Argument TRANSITION_SEQ must be a ColorSequence or NumberSequence. Got '..typeof(TRANSITION_SEQ)) end
	
	local propertyTransition: any, index = self:GetPropertyTransition(PROPERTY_NAME) 
	
	if propertyTransition == nil then
		-- Change this when you can check if a certain class has a property
		local success, propertyValue = instanceHasProperty(self.TemplateParticle, PROPERTY_NAME)
		if not success then error(`Could not find property {PROPERTY_NAME} for {self.TemplateParticle.ClassName}!`) end
		if typeof(propertyValue) ~= 'number' and typeof(propertyValue) ~= 'Color3' then
			error(`{PROPERTY_NAME} is neither a color nor a number!`)
		end
		
		propertyTransition = {}
		propertyTransition.Name = PROPERTY_NAME
		propertyTransition.IsColorSequence = isColorSequence
		propertyTransition.IsNumberSequence = isNumberSequence
	end
	
	propertyTransition.SequenceFixed = isSequenceFixed(TRANSITION_SEQ)
	propertyTransition.Value = TRANSITION_SEQ
	
	propertyTransition = propertyTransition :: PropertyTransition
	
	for _, particle in self.Particles do
		local progress = particle.CurrentAge/particle.DeterminedLifetime
		-- i love typechecking!!
		particle.GuiObject[PROPERTY_NAME] =  if isColorSequence then evalColorSequence(TRANSITION_SEQ :: ColorSequence, progress) 
			else evalNumberSequence(TRANSITION_SEQ :: NumberSequence, progress)
	end
	
	table.insert(self.PropertyTransitions, propertyTransition)
	
	return self
end

function emitterMethods.RemovePropertyTransition(self: ParticleEmitter2D, PROPERTY_NAME: string): ParticleEmitter2D
	if type(PROPERTY_NAME) ~= 'string' then error('Property name must be a string!') end
	
	local index, propertyTransition
	
	for tblIndex, tblPropTransition in self.PropertyTransitions do
		if tblPropTransition.Name == PROPERTY_NAME then
			index = tblIndex
			propertyTransition = tblPropTransition
			break
		end
	end
	
	if not index then error(`Could not find {PROPERTY_NAME} in property transitions array!`) end
	
	table.remove(self.PropertyTransitions, index)
	table.clear(propertyTransition)
	
	return self
end

function emitterMethods.SetScale(self: ParticleEmitter2D, SCALE_SEQ: NumberSequence): ParticleEmitter2D
	if typeof(SCALE_SEQ) ~= 'NumberSequence' then
		error(formatString(not_correct_type_err, 'SetScale', SCALE_SEQ)) 
	end
	
	self.DoUpdateSize = not isSequenceFixed(SCALE_SEQ)
	self.Scale = SCALE_SEQ

	return self
end

function emitterMethods.SetAcceleration(self: ParticleEmitter2D, NEW_ACCELERATION: Vector2): ParticleEmitter2D
	if typeof(NEW_ACCELERATION) ~= 'Vector2' then 
		error(formatString(not_correct_type_err, 'SetAcceleration', NEW_ACCELERATION)) 
	end
	
	self.Acceleration = NEW_ACCELERATION

	return self
end

function emitterMethods.SetDrag(self: ParticleEmitter2D, NEW_DRAG: number): ParticleEmitter2D
	if type(NEW_DRAG) ~= 'number' then 
		error(formatString(not_number_err, NEW_DRAG)) 
	end

	self.Drag = NEW_DRAG

	return self
end

function emitterMethods.ApplyDefaultProperties(self: ParticleEmitter2D, OVERRIDE: boolean?): ParticleEmitter2D
	for propertyName, propertyValue in default_emitter_values do
		if self[propertyName] ~= nil and not OVERRIDE then continue end
		self[propertyName] = propertyValue
	end
	
	self.AllPropertiesSet = true
	
	return self
end

function emitterMethods.Emit(self: ParticleEmitter2D, COUNT: number): ParticleEmitter2D
	COUNT = COUNT or 1
	
	for i = 1, COUNT do
		emitYourParticleModule.newParticle(self)
	end
	
	return self
end

-- Updates every particle. Runs every frame.
function emitterMethods.Update(self: ParticleEmitter2D, DELTA_TIME: number)
	if not self.TemplateParticle then return end
	
	if self.Rate ~= 0 then
		self.RateTick += DELTA_TIME
		
		if self.RateTick >= 1/self.Rate then
			self.RateTick = 0
			self:Emit(1)
		end
	end
	
	for _, particle in self.Particles do
		particle:Update(DELTA_TIME)
	end
end

function emitterMethods.ClearParticles(self: ParticleEmitter2D): ParticleEmitter2D
	local _, particle = next(self.Particles)
	while particle do
		particle:Destroy()
		_, particle = next(self.Particles)
	end
	
	return self
end

function emitterMethods.ClearPropertyTransitions(self: ParticleEmitter2D): ParticleEmitter2D
	local _, propertyTransition = next(self.PropertyTransitions)
	while propertyTransition do
		self:RemovePropertyTransition(propertyTransition.Name)
		_, propertyTransition = next(self.PropertyTransitions)
	end

	return self
end

function emitterMethods.Destroy(self: ParticleEmitter2D)
	self:SetEmitterParticle(nil)
	self:ClearParticles()
	self:ClearPropertyTransitions()
	
	self.ParticleCreated:Destroy()
	self.ParticleUpdated:Destroy()
	
	setmetatable(self :: any, nil)
	table.clear(self :: any)
end

--- Particle Methods ---

function particleMethods.Update(self: Particle2D, DELTA_TIME: number)
	self.CurrentAge = math.clamp(self.CurrentAge + DELTA_TIME, 0, self.DeterminedLifetime)
	
	self.Velocity -= self.Velocity/2 * DELTA_TIME * self.EmittedBy.Drag
	self.Velocity += self.EmittedBy.Acceleration * DELTA_TIME
	
	self.Position += self.Velocity * DELTA_TIME
	
	local lifetimeProgress = self.CurrentAge/self.DeterminedLifetime
	
	self.GuiObject.Position = self.Origin + UDim2.fromOffset(self.Position.X, self.Position.Y)
	self.GuiObject.Rotation += self.DeterminedRotationSpeed * 360 * DELTA_TIME
	
	for _, propertyTransition in self.EmittedBy.PropertyTransitions do
		-- I loveeeeeeee typechecking
		self.GuiObject[propertyTransition.Name] = 
			if propertyTransition.IsColorSequence then 
				evalColorSequence(propertyTransition.Value :: ColorSequence, lifetimeProgress) 
			elseif propertyTransition.IsNumberSequence then 
				evalNumberSequence(propertyTransition.Value :: NumberSequence, lifetimeProgress)
			else nil
	end
	
	--[[if self.EmittedBy.DoUpdateBackgroundColor then
		self.GuiObject.BackgroundColor3 = evalColorSequence(self.EmittedBy.BackgroundColor :: ColorSequence, lifetimeProgress)
	end]]
	
	if self.EmittedBy.DoUpdateSize then
		self.GuiObject.Size = multiplyUDim2ByFactor(self.InitialSize, evalNumberSequence(self.EmittedBy.Scale, lifetimeProgress))
	end
	
	--[[if self.EmittedBy.DoUpdateTransparency then
		self.GuiObject.BackgroundTransparency = evalNumberSequence(self.EmittedBy.BackgroundTransparency, lifetimeProgress)
	end]]
	
	self.EmittedBy.ParticleUpdated:Fire(self, DELTA_TIME, lifetimeProgress)
	
	if lifetimeProgress == 1 then
		self:Destroy()
	end
end

-- using (:: any) to silence roblox type check
function particleMethods.Destroy(self: Particle2D)
	local index = table.find(self.EmittedBy.Particles, self)
	table.remove(self.EmittedBy.Particles, table.find(self.EmittedBy.Particles, self))
	
	self.GuiObject:Destroy()
		
	self.EmittedBy = self :: any; -- Remove reference to make sure it GCs
	table.clear(self :: any)
	setmetatable(self :: any, nil)
end

--- Constructors ---

function emitYourParticleModule.newParticle(EMITTER: ParticleEmitter2D): Particle2D
	if not EMITTER.TemplateParticle then error('Template particle must be set before emitting a particle!') end
	
	local particle = setmetatable({}, particleMetatable) :: Particle2D

	local spreadAngle = getNumFromNumRange(EMITTER.SpreadAngle)
	
	particle.VelocityDirection = Vector2.new(math.cos(math.rad(spreadAngle)), math.sin(math.rad(spreadAngle))).Unit
	particle.Velocity = particle.VelocityDirection * getNumFromNumRange(EMITTER.Speed)
	particle.Position = Vector2.new()
	
	particle.CurrentAge = 0
	
	particle.DeterminedLifetime = getNumFromNumRange(EMITTER.Lifetime)
	particle.DeterminedRotationSpeed = getNumFromNumRange(EMITTER.RotationSpeed)
	
	local parentAbsSize = EMITTER.GuiObject.AbsoluteSize
	
	particle.GuiObject = EMITTER.TemplateParticle:Clone()
	particle.GuiObject.Rotation = getNumFromNumRange(EMITTER.Rotation)
	particle.GuiObject.Visible = true
	
	local initialPos = particle.GuiObject.Position
	particle.InitialSize = particle.GuiObject.Size
	
	if EMITTER.EmitShape == 'point' then
		particle.Origin = UDim2.fromOffset(parentAbsSize.X * initialPos.X.Scale + initialPos.X.Offset, parentAbsSize.Y * initialPos.Y.Scale + initialPos.Y.Offset)
	elseif EMITTER.EmitShape == 'area' then
		particle.Origin = UDim2.fromOffset(parentAbsSize.X * random:NextNumber(), parentAbsSize.Y * random:NextNumber())
	end
	
	particle.GuiObject.Position = particle.Origin
	particle.GuiObject.Parent = EMITTER.GuiObject

	particle.EmittedBy = EMITTER
	
	table.insert(EMITTER.Particles, particle)
	
	return particle
end

function emitYourParticleModule.newEmitter(WRAPPED_OBJECT: GuiObject): ParticleEmitter2D
	local emitter = setmetatable({}, emitterMetatable) :: ParticleEmitter2D
	
	emitter.GuiObject = WRAPPED_OBJECT
	emitter.Particles = {}
	
	emitter.ParticleCreated = signalModule.new()
	emitter.ParticleUpdated = signalModule.new()
	
	emitter:ApplyDefaultProperties(false)
	
	return emitter
end

return emitYourParticleModule