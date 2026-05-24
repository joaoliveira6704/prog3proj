// João Oliveira — layer 1

// ── Data container for one prism instance ────
class Prism {
  float x, y;          // screen centre
  float size;          // base scale (px)

  float rotX, rotY, rotZ;          // current Euler angles
  float speedX, speedY, speedZ;    // rotation speed (rad/frame)

  int   born;          // millis() when spawned
  int   life;          // total lifespan (ms)
  float alpha;         // 0–1 opacity (computed each frame)

  Prism(float x, float y) {
    this.x = x;
    this.y = y;
    size   = random(50, 160);

    rotX   = random(TWO_PI);
    rotY   = random(TWO_PI);
    rotZ   = random(TWO_PI);

    // mix of slow and slightly faster axes for interesting tumble
    speedX = random(-0.008, 0.008);
    speedY = random(-0.013, 0.013);
    speedZ = random(-0.006, 0.010);

    born   = millis();
    life   = (int) random(4000, 7000);
    alpha  = 0;
  }

  // Returns false when the prism should be removed.
  boolean tick() {
    int   age     = millis() - born;
    float fadeIn  = 400;
    float fadeOut = 600;

    if (age > life) return false;

    if      (age < fadeIn)        alpha = age / fadeIn;
    else if (age > life - fadeOut) alpha = (life - age) / fadeOut;
    else                           alpha = 1.0;

    alpha = constrain(alpha, 0, 1);

    rotX += speedX;
    rotY += speedY;
    rotZ += speedZ;

    return true;
  }
}


// ── The layer itself ──────────────────────────
class LayerJO1 extends Layer {

  ArrayList<Prism> prisms = new ArrayList<Prism>();

  LayerJO1(color c) { super(c); }

  // ── Layer interface ──────────────────────────
  void update(float t,
              float bass, float mid, float treble,
              float burstA, float burstB, float burstC,
              boolean isBeat, float beatStrength, float flashVal) {

    // Advance every prism; remove dead ones
    for (int i = prisms.size() - 1; i >= 0; i--) {
      if (!prisms.get(i).tick()) prisms.remove(i);
    }
  }

  void keyPressed(char k) {
    if (k == 'q' || k == 'Q') spawnRandom();
  }

  void draw() {
    for (Prism p : prisms) drawPrism(p);
  }

  // ── Public spawn API ─────────────────────────
  void spawnRandom() {
    prisms.add(new Prism(random(80, width - 80),
                         random(80, height - 80)));
  }

  void spawnAt(float x, float y) {
    prisms.add(new Prism(x, y));
  }

  // ── 3-D projection helpers ───────────────────
  float[] rotate3D(float x, float y, float z,
                   float rx, float ry, float rz) {
    // X axis
    float y1 = y * cos(rx) - z * sin(rx);
    float z1 = y * sin(rx) + z * cos(rx);
    // Y axis
    float x2 = x  * cos(ry) + z1 * sin(ry);
    float z2 = -x * sin(ry) + z1 * cos(ry);
    // Z axis
    float x3 = x2 * cos(rz) - y1 * sin(rz);
    float y3 = x2 * sin(rz) + y1 * cos(rz);
    return new float[]{ x3, y3, z2 };
  }

  // Project one 3-D vertex to screen space around prism centre.
  float[] proj(float[] v3, Prism p) {
    float[] r = rotate3D(v3[0], v3[1], v3[2], p.rotX, p.rotY, p.rotZ);
    return new float[]{ p.x + r[0], p.y + r[1], r[2] };
  }

  // ── Draw one prism ───────────────────────────
  void drawPrism(Prism p) {
    float s = p.size;
    float h = s * 1.6;
    int   a = (int)(p.alpha * 255);
    if (a <= 0) return;

    // 3-D vertices: apex + 3 base corners
    float[][] verts3D = {
      {  0,      -h * 0.5,  0        },   // 0 apex
      { -s*0.6,   h * 0.5,  s * 0.35 },   // 1 base-left
      {  s*0.6,   h * 0.5,  s * 0.35 },   // 2 base-right
      {  0,       h * 0.5, -s * 0.7  }    // 3 base-back
    };

    // Project all 4 vertices
    float[][] v = new float[4][];
    for (int i = 0; i < 4; i++) v[i] = proj(verts3D[i], p);

    // Build faces with their avg Z for painter-sort
    int[][] faceIdx = { {0,1,2}, {0,2,3}, {0,3,1}, {1,2,3} };
    String[] faceId = { "front", "right", "left", "base" };

    float[] faceZ = new float[4];
    for (int f = 0; f < 4; f++) {
      faceZ[f] = (v[faceIdx[f][0]][2] +
                  v[faceIdx[f][1]][2] +
                  v[faceIdx[f][2]][2]) / 3.0;
    }

    // Sort faces back-to-front (simple insertion sort on 4 elements)
    int[] order = {0, 1, 2, 3};
    for (int i = 1; i < 4; i++) {
      int key = order[i]; float kz = faceZ[key];
      int j = i - 1;
      while (j >= 0 && faceZ[order[j]] > kz) { order[j+1] = order[j]; j--; }
      order[j+1] = key;
    }

    pushMatrix();
    noStroke();

    for (int fi = 0; fi < 4; fi++) {
      int f = order[fi];
      int[] idx = faceIdx[f];
      float[] pa = v[idx[0]], pb = v[idx[1]], pc = v[idx[2]];

      if (faceId[f].equals("base")) {
        // Rainbow-tinted base
        beginShape();
        fill(255, 0,  60, (int)(a * 0.5));  vertex(pa[0], pa[1]);
        fill(0, 200, 255, (int)(a * 0.5));  vertex(pb[0], pb[1]);
        fill(120, 0, 255, (int)(a * 0.5));  vertex(pc[0], pc[1]);
        endShape(CLOSE);
      } else {
        // Glass-like grey face, brightness varies by face
        float bright = map(faceZ[f], -s, s, 160, 230);
        fill(bright, bright + 10, bright + 20, (int)(a * 0.72));
        beginShape();
        vertex(pa[0], pa[1]);
        vertex(pb[0], pb[1]);
        vertex(pc[0], pc[1]);
        endShape(CLOSE);
      }

      // Edge outline
      stroke(255, 255, 255, (int)(a * 0.55));
      strokeWeight(0.8);
      noFill();
      beginShape();
      vertex(pa[0], pa[1]);
      vertex(pb[0], pb[1]);
      vertex(pc[0], pc[1]);
      endShape(CLOSE);
      noStroke();
    }

    popMatrix();

    // ── White input ray ───────────────────────
    float[] entryPt = v[3];
    float[] rayStart = { entryPt[0] - s * 1.1, entryPt[1] - s * 0.35 };

    stroke(255, 255, 255, (int)(a * 0.8));
    strokeWeight(1.5);
    line(rayStart[0], rayStart[1], entryPt[0], entryPt[1]);

    // ── Rainbow exit rays ─────────────────────
    float[] exitPt = v[2];
    int[] rColors = {
      color(255,   0,   0),
      color(255, 100,   0),
      color(255, 220,   0),
      color(  0, 220,  60),
      color(  0, 130, 255),
      color( 80,   0, 255),
      color(200,   0, 255)
    };

    strokeWeight(1.8);
    for (int i = 0; i < rColors.length; i++) {
      float angle = -0.22 + i * 0.075;
      float len   = s * 1.8;
      int rc = rColors[i];
      stroke(red(rc), green(rc), blue(rc), (int)(a * 0.78));
      line(exitPt[0], exitPt[1],
           exitPt[0] + cos(angle) * len,
           exitPt[1] + sin(angle) * len);
    }

    noStroke();
  }
}
