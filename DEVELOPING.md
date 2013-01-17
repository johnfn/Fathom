# Developing

I'm going to use this document to keep track of development-related things I've been thinking about.

## starlingextensions

99% of the time Starling is perfect. That 1%, though... 

### starling.text.TextField

starling.text.TextField doesn't allow you to individually style words in a TextField, which is actually something that people like to do in games (go get the **MAGIC ORB**). So I ported it to haxe under `starlingextensions.TextField` and dropped in a callback called `textFormatCallback` that takes a `flash.text.TextField` (to format) and a `flash.text.TextFormat` (the normal text format).

I use this callback in Fathom.Text to do all that fancy formatting (when compiling to Flash, that is).
