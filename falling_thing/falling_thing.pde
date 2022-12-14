import ddf.minim.*;

BufferedReader reader;

PVector pos;
PVector siz;
PVector targetPos;
PVector targetSize;
PVector otherCircleSize;
int maxDist = 200;
Minim minim;
int currentColour = 3;
int currentMessage = 3;
//int fallerFrequency = 30;

int nextSpawnPoint = 0;

boolean fileRead = false;
boolean gameOver = false;
boolean spawn = true;

float score = 0;
float scoreMultiplier = 1;
int hitStreak = 0;
int currentBar = 2; //current colour for the bar

String [] messages = {
  "Perfect!",
  "Close!",
  "Miss!",
  ""
};

color [] colours = {
  color(0, 255, 0, 100),
  color(150, 150, 0, 100),
  color(255, 0, 0, 100),
  color(0, 0, 255, 100)
};

color [] outlineColours = {
  color(0, 255, 0),
  color(150, 150, 0),
  color(255, 0, 0),
  color(0, 0, 255)
};

ArrayList<Faller> fallers;
ArrayList<Integer>currentColours;
ArrayList<Boolean>pressed;

ArrayList<Integer> spawnPoints;

AudioPlayer [] sound = new AudioPlayer[3];

void setup() {
  fallers = new ArrayList<Faller>();
  currentColours = new ArrayList<Integer>();
  pressed = new ArrayList<Boolean>();
  //size(500, 750);
  fullScreen();
  textSize(25);
  pos = new PVector(width/2, 0);
  siz = new PVector(100, 100);
  targetSize = new PVector(100, 100);
  targetPos = new PVector(width/2, height - 100);
  otherCircleSize = new PVector(0, 0);
  
  //loads sounds
  minim = new Minim(this);
  for (int i = 0; i < sound.length; i++) {
    sound[i] = minim.loadFile("sound"+i+".wav");
  }
}

void keyPressed() {
  if (key == ' ') {
    checkFaller();
  }
}

void mousePressed() {
  checkFaller();
}

void checkFaller () { //checks if a faller can be pressed and how far it is
  int m;
  if (getLowestFaller(fallers, pressed) == null) {
    m = 2;
  } else {
    m = assess(getLowestFaller(fallers, pressed).pos);
    currentColours.set(getLowestFallerNum(fallers, pressed), m);
    pressed.set(getLowestFallerNum(fallers, pressed), true);
  }
  sound[m].play();
  sound[m].rewind();
  currentMessage = m;
  score += invert(m) * 100 * scoreMultiplier;
  
  switch (invert(m)) {
    case 0:
      hitStreak--;
      break;
     case 1:
       //do nothing
       break;
    case 2:
      hitStreak++;
      break;
  }
  hitStreak = constrain(hitStreak, 0, 4);
}

int assess(PVector p) { //assesses how close to the target a falling object is
  float dist = targetPos.dist(p);
  int value = 0;
  
  if (dist > maxDist) {
    value = 2;
  } else {
    value = round(map(dist, 0, maxDist, 0, 2));
  }
  return value;
}

void closingRing(PVector posA, PVector p) { //creates the ring that closes around the center circle
  if (p.y < targetPos.y) {
    PVector sizA = new PVector(0, 0);
    
    float dist = targetPos.dist(p);
    sizA.x = map(dist, 0, height, targetSize.x, min(width, height));
    sizA.y = map(dist, 0, height, targetSize.y, min(width, height));
    
    noFill();
    strokeWeight(2);
    stroke(outlineColours[assess(p)]);
    ellipse(posA.x, posA.y, sizA.x, sizA.y);
  }
}

Faller getLowestFaller(ArrayList<Faller> fallers, ArrayList<Boolean> pressed) { //finds the lowest falling object that isn't offscreen
  float max = 0;
  
  for (int i = 0; i < fallers.size(); i++) {
    if (fallers.get(i).pos.y < height && !pressed.get(i)) {
      max = max(max, fallers.get(i).pos.y);
    }
  }
  
  for (int i = 0; i < fallers.size(); i++) {
    if (fallers.get(i).pos.y == max) {
      return fallers.get(i);
    }
  }
  
  //shouldn't get here
  return null;
}

int getLowestFallerNum(ArrayList<Faller> fallers, ArrayList<Boolean> pressed) { //gets the number of the lowest falling object that isn't offscreen
  float max = 0;
  
  for (int i = 0; i < fallers.size(); i++) {
    if (fallers.get(i).pos.y < height && !pressed.get(i)) {
      max = max(max, fallers.get(i).pos.y);
    }
  }
  
  for (int i = 0; i < fallers.size(); i++) {
    if (fallers.get(i).pos.y == max) {
      return i;
    }
  }
  
  //shouldn't get here
  return 0;
}

void draw () {
  if(!gameOver) {
    playGame();
  }
}

int invert(int points) { //makes it so hit give 2 and misses give 0
  int newPoints = 1;
  
  if(points == 0) {
    newPoints = 2;
  }
  if(points == 2) {
    newPoints = 0;
  }
  
  return newPoints;
}

void stop() //closes all sounds
{
  for (int i = 0; i < sound.length; i++) {
    sound[i].close();
  }
  minim.stop();
  super.stop();
}

void addFaller() { //adds a new falling object at specific intervals
  if(spawnPoints.size() == 0) {
    spawn = false;
  } else if (spawnPoints.get(0) != 0 && frameCount % spawnPoints.get(0) == 0) {
    fallers.add(new Faller(pos, siz));
    currentColours.add(3);
    pressed.add(false);
    spawnPoints.remove(0);
  } else if(spawnPoints.get(0) == 0) {
    fallers.add(new Faller(pos, siz));
    currentColours.add(3);
    pressed.add(false);
    spawnPoints.remove(0);
  }
}

ArrayList<Integer> readFile(String filename) { //reads a file to find when to spawn falling objects
  reader = createReader(filename);


  ArrayList<Integer> data = new ArrayList<Integer>();
  String line;
  
  while(true) {
    try{
      line = reader.readLine();
    } catch(Exception e) {
      println(e);
      line = null;
    }
    if(line == null) {
      break;
    } else {
      try {
        data.add(Integer.parseInt(line));
      } catch(Exception e) {
        println(e);
      }
    }
  }
  fileRead = true;
  return data;
}

void playGame() {//plays the game
  if(!fileRead) { //reads the file once
    spawnPoints = readFile("input.txt");
  }
  
  if(spawn) { //stops spawning falling objects if the file is empty
    addFaller();
  }
  
  if(fallers.size() == 0 && !spawn) { //ends the game once all falling objects are off screen
    gameOver = true;
  }
  
  background(100, 100, 100);
  strokeWeight(0);
  fill(255, 0, 0);
  ellipse(targetPos.x, targetPos.y, siz.x, siz.y);
  
  fill(255);
  text(messages[currentMessage], width - 100, 25);
  text((int)score, width - 100, 50);
  
  scoreBar();
  
  if(!gameOver) {
    for (int i = 0; i < fallers.size(); i++) {
      fallers.get(i).fall(colours[currentColours.get(i)]);
      closingRing(targetPos, fallers.get(i).pos);
      if (fallers.get(i).isGone() == true) {
        fallers.remove(i);
        currentColours.remove(i);
        pressed.remove(i);
      }
    }
  }
}

void scoreBar() {//draws a bar based on the score multiplier
  noFill();
  strokeWeight(5);
  stroke(colours[currentBar]);
  rect(25, 25, 50, height - 50);
  scoreMultiplier = pow(2, hitStreak);
  
  noStroke();
  fill(outlineColours[currentBar]);
  float barTop = map(hitStreak, 0, 4, height-25, 25);
  
  rect(25, barTop, 50, height-25-barTop);
  textSize(50);
  fill(255);
  text((int)scoreMultiplier, 100, 40);
}
