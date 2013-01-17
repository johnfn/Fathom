package starlingextensions;

// =================================================================================================
//
//  Starling Framework
//  Copyright 2011 Gamua OG. All Rights Reserved.
//
//  This program is free software. You can redistribute and/or modify it
//  in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

// This code is a modified version of code from the Starling framework. That means it's BSD licensed.

import flash.display.BitmapData;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.text.AntiAliasType;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.utils.Dictionary;
import flash.filters.BitmapFilter;
import starling.core.RenderSupport;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;
import starling.display.Image;
import starling.display.Quad;
import starling.display.QuadBatch;
import starling.display.Sprite;
import starling.events.Event;
import starling.textures.Texture;
import starling.utils.HAlign;
import starling.utils.VAlign;
import starling.text.BitmapFont;

/** A TextField displays text, either using standard true type fonts or custom bitmap fonts.
 *
 *  <p>You can set all properties you are used to, like the font name and size, a color, the
 *  horizontal and vertical alignment, etc. The border property is helpful during development,
 *  because it lets you see the bounds of the textfield.</p>
 *
 *  <p>There are two types of fonts that can be displayed:</p>
 *
 *  <ul>
 *    <li>Standard true type fonts. This renders the text just like a conventional Flash
 *        TextField. It is recommended to embed the font, since you cannot be sure which fonts
 *        are available on the client system, and since this enhances rendering quality.
 *        Simply pass the font name to the corresponding property.</li>
 *    <li>Bitmap fonts. If you need speed or fancy font effects, use a bitmap font instead.
 *        That is a font that has its glyphs rendered to a texture atlas. To use it, first
 *        register the font with the method <code>registerBitmapFont</code>, and then pass
 *        the font name to the corresponding property of the text field.</li>
 *  </ul>
 *
 *  For bitmap fonts, we recommend one of the following tools:
 *
 *  <ul>
 *    <li>Windows: <a href="http://www.angelcode.com/products/bmfont">Bitmap Font Generator</a>
 *       from Angel Code (free). Export the font data as an XML file and the texture as a png
 *       with white characters on a transparent background (32 bit).</li>
 *    <li>Mac OS: <a href="http://glyphdesigner.71squared.com">Glyph Designer</a> from
 *        71squared or <a href="http://http://www.bmglyph.com">bmGlyph</a> (both commercial).
 *        They support Starling natively.</li>
 *  </ul>
 */

 typedef ColorSegment = {
   var start: Int;
   var end: Int;
   var color: Int;

   // Necessary so that if they then change the accent color, we
   // can retroactively update.
   var accentDefault: Bool;
 }

class ColoredText extends DisplayObjectContainer {
  public var textBounds(getTextBounds, never) : Rectangle;
  public var text(getText, setText) : String;
  public var fontName(getFontName, setFontName) : String;
  public var fontSize(getFontSize, setFontSize) : Float;
  public var color(getColor, setColor) : UInt;
  public var hAlign(getHAlign, setHAlign) : String;
  public var vAlign(getVAlign, setVAlign) : String;
  public var border(getBorder, setBorder) : Bool;
  public var bold(getBold, setBold) : Bool;
  public var italic(getItalic, setItalic) : Bool;
  public var underline(getUnderline, setUnderline) : Bool;
  public var kerning(getKerning, setKerning) : Bool;
  public var autoScale(getAutoScale, setAutoScale) : Bool;
  public var nativeFilters(getNativeFilters, setNativeFilters) : Array<BitmapFilter>;
  public var accentColor: Int = 0xff0000;
  static var bitmapFonts(getBitmapFonts, never) : Dictionary;

  // the name container with the registered bitmap fonts
  static inline var BITMAP_FONT_DATA_NAME : String = "starling.ColoredText.BitmapFonts";
  var mFontSize : Float;
  var mColor : UInt;
  var mText : String;
  var mFontName : String;
  var mHAlign : String;
  var mVAlign : String;
  var mBold : Bool;
  var mItalic : Bool;
  var mUnderline : Bool;
  var mAutoScale : Bool;
  var mKerning : Bool;
  var mNativeFilters : Array<BitmapFilter>;
  var mRequiresRedraw : Bool;
  var mIsRenderedText : Bool;
  var mTextBounds : Rectangle;
  var mHitArea : DisplayObject;
  var mBorder : DisplayObjectContainer;
  var mImage : Image;
  var mQuadBatch : QuadBatch;

  var pairs: Array<ColorSegment>;

  // this object will be used for text rendering
  static var sNativeTextField : flash.text.TextField = new flash.text.TextField();
  /** Create a new text field with the given properties. */
  public function new(width : Int, height : Int, text : String, fontName : String = "Verdana", fontSize : Float = 12, color : UInt = 0x0, bold : Bool = false) {
    super();

    pairs = [];
    this.text = (text != null) ? text : "";
    mFontSize = fontSize;
    mColor = color;
    mHAlign = HAlign.CENTER;
    mVAlign = VAlign.CENTER;
    mBorder = null;
    mKerning = true;
    mBold = bold;
    this.fontName = fontName;
    mHitArea = new Quad(width, height);
    mHitArea.alpha = 0.0;
    addChild(mHitArea);
    addEventListener(Event.FLATTEN, onFlatten);
  }

  /** Disposes the underlying texture data. */
  override public function dispose() : Void {
    removeEventListener(Event.FLATTEN, onFlatten);
    if(mImage != null)
      mImage.texture.dispose();
    if(mQuadBatch != null)
      mQuadBatch.dispose();
    super.dispose();
  }

  function onFlatten() : Void {
    if(mRequiresRedraw)
      redrawContents();
  }

  /** @inheritDoc */
  override public function render(support : RenderSupport, parentAlpha : Float) : Void {
    if(mRequiresRedraw)
      redrawContents();
    super.render(support, parentAlpha);
  }

  function redrawContents() : Void {
    if(mIsRenderedText)
      createRenderedContents()
    else createComposedContents();
    mRequiresRedraw = false;
  }

  function strToAlign(s: String): flash.text.TextFormatAlign {
    if (s.toLowerCase() == "left") {
      return flash.text.TextFormatAlign.LEFT;
    }

    if (s.toLowerCase() == "right") {
      return flash.text.TextFormatAlign.RIGHT;
    }

    if (s.toLowerCase() == "center") {
      return flash.text.TextFormatAlign.CENTER;
    }

    throw "Woops, that HAlign is not supported.";
    return flash.text.TextFormatAlign.LEFT;
  }

  function createRenderedContents() : Void {
    if(mQuadBatch != null)  {
      mQuadBatch.removeFromParent(true);
      mQuadBatch = null;
    }
    var scale : Float = Starling.contentScaleFactor;
    var width : Float = mHitArea.width * scale;
    var height : Float = mHitArea.height * scale;
    var textFormat : TextFormat = new TextFormat();
    {
      textFormat.font = mFontName;
      textFormat.size = mFontSize * scale;
      textFormat.color = mColor;
      textFormat.bold = mBold;
      textFormat.italic = mItalic;
      textFormat.underline = mUnderline;
      textFormat.align = strToAlign(mHAlign);
    }
    textFormat.kerning = mKerning;
    sNativeTextField.defaultTextFormat = textFormat;
    sNativeTextField.width = width;
    sNativeTextField.height = height;
    sNativeTextField.antiAliasType = AntiAliasType.ADVANCED;
    sNativeTextField.selectable = false;
    sNativeTextField.multiline = true;
    sNativeTextField.wordWrap = true;
    sNativeTextField.text = mText;
    sNativeTextField.embedFonts = true;
    sNativeTextField.filters = mNativeFilters;

    for (pair in pairs) {
      textFormat.color = pair.color;
      if (pair.accentDefault) {
        textFormat.color = accentColor;
      }
      sNativeTextField.setTextFormat(textFormat, pair.start, pair.end);
    }

    // we try embedded fonts first, non-embedded fonts are just a fallback
    if(sNativeTextField.textWidth == 0.0 || sNativeTextField.textHeight == 0.0)
      sNativeTextField.embedFonts = false;
    if(mAutoScale)
      autoScaleNativeTextField(sNativeTextField);
    var textWidth : Float = sNativeTextField.textWidth;
    var textHeight : Float = sNativeTextField.textHeight;
    var xOffset : Float = 0.0;
    if(mHAlign == HAlign.LEFT)
      xOffset = 2
    else // flash adds a 2 pixel offset
    if(mHAlign == HAlign.CENTER)
      xOffset = (width - textWidth) / 2.0
    else if(mHAlign == HAlign.RIGHT)
      xOffset = width - textWidth - 2;
    var yOffset : Float = 0.0;
    if(mVAlign == VAlign.TOP)
      yOffset = 2
    else // flash adds a 2 pixel offset
    if(mVAlign == VAlign.CENTER)
      yOffset = (height - textHeight) / 2.0
    else if(mVAlign == VAlign.BOTTOM)
      yOffset = height - textHeight - 2;

    var bitmapData : BitmapData = new BitmapData(Std.int(width), Std.int(height), true, 0x0);
    bitmapData.draw(sNativeTextField, new Matrix(1, 0, 0, 1, 0, Std.int(yOffset) - 2));
    sNativeTextField.text = "";
    // update textBounds rectangle
    if (mTextBounds == null)
      mTextBounds = new Rectangle();
    mTextBounds.setTo(xOffset / scale, yOffset / scale, textWidth / scale, textHeight / scale);
    var texture : Texture = Texture.fromBitmapData(bitmapData, false, false, scale);
    if (mImage == null) {
      mImage = new Image(texture);
      mImage.touchable = false;
      addChild(mImage);
    } else {
      mImage.texture.dispose();
      mImage.texture = texture;
      mImage.readjustSize();
    }
  }

  function autoScaleNativeTextField(textField : flash.text.TextField) : Void {
    var size : Float = textField.defaultTextFormat.size;
    var maxHeight : Int = Std.int(textField.height - 4);
    var maxWidth : Int = Std.int(textField.width - 4);
    while(textField.textWidth > maxWidth || textField.textHeight > maxHeight) {
      if(size <= 4)
        break;
      var format : TextFormat = textField.defaultTextFormat;
      format.size = size--;
      textField.setTextFormat(format);
    }

  }

  function createComposedContents() : Void {
    if(mImage != null) {
      mImage.removeFromParent(true);
      mImage = null;
    }
    if(mQuadBatch == null)  {
      mQuadBatch = new QuadBatch();
      mQuadBatch.touchable = false;
      addChild(mQuadBatch);
    }

    else mQuadBatch.reset();
    var bitmapFont : BitmapFont = Reflect.field(bitmapFonts, mFontName);
    if(bitmapFont == null)
      throw ("Bitmap font not registered: " + mFontName);
    bitmapFont.fillQuadBatch(mQuadBatch, mHitArea.width, mHitArea.height, mText, mFontSize, mColor, mHAlign, mVAlign, mAutoScale, mKerning);
    mTextBounds = null;
  }

  function updateBorder() : Void {
    if(mBorder == null)
      return;
    var width : Float = mHitArea.width;
    var height : Float = mHitArea.height;
    var topLine : Quad = try cast(mBorder.getChildAt(0), Quad) catch(e:Dynamic) null;
    var rightLine : Quad = try cast(mBorder.getChildAt(1), Quad) catch(e:Dynamic) null;
    var bottomLine : Quad = try cast(mBorder.getChildAt(2), Quad) catch(e:Dynamic) null;
    var leftLine : Quad = try cast(mBorder.getChildAt(3), Quad) catch(e:Dynamic) null;
    topLine.width = width;
    topLine.height = 1;
    bottomLine.width = width;
    bottomLine.height = 1;
    leftLine.width = 1;
    leftLine.height = height;
    rightLine.width = 1;
    rightLine.height = height;
    rightLine.x = width - 1;
    bottomLine.y = height - 1;
    topLine.color = rightLine.color = bottomLine.color = leftLine.color = mColor;
  }

  /** Returns the bounds of the text within the text field. */
  public function getTextBounds() : Rectangle {
    if(mRequiresRedraw)
      redrawContents();
    if(mTextBounds == null)
      mTextBounds = mQuadBatch.getBounds(mQuadBatch);
    return mTextBounds.clone();
  }

  /** @inheritDoc */
  override public function getBounds(targetSpace : DisplayObject, resultRect : Rectangle = null) : Rectangle {
    return mHitArea.getBounds(targetSpace, resultRect);
  }

  /** @inheritDoc */
  public function setWidth(value : Float) : Float {
    // different to ordinary display objects, changing the size of the text field should
    // not change the scaling, but make the texture bigger/smaller, while the size
    // of the text/font stays the same (this applies to the height, as well).
    mHitArea.width = value;
    mRequiresRedraw = true;
    updateBorder();
    return value;
  }

  /** @inheritDoc */
  public function setHeight(value : Float) : Float {
    mHitArea.height = value;
    mRequiresRedraw = true;
    updateBorder();
    return value;
  }

  /** The displayed text. */
  public function getText() : String {
    return mText;
  }

  public function setText(value : String) : String {
    if(value == null)
      value = "";

    if(mText != value)  {
      pairs = [];

      var isDefaultAccentColor: Bool = true;
      var currentColor: Int = accentColor;
      var r: EReg = ~/\*|\{([0-9]+)[\s]*,[\s]*([0-9]+)[\s]*,[\s]*([0-9]+)\}/;
      var currentPair: ColorSegment = { start: -1, end: -1, color: currentColor, accentDefault: isDefaultAccentColor };

      var resultText: String = value;

      while (r.match(resultText)) {
        var loc: Int = r.matchedPos().pos;

        if (r.matched(0) == "*") {
          if (currentPair.start == -1) {
            currentPair.start = loc;
          } else {
            currentPair.end = loc;
            pairs.push(currentPair);
            currentPair = { start: -1, end: -1, color: currentColor, accentDefault: isDefaultAccentColor };
          }
        } else {
          currentColor = new Color(Std.parseInt(r.matched(1))
                                 , Std.parseInt(r.matched(2))
                                 , Std.parseInt(r.matched(3))).toInt();
          currentPair.color = currentColor;
          isDefaultAccentColor = false;
          currentPair.accentDefault = false;
        }

        resultText = r.replace(resultText, "");
      }


      /*
      var idx : Int = 0;
      var resultString : String = "";
      for (i in 0...value.length) {
          idx++;
          if(value.charAt(i) == "*")  {
            idx--;

          } else  {
            resultString += value.charAt(i);
          }
      }

      */
      mText = resultText;
      mRequiresRedraw = true;
    }
    return value;
  }

  /** The name of the font (true type or bitmap font). */
  public function getFontName() : String {
    return mFontName;
  }

  public function setFontName(value : String) : String {
    if(mFontName != value)  {
      if(value == BitmapFont.MINI && Reflect.field(bitmapFonts, value) == null)
        registerBitmapFont(new BitmapFont());
      mFontName = value;
      mRequiresRedraw = true;
      mIsRenderedText = Reflect.field(bitmapFonts, value) == null;
    }
    return value;
  }

  /** The size of the font. For bitmap fonts, use <code>BitmapFont.NATIVE_SIZE</code> for
         *  the original size. */
  public function getFontSize() : Float {
    return mFontSize;
  }

  public function setFontSize(value : Float) : Float {
    if(mFontSize != value)  {
      mFontSize = value;
      mRequiresRedraw = true;
    }
    return value;
  }

  /** The color of the text. For bitmap fonts, use <code>Color.WHITE</code> to use the
   *  original, untinted color. @default black */
  public function getColor() : UInt {
    return mColor;
  }

  public function setColor(value : UInt) : UInt {
    if(mColor != value)  {
      mColor = value;
      updateBorder();
      mRequiresRedraw = true;
    }
    return value;
  }

  /** The horizontal alignment of the text. @default center @see starling.utils.HAlign */
  public function getHAlign() : String {
    return mHAlign;
  }

  public function setHAlign(value : String) : String {
    if(!HAlign.isValid(value))
      throw ("Invalid horizontal align: " + value);
    if(mHAlign != value)  {
      mHAlign = value;
      mRequiresRedraw = true;
    }
    return value;
  }

  /** The vertical alignment of the text. @default center @see starling.utils.VAlign */
  public function getVAlign() : String {
    return mVAlign;
  }

  public function setVAlign(value : String) : String {
    if(!VAlign.isValid(value))
      throw ("Invalid vertical align: " + value);
    if(mVAlign != value)  {
      mVAlign = value;
      mRequiresRedraw = true;
    }
    return value;
  }

  /** Draws a border around the edges of the text field. Useful for visual debugging.
   *  @default false */
  public function getBorder() : Bool {
    return mBorder != null;
  }

  public function setBorder(value : Bool) : Bool {
    if(value && mBorder == null)  {
      mBorder = new Sprite();
      addChild(mBorder);
      var i : Int = 0;
      while(i < 4) {
        mBorder.addChild(new Quad(1.0, 1.0));
        ++i;
      }
      updateBorder();
    }

    else if(!value && mBorder != null)  {
      mBorder.removeFromParent(true);
      mBorder = null;
    }
    return value;
  }

  /** Indicates whether the text is bold. @default false */
  public function getBold() : Bool {
    return mBold;
  }

  public function setBold(value : Bool) : Bool {
    if(mBold != value)  {
      mBold = value;
      mRequiresRedraw = true;
    }
    return value;
  }

  /** Indicates whether the text is italicized. @default false */
  public function getItalic() : Bool {
    return mItalic;
  }

  public function setItalic(value : Bool) : Bool {
    if(mItalic != value)  {
      mItalic = value;
      mRequiresRedraw = true;
    }
    return value;
  }

  /** Indicates whether the text is underlined. @default false */
  public function getUnderline() : Bool {
    return mUnderline;
  }

  public function setUnderline(value : Bool) : Bool {
    if(mUnderline != value)  {
      mUnderline = value;
      mRequiresRedraw = true;
    }
    return value;
  }

  /** Indicates whether kerning is enabled. @default true */
  public function getKerning() : Bool {
    return mKerning;
  }

  public function setKerning(value : Bool) : Bool {
    if(mKerning != value)  {
      mKerning = value;
      mRequiresRedraw = true;
    }
    return value;
  }

  /** Indicates whether the font size is scaled down so that the complete text fits
   *  into the text field. @default false */
  public function getAutoScale() : Bool {
    return mAutoScale;
  }

  public function setAutoScale(value : Bool) : Bool {
    if(mAutoScale != value)  {
      mAutoScale = value;
      mRequiresRedraw = true;
    }
    return value;
  }

  /** The native Flash BitmapFilters to apply to this TextField.
   *  Only available when using standard (TrueType) fonts! */
  public function getNativeFilters() : Array<BitmapFilter> {
    return mNativeFilters;
  }

  public function setNativeFilters(value : Array<BitmapFilter>) : Array<BitmapFilter> {
    if(!mIsRenderedText)
      throw ("The TextField.nativeFilters property cannot be used on Bitmap fonts.");
    mNativeFilters = value.concat([]);
    mRequiresRedraw = true;
    return value;
  }

  /** Makes a bitmap font available at any text field, identified by its <code>name</code>.
   *  Per default, the <code>name</code> property of the bitmap font will be used, but you
   *  can pass a custom name, as well. @returns the name of the font. */
  static public function registerBitmapFont(bitmapFont : BitmapFont, name : String = null) : String {
    if(name == null)
      name = bitmapFont.name;
    Reflect.setField(bitmapFonts, name, bitmapFont);
    return name;
  }

  /** Unregisters the bitmap font and, optionally, disposes it. */
  static public function unregisterBitmapFont(name : String, dispose : Bool = true) : Void {
    if(dispose && Reflect.field(bitmapFonts, name) != null)
      Reflect.field(bitmapFonts, name).dispose();
    untyped __delete__(bitmapFonts, name);
  }

  /** Returns a registered bitmap font (or null, if the font has not been registered). */
  static public function getBitmapFont(name : String) : BitmapFont {
    return Reflect.field(bitmapFonts, name);
  }

  /** Stores the currently available bitmap fonts. Since a bitmap font will only work
   *  in one Starling instance, they are saved in Starling's 'customData' property. */
  static function getBitmapFonts() : Dictionary {
    var fonts : Dictionary = try cast(Reflect.getProperty(Starling.current.customData, BITMAP_FONT_DATA_NAME), Dictionary) catch(e:Dynamic) null;
    if(fonts == null)  {
      fonts = new Dictionary();
      Reflect.setField(Starling.current.customData, BITMAP_FONT_DATA_NAME, fonts);
    }
    return fonts;
  }
}

