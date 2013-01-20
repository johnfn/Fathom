# Developing

I'm going to use this document to keep track of development-related things I've been thinking about.

## starlingextensions

Starling is pretty awesome, but you do have to watch out for a few minor issues.

### starling.text.TextField

Starling doesn't let you resize a TextField. Actually, it does, but what it does is just stretches out the text that was rendered to the original size. This has trickled all the way down to `fathom.Text`, which can't be resized either. The only way around it would be to destroy the old TextField and make a new one. I guess you could also rewrite TextField, but I don't like rewriting other libraries when it's not absolutely necessary.
