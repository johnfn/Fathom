#if flash
import flash.geom.Point;
import starling.display.DisplayObject;
import starling.display.Stage;
import starling.events.Event;
#else
import nme.geom.Point;
import nme.display.DisplayObject;
import nme.display.Stage;
import nme.events.Event;
#end

class CameraFocusEvent extends Event {
	public static var HIT_BOUNDARY:String = 'hitBoundary';
	public static var SWAP_STARTED:String = 'swapStarted';
	public static var SWAP_FINISHED:String = 'swapFinished';
	public static var ZOOM_STARTED:String = 'zoomStarted';
	public static var ZOOM_FINISHED:String = 'zoomFinished';
	public static var SHAKE_STARTED:String = 'shakeStarted';
	public static var SHAKE_FINISHED:String = 'shakeFinished';

	public var boundary:String;

	public function new(type:String, bubbles:Bool=false) {
		super(type, bubbles);
	}
}

typedef Layer = {
	var name: String;
	var instance: Graphic;
	var ratio: Float;
	@optional var ox: Float;
	@optional var oy: Float;
}

class CameraFocus {
	public var focusTarget(getFocusTarget, setFocusTarget) : Dynamic;
	public var zoomFactor(getZoomFactor, never) : Float;
	var focusDist(getFocusDist, never) : Dynamic;
	var globalTrackerLoc(getGlobalTrackerLoc, never) : Point;

	var _stage : Stage;
	var _stageContainer : DisplayObject;
	var _focusPosition : Point;
	var _focusTracker : Point;
	var _focusOrientation : Point;
	var _focusCurrentLoc : Point;
	var _focusLastLoc : Point;
	var _focusDistX : Float;
	var _focusDistY : Float;
	var _focusTarget : Dynamic;
	var _layersInfo : SuperObjectHash<String, Layer>;
	// each object(layer) contains keys of 'name', 'instance', 'ratio'
	var _boundaryLayer : DisplayObject;
	var _switch : Bool;
	var _targetLastX : Float;
	var _targetLastY : Float;
	var _targetCurrentX : Float;
	var _targetCurrentY : Float;
	var _zoomFactor : Float;
	var _intensity : Float;
	var _shakeTimer : Int;
	var _shakeDecay : Float;
	public var trackStep : Int;
	public var swapStep : Int;
	public var zoomStep : Int;
	var _tempStep : Int;
	var _step : Int;
	public var ignoreLeftBound : Bool;
	public var ignoreRightBound : Bool;
	public var ignoreTopBound : Bool;
	public var ignoreBottomBound : Bool;
	public var isFocused : Bool;
	public var isSwaping : Bool;
	public var isZooming : Bool;
	public var isShaking : Bool;
	public var enableCallBack : Bool;
	var _boundaryEvent : CameraFocusEvent;
	var _swapStartedEvent : CameraFocusEvent;
	var _swapFinishedEvent : CameraFocusEvent;
	var _zoomStartedEvent : CameraFocusEvent;
	var _zoomFinishedEvent : CameraFocusEvent;
	var _shakeStartedEvent : CameraFocusEvent;
	var _shakeFinishedEvent : CameraFocusEvent;
	public function new(aStage : Stage, aStageContainer : DisplayObject, aFocusTarget : Dynamic, aLayersInfo : Array<Layer> = null, aAutoStart : Bool = true) {
		if (aLayersInfo == null) aLayersInfo = [];

		_stage = aStage;
		_stageContainer = aStageContainer;
		_layersInfo = new SuperObjectHash();
		focusTarget = aFocusTarget;
		_focusPosition = new Point();
		_focusTracker = new Point();
		_focusTracker.x = _focusTarget.x;
		_focusTracker.y = _focusTarget.y;
		_focusOrientation = new Point();
		_focusOrientation.x = _focusTarget.x;
		_focusOrientation.y = _focusTarget.y;
		_focusCurrentLoc = _focusTracker.clone();
		_focusLastLoc = _focusTracker.clone();
		for(obj in aLayersInfo/* AS3HX WARNING could not determine type for var: obj exp: EIdent(aLayersInfo) type: Array<Dynamic>*/) {
			obj.ox = obj.instance.x;
			obj.oy = obj.instance.y;
			_layersInfo.set(obj.name, obj);
		}

		_targetLastX = _targetCurrentX = focusTarget.x;
		_targetLastY = _targetCurrentY = focusTarget.y;
		// default step values, can be reset
		trackStep = 10;
		swapStep = 10;
		zoomStep = 10;
		_step = trackStep;
		_tempStep = trackStep;
		// default zoom factor
		_zoomFactor = _stageContainer.scaleX;
		// default focus is at the stage center
		setFocusPosition(_stage.stageWidth * .5, _stage.stageHeight * .5);
		// by default, the stage boundary is not set
		setBoundary();
		// create event instance
		_boundaryEvent = new CameraFocusEvent(CameraFocusEvent.HIT_BOUNDARY);
		_swapStartedEvent = new CameraFocusEvent(CameraFocusEvent.SWAP_STARTED);
		_swapFinishedEvent = new CameraFocusEvent(CameraFocusEvent.SWAP_FINISHED);
		_zoomStartedEvent = new CameraFocusEvent(CameraFocusEvent.ZOOM_STARTED);
		_zoomFinishedEvent = new CameraFocusEvent(CameraFocusEvent.ZOOM_FINISHED);
		_shakeStartedEvent = new CameraFocusEvent(CameraFocusEvent.SHAKE_STARTED);
		_shakeFinishedEvent = new CameraFocusEvent(CameraFocusEvent.SHAKE_FINISHED);
		if(aAutoStart)
			start()
		else pause();
	}

	public function setFocusTarget(aFocusTarget : Dynamic) : Dynamic {
		_focusTarget = aFocusTarget;
		return aFocusTarget;
	}

	public function getFocusTarget() : Dynamic {
		return _focusTarget;
	}

	public function getZoomFactor() : Float {
		return _zoomFactor;
	}

	function getFocusDist() : Dynamic {
		return {
			distX : _focusCurrentLoc.x - _focusLastLoc.x,
			distY : _focusCurrentLoc.y - _focusLastLoc.y,
		};
	}

	function getGlobalTrackerLoc() : Point {
		var loc : Point;
		if(Std.is(_focusTarget, Point)) {
			loc = _stageContainer.localToGlobal(_focusTracker);
		} else if(Std.is(_focusTarget, DisplayObject)) {
			loc = _focusTarget.parent.localToGlobal(_focusTracker);
		} else if (Std.is(_focusTarget, Entity)) untyped {
			var v:Vec = Fathom.stage.localToGlobal(_focusTarget);
			loc = new Point(v.x, v.y);
			//loc = new Point(_focusTarget.vec().x, _focusTarget.vec().y);
		} else if (Std.is(_focusTarget, Vec)) {
			var v:Vec = cast(_focusTarget, Vec);
			loc = Fathom.stage.localToGlobal(new Point(v.x, v.y));
			//loc = new Point(_focusTarget.vec().x, _focusTarget.vec().y);
		} else {
			Util.assert(false, "Unsupported type for CameraFocus to follow: " + Type.getClassName(_focusTarget));
			return null;
		}
		return loc;
	}

	public function getLayerByName(aName : String) : DisplayObject {
		return Reflect.field(_layersInfo, aName).instance;
	}

	public function start() : Void {
		_switch = true;
	}

	public function pause() : Void {
		_switch = false;
	}

	public function destroy() : Void {
		_stage = null;
		_stageContainer = null;
		_boundaryLayer = null;
		_layersInfo = null;
		focusTarget = null;
		_boundaryEvent = null;
		_swapStartedEvent = null;
		_swapFinishedEvent = null;
		_zoomStartedEvent = null;
		_zoomFinishedEvent = null;
		_shakeStartedEvent = null;
		_shakeFinishedEvent = null;
	}

	public function setFocusPosition(aX : Float, aY : Float) : Void {
		_focusPosition.x = aX;
		_focusPosition.y = aY;
	}

	public function setBoundary(aLayer : DisplayObject = null) : Void {
		_boundaryLayer = aLayer;
	}

	public function jumpToFocus(aFocusTarget : Dynamic = null) : Void {
		if(aFocusTarget == null)
			aFocusTarget = _focusTarget;
		_focusCurrentLoc.x = _focusLastLoc.x = _focusTracker.x = _focusTarget.x;
		_focusCurrentLoc.y = _focusLastLoc.y = _focusTracker.y = _focusTarget.y;
		swapFocus(aFocusTarget, 1);
	}

	public function swapFocus(aFocusTarget : Dynamic, aSwapStep : Int = 10, aZoom : Bool = false, aZoomFactor : Float = 1, aZoomStep : Int = 10) : Void {
		_focusTarget = aFocusTarget;
		swapStep = Std.int(Math.max(1, aSwapStep));
		_tempStep = trackStep;
		_step = swapStep;
		isSwaping = true;
		if(enableCallBack)
			_stage.dispatchEvent(_swapStartedEvent);
		if(aZoom)
			zoomFocus(aZoomFactor, aZoomStep);
	}

	public function zoomFocus(aZoomFactor : Float, aZoomStep : Int = 10) : Void {
		_zoomFactor = Math.max(0, aZoomFactor);
		zoomStep = Std.int(Math.max(1, aZoomStep));
		isZooming = true;
		if(enableCallBack)
			_stage.dispatchEvent(_zoomStartedEvent);
	}

	public function shake(aIntensity : Float, aShakeTimer : Int) : Void {
		_intensity = aIntensity;
		_shakeTimer = aShakeTimer;
		_shakeDecay = aIntensity / aShakeTimer;
		isShaking = true;
		if(enableCallBack)
			_stage.dispatchEvent(_shakeStartedEvent);
	}

	public function update() : Void {
		// if paused then ignore the following code
		if(!_switch)
			return;
		// if focusTarget is set to null or not existing on stage, ignore the following code
		if(_focusTarget == null)
			return;
		if(Std.is(_focusTarget, DisplayObject) && _focusTarget.parent == null)
			return;
		// detect if it is tracking behind(or swaping to) the focus target
		if (Math.round(_focusTarget.x-_focusTracker.x) == 0 && Math.round(_focusTarget.y-_focusTracker.y) == 0) {
			_tempStep = trackStep;
			_step = _tempStep;
			_focusTracker.x = _focusTarget.x;
			_focusTracker.y = _focusTarget.y;
			if(isSwaping)  {
				isSwaping = false;
				if(enableCallBack)
					_stage.dispatchEvent(_swapFinishedEvent);
			}
			isFocused = true;
		} else  {
			isFocused = false;
		}
;
		// update the location of the focusTracker
		_focusTracker.x += (_focusTarget.x - _focusTracker.x) / _step;
		_focusTracker.y += (_focusTarget.y - _focusTracker.y) / _step;
		// update the current and last tracking location
		_focusLastLoc.x = _focusCurrentLoc.x;
		_focusLastLoc.y = _focusCurrentLoc.y;
		_focusCurrentLoc.x = _focusTracker.x;
		_focusCurrentLoc.y = _focusTracker.y;
		// update the location of the focus target
		_targetLastX = _targetCurrentX;
		_targetLastY = _targetCurrentY;
		_targetCurrentX = focusTarget.x;
		_targetCurrentY = focusTarget.y;
		if(isZooming)  {
			_stageContainer.scaleX += (_zoomFactor - _stageContainer.scaleX) / zoomStep;
			_stageContainer.scaleY += (_zoomFactor - _stageContainer.scaleY) / zoomStep;
			// detect if zooming finished
			if(Math.abs(_stageContainer.scaleX - _zoomFactor) < .01)  {
				isZooming = false;
				_stageContainer.scaleX = _stageContainer.scaleY = _zoomFactor;
				if(enableCallBack)
					_stage.dispatchEvent(_zoomFinishedEvent);
			}
;
		}
		// nudge stage-container
		positionStageContainer();
		var testResult : Dynamic = testBounds();
		// adjust parallax layers
		positionParallax(testResult);
		// shake
		if(isShaking)  {
			if(_shakeTimer > 0)  {
				_shakeTimer--;
				if(_shakeTimer <= 0)  {
					_shakeTimer = 0;
					isShaking = false;
					if(enableCallBack)
						_stage.dispatchEvent(_shakeFinishedEvent);
				}

				else  {
					_intensity -= _shakeDecay;
					_stageContainer.x = Math.random() * _intensity * _stage.stageWidth * 2 - _intensity * _stage.stageWidth + _stageContainer.x;
					_stageContainer.y = Math.random() * _intensity * _stage.stageHeight * 2 - _intensity * _stage.stageHeight + _stageContainer.y;
				}

			}
		}
;
	}

	function testBounds() : Dynamic {
		var testResult : Dynamic = {
			top : false,
			bottom : false,
			left : false,
			right : false,

		};
		if(_boundaryLayer == null)
			return testResult;
		var stageBoundaryUpperLeft : Point = _boundaryLayer.parent.localToGlobal(new Point(_boundaryLayer.x, _boundaryLayer.y));
		var stageBoundaryLowerRight : Point = _boundaryLayer.parent.localToGlobal(new Point(_boundaryLayer.x + _boundaryLayer.width, _boundaryLayer.y + _boundaryLayer.height));
		var boundLeft : Float = stageBoundaryUpperLeft.x;
		var boundTop : Float = stageBoundaryUpperLeft.y;
		var boundRight : Float = stageBoundaryLowerRight.x;
		var boundBottom : Float = stageBoundaryLowerRight.y;
		//trace( 'left:'+boundLeft+',right:'+boundRight+',up:'+boundUp+',down:'+boundDown );
		if(boundLeft > 0)  {
			if(!ignoreLeftBound)  {
				_stageContainer.x += 0 - boundLeft;
			}
			if(enableCallBack)  {
				_boundaryEvent.boundary = "left";
				_stage.dispatchEvent(_boundaryEvent);
			}
			testResult.left = true;
		}
;
		if(boundRight < _stage.stageWidth)  {
			if(!ignoreRightBound)  {
				_stageContainer.x += _stage.stageWidth - boundRight;
			}
			if(enableCallBack)  {
				_boundaryEvent.boundary = "right";
				_stage.dispatchEvent(_boundaryEvent);
			}
			testResult.right = true;
		}
		if(boundTop > 0)  {
			if(!ignoreTopBound)  {
				_stageContainer.y += 0 - boundTop;
			}
			if(enableCallBack)  {
				_boundaryEvent.boundary = "top";
				_stage.dispatchEvent(_boundaryEvent);
			}
			testResult.top = true;
		}
		if(boundBottom < _stage.stageHeight)  {
			if(!ignoreBottomBound)  {
				_stageContainer.y += _stage.stageHeight - boundBottom;
			}
			if(enableCallBack)  {
				_boundaryEvent.boundary = "bottom";
				_stage.dispatchEvent(_boundaryEvent);
			}
			testResult.bottom = true;
		}
		return testResult;
	}

	function positionStageContainer() : Void {
		_stageContainer.x += _focusPosition.x - globalTrackerLoc.x;
		_stageContainer.y += _focusPosition.y - globalTrackerLoc.y;
	}

	function positionParallax(aTestResult : Dynamic) : Void {
		var testResult : Dynamic = aTestResult;
		var layer : Graphic;
		var layerOX : Float;
		var layerOY : Float;
		var ratio : Float;
		for(value in _layersInfo.values()) {
			layer = value.instance;
			layerOX = value.ox;
			layerOY = value.oy;
			ratio = value.ratio;
			var distX : Float = (_focusCurrentLoc.x - _focusOrientation.x) * ratio;
			var distY : Float = (_focusCurrentLoc.y - _focusOrientation.y) * ratio;
			if((!testResult.left && distX < 0) || (!testResult.right && distX > 0))
				layer.x = layerOX + distX;
			if((!testResult.top && distY < 0) || (!testResult.bottom && distY > 0))
				layer.y = layerOY + distY;
		}

	}

	/* ----------------------------------- END --------------------------------------- */}

