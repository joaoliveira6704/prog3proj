// Abstract base class for all 9 visualizer layers
// Each layer owns a PGraphics buffer for fully independent rendering

abstract class Layer {
  color col;
  PGraphics pg;

  Layer(color c) {
    col = c;
  }

  // Create the off-screen buffer sized to the display
  void initGraphics() {
    pg = createGraphics(width, height);
  }

  // Called every frame with time and audio analysis data
  abstract void update(float t,
                       float bass, float mid, float treble,
                       float burstA, float burstB, float burstC,
                       boolean isBeat, float beatStrength, float flashVal);

  // Render the layer by drawing to its buffer then compositing to screen
  void draw() {
    if (pg == null) return;
    pg.beginDraw();
    drawLayer(pg);
    pg.endDraw();
    image(pg, 0, 0);
  }

  // Subclasses implement their drawing logic here
  abstract void drawLayer(PGraphics g);

  // Optional per-layer key press handler
  void keyPressed(char k) {}
}
