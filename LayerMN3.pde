// Miguel Neto — MN3
// Screen border shake effect triggered by key press (D)

class LayerMN3 extends Layer {

  float shakeIntensity = 0;   // current shake amount (decays)
  float shakeDecay     = 0.88; // how fast it fades
  float maxShake       = 28;   // max border displacement in px

  LayerMN3(color c) { super(c); }

  void update(float t,
              float bass, float mid, float treble,
              float burstA, float burstB, float burstC,
              boolean isBeat, float beatStrength, float flashVal) {
    shakeIntensity *= shakeDecay;
  }

  void drawLayer(PGraphics g) {
    g.clear();
    if (shakeIntensity < 0.5) return;

    float s = shakeIntensity;
    int   segments = 32;   // how many segments per edge

    g.stroke(255, 255, 255, min(shakeIntensity * 8, 220));
    g.strokeWeight(2.5);
    g.noFill();

    // Top edge
    g.beginShape();
    for (int i = 0; i <= segments; i++) {
      float x = map(i, 0, segments, 0, width);
      float y = random(-s, s);
      g.vertex(x, y);
    }
    g.endShape();

    // Bottom edge
    g.beginShape();
    for (int i = 0; i <= segments; i++) {
      float x = map(i, 0, segments, 0, width);
      float y = height + random(-s, s);
      g.vertex(x, y);
    }
    g.endShape();

    // Left edge
    g.beginShape();
    for (int i = 0; i <= segments; i++) {
      float x = random(-s, s);
      float y = map(i, 0, segments, 0, height);
      g.vertex(x, y);
    }
    g.endShape();

    // Right edge
    g.beginShape();
    for (int i = 0; i <= segments; i++) {
      float x = width + random(-s, s);
      float y = map(i, 0, segments, 0, height);
      g.vertex(x, y);
    }
    g.endShape();
  }

  void keyPressed(char k) {
    if (k == 'd' || k == 'D') {
      shakeIntensity = maxShake;
    }
  }
}
