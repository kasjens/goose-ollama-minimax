// slide-05.js - Summary / Closing
const pptxgen = require("pptxgenjs");

const slideConfig = {
  type: 'summary',
  index: 5,
  title: 'Get Started with Goose'
};

function createSlide(pres, theme) {
  const slide = pres.addSlide();
  slide.background = { color: theme.primary };

  // Decorative elements
  slide.addShape(pres.shapes.OVAL, {
    x: -1, y: -1, w: 3, h: 3,
    fill: { color: theme.secondary, transparency: 50 }
  });

  slide.addShape(pres.shapes.OVAL, {
    x: 8, y: 4, w: 3, h: 3,
    fill: { color: theme.accent, transparency: 40 }
  });

  // Main title
  slide.addText("Get Started with Goose", {
    x: 0.5, y: 1.2, w: 9, h: 1,
    fontSize: 44, fontFace: "Arial",
    color: theme.bg, bold: true,
    align: "center"
  });

  // Key takeaways
  const takeaways = [
    "Open-source and community-driven",
    "Works with local models via Ollama",
    "Extensible skills architecture",
    "Designed for real development workflows"
  ];

  takeaways.forEach((item, i) => {
    const y = 2.5 + i * 0.55;

    // Checkmark circle
    slide.addShape(pres.shapes.OVAL, {
      x: 2.5, y: y, w: 0.35, h: 0.35,
      fill: { color: theme.accent }
    });

    slide.addText("✓", {
      x: 2.5, y: y - 0.02, w: 0.35, h: 0.35,
      fontSize: 16, fontFace: "Arial",
      color: theme.bg, bold: true,
      align: "center", valign: "middle"
    });

    // Takeaway text
    slide.addText(item, {
      x: 3.0, y: y, w: 5, h: 0.4,
      fontSize: 18, fontFace: "Arial",
      color: theme.bg,
      align: "left", valign: "middle"
    });
  });

  // Bottom tagline
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 5.0, w: 10, h: 0.625,
    fill: { color: theme.accent }
  });

  slide.addText("github.com/block/goose", {
    x: 0.5, y: 5.1, w: 9, h: 0.4,
    fontSize: 20, fontFace: "Arial",
    color: theme.bg, bold: true,
    align: "center"
  });

  return slide;
}

if (require.main === module) {
  const pres = new pptxgen();
  pres.layout = 'LAYOUT_16x9';
  const theme = {
    primary: "22223b",
    secondary: "4a4e69",
    accent: "9a8c98",
    light: "c9ada7",
    bg: "f2e9e4"
  };
  createSlide(pres, theme);
  pres.writeFile({ fileName: "slide-05-preview.pptx" });
}

module.exports = { createSlide, slideConfig };
