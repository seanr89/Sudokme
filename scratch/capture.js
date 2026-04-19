const puppeteer = require('puppeteer');
const fs = require('fs');

async function run() {
  const browser = await puppeteer.launch({ 
    headless: "new",
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });
  const page = await browser.newPage();
  
  // Set a good viewport for screenshots
  await page.setViewport({ width: 400, height: 800 });

  console.log("Navigating to http://localhost:8080...");
  await page.goto('http://localhost:8080', { waitUntil: 'networkidle2' });
  
  console.log("Waiting 2 seconds for LoginScreen...");
  await new Promise(r => setTimeout(r, 2000));
  await page.screenshot({ path: 'login_screen.png' });
  console.log("Saved login_screen.png");

  console.log("Waiting 5 seconds for DifficultyScreen...");
  await new Promise(r => setTimeout(r, 5000));
  await page.screenshot({ path: 'difficulty_screen.png' });
  console.log("Saved difficulty_screen.png");

  console.log("Waiting 5 seconds for SudokuScreen...");
  await new Promise(r => setTimeout(r, 5000));
  await page.screenshot({ path: 'sudoku_screen.png' });
  console.log("Saved sudoku_screen.png");

  console.log("Waiting 5 seconds for HistoryScreen...");
  await new Promise(r => setTimeout(r, 5000));
  await page.screenshot({ path: 'history_screen.png' });
  console.log("Saved history_screen.png");

  await browser.close();
  console.log("Done.");
}

run().catch(console.error);
