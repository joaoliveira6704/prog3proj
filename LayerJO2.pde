import processing.sound.*;

class LayerJO2 extends Layer {

  ArrayList<Node> nodes;
  float currentT;
  float bassS, midS, trebS;
  float growthAge;
  float visibility;

  // Independent mic input
  AudioIn mic;
  FFT micFFT;
  int micBands = 64;
  float[] micSpec;
  float micAmp, micBass, micMid, micTreble;
  float micBeat;
  float[] avgE;

  static final int MAX_NODES = 180;

  LayerJO2(PApplet p, color c) {
    this(p, c, 0);
  }

  LayerJO2(PApplet p, color c, int device) {
    super(c);
    println("JO2 using mic device: " + device);
    mic = new AudioIn(p, 1);
    mic.start();
    micFFT = new FFT(p, micBands);
    micFFT.input(mic);
    micSpec = new float[micBands];
    avgE = new float[4];

    nodes = new ArrayList<Node>(MAX_NODES);
    for (int i = 0; i < 5; i++) {
      float x = random(width * 0.2, width * 0.8);
      float y = random(height * 0.2, height * 0.8);
      nodes.add(new Node(x, y, random(TWO_PI), random(100, 180)));
    }
  }

  void update(float t, float bass, float mid, float treble,
              float burstA, float burstB, float burstC,
              boolean isBeat, float beatStrength, float flashVal) {
    currentT = t;

    // ── Analyze mic input ──────────────────────
    micFFT.analyze(micSpec);

    float b = 0, m = 0, tr = 0;
    for (int i = 0; i < 4; i++)   b  += micSpec[i];
    for (int i = 4; i < 20; i++)  m  += micSpec[i];
    for (int i = 20; i < micBands; i++) tr += micSpec[i];

    micBass   = constrain(b / 2,  0, 1);
    micMid    = constrain(m / 8,  0, 1);
    micTreble = constrain(tr / 22, 0, 1);
    micAmp    = (micBass + micMid + micTreble) / 3;

    bassS = lerp(bassS, micBass,   0.08);
    midS  = lerp(midS,  micMid,    0.08);
    trebS = lerp(trebS, micTreble, 0.08);

    // Simple onset detection on mic
    int sub = 4;
    int perBand = micBands / sub;
    int beatCount = 0;
    float beatStr = 0;
    for (int band = 0; band < sub; band++) {
      float e = 0;
      for (int i = band * perBand; i < (band + 1) * perBand; i++) e += micSpec[i];
      e /= perBand;
      avgE[band] = avgE[band] * 0.8 + e * 0.2;
      if (e > avgE[band] * 1.3 && e > 0.01) {
        beatCount++;
        beatStr += e - avgE[band] * 1.3;
      }
    }
    micBeat = (beatCount >= 2) ? constrain(beatStr * 4, 0, 1) : 0;

    // ── Growth driven by mic ───────────────────
    growthAge += 0.2 + micBass * 4 + micMid * 2;

    for (Node n : nodes) n.grow(t, midS);

    int desired = min((int)(growthAge * 0.13) + 5, MAX_NODES);
    while (nodes.size() < desired) { if (!spawnNode()) break; }

    // Mic beat → burst of divisions
    if (micBeat > 0.3) {
      int extra = (int)(2 + micBeat * 12);
      float spread = 1.2 + micMid * 1.5;
      for (int i = 0; i < extra; i++) {
        if (nodes.size() >= MAX_NODES) break;
        Node p = nodes.get((int)random(nodes.size()));
        if (p.growT > 0.3) {
          Node c = new Node(p.endX, p.endY,
                            p.angle + random(-spread, spread),
                            p.targetLen * random(0.3, 0.7));
          nodes.add(c);
          p.pulse = max(p.pulse, 0.5 + micBeat * 0.5);
        }
      }
    }

    float raw = sin(t * 0.25) * sin(t * 0.09);
    visibility = constrain(map(raw, -1, 1, -0.3, 1.2), 0, 1);
    visibility = visibility * visibility * (3 - 2 * visibility);
  }

  boolean spawnNode() {
    for (int i = 0; i < 40; i++) {
      Node p = nodes.get((int)random(nodes.size()));
      if (p.children < 4 && p.growT > 0.3) {
        float spread = 0.5 + micMid * 1.5;
        int arm = (int)(1 + micAmp * 3);
        for (int j = 0; j < arm; j++) {
          if (nodes.size() >= MAX_NODES) break;
          float a = p.angle + random(-spread, spread) + random(-0.4, 0.4);
          float l = p.targetLen * random(0.3, 0.75);
          Node c = new Node(p.endX, p.endY, a, max(l, 12));
          nodes.add(c);
          p.children++;
        }
        return true;
      }
    }
    return false;
  }

  void draw() {
    if (nodes.isEmpty() || visibility < 0.01) return;
    pushStyle();
    colorMode(RGB, 255);

    for (Node n : nodes) n.draw(currentT, bassS, trebS, visibility, micAmp);

    popStyle();
  }

  // ── Node ─────────────────────────────────────
  class Node {
    float x, y, endX, endY;
    float angle, targetLen;
    int children;
    float growT, pulse;
    int seed;

    Node(float x, float y, float angle, float len) {
      this.x = x; this.y = y;
      this.angle = angle; this.targetLen = len;
      endX = x; endY = y;
      growT = 0; pulse = 0;
      seed = (int)random(10000);
    }

    void grow(float t, float mid) {
      growT = min(growT + 0.018 + mid * 0.015, 1);
      float curLen = growT * targetLen;
      endX = x + cos(angle) * curLen;
      endY = y + sin(angle) * curLen;

      float drift = (sin(t * 0.9 + seed * 0.5) + sin(t * 0.4 + seed)) * mid * 3;
      endX += drift * growT;
      endY += (sin(t * 1.1 + seed * 1.7) + sin(t * 0.6 + seed * 0.3)) * mid * 1.5 * growT;

      pulse *= 0.88;
    }

    void draw(float t, float bass, float treb, float vis, float amp) {
      float g = growT;
      if (g < 0.01) return;

      float a = constrain(vis * (60 + 195 * g), 0, 255);
      if (a < 2) return;

      float pu = pulse;
      float sw = constrain(0.6 + pu * 3 + amp * 2, 0.3, 6);

      float hue = (angle * 180 / PI + seed * 0.5 + t * 15 + treb * 80 + amp * 60) % 360;
      float sat = 180 + bass * 75 + amp * 50;
      float bri = 160 + treb * 95 + pu * 70 + amp * 40;

      colorMode(HSB, 360, 255, 255, 255);

      stroke(hue, sat, bri, (int)a);
      strokeWeight(sw);
      line(x, y, endX, endY);

      float ns = 2 + pu * 5 + amp * 3;
      float na = a * (0.5 + 0.5 * pu);
      noStroke();
      fill(hue, sat * 0.6, min(bri * 1.4, 255), (int)na);
      ellipse(endX, endY, ns, ns);

      if (pu > 0.05 || amp > 0.4) {
        float glowAmp = max(pu, amp * 0.5);
        fill(hue, sat * 0.25, bri, (int)(na * glowAmp * 0.35));
        ellipse(endX, endY, ns * 3 + glowAmp * 8, ns * 3 + glowAmp * 8);
      }

      if (g > 0.4 && random(1) < 0.25) {
        float da = a * g * 0.12;
        stroke(hue, sat * 0.4, bri * 0.5, (int)da);
        strokeWeight(0.3);
        line(x, y, (x + endX) * 0.5, (y + endY) * 0.5);
      }

      colorMode(RGB, 255);
    }
  }
}
