// João Oliveira — layer 3
class LayerJO3 extends Layer {
  color layerCol;
  
  // Planet Caravan lyrics
  String[] lyrics = {
    "We sail through endless skies",
    "Stars shine like eyes",
    "The black night sighs",
    "The moon in silver trees",
    "Falls down in tears",
    "Light of the night",
    "The earth, a purple blaze",
    "Of sapphires and haze"
  };
  
  int currentLine = 0;
  float time = 0;
  
  float textX;
  float textY;
  boolean positionInitialized = false;

  ArrayList<BlockParticle> particles = new ArrayList<BlockParticle>();

  LayerJO3(color c) { 
    super(c); 
    this.layerCol = c;
  }
  
  void pickRandomPosition() {
    textX = random(width * 0.2, width * 0.8);
    textY = random(height * 0.2, height * 0.5); // Keep it slightly higher so we can watch them fall
  }
  
  void update(float t, float bass, float mid, float treble,
              float burstA, float burstB, float burstC,
              boolean isBeat, float beatStrength, float flashVal) {
    this.time = t;
    
    // Update all falling blocks
    for (int i = particles.size() - 1; i >= 0; i--) {
      BlockParticle p = particles.get(i);
      p.update(height, bass); // Pass the screen height for floor collision
      if (p.isDead()) {
        particles.remove(i);
      }
    }
  }
  
  void draw() {
    if (!positionInitialized) {
      pickRandomPosition();
      positionInitialized = true;
    }

    textSize(48);
    textAlign(CENTER, CENTER);
    fill(layerCol);
    
    // Float the intact text gently before it breaks
    float floatY = textY + sin(time * 2) * 15;
    text(lyrics[currentLine], textX, floatY);
    
    // Draw the collapsed blocks
    for (BlockParticle p : particles) {
      p.draw();
    }
  }

  void keyPressed(char k) {
    explodeText();
  }

  void explodeText() {
    String txt = lyrics[currentLine];
    textSize(48);
    float totalWidth = textWidth(txt);
    
    float startX = textX - (totalWidth / 2);
    float floatY = textY + sin(time * 2) * 15;

    for (int i = 0; i < txt.length(); i++) {
      char c = txt.charAt(i);
      if (c == ' ') {
        startX += textWidth(" ");
        continue;
      }
      
      // Spawn heavier, larger, geometric blocks per letter to match the OFFF style
      // We spawn 2-3 constituent "pieces" of each letter
      int numPieces = int(random(2, 4));
      for(int j = 0; j < numPieces; j++) {
         particles.add(new BlockParticle(startX + textWidth(c)/2, floatY, layerCol));
      }
      startX += textWidth(c); 
    }
    
    currentLine = (currentLine + 1) % lyrics.length;
    pickRandomPosition();
  }
}

// --- Helper Class for the Heavy Decomposed Letters ---
class BlockParticle {
  float x, y;
  float vx, vy;
  float rot, rotSpeed;
  float life, maxLife;
  int shapeType; // 0 = Circle, 1 = Thick Vertical Bar, 2 = Thick Horizontal Bar
  color pColor;
  float w, h; // Width and height for the blocks

  BlockParticle(float x, float y, color c) {
    this.x = x + random(-10, 10); 
    this.y = y + random(-10, 10);
    
    // Explosive burst outward
    this.vx = random(-6, 6);
    this.vy = random(-5, 2); 
    
    this.rot = random(TWO_PI);
    this.rotSpeed = random(-0.2, 0.2);
    
    this.maxLife = 400; // Live longer so they pile up on the floor
    this.life = maxLife;
    
    this.shapeType = int(random(3));
    this.pColor = c;
    
    // Make them large and chunky like the OFFF projection
    if (this.shapeType == 0) {
      this.w = random(20, 50);
      this.h = this.w; // Circle
    } else if (this.shapeType == 1) {
      this.w = random(10, 20);
      this.h = random(40, 80); // Tall bar
    } else {
      this.w = random(40, 80);
      this.h = random(10, 20); // Wide bar
    }
  }

  void update(float screenHeight, float bass) {
    // 1. Heavy Gravity
    vy += 0.6; 
    
    // 2. Air friction
    vx *= 0.98;
    vy *= 0.99;

    x += vx;
    y += vy;
    
    // 3. Floor Collision Logic
    float floorY = screenHeight - (max(w, h) / 2);
    if (y >= floorY) {
      y = floorY;
      vy *= -0.3; // Bounce slightly
      vx *= 0.7;  // Friction against the ground
      
      // Stop rotating when it hits the ground
      rotSpeed *= 0.7; 
      
      // Bump slightly with the bass when on the ground
      if (bass > 0.5) {
        vy -= bass * 2; 
        vx += random(-bass, bass);
      }
    } else {
      // Keep spinning while falling
      rot += rotSpeed; 
    }

    life--;
  }

  void draw() {
    // Fade out very slowly only at the very end of their life
    float alpha = 255;
    if (life < 60) {
      alpha = map(life, 0, 60, 0, 255);
    }

    pushMatrix();
    translate(x, y);
    rotate(rot);
    noStroke();
    
    // Solid, opaque colors to mimic the silhouette look
    fill(red(pColor) * 0.8, green(pColor) * 0.8, blue(pColor) * 0.8, alpha); // Slightly darker for depth

    // Draw chunky geometric shapes
    if (shapeType == 0) {
      ellipse(0, 0, w, h);
    } else {
      rectMode(CENTER);
      rect(0, 0, w, h);
      rectMode(CORNER); 
    }
    popMatrix();
  }

  boolean isDead() {
    return life <= 0;
  }
}