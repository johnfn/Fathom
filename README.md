# Fathom

Hi. Fathom is a game development library, currently being developed for Haxe. It compiles to Flash and C++.

**Fathom is under heavy development. Expect brokenness until this message goes away. Of course, if you want to help, just let me know. There's lots to do.**

On the Flash side of things, you get a game engine backed by [Starling](https://github.com/PrimaryFeather/Starling-Framework), an awesome graphics library that uses Stage3D. That means we have blazing fast graphics. I'm not being superlative, it's pretty ridiculous. The GPU acceleration means that you need to have tens of thousands of Sprites to see the framerate even dip below 60FPS.

On the NME side, we take advantage of the desktop environment. Here, we reload data automatically when it is changed. You can change images or map data files without having to restart the game - all you have to do is press `r`. Saving in Photoshop will make the game instantly reload any changes, without restarting. If you're wondering if that is as awesome as it sounds, it is. I'll gradually be pushing for more assets to be developed outside of Haxe (think cinematic files, backgrounds etc.) so that designing and testing can happen in tandem.

Fathom compiles to AS3 (via .swc), so you can use AS3 too. But you don't get that awesome hotswapping stuff. 

## Cool stuff

* `SuperObjectHash` - Did you know that Haxe doesn't provide a cross-platform TypedDictionary? `nme.ObjectHash` comes close, but silently screws up primitive key values (so `ObjectHash<Int, String>` would be a disaster). `SuperObjectHash` is what you want.
* `Set` - A collection of unique items, with some handy high power functions.

## Developing?

If you want to develop on Fathom, awesome! There are some things I think you should know. [Go here.](Fathom/blob/master/DEVELOPING.md)

### Tests

Fathom is also tested! How cool is that.

To run the AS3 tests, use `./as3test`.

To run the NME tests, use `./nmetest`.

### License

Fathom is licensed under the MIT license. That means you can do whatever you want with it, so long as you keep the LICENSE file intact.

## Credits

There's no way that Fathom could have come together without the open source contributions of awesome developers.

* `CameraFocus` thanks to [joeonmars](https://github.com/joeonmars/CameraFocus)
* `Starling` thanks to the guys at [PrimaryFeather/Gamua](https://github.com/PrimaryFeather/Starling-Framework)
* `ObjectHash` thanks to [fermmmtools](https://code.google.com/p/fermmmtools/source/browse/Haxe/com/fermmmtools/utils/ObjectHash.hx)
* `haxe.unit` extensions thanks to [a super cool dude](https://github.com/johnfn/haxe.unit)
