// Base class shared by all 9 visualizer layers.
// Each layer owns a PGraphics buffer so drawing is fully independent
// w.r.t. accumulation/overlap and per-layer filters.

abstract class Layer {
  color col;
  PGraphics pg;

  Layer(color c) {
    col = c;
  }

  void initGraphics() {
    pg = createGraphics(width, height);
  }

  abstract void update(float t,
                       float bass, float mid, float treble,
                       float burstA, float burstB, float burstC,
                       boolean isBeat, float beatStrength, float flashVal);

  void draw() {
    if (pg == null) return;
    pg.beginDraw();
    drawLayer(pg);
    pg.endDraw();
    image(pg, 0, 0);
  }

  abstract void drawLayer(PGraphics g);

  void keyPressed(char k) {}
}
