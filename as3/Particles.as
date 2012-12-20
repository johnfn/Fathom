package {

	import flash.display.Sprite;
	import mx.core.BitmapAsset;
	import flash.utils.Dictionary;

	public class Particles {
		private static var particleEffects:Array = [];

		// Recycling particles within ALL particle effects.
		private static var recycledParticles:Array = [];

		// Recycling particles within this particle effect.
		private var deadParticles:Array = [];

		// Number from 0 to 1 - % chance of spawning the particle on a single frame.
		private var spawnRate:Number = 1;

		private var lifetimeLow:int = 60;
		private var lifetimeHigh:int = 90;

		private var flickerOnDeath:Boolean = false;
		private var fadeOut:Boolean = false;

		private var following:Boolean = false;
		private var followTarget:Entity = null;

		private var spawnLoc:Rect = new Rect(0, 0, 500, 500);

		private var scaleX:Number = 1;
		private var scaleY:Number = 1;

		private var velXLow:Number = -2;
		private var velXHigh:Number = 2;

		private var velYLow:Number = 1;
		private var velYHigh:Number = 4;

		private var stopParticleGen:int = -1;

		private var particleData:Dictionary = new Dictionary();

		private var animated:Boolean = false;
		private var animationFrames:Array;
		// dimensions of the particle. currently only defined if thie particle is animated, TODO.
		private var particleDim:Vec;

		private var baseMC:Class;

		public function Particles(baseMC:Class, width:int = -1):void {
			this.baseMC = baseMC;

			particleEffects.push(this);
		}

		public function setImage(img:Class):void {
			this.baseMC = img;
		}

		// Chainable methods for ease of constructing particle effects.

		public function withLifetime(newLow:int, newHigh:int):Particles {
			this.lifetimeLow = newLow;
			this.lifetimeHigh = newHigh;

			return this;
		}

		public function withSpawnRate(rate:Number):Particles {
			this.spawnRate = rate;

			return this;
		}

		// Makes the assumption that the baseMC is a height * numFrames by width spritesheet.
		// Yep, square frames for now. TODO.
		public function animateFromSpritesheet():Particles {
			var width:int, height:int;
			var asset:BitmapAsset = new baseMC();
			var animationFrames:Array = [];

			animated = true;

			// Initialize the baseMC just to get its width and height.
			width = asset.width;
			height = asset.height;

			particleDim = new Vec(asset.height, asset.height);

			Util.assert(width % height == 0);

			for (var i:int = 0; i < width / height; i++) {
				animationFrames.push([i, 0]);
			}

			this.animationFrames = animationFrames;
			return this;
		}

		// This naming scheme only really makes sense with chaining:

		// new Particles().withLifetime(50, 90).thatFlicker();

		public function thatFlicker():Particles {
			flickerOnDeath = true;

			return this;
		}

		public function thatFade():Particles {
			fadeOut = true;

			return this;
		}

		public function spawnAt(x:int, y:int, width:int, height:int):Particles {
			spawnLoc = new Rect(x, y, width, height);

			return this;
		}

		// TODO: Not fully implemented.
		public function andFollow(e:Entity):Particles {
			following = true;
			followTarget = e;

			Util.assert(false);

			return this;
		}

		public function withVelX(newXLow:Number, newXHigh:Number):Particles {
			this.velXLow  = newXLow;
			this.velXHigh = newXHigh;

			return this;
		}

		public function withVelY(newYLow:Number, newYHigh:Number):Particles {
			this.velYLow  = newYLow;
			this.velYHigh = newYHigh;

			return this;
		}

		public function withScale(scale:Number):Particles {
			this.scaleX = scale;
			this.scaleY = scale;

			return this;
		}

		public function spawnParticles(num:int):Particles {
			for (var i:int = 0; i < num; i++) {
				spawnParticle();
			}

			return this;
		}

		public function andThenStop():Particles {
			spawnRate = 0;

			return this;
		}

		// This terminates the entire Particle generator, not individual particles.
		// Time is in frames.
		public function thatStopsAfter(time:int):Particles {
			stopParticleGen = time;

			return this;
		}

		private function killParticle(p:Sprite):void {
			delete particleData[p];
		}

		public static function removeParticleEffect(p:Particles):void {
			Particles.particleEffects.remove(p);
		}

		public static function updateAll():void {
			for (var i:int = 0; i < Particles.particleEffects.length; i++) {
				Particles.particleEffects[i].update();
			}
		}

		public function spawnParticle():Particles {
			var newParticle:Graphic;
			var newData:Object = {};

			if (deadParticles.length > 0) {
				newParticle = deadParticles.pop();

				/*
				if (!(newParticle is baseMC)) {
					newParticle = new baseMC();
				}
				*/
			} else {
				newParticle = new Graphic();
				if (animated) {
			        newParticle.loadSpritesheet(baseMC, particleDim, new Vec(animationFrames[0][0], animationFrames[0][1]));

					newParticle.animations.addAnimationXY("particle", animationFrames);
					newParticle.animations.playWithOffset("particle", Util.randRange(0, 12));
				} else {
					newParticle.loadImage(baseMC);
				}
			}

			newData.life = Util.randRange(lifetimeLow, lifetimeHigh);
			newData.totalLife = newData.life;

			newData.vel = new Vec(Util.randNum(velXLow, velXHigh),
				                  Util.randNum(velYLow, velYHigh));

			newData.x = Util.randRange(spawnLoc.x, spawnLoc.right);
			newData.y = Util.randRange(spawnLoc.y, spawnLoc.bottom);

			particleData[newParticle] = newData;

			newParticle.scaleX = scaleX;
			newParticle.scaleY = scaleY;

			Fathom.container.addChild(newParticle);

			return this;
		}

		private function killThisParticleEffect():void {
			Particles.removeParticleEffect(this);
		}

		public function update():void {
			if (Fathom.currentMode != 0) {
				trace("Due to a hack, I'm returning now.");
				return;
			}

			var particlesLeft:Boolean = true;

			stopParticleGen--;

			if (stopParticleGen == 0) {
				killThisParticleEffect();

				return;
			}

			// See if we should make a new particle.
			if (Math.random() < spawnRate) {
				spawnParticle();
			}

			// Update each particle.
			for (var pObj:* in particleData) {
				var p:Graphic = pObj as Graphic;
				var data:Object = particleData[p];

				particlesLeft = true;

				data.x += data.vel.x;
				data.y += data.vel.y;

				pObj.x = data.x;
				pObj.y = data.y;

				// TODO: Graphics should just update themselves.
				pObj.update(null);

				var lifeLeft:int = data["life"]--;

				// Kill the particle, if necessary.
				if (lifeLeft == 0 || (animated && pObj.animations.lastFrame())) {
					delete particleData[p];
					deadParticles.push(p);

					p.parent.removeChild(p);

					if (animated) {
						p.animations.stop();
					}
				}

				// Flicker if necessary
				if (flickerOnDeath && lifeLeft < 10) {
					p.visible = (lifeLeft / 3) % 2 == 0;
				}

				if (fadeOut) {
					p.alpha = lifeLeft / data.totalLife;
				}
			}

			if (!particlesLeft) {
				killThisParticleEffect();
			}
		}
	}
}