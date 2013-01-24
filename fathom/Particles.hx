package fathom;
//TODO...
#if false

import flash.display.Sprite;

typedef ParticleData = {life: Int, totalLife: Int, vel: Vec, x: Int, y: Int};

class Particles {

    static var particleEffects : Array<Dynamic> = [];
    // Recycling particles within ALL particle effects.
    static var recycledParticles : Array<Dynamic> = [];
    // Recycling particles within this particle effect.
    var deadParticles : Array<Dynamic>;
    // Number from 0 to 1 - % chance of spawning the particle on a single frame.
    var spawnRate : Float;
    var lifetimeLow : Int;
    var lifetimeHigh : Int;
    var flickerOnDeath : Bool;
    var fadeOut : Bool;
    var following : Bool;
    var followTarget : Entity;
    var spawnLoc : Rect;
    var scaleX : Float;
    var scaleY : Float;
    var velXLow : Float;
    var velXHigh : Float;
    var velYLow : Float;
    var velYHigh : Float;
    var stopParticleGen : Int;
    var particleData : SuperObjectHash<Entity, ParticleData>;
    var animated : Bool;
    var animationFrames : Array<Array<Int>>;

    // dimensions of the particle. currently only defined if thie particle is animated, TODO.
    var particleDim : Vec;
    var baseMC : Class<Dynamic>;

    public function new(baseMC : Class<Dynamic>, width : Int = -1) {
        deadParticles = [];
        spawnRate = 1;
        lifetimeLow = 60;
        lifetimeHigh = 90;
        flickerOnDeath = false;
        fadeOut = false;
        following = false;
        followTarget = null;
        spawnLoc = new Rect(0, 0, 500, 500);
        scaleX = 1;
        scaleY = 1;
        velXLow = -2;
        velXHigh = 2;
        velYLow = 1;
        velYHigh = 4;
        stopParticleGen = -1;
        particleData = new SuperObjectHash();
        animated = false;
        this.baseMC = baseMC;
        particleEffects.push(this);
    }

    public function setImage(img : Class<Dynamic>) : Void {
        this.baseMC = img;
    }

    // Chainable methods for ease of constructing particle effects.
        public function withLifetime(newLow : Int, newHigh : Int) : Particles {
        this.lifetimeLow = newLow;
        this.lifetimeHigh = newHigh;
        return this;
    }

    public function withSpawnRate(rate : Float) : Particles {
        this.spawnRate = rate;
        return this;
    }

    // Makes the assumption that the baseMC is a height * numFrames by width spritesheet.
    // Yep, square frames for now. TODO.
    public function animateFromSpritesheet() : Particles {
        var width : Int;
        var height : Int;
        var asset = Type.createInstance(baseMC, []);
        var animationFrames : Array<Array<Int>> = [];
        animated = true;
        // Initialize the baseMC just to get its width and height.
        width = asset.width;
        height = asset.height;
        particleDim = new Vec(asset.height, asset.height);
        Util.assert(width % height == 0);

        for (i in 0...Std.int(width / height)) {
            animationFrames.push([i, 0]);
        }
        this.animationFrames = animationFrames;
        return this;
    }

    // This naming scheme only really makes sense with chaining:
    // new Particles().withLifetime(50, 90).thatFlicker();
    public function thatFlicker() : Particles {
        flickerOnDeath = true;
        return this;
    }

    public function thatFade() : Particles {
        fadeOut = true;
        return this;
    }

    public function spawnAt(x : Int, y : Int, width : Int, height : Int) : Particles {
        spawnLoc = new Rect(x, y, width, height);
        return this;
    }

    // TODO: Not fully implemented.
        public function andFollow(e : Entity) : Particles {
        following = true;
        followTarget = e;
        Util.assert(false);
        return this;
    }

    public function withVelX(newXLow : Float, newXHigh : Float) : Particles {
        this.velXLow = newXLow;
        this.velXHigh = newXHigh;
        return this;
    }

    public function withVelY(newYLow : Float, newYHigh : Float) : Particles {
        this.velYLow = newYLow;
        this.velYHigh = newYHigh;
        return this;
    }

    public function withScale(scale : Float) : Particles {
        this.scaleX = scale;
        this.scaleY = scale;
        return this;
    }

    public function spawnParticles(num : Int) : Particles {
        var i : Int = 0;
        while(i < num) {
            spawnParticle();
            i++;
        }
        return this;
    }

    public function andThenStop() : Particles {
        spawnRate = 0;
        return this;
    }

    // This terminates the entire Particle generator, not individual particles.
    // Time is in frames.
    public function thatStopsAfter(time : Int) : Particles {
        stopParticleGen = time;
        return this;
    }

    function killParticle(p : Entity) : Void {
        particleData.delete(p);
    }

    static public function removeParticleEffect(p : Particles) : Void {
        Particles.particleEffects.remove(p);
    }

    static public function updateAll() : Void {
        var i : Int = 0;
        while(i < Particles.particleEffects.length) {
            Particles.particleEffects[i].update();
            i++;
        }
    }

    public function spawnParticle() : Particles {
        var newParticle : Entity;
        Util.assert(false);

        if(deadParticles.length > 0)  {
            newParticle = deadParticles.pop();
        } else {
            newParticle = new Entity();
            if(animated)  {
                newParticle.loadSpritesheet(baseMC, particleDim, new Vec(animationFrames[0][0], animationFrames[0][1]));
                newParticle.animations.addAnimationXY("particle", animationFrames);
                newParticle.animations.playWithOffset("particle", Util.randRange(0, 12));
            } else  {
                newParticle.loadImage(baseMC);
            }
        }

        var l:Int = Util.randRange(lifetimeLow, lifetimeHigh);

        var newData : ParticleData =
            { life : l
            , totalLife : l
            , vel : new Vec(Util.randFloat(velXLow, velXHigh), Util.randNum(velYLow, velYHigh))
            , x : Util.randRange(Std.int(spawnLoc.x), Std.int(spawnLoc.right))
            , y : Util.randRange(Std.int(spawnLoc.y), Std.int(spawnLoc.bottom))
        };
        particleData.set(newParticle, newData);
        newParticle.scaleX = scaleX;
        newParticle.scaleY = scaleY;
        Fathom.container.addChild(newParticle);
        return this;
    }

    function killThisParticleEffect() : Void {
        Particles.removeParticleEffect(this);
    }

    public function update() : Void {
        if(Fathom.mode.currentMode != 0)  {
            trace("Due to a hack, I'm returning now.");
            return;
        }
        var particlesLeft : Bool = true;
        stopParticleGen--;
        if(stopParticleGen == 0)  {
            killThisParticleEffect();
            return;
        }
        // See if we should make a new particle.
        if(Math.random() < spawnRate)  {
            spawnParticle();
        }

        // Update each particle.
        for(pObj in particleData) {
            var data : Dynamic = particleData.get(pObj);
            particlesLeft = true;
            data.x += data.vel.x;
            data.y += data.vel.y;
            pObj.x = data.x;
            pObj.y = data.y;
            // TODO: Graphics should just update themselves.
            pObj.update();
            data.set("life", data.get("life") - 1);
            var lifeLeft : Int = data.get("life");
            // Kill the particle, if necessary.
            if(lifeLeft == 0 || (animated && pObj.animations.lastFrame()))  {
                particleData.delete(pObj);
                deadParticles.push(pObj);
                if(animated)  {
                    pObj.animations.stop();
                }
            }

            // Flicker if necessary
            if(flickerOnDeath && lifeLeft < 10)  {
                pObj.visible = (lifeLeft / 3) % 2 == 0;
            }

            if(fadeOut)  {
                pObj.alpha = lifeLeft / data.totalLife;
            }
        }

        if(!particlesLeft)  {
            killThisParticleEffect();
        }
    }

}
#else

//TODO

class Particles {

    public static function updateAll():Void {

    }
}
#end