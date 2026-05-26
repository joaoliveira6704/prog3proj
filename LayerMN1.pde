// Miguel Neto — MN1
// Three Sims-style wireframe prisms that shatter when treble spikes
// and rebuild as energy drops

class LayerMN1 extends Layer {

  float[] rotY   = { 0, 0, 0 };
  float[] speedY = { 0.008, 0.011, 0.007 };
  float   baseSize = 80;
  float   bass, treble;

  // Shatter state
  static final int STATE_WHOLE    = 0;
  static final int STATE_BREAKING = 1;
  static final int STATE_BROKEN   = 2;
  static final int STATE_REBUILDING = 3;

  int   state          = STATE_WHOLE;
  float trebleThreshold = 0.65;   // treble level that triggers shatter
  float trebleSmooth   = 0;       // smoothed treble to avoid flicker

  // Shards — fragments of the broken prisms
  ArrayList<Shard> shards = new ArrayList<Shard>();

  // Rebuild timer — how long before they come back
  float rebuildTimer = 0;
  float rebuildDuration = 120;   // frames

  // Prism opacity during rebuild (0=invisible, 1=fully drawn)
  float rebuildAlpha = 1.0;

  LayerMN1(color c) { super(c); }

  void update(float t,
              float bass, float mid, float treble,
              float burstA, float burstB, float burstC,
              boolean isBeat, float beatStrength, float flashVal) {
    this.bass   = bass;
    this.treble = treble;

    // Smooth treble to avoid rapid flickering
    trebleSmooth = lerp(trebleSmooth, treble, 0.08);

    for (int i = 0; i < 3; i++) rotY[i] += speedY[i];

    // Update shards
    for (int i = shards.size() - 1; i >= 0; i--) {
      shards.get(i).update();
      if (shards.get(i).isDead()) shards.remove(i);
    }

    switch (state) {

      case STATE_WHOLE:
        if (trebleSmooth > trebleThreshold) {
          triggerShatter();
          state = STATE_BREAKING;
        }
        rebuildAlpha = 1.0;
        break;

      case STATE_BREAKING:
        // Wait for shards to finish then go to BROKEN
        if (shards.size() == 0) {
          state = STATE_BROKEN;
          rebuildTimer = 0;
        }
        break;

      case STATE_BROKEN:
        rebuildTimer++;
        // Start rebuilding once treble drops back down
        if (trebleSmooth < trebleThreshold * 0.5 && rebuildTimer > 30) {
          state = STATE_REBUILDING;
          rebuildTimer = 0;
          rebuildAlpha = 0;
        }
        break;

      case STATE_REBUILDING:
        rebuildTimer++;
        rebuildAlpha = rebuildTimer / rebuildDuration;
        if (rebuildTimer >= rebuildDuration) {
          state = STATE_WHOLE;
          rebuildAlpha = 1.0;
        }
        break;
    }
  }

  void draw() {
    float s       = baseSize + bass * 120;
    float spacing = width / 4.0;

    // Draw shards always
    for (Shard sh : shards) sh.draw();

    // Draw prisms when whole or rebuilding
    if (state == STATE_WHOLE || state == STATE_REBUILDING) {
      float a = rebuildAlpha * 200;
      stroke(255, 255, 255, a);
      strokeWeight(1.2);
      noFill();
      for (int i = 0; i < 3; i++) {
        drawOctahedron(spacing * (i + 1), height / 2.0, s, rotY[i], a);
      }
    }
  }

  // ── Spawn shards for all 3 prisms ──────────────────────────
  void triggerShatter() {
    shards.clear();
    float s       = baseSize + bass * 120;
    float spacing = width / 4.0;
    for (int i = 0; i < 3; i++) {
      float cx = spacing * (i + 1);
      float cy = height / 2.0;
      // Spawn shards radiating from each prism centre
      int numShards = 18;
      for (int j = 0; j < numShards; j++) {
        shards.add(new Shard(cx, cy, s));
      }
    }
  }

  // ── Draw one wireframe octahedron ───────────────────────────
  void drawOctahedron(float cx, float cy, float s, float ry, float alpha) {
    float[][] v3 = {
      {  0,      -s * 1.4,  0  },
      {  s,       0,        0  },
      {  0,       0,        s  },
      { -s,       0,        0  },
      {  0,       0,       -s  },
      {  0,       s * 1.4,  0  }
    };

    float[][] v = new float[6][2];
    for (int i = 0; i < 6; i++) {
      float x  = v3[i][0], y = v3[i][1], z = v3[i][2];
      float rx = x * cos(ry) + z * sin(ry);
      float rz = -x * sin(ry) + z * cos(ry);
      float d  = 600.0 / (600 + rz + s * 2);
      v[i][0]  = cx + rx * d;
      v[i][1]  = cy + y  * d;
    }

    int[][] faces = {
      {0,1,2}, {0,2,3}, {0,3,4}, {0,4,1},
      {5,2,1}, {5,3,2}, {5,4,3}, {5,1,4}
    };

    stroke(255, 255, 255, alpha);
    strokeWeight(1.2);
    noFill();
    for (int[] f : faces) {
      beginShape();
      vertex(v[f[0]][0], v[f[0]][1]);
      vertex(v[f[1]][0], v[f[1]][1]);
      vertex(v[f[2]][0], v[f[2]][1]);
      endShape(CLOSE);
    }
  }

  // ── Shard: a small line fragment that flies outward ─────────
  class Shard {
    float x, y;
    float vx, vy;
    float len;
    float angle;
    float life, maxLife;
    float rot, rotSpeed;

    Shard(float cx, float cy, float s) {
      x        = cx + random(-s * 0.5, s * 0.5);
      y        = cy + random(-s * 0.5, s * 0.5);
      float a  = random(TWO_PI);
      float spd = random(1.5, 5.0);
      vx       = cos(a) * spd;
      vy       = sin(a) * spd;
      len      = random(8, 30);
      angle    = random(TWO_PI);
      rotSpeed = random(-0.08, 0.08);
      maxLife  = random(40, 90);
      life     = maxLife;
    }

    void update() {
      x     += vx;
      y     += vy;
      vx    *= 0.95;
      vy    *= 0.95;
      angle += rotSpeed;
      life--;
    }

    boolean isDead() { return life <= 0; }

    void draw() {
      float alpha = map(life, 0, maxLife, 0, 200);
      stroke(255, 255, 255, alpha);
      strokeWeight(1.0);
      float dx = cos(angle) * len * 0.5;
      float dy = sin(angle) * len * 0.5;
      line(x - dx, y - dy, x + dx, y + dy);
    }
  }
}
