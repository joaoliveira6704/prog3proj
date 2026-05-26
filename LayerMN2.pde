// Miguel Neto — layer 2
// Sand particles that burst across the scene on beats and fade out

class LayerL2 extends Layer {

  ArrayList<SandParticle> particles = new ArrayList<SandParticle>();

  float bass, mid, treble;
  boolean isBeat;
  float beatStrength;

  // Max particles on screen at once
  static final int MAX_PARTICLES = 800;

  LayerL2(color c) { super(c); }

  void update(float t,
              float bass, float mid, float treble,
              float burstA, float burstB, float burstC,
              boolean isBeat, float beatStrength, float flashVal) {
    this.bass        = bass;
    this.mid         = mid;
    this.treble      = treble;
    this.isBeat      = isBeat;
    this.beatStrength = beatStrength;

    // Update existing particles
    for (int i = particles.size() - 1; i >= 0; i--) {
      SandParticle p = particles.get(i);
      p.update();
      if (p.isDead()) particles.remove(i);
    }

    // Spawn burst on beat
    if (isBeat && particles.size() < MAX_PARTICLES) {
      int count = (int)(30 + beatStrength * 120);
      for (int i = 0; i < count; i++) {
        if (particles.size() >= MAX_PARTICLES) break;
        particles.add(new SandParticle(mid, treble));
      }
    }
  }

  void draw() {
    noStroke();
    for (SandParticle p : particles) p.draw();
  }

  // ── Sand particle ──────────────────────────────────────────
  class SandParticle {
    float x, y;
    float vx, vy;
    float life, maxLife;
    float sz;

    SandParticle(float mid, float treble) {
      // Spawn randomly across the scene
      x = random(width);
      y = random(height);

      // Slow drift — sand not projectiles
      float speed = random(0.2, 0.8 + mid * 1.5);
      float angle = random(TWO_PI);
      vx = cos(angle) * speed;
      vy = sin(angle) * speed;

      sz      = random(1, 2.5 + treble * 2);
      maxLife = random(60, 180);
      life    = maxLife;
    }

    void update() {
      x    += vx;
      y    += vy;
      vx   *= 0.97;   // friction — particles slow to a stop
      vy   *= 0.97;
      life--;
    }

    boolean isDead() { return life <= 0; }

    void draw() {
      float alpha = map(life, 0, maxLife, 0, 180);
      fill(255, 255, 255, alpha);
      ellipse(x, y, sz, sz);
    }
  }
}
