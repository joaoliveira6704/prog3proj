// SHINE ON YOU CRAZY DIAMOND — 9 Layer Visualizer
// Processing 4 | Grupo: Estudante S, A, X
// Teclas: Q W E R T Y U I O = toggle layers | A S D = burst | SPACE = flash

import processing.sound.*;

// CHANGED: Swapped AudioIn for SoundFile
SoundFile music; 
FFT fft;
int bands = 512;
float[] spectrum = new float[bands];

float bass, mid, treble;
float t = 0;
float flashVal = 0;
float burstA, burstB, burstC;

float[] avgEnergies = new float[8];
boolean isBeat = false;
float beatStrength = 0;

Layer[] layers = new Layer[9];

void setup() {
  fullScreen();
  frameRate(60);
  colorMode(RGB, 255);
  background(0);

  // CHANGED: Load and play the MP3 file instead of the mic
  music = new SoundFile(this, "music.mp3");
  music.loop();
  music.jump(120.0);

  // Init FFT using the music file as input
  fft = new FFT(this, bands);
  fft.input(music);

  // Estudante S
  layers[0] = new LayerS1(color(167, 123, 202));
  layers[1] = new LayerS2(color(123, 170, 232));
  layers[2] = new LayerS3(color(232, 123, 123));
  // Estudante A
  layers[3] = new LayerA1(color(123, 232, 180));
  layers[4] = new LayerA2(color(232, 201, 122));
  layers[5] = new LayerA3(color(232, 123, 187));
  // Estudante X
  layers[6] = new LayerX1(color(123, 232, 232));
  layers[7] = new LayerX2(color(188, 232, 123));
  layers[8] = new LayerX3(color(232, 160, 123));
}

void draw() {
  background(0);
  t += 0.016;

  analyzeAudio();

  for (Layer l : layers) {
    if (l.visible) {
      l.update(t, bass, mid, treble, burstA, burstB, burstC, isBeat, beatStrength, flashVal);
      l.draw();
    }
  }

  drawFlash();

  burstA *= 0.92;
  burstB *= 0.92;
  burstC *= 0.92;
  flashVal *= 0.85;
}

void analyzeAudio() {
  fft.analyze(spectrum);

  float b = 0, m = 0, tr = 0;
  for (int i = 0;  i < 8;  i++) b  += spectrum[i];
  for (int i = 8;  i < 64; i++) m  += spectrum[i];
  for (int i = 64; i < bands; i++) tr += spectrum[i];

  bass   = constrain(b  / (8   * 0.05), 0, 1);
  mid    = constrain(m  / (56  * 0.05), 0, 1);
  treble = constrain(tr / (448 * 0.02), 0, 1);

  // fallback suave quando não há sinal forte
  if (bass   < 0.05) bass   = 0.10 + 0.07 * sin(t * 0.8);
  if (mid    < 0.05) mid    = 0.10 + 0.06 * sin(t * 1.3 + 1);
  if (treble < 0.05) treble = 0.08 + 0.05 * sin(t * 2.1 + 2);

  // Multi-band onset detection (spectral flux)
  int subBands = 8;
  int perBand = bands / subBands;
  int beatCount = 0;
  beatStrength = 0;
  for (int band = 0; band < subBands; band++) {
    float e = 0;
    for (int i = band * perBand; i < (band + 1) * perBand; i++) {
      e += spectrum[i];
    }
    e /= perBand;
    avgEnergies[band] = avgEnergies[band] * 0.85 + e * 0.15;
    if (e > avgEnergies[band] * 1.25 && e > 0.008) {
      beatCount++;
      beatStrength += e - avgEnergies[band] * 1.25;
    }
  }
  isBeat = beatCount >= 2;
  beatStrength = constrain(beatStrength * 3, 0, 1);
}

void drawFlash() {
  if (flashVal > 0.01) {
    noStroke();
    fill(255, 255, 220, flashVal * 50);
    rect(0, 0, width, height);
  }
}

void keyPressed() {
  switch (key) {
    case '1': layers[0].toggle(); break;
    case '2': layers[1].toggle(); break;
    case '3': layers[2].toggle(); break;
    case ' ': flashVal = 1.0; break;
  }
}
