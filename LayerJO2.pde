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
    println("Available audio input devices:");
    String[] devices = Sound.list();
    for (int i = 0; i < devices.length; i++) {
      println(i + ": " + devices[i]);
    }
    mic = new AudioIn(p, 0);
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

    // UPDATE: Backwards loop to allow safe removal of dead nodes
    for (int i = nodes.size() - 1; i >= 0; i--) {
      Node n = nodes.get(i);
      n.grow(t, midS);
      if (n.isDead()) {
        nodes.remove(i);
      }
    }

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
    
    // 1. Draw the organic curved branches
    for (Node n : nodes) n.draw(currentT, bassS, trebS, visibility, micAmp);

    // 2. The "Casey Reas" Proximity Web
    colorMode(RGB, 255);
    strokeWeight(0.5); // Hairline stroke
    
    float connectionDistance = 40 + (micAmp * 40); // Distance expands with the audio
    
    for (int i = 0; i < nodes.size(); i++) {
      Node n1 = nodes.get(i);
      if (n1.growT < 0.5) continue; // Only connect established nodes
      
      for (int j = i + 1; j < nodes.size(); j++) {
        Node n2 = nodes.get(j);
        if (n2.growT < 0.5) continue;
        
        float d = dist(n1.endX, n1.endY, n2.endX, n2.endY);
        if (d < connectionDistance) {
          // Fade the line out as the distance increases
          float alphaMap = map(d, 0, connectionDistance, 80, 0); 
          stroke(200, 200, 255, alphaMap * visibility); 
          line(n1.endX, n1.endY, n2.endX, n2.endY);
        }
      }
    }
    popStyle();
  }

  // ── Node ─────────────────────────────────────
  class Node {
    float x, y, endX, endY;
    float angle, targetLen;
    int children;
    float growT, tailT, pulse; // NEW: Added tailT to track the decaying tail
    int seed;

    Node(float x, float y, float angle, float len) {
      this.x = x; this.y = y;
      this.angle = angle; this.targetLen = len;
      endX = x; endY = y;
      growT = 0; 
      tailT = 0; // Initialize tail tracker
      pulse = 0;
      seed = (int)random(10000);
    }

    void grow(float t, float mid) {
      growT = min(growT + 0.018 + mid * 0.015, 1);
      
      // NEW: Once the head grows out a bit, the tail starts following it
      if (growT > 0.4) {
        tailT = min(tailT + 0.012 + mid * 0.01, 1);
      }

      float curLen = growT * targetLen;
      endX = x + cos(angle) * curLen;
      endY = y + sin(angle) * curLen;

      float drift = (sin(t * 0.9 + seed * 0.5) + sin(t * 0.4 + seed)) * mid * 3;
      endX += drift * growT;
      endY += (sin(t * 1.1 + seed * 1.7) + sin(t * 0.6 + seed * 0.3)) * mid * 1.5 * growT;

      pulse *= 0.88;
    }
    
    // NEW: Method to check if the segment has fully decayed
    boolean isDead() {
      return tailT >= 1;
    }

    void draw(float t, float bass, float treb, float vis, float amp) {
      float g = growT;
      if (g < 0.01) return;

      // Soften the overall alpha for that sketch-like buildup, fade out as tail dies
      float a = constrain(vis * (40 + 100 * g) * (1.0 - tailT), 0, 255); 
      if (a < 2) return;

      float pu = pulse;
      // Very thin, delicate stroke weights
      float sw = constrain(0.5 + amp * 1.5, 0.2, 1.5); 

      // Tone down saturation, boost brightness for an elegant look
      float hue = (angle * 180 / PI + seed * 0.5 + t * 5 + treb * 20) % 360;
      float sat = 60 + bass * 40;  
      float bri = 200 + treb * 55; 

      colorMode(HSB, 360, 255, 255, 255);

      stroke(hue, sat, bri, a * 0.5);
      strokeWeight(sw);
      noFill();

      // NEW: Calculate the dynamic starting point so the tail slithers forward
      float currentStartX = lerp(x, endX, tailT);
      float currentStartY = lerp(y, endY, tailT);

      // Casey Reas Curves: Calculate control points to bend the line gracefully
      float d = dist(currentStartX, currentStartY, endX, endY);
      
      // Use Perlin noise tied to the node's seed and time to make the curves writhe slightly
      float n1 = (noise(seed, t * 0.2) - 0.5) * 1.5;
      float n2 = (noise(seed + 100, t * 0.2) - 0.5) * 1.5;
      
      float cp1X = currentStartX + cos(angle + n1) * (d * 0.5);
      float cp1Y = currentStartY + sin(angle + n1) * (d * 0.5);
      
      float cp2X = endX + cos(angle + PI + n2) * (d * 0.5);
      float cp2Y = endY + sin(angle + PI + n2) * (d * 0.5);

      // Draw the organic moving branch
      bezier(currentStartX, currentStartY, cp1X, cp1Y, cp2X, cp2Y, endX, endY);

      // Only draw the glowing joint if the tail hasn't fully detached yet
      if (tailT < 0.8) {
        float ns = 4 + pu * 15 + amp * 8;
        stroke(hue, sat, bri, a * 0.3);
        strokeWeight(0.3);
        ellipse(endX, endY, ns, ns);
        
        if (pu > 0.1 || amp > 0.3) {
          ellipse(endX, endY, ns * 1.5, ns * 1.5);
        }
      }

      colorMode(RGB, 255);
    }
  }
}