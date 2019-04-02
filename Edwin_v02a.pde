/*
Edwin edwin;
int aNum = 0;

void setup() {
	size(1200, 900);
	edwin = new Edwin();
	Kid someMenu = new GridMenu(50, 10, 3, new Symbol("data\\edwinButtons.sym", 2.0), new String[] { EdConst.Menus.BRUSH, EdConst.Menus.LINE, EdConst.Menus.BRUSH_SMALLER, EdConst.Menus.BRUSH_BIGGER }) {
		public void menuAction(String clicked) { 
			aNum += 1;
			println(clicked + " " + aNum);
		}
	}
	edwin.addKid(someMenu);
	//edwin.addKid(new MinesweeperGame());
}

void draw() {
	edwin.update();
	image(edwin.canvas, 0, 0);
}
*/

import java.util.Collections;
import java.util.BitSet;
import java.awt.Color;
import javax.swing.JColorChooser;
import javax.swing.JOptionPane;

void keyPressed(KeyEvent event) { edwin.handleKeyboard(event); }
void keyReleased(KeyEvent event) { edwin.handleKeyboard(event); }
void mouseMoved(MouseEvent event) { edwin.handleMouse(event); }
void mousePressed(MouseEvent event) { edwin.handleMouse(event); }
void mouseDragged(MouseEvent event) { edwin.handleMouse(event); }
void mouseReleased(MouseEvent event) { edwin.handleMouse(event); }
void mouseWheel(MouseEvent event) { edwin.handleMouse(event); }	

/**
* Edwin the art/game "engine"
* which is mostly a manager/god class
* currently in alpha...
* made by moonbaseone@hush.com
*/
class Edwin {
	PGraphics canvas;
	PFont defaultFont;
	ArrayList<Kid> kids;
	ArrayList<MouseReactive> mouseKids;
	ArrayList<KeyReactive> keyKids;
	ArrayList<Excited> activeKids;
	XY mouseInitial, mouseLast;
	int mouseWheel, mouseHeldMillis, mouseBtnBeginHoldMillis, mouseBtnHeld, mouseBtnBeginHold, mouseBtnReleased;
	boolean resetMouse;

	Edwin() {
		this(false);
	}

	Edwin(boolean editorVisible) {
		canvas = createGraphics(width, height);
		defaultFont = createFont("data\\consolas.ttf", 12);
		kids = new ArrayList<Kid>();
		mouseKids = new ArrayList<MouseReactive>();
		keyKids = new ArrayList<KeyReactive>();
		activeKids = new ArrayList<Excited>();
		mouseInitial = new XY();
		mouseLast = new XY();
		mouseWheel = mouseHeldMillis = mouseBtnBeginHoldMillis = mouseBtnHeld = mouseBtnBeginHold = mouseBtnReleased = 0;
		resetMouse = false;
		addKid(new EditorWindow(editorVisible));
	}

	void addKid(Kid kid) {
		kids.add(kid);
		if (kid instanceof MouseReactive) {
			mouseKids.add((MouseReactive)kid);
		}
		if (kid instanceof KeyReactive) {
			keyKids.add((KeyReactive)kid);
		}
		if (kid instanceof Excited) {
			activeKids.add((Excited)kid);
		}
	}

	void update() {
		if (mouseBtnHeld != 0) {
			mouseHeldMillis = millis() - mouseBtnBeginHoldMillis; //gives a more reliable figure than using mouse events to update
		}
		for (Excited kid : activeKids) {
			kid.breathe();
		}
		canvas.beginDraw();
		canvas.background(0);
		canvas.textFont(defaultFont);
		for (Kid kid : kids) {
			kid.drawSelf(canvas);
		}
		canvas.endDraw();
	}

	void handleMouse(MouseEvent event) {
		int action = event.getAction();
		if (action == MouseEvent.PRESS) { 
			mouseInitial.set(mouseX, mouseY);
			mouseBtnBeginHold = mouseBtnHeld = mouseButton;
			mouseBtnBeginHoldMillis = millis();
			mouseBtnReleased = 0;
		}
		else if (action == MouseEvent.RELEASE) {
			mouseBtnReleased = mouseBtnHeld;
			mouseBtnBeginHold = mouseBtnHeld = 0;
			resetMouse = true; //other resets need to happen after calling each MouseReactive so they can use the values first
		}
		else if (action == MouseEvent.MOVE) {
			
		}
		else if (action == MouseEvent.DRAG) {
			mouseBtnBeginHold = 0;
		}
		else if (action == MouseEvent.WHEEL) {
			mouseWheel = event.getCount(); // 1 == down (toward you), -1 == up (away from you)
		}

		//notify the kids. if they respond we assume it handled the event and we don't need to check others
		for (MouseReactive m : mouseKids) {
			if (m.mouse() != "") break; 
		}

		//wrap up
		if (resetMouse) {
			resetMouse = false;
			mouseHeldMillis = 0;
			mouseBtnReleased = 0;
			//mouseInitial.set(mouseX, mouseY);
		}
		mouseLast.set(mouseX, mouseY);
		mouseWheel = 0;
	}

	/**
	* Keyboard interactions are complicated
	* so each Kid will get handed the event and let them react
	*/
	void handleKeyboard(KeyEvent event) {
		for (KeyReactive kid : keyKids) {
			if (kid.keyboard(event) != "") break;
		}
	}

} //end Edwin


/**
* I started off trying to implement an Entity Component System 
*/
interface Kid {
	void drawSelf(PGraphics canvas);
	String getName();
	//boolean hasComponent(Component comp); 
}
//interface Component { } //not really useful atm
interface MouseReactive { String mouse(); }
interface KeyReactive { String keyboard(KeyEvent event); }
interface Excited { void breathe(); } //called before drawSelf() so it doesn't really do much yet. Maybe later I could put these in a separate thread for updating

/** A kind of sprite */
class Symbol {
	PGraphics[] expressions; //images
	IntDict exprKeys;
	int pixelW, pixelH;
	float w, h, scale;

	Symbol(String filename) {
		this(filename, 1.0);
	}

	Symbol(String filename, float s) {
		//println("loading Symbol from file " + filename);
		JSONObject json = loadJSONObject(filename);
		JSONArray allLayers = json.getJSONArray(EdConst.Files.LAYERS);
		JSONArray colorPalette = json.getJSONArray(EdConst.Files.COLOR_PALETTE);
		JSONObject jsonExpr = json.getJSONObject(EdConst.Files.EXPRESSIONS);
		pixelW = json.getInt(EdConst.Files.PX_WIDTH);
		pixelH = json.getInt(EdConst.Files.PX_HEIGHT);
		scale = s;
		w = pixelW * scale;
		h = pixelH * scale;
		exprKeys = new IntDict();
		expressions = new PGraphics[jsonExpr.keys().size()];
		int c = 0, x = 0, y = 0; //x is calculated using y, which is why I can't use a XY
		float bump = scale % 1; //i dunno, helps close pixels when scale has a fraction
		//loop through each expression and draw it
		for (Object keyName : jsonExpr.keys()) {
			PGraphics expr = createGraphics((int)w, (int)h);
			expr.beginDraw();
			expr.noStroke();
			if (!json.isNull(EdConst.Files.BGD_COLOR)) {
				expr.background(json.getInt(EdConst.Files.BGD_COLOR));
			}
			//loop through each layer in the expression
			for (int expIndex : jsonExpr.getJSONArray(keyName.toString()).getIntArray()) {
				JSONObject thisLayer = allLayers.getJSONObject(expIndex);
				expr.fill(colorPalette.getInt(thisLayer.getInt(EdConst.Files.PALETTE_INDEX)));
				//draw layer to current expression
				for (int v : thisLayer.getJSONArray(EdConst.Files.DOTS).getIntArray()) {
					y = (int)(v / (float)pixelW);
					x = v - (y * pixelW);
					//expr.point(x, y);
					expr.rect(x * scale, y * scale, scale + bump, scale + bump);
				}
			}
			expr.endDraw();
			exprKeys.set(keyName.toString(), c);
			expressions[c++] = expr;
		}
	}

	PGraphics expr(String keyName) {
		return expressions[exprKeys.get(keyName, 0)];
	}
}

// ===================================
// HELPERS
// ===================================

/** 
* Give this function an octave count and it will give you perlin noise
* with the max number of points you can have with that number of octaves.
* See https://www.youtube.com/watch?v=6-0UaeJBumA
*/
float[] perlinNoise1D(int octaves) {
	int count, pitch, sample1, sample2;
	float noiseVal, scale, scaleAcc, scaleBias, blend;
	count = (int)pow(2, octaves);
	scaleBias = 2.0; //2 is standard. lower = more pronounced peaks

	float[] seedArray, values;
	seedArray = new float[count];
	for (int i = 0; i < seedArray.length; i++) {
		seedArray[i] = random(1);
	}

	values = new float[count];
	for (int x = 0; x < count; x++) {
		scale = 1;
		scaleAcc = 0;
		noiseVal = 0;
		for (int o = 0; o < octaves; o++) {
			pitch = count >> o;
			sample1 = (x / pitch) * pitch;
			sample2 = (sample1 + pitch) % count;
			blend = (x - sample1) / (float)pitch;
			noiseVal += scale * ((1 - blend) * seedArray[sample1] + blend * seedArray[sample2]);
			scaleAcc += scale;
			scale /= scaleBias;
		}
		values[x] = noiseVal / scaleAcc;
		//println(values[x]);
	}
	//println("len:" + values.length +"  0:" + values[0] + "  max:" + values[values.length - 1]);
	return values;
}

/** A class for keeping track of a positive integer that has a minimum and a maximum. */
class BoundedInt {
	int min, val, max;
	byte step;
	boolean valueOff;
	BoundedInt(int minimum, int maximum) { this(minimum, maximum, minimum); }
	BoundedInt(int minimum, int maximum, int value) {
		min = minimum;
		max = maximum;
		val = value;
		step = 1; //amount to inc/dec each time
		valueOff = false;
	}
	String toString() { return "[min:" + min + " max:" + max + " val:" + val + "]"; }
	BoundedInt clone() { return new BoundedInt(min, max, val); }
	int randomize() { val = (int)random(min, max + 1); return val; }
	boolean isWithinBounds(int num) { return (num >= min && num <= max); }

	/** returns false if the value can't go higher */
	boolean increment() {
		if (val + step > max) {
			return false;
		}
		val += step;
		return true;
	}

	/** returns false if the value can't go lower */
	boolean decrement() {
		if (val - step < min) {
			return false;
		}
		val -= step;
		return true;
	}	

	/** returns false if the new min is greater than the maximum */
	boolean updateMin(int newMin) {
		if (newMin > max) {
			return false;
		}
		min = newMin;
		val = max(min, val);
		return true;
	}

	/** returns false if the new max is less than the minimum */
	boolean updateMax(int newMax) {
		if (newMax < min) {
			return false;
		}
		max = newMax;
		val = min(max, val);
		return true;
	}
}

/** Simple class for holding coordinates */
class XY {
	float x, y;	
	XY() { set(0, 0); }
	XY(float _x, float _y) { set(_x, _y); }
	void set(float _x, float _y) { x = _x; y = _y; }
	String toString() { return "[x:" + x + " y:" + y + "]"; }
	XY clone() { return new XY(x, y); }
	boolean equals(XY point) { return equals(point.x, point.y); }
	boolean equals(float _x, float _y) { return x == _x && y == _y; }
	float distance(XY point) { return distance(point.x, point.y); }
	float distance(float _x, float _y) { return (float)sqrt(pow(x - _x, 2) + pow(y - _y, 2)); }
}

/**
* A plain rectangle. Stores the top-left xy anchor, width and height, 
* plus a handful of helper functions for the data.
* x and y are declared in the parent class
* I do this to demonstrate inheritance, not because I'm hopelessly addicted to OOP
*/
class RectBody extends XY {
	float w, h;
	RectBody() { set(0, 0, width, height); }
	RectBody(float _x, float _y, float _w, float _h) {	set(_x, _y, _w, _h); }
	String toString() { return "[x:" + x + " y:" + y + " | w:" + w + " h:" + h + "]"; }
	RectBody clone() { return new RectBody(x, y, w, h); }
	void moveAnchor(XY point) { moveAnchor(point.x, point.y); }
	void moveAnchor(float _x, float _y) { x = _x; y = _y; } //redundant since we have set(x, y) in the parent class...

	/** Assign the body's values. This is a convenience function since you can already access each variable individually */
	void set(float _x, float _y, float _w, float _h) { x = _x; y = _y; w = _w; h = _h; }

	/** Returns the x coordinate plus the width, the right boundary */
	float xw() { return x + w; }

	/** Returns the y coordinate plus the height, the bottom boundary */
	float yh() { return y + h; }
	
	/** Returns true if the incoming body overlaps this one */
	boolean intersects(RectBody other) {
		if (other.xw() >= x && other.x <= xw() &&
			other.yh() >= y && other.y <= yh()) {
			return true;
		}
		return false;
	}

	/** Takes a x coordinate and gives you the closest value inbounds */
	float xInside(float _x) {
		if (_x < x) {
			return x;
		}
		else if (_x >= xw()) {
			return xw();
		}
		return _x;
	}

	/** Takes a y coordinate and gives you the closest value inbounds */
	float yInside(float _y) {
		if (_y < y) {
			return y;
		}
		else if (_y >= yh()) {
			return yh();
		}
		return _y;
	}

	/** Returns true if the mouse is inbounds */
	boolean isMouseOver() { return containsPoint(mouseX, mouseY); }
	boolean containsPoint(XY point) { return containsPoint(point.x, point.y); }
	boolean containsPoint(float _x, float _y) {
		if (_x >= x && _x < xw() &&
			_y >= y && _y < yh()) {
			return true;
		}
		return false;
	}
}

/**
* NestedRectBodys are supposed to be children of a RectBody
* and is not intended to have any children of its own. I don't think nesting one more would work.
* Its purpose is to make it easier to draw a window with bodies inside itself (see EditorWindow)
*/
class NestedRectBody extends RectBody {
	RectBody parent;
	NestedRectBody(RectBody parentBody, float _x, float _y, float _w, float _h) {
		super(_x, _y, _w, _h);
		parent = parentBody;
	}
	float realX()  { return parent.x + x; }
	float realXW() { return parent.x + x + w; }
	float realY()  { return parent.y + y; }
	float realYH() { return parent.y + y + h; }
	boolean containsPoint(float _x, float _y) { //overriding
		_x -= parent.x;
		_y -= parent.y;
		if (_x >= x && _x < xw() &&
			_y >= y && _y < yh()) {
			return true;
		}
		return false;
	}
}

/**
* Constants
* Think of this like a folder or swatch
*/
static class EdConst {
	static class Colors {
		// https://coolors.co/3f4144-a89886-b6680e-16332e-3d8cf6
		// taken from Edwin VanCleef https://media-hearth.cursecdn.com/avatars/331/109/3.png
		public static final int DEFAULT_BACKGROUND = #FFFFFF,
		UI_NORMAL = #16332E, 
		UI_LIGHT = #A89886, 
		UI_DARK = #26261D,
		BRUSH_PREVIEW = #99BB99,
		INFO = #F6332B,
		BLANK = #101010,
		BLACK = #000000,
		WHITE = #FFFFFF,
		ROW_EVEN = #0A0A0A,
		ROW_ODD = #101010;
		// https://coolors.co/271e21-5a7b74-91a290-f3ebba-41291d
	}

	static class Files {
		public static final String BGD_COLOR = "backgroundColor",
		PX_WIDTH = "width",
		PX_HEIGHT = "height",
		EXPRESSIONS = "expressions",
		LAYERS = "layers",
		DOTS = "dots",
		COLOR_PALETTE = "colorPalette",
		PALETTE_INDEX = "paletteIndex",
		TRANSPARENCY = "transparency",
		LAYER_NAME = "layerName";
	}

	static class Menus {
		public static final String EMPTY = "empty",
		//main editor menu buttons
		BRUSH = "brush", 
		LINE = "line",
		BRUSH_SMALLER = "brushSmaller", 
		BRUSH_BIGGER = "brushBigger", 
		RECTANGLE = "rectangle", 
		PERIMETER = "perimeter",
		ZOOM_IN = "zoomIn", 
		ZOOM_OUT = "zoomOut", 
		SAVE_FILE = "save",
		OPEN_FILE = "open", 
		ADD_LAYER = "addLayer",
		NEW_EXPRESSION = "newExpression",
		//layer list item stuff
		DELETE = "delete",
		IS_VISIBLE = "isVisible",
		IS_NOT_VISIBLE = "isNotVisible",
		MOVE_DOWN = "moveDown",
		EDIT_COLOR = "editColor",
		EDIT_NAME = "editName",
		EDIT_EXPRESSIONS = "editExpressions";
	}

	/**
	* Ripped from Java's KeyEvent -- https://docs.oracle.com/javase/8/docs/api/constant-values.html
	* Gives finer control over keyboard input. Processing cut these out to save on space (probably)
	* but also simplified things with their global variables "key" and "keyCode"
	* see https://processing.org/reference/keyCode.html
	*/
	static class KeyCodes {
		public static final int VK_UNDEFINED = 0,
		VK_TAB = 9,
		VK_SHIFT = 16, //probably easier to use event.isShiftDown(), event.isAltDown(), event.isControlDown()
		VK_CONTROL = 17,
		VK_ALT = 18,
		VK_LEFT = 37,
		VK_UP = 38,
		VK_RIGHT = 39,
		VK_DOWN = 40,
		VK_0 = 48,
		VK_1 = 49,
		VK_2 = 50,
		VK_3 = 51,
		VK_4 = 52,
		VK_5 = 53,
		VK_6 = 54,
		VK_7 = 55,
		VK_8 = 56,
		VK_9 = 57,
		VK_A = 65,
		VK_B = 66,
		VK_C = 67,
		VK_D = 68,
		VK_E = 69,
		VK_F = 70,
		VK_G = 71,
		VK_H = 72,
		VK_I = 73,
		VK_J = 74,
		VK_K = 75,
		VK_L = 76,
		VK_M = 77,
		VK_N = 78,
		VK_O = 79,
		VK_P = 80,
		VK_Q = 81,
		VK_R = 82,
		VK_S = 83,
		VK_T = 84,
		VK_U = 85,
		VK_V = 86,
		VK_W = 87,
		VK_X = 88,
		VK_Y = 89,
		VK_Z = 90,
		VK_NUMPAD0 = 96,
		VK_NUMPAD1 = 97,
		VK_NUMPAD2 = 98,
		VK_NUMPAD3 = 99,
		VK_NUMPAD4 = 100,
		VK_NUMPAD5 = 101,
		VK_NUMPAD6 = 102,
		VK_NUMPAD7 = 103,
		VK_NUMPAD8 = 104,
		VK_NUMPAD9 = 105,
		VK_F1 = 112,
		VK_F2 = 113,
		VK_F3 = 114,
		VK_F4 = 115,
		VK_F5 = 116,
		VK_F6 = 117,
		VK_F7 = 118,
		VK_F8 = 119,
		VK_F9 = 120,
		VK_F10 = 121,
		VK_F11 = 122,
		VK_F12 = 123,
		VK_PAGE_UP = 33,
		VK_PAGE_DOWN = 34,
		VK_END = 35,
		VK_HOME = 36,
		VK_DELETE = 127,
		VK_INSERT = 155,
		VK_BACK_SPACE = 8,
		VK_ENTER = 10,
		VK_ESCAPE = 27,
		VK_SPACE = 32,
		VK_CAPS_LOCK = 20,
		VK_NUM_LOCK = 144,
		VK_SCROLL_LOCK = 145,
		VK_AMPERSAND = 150,
		VK_ASTERISK = 151,
		VK_BACK_QUOTE = 192,
		VK_BACK_SLASH = 92,
		VK_BRACELEFT = 161,
		VK_BRACERIGHT = 162,
		VK_CLEAR = 12,
		VK_CLOSE_BRACKET = 93,
		VK_COLON = 513,
		VK_COMMA = 44,
		VK_CONVERT = 28,
		VK_DECIMAL = 110,
		VK_DIVIDE = 111,
		VK_DOLLAR = 515,
		VK_EQUALS = 61,
		VK_SLASH = 47,
		VK_META = 157,
		VK_MINUS = 45,
		VK_MULTIPLY = 106,
		VK_NUMBER_SIGN = 520,
		VK_OPEN_BRACKET = 91,	
		VK_PERIOD = 46,
		VK_PLUS = 521,	
		VK_PRINTSCREEN = 154,
		VK_QUOTE = 222,
		VK_QUOTEDBL = 152,
		VK_RIGHT_PARENTHESIS = 522,	
		VK_SEMICOLON = 59,
		VK_SEPARATOR = 108,
		VK_SUBTRACT = 109;
	}
}

// ===================================
// DEFAULT KIDS
// ===================================

class GridMenu implements Kid, MouseReactive {
	NestedRectBody body;
	Symbol menuSymbol;
	String[] menuKeys;
	String name;
	int columns;

	GridMenu(float anchorX, float anchorY, int numCols, Symbol symbol, String[] keys) {
		this(new RectBody(), anchorX, anchorY, numCols, symbol, keys);
	}

	GridMenu(RectBody parent, float anchorX, float anchorY, int numCols, Symbol symbol, String[] keys) {
		columns = min(max(1, numCols), keys.length); //quick error checking
		body = new NestedRectBody(parent, anchorX, anchorY, columns * symbol.w, ceil(keys.length / (float)columns) * symbol.h);
		menuSymbol = symbol;
		menuKeys = keys;
		name = "menu";
	}

	String getName() {
		return name;
	}

	void drawSelf(PGraphics canvas) {
		for (int i = 0; i < menuKeys.length; i++) {
			canvas.image(menuSymbol.expr(menuKeys[i]), body.x + (i % columns) * menuSymbol.w, body.y + (i / columns) * menuSymbol.h);
		}
	}

	String mouse() { 
		if (!body.isMouseOver() || edwin.mouseBtnReleased != LEFT) {
			return "";
		}
		int i = indexAtMouse();
		if (i < menuKeys.length) {
			menuAction(menuKeys[i]); //ehhh
			return menuKeys[i]; 
		}
		return "";
	}

	void menuAction(String clicked) { } //questionable...only useful if you instantiate with an anonymous class

	int indexAtMouse() { return indexAtPosition(mouseX, mouseY); }
	int indexAtPosition(XY point) { return indexAtPosition(point.x, point.y); }
	int indexAtPosition(float _x, float _y) {
		float relativeX = _x - body.parent.x - body.x;
		float relativeY = _y - body.parent.y - body.y;
		int i = (int)(floor(relativeY / menuSymbol.h) * columns + (relativeX / menuSymbol.w)); 
		// println("x:" + relativeX + " y:" + relativeY);
		// println(" | i: " + i + " val:" + menuKeys[i]);
		return i;
	}
}








/**
* The tile editor
*/
public class EditorWindow implements Kid, MouseReactive, KeyReactive {
	XY gridPt1, gridPt2, zoomPxl, dragOffset;
	RectBody body, onePixel;
	NestedRectBody editBounds, previewBounds, layerListBounds, dragAnchorBounds;
	BoundedInt brushSize, zoomLevel, previewZoomLevel;
	GridMenu toolMenu;
	Symbol layerButtons;
	ArrayList<PixelLayer> layers;
	ArrayList<ExpressionItem> expressions;
	ArrayList<Integer> colorPalette;
	String currentBrush, currentExpression, newSymbolPath;
	boolean isVisible, beingDragged, showPalette, showExpressions;
	int spriteW, spriteH, maxColors, selectedLayerIndex, selectedExpressionIndex;

	final int MS_THRESHOLD = 500, //number of milliseconds you need to hold for certain clicks
		UI_PADDING = 8, //distance between UI elements
		LIH = 10; //list item height - height of layer list items, and width of its buttons

	EditorWindow(boolean visible) { 
		isVisible = visible;
		int margin = 0; //not necessary at all
		body = new RectBody(margin, margin, max(width - margin * 2, 600), max(height - margin * 2, 400));
		onePixel = new RectBody(); //used to draw individual pixels at zoom level
		zoomLevel = new BoundedInt(1, 20, 4);
		previewZoomLevel = new BoundedInt(0, 3, 1);
		brushSize = new BoundedInt(1, 20, 3);
		currentBrush = EdConst.Menus.BRUSH;
		currentExpression = "";
		showPalette = showExpressions = beingDragged = false;
		newSymbolPath = null; //stays null until a new file is opened, at which point it will be loaded the next time drawSelf() is called
		spriteW = 20;
		spriteH = 20;
		gridPt1 = new XY();
		gridPt2 = new XY(); //for drawing grid lines
		zoomPxl = new XY(); //reusable coords to track which zoomed pixel is being drawn
		dragOffset = new XY(); //for when the window is being dragged
		layerButtons = new Symbol("data\\layerButtons.syb");
		Symbol brushMenuSymbol = new Symbol("data\\edwinButtons.syb");
		int menuCols = 4;
		int menuW = menuCols * brushMenuSymbol.pixelW;
		maxColors = (menuW / LIH); //not great design...
		XY ui = new XY(UI_PADDING, UI_PADDING); //anchor for current UI body
		editBounds = new NestedRectBody(body, ui.x + menuW + UI_PADDING, ui.y, body.w - menuW - UI_PADDING * 3, body.h - UI_PADDING * 2); 
		dragAnchorBounds = new NestedRectBody(body, ui.x, ui.y, menuW, LIH * 2);
		ui.y += LIH * 2 + UI_PADDING;
		previewBounds = new NestedRectBody(body, ui.x, ui.y, menuW, menuW);
		ui.y += menuW + UI_PADDING;
		toolMenu = new GridMenu(body, ui.x, ui.y, menuCols, brushMenuSymbol, new String[] { 
			EdConst.Menus.BRUSH, EdConst.Menus.LINE, EdConst.Menus.BRUSH_SMALLER, EdConst.Menus.BRUSH_BIGGER, 
			EdConst.Menus.RECTANGLE, EdConst.Menus.PERIMETER, EdConst.Menus.ZOOM_OUT, EdConst.Menus.ZOOM_IN, 
			EdConst.Menus.OPEN_FILE, EdConst.Menus.SAVE_FILE, EdConst.Menus.NEW_EXPRESSION, EdConst.Menus.ADD_LAYER
		});
		ui.y += toolMenu.body.h + UI_PADDING;
		layerListBounds = new NestedRectBody(body, ui.x, ui.y, menuW, body.h - ui.y - UI_PADDING);
		layers = new ArrayList<PixelLayer>();
		expressions = new ArrayList<ExpressionItem>();
		colorPalette = new ArrayList<Integer>();
		colorPalette.add(#FFFFFF); //bgd
		colorPalette.add(#000000); //first layer
		resetLayers();
		addPixelLayer(); //"first" layer
		expressions.add(new ExpressionItem("all", 0, new int[] { 0 }));
	}

	String getName() { 
		return "editor"; 
	}

	void resetLayers() {
		layers.clear();
		layers.add(new PixelLayer(0, 0, new BitSet(spriteW * spriteH), new String[] { EdConst.Menus.EDIT_COLOR, EdConst.Menus.EDIT_EXPRESSIONS, EdConst.Menus.IS_VISIBLE }));
		//layers.get(0).name = "background";
		selectedLayerIndex = 1; //index in layers. Should never be 0 since that is reserved for the brush preview and bgd layer
		selectedExpressionIndex = 0;
		expressions.clear();
	}

	void addPixelLayer() {
		addPixelLayer(new BitSet(spriteW * spriteH), 1);
	}

	void addPixelLayer(BitSet pxls, int paletteIndex) {
		selectedLayerIndex = layers.size();
		layers.add(new PixelLayer(selectedLayerIndex, paletteIndex, pxls));
	}

	/** Input layer index, receive color from palette */
	int colr(int index) {
		return colorPalette.get(layers.get(index).paletteIndex);
	}

	// big methods ============================================================================================================================================
	void drawSelf(PGraphics canvas) { // ======================================================================================================================
		//canvas.beginDraw() has already been called in Edwin
		if (!isVisible) {
			return;
		}

		//This is so that we can't use the new Symbol from digestSymbol() while the old one is still being drawn
		//It stays null until a new Symbol file is opened
		if (newSymbolPath != null) {
			digestSymbol(newSymbolPath);
			newSymbolPath = null;
		}
		
		//This must be called before translations, and popMatrix() reverses them
		canvas.pushMatrix(); 
		//This translate call is the benefit and requirement of using NestedRectBodys
		//It allows us to keep the EditorWindow's body anchor separate so everything can now draw from 0,0 
		canvas.translate(body.x, body.y);

		//editor window bgd
		canvas.noStroke();
		canvas.fill(EdConst.Colors.UI_NORMAL);
		canvas.rect(0, 0, body.w, body.h);

		//blank bgds
		canvas.fill(EdConst.Colors.BLANK);
		canvas.rect(editBounds.x, editBounds.y, editBounds.w, editBounds.h);
		canvas.rect(dragAnchorBounds.x, dragAnchorBounds.y, dragAnchorBounds.w, dragAnchorBounds.h);
		canvas.rect(previewBounds.x, previewBounds.y, previewBounds.w, previewBounds.h);
		canvas.rect(layerListBounds.x, layerListBounds.y, layerListBounds.w, layerListBounds.h);

		//sprite bgds
		float z = (previewZoomLevel.val == 0 ? 0.5 : previewZoomLevel.val); //temporary hopefully
		if (layers.get(0).isVisible) {
			canvas.fill(colr(0));
			canvas.rect(editBounds.x, editBounds.y, min(spriteW * zoomLevel.val, editBounds.w), min(spriteH * zoomLevel.val, editBounds.h));
			canvas.rect(previewBounds.x, previewBounds.y, min(spriteW * z, previewBounds.w), min(spriteH * z, previewBounds.h));
		}

		//draw each layer scaled at zoomLevel
		PixelLayer thisLayer = null;
		for (int j = 1; j <= layers.size(); j++) {
			if (j == layers.size()) j = 0; //stupid hack to draw layer 0 last
			thisLayer = layers.get(j);

			//set color
			if (j == 0) {
				canvas.fill(EdConst.Colors.BRUSH_PREVIEW);
			} 
			else if (!thisLayer.isVisible) {
				continue; 
			}
			else {
				canvas.fill(colr(j));
			}

			//draw each pixel for this layer, factoring in zoomLevel
			for (int i = 0; i < thisLayer.dots.size(); i++) {
				if (!thisLayer.dots.get(i)) {
					continue; //if pixel isn't set, skip loop iteration
				}
				//calculate coords based on i
				zoomPxl.y = round(i / spriteW);
				zoomPxl.x = i - (zoomPxl.y * spriteW);
				//draw preview in top left
				canvas.rect(previewBounds.x + zoomPxl.x * z, previewBounds.y + zoomPxl.y * z, z, z);

				//determine rectangle to draw that represents the current pixel with current zoom level
				onePixel.set(
					editBounds.x + zoomPxl.x * zoomLevel.val,
					editBounds.y + zoomPxl.y * zoomLevel.val,
					min(zoomLevel.val, editBounds.xw() - editBounds.x - zoomPxl.x * zoomLevel.val), 
					min(zoomLevel.val, editBounds.yh() - editBounds.y - zoomPxl.y * zoomLevel.val));
				//if we're not in the pane, leave
				if (!editBounds.intersects(onePixel)) {
					continue;
				}
				canvas.rect(onePixel.x, onePixel.y, onePixel.w, onePixel.h);
			}

			if (j == 0) break; //undo stupid hack
		}

		//pixel grid lines
		if (zoomLevel.val >= 6) {
			//vertical lines
			gridPt1.x = editBounds.x;
			gridPt2.x = editBounds.xInside(editBounds.x + spriteW * zoomLevel.val);
			for (int yy = 1; yy < spriteH; yy++) { 
				if (yy % 10 == 0) canvas.stroke(50, 200);
				else if (zoomLevel.val < 12) continue;
				else canvas.stroke(120, 100);
				gridPt1.y = gridPt2.y = editBounds.yInside(editBounds.y + yy * zoomLevel.val);
				canvas.line(gridPt1.x, gridPt1.y, gridPt2.x, gridPt2.y);
			}
			//horizontal lines
			gridPt1.y = editBounds.y;
			gridPt2.y = editBounds.yInside(editBounds.y + spriteH * zoomLevel.val);
			for (int xx = 1; xx < spriteW; xx++) { 
				if (xx % 10 == 0) canvas.stroke(50, 200);
				else if (zoomLevel.val < 12) continue;
				else canvas.stroke(120, 100);
				gridPt1.x = gridPt2.x = editBounds.xInside(editBounds.x + xx * zoomLevel.val);
				canvas.line(gridPt1.x, gridPt1.y, gridPt2.x, gridPt2.y);
			}
			canvas.noStroke();
		}

		//draw menus
		toolMenu.drawSelf(canvas);
		//layer list items/menus
		if (showExpressions) {
			for (int i = 0; i < expressions.size(); i++) {
				canvas.fill(i % 2 == 0 ? EdConst.Colors.ROW_EVEN : EdConst.Colors.ROW_ODD);
				//canvas.rect(layerListBounds.x, layerListBounds.y + LIH * i, layerListBounds.w, LIH);
				canvas.rect(
					(selectedExpressionIndex == i ? layerListBounds.x - UI_PADDING : layerListBounds.x), 
					layerListBounds.y + (LIH * i), 
					(selectedExpressionIndex == i ? layerListBounds.w + UI_PADDING * 2 : layerListBounds.w), 
					LIH);
				listLabel(canvas, i, expressions.get(i).name);
				expressions.get(i).menu.drawSelf(canvas);
			}
		}
		else {
			canvas.fill(colr(0));
			canvas.rect(layerListBounds.x, layerListBounds.y, layerListBounds.w, LIH);
			if (showPalette) {
				listLabel(canvas, 0, "palette");
				//draw palette squares
				for (int i = 1; i < colorPalette.size(); i++) {
					canvas.fill(colorPalette.get(i));
					canvas.rect(layerListBounds.xw() - (LIH * i), layerListBounds.y, LIH, LIH);
				}
			}
			else {
				listLabel(canvas, 0, expressions.get(selectedExpressionIndex).name);
				layers.get(0).menu.drawSelf(canvas);
			}

			//layer list items
			for (int i = 1; i < layers.size(); i++) {
				canvas.fill(colr(i));
				canvas.rect(
					(selectedLayerIndex == i ? layerListBounds.x - UI_PADDING : layerListBounds.x), 
					layerListBounds.y + (LIH * i), 
					(selectedLayerIndex == i ? layerListBounds.w + UI_PADDING * 2 : layerListBounds.w), 
					LIH);
				layers.get(i).menu.drawSelf(canvas);
				if (i == selectedLayerIndex) {
					listLabel(canvas, i, layers.get(i).name);
				}
			}
		}

		//indicator that you've been holding down the mouse
		if (edwin.mouseHeldMillis > MS_THRESHOLD  && layerListBounds.isMouseOver()) {
			canvas.fill(255, 0, 255, 150);
			canvas.ellipse(mouseX - body.x, mouseY - body.y, 10, 10);
		}

		canvas.popMatrix(); //undo translate()
	} // end drawSelf() =======================================================================================================================================
	// ========================================================================================================================================================

	/** convenience method */
	void listLabel(PGraphics canvas, int index, String label) {
		canvas.fill(EdConst.Colors.UI_LIGHT);
		canvas.rect(layerListBounds.x, layerListBounds.y + LIH * index, canvas.textWidth(label) + 1, LIH);
		canvas.fill(EdConst.Colors.BLACK);
		canvas.text(label, layerListBounds.x, layerListBounds.y + (LIH * (index + 1)) - 2);
	}

	String mouse() {
		if (!isVisible) {
			return "";
		}
		
		if (beingDragged) {
			body.set(mouseX - dragOffset.x, mouseY - dragOffset.y);
			if (edwin.mouseBtnReleased != 0) {
				beingDragged = false;
			}
			return getName();
		}
		
		if (edwin.mouseBtnBeginHold != 0) {
			layers.get(0).dots.clear(); //clear brush preview
			if (dragAnchorBounds.isMouseOver()) {
				beingDragged = true;
				dragOffset.set(mouseX - body.x, mouseY - body.y);
			}
		}
		else if (edwin.mouseBtnReleased != 0) {
			layers.get(0).dots.clear(); //clear brush preview
		}

		if (!body.isMouseOver()) {
			return "";
		}

		if (editBounds.isMouseOver()) {
			if (edwin.mouseBtnHeld == 0 && edwin.mouseBtnReleased == 0) { //hovering
				switch (currentBrush) {
					case EdConst.Menus.BRUSH:
						//brush preview
						layers.get(0).dots.clear(); 
						applyBrush(0, true);
						break;
				}
			}
			else if (edwin.mouseBtnHeld == LEFT || edwin.mouseBtnHeld == RIGHT) {
				switch (currentBrush) {
					case EdConst.Menus.BRUSH:
						applyBrush(selectedLayerIndex, edwin.mouseBtnHeld == LEFT ? true : false);
						break;
					case EdConst.Menus.LINE:
					case EdConst.Menus.RECTANGLE:
					case EdConst.Menus.PERIMETER:
						//brush preview
						layers.get(0).dots.clear();
						applyBrush(0, true);
						break;
				}
			}
			else if (edwin.mouseBtnReleased == LEFT || edwin.mouseBtnReleased == RIGHT) {
				switch (currentBrush) {
					case EdConst.Menus.LINE:
					case EdConst.Menus.RECTANGLE:
					case EdConst.Menus.PERIMETER:
						applyBrush(selectedLayerIndex, edwin.mouseBtnReleased == LEFT ? true : false);
						break;
				}
			}
		}
		else if (edwin.mouseBtnReleased != LEFT) {
			return ""; //I'm doing it this way so that the block below doesn't have to be nested one level deeper
		}

		String menuClick = toolMenu.mouse(); //primary menu buttons below preview
		switch (menuClick) {
			case EdConst.Menus.BRUSH:
			case EdConst.Menus.LINE:
			case EdConst.Menus.RECTANGLE:
			case EdConst.Menus.PERIMETER:
				currentBrush = menuClick;
				break;
			case EdConst.Menus.ZOOM_IN: 
				zoomLevel.increment();
				break;
			case EdConst.Menus.ZOOM_OUT: 
				zoomLevel.decrement();
				break;
			case EdConst.Menus.BRUSH_BIGGER:
				brushSize.increment();
				break;
			case EdConst.Menus.BRUSH_SMALLER:
				brushSize.decrement();
				break;
			case EdConst.Menus.ADD_LAYER:
				addPixelLayer();
				expressions.get(selectedExpressionIndex).layerIndicies.add(layers.size() - 1);
				break;
			case EdConst.Menus.NEW_EXPRESSION: 
				String newName = JOptionPane.showInputDialog("Enter new expression name", "newexp");
				if (newName != null) {
					expressions.add(new ExpressionItem(newName, expressions.size(), new int[] { 0 }));
					selectedExpressionIndex = expressions.size() - 1;
				}
				break;
			case EdConst.Menus.SAVE_FILE:
				selectOutput("Save Symbol .sym", "saveFile", null, this);
				break;
			case EdConst.Menus.OPEN_FILE:
				selectInput("Open Symbol .sym", "openFile", null, this);
				break;
		}

		if (menuClick != "") {
			return getName();
		}
		else if (!layerListBounds.isMouseOver() || editBounds.containsPoint(edwin.mouseInitial)) {
			return ""; 
		}
		else if (showExpressions) {
			int index = -1;
			for (int i = 0; i < expressions.size(); i++) {
				menuClick = expressions.get(i).menu.mouse();
				if (!menuClick.equals("")) {
					index = i;
					break;
				}
			}
			if (index == -1) {
				return "";
			}
			ExpressionItem exp = expressions.get(index);
			switch (menuClick) {
				case EdConst.Menus.DELETE:
					if (expressions.size() == 1) {
						JOptionPane.showMessageDialog(null, "Can't delete expression when it's the only one", "Hey", JOptionPane.INFORMATION_MESSAGE);
						break;
					}
					int selected = JOptionPane.showConfirmDialog(null, "Really delete expression \"" + exp.name + "\"?", "Delete Expression?", JOptionPane.YES_NO_OPTION, JOptionPane.WARNING_MESSAGE);
					if (selected == JOptionPane.YES_OPTION) {
						expressions.remove(index);
						if (index == 1 && expressions.size() == 1) {
							selectedExpressionIndex = 0;
						}
						else {
							for (int i = index; i < expressions.size(); i++) {
								expressions.get(i).menu.body.y -= LIH;
							}
							selectedExpressionIndex = min(selectedExpressionIndex, expressions.size() - 1);
						}
					}
					break;
				case EdConst.Menus.EDIT_NAME:
					String newName = JOptionPane.showInputDialog("Enter new expression name", exp.name);
					if (newName != null) {
						exp.name = newName;
					}
					break;
				case EdConst.Menus.MOVE_DOWN: //currently what I'm using for selection
					useExpression(index);
					//showExpressions = false;
					break;
			}
			return getName();
		}
		//else layer list item was clicked

		//Here we translate the mouse coordinate into an index location
		//using LIH (List Item Height) as the side length of 1 grid cell
		//yIndex 0 is the background layer and topmost item, xIndex 1 is the rightmost item
		//this is a remnant from before I had GridMenus when I was using square regions as buttons
		int yIndex = (int)((mouseY - layerListBounds.realY()) / LIH);
		int xIndex = (int)((layerListBounds.realXW() - mouseX) / LIH) + 1;

		//edit color palette
		if (yIndex == 0 && showPalette) {
			if (xIndex < colorPalette.size()) {
				if (edwin.mouseHeldMillis < MS_THRESHOLD) {
					layers.get(selectedLayerIndex).paletteIndex = xIndex;
				}
				else if (pickNewColor(xIndex)) {
					layers.get(selectedLayerIndex).paletteIndex = xIndex;
				}
			}
			else if (edwin.mouseHeldMillis > MS_THRESHOLD) {
				pickNewColor(0);
			}
			else {
				showPalette = false;
			}
			return getName();
		}
		else if (yIndex >= layers.size()) {
			return "";
		}

		PixelLayer thisLayer = layers.get(yIndex);
		menuClick = thisLayer.menu.mouse();
		switch (menuClick) {
			case EdConst.Menus.DELETE:
				if (yIndex != selectedLayerIndex) {
					break; //exit the switch and select this layer so that it's slightly more difficult to delete layers
				}
				else if (layers.size() == 2) {
					JOptionPane.showMessageDialog(null, "Can't delete layer when it's the only one", "Hey", JOptionPane.INFORMATION_MESSAGE);
					break;
				}
				int selected = JOptionPane.showConfirmDialog(null, "Really delete layer \"" + thisLayer.name + "\"?", "Delete Layer?", JOptionPane.YES_NO_OPTION, JOptionPane.WARNING_MESSAGE);
				if (selected == JOptionPane.YES_OPTION) {
					layers.remove(yIndex);
					for (int i = yIndex; i < layers.size(); i++) { 
						layers.get(i).menu.body.y -= LIH;
					}
					for (ExpressionItem exp : expressions) {
						exp.deleteLayer(yIndex);
					}
				}
				break;
			case EdConst.Menus.EDIT_NAME:
				String newName = JOptionPane.showInputDialog("Enter new layer name", thisLayer.name);
				if (newName != null) {
					thisLayer.name = newName;
				}
				break;
			case EdConst.Menus.MOVE_DOWN:
				if (yIndex < layers.size() - 1) {
					//TODO make cleaner...
					thisLayer.menu.body.y += LIH;
					layers.get(yIndex + 1).menu.body.y -= LIH;
					Collections.swap(layers, yIndex, yIndex + 1);
					selectedLayerIndex = yIndex + 1;
					for (ExpressionItem exp : expressions) {
						exp.adjustLayerDown(yIndex);
					}
				}
				break;
			case EdConst.Menus.IS_VISIBLE:
			case EdConst.Menus.IS_NOT_VISIBLE:
				thisLayer.toggleVisibility();
				expressions.get(selectedExpressionIndex).setVis(yIndex, thisLayer.isVisible);
				break;
			case EdConst.Menus.EDIT_COLOR:
				if (edwin.mouseHeldMillis > MS_THRESHOLD) {
					if (yIndex == 0) {
						pickNewColor(0);
					}
					else if (colorPalette.size() <= maxColors) {
						if (pickNewColor(colorPalette.size())) {
							thisLayer.paletteIndex = colorPalette.size() - 1;
						}
					}
					else {
						JOptionPane.showMessageDialog(null, "Too many colors in the palette", "Coding is complicated...", JOptionPane.INFORMATION_MESSAGE);
					}
				}
				else {
					showPalette = !showPalette;
				}
				break;
			case EdConst.Menus.EDIT_EXPRESSIONS: //only available in layer 0...
				showExpressions = true;
				break;
		}
		selectedLayerIndex = max(min(yIndex, layers.size() - 1), 1);
		//println(menuClick);
		return getName();
	} // end mouse() ==========================================================================================================================================
	// ========================================================================================================================================================

	String keyboard(KeyEvent event) {
		int kc = event.getKeyCode();
		if (kc == EdConst.KeyCodes.VK_Z) {
			zoomLevel.increment();
		}
		else if (kc == EdConst.KeyCodes.VK_A) {
			zoomLevel.decrement();
		}
		else if (event.getAction() != KeyEvent.RELEASE) { //the keys above react to any event, below only to RELEASE
			return "";
		}
		else if (kc == EdConst.KeyCodes.VK_UP) {
			if (showExpressions) selectedExpressionIndex = max(selectedExpressionIndex - 1, 1);
			else selectedLayerIndex = max(selectedLayerIndex - 1, 1);
		}
		else if (kc == EdConst.KeyCodes.VK_DOWN) {
			if (showExpressions) selectedExpressionIndex = min(selectedExpressionIndex + 1, expressions.size() - 1);
			else selectedLayerIndex = min(selectedLayerIndex + 1, layers.size() - 1);
		}
		else if (kc == EdConst.KeyCodes.VK_X) {
			showExpressions = !showExpressions;
		}
		else if (kc == EdConst.KeyCodes.VK_E) {
			isVisible = !isVisible;
		}
		else if (kc == EdConst.KeyCodes.VK_V) {
			layers.get(selectedLayerIndex).toggleVisibility();
			expressions.get(selectedExpressionIndex).setVis(selectedLayerIndex, layers.get(selectedLayerIndex).isVisible);
		}
		else if (kc == EdConst.KeyCodes.VK_O && event.isControlDown()) {
			selectInput("Open Symbol .sym", "openFile", null, this);
		}
		else if (kc == EdConst.KeyCodes.VK_S && event.isControlDown()) {
			selectOutput("Save Symbol .sym", "saveFile", null, this);
		}
		else {
			return "";
		}

		return getName();
	}

	boolean pickNewColor(int paletteIndex) {
		Color init = (paletteIndex == colorPalette.size()) ? Color.BLACK : new Color(colorPalette.get(paletteIndex));
		Color picked = JColorChooser.showDialog(null, "Pick new Color", init);
		if (picked != null) {
			if (paletteIndex == colorPalette.size()) {
				colorPalette.add(picked.getRGB());
			}
			else {
				colorPalette.set(paletteIndex, picked.getRGB());
			}
			return true;
		}
		return false;
	}

	void useExpression(int index) {
		//turn all layers off
		for (int i = 1; i < layers.size(); i++) {
			if (layers.get(i).isVisible) {
				layers.get(i).toggleVisibility();
			}
		}
		//turn on layers selectively
		for (int l : expressions.get(index).layerIndicies) {
			layers.get(l).toggleVisibility();
			selectedLayerIndex = l;
		}
		selectedExpressionIndex = index;
	}

	/**
	* brushVal == true means setting pixels
	* brushVal == false means removing pixels
	*/
	void applyBrush(int layerIndex, boolean brushVal) {
		//these figures are aimed at consistency while zoomed
		XY mouseTranslated = new XY(round((mouseX - body.x - editBounds.x - (zoomLevel.val * .4)) / zoomLevel.val), 
			round((mouseY - body.y - editBounds.y - (zoomLevel.val * .4)) / zoomLevel.val));
		XY mouseInitialTranslated = new XY((edwin.mouseInitial.x - body.x - editBounds.x) / zoomLevel.val, 
			(edwin.mouseInitial.y - body.y - editBounds.y) / zoomLevel.val);

		PixelLayer thisLayer = layers.get(layerIndex);
		if (!thisLayer.isVisible && layerIndex != 0) return; //can't draw on layers that aren't visible, except 0 is a special case

		if (currentBrush == EdConst.Menus.BRUSH) {
			//square of size brushSize
			thisLayer.pixelRectangle(brushVal, mouseTranslated.x, mouseTranslated.y, (float)brushSize.val, (float)brushSize.val);
		}
		else if (currentBrush == EdConst.Menus.RECTANGLE) {
			//just a solid block
			thisLayer.pixelRectangle(brushVal, 
				min(mouseInitialTranslated.x, mouseTranslated.x),
				min(mouseInitialTranslated.y, mouseTranslated.y),
				abs(mouseInitialTranslated.x - mouseTranslated.x),
				abs(mouseInitialTranslated.y - mouseTranslated.y));
		}
		else if (currentBrush == EdConst.Menus.PERIMETER) {
			//perimeter is an outline of a rectangle
			//so we will be adding in a rectangle of points for each side
			RectBody rectArea = new RectBody(
				min(mouseInitialTranslated.x, mouseTranslated.x),
				min(mouseInitialTranslated.y, mouseTranslated.y),
				abs(mouseInitialTranslated.x - mouseTranslated.x),
				abs(mouseInitialTranslated.y - mouseTranslated.y));
			//left
			thisLayer.pixelRectangle(brushVal, 
				rectArea.x, 
				rectArea.y, 
				min(brushSize.val, rectArea.w), 
				rectArea.h);
			//top
			thisLayer.pixelRectangle(brushVal, 
				rectArea.x, 
				rectArea.y, 
				rectArea.w, 
				min(brushSize.val, rectArea.h));
			//right
			thisLayer.pixelRectangle(brushVal, 
				max(rectArea.xw() - brushSize.val, rectArea.x),
				rectArea.y, 
				min(brushSize.val, rectArea.w),
				rectArea.h);
			//bottom
			thisLayer.pixelRectangle(brushVal, 
				rectArea.x, 
				max(rectArea.yh() - brushSize.val, rectArea.y),
				rectArea.w, 
				min(brushSize.val, rectArea.h));
		}
		else if (currentBrush == EdConst.Menus.LINE) {
			//line of brushSize width
			//math.stackexchange.com/a/2109383
			float segmentIncrement = 1;
			float lineDist = mouseInitialTranslated.distance(mouseTranslated);
			XY newPoint = new XY();
			thisLayer.pixelRectangle(brushVal, mouseTranslated.x, mouseTranslated.y, brushSize.val, brushSize.val);
			for (float segDist = 0; segDist <= lineDist; segDist += segmentIncrement) {
				newPoint.set(mouseInitialTranslated.x - (segDist * (mouseInitialTranslated.x - mouseTranslated.x)) / lineDist, 
					mouseInitialTranslated.y - (segDist * (mouseInitialTranslated.y - mouseTranslated.y)) / lineDist);
				thisLayer.pixelRectangle(brushVal, newPoint.x, newPoint.y, brushSize.val - 1, brushSize.val - 1);
			}
		}
	}
	
	void openFile(File selected) {
		if (selected == null) {
			return; //user hit cancel or closed
		}
		newSymbolPath = selected.getAbsolutePath(); 
		//Next time drawSelf() is called it'll call digestSymbol() so we don't screw with variables in use 
		//since we might be in the middle of drawing at this time. Then newSymbolPath becomes null.
	}

	/** Load file into editor variables */
	void digestSymbol(String filename) {
		JSONObject json = loadJSONObject(filename);
		spriteW = json.getInt(EdConst.Files.PX_WIDTH);
		spriteH = json.getInt(EdConst.Files.PX_HEIGHT);
		colorPalette.clear();
		resetLayers();

		//colors
		if (json.isNull(EdConst.Files.BGD_COLOR)) {
			colorPalette.add(#FFFFFF);
			layers.get(0).isVisible = false; 
		}
		else {
			colorPalette.add(json.getInt(EdConst.Files.BGD_COLOR));
		}

		for (int paletteColor : json.getJSONArray(EdConst.Files.COLOR_PALETTE).getIntArray()) {
			colorPalette.add(paletteColor);
		}

		//expressions of the symbol
		JSONObject jsonExpressions = json.getJSONObject(EdConst.Files.EXPRESSIONS);
		int e = 0;
		for (Object keyName : jsonExpressions.keys().toArray()) {
			expressions.add(new ExpressionItem(keyName.toString(), e++, jsonExpressions.getJSONArray(keyName.toString()).getIntArray()));
		}

		//layer pixels
		JSONArray allLayers = json.getJSONArray(EdConst.Files.LAYERS);
		for (int i = 0; i < allLayers.size(); i++) {
			JSONObject thisLayer = allLayers.getJSONObject(i);
			BitSet pxls = new BitSet(spriteW * spriteH);
			for (int v : thisLayer.getJSONArray(EdConst.Files.DOTS).getIntArray()) {
				pxls.set(v);
			}
			addPixelLayer(pxls, thisLayer.getInt(EdConst.Files.PALETTE_INDEX) + 1); // + 1 because the file has the bgdColor on its own but EditorWindow puts it in layer 0
			layers.get(i + 1).name = thisLayer.getString(EdConst.Files.LAYER_NAME);
		}

		//choose some expression rather than have all layers on
		for (int i = 1; i < layers.size(); i++) {
			if (expressions.get(0).layerIndicies.indexOf(i) == -1) {
				layers.get(i).toggleVisibility();
			}
		}
	}

	/**
	* So unfortunately for me the default toString() methods
	* for JSONObjects and JSONArrays that were provided by 
	* the wonderful Processing devs give each value their own line. 
	* So the dump I'm trying to take is too big for that, 
	* and this is my attempt at significantly fewer 
	* newline characters and having a sorted readable format.
	* Also I don't know how to work with binary files.
	*/
	void saveFile(File selected) {
		if (selected == null) {
			return; //user hit cancel or closed
		}
		//remember the 0th element in layers is actually the brush preview pixels (which aren't saved)
		//and whether the sprite background has a color, or isn't visible
		ArrayList<String> fileLines = new ArrayList<String>();
		String TAB = "\t";
		fileLines.add("{"); //opening bracket
		fileLines.add(jKey(EdConst.Files.PX_WIDTH, spriteW));
		fileLines.add(jKey(EdConst.Files.PX_HEIGHT, spriteH));
		fileLines.add(jKey(EdConst.Files.BGD_COLOR, layers.get(0).isVisible ? String.valueOf(colr(0)) : "null"));
		fileLines.add(jKey(EdConst.Files.COLOR_PALETTE, colorPalette.subList(1, colorPalette.size()).toString()));
		fileLines.add(jKeyNoComma(EdConst.Files.EXPRESSIONS, "{"));

		for (ExpressionItem exp : expressions) {
			ArrayList<Integer> ly = new ArrayList<Integer>();
			for (int i : exp.layerIndicies) {
				ly.add(i - 1); //dumb
			}
			Collections.sort(ly);
			fileLines.add(TAB + jKey(exp.name, ly.toString()));
		}

		fileLines.add("},"); //close expressions
		fileLines.add(jKeyNoComma(EdConst.Files.LAYERS, "[{")); //array of objects
		for (int i = 1; i < layers.size(); i++) {
			if (i > 1) {
				fileLines.add("},{"); //separation between layer objects in this array
			}

			BitSet pxls = layers.get(i).dots;
			ArrayList<Integer> layerDots = new ArrayList<Integer>();
			for (int j = 0; j < pxls.size(); j++) {
				if (pxls.get(j)) {
					layerDots.add(j);
				}
			}

			fileLines.add(TAB + jKey(EdConst.Files.DOTS, layerDots.toString()));
			fileLines.add(TAB + jKey("index", i - 1)); //unncessary and confusing...
			fileLines.add(TAB + jKeyString(EdConst.Files.LAYER_NAME, layers.get(i).name));
			fileLines.add(TAB + jKey(EdConst.Files.PALETTE_INDEX, layers.get(i).paletteIndex - 1));
			fileLines.add(TAB + jKey(EdConst.Files.TRANSPARENCY, "255")); //not implemented yet...
		}
		fileLines.add("}]"); //close LAYERS
		fileLines.add("}"); //final closing bracket
		saveStrings(selected.getAbsolutePath(), fileLines.toArray(new String[0]));
	}

	/** returns your key and value as "key":value, */
	String jKey(String keyName, int value) {
		return jKey(keyName, String.valueOf(value));
	}

	String jKey(String keyName, String value) {
		return jKeyNoComma(keyName, value + ",");
	}

	String jKeyString(String keyName, String value) {
		return jKeyNoComma(keyName, "\"" + value + "\",");
	}

	String jKeyNoComma(String keyName, String value) {
		return "\"" + keyName + "\":" + value;
	}

	/** Part of EditorWindow */
	class PixelLayer {
		GridMenu menu;
		BitSet dots;
		String name;
		int paletteIndex;
		boolean isVisible;

		PixelLayer(int index, int colorPaletteIndex, BitSet pxls) {
			this(index, colorPaletteIndex, pxls, new String[] { EdConst.Menus.DELETE, EdConst.Menus.EDIT_NAME, EdConst.Menus.EDIT_COLOR, EdConst.Menus.MOVE_DOWN, EdConst.Menus.IS_VISIBLE });
		}

		PixelLayer(int index, int colorPaletteIndex, BitSet pxls, String[] btns) {
			paletteIndex = colorPaletteIndex;
			dots = pxls;
			isVisible = true;
			name = "newlayer";
			menu = new GridMenu(body, layerListBounds.xw() - layerButtons.w * btns.length, layerListBounds.y + layerButtons.h * index, btns.length, layerButtons, btns);
		}

		void toggleVisibility() {
			isVisible = !isVisible;
			menu.menuKeys[menu.menuKeys.length - 1] = isVisible ? EdConst.Menus.IS_VISIBLE : EdConst.Menus.IS_NOT_VISIBLE;
		}

		/**
		* brushVal == true means setting pixels
		* brushVal == false means removing pixels
		*/
		void pixelRectangle(boolean brushVal, float _x, float _y, float _w, float _h) {
			//if rectangle isn't in bounds, leave
			if (_x >= spriteW || _y >= spriteH ||
				_x + _w < 0 || _y + _h < 0) {
				return;
			}
			//clamp boundaries
			_x = max(_x, 0);
			_y = max(_y, 0);
			_w = min(_w, spriteW - _x);
			_h = min(_h, spriteH - _y);
			//finally, loop through each pixel in rect and set it
			for (int y = (int)_y; y < _y + _h; y++) {
				for (int x = (int)_x; x < _x + _w; x++) {
					dots.set(y * spriteW + x, brushVal);
				}
			}
		}

		// void updateBounds(BitSet pxl, int _w, int _h) {
		// 	BitSet newPixels = new BitSet(_w * _h);
		// 	XY point = new XY();
		// 	//try to maintain pixels from old bounds
		// 	for (int i = 0; i < pxl.size(); i++) {
		// 		if (pxl.get(i)) {
		// 			point.y = (int) ((float) i / (float) spriteW);
		// 			point.x = i - (point.y * spriteW);
		// 			if (point.x >= _w || point.y >= _h) {
		// 				continue;
		// 			}
		// 			newPixels.set((int) (point.y * _w + point.x));
		// 		}		
		// 	}
		// 	pxl = newPixels;
		// }
	}

	class ExpressionItem {
		ArrayList<Integer> layerIndicies;
		String name;
		GridMenu menu;

		ExpressionItem(String expName, int index) {
			this(expName, index, new int[] {});
		}

		ExpressionItem(String expName, int index, int[] layerIds) {
			name = expName;
			layerIndicies = new ArrayList<Integer>();
			for (int i = 0; i < layerIds.length; i++) {
				layerIndicies.add(layerIds[i] + 1);
			}
			String[] btns = new String[] { EdConst.Menus.DELETE, EdConst.Menus.EDIT_NAME, EdConst.Menus.MOVE_DOWN };
			menu = new GridMenu(body, layerListBounds.xw() - layerButtons.w * btns.length, layerListBounds.y + layerButtons.h * index, btns.length, layerButtons, btns);
		}

		/** for when layers are being shuffled around */
		void adjustLayerDown(int index) {
			for (int i = 0; i < layerIndicies.size(); i++) {
				if (layerIndicies.get(i) == index) {
					layerIndicies.set(i, index + 1);
				}
				else if (layerIndicies.get(i) == index + 1) {
					layerIndicies.set(i, index);
				}
			}
		}

		void setVis(int index, boolean vis) {
			int existing = -1;
			for (int i = 0; i < layerIndicies.size(); i++) {
				if (layerIndicies.get(i) == index) {
					existing = i;
					break;
				}
			}
			if (vis && existing == -1) { //if we want to set it and it doesn't exist
				layerIndicies.add(index);
			}
			else if (!vis && existing != -1) { //if we want to remove it and it does exist
				layerIndicies.remove(existing);
			}
		}

		void deleteLayer(int index) {
			int existing = -1;
			for (int i = 0; i < layerIndicies.size(); i++) {
				if (layerIndicies.get(i) == index) {
					existing = i;
				}
				else if (layerIndicies.get(i) > index) {
					layerIndicies.set(i, layerIndicies.get(i) - 1); //shift others layers up a value
				}
			} 
			if (existing != -1) {
				layerIndicies.remove(existing);
			}
		}
	}

} //end EditorWindow



