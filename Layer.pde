// Base class shared by all 9 visualizer layers.
// Each subclass receives audio-reactive data per frame via update(),
// then renders itself in draw().

abstract class Layer {
  color col;

  Layer(color c) {
    col = c;
  }

  abstract void update(float t,
                       float bass, float mid, float treble,
                       float burstA, float burstB, float burstC,
                       boolean isBeat, float beatStrength, float flashVal);

  abstract void draw();
}
