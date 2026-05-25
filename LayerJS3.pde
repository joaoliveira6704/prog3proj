// João Santos — layer 3
// Press 'c' → a meteorite streaks across the screen with a glowing tail
// and sparks of debris. Multiple meteorites can fly at once.

class LayerJS3 extends Layer {
  float bassP, midP, trebP, beatP;

  static final int MAX_METEORS = 12;
  static final int TRAIL = 26;

  float[]   mX     = new float[MAX_METEORS];
  float[]   mY     = new float[MAX_METEORS];
  float[]   mVX    = new float[MAX_METEORS];
  float[]   mVY    = new float[MAX_METEORS];
  float[]   mSize  = new float[MAX_METEORS];
  boolean[] mAlive = new boolean[MAX_METEORS];
  float[][] mTX    = new float[MAX_METEORS][TRAIL];
  float[][] mTY    = new float[MAX_METEORS][TRAIL];
  int[]     mHead  = new int[MAX_METEORS];

  static final int DEBRIS = 220;
  float[] dX    = new float[DEBRIS];
  float[] dY    = new float[DEBRIS];
  float[] dVX   = new float[DEBRIS];
  float[] dVY   = new float[DEBRIS];
  float[] dLife = new float[DEBRIS];

  LayerJS3(color c) { super(c); }

  void spawnMeteor() {
    for (int i = 0; i < MAX_METEORS; i++) {
      if (!mAlive[i]) {
        // start somewhere off the top or left edge
        float sx, sy;
        if (random(1) < 0.6) {
          sx = random(-0.1, 0.9) * width;
          sy = -60;
        } else {
          sx = -60;
          sy = random(-0.1, 0.6) * height;
        }
        // aim toward bottom-right at a shallow-ish angle
        float ang = random(PI * 0.18, PI * 0.42);
        float spd = random(12, 20);
        mX[i] = sx;
        mY[i] = sy;
        mVX[i] = cos(ang) * spd;
        mVY[i] = sin(ang) * spd;
        mSize[i] = random(5, 11);
        mAlive[i] = true;
        mHead[i] = 0;
        for (int j = 0; j < TRAIL; j++) {
          mTX[i][j] = sx;
          mTY[i][j] = sy;
        }
        return;
      }
    }
  }

  void emitDebris(float x, float y, int n) {
    for (int k = 0; k < n; k++) {
      for (int i = 0; i < DEBRIS; i++) {
        if (dLife[i] <= 0) {
          dX[i] = x + random(-2, 2);
          dY[i] = y + random(-2, 2);
          float a = random(TWO_PI);
          float s = random(0.4, 2.2);
          dVX[i] = cos(a) * s;
          dVY[i] = sin(a) * s + 0.4;  // tiny gravity tilt
          dLife[i] = 1.0;
          break;
        }
      }
    }
  }

  void update(float t, float bass, float mid, float treble,
              float burstA, float burstB, float burstC,
              boolean isBeat, float beatStrength, float flashVal) {

    bassP = lerp(bassP, bass, 0.22);
    midP  = lerp(midP,  mid,  0.22);
    trebP = lerp(trebP, treble, 0.30);
    beatP = lerp(beatP, beatStrength, 0.28);

    for (int i = 0; i < MAX_METEORS; i++) {
      if (!mAlive[i]) continue;
      mX[i] += mVX[i];
      mY[i] += mVY[i];
      mHead[i] = (mHead[i] + 1) % TRAIL;
      mTX[i][mHead[i]] = mX[i];
      mTY[i][mHead[i]] = mY[i];
      emitDebris(mX[i], mY[i], 2);
      if (mX[i] > width + 120 || mY[i] > height + 120) mAlive[i] = false;
    }

    for (int i = 0; i < DEBRIS; i++) {
      if (dLife[i] <= 0) continue;
      dX[i] += dVX[i];
      dY[i] += dVY[i];
      dVX[i] *= 0.96;
      dVY[i] *= 0.97;
      dLife[i] -= 0.025;
    }
  }

  void keyPressed(char k) {
    if (k == 'c' || k == 'C') spawnMeteor();
  }

  void draw() {
    pushStyle();

    // debris first — sits behind meteor head
    noStroke();
    for (int i = 0; i < DEBRIS; i++) {
      if (dLife[i] <= 0) continue;
      float a = dLife[i];
      fill(255, 200 + a * 40, 140, a * 220);
      float sz = 1 + a * 2.2;
      ellipse(dX[i], dY[i], sz, sz);
    }

    // meteors
    for (int i = 0; i < MAX_METEORS; i++) {
      if (!mAlive[i]) continue;

      // tail: walk backward from head, fade + thin out
      int head = mHead[i];
      for (int j = 1; j < TRAIL; j++) {
        int idxA = (head - (j - 1) + TRAIL) % TRAIL;
        int idxB = (head - j + TRAIL) % TRAIL;
        float f = 1 - j / (float)TRAIL;
        // hot core → warm tail
        float r = 255;
        float g = 180 + f * 70;
        float b = 80 + f * 100;
        stroke(r, g, b, 230 * f);
        strokeWeight(mSize[i] * f * 1.1);
        line(mTX[i][idxA], mTY[i][idxA], mTX[i][idxB], mTY[i][idxB]);
      }

      // glowing head — layered halo then bright core
      noStroke();
      for (int g = 4; g >= 0; g--) {
        float a = 50 + (4 - g) * 40;
        float rr = mSize[i] * (1 + g * 0.9);
        fill(255, 210 - g * 12, 150 - g * 22, a);
        ellipse(mX[i], mY[i], rr, rr);
      }
      fill(255);
      ellipse(mX[i], mY[i], mSize[i] * 0.7, mSize[i] * 0.7);
    }

    popStyle();
  }
}
