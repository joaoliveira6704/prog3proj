// Project: Planet Caravan — 9 Layer Visualizer
// Processing 4 | Group: Joao Oliveira, Miguel Neto, Joao Santos
// Keys: 1-9 toggle layers JO1-3/MN1-3/JS1-3 on/off
// Space = flash, Q/W/E = JO actions, A/S/D = MN actions, Z/X/C = JS actions

import processing.sound.*;

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

// Global palette with 8 colors (within the required 3-8 range)
color[] palette = new color[8];

Layer[] layers = new Layer[9];
boolean[] layerActive = new boolean[9];

void settings() {
  fullScreen(P2D);
}

void setup() {
  frameRate(25);
  colorMode(RGB, 255);
  background(0);

  palette[0] = color(167, 123, 202);
  palette[1] = color(123, 170, 232);
  palette[2] = color(232, 123, 123);
  palette[3] = color(123, 232, 180);
  palette[4] = color(232, 201, 122);
  palette[5] = color(232, 123, 187);
  palette[6] = color(123, 232, 232);
  palette[7] = color(188, 232, 123);

  // Load and loop the MP3 file
  music = new SoundFile(this, "music.mp3");
  music.loop();
  music.jump(0);

  // Initialize FFT using the music file as input
  fft = new FFT(this, bands);
  fft.input(music);

  // Create all 9 layers (3 per team member)
  // Joao Oliveira
  layers[0] = new LayerJO1(palette[0]);
  layers[1] = new LayerJO2(palette[1]);
  layers[2] = new LayerJO3(palette[2]);
  // Miguel Neto
  layers[3] = new LayerMN1(palette[3]);
  layers[4] = new LayerMN2(palette[4]);
  layers[5] = new LayerMN3(palette[5]);
  // Joao Santos
  layers[6] = new LayerJS1(palette[6]);
  layers[7] = new LayerJS2(palette[7]);
  layers[8] = new LayerJS3(palette[0]);

  // Each layer gets its own PGraphics buffer for independent rendering
  for (int i = 0; i < layers.length; i++) layers[i].initGraphics();

  // Activate initial layers
  layerActive[0] = true;
  layerActive[1] = true;
  layerActive[2] = true;
  layerActive[5] = true;
  layerActive[8] = true;
}

void draw() {
  background(0);
  t += 0.016;

  analyzeAudio();

  // Layer index 2 (LayerJO3) is drawn last so it stays on top
  int topLayerIndex = 2;

  // Draw all layers except the top layer
  for (int i = 0; i < 9; i++) {
    if (i != topLayerIndex && layerActive[i] && layers[i] != null) {
      Layer l = layers[i];
      l.update(t, bass, mid, treble, burstA, burstB, burstC, isBeat, beatStrength, flashVal);
      l.draw();
    }
  }

  // Draw the top layer last so it stays in the foreground
  if (layerActive[topLayerIndex] && layers[topLayerIndex] != null) {
    Layer l = layers[topLayerIndex];
    l.update(t, bass, mid, treble, burstA, burstB, burstC, isBeat, beatStrength, flashVal);
    l.draw();
  }

  drawFlash();

  // Decay burst and flash values over time
  burstA *= 0.92;
  burstB *= 0.92;
  burstC *= 0.92;
  flashVal *= 0.85;
}

// Analyze audio spectrum and detect beats
void analyzeAudio() {
  fft.analyze(spectrum);

  // Split spectrum into bass, mid, and treble ranges
  float b = 0, m = 0, tr = 0;
  for (int i = 0;  i < 8;  i++) b  += spectrum[i];
  for (int i = 8;  i < 64; i++) m  += spectrum[i];
  for (int i = 64; i < bands; i++) tr += spectrum[i];

  bass   = constrain(b  / (8   * 0.05), 0, 1);
  mid    = constrain(m  / (56  * 0.05), 0, 1);
  treble = constrain(tr / (448 * 0.02), 0, 1);

  // Gentle fallback when audio signal is weak
  if (bass   < 0.05) bass   = 0.10 + 0.07 * sin(t * 0.8);
  if (mid    < 0.05) mid    = 0.10 + 0.06 * sin(t * 1.3 + 1);
  if (treble < 0.05) treble = 0.08 + 0.05 * sin(t * 2.1 + 2);

  // Multi-band beat detection using spectral flux
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

// Draw a semi-transparent white flash overlay
void drawFlash() {
  if (flashVal > 0.01) {
    noStroke();
    fill(255, 255, 220, flashVal * 50);
    rect(0, 0, width, height);
  }
}

// Keyboard controls for toggling layers and triggering actions
void keyPressed() {
  switch (key) {
    case '1': layerActive[0] = !layerActive[0]; break;
    case '2': layerActive[1] = !layerActive[1]; break;
    case '3': layerActive[2] = !layerActive[2]; break;
    case '4': layerActive[3] = !layerActive[3]; break;
    case '5': layerActive[4] = !layerActive[4]; break;
    case '6': layerActive[5] = !layerActive[5]; break;
    case '7': layerActive[6] = !layerActive[6]; break;
    case '8': layerActive[7] = !layerActive[7]; break;
    case '9': layerActive[8] = !layerActive[8]; break;
    case ' ': flashVal = 1.0; break;
      // JO layer actions
      case 'q':
      case 'Q':
        if (layerActive[0]) layers[0].keyPressed(key);
        break;
      case 'w':
      case 'W':
        if (layerActive[1]) layers[1].keyPressed(key);
        break;
      case 'e':
      case 'E':
        if (layerActive[2]) layers[2].keyPressed(key);
        break;

      // MN layer actions
      case 'a':
      case 'A':
        if (layerActive[3]) layers[3].keyPressed(key);
        break;
      case 's':
      case 'S':
        if (layerActive[4]) layers[4].keyPressed(key);
        break;
      case 'd':
      case 'D':
        if (layerActive[5]) layers[5].keyPressed(key);
        break;

      // JS layer actions
      case 'z':
      case 'Z':
        if (layerActive[6]) layers[6].keyPressed(key);
        break;
      case 'x':
      case 'X':
        if (layerActive[7]) layers[7].keyPressed(key);
        break;
      case 'c':
      case 'C':
        if (layerActive[8]) layers[8].keyPressed(key);
        break;
    }
}
