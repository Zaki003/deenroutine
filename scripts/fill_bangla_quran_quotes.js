/**
 * Fills in the `textBn` field for Qur'an-sourced entries in data/daily_quotes.json
 * by fetching the Muhiuddin Khan Bengali translation from the free AlQuran Cloud
 * API (api.alquran.cloud — no key required).
 *
 * Only touches entries whose "source" looks like "Qur'an <surah>:<ayah>" or
 * "Qur'an <surah>:<start>-<end>" and that don't already have a non-empty textBn,
 * so it's safe to re-run after adding new verses to the file. Hadith entries are
 * left untouched — Bangla hadith translation needs a different source and isn't
 * handled here.
 *
 * Usage (from the project root):
 *   node scripts/fill_bangla_quran_quotes.js            # fetch + write
 *   node scripts/fill_bangla_quran_quotes.js --dry-run  # fetch + report, write nothing
 */

const fs = require('fs');
const path = require('path');

const DATA_FILE = path.join(__dirname, '..', 'data', 'daily_quotes.json');
const EDITION = 'bn.bengali'; // Muhiuddin Khan Bengali translation
const SOURCE_RE = /^Qur'an\s+(\d+):(\d+)(?:-(\d+))?\s*$/;
const REQUEST_DELAY_MS = 150;

const dryRun = process.argv.includes('--dry-run');

function fail(message) {
  console.error(`\nError: ${message}\n`);
  process.exit(1);
}

function loadQuotes() {
  if (!fs.existsSync(DATA_FILE)) fail(`Data file not found: ${DATA_FILE}`);
  try {
    return JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
  } catch (err) {
    fail(`${DATA_FILE} is not valid JSON.\n  ${err.message}`);
  }
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function fetchAyah(surah, ayah, attempt = 1) {
  const url = `https://api.alquran.cloud/v1/ayah/${surah}:${ayah}/${EDITION}`;
  try {
    const res = await fetch(url);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const json = await res.json();
    if (json.code !== 200 || !json.data || !json.data.text) {
      throw new Error(`unexpected response: ${JSON.stringify(json).slice(0, 200)}`);
    }
    return json.data.text.trim();
  } catch (err) {
    if (attempt < 3) {
      await sleep(400 * attempt);
      return fetchAyah(surah, ayah, attempt + 1);
    }
    throw err;
  }
}

async function main() {
  const quotes = loadQuotes();
  if (!Array.isArray(quotes)) fail('The data file must contain a JSON array of quotes.');

  const candidates = quotes.filter((q) => SOURCE_RE.test(q.source || ''));
  const alreadyDone = candidates.filter((q) => q.textBn && q.textBn.trim());
  const toFetch = candidates.filter((q) => !(q.textBn && q.textBn.trim()));

  console.log(
    `${candidates.length} Qur'an-sourced quote(s) found: ` +
      `${alreadyDone.length} already have textBn, ${toFetch.length} to fetch.`
  );

  const failed = [];
  let updated = 0;

  for (const quote of toFetch) {
    const m = quote.source.match(SOURCE_RE);
    const surah = Number(m[1]);
    const start = Number(m[2]);
    const end = m[3] ? Number(m[3]) : start;

    const parts = [];
    try {
      for (let ayah = start; ayah <= end; ayah++) {
        parts.push(await fetchAyah(surah, ayah));
        await sleep(REQUEST_DELAY_MS);
      }
    } catch (err) {
      failed.push({ id: quote.id, source: quote.source, error: err.message });
      console.error(`  ✗ ${quote.id} (${quote.source}): ${err.message}`);
      continue;
    }

    quote.textBn = parts.join(' ');
    updated++;
    console.log(`  ✓ ${quote.id} (${quote.source})`);
  }

  console.log(`\n${updated} quote(s) updated, ${failed.length} failed.`);

  if (dryRun) {
    console.log('\nDry run — nothing written.\n');
    return;
  }

  if (updated > 0) {
    fs.writeFileSync(DATA_FILE, JSON.stringify(quotes, null, 2) + '\n');
    console.log(`Wrote changes to ${DATA_FILE}.`);
  }

  if (failed.length) {
    console.log('\nCould not fetch (left textBn empty):');
    failed.forEach((f) => console.log(`  - ${f.id} (${f.source}): ${f.error}`));
    console.log('\nRe-run this script to retry just these — everything else is skipped as already done.\n');
  }

  console.log(
    '\nNext step: review the diff in data/daily_quotes.json, then run ' +
      '`npm run seed:quotes` (or `:check` first) to push it to Firestore.\n'
  );
}

main().catch((err) => fail(err.stack || err.message));
