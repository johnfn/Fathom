# Fathom

Hi. Fathom is a game development library, currently being developed for Haxe. It compiles to Flash and NME.

On the Flash side of things, you get a game engine backed by [Starling](https://github.com/PrimaryFeather/Starling-Framework), an awesome graphics library that uses Stage3D. That means we have blazing fast graphics. I'm not being superlative, it's pretty ridiculous. The GPU acceleration means that you need to have tens of thousands of Sprites to see the framerate even dip below 60FPS.

On the NME side, we take advantage of the desktop environment. It's not quite there yet, but my dream is to have all assets have hotswapping built in by default. This means you don't need to restart and travel back to some room to see the effect of changing the map, or testing out a new graphic. Saving in Photoshop will make the game instantly reload any changes, without restarting. If you're wondering if that is as awesome as it sounds, it is.

Fathom compiles to AS3 (via .swc), so you can use AS3 too. But you don't get that awesome hotswapping stuff. 

## Cool stuff

* `SuperObjectHash` - Did you know that Haxe doesn't provide a cross-platform TypedDictionary? `nme.ObjectHash` comes close, but silently screws up primitive key values (so `ObjectHash<Int, String>` would be a disaster). `SuperObjectHash` is what you want.
* `Set` - A collection of unique items, with some handy high power functions.

## Tests

Fathom is also tested! How cool is that.

To run the AS3 tests, use `./as3tests`.

To run the NME tests, use `./nmetests`.
