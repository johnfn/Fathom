package;
 
import neko.FileSystem;
import neko.Lib;
import neko.Sys;
 
using StringTools;
using As3ToHaxe;
 
/**
 * Simple Program which iterates -from folder, finds .mtt templates and compiles them to the -to folder
 */
class As3ToHaxe
{
        public static inline var keys = ["-from", "-to", "-remove"];
       
        var to:String;
        var from:String;
        var remove:String;
        var sysargs:Array<String>;
       
        var items:Array<String>;
       
        public static var basePackage:String = "away3d";
       
        private var nameSpaces:Hash<Ns>;
        private var maxLoop:Int;
       
        static function main()
        {
                new As3ToHaxe();
        }
       
        public function new()
        {
                maxLoop = 1000;
               
                if (parseArgs())
                {
               
                        // make sure that the to directory exists
                        if (!FileSystem.exists(to)) FileSystem.createDirectory(to);
                       
                        // delete old files
                        if (remove == "true")
                                removeDirectory(to);
                       
                        items = [];
                        // fill items
                        recurse(from);
 
                        // to remember namespaces
                        nameSpaces = new Hash();
                       
                        for (item in items)
                        {
                                // make sure we only work wtih AS fiels
                                var ext = getExt(item);
                                switch(ext)
                                {
                                        case "as":
                                                doConversion(item);
                                }
                        }
                       
                        // build namespace files
                        buildNameSpaces();
                }
        }
       
        private function doConversion(file:String):Void
        {              
                var fromFile = file;
                var toFile = to + "/" + file.substr(from.length + 1, file.lastIndexOf(".") - (from.length)) + "hx";
               
                var rF = "";
                var rC = "";
               
                var b = 0;
               
                // create the folder if it doesn''t exist
                var dir = toFile.substr(0, toFile.lastIndexOf("/"));
                createFolder(dir);
               
                var s = neko.io.File.getContent(fromFile);
               
                // spacse to tabs
                s = quickRegR(s, "    ", "\t");
                // undent
                s = quickRegR(s, "\t\t", "\t");
               
                // some quick setup, finding what we''ve got
                var className = quickRegM(s, "public class([ ]*)([A-Z][a-zA-Z0-9_]*)", 2)[1];
                var hasVectors = (quickRegM(s, "Vector([ ]*)\\.([ ]*)<([ ]*)([^>]*)([ ]*)>").length != 0);
 
                // package
                s = quickRegR(s, "package ([a-zA-Z\\.0-9-_]*)([ \n\r]*){", "package $1;\n", "gs");
                // remove last
                s = quickRegR(s, "\\}([\n\r\t ]*)\\}([\n\r\t ]*)$", "}", "gs");
 
                // extra indentation
                s = quickRegR(s, "\n\t", "\n");
               
                // class
                s = quickRegR(s, "public class", "class");
 
                // constructor
                s = quickRegR(s, "function " + className, "function new");
                       
                // simple typing
                s = quickRegR(s, ":([ ]*)void", ":$1Void");
                s = quickRegR(s, ":([ ]*)Boolean", ":$1Bool");
                s = quickRegR(s, ":([ ]*)int", ":$1Int");
                s = quickRegR(s, ":([ ]*)uint", ":$1UInt");
                s = quickRegR(s, ":([ ]*)Number", ":$1Float");
                s = quickRegR(s, ":([ ]*)\\*", ":$1Dynamic");
               
                s = quickRegR(s, "<Number>", "<Float>");
                s = quickRegR(s, "<int>", "<Int>");
                s = quickRegR(s, "<uint>", "<UInt>");
                s = quickRegR(s, "<Boolean>", "<Bool>");
               
                // vector
                // definition
                s = quickRegR(s, "Vector([ ]*)\\.([ ]*)<([ ]*)([^>]*)([ ]*)>", "Vector<$3$4$5>");
                // new (including removing stupid spaces)
                s = quickRegR(s, "new Vector([ ]*)([ ]*)<([ ]*)([^>]*)([ ]*)>([ ]*)\\(([ ]*)\\)([ ]*)", "new Vector()");
                // and import if we have to
                if (hasVectors) {
                        s = quickRegR(s, "class([ ]*)(" + className + ")", "import flash.Vector;\n\nclass$1$2");
                }
               
                // array
                s = quickRegR(s, " Array([ ]*);", " Array<Dynamic>;");
               
                // remap protected -> private & internal -> private
                s = quickRegR(s, "protected var", "private var");
                s = quickRegR(s, "internal var", "private var");
                s = quickRegR(s, "protected function", "private function");
                s = quickRegR(s, "internal function", "private function");
 
                /* -----------------------------------------------------------*/
                // namespaces
                // find which namespaces are used in this class
                var r = new EReg("([^#])use([ ]+)namespace([ ]+)([a-zA-Z-]+)([ ]*);", "g");
                b = 0;
                while (true) {
                        b++; if (b > maxLoop) { logLoopError("namespaces find", file); break; }
                        if (r.match(s)) {
                                var ns:Ns = {
                                        name : r.matched(4),
                                        classDefs : new Hash()
                                };
                                nameSpaces.set(ns.name, ns);
                                s = r.replace(s, "//" + r.matched(0).replace("use", "#use") + "\nusing " + basePackage + ".namespace." + ns.name.fUpper() +  ";");
                        }else {
                                break;
                        }
                }
               
                // collect all namespace definitions
                // replace them with private
                for (k in nameSpaces.keys()) {
                        var n = nameSpaces.get(k);
                        b = 0;
                        while (true) {
                                b++; if (b > maxLoop) { logLoopError("namespaces collect/replace var", file); break; }
                                // vars
                                var r = new EReg(n.name + "([ ]+)var([ ]+)", "g");
                                s = r.replace(s, "private$1var$2");
                                if (!r.match(s)) break;
                        }
                        b = 0;
                        while (true) {
                                b++; if (b > maxLoop) { logLoopError("namespaces collect/replace func", file); break; }
                                // funcs
                                var matched:Bool = false;
                                var r = new EReg(n.name + "([ ]+)function([ ]+)", "g");
                                if (r.match(s)) matched = true;
                                s = r.replace(s, "private$1function$2");
                                r = new EReg(n.name + "([ ]+)function([ ]+)get([ ]+)", "g");
                                if (r.match(s)) matched = true;
                                s = r.replace(s, "private$1function$2get$3");
                                r = new EReg(n.name + "([ ]+)function([ ]+)set([ ]+)", "g");
                                if (r.match(s)) matched = true;
                                s = r.replace(s, "private$1function$2$3set");
                                if (!matched) break;
                        }
                }
               
                /* -----------------------------------------------------------*/
                // change const to inline statics
                s = quickRegR(s, "([\n\t ]+)(public|private)([ ]*)const([ ]+)([a-zA-Z0-9_]+)([ ]*):", "$1$2$3static inline var$4$5$6:");
                s = quickRegR(s, "([\n\t ]+)(public|private)([ ]*)(static)*([ ]+)const([ ]+)([a-zA-Z0-9_]+)([ ]*):", "$1$2$3$4$5inline var$6$7$8:");
               
                /* -----------------------------------------------------------*/
                // move variables being set from var def to top of constructor
                // do NOT do this for const
                // if they're static, leave them there
                // TODO!
               
                /* -----------------------------------------------------------*/
                // Error > flash.Error
                // if " Error (" then add "import flash.Error" to head
                var r = new EReg("([ ]+)new([ ]+)Error([ ]*)\\(", "");
                if (r.match(s))
                        s = quickRegR(s, "class([ ]*)(" + className + ")", "import flash.Error;\n\nclass$1$2");
               
                /* -----------------------------------------------------------*/
 
                // create getters and setters
                b = 0;
                while (true) {
                        b++;
                        var d = { get: null, set: null, type: null, ppg: null, pps: null, name: null };
                       
                        // get
                        var r = new EReg("([\n\t ]+)([a-z]+)([ ]*)function([ ]*)get([ ]+)([a-zA-Z_][a-zA-Z0-9_]+)([ ]*)\\(([ ]*)\\)([ ]*):([ ]*)([A-Z][a-zA-Z0-9_]*)", "");
                        var m = r.match(s);
                        if (m) {
                                d.ppg = r.matched(2);
                                if (d.ppg == "") d.ppg = "public";
                                d.name = r.matched(6);
                                d.get = "get" + d.name.substr(0, 1).toUpperCase() + d.name.substr(1);
                                d.type = r.matched(11);
                        }
                       
                        // set
                        var r = new EReg("([\n\t ]+)([a-z]+)([ ]*)function([ ]*)set([ ]+)([a-zA-Z_][a-zA-Z0-9_]*)([ ]*)\\(([ ]*)([a-zA-Z][a-zA-Z0-9_]*)([ ]*):([ ]*)([a-zA-Z][a-zA-Z0-9_]*)", "");
                        var m = r.match(s);
                        if (m) {
                                if (r.matched(6) == d.get || d.get == null)
                                        if (d.name == null) d.name = r.matched(6);
                                d.pps = r.matched(2);
                                if (d.pps == "") d.pps = "public";
                                d.set = "set" + d.name.substr(0, 1).toUpperCase() + d.name.substr(1);
                                if (d.type == null) d.type = r.matched(12);
                        }
                       
                        // ERROR
                        if (b > maxLoop) { logLoopError("getter/setter: " + d, file); break; }
 
                        // replace get
                        if (d.get != null)
                                s = quickRegR(s, d.ppg + "([ ]+)function([ ]+)get([ ]+)" + d.name, "private function " + d.get);
                       
                        // replace set
                        if (d.set != null)
                                s = quickRegR(s, d.pps + "([ ]+)function([ ]+)set([ ]+)" + d.name, "private function " + d.set);
                       
                        // make haxe getter/setter OR finish
                        if (d.get != null || d.set != null) {
                                var gs = (d.ppg != null ? d.ppg : d.pps) + " var " + d.name + "(" + d.get + ", " + d.set + "):" + d.type + ";";
                                s = quickRegR(s, "private function " + (d.get != null ? d.get : d.set), gs + "\n \tprivate function " + (d.get != null ? d.get : d.set));
                        }else {
                                break;
                        }
                }
 
                /* -----------------------------------------------------------*/
               
                // for loops (?)
                // TODO!
                //s = quickRegR(s, "for([ ]*)\\(([ ]*)var([ ]*)([A-Z][a-zA-Z0-9_]*)([.^;]*);([.^;]*);([.^\\)]*)\\)", "");
                //var t = quickRegM(s, "for([ ]*)\\(([ ]*)var([ ]*)([a-zA-Z][a-zA-Z0-9_]*)([.^;]*)", 5);
                //trace(t);
                //for (var i : Int = 0; i < len; ++i)
               
                /* -----------------------------------------------------------*/
 
                var o = neko.io.File.write(toFile, true);
                o.writeString(s);
                o.close();
               
                // use for testing on a single file
                //Sys.exit(1);
        }
       
        private function logLoopError(type:String, file:String)
        {
                trace("ERROR: " + type + " - " + file);
        }
       
        private function buildNameSpaces()
        {
                // build friend namespaces!
                trace(nameSpaces);
        }
       
        public static function quickRegR(str:String, reg:String, rep:String, ?regOpt:String = "g"):String
        {
                return new EReg(reg, regOpt).replace(str, rep);
        }
       
        public static function quickRegM(str:String, reg:String, ?numMatches:Int = 1, ?regOpt:String = "g"):Array<String>
        {
                var r = new EReg(reg, regOpt);
                var m = r.match(str);
                if (m) {
                        var a = [];
                        var i = 1;
                        while (i <= numMatches) {
                                a.push(r.matched(i));
                                i++;
                        }
                        return a;
                }
                return [];
        }
       
        private function createFolder(path:String):Void
        {
                var parts = path.split("/");
                var folder = "";
                for (part in parts)
                {
                        if (folder == "") folder += part;
                        else folder += "/" + part;
                        if (!FileSystem.exists(folder)) FileSystem.createDirectory(folder);
                }
        }
       
        private function parseArgs():Bool
        {
                // Parse args
                var args = Sys.args();
                for (i in 0...args.length)
                        if (Lambda.has(keys, args[i]))
                                Reflect.setField(this, args[i].substr(1), args[i + 1]);
                       
                // Check to see if argument is missing
                if (to == null) { Lib.println("Missing argument '-to'"); return false; }
                if (from == null) { Lib.println("Missing argument '-from'"); return false; }
               
                return true;
        }
       
        public function recurse(path:String)
        {
                var dir = FileSystem.readDirectory(path);
               
                for (item in dir)
                {
                        var s = path + "/" + item;
                        if (FileSystem.isDirectory(s))
                        {
                                recurse(s);
                        }
                        else
                        {
                                var exts = ["as"];
                                if(Lambda.has(exts, getExt(item)))
                                        items.push(s);
                        }
                }
        }
       
        public function getExt(s:String)
        {
                return s.substr(s.lastIndexOf(".") + 1).toLowerCase();
        }
       
        public function removeDirectory(d, p = null)
        {
                if (p == null) p = d;
                var dir = FileSystem.readDirectory(d);
 
                for (item in dir)
                {
                        item = p + "/" + item;
                        if (FileSystem.isDirectory(item)) {
                                removeDirectory(item);
                        }else{
                                FileSystem.deleteFile(item);
                        }
                }
               
                FileSystem.deleteDirectory(d);
        }
       
        public static function fUpper(s:String)
        {
                return s.charAt(0).toUpperCase() + s.substr(1);
        }
}
 
typedef Ns = {
        var name:String;
        var classDefs:Hash<String>;
}

