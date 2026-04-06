// slide-02.js - What is Goose?
const pptxgen = require("pptxgenjs");

const slideConfig = {
  type: 'content',
  index: 2,
  title: 'What is Goose?'
};

function createSlide(pres, theme) {
  const slide = pres.addSlide();
  slide.background = { color: theme.bg };

  // Left accent bar
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 0.15, h: 5.625,
    fill: { color: theme.primary }
  });

  // Title
  slide.addText("What is Goose?", {
    x: 0.5, y: 0.4, w: 9, h: 0.8,
    fontSize: 40, fontFace: "Arial",
    color: theme.primary, bold: true,
    align: "left"
  });

  // Divider line
  slide.addShape(pres.shapes.LINE, {
    x: 0.5, y: 1.2, w: 2, h: 0,
    line: { color: theme.accent, width: 3 }
  });

  // Main description - paragraph style
  slide.addText("Goose is an open-source AI agent that autonomously handles software development tasks. It reads code, writes tests, fixes bugs, and explains functionality — all while you maintain full control.", {
    x: 0.5, y: 1.5, w: 5.5, h: 1.5,
    fontSize: 16, fontFace: "Arial",
    color: theme.secondary,
    align: "left", valign: "top"
  });

  // Key point card
  slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 0.5, y: 3.2, w: 5, h: 1.8,
    fill: { color: theme.light, transparency: 50 },
    rectRadius: 0.1
  });

  slide.addText("Built for Developers", {
    x: 0.7, y: 3.4, w: 4.6, h: 0.5,
    fontSize: 20, fontFace: "Arial",
    color: theme.primary, bold: true
  });

  slide.addText("Goose integrates directly into your workflow, understanding your codebase and acting as an intelligent pair programmer.", {
    x: 0.7, y: 3.9, w: 4.6, h: 0.9,
    fontSize: 14, fontFace: "Arial",
    color: theme.secondary,
    align: "left", valign: "top"
  });

  // Right side visual - large icon representation
  slide.addShape(pres.shapes.OVAL, {
    x: 7, y: 1.5, w: 2.5, h: 2.5,
    fill: { color: theme.accent, transparency: 20 }
  });

  slide.addShape(pres.shapes.OVAL, {
    x: 7.4, y: 1.9, w: 1.7, h: 1.7,
    fill: { color: theme.secondary }
  });

  slide.addText("AI", {
    x: 7.4, y: 2.4, w: 1.7, h: 0.6,
    fontSize: 28, fontFace: "Arial",
    color: theme.bg, bold: true,
    align: "center", valign: "middle"
  });

  // Page number badge
  slide.addShape(pres.shapes.OVAL, {
    x: 9.3, y: 5.1, w: 0.4, h: 0.4,
    fill: { color: theme.accent }
  });
  slide.addText("2", {
    x: 9.3, y: 5.1, w: 0.4, h: 0.4,
    fontSize: 12, fontFace: "Arial",
    color: "FFFFFF", bold: true,
    align: "center", valign: "middle"
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
  pres.writeFile({ fileName: "slide-02-preview.pptx" });
}

module.exports = { createSlide, slideConfig };
