// L-System Baum – Prototyp (Processing, Java-Modus)
// Steuerung:
//   LEERTASTE / Mausklick : nächste Iteration (Baum wächst)
//   R                     : Reset
//   W                     : Wind an/aus
//   Pfeil hoch/runter     : Winkel ändern

String axiom = "F";
String rule  = "FF+[+F-F-F]-[-F+F+F]";   // F -> ...
int maxIter  = 5;
int iter     = 1;
String sentence;

float angleDeg = 22.5;
float len;
float growth = 0;       // 0..1: Wie viel vom String schon gezeichnet ist
float t = 0;            // Zeit für Wind
boolean windOn = true;

void setup() {
  size(900, 700);
  reset();
}

void reset() {
  iter = 1;
  sentence = generate(iter);
  growth = 0;
}

// Wendet die Produktionsregel n-mal parallel auf alle Symbole an
String generate(int n) {
  String s = axiom;
  for (int i = 0; i < n; i++) {
    StringBuilder next = new StringBuilder();
    for (int j = 0; j < s.length(); j++) {
      char c = s.charAt(j);
      if (c == 'F') next.append(rule);
      else next.append(c);
    }
    s = next.toString();
  }
  return s;
}

// Seitliches Schwanken je Verzweigungstiefe
float sway(int depth) {
  if (!windOn) return 0;
  return radians(2.5) * sin(t + depth * 0.7) * (depth + 1) * 0.5;
}

void draw() {
  background(235, 245, 255);
  t += 0.03;
  growth = min(1, growth + 0.008);

  len = 220.0 / pow(2, iter);
  float angle = radians(angleDeg);

  translate(width / 2, height - 20);

  int n = int(sentence.length() * growth);   // Wachstumsanimation
  int depth = 0;

  for (int i = 0; i < n; i++) {
    char c = sentence.charAt(i);
    if (c == 'F') {
      stroke(lerpColor(color(90, 60, 30), color(60, 170, 60), constrain(depth / 4.0, 0, 1)));
      strokeWeight(max(1, 6 - depth * 1.2));
      line(0, 0, 0, -len);
      translate(0, -len);
    } else if (c == '+') {
      rotate(angle + sway(depth));
    } else if (c == '-') {
      rotate(-angle + sway(depth));
    } else if (c == '[') {
      pushMatrix();
      depth++;
    } else if (c == ']') {
      popMatrix();
      depth--;
    }
  }
  while (depth-- > 0) popMatrix();   // Stack aufräumen bei Teil-Zeichnung

  // Infotext (ohne Transformation)
  resetMatrix();
  fill(0);
  textSize(14);
  text("Iteration: " + iter + "/" + maxIter + "   Winkel: " + nf(angleDeg, 1, 1)
     + "°   Wind: " + (windOn ? "an" : "aus")
     + "   Symbole: " + sentence.length(), 10, 20);
  text("[Leertaste/Klick] wachsen  [R] Reset  [W] Wind  [↑/↓] Winkel", 10, 40);
}

void nextIteration() {
  if (iter < maxIter) {
    iter++;
    sentence = generate(iter);
    growth = 0;
  }
}

void keyPressed() {
  if (key == ' ') nextIteration();
  if (key == 'r' || key == 'R') reset();
  if (key == 'w' || key == 'W') windOn = !windOn;
  if (keyCode == UP)   angleDeg += 1;
  if (keyCode == DOWN) angleDeg -= 1;
}

void mousePressed() {
  nextIteration();
}
