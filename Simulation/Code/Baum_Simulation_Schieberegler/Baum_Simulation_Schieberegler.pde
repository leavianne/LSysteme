// L-System Prototyp 4: SCHIEBEREGLER (ohne externe Bibliothek)
// Parameter live einstellen: Iterationen, Winkel, Länge, Zufall, Wind.

String axiom = "F";
String rule = "FF+[+F-F-F]-[-F+F+F]";
String sentence;
int lastIter = -1;
float t = 0;

Slider[] sliders;

void setup() {
  size(1000, 700);
  sliders = new Slider[] {
    new Slider("Iterationen", 20, 70, 220, 1, 5, 3, true),
    new Slider("Winkel (°)", 20, 130, 220, 5, 60, 22.5, false),
    new Slider("Länge", 20, 190, 220, 0.5, 1.5, 1.0, false),
    new Slider("Zufall (°)", 20, 250, 220, 0, 20, 0, false),
  };
}

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

void draw() {
  background(255);
  t += 0.03;
  for (Slider s : sliders) s.update();

  int iter = int(sliders[0].value);
  if (iter != lastIter) {                 // String nur bei Änderung neu erzeugen
    sentence = generate(iter);
    lastIter = iter;
  }
  float angle = radians(sliders[1].value);
  float len = 220.0 / pow(2, iter) * sliders[2].value;
  float jitter = sliders[3].value;

  randomSeed(42);                          // gleiches Zufallsmuster in jedem Frame
  pushMatrix();
  translate(width / 2 + 130, height - 20);
  int depth = 0;
  for (int i = 0; i < sentence.length(); i++) {
    char c = sentence.charAt(i);
    if (c == 'F') {
      stroke(lerpColor(color(90, 60, 30), color(60, 170, 60), constrain(depth / 4.0, 0, 1)));
      strokeWeight(max(1, 6 - depth * 1.2));
      line(0, 0, 0, -len);
      translate(0, -len);
    } else if (c == '+' || c == '-') {
      float a = angle + radians(random(-jitter, jitter));
      rotate(c == '+' ? a : -a);
    } else if (c == '[') {
      pushMatrix();
      depth++;
    } else if (c == ']') {
      popMatrix();
      depth--;
    }
  }
  popMatrix();

  // Bedienfeld
  noStroke();
  fill(240);
  rect(0, 0, 270, height);
  fill(0);
  textSize(16);
  text("L-System Parameter", 20, 30);
  textSize(12);
  text("Regel: F → " + rule, 20, 300);
  text("Symbole: " + sentence.length(), 20, 320);
  for (Slider s : sliders) s.show();
}

class Slider {
  String label;
  float x, y, w, minV, maxV, value;
  boolean isInt, dragging = false;

  Slider(String label, float x, float y, float w, float minV, float maxV, float value, boolean isInt) {
    this.label = label;
    this.x = x;
    this.y = y;
    this.w = w;
    this.minV = minV;
    this.maxV = maxV;
    this.value = value;
    this.isInt = isInt;
  }

  boolean over() {
    return mouseX >= x - 8 && mouseX <= x + w + 8 && mouseY >= y - 12 && mouseY <= y + 12;
  }

  void update() {
    if (dragging) {
      value = constrain(map(mouseX, x, x + w, minV, maxV), minV, maxV);
      if (isInt) value = round(value);
    }
  }

  void show() {
    fill(0);
    textSize(13);
    text(label + ": " + (isInt ? str(int(value)) : nf(value, 1, 1)), x, y - 14);
    stroke(150);
    strokeWeight(3);
    line(x, y, x + w, y);
    float kx = map(value, minV, maxV, x, x + w);
    noStroke();
    fill(dragging ? color(60, 140, 60) : color(90, 90, 90));
    ellipse(kx, y, 16, 16);
  }
}

void mousePressed() {
  for (Slider s : sliders) if (s.over()) s.dragging = true;
}

void mouseReleased() {
  for (Slider s : sliders) s.dragging = false;
}
