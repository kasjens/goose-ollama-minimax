// slide-04.js - Available Skills
const pptxgen = require("pptxgenjs");

const slideConfig = {
  type: 'content',
  index: 4,
  title: 'Available Skills'
};

function createSlide(pres, theme) {
  const slide = pres.addSlide();
  slide.background = { color: theme.bg };

  // Title
  slide.addText("Available Skills", {
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

  // Skills list with icons
  const skills = [
    { name: "Frontend Dev", desc: "React, Vue, and modern web development" },
    { name: "Fullstack Dev", desc: "End-to-end application development" },
    { name: "PDF Processing", desc: "Read, create, and manipulate PDFs" },
    { name: "Excel Operations", desc: "Spreadsheets, formulas, and data" },
    { name: "Word Documents", desc: "Create and edit DOCX files" },
    { name: "Vision Analysis", desc: "Image recognition and processing" }
  ];

  // Create two columns
  skills.forEach((skill, i) => {
    const col = i < 3 ? 0 : 1;
    const row = i % 3;
    const x = col === 0 ? 0.5 : 5.1;
    const y = 1.5 + row * 1.25;

    // Circle icon
    slide.addShape(pres.shapes.OVAL, {
      x: x, y: y, w: 0.5, h: 0.5,
      fill: { color: theme.primary }
    });

    // Skill name
    slide.addText(skill.name, {
      x: x + 0.7, y: y, w: 3.5, h: 0.4,
      fontSize: 18, fontFace: "Arial",
      color: theme.primary, bold: true,
      align: "left"
    });

    // Skill description
    slide.addText(skill.desc, {
      x: x + 0.7, y: y + 0.4, w: 3.5, h: 0.5,
      fontSize: 13, fontFace: "Arial",
      color: theme.secondary,
      align: "left"
    });
  });

  // Bottom note
  slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 0.5, y: 4.85, w: 9, h: 0.55,
    fill: { color: theme.light, transparency: 50 },
    rectRadius: 0.08
  });

  slide.addText("Skills can be combined and extended to match your specific development needs", {
    x: 0.7, y: 4.95, w: 8.6, h: 0.35,
    fontSize: 13, fontFace: "Arial",
    color: theme.secondary, italic: true,
    align: "center"
  });

  // Page number badge
  slide.addShape(pres.shapes.OVAL, {
    x: 9.3, y: 5.1, w: 0.4, h: 0.4,
    fill: { color: theme.accent }
  });
  slide.addText("4", {
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
  pres.writeFile({ fileName: "slide-04-preview.pptx" });
}

module.exports = { createSlide, slideConfig };
