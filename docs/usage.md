[GuiObjectDoc]: https://create.roblox.com/docs/reference/engine/classes/GuiObject
[NumberDoc]: https://create.roblox.com/docs/luau/numbers
[BooleanDoc]: https://create.roblox.com/docs/luau/booleans
[NumberRangeDoc]: https://create.roblox.com/docs/reference/engine/datatypes/NumberRange
[Vector2Doc]: https://create.roblox.com/docs/reference/engine/datatypes/Vector2
[ColorSequenceDoc]: https://create.roblox.com/docs/reference/engine/datatypes/ColorSequence
[NumberSequenceDoc]: https://create.roblox.com/docs/reference/engine/datatypes/NumberSequence
[StringDoc]: https://create.roblox.com/docs/luau/strings

## Particle Emitter

```lua title="Construction"
local emitYourParticle = require('Module Path Here') --(1)!

local ParticleEmitter = emitYourParticle.newEmitter(GuiObject) --(2)!
```

1. Replace this with your module's path. Remove the single quotes.
2. Put your emitter's GUI object here.

### Properties 

!!! note 

    All of these are read-only. Only index when reading the properties. Set the properties using methods.

| Property Name | Description | Default | 
| :--- | :--- | :--- |
| GuiObject [`GuiObject`][GuiObjectDoc] | The particle emitter's GUI Object | `GuiObject` |
| TemplateParticle [`GuiObject`][GuiObjectDoc] | The particle emitter's particle | `nil` |
| Particles <br>[`{ Particle2D }`]() | An array of active particles | `{ }` |
| PropertyTransitions <br>[`{ PropertyTransition }`]() | An array of active property transitions  | `nil` |
| AllPropertiesSet [`Boolean`][BooleanDoc] | True if every `ParticleEmitter:ApplyDefaultProperties()` has been called | `false` |
| DoUpdateSize [`Boolean`][BooleanDoc] | True if the `Scale` property is set and the NumberSequence is not a fixed number | `false` |
| Rate [`Number`][NumberDoc] | Particles emitted every second | `5` |
| RateTick [`Number`][NumberDoc] | A number from `0` to `1/Rate` that ticks up with the time and resets everytime it reaches `1/Rate`. | `0` |
| Speed [`NumberRange`][NumberRangeDoc] | A range of speeds that determine the initial speed of a particle. Pixels/Second | `[30 - 70]` |
| RotationSpeed [`NumberRange`][NumberRangeDoc] | A range of rotation speeds in full rotations every second | `0` |
| Rotation [`NumberRange`][NumberRangeDoc] | A range of starting rotations of a particle. | `0` |
| Lifetime [`NumberRange`][NumberRangeDoc] | A range of lifetimes in seconds which determine the time the particle will last. | `[5 - 10]`
| SpreadAngle [`NumberRange`][NumberRangeDoc] | A range of angles in degrees that the particle's initial velocity direction will be. | `0` |
| EmitShape [`'area' or 'point'`]() | If the EmitShape is 'area' then the emitter will emit throughout the emitter, if it is 'point' then it will emit at the TemplateParticle's position | `'point'` |
| Acceleration [`Vector2`][Vector2Doc] | The acceleration, in pixels/second^2, every particle will have. | `[0, 0]` |
| Drag [`Number`][NumberDoc] | The time it takes for a particle to reach half its velocity. | `0` |
| Scale [`NumberSequence`][NumberSequenceDoc] | The way the scale will change over a particle's lifetime. | `NumberSequence.new(1, 1)` |


### Methods

!!! note

    Most methods are chainable.

#### SetEmitterParticle

| `self` ParticleEmiter:SetEmitterParticle( `GuiObject:` [`GuiObject`][GuiObjectDoc] ) |
| - |
| Sets the GUI object as the template particle. Property transitions are checked for compatibility and deleted if they are incompatible. All particles will be cleared. |

```lua title="Example"
local particleObject = script.Parent.Frame

ParticleEmitter:SetEmitterParticle(particleObject)
```
<hr>

#### SetEmitterRate

| `self` ParticleEmiter:SetEmitterRate( `New Rate:` [`Number`][NumberDoc] ) |
| - |
| Sets the speed particles are emitted at emissions per second. |

```lua title="Example"
ParticleEmitter:SetEmitterRate(15)
```
<hr>

#### SetEmissionShape

| `self` ParticleEmiter:SetEmissionShape( `New Shape:` [`"area" | "point"`]() ) |
| - |
| Sets the way the first position of a particle is determined. Read [EmitShape property](#properties) for more info. |

```lua title="Example"
ParticleEmitter:SetEmissionShape('Point')
```
<hr>

#### SetSpeed

| `self` ParticleEmiter:SetSpeed( `New Speed:` [`Number`][NumberDoc] ) |
| - |
| Sets the inital speed of a particle. |

| `self` ParticleEmiter:SetSpeed( `Minimum Speed:` [`Number`][NumberDoc], `Maximum Speed:` [`Number`][NumberDoc] ) |
| - |
| Sets the range of speeds that will be the initial speed of a particle. |

```lua title="Example"
ParticleEmitter:SetSpeed(5, 15)
```
<hr>

#### SetRotationSpeed

| `self` ParticleEmiter:SetRotationSpeed( `Rotation Speed:` [`Number`][NumberDoc] ) |
| - |
| Sets the speed particles rotate. Rotations per second. |

| `self` ParticleEmiter:SetRotationSpeed( `Minimum Rotation Speed:` [`Number`][NumberDoc], `Maximum  Rotation Speed:` [`Number`][NumberDoc] ) |
| - |
| Sets the range of speeds at which the particles will rotate. |

```lua title="Example"
ParticleEmitter:SetRotationSpeed(.2, .6)
```
<hr>

#### SetRotation

| `self` ParticleEmiter:SetRotation( `Rotation:` [`Number`][NumberDoc] ) |
| - |
| Sets the rotation particles will start at. |

| `self` ParticleEmiter:SetRotation( `Minimum Rotation:` [`Number`][NumberDoc], `Maximum Rotation:` [`Number`][NumberDoc] ) |
| - |
| Sets the range of rotations particles will start at. |

```lua title="Example"
ParticleEmitter:SetRotation(0, 360)
```
<hr>

#### SetLifetime

| `self` ParticleEmiter:SetLifetime( `Lifetime:` [`Number`][NumberDoc] ) |
| - |
| Sets the lifetime which is the amount of time the particles will be active until they get deleted. |

| `self` ParticleEmiter:SetLifetime( `Minimum Lifetime:` [`Number`][NumberDoc], `Maximum Lifetime:` [`Number`][NumberDoc] ) |
| - |
| Sets the range of lifetimes a particle will have. |

```lua title="Example"
ParticleEmitter:SetLifetime(.2, 1)
```
<hr>

#### SetSpreadAngle

| `self` ParticleEmiter:SetSpreadAngle( `Spread Angle:` [`Number`][NumberDoc] ) |
| - |
| Sets the direction of a particle's velocity. |

| `self` ParticleEmiter:SetSpreadAngle( `Minimum Spread Angle:` [`Number`][NumberDoc], `Maximum Spread Angle:` [`Number`][NumberDoc] ) |
| - |
| Sets the range of a particle's velocity direction. |

```lua title="Example"
ParticleEmitter:SetSpreadAngle(75, 105)
```
<hr>

#### SetAcceleration

| `self` ParticleEmiter:SetAcceleration( `New Acceleration:` [`Vector2`][Vector2Doc] ) |
| - |
| `self` Sets the speed at which the velocity of a particle will change. |

```lua title="Example"
ParticleEmitter:SetAcceleration(Vector2.new())
```
<hr>

#### SetDrag

| `self` ParticleEmiter:SetDrag( `Drag:` [`Number`][NumberDoc] ) |
| - |
| Sets the time that it takes for a particle to reach half of its velocity. |

```lua title="Example"
ParticleEmitter:SetDrag(4)
```
<hr>

#### SetScale

| `self` ParticleEmiter:SetScale( `New Scale:` [`NumberSequence`][NumberSequenceDoc] ) |
| - |
| Sets the transition of the particle's size. |

```lua title="Example"
local scaleNumberSequence = NumberSequence.new({
    NumberSequenceKeypoint.new(0, .5),
    NumberSequenceKeypoint.new(1, 1)
}) 

ParticleEmitter:SetScale(scaleNumberSequence)
```
<hr>

#### SetPropertyTransition

| `self` ParticleEmiter:SetPropertyTransition( `Property Name:` [`string`][StringDoc], `Transition Sequence:` [`NumberSequence or ColorSequence`][NumberSequenceDoc] ) |
| - |
| Sets the transition of one of the particle's property. Property name must exist for the current particle template. |

```lua title="Example"
local bgColorSequence = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 50, 85)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
})

ParticleEmitter:SetPropertyTransition('BackgroundColor',  bgColorSequence)
```
<hr>

#### GetPropertyTransition

| [`PropertyTransition`]() ParticleEmiter:GetPropertyTransition( `Property Name:` [`string`][StringDoc] ) |
| - |
| Returns a property transition from the property name given. |

```lua title="Example"
ParticleEmitter:GetPropertyTransition('BackgroundColor')
```
<hr>

#### Emit

| `self` :Emit( `Emit Count:` [`Number`][NumberDoc] ) |
| - |
| Emits the number of particles. |

| `self` :Emit(  ) |
| - |
| Emits a particle. |

```lua title="Example"
ParticleEmitter:Emit(5)
```
<hr>

#### ClearParticles

| `void` :ClearParticles( ) |
| - |
| Removes every particle |

```lua title="Example"
ParticleEmitter:ClearParticles()
```
<hr>

#### ClearPropertyTransitions

| `void` :ClearPropertyTransitions( ) |
| - |
| Removes every property transition. |

```lua title="Example"
ParticleEmitter:ClearPropertyTransitions()
```
<hr>

#### Destroy

| `void` :Destroy( ) |
| - |
| Destroys the particle emitter by destroying all the particles and some other stuff. |

```lua title="Example"
ParticleEmitter:Destroy()
```
<hr>

#### Update

| `void` :Update( `Delta Time:` [`Number`][NumberDoc] ) |
| - |
| Updates every particle's position. Runs for every frame the particle emitter has a particle template. |

```lua title="Example"
ParticleEmitter:Update(10000) -- i don't really know why you would want to do this
```
<hr>

### Events

| Event Name | Arguments | Description | 
| :--- | :--- | :--- |
| ParticleCreated | `Particle:` [`Particle`]() | Fired every time a particle is emitted|
| ParticleUpdated | `Particle:` [`Particle`](), `DeltaTime:` [`Number`][NumberDoc], `LifetimeProgres:` [`Number`][NumberDoc] | Fired every frame for every particle on the screen |

!!! note

    Lifetime Progress is a number from `0` to `1` which is the particle's age divided by the particle's determined lifetime

## Particle

### Properties

| Property Name | Description |
| :--- | :--- |
| VelocityDirection [`Vector2`][Vector2Doc] | The initial direction of the determined velocity. |
| Velocity [`Vector2`][Vector2Doc] | The current velocity of the particle in pixels. |
| Position [`Vector2`][Vector2Doc] | The current position of the particle in pixels. |
| CurrentAge [`Number`][NumberDoc] | The amount of time the particle has been alive. |
| DeterminedLifetime [`Number`][NumberDoc] | The determined amount of time time until the particle will be destroyed. |
| DeterminedRotationSpeed [`Number`][NumberDoc] | The determined speed in rotations per second of the particle. |
| GuiObject [`GuiObject`][GuiObjectDoc] | The particle's gui object. |
| EmittedBy [`ParticleEmitter`]() | The particle's parent emitter. |

!!! note

    Determined essentially just means its a single random number from a certain range.

### Methods

#### Update

| `void` :Update( `Delta Time:` [`Number`][NumberDoc] ) |
| - |
| Updates the particle's position. Ran every frame for the particle's lifetime. |

```lua title="Example"
Particle:Update(10000) -- i don't really know why you would do this either
```
<hr>

#### Destroy

| `void` :Destroy( ) |
| - |
| Destroys the particle, removes it from the Particles table of the emitter, and removes references. Does this automatically on lifetime end. |

```lua title="Example"
Particle:Destroy()
```
