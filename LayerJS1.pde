// Joao Santos — Layer 1: Black Hole Event Horizon
// Black and white simulation of a black hole with orbiting starfield,
// accretion disk, photon ring, and beat-reactive shockwaves
// Press Z to trigger a pull effect

class LayerJS1 extends Layer {
  float bassP, midP, trebP, beatP, swirl, shockR, shockA;
  float pull;

  static final int STARS = 220;
  float[] starA = new float[STARS];
  float[] starR = new float[STARS];
  float[] starS = new float[STARS];

  static final int RAYS = 140;
  float[] rayA = new float[RAYS];
  float[] rayJ = new float[RAYS];

  LayerJS1(color c) {
    super(c);
    // Initialize star positions and brightness
    for (int i = 0; i < STARS; i++) {
      starA[i] = random(TWO_PI);
      starR[i] = random(0.6, 1.8);
      starS[i] = random(0.4, 1.6);
    }
    for (int i = 0; i < RAYS; i++) {
      rayA[i] = random(TWO_PI);
      rayJ[i] = random(0.6, 1.4);
    }
  }

  void update(float t, float bass, float mid, float treble,
              float burstA, float burstB, float burstC,
              boolean isBeat, float beatStrength, float flashVal) {

    // Smooth all audio parameters
    bassP = lerp(bassP, bass, 0.18);
    midP  = lerp(midP,  mid,  0.20);
    trebP = lerp(trebP, treble, 0.30);
    beatP = lerp(beatP, beatStrength, 0.25);
    swirl += 0.006 + midP * 0.08;

    // Trigger shockwave on beat (if not already active)
    if (isBeat && shockA < 0.2) {
      shockR = 0;
      shockA = 1;
    }
    shockR += 6 + beatStrength * 8 + pull * 14;
    shockA *= 0.94;
    pull *= 0.92;
  }

  void keyPressed(char k) {
    if (k == 'z' || k == 'Z') {
      pull = 1.0;
      shockR = 0;
      shockA = 1.0;
      swirl += 0.8;
    }
  }

  void drawLayer(PGraphics g) {
    g.clear();
    g.pushStyle();
    float cx = width * 0.5;
    float cy = height * 0.5;
    float base = min(width, height) * 0.18;
    float horizonR = base * (1 + bassP * 0.35);
    float diskR   = horizonR * 2.4;
    float photonR = horizonR * 1.08;

    // Draw starfield with warp toward center on pull
    g.noStroke();
    for (int i = 0; i < STARS; i++) {
      float a = starA[i] + swirl * (0.15 + pull * 1.2) * starS[i];
      float rr = starR[i] * min(width, height) * 0.5 * (1 + pull * 0.6);
      float x = cx + cos(a) * rr;
      float y = cy + sin(a) * rr;
      float br = 180 * starS[i] + trebP * 70 + pull * 80;
      g.fill(br);
      float sz = 1 + starS[i] * (1 + trebP * 2) + pull * 1.5;
      g.ellipse(x, y, sz, sz);
    }

    // Accretion disk — concentric warped rings
    g.noFill();
    int ringCount = 40;
    int steps = 60;
    for (int r = 0; r < ringCount; r++) {
      float rad = lerp(photonR, diskR, r / (float)ringCount);
      float warp = sin(swirl * 2 + r * 0.35) * (4 + midP * 18);
      float bright = 255 * pow(1 - r / (float)ringCount, 1.6) * (0.35 + midP * 0.9);
      bright = constrain(bright, 0, 255);
      g.stroke(bright);
      g.strokeWeight(1 + trebP * 1.2);
      g.beginShape();
      for (int k = 0; k <= steps; k++) {
        float a = TWO_PI * k / steps;
        float squash = 1 + 0.35 * sin(a * 2 + swirl);
        float rx = (rad + warp * cos(a + swirl * 0.6)) * squash;
        float ry = (rad + warp * cos(a + swirl * 0.6)) * 0.55;
        float x = cx + cos(a) * rx;
        float y = cy + sin(a) * ry;
        g.vertex(x, y);
      }
      g.endShape(CLOSE);
    }

    // Photon ring — bright thin halos around the event horizon
    g.noFill();
    for (int i = 0; i < 4; i++) {
      float a = 255 - i * 50;
      g.stroke(a);
      g.strokeWeight(1.5 + i * 0.6 + trebP * 2 + pull * 3);
      float bulge = pull * horizonR * 0.6;
      g.ellipse(cx, cy, photonR * 2 + i + bulge, photonR * 2 + i + bulge);
    }

    // Shockwave expanding on beat
    if (shockA > 0.02) {
      g.noFill();
      g.stroke(255, shockA * 220);
      g.strokeWeight(2 + shockA * 4);
      g.ellipse(cx, cy, shockR * 2, shockR * 2);
    }

    // Event horizon — pure black disk with soft white rim
    g.noStroke();
    g.fill(255, 90 + beatP * 120 + pull * 140);
    float rim = horizonR * 2 + 6 + pull * horizonR * 0.8;
    g.ellipse(cx, cy, rim, rim);
    g.fill(0);
    g.ellipse(cx, cy, horizonR * 2, horizonR * 2);

    g.popStyle();
  }
}
