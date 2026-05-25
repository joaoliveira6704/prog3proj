// João Santos — layer 2
// Pink Floyd rollercoaster: infinite tunnel of receding triangles.
// Mic input steers the tunnel direction:
//   - mic volume   = how hard it bends
//   - mic pitch    = which way (low freq → left/down, high freq → right/up)

class LayerJS2 extends Layer {
  float bassP, midP, trebP, beatP;
  float zPos;
  float roll;
  float shakeX, shakeY;
  float kick;

  // mic stuff — local to this layer, doesn't touch the global music FFT
  AudioIn micIn;
  Amplitude micAmp;
  FFT micFft;
  float[] micSpec;
  int micBands = 64;
  boolean micReady = false;
  boolean micTried = false;

  float micVol;            // smoothed mic loudness 0..1
  float micPitch;          // smoothed pitch balance -1..1 (low..high)
  float steerVX, steerVY;  // smoothed steering velocity (px/ring)
  float steerX, steerY;    // accumulated steering offset (per-ring scaling)
  float pitchBaseline;     // slow-adapting ambient pitch balance

  static final int RINGS = 60;
  static final float SPACING = 1.0;
  static final float NEAR = 0.05;
  static final float FAR  = 60;

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
      ringSpin[i] = random(-0.4, 0.4);
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
      micFft = new FFT(prog3proj.this, micBands);
      micFft.input(micIn);
      micSpec = new float[micBands];
      micReady = true;
    } catch (Exception e) {
      micReady = false;
    }
  }

  void readMic() {
    if (!micReady) return;
    float v = micAmp.analyze();
    micFft.analyze(micSpec);

    // skip the first few bins — they're room rumble / mic DC / fan noise
    // and bias the balance permanently toward "low"
    int loStart = 4;
    int loEnd   = 20;        // ~vocal low band
    int hiStart = 20;
    int hiEnd   = micBands;  // everything above = "high"
    float lo = 0, hi = 0;
    for (int i = loStart; i < loEnd; i++) lo += micSpec[i];
    for (int i = hiStart; i < hiEnd; i++) hi += micSpec[i];
    float bal = (hi - lo) / (lo + hi + 0.0001);   // -1..1

    // auto-calibrate: slowly track ambient balance and subtract.
    // result: at rest, micPitch ≈ 0; only deviations from your room steer.
    pitchBaseline = lerp(pitchBaseline, bal, 0.01);
    float pitchDev = constrain((bal - pitchBaseline) * 2.0, -1, 1);

    micVol   = lerp(micVol,   constrain(v * 14, 0, 1), 0.40);
    micPitch = lerp(micPitch, pitchDev, 0.35);
  }

  void update(float t, float bass, float mid, float treble,
              float burstA, float burstB, float burstC,
              boolean isBeat, float beatStrength, float flashVal) {

    initMic();
    readMic();

    bassP = lerp(bassP, bass, 0.25);
    midP  = lerp(midP,  mid,  0.22);
    trebP = lerp(trebP, treble, 0.30);
    beatP = lerp(beatP, beatStrength, 0.30);

    // forward speed
    float speed = 0.18 + bassP * 0.55 + beatP * 0.35 + kick * 0.9
                + micVol * 0.4;       // shouting also speeds you up
    zPos += speed;

    // pitch decides left/right, volume decides how hard
    // high pitch (treble) → right, low pitch (bass) → left
    float driveX = micPitch * micVol * 38;
    float driveY = sin(zPos * 0.05) * micVol * 4;     // mild idle drift only
    steerVX = lerp(steerVX, driveX, 0.22);
    steerVY = lerp(steerVY, driveY, 0.22);

    // integrate so bend persists like a real curving track
    steerX += steerVX * 0.14;
    steerY += steerVY * 0.14;
    // soft cap so tunnel can't fly fully off-screen
    float maxSteer = min(width, height) * 0.5;
    steerX = constrain(steerX, -maxSteer, maxSteer);
    steerY = constrain(steerY, -maxSteer, maxSteer);
    // gentle recenter
    steerX *= 0.97;
    steerY *= 0.97;

    // banking roll — mic pitch banks the camera, beats jolt it
    roll += 0.004 + midP * 0.025 + micPitch * micVol * 0.08;
    if (isBeat) roll += random(-0.12, 0.12);

    float shakeAmt = (beatP * 18 + kick * 30) * (1 + trebP);
    shakeX = lerp(shakeX, random(-shakeAmt, shakeAmt), 0.5);
    shakeY = lerp(shakeY, random(-shakeAmt, shakeAmt), 0.5);

    kick *= 0.88;
  }

  void keyPressed(char k) {
    if (k == 'x' || k == 'X') kick = 1.0;
  }

  void draw() {
    pushStyle();
    float cx = width * 0.5 + shakeX;
    float cy = height * 0.5 + shakeY;
    float focal = min(width, height) * 0.9;

    noStroke();
    fill(0, 60);
    rect(0, 0, width, height);

    for (int i = RINGS - 1; i >= 0; i--) {
      float z = ((i * SPACING) - (zPos % (RINGS * SPACING)) + RINGS * SPACING) % (RINGS * SPACING);
      if (z < NEAR) continue;

      float scale = focal / z;
      float worldR = 4.0;
      float r = worldR * scale;
      if (r > max(width, height) * 2) continue;

      float depthT = constrain(1 - z / FAR, 0, 1);
      float alpha = depthT * 220;

      int colorIdx = ((i + (int)(zPos * 0.5)) % rainbow.length + rainbow.length) % rainbow.length;
      color c = rainbow[colorIdx];

      float ang = ringPhase[i] + ringSpin[i] * zPos * 0.06 + roll
                + sin(zPos * 0.08 + i * 0.3) * (0.15 + trebP * 0.4);

      // bend: far rings drift more, in the direction the mic is steering
      float depthBend = pow(z / FAR, 1.2);
      float bendX = steerX * depthBend * 6;
      float bendY = steerY * depthBend * 6;

      pushMatrix();
      translate(cx + bendX, cy + bendY);
      rotate(ang);

      noFill();
      for (int g = 4; g >= 0; g--) {
        float gw = (1.5 + g * 1.8) * (1 + beatP * 0.6 + kick * 1.2);
        float ga = alpha * pow(0.5, g);
        stroke(red(c), green(c), blue(c), ga);
        strokeWeight(gw);
        triangle(0, -r, -r * 0.866, r * 0.5, r * 0.866, r * 0.5);
      }
      stroke(255, alpha * 0.9);
      strokeWeight(1.2 + beatP * 1.5);
      triangle(0, -r, -r * 0.866, r * 0.5, r * 0.866, r * 0.5);

      popMatrix();
    }

    // vanishing-point anchor (invisible) — streaks still emanate from here
    float sparkX = cx + steerX * 0.6;
    float sparkY = cy + steerY * 0.6;

    // motion streaks — only on real song beats / X kick, not on mic input
    if (beatP > 0.4 || kick > 0.2) {
      stroke(255, beatP * 120 + kick * 180);
      strokeWeight(1);
      int streaks = 14;
      for (int s = 0; s < streaks; s++) {
        float a = TWO_PI * s / streaks + roll;
        float r1 = min(width, height) * 0.05;
        float r2 = min(width, height) * (0.4 + beatP * 0.5 + kick * 0.6);
        line(sparkX + cos(a) * r1, sparkY + sin(a) * r1,
             sparkX + cos(a) * r2, sparkY + sin(a) * r2);
      }
    }

    // mic-off indicator (faint, top-right) so user knows if no input
    if (!micReady) {
      fill(255, 80);
      textAlign(RIGHT, TOP);
      textSize(11);
      text("mic off", width - 12, 12);
    }

    popStyle();
  }
}
