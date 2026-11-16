// L-System Prototyp 7: DRACHENKURVE (Heighway-Drache)
// Axiom: FX   Regeln: X -> X+YF+,  Y -> -FX-Y   Winkel: 90°
// (nur F zeichnet; X und Y steuern nur die Struktur)
// Steuerung:
//   LEERTASTE / Mausklick : nächste Iteration
//   T                     : 1 Drache <-> 4 gedrehte Drachen (füllen die Ebene)
//   A                     : Autoplay an/aus
//   R                     : Reset

String axiom = "FX";
boolean four = false;
boolean autoplay = false;
int iter = 1;
int maxIter = 14;
float angleDeg = 90;
float growth = 0;
int wait = 0;

String sentence;
ArrayList<PVector> pts;
float minX, maxX, minY, maxY;

void setup() {
  size(900, 700);
  colorMode(HSB, 360, 100, 100);
  build();
}

void build() {
  sentence = generate(iter);
  trace(sentence);
  growth = 0;
  wait = 0;
}

String generate(int n) {
  String s = axiom;
  for (int i = 0; i < n; i++) {
    StringBuilder next = new StringBuilder();
    for (int j = 0; j < s.length(); j++) {
      char c = s.charAt(j);
      if (c == 'X') next.append("X+YF+");
      else if (c == 'Y') next.append("-FX-Y");
      else next.append(c);              // F, +, - bleiben
    }
    s = next.toString();
  }
  return s;
}

// Punkt p um den Startpunkt (0,0) um k*90° drehen
PVector rot(PVector p, int k) {
  float c = cos(k * HALF_PI), s = sin(k * HALF_PI);
  return new PVector(p.x * c - p.y * s, p.x * s + p.y * c);
}

void trace(String s) {
  pts = new ArrayList<PVector>();
  float x = 0, y = 0, h = 0, a = radians(angleDeg);
  pts.add(new PVector(x, y));
  for (int i = 0; i < s.length(); i++) {
    char c = s.charAt(i);
    if (c == 'F') {
      x += cos(h);
      y += sin(h);
      pts.add(new PVector(x, y));
    } else if (c == '+') {
      h += a;
    } else if (c == '-') {
      h -= a;
    }
  }
  // Begrenzungsrahmen (bei 4 Kopien über alle Drehungen)
  minX = maxX = minY = maxY = 0;
  for (int k = 0; k < (four ? 4 : 1); k++) {
    for (PVector p : pts) {
      PVector r = rot(p, k);
      minX = min(minX, r.x);
      maxX = max(maxX, r.x);
      minY = min(minY, r.y);
      maxY = max(maxY, r.y);
    }
  }
}

void draw() {
  background(15);
  growth = min(1, growth + 0.012);

  if (autoplay && growth >= 1) {
    wait++;
    if (wait > 70) {
      iter = (iter < maxIter) ? iter + 1 : 1;
      build();
    }
  }

  float w = max(maxX - minX, 0.0001);
  float h = max(maxY - minY, 0.0001);
  float sc = min((width - 80) / w, (height - 140) / h);
  float ox = width / 2 - sc * (minX + maxX) / 2;
  float oy = height / 2 + 20 - sc * (minY + maxY) / 2;

  int n = int((pts.size() - 1) * growth);
  strokeWeight(iter > 10 ? 1 : 1.8);
  for (int k = 0; k < (four ? 4 : 1); k++) {
    for (int i = 0; i < n; i++) {
      PVector p = rot(pts.get(i), k), q = rot(pts.get(i + 1), k);
      float hue = (map(i, 0, pts.size(), 0, 300) + k * 90) % 360;
      stroke(hue, 75, 100);
      line(ox + sc * p.x, oy + sc * p.y, ox + sc * q.x, oy + sc * q.y);
    }
  }

  fill(0, 0, 100);
  textSize(14);
  text("Drachenkurve   Iteration " + iter + "/" + maxIter
     + "   Segmente: " + (pts.size() - 1) + " (= 2^n)", 10, 20);
  text("Jede Iteration entspricht einmal Papierstreifen falten (90°-Knicke)", 10, 40);
  text("[Leertaste/Klick] Iteration  [T] 1/4 Drachen  [A] Autoplay  [R] Reset", 10, height - 15);
}

void nextIteration() {
  if (iter < maxIter) {
    iter++;
    build();
  }
}

void keyPressed() {
  if (key == ' ') nextIteration();
  if (key == 't' || key == 'T') { four = !four; build(); }
  if (key == 'a' || key == 'A') autoplay = !autoplay;
  if (key == 'r' || key == 'R') { iter = 1; build(); }
}

void mousePressed() {
  nextIteration();
}
