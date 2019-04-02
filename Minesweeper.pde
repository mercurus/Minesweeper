
Edwin edwin;
int edd = 0;

void setup() {
	size(1200, 800);
	edwin = new Edwin(true);
	edwin.addKid(new MinesweeperGame());
}

void draw() {
	edwin.update();
	image(edwin.canvas, 0, 0);
}








/**
* An early test to see how useful this whole thing is
*/
class MinesweeperGame implements Kid, MouseReactive, KeyReactive {
	final String BOMB = "bomb",
	UNTOUCHED = "untouched",
	EMPTY = "empty",
	FLAG = "flag",
	QUESTION = "question",
	ONE = "one",
	TWO = "two",
	THREE = "three",
	FOUR = "four",
	FIVE = "five",
	SIX = "six",
	SEVEN = "seven",
	EIGHT = "eight";

	RectBody body;
	Symbol mineSymbol;
	String[] gameState, displayState;
	int mouseSelectedI, gameW, gameH, numBombs;

	MinesweeperGame() {
		//==============================
		//Feel free to change up the game settings here:
		gameW = 16;
		gameH = 16;
		numBombs = 40;
		//Standard tile sizes:
		//Beginner 		= W:9  H:9  B:10
		//Intermediate 	= W:16 H:16 B:40
		//Expert 		= W:30 H:16 B:99
		//==============================
		mineSymbol = new Symbol("data\\minesweeper.syb", 2);
		body = new RectBody(0, 0, gameW * mineSymbol.w, gameH * mineSymbol.h);
		gameState = new String[gameW * gameH];
		displayState = new String[gameW * gameH];
		mouseSelectedI = 0;
		resetGame();
	}

	void resetGame() {
		int randI, tempBombs, thisTileBombs; 
		boolean north, east, south, west;
		//initialize
		for (int i = 0; i < gameState.length; i++) {
			gameState[i] = EMPTY;
			displayState[i] = UNTOUCHED;
		}
		//place bombs
		tempBombs = min(numBombs, gameW * gameH); //make sure we didn't set numBombs too high
		while (tempBombs > 0) {
			randI = (int)random(0, gameW * gameH);
			if (gameState[randI] == EMPTY) {
				gameState[randI] = BOMB;
				tempBombs--;
			}
		}
		//assign numbers
		for (int i = 0; i < gameState.length; i++) {
			if (gameState[i] == BOMB) {
				continue;
			}
			thisTileBombs = 0;
			north = east = south = west = false;
			//check the cardinal directions first so we can know which corners to check afterwards
			if (i / (float)gameW >= 1) {
				north = true;
				if (gameState[i - gameW] == BOMB) thisTileBombs++;
			}
			if (i % gameW != gameW - 1) {
				east = true;
				if (gameState[i + 1] == BOMB) thisTileBombs++;
			}
			if (i < gameW * (gameH - 1)) {
				south = true;
				if (gameState[i + gameW] == BOMB) thisTileBombs++;
			}
			if (i % gameW > 0) {
				west = true;
				if (gameState[i - 1] == BOMB) thisTileBombs++;
			}
			if (north && west && gameState[i - gameW - 1] == BOMB) thisTileBombs++;
			if (north && east && gameState[i - gameW + 1] == BOMB) thisTileBombs++;
			if (south && east && gameState[i + gameW + 1] == BOMB) thisTileBombs++;
			if (south && west && gameState[i + gameW - 1] == BOMB) thisTileBombs++;
			
			String newVal = EMPTY; 
			if (thisTileBombs == 1) newVal = ONE;
			else if (thisTileBombs == 2) newVal = TWO;
			else if (thisTileBombs == 3) newVal = THREE;
			else if (thisTileBombs == 4) newVal = FOUR;
			else if (thisTileBombs == 5) newVal = FIVE;
			else if (thisTileBombs == 6) newVal = SIX;
			else if (thisTileBombs == 7) newVal = SEVEN;
			else if (thisTileBombs == 8) newVal = EIGHT;
			gameState[i] = newVal;
			//displayState[i] = newVal; //uncomment this to see all the numbers
		}
	}

	String getName() { 
		return "Minesweeper"; 
	}

	void drawSelf(PGraphics canvas) {
		int x, y;
		for (int i = 0; i < displayState.length; i++) {
			y = (int)(i / (float)gameW);
			x = i - (y * gameW);
			canvas.image(mineSymbol.expr(displayState[i]), body.x + x * mineSymbol.w, body.y + y * mineSymbol.h);
			//now we see if we need to show a button press
			if (edwin.mouseBtnHeld == LEFT && mouseSelectedI == i && i == indexAtMouse() && displayState[i] == UNTOUCHED) {
				canvas.image(mineSymbol.expr(EMPTY), body.x + (i - y * gameW) * mineSymbol.w, body.y + y * mineSymbol.h);
			}
		}
	}

	String keyboard(KeyEvent event) {
		if (event.getAction() == KeyEvent.RELEASE && event.getKeyCode() == EdConst.KeyCodes.VK_R) {
			resetGame();
			return getName();
		}
		return "";
	}

	String mouse() {
		if (edwin.mouseBtnHeld == CENTER) {
			body.moveAnchor(mouseX, mouseY);
		}
		else if (!body.isMouseOver()) {
			return "";
		}
		else if (edwin.mouseBtnBeginHold != 0) {
			mouseSelectedI = indexAtMouse();
			if (edwin.mouseBtnBeginHold == RIGHT) {
				//cycle image from blank to flag to question and back
				if (displayState[mouseSelectedI] == FLAG) displayState[mouseSelectedI] = QUESTION;
				else if (displayState[mouseSelectedI] == QUESTION) displayState[mouseSelectedI] = UNTOUCHED;
				else if (displayState[mouseSelectedI] == UNTOUCHED) {
					displayState[mouseSelectedI] = FLAG;
					//see if the game is over
					int flagCount = 0, correctCount = 0;
					for (int i = 0; i < displayState.length; i++) {
						if (displayState[i] == FLAG) {
							flagCount++;
							if (gameState[i] == BOMB) {
								correctCount++;
							}
						}
					}
					if (flagCount > numBombs - 5) println(flagCount + "/" + numBombs + " bombs flagged");
					if (correctCount == numBombs && correctCount == flagCount) println("YOU WIN");
				}
			}
		}
		else if (edwin.mouseBtnReleased == LEFT) {
			//if we release on the same cell we started the click on
			if (displayState[mouseSelectedI] == UNTOUCHED && mouseSelectedI == indexAtMouse()) {
				explore(mouseSelectedI);
				if (gameState[mouseSelectedI] == BOMB) println("YOU LOSE");
			}
		}
		return getName();
	}

	int indexAtMouse() {
		int yIndex = (int)((mouseY - body.y) / mineSymbol.h);
		int xIndex = (int)((mouseX - body.x) / mineSymbol.w);
		//println("x:" + xIndex + " y:" + yIndex);
		return yIndex * gameW + xIndex;
	}

	/** Reveal tile being clicked and if it's blank then recursively reveal neighbors until the edge hits numbers */
	void explore(int index) {
		displayState[index] = gameState[index];
		if (gameState[index] != EMPTY) {
			return;
		}
		boolean north, east, south, west;
		north = east = south = west = false;
		//check the cardinal directions first so we can know which corners to check afterwards
		if ((index / (float)gameW) >= 1) {
			north = true;
			if (displayState[index - gameW] == UNTOUCHED) explore(index - gameW);
		}
		if (index % gameW != gameW - 1) {
			east = true;
			if (displayState[index + 1] == UNTOUCHED) explore(index + 1);
		}
		if (index < gameW * (gameH - 1)) {
			south = true;
			if (displayState[index + gameW] == UNTOUCHED) explore(index + gameW);
		}
		if (index % gameW > 0) {
			west = true;
			if (displayState[index - 1] == UNTOUCHED) explore(index - 1);
		}
		//corners
		if (north && west && displayState[index - gameW - 1] == UNTOUCHED) explore(index - gameW - 1);
		if (north && east && displayState[index - gameW + 1] == UNTOUCHED) explore(index - gameW + 1);
		if (south && east && displayState[index + gameW + 1] == UNTOUCHED) explore(index + gameW + 1);
		if (south && west && displayState[index + gameW - 1] == UNTOUCHED) explore(index + gameW - 1);
	}
}