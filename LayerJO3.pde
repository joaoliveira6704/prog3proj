// Joao Oliveira — Layer 3: Lyrics + Lissajous Roaming + Text Explosion
// Displays Planet Caravan lyrics that drift in Lissajous curves
// Press E to explode the current text into falling block particles and advance to the next line

class LayerJO3 extends Layer {
  color layerCol;

  // Planet Caravan lyrics (Black Sabbath)
  String[] lyrics = {
    "We sail through endless skies",
    "Stars shine like eyes",
    "The black night sighs",
    "The moon in silver trees",
    "Falls down in tears",
    "Light of the night",
    "The earth, a purple blaze",
    "Of sapphire and haze",
    "In orbit always",
    "While down below the trees",
    "Bathed in cool breeze",
    "Silver starlight breaks down the night",
    "And so we pass on the crimson eye",
    "Of great god Mars",
    "As we travel",
    "The universe",
    "In the heat of the sun",
    "A cold world of ice",
    "Planet Caravan",
    "We wait for the dawn",
    "To come and take us away",
    "Planet Caravan",
    "Resting in the noonday sun",
    "We wait for the dawn",
    "To come and take us away",
    "To come and take us away",
    "Light of the night",
    "We wait for the dawn",
    "To come and take us away",
    "To come and take us away"
  };

  int currentLine = 0;
  float time = 0;
  float currentBass = 0;

  // Dynamic positioning variables
  float currentTextX;
  float currentTextY;
  float currentTextSize;

  ArrayList<BlockParticle> particles = new ArrayList<BlockParticle>();

  LayerJO3(color c) {
    super(c);
    this.layerCol = c;
  }

  void update(float t, float bass, float mid, float treble,
              float burstA, float burstB, float burstC,
              boolean isBeat, float beatStrength, float flashVal) {
    this.time = t;

    // Smooth the bass slightly
    this.currentBass = lerp(this.currentBass, bass, 0.1);

    // Update all falling block particles
    for (int i = particles.size() - 1; i >= 0; i--) {
      BlockParticle p = particles.get(i);
      p.update(height, bass);
      if (p.isDead()) {
        particles.remove(i);
      }
    }
  }

  void drawLayer(PGraphics g) {
    g.clear();
    // Compute roaming text position using Lissajous curves for smooth drifting
    float roamX = sin(time * 0.3) * cos(time * 0.15) * (width * 0.35);
    float roamY = cos(time * 0.2) * sin(time * 0.25) * (height * 0.35);

    currentTextX = (width / 2) + roamX;
    currentTextY = (height / 2) + roamY;

    // Text size breathes gently with sine and bass
    currentTextSize = 48 + (sin(time * 0.5) * 5) + (currentBass * 15);

    g.textSize(currentTextSize);
    g.textAlign(CENTER, CENTER);

    String displayTxt = lyrics[currentLine].toUpperCase();

    // Draw colored shadow for a psych effect
    g.fill(red(layerCol) * 0.5, green(layerCol) * 0.5, blue(layerCol) * 0.5, 150);
    g.text(displayTxt, currentTextX + 3, currentTextY + 3);

    // Draw main text
    g.fill(layerCol);
    g.text(displayTxt, currentTextX, currentTextY);

    // Draw falling block particles from text explosions
    for (BlockParticle p : particles) {
      p.draw(g);
    }
  }

  void keyPressed(char k) {
    explodeText();
  }

  // Explode the current line into falling block particles and advance to the next line
  void explodeText() {
    String txt = lyrics[currentLine].toUpperCase();
    textSize(currentTextSize);
    float totalWidth = textWidth(txt);

    float startX = currentTextX - (totalWidth / 2);

    for (int i = 0; i < txt.length(); i++) {
      char c = txt.charAt(i);
      if (c == ' ') {
        startX += textWidth(" ");
        continue;
      }

      int numPieces = int(random(2, 4));
      for(int j = 0; j < numPieces; j++) {
         particles.add(new BlockParticle(startX + textWidth(c)/2, currentTextY, layerCol));
      }
      startX += textWidth(c);
    }

    currentLine = (currentLine + 1) % lyrics.length;
  }
}

// Helper class for the decomposed letter blocks
class BlockParticle {
  float x, y;
  float vx, vy;
  float rot, rotSpeed;
  float life, maxLife;
  int shapeType;
  color pColor;
  float w, h;

  BlockParticle(float x, float y, color c) {
    this.x = x + random(-10, 10);
    this.y = y + random(-10, 10);

    // Explosion burst velocity
    this.vx = random(-6, 6);
    this.vy = random(-5, 2);

    this.rot = random(TWO_PI);
    this.rotSpeed = random(-0.2, 0.2);

    this.maxLife = 400;
    this.life = maxLife;

    this.shapeType = int(random(3));
    this.pColor = c;

    // Random block sizes
    if (this.shapeType == 0) {
      this.w = random(20, 50);
      this.h = this.w;
    } else if (this.shapeType == 1) {
      this.w = random(10, 20);
      this.h = random(40, 80);
    } else {
      this.w = random(40, 80);
      this.h = random(10, 20);
    }
  }

  // Apply gravity, bounce on floor, react to bass
  void update(float screenHeight, float bass) {
    vy += 0.6;

    vx *= 0.98;
    vy *= 0.99;

    x += vx;
    y += vy;

    float floorY = screenHeight - (max(w, h) / 2);
    if (y >= floorY) {
      y = floorY;
      vy *= -0.3;
      vx *= 0.7;
      rotSpeed *= 0.7;

      // Extra bounce on strong bass
      if (bass > 0.5) {
        vy -= bass * 2;
        vx += random(-bass, bass);
      }
    } else {
      rot += rotSpeed;
    }

    life--;
  }

  void draw(PGraphics g) {
    float alpha = 255;
    if (life < 60) {
      alpha = map(life, 0, 60, 0, 255);
    }

    g.pushMatrix();
    g.translate(x, y);
    g.rotate(rot);
    g.noStroke();

    g.fill(red(pColor) * 0.8, green(pColor) * 0.8, blue(pColor) * 0.8, alpha);

    if (shapeType == 0) {
      g.ellipse(0, 0, w, h);
    } else {
      g.rectMode(CENTER);
      g.rect(0, 0, w, h);
      g.rectMode(CORNER);
    }
    g.popMatrix();
  }

  boolean isDead() {
    return life <= 0;
  }
}
