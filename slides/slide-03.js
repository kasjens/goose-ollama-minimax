// slide-03.js - Key Features
const pptxgen = require("pptxgenjs");

const slideConfig = {
  type: 'content',
  index: 3,
  title: 'Key Features'
};

function createSlide(pres, theme) {
  const slide = pres.addSlide();
  slide.background = { color: theme.bg };

  // Title
  slide.addText("Key Features", {
    x: 0.5, y: 0.4, w: 9, h: 0.8,
    fontSize: 40, fontFace: "Arial",
    color: theme.primary, bold: true,
    align: "left"
  });

  // Divider line
  slide.addShape(pres.shapes.LINE, {
    x: 0.5, y: 1.1, w: 2, h: 0,
    line: { color: theme.accent, width: 3 }
  });

  // Feature cards - 2x2 grid
  const features = [
    { title: "Autonomous Task Execution", desc: "Goose independently writes code, runs tests, and fixes issues" },
    { title: "Skills System", desc: "Extend capabilities with modular skills for different tasks" },
    { title: "Multi-Provider Support", desc: "Connect to Ollama, OpenAI, Anthropic, and more" },
    { title: "Full Codebase Awareness", desc: "Understands your entire project structure and context" }
  ];

  const positions = [
    { x: 0.5, y: 1.4 },
    { x: 5.1, y: 1.4 },
    { x: 0.5, y: 3.5 },
    { x: 5.1, y: 3.5 }
  ];

  const iconColors = [theme.primary, theme.secondary, theme.accent, theme.light];

  features.forEach((feature, i) => {
    const pos = positions[i];

    // Card background
    slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
      x: pos.x, y: pos.y, w: 4.4, h: 1.8,
      fill: { color: "FFFFFF" },
      rectRadius: 0.1,
      shadow: { type: 'outer', blur: 3, offset: 2, angle: 45, color: '000000', opacity: 0.1 }
    });

    // Colored accent bar on left of card
    slide.addShape(pres.shapes.RECTANGLE, {
      x: pos.x, y: pos.y, w: 0.12, h: 1.8,
      fill: { color: iconColors[i] }
    });

    // Feature title
    slide.addText(feature.title, {
      x: pos.x + 0.3, y: pos.y + 0.2, w: 3.9, h: 0.5,
      fontSize: 18, fontFace: "Arial",
      color: theme.primary, bold: true,
      align: "left"
    });

    // Feature description
    slide.addText(feature.desc, {
      x: pos.x + 0.3, y: pos.y + 0.75, w: 3.9, h: 0.85,
      fontSize: 13, fontFace: "Arial",
      color: theme.secondary,
      align: "left", valign: "top"
    });
  });

  // Page number badge
  slide.addShape(pres.shapes.OVAL, {
    x: 9.3, y: 5.1, w: 0.4, h: 0.4,
    fill: { color: theme.accent }
  });
  slide.addText("3", {
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
  pres.writeFile({ fileName: "slide-03-preview.pptx" });
}

module.exports = { createSlide, slideConfig };
