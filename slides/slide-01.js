// slide-01.js - Cover Page
const pptxgen = require("pptxgenjs");

const slideConfig = {
  type: 'cover',
  index: 1,
  title: 'Artificial Intelligence: Transforming the Future'
};

function createSlide(pres, theme) {
  const slide = pres.addSlide();
  slide.background = { color: theme.primary };

  // Decorative accent bar on left
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 0.15, h: 5.625,
    fill: { color: theme.accent }
  });

  // Decorative circles (top right)
  slide.addShape(pres.shapes.OVAL, {
    x: 7.5, y: -0.5, w: 2.5, h: 2.5,
    fill: { color: theme.secondary, transparency: 40 }
  });
  slide.addShape(pres.shapes.OVAL, {
    x: 8.5, y: 0.3, w: 1.5, h: 1.5,
    fill: { color: theme.accent, transparency: 50 }
  });

  // Main title
  slide.addText("ARTIFICIAL", {
    x: 0.8, y: 1.8, w: 8.5, h: 1,
    fontSize: 60, fontFace: "Arial",
    color: "FFFFFF", bold: true,
    align: "left", charSpacing: 4
  });
  slide.addText("INTELLIGENCE", {
    x: 0.8, y: 2.7, w: 8.5, h: 1,
    fontSize: 60, fontFace: "Arial",
    color: theme.light, bold: true,
    align: "left", charSpacing: 4
  });

  // Subtitle
  slide.addText("Transforming the Future", {
    x: 0.8, y: 3.9, w: 6, h: 0.6,
    fontSize: 24, fontFace: "Arial",
    color: theme.accent, italic: true
  });

  // Date
  slide.addText("April 2026", {
    x: 0.8, y: 5.0, w: 3, h: 0.4,
    fontSize: 14, fontFace: "Arial",
    color: theme.light
  });

  // Bottom decorative line
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0.8, y: 4.7, w: 2.5, h: 0.04,
    fill: { color: theme.accent }
  });

  return slide;
}

// Standalone preview
if (require.main === module) {
  const pres = new pptxgen();
  pres.layout = 'LAYOUT_16x9';
  const theme = {
    primary: "1a1a2e",
    secondary: "16213e",
    accent: "e94560",
    light: "f1f1f1",
    bg: "0f0f23"
  };
  createSlide(pres, theme);
  pres.writeFile({ fileName: "slide-01-preview.pptx" });
}

module.exports = { createSlide, slideConfig };
