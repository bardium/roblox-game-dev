// Scrape names of Roblox assets using their IDs from an array ASSET_IDS. Save item names and IDs into a JSON file named output.json.
import { writeFile } from "node:fs";
import puppeteer from "puppeteer";

const ASSET_IDS = ["17237488394", "14840403674", "10414001254", "17240191081"];

(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();

  const assetObject = {};

  for (let i = 0; i < ASSET_IDS.length; i++) {
    await page.goto(`https://roblox.com/library/${ASSET_IDS[i]}`);

    const itemNameSelector = await page.waitForSelector(
      "#item-container > div.remove-panel.section-content.top-section > div.border-bottom.item-name-container > h1"
    );
    const itemName = await itemNameSelector?.evaluate((el) => el.textContent);

    console.log(`Item name for ${ASSET_IDS[i]}:`, itemName);
    assetObject[itemName] = ASSET_IDS[i];
  }

  await browser.close();

  writeFile("output.json", JSON.stringify(assetObject), (err) => {
    if (err) throw err;
    console.log("The output json has been saved!");
  });
})();
