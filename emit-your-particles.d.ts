import Signal from "@rbxts/signal";

interface PropertyTransition {
  Name: string;
  SequenceFixed: boolean;
  IsColorSequence: boolean;
  IsNumberSequence: boolean;
  Value: ColorSequence | NumberSequence;
}

interface Particle2D {
  EmittedBy: ParticleEmitter2D;
  GuiObject: GuiObject;

  Origin: UDim2;
  InitialSize: UDim2;

  Position: Vector2;
  VelocityDirection: Vector2;
  Velocity: Vector2;

  DeterminedLifetime: number;
  DeterminedRotationSpeed: number;

  CurrentAge: number;

  Update(deltaTime: number): void;
  Destroy(): void;
}

interface ParticleEmitter2D {
  GuiObject: GuiObject;
  TemplateParticle?: GuiObject;
  Particles: Array<Particle2D>;
  PropertyTransitions: Array<PropertyTransition>;

  AllPropertiesSet: boolean;
  DoUpdateSize: boolean;

  ParticleCreated: Signal<(particle: Particle2D) => void>;
  ParticleUpdated: Signal<
    (particle: Particle2D, deltaTime: number, lifetimeProgress: number) => void
  >;

  Rate: number;
  RateTick: number;

  Speed: NumberRange;
  RotationSpeed: NumberRange;
  Rotation: NumberRange;
  Lifetime: NumberRange;
  SpreadAngle: NumberRange;

  Acceleration: Vector2;
  Drag: number;

  EmitShape: "area" | "point";

  Scale: NumberSequence;
  BackgroundTransparency: NumberSequence;
  BackgroundColor: ColorSequence | -1;

  GetPropertyTransition(
    propertyName: string,
  ): LuaTuple<[PropertyTransition, number]> | undefined;
  SetEmitterParticle(): this;
  SetEmitterRate(newRate: number): this;
  SetEmissionShape(newEmissionShape: "point" | "area"): this;

  SetSpeed(speed: number): this;
  SetSpeed(minSpeed: number, maxSpeed: number): this;
  SetRotationSpeed(rotSpeed: number): this;
  SetRotationSpeed(minRotSpeed: number, maxRotSpeed: number): this;
  SetLifetime(lifetime: number): this;
  SetLifetime(minLifetime: number, maxLifetime: number): this;
  SetSpreadAngle(spreadAngle: number): this;
  SetSpreadAngle(minSpreadAngle: number, maxSpreadAngle: number): this;
  SetRotation(rotation: number): this;
  SetRotation(minRotation: number, maxRotation: number): this;
  SetPropertyTransition(
    propertyName: string,
    sequence: ColorSequence | NumberSequence,
  ): this;
  RemovePropertyTransition(propertyName: string): this;
  SetScale(scaleNumberSequence: NumberSequence): this;
  SetAcceleration(acceleration: Vector2): this;
  SetDrag(dragCoefficient: number): this;
  ApplyDefaultProperties(override: boolean | undefined): this;
  Emit(count: number | undefined): this;
  Update(deltaTime: number): this;
  ClearParticles(): this;
  Destroy(): void;
}

interface EmitYourParticles {
  newParticle(emitter: ParticleEmitter2D): Particle2D;
  newEmitter(wrappedGui: GuiObject): ParticleEmitter2D;
}

declare const EmitYourParticles: EmitYourParticles;

export = EmitYourParticles;
