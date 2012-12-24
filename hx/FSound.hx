import flash.media.Sound;
import flash.media.SoundTransform;
import flash.media.SoundChannel;

class FSound {

    var volume : Float;
    var sound : Sound;
    var sc : SoundChannel;
    public function new(soundClass : Class<Dynamic>) {
        volume = 1.0;
        this.sound = Type.createInstance(soundClass, []);
    }

    // Set the volume of all future plays of this sound.
        public function withVolume(vol : Float) : FSound {
        this.volume = vol;
        return this;
    }

    // Play this sound.
        public function play(offset : Int = 0, loops : Int = 1) : FSound {
        sc = this.sound.play(offset, loops);
        var st : SoundTransform = sc.soundTransform;
        st.volume = volume;
        sc.soundTransform = st;
        return this;
    }

    public function stop() : Void {
        sc.stop();
    }

}

