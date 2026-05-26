import processing.sound.*;

class LayerJO2 extends Layer {

  ArrayList<Node> nodes;
  float currentT;
  float bassS, midS, trebS;
  float growthAge;
  float visibility;

  // Track the overall volume and a decaying beat
  float smoothAmp = 0;
  float beatDecay = 0;

  static final int MAX_NODES = 180;

  LayerJO2(color c) {
    super(c);
    nodes = new ArrayList<Node>(MAX_NODES);
    for (int i = 0; i < 5; i++) {
      float x = random(width * 0.2, width * 0.8);
      float y = random(height * 0.2, height * 0.8);
      // INCREASED: Initial branches are now much longer (was 100-180)
      nodes.add(new Node(x, y, random(TWO_PI), random(250, 450)));
    }
  }

  void update(float t, float bass, float mid, float treble,
              float burstA, float burstB, float burstC,
              boolean isBeat, float beatStrength, float flashVal) {
    currentT = t;

    // ── Smooth the incoming music data ──────────────────────
    bassS = lerp(bassS, bass, 0.08);
    midS  = lerp(midS,  mid,  0.08);
    trebS = lerp(trebS, treble, 0.08);

    // Calculate overall amplitude
    float currentAmp = (bass + mid + treble) / 3.0;
    smoothAmp = lerp(smoothAmp, currentAmp, 0.1);

    // Create a decaying beat spike for sudden bursts
    if (isBeat) {
      beatDecay = max(beatStrength, 0.8);
    }
    beatDecay *= 0.9;

    // ── Growth driven by music ───────────────────
    growthAge += 0.2 + bass * 4 + mid * 2;

    for (int i = nodes.size() - 1; i >= 0; i--) {
      Node n = nodes.get(i);
      n.grow(t, midS);
      if (n.isDead()) {
        nodes.remove(i);
      }
    }

    int desired = min((int)(growthAge * 0.13) + 5, MAX_NODES);
    while (nodes.size() < desired) { if (!spawnNode()) break; }

    // Music beat → burst of divisions
    if (beatDecay > 0.3) {
      int extra = (int)(2 + beatDecay * 12);
      float spread = 1.2 + mid * 1.5;
      for (int i = 0; i < extra; i++) {
        if (nodes.size() >= MAX_NODES) break;
        Node p = nodes.get((int)random(nodes.size()));
        if (p.growT > 0.3) {
          // INCREASED: Child branches retain more length (was 0.3-0.7)
          Node c = new Node(p.endX, p.endY,
                            p.angle + random(-spread, spread),
                            p.targetLen * random(0.5, 0.9));
          nodes.add(c);
          p.pulse = max(p.pulse, 0.5 + beatDecay * 0.5);
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
        float spread = 0.5 + midS * 1.5;
        int arm = (int)(1 + smoothAmp * 3);
        for (int j = 0; j < arm; j++) {
          if (nodes.size() >= MAX_NODES) break;
          float a = p.angle + random(-spread, spread) + random(-0.4, 0.4);
          // INCREASED: Child branches retain more length, minimum size is bigger
          float l = p.targetLen * random(0.5, 0.9);
          Node c = new Node(p.endX, p.endY, a, max(l, 35)); // Minimum length was 12
          nodes.add(c);
          p.children++;
        }
        return true;
      }
    }
    return false;
  }

  void drawLayer(PGraphics g) {
    g.clear();
    if (nodes.isEmpty() || visibility < 0.01) return;
    g.pushStyle();

    // 1. Draw the organic curved branches
    for (Node n : nodes) n.draw(g, currentT, bassS, trebS, visibility, smoothAmp);

    // 2. The "Casey Reas" Proximity Web
    g.colorMode(RGB, 255);
    g.strokeWeight(1.0); // INCREASED: slightly thicker web lines

    // proximity web — squared distance avoids sqrt()
    float connDist = 80 + (smoothAmp * 80);
    float connDistSq = connDist * connDist;

    for (int i = 0; i < nodes.size(); i++) {
      Node n1 = nodes.get(i);
      if (n1.growT < 0.5) continue;

      for (int j = i + 1; j < nodes.size(); j++) {
        Node n2 = nodes.get(j);
        if (n2.growT < 0.5) continue;

        float dx = n1.endX - n2.endX;
        float dy = n1.endY - n2.endY;
        float dSq = dx * dx + dy * dy;
        if (dSq < connDistSq) {
          float d = sqrt(dSq);            // sqrt only when inside range
          float alphaMap = map(d, 0, connDist, 80, 0);
          g.stroke(200, 200, 255, alphaMap * visibility);
          g.line(n1.endX, n1.endY, n2.endX, n2.endY);
        }
      }
    }
    g.popStyle();
  }

  // ── Node ─────────────────────────────────────
  class Node {
    float x, y, endX, endY;
    float angle, targetLen;
    int children;
    float growT, tailT, pulse;
    int seed;

    Node(float x, float y, float angle, float len) {
      this.x = x; this.y = y;
      this.angle = angle; this.targetLen = len;
      endX = x; endY = y;
      growT = 0;
      tailT = 0;
      pulse = 0;
      seed = (int)random(10000);
    }

    void grow(float t, float mid) {
      growT = min(growT + 0.018 + mid * 0.015, 1);

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

    boolean isDead() {
      return tailT >= 1;
    }

    void draw(PGraphics g, float t, float bass, float treb, float vis, float amp) {
      float gT = growT;
      if (gT < 0.01) return;

      float a = constrain(vis * (40 + 100 * gT) * (1.0 - tailT), 0, 255);
      if (a < 2) return;

      float pu = pulse;
      // INCREASED: The main branch lines are thicker
      float sw = constrain(1.5 + amp * 3.0, 0.8, 4.0);

      float hue = (angle * 180 / PI + seed * 0.5 + t * 5 + treb * 20) % 360;
      float sat = 60 + bass * 40;
      float bri = 200 + treb * 55;

      g.colorMode(HSB, 360, 255, 255, 255);
      g.stroke(hue, sat, bri, a * 0.5);
      g.strokeWeight(sw);
      g.noFill();

      float currentStartX = lerp(x, endX, tailT);
      float currentStartY = lerp(y, endY, tailT);

      float d = dist(currentStartX, currentStartY, endX, endY);
      float n1 = (noise(seed, t * 0.2) - 0.5) * 1.5;
      float n2 = (noise(seed + 100, t * 0.2) - 0.5) * 1.5;

      float cp1X = currentStartX + cos(angle + n1) * (d * 0.5);
      float cp1Y = currentStartY + sin(angle + n1) * (d * 0.5);

      float cp2X = endX + cos(angle + PI + n2) * (d * 0.5);
      float cp2Y = endY + sin(angle + PI + n2) * (d * 0.5);

      g.bezier(currentStartX, currentStartY, cp1X, cp1Y, cp2X, cp2Y, endX, endY);

      if (tailT < 0.8) {
        // INCREASED: The circular joints at the end of the nodes are larger
        float ns = 8 + pu * 25 + amp * 15;
        g.stroke(hue, sat, bri, a * 0.4);
        g.strokeWeight(1.0);
        g.ellipse(endX, endY, ns, ns);

        if (pu > 0.1 || amp > 0.3) {
          g.ellipse(endX, endY, ns * 1.5, ns * 1.5);
        }
      }

      g.colorMode(RGB, 255);
    }
  }
}
