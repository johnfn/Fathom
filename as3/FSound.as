package {
	import flash.media.Sound;
	import flash.media.SoundTransform;
	import flash.media.SoundChannel;

	public class FSound {
		private var volume:Number = 1.0;
		private var sound:Sound;
		private var sc:SoundChannel;

		public function FSound(soundClass:Class) {
			this.sound = new soundClass();
		}

		// Set the volume of all future plays of this sound.
		public function withVolume(vol:Number):FSound {
			this.volume = vol;

			return this;
		}

		// Play this sound.
		public function play(offset:int = 0, loops:int = 1):FSound {
			sc = this.sound.play(offset, loops);
			var st:SoundTransform = sc.soundTransform;

			st.volume = volume;
			sc.soundTransform = st;

			return this;
		}

		public function stop():void {
			sc.stop();
		}
	}
}