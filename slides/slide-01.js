// slide-01.js - Cover Page
const pptxgen = require("pptxgenjs");

const slideConfig = {
  type: 'cover',
  index: 1,
  title: 'Goose AI'
};

function createSlide(pres, theme) {
  const slide = pres.addSlide();
  slide.background = { color: theme.primary };

  // Decorative accent shape - top right corner
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 7, y: 0, w: 3, h: 0.15,
    fill: { color: theme.accent }
  });

  // Large decorative circle
  slide.addShape(pres.shapes.OVAL, {
    x: 6.5, y: 2.5, w: 4, h: 4,
    fill: { color: theme.secondary, transparency: 30 }
  });

  // Smaller accent circle
  slide.addShape(pres.shapes.OVAL, {
    x: 8.5, y: 1.5, w: 1.2, h: 1.2,
    fill: { color: theme.light, transparency: 40 }
  });

  // Main title
  slide.addText("Goose AI", {
    x: 0.5, y: 1.8, w: 6, h: 1.2,
    fontSize: 72, fontFace: "Arial",
    color: theme.bg, bold: true,
    align: "left"
  });

  // Subtitle
  slide.addText("The Open-Source AI Agent", {
    x: 0.5, y: 3.1, w: 6, h: 0.6,
    fontSize: 28, fontFace: "Arial",
    color: theme.light,
    align: "left"
  });

  // Tagline
  slide.addText("Intelligent automation for developers", {
    x: 0.5, y: 3.8, w: 5, h: 0.5,
    fontSize: 18, fontFace: "Arial",
    color: theme.accent,
    align: "left"
  });

  // Bottom accent bar
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 5.4, w: 10, h: 0.225,
    fill: { color: theme.accent }
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
  pres.writeFile({ fileName: "slide-01-preview.pptx" });
}

module.exports = { createSlide, slideConfig };
