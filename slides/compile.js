// compile.js - Compile all slides into final presentation
const pptxgen = require('pptxgenjs');
const pres = new pptxgen();
pres.layout = 'LAYOUT_16x9';

// Theme: Luxury & Mysterious (palette #14)
const theme = {
  primary: "22223b",    // dark purple - titles
  secondary: "4a4e69",  // medium purple - body text
  accent: "9a8c98",     // muted purple - accents
  light: "c9ada7",      // light pink - highlights
  bg: "f2e9e4"          // cream - background
};

// Load and create each slide
for (let i = 1; i <= 5; i++) {
  const num = String(i).padStart(2, '0');
  const slideModule = require(`./slide-${num}.js`);
  slideModule.createSlide(pres, theme);
}

// Write final presentation
pres.writeFile({ fileName: './output/goose-presentation.pptx' })
  .then(() => {
    console.log('Presentation created: ./output/goose-presentation.pptx');
  })
  .catch(err => {
    console.error('Error creating presentation:', err);
  });
