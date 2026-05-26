// Joao Santos — Layer 2: Infinite Triangle Tunnel
// A receding tunnel of rotating equilateral triangles with rainbow colors
// Reacts to global audio and optional microphone input
// Press X for a speed kick

import processing.sound.*;

class LayerJS2 extends Layer {
  float bassP, midP, trebP, beatP;
  float zPos;
  float roll;
  float shakeX, shakeY;
  float kick;

  // Mic input using AudioIn + Amplitude (no extra FFT)
  AudioIn micIn;
  Amplitude micAmp;
  boolean micReady = false;
  boolean micTried = false;
  float micVol;

  static final int RINGS = 30;
  static final float SPACING = 1.6;
  static final float NEAR = 0.08;
  static final float FAR  = 48;

  float[] ringSpin = new float[RINGS];
  float[] ringPhase = new float[RINGS];

  color[] rainbow = {
    color(255,  40,  80),
    color(255, 140,  40),
    color(255, 230,  60),
    color( 60, 230, 120),
    color( 60, 180, 255),
    color(140,  80, 240),
    color(230,  80, 220)
  };

  LayerJS2(color c) {
    super(c);
    for (int i = 0; i < RINGS; i++) {
      ringSpin[i] = random(-0.3, 0.3);
      ringPhase[i] = random(TWO_PI);
    }
  }

  void initMic() {
    if (micTried) return;
    micTried = true;
    try {
      micIn = new AudioIn(prog3proj.this, 0);
      micIn.start();
      micAmp = new Amplitude(prog3proj.this);
      micAmp.input(micIn);
      micReady = true;
    } catch (Exception e) {
      micReady = false;
    }
  }

  void readMic() {
    if (!micReady) return;
    float raw = micAmp.analyze();
    micVol = lerp(micVol, constrain(raw * 12, 0, 1), 0.35);
  }

  void update(float t, float bass, float mid, float treble,
              float burstA, float burstB, float burstC,
              boolean isBeat, float beatStrength, float flashVal) {

    initMic();
    readMic();

    bassP = lerp(bassP, bass,  0.25);
    midP  = lerp(midP,  mid,   0.22);
    trebP = lerp(trebP, treble, 0.30);
    beatP = lerp(beatP, beatStrength, 0.30);

    // Forward speed driven by audio and mic volume
    float speed = 0.22 + bassP * 0.45 + beatP * 0.30 + kick * 0.7
                + micVol * 0.5;
    zPos += speed;

    roll += 0.005 + midP * 0.02 + micVol * 0.04;
    if (isBeat) roll += random(-0.08, 0.08);

    // Camera shake
    float shakeAmt = (beatP * 10 + kick * 20 + micVol * 25) * (1 + trebP);
    shakeX = lerp(shakeX, random(-shakeAmt, shakeAmt), 0.4);
    shakeY = lerp(shakeY, random(-shakeAmt, shakeAmt), 0.4);

    kick  *= 0.90;
    micVol *= 0.96;
  }

  void keyPressed(char k) {
    if (k == 'x' || k == 'X') kick = 1.0;
  }

  void drawLayer(PGraphics g) {
    g.clear();
    g.pushStyle();

    float cx = width * 0.5 + shakeX;
    float cy = height * 0.5 + shakeY;
    float focal = min(width, height) * 0.85;

    g.noStroke();
    // Semi-transparent black for motion blur effect
    g.fill(0, 50);
    g.rect(0, 0, width, height);

    float wrap = RINGS * SPACING;

    // Draw rings from far to near
    for (int i = RINGS - 1; i >= 0; i--) {
      float z = ((i * SPACING) - (zPos % wrap) + wrap) % wrap;
      if (z < NEAR) continue;

      float scale = focal / z;
      float r = 4.0 * scale;
      if (r > max(width, height) * 1.8) continue;

      float depthT = constrain(1 - z / FAR, 0, 1);
      float alpha = depthT * 200;

      // Cycle through rainbow colors based on position
      int colorIdx = ((i + (int)(zPos * 0.5)) % rainbow.length + rainbow.length) % rainbow.length;
      color c = rainbow[colorIdx];

      float ang = ringPhase[i] + ringSpin[i] * zPos * 0.05 + roll
                + sin(zPos * 0.07 + i * 0.25) * (0.12 + trebP * 0.3);

      // Pre-compute equilateral triangle vertices
      float ca = cos(ang);
      float sa = sin(ang);

      float x0 = cx + (-sa * -r + ca * 0);
      float y0 = cy + ( ca * -r + sa * 0);
      float x1 = cx + (-sa * (r * 0.5) + ca * (-r * 0.866));
      float y1 = cy + ( ca * (r * 0.5) + sa * (-r * 0.866));
      float x2 = cx + (-sa * (r * 0.5) + ca * ( r * 0.866));
      float y2 = cy + ( ca * (r * 0.5) + sa * ( r * 0.866));

      g.noFill();
      g.stroke(red(c), green(c), blue(c), alpha);
      g.strokeWeight(1.5 + beatP + kick * 1.2 + micVol * 1.5);
      g.triangle(x0, y0, x1, y1, x2, y2);

      // White inner stroke
      g.stroke(255, alpha * 0.7);
      g.strokeWeight(1.0);
      g.triangle(x0, y0, x1, y1, x2, y2);
    }

    // Mic-off indicator
    if (!micReady) {
      g.fill(255, 80);
      g.textAlign(RIGHT, TOP);
      g.textSize(11);
      g.text("mic off", width - 12, 12);
    }

    g.popStyle();
  }
}
