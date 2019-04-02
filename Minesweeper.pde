
Edwin edwin;
int edd = 0;

void setup() {
	size(1200, 800);
	edwin = new Edwin(true);
	//edwin.addKid(new MinesweeperGame());
}

void draw() {
	edwin.update();
	image(edwin.canvas, 0, 0);
}





