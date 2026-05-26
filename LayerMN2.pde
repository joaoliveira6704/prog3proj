// Miguel Neto — LayerMN2
// Permanent sand field + radial pulse kicks on beats

class LayerMN2 extends Layer {

  ArrayList<SandParticle> particles = new ArrayList<SandParticle>();

  // Pulse rings — visual only, for feedback
  ArrayList<PulseRing> rings = new ArrayList<PulseRing>();

  float _mid, _treble, _bass;
  boolean _isBeat;
  float _beatStrength;

  static final int TARGET_PARTICLES = 600;
  static final float PULSE_RADIUS   = 340; // max influence range of a beat pulse

  LayerMN2(color c) { super(c); }

  void update(float t,
              float bass, float mid, float treble,
              float burstA, float burstB, float burstC,
              boolean isBeat, float beatStrength, float flashVal) {
    _bass        = bass;
    _mid         = mid;
    _treble      = treble;
    _isBeat      = isBeat;
    _beatStrength = beatStrength;

    // ── Keep particle pool topped up ───────────────────────────
    // Respawn wherever they fade out so the field stays full
    while (particles.size() < TARGET_PARTICLES) {
      particles.add(new SandParticle());
    }

    // ── Beat pulse ─────────────────────────────────────────────
    if (isBeat) {
      float ox = random(width  * 0.15, width  * 0.85);
      float oy = random(height * 0.15, height * 0.85);
      float force = 1.8 + beatStrength * 4.5;

      // Kick every particle based on distance from pulse origin
      for (SandParticle p : particles) {
        float dx = p.x - ox;
        float dy = p.y - oy;
        float dist = sqrt(dx * dx + dy * dy);
        if (dist < PULSE_RADIUS && dist > 0) {
          float falloff = 1.0 - (dist / PULSE_RADIUS);
          falloff = falloff * falloff; // quadratic — strong at center, zero at edge
          float f = force * falloff;
          p.vx += (dx / dist) * f;
          p.vy += (dy / dist) * f;
          p.pulseGlow = falloff; // particles near origin flash brighter
        }
      }

      // Add a visual ring
      rings.add(new PulseRing(ox, oy, beatStrength));
    }

    // ── Update particles ────────────────────────────────────────
    for (int i = particles.size() - 1; i >= 0; i--) {
      SandParticle p = particles.get(i);
      p.update(mid, treble);
      if (p.isDead()) particles.remove(i);
    }

    // ── Update rings ────────────────────────────────────────────
    for (int i = rings.size() - 1; i >= 0; i--) {
      PulseRing r = rings.get(i);
      r.update();
      if (r.isDead()) rings.remove(i);
    }
  }

  void draw() {
    // Draw rings first (behind particles)
    noFill();
    for (PulseRing r : rings) r.draw();

    // Draw particles
    noStroke();
    for (SandParticle p : particles) p.draw();
  }

  void keyPressed(char k) {
    // Manual pulse for testing: press 's'
    if (k == 's' || k == 'S') {
      _isBeat      = true;
      _beatStrength = 0.8;
      update(0, 0.5, 0.6, 0.4, 0, 0, 0, true, 0.8, 0);
    }
  }

  // ── Sand particle ─────────────────────────────────────────────
  class SandParticle {
    float x, y;
    float vx, vy;
    float life, maxLife;
    float sz;
    float pulseGlow = 0; // extra brightness from a nearby beat pulse

    SandParticle() {
      reset();
    }

    void reset() {
      // Spawn anywhere on canvas, including off-edge for natural entry
      x  = random(-20, width  + 20);
      y  = random(-20, height + 20);

      // Ambient: slow random drift
      float speed = random(0.05, 0.35);
      float angle = random(TWO_PI);
      vx = cos(angle) * speed;
      vy = sin(angle) * speed;

      sz      = random(1.0, 2.8);
      maxLife = random(180, 420);
      life    = maxLife;
      pulseGlow = 0;
    }

    void update(float mid, float treble) {
      // Apply ambient audio modulation — gentle sway
      vx += random(-0.01, 0.01) + sin(y * 0.008) * mid * 0.04;
      vy += random(-0.01, 0.01) + cos(x * 0.008) * treble * 0.03;

      // Friction — velocity decays toward ambient drift speed
      vx *= 0.965;
      vy *= 0.965;

      x += vx;
      y += vy;

      // Fade pulse glow
      pulseGlow *= 0.88;

      life--;
    }

    boolean isDead() {
      // Also die if drifted well off-screen (replaced immediately anyway)
      return life <= 0
          || x < -60 || x > width  + 60
          || y < -60 || y > height + 60;
    }

    void draw() {
      float lifeFrac = life / maxLife;
      // Fade in at birth, fade out at death
      float envelope = lifeFrac < 0.12
                     ? map(lifeFrac, 0, 0.12, 0, 1)
                     : map(lifeFrac, 0.12, 1.0,  1, 0.4);

      float glow   = min(1.0, envelope + pulseGlow * 0.9);
      float alpha  = glow * 200;
      float drawSz = sz * (1.0 + pulseGlow * 1.6); // particles swell briefly

      fill(255, 255, 255, alpha);
      ellipse(x, y, drawSz, drawSz);
    }
  }

  // ── Pulse ring ────────────────────────────────────────────────
  // Expanding ring drawn at the beat origin — purely visual cue
  class PulseRing {
    float ox, oy;
    float radius = 0;
    float maxRadius;
    float alpha = 180;
    float speed;

    PulseRing(float ox, float oy, float strength) {
      this.ox = ox;
      this.oy = oy;
      maxRadius = 200 + strength * 260;
      speed     = 6 + strength * 8;
    }

    void update() {
      radius += speed;
      speed  *= 0.97; // ring decelerates
      alpha  *= 0.88;
    }

    boolean isDead() { return alpha < 2; }

    void draw() {
      stroke(255, 255, 255, alpha);
      strokeWeight(0.8);
      ellipse(ox, oy, radius * 2, radius * 2);
      // second inner ring, slightly behind
      if (radius > 30) {
        stroke(255, 255, 255, alpha * 0.4);
        ellipse(ox, oy, (radius - 25) * 2, (radius - 25) * 2);
      }
    }
  }
}