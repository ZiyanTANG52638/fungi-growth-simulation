import processing.serial.*;

// Mycelial Growth Simulation with FSR Pressure Control
// FSR data comes from Arduino via Serial

// Serial communication
Serial myPort;
int sensorValue = 0;
boolean portFound = false;

// Mycelial Growth System
ArrayList<GrowthPoint> growthPoints = new ArrayList<GrowthPoint>();
ArrayList<FloatingLabel> floatingLabels = new ArrayList<FloatingLabel>();

// Color variables
color youngColor;
color oldColor;
PVector lastMousePosition = new PVector(0, 0);

// Performance variables
int maxGrowthPoints = 25;
int maxBranchesPerSystem = 80;
int nodeLifespan = 15000; // 15 seconds

void setup() {
  size(1200, 800, P2D);
  background(0);
  colorMode(HSB, 100);
  
  // Set colors - golden hues
  youngColor = color(50, 90, 75);  // Bright golden yellow
  oldColor = color(42, 85, 65);    // Darker amber
  
  // Initialize mouse position tracker
  lastMousePosition = new PVector(mouseX, mouseY);
  
  // Setup serial connection
  setupSerialConnection();
  
  // Print instructions
  println("FSR-Controlled Mycelial Growth");
  println("Apply pressure to the FSR to create growth");
}

void draw() {
  // Fade background for trail effect
  fill(0, 20);
  noStroke();
  rect(0, 0, width, height);
  
  // Create growth based on FSR pressure
  if (portFound) {
    processSerialData();
  }
  
  // Update and display mycelial growth
  updateGrowthSystem();
  
  // Update and display floating labels
  updateFloatingLabels();
  
  // Display parameters
  displayParameters();
}

void setupSerialConnection() {
  // List all available serial ports
  println("Available serial ports:");
  for (int i = 0; i < Serial.list().length; i++) {
    println(i + ": " + Serial.list()[i]);
  }
  
  // Try to connect to Arduino port
  try {
    // Use the correct port for your Arduino (port 3 in your case)
    String portName = "/dev/cu.usbserial-110"; // Use this specific port
    
    // Alternative: If you want to select by index instead
    // String portName = Serial.list()[3]; // Index 3 corresponds to /dev/cu.usbserial-110
    
    myPort = new Serial(this, portName, 9600);
    myPort.bufferUntil('\n'); // Read until newline
    println("Connected to: " + portName);
    portFound = true;
  } catch (Exception e) {
    println("Error connecting to serial port: " + e.getMessage());
    println("FSR control disabled - using mouse clicks instead");
    portFound = false;
  }
}

void serialEvent(Serial port) {
  // Read and parse the incoming data
  String inString = port.readStringUntil('\n');
  if (inString != null) {
    inString = trim(inString);
    try {
      sensorValue = Integer.parseInt(inString);
      
      // Create growth based on pressure intensity
      float intensity = map(sensorValue, 0, 100, 0.1, 1.0);
      
      // Only create growth when pressure exceeds threshold
      if (sensorValue > 10) {
        // Higher intensity = more growth points and larger growth
        if (random(1) < intensity * 0.3) {
          // Create growth at random position
          float x = random(width);
          float y = random(height);
          growthPoints.add(new GrowthPoint(x, y, intensity));
          
          // Add floating label showing pressure
          floatingLabels.add(new FloatingLabel(x, y, "Pressure: " + sensorValue));
        }
      }
      
      // Debug output
      println("FSR: " + sensorValue);
    } catch (Exception e) {
      println("Error parsing sensor data: " + e.getMessage());
    }
  }
}

void processSerialData() {
  // Process the current sensor reading
  if (sensorValue > 10) {
    float intensity = map(sensorValue, 10, 100, 0.1, 1.0);
    
    // Trigger growth with varying probability based on pressure
    if (random(1) < intensity * 0.05) {
      float x = random(width);
      float y = random(height);
      growthPoints.add(new GrowthPoint(x, y, intensity));
    }
    
    // Grow existing points more aggressively with higher pressure
    if (growthPoints.size() > 0 && random(1) < intensity * 0.2) {
      int idx = floor(random(growthPoints.size()));
      growthPoints.get(idx).addBranches(intensity);
    }
  }
}

// Add growth on mouse click (backup if no serial connection)
void mousePressed() {
  // Add growth point at mouse click position
  growthPoints.add(new GrowthPoint(mouseX, mouseY, 0.5));
  println("Growth point added at: " + mouseX + ", " + mouseY);
}

void updateGrowthSystem() {
  // Update all growth points
  for (int i = growthPoints.size() - 1; i >= 0; i--) {
    GrowthPoint gp = growthPoints.get(i);
    gp.update();
    gp.display();
    
    // Remove growth points with no branches
    if (gp.branches.size() == 0 && millis() - gp.creationTime > 8000) {
      growthPoints.remove(i);
    }
  }
  
  // Limit growth points for performance
  while (growthPoints.size() > maxGrowthPoints) {
    // Remove oldest growth point
    growthPoints.remove(0);
  }
}

void updateFloatingLabels() {
  for (int i = floatingLabels.size() - 1; i >= 0; i--) {
    FloatingLabel label = floatingLabels.get(i);
    label.update();
    label.display();
    if (label.isDead()) {
      floatingLabels.remove(i);
    }
  }
}

void displayParameters() {
  // Display parameter values
  fill(0, 0, 100); // White in HSB
  textSize(14);
  text("FSR Pressure: " + sensorValue, 20, height - 40);
  text("Growth Points: " + growthPoints.size(), 20, height - 20);
  
  // Display pressure meter
  int meterWidth = 150;
  int meterHeight = 20;
  int x = width - meterWidth - 20;
  int y = 20;
  
  // Draw meter background
  noFill();
  stroke(0, 0, 70);
  rect(x, y, meterWidth, meterHeight);
  
  // Draw meter fill based on pressure
  if (sensorValue > 0) {
    float fillWidth = map(sensorValue, 0, 100, 0, meterWidth);
    fill(map(sensorValue, 0, 100, 42, 50), 90, 75);
    noStroke();
    rect(x, y, fillWidth, meterHeight);
  }
  
  // Draw label
  fill(0, 0, 100);
  text("Pressure", x, y + meterHeight + 15);
}

// Growth Point - origin of branch systems
class GrowthPoint {
  PVector pos;
  ArrayList<Branch> branches = new ArrayList<Branch>();
  float creationTime;
  float intensity;
  
  GrowthPoint(float x, float y, float _intensity) {
    pos = new PVector(x, y);
    creationTime = millis();
    intensity = _intensity;
    
    // Create branches based on intensity
    int branchCount = floor(random(5, 10) * map(intensity, 0.1, 1.0, 0.8, 1.5));
    
    for (int i = 0; i < branchCount; i++) {
      // Evenly distribute branches in all directions
      float angle = i * TWO_PI / branchCount + random(-0.2, 0.2);
      float len = random(20, 50) * intensity;
      float thick = random(0.3, 1.0) * intensity;
      branches.add(new Branch(x, y, angle, len, thick));
    }
  }
  
  void update() {
    // Update all branches
    for (int i = branches.size() - 1; i >= 0; i--) {
      Branch branch = branches.get(i);
      branch.update();
      
      // Remove dead branches
      if (branch.isDead()) {
        branches.remove(i);
      }
    }
    
    // Mark branches for death after lifespan
    float age = millis() - creationTime;
    if (age > nodeLifespan) {
      for (Branch branch : branches) {
        if (!branch.isDying) {
          branch.isDying = true;
        }
      }
    }
  }
  
  void display() {
    // Display all branches
    for (Branch branch : branches) {
      branch.display();
    }
    
    // Draw the central point
    noStroke();
    fill(50, 90, 75, 100);
    ellipse(pos.x, pos.y, 6, 6);
  }
  
  void addBranches(float intensity) {
    // Add more branches when triggered
    int newBranches = floor(random(1, 3));
    for (int i = 0; i < newBranches; i++) {
      float angle = random(TWO_PI);
      float len = random(15, 35) * intensity;
      float thick = random(0.3, 0.9) * intensity;
      branches.add(new Branch(pos.x, pos.y, angle, len, thick));
    }
  }
}

// Branch class - represents a single branch in the mycelial network
class Branch {
  PVector start, end;
  PVector dir;
  float length;
  float thickness;
  float growSpeed;
  float growProgress = 0;
  float hue;
  float lifespan = 255;
  boolean isDying = false;
  ArrayList<Branch> children = new ArrayList<Branch>();
  ArrayList<TurnPoint> turnPoints = new ArrayList<TurnPoint>();
  float currentAngle;
  
  Branch(float x, float y, float angle, float len, float thick) {
    start = new PVector(x, y);
    dir = PVector.fromAngle(angle);
    length = len;
    thickness = thick;
    growSpeed = random(0.005, 0.02);
    currentAngle = angle;
    hue = random(42, 58);
    
    // Add natural turns
    int numTurns = floor(random(0, 3));
    for (int i = 0; i < numTurns; i++) {
      float turnPos = random(0.2, 0.8);
      float turnAmount = random(-PI/6, PI/6);
      turnPoints.add(new TurnPoint(turnPos, turnAmount));
    }
    
    // Sort turn points by position
    if (turnPoints.size() > 1) {
      turnPoints.sort((a, b) -> Float.compare(a.position, b.position));
    }
    
    updateEndPosition();
  }
  
  void update() {
    // Grow the branch
    if (growProgress < 1) {
      growProgress += growSpeed;
      if (growProgress > 1) {
        growProgress = 1;
        // Create child branches
        if (random(1) < 0.2 && thickness > 0.3) {
          createChildren();
        }
      }
    }
    
    updateEndPosition();
    
    // Update children
    for (int i = children.size() - 1; i >= 0; i--) {
      Branch child = children.get(i);
      child.update();
      
      if (child.isDead()) {
        children.remove(i);
      }
    }
    
    // Fade if dying
    if (isDying) {
      lifespan -= 2.0;
    }
  }
  
  void updateEndPosition() {
    PVector currentPos = start.copy();
    float currentLength = length * growProgress;
    float remainingLength = currentLength;
    float lastTurnPos = 0;
    currentAngle = dir.heading();
    
    // Apply turns
    for (TurnPoint turn : turnPoints) {
      float turnPosLength = length * turn.position;
      
      if (turnPosLength > currentLength) break;
      
      float segmentLength = turnPosLength - (length * lastTurnPos);
      currentPos.x += cos(currentAngle) * segmentLength;
      currentPos.y += sin(currentAngle) * segmentLength;
      currentAngle += turn.amount;
      remainingLength -= segmentLength;
      lastTurnPos = turn.position;
    }
    
    currentPos.x += cos(currentAngle) * remainingLength;
    currentPos.y += sin(currentAngle) * remainingLength;
    end = currentPos;
  }
  
  void display() {
    if (growProgress <= 0) return;
    
    // For branches with turns
    if (turnPoints.size() > 0) {
      PVector currentPos = start.copy();
      float currentDrawAngle = dir.heading();
      float lastTurnPos = 0;
      float currentLength = length * growProgress;
      
      for (int i = 0; i < turnPoints.size(); i++) {
        TurnPoint turn = turnPoints.get(i);
        float turnPosLength = length * turn.position;
        
        if (turnPosLength > currentLength) {
          float segmentLength = currentLength - (length * lastTurnPos);
          PVector nextPos = new PVector(
            currentPos.x + cos(currentDrawAngle) * segmentLength,
            currentPos.y + sin(currentDrawAngle) * segmentLength
          );
          
          stroke(hue, 85, 70, lifespan);
          strokeWeight(thickness);
          line(currentPos.x, currentPos.y, nextPos.x, nextPos.y);
          break;
        }
        
        float segmentLength = turnPosLength - (length * lastTurnPos);
        PVector nextPos = new PVector(
          currentPos.x + cos(currentDrawAngle) * segmentLength,
          currentPos.y + sin(currentDrawAngle) * segmentLength
        );
        
        stroke(hue, 85, 70, lifespan);
        strokeWeight(thickness);
        line(currentPos.x, currentPos.y, nextPos.x, nextPos.y);
        
        currentPos = nextPos.copy();
        currentDrawAngle += turn.amount;
        lastTurnPos = turn.position;
      }
      
      if (length * lastTurnPos < currentLength) {
        float remainingLength = currentLength - (length * lastTurnPos);
        PVector finalPos = new PVector(
          currentPos.x + cos(currentDrawAngle) * remainingLength,
          currentPos.y + sin(currentDrawAngle) * remainingLength
        );
        
        stroke(hue, 85, 70, lifespan);
        strokeWeight(thickness);
        line(currentPos.x, currentPos.y, finalPos.x, finalPos.y);
      }
    } else {
      stroke(hue, 85, 70, lifespan);
      strokeWeight(thickness);
      line(start.x, start.y, end.x, end.y);
    }
    
    // Draw node at end
    if (growProgress == 1) {
      noStroke();
      fill(hue, 90, 75, lifespan);
      float nodeSizeFactor = map(sin(thickness * 5 + length * 0.1), -1, 1, 0.8, 1.5);
      ellipse(end.x, end.y, thickness * (1.2 + nodeSizeFactor), thickness * (1.2 + nodeSizeFactor));
    }
    
    // Display children
    for (Branch child : children) {
      child.display();
    }
  }
  
  void createChildren() {
    int numChildren = floor(random(1, 3));
    for (int i = 0; i < numChildren; i++) {
      float angle = currentAngle + random(-PI/4, PI/4);
      float len = length * random(0.6, 0.9);
      float thick = thickness * random(0.5, 0.8);
      Branch child = new Branch(end.x, end.y, angle, len, thick);
      children.add(child);
    }
  }
  
  boolean isDead() {
    return lifespan <= 0;
  }
}

// Class to represent a turn in a branch
class TurnPoint {
  float position; // 0-1 position along branch length
  float amount;   // Amount to turn in radians
  
  TurnPoint(float pos, float amt) {
    position = pos;
    amount = amt;
  }
}

// Floating Label class for data visualization
class FloatingLabel {
  PVector pos;
  String text;
  float opacity = 255;
  float size = 14;
  
  FloatingLabel(float x, float y, String txt) {
    pos = new PVector(x, y);
    text = txt;
  }
  
  void update() {
    opacity -= 3;
    size += 0.1;
    pos.y -= 0.5;
  }
  
  void display() {
    textSize(size);
    fill(45, 70, 100, opacity);
    textAlign(CENTER, CENTER);
    text(text, pos.x, pos.y);
  }
  
  boolean isDead() {
    return opacity <= 0;
  }
}
