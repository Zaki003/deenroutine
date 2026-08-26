/**
 * Builds assets/cities.json — the bundled, offline city list behind the
 * "enter a city" location picker (a no-GPS alternative wired into
 * PrayerProvider/CityService).
 *
 * Source: GeoNames (https://www.geonames.org), public domain, the "cities
 * with population > 15,000" cut plus its country and admin1 (state/region)
 * reference tables, joined and trimmed down to just what the picker needs.
 * This is a bundled asset, not Firestore content, so unlike
 * seed_quiz_questions.js there's no push step — this script's output is
 * committed directly to assets/cities.json.
 *
 * One-time setup to (re)run this (e.g. to refresh with newer GeoNames data):
 *   mkdir -p scripts/.geonames-raw
 *   curl -o scripts/.geonames-raw/cities15000.zip https://download.geonames.org/export/dump/cities15000.zip
 *   curl -o scripts/.geonames-raw/countryInfo.txt https://download.geonames.org/export/dump/countryInfo.txt
 *   curl -o scripts/.geonames-raw/admin1CodesASCII.txt https://download.geonames.org/export/dump/admin1CodesASCII.txt
 *   unzip -o scripts/.geonames-raw/cities15000.zip -d scripts/.geonames-raw
 *   node scripts/build_cities_asset.js
 */

const fs = require('fs');
const path = require('path');

const RAW_DIR = path.join(__dirname, '.geonames-raw');
const OUT_FILE = path.join(__dirname, '..', 'assets', 'cities.json');

function fail(message) {
  console.error(`\nError: ${message}\n`);
  process.exit(1);
}

function readLines(filePath) {
  if (!fs.existsSync(filePath)) {
    fail(`Missing ${filePath} — see the setup steps in this script's header comment.`);
  }
  return fs
    .readFileSync(filePath, 'utf8')
    .split('\n')
    .filter((line) => line.trim().length > 0);
}

// countryInfo.txt: tab-separated, '#'-prefixed comment lines, column 0 = ISO
// code, column 4 = full country name.
function buildCountryNames() {
  const names = {};
  for (const line of readLines(path.join(RAW_DIR, 'countryInfo.txt'))) {
    if (line.startsWith('#')) continue;
    const cols = line.split('\t');
    names[cols[0]] = cols[4];
  }
  return names;
}

// admin1CodesASCII.txt: tab-separated, column 0 = "{countryCode}.{admin1Code}",
// column 1 = the region/state name (e.g. "US.GA" -> "Georgia").
function buildRegionNames() {
  const names = {};
  for (const line of readLines(path.join(RAW_DIR, 'admin1CodesASCII.txt'))) {
    const cols = line.split('\t');
    names[cols[0]] = cols[1];
  }
  return names;
}

function main() {
  const countryNames = buildCountryNames();
  const regionNames = buildRegionNames();

  // cities15000.txt is GeoNames' standard 19-column "geoname" table dump:
  // geonameid, name, asciiname, alternatenames, latitude, longitude,
  // feature class, feature code, country code, cc2, admin1 code, admin2
  // code, admin3 code, admin4 code, population, elevation, dem, timezone,
  // modification date. Only the indices used below are kept.
  const cities = [];
  for (const line of readLines(path.join(RAW_DIR, 'cities15000.txt'))) {
    const cols = line.split('\t');
    const asciiName = cols[2];
    const lat = parseFloat(cols[4]);
    const lng = parseFloat(cols[5]);
    const countryCode = cols[8];
    const admin1Code = cols[10];
    const population = parseInt(cols[14], 10) || 0;

    if (!asciiName || Number.isNaN(lat) || Number.isNaN(lng)) continue;

    const region = admin1Code ? regionNames[`${countryCode}.${admin1Code}`] || '' : '';
    // [name, countryCode, region, lat, lng, population] — array form (not
    // {name: ..., ...}) since repeating six key names across ~34,000 rows
    // would otherwise roughly double the shipped asset's size for nothing
    // CityService.fromRow can't already reconstruct positionally.
    cities.push([
      asciiName,
      countryCode,
      region,
      Math.round(lat * 10000) / 10000,
      Math.round(lng * 10000) / 10000,
      population,
    ]);
  }

  // Biggest first: CityService's in-memory search filters this list without
  // re-sorting, so build-time order is what determines result ranking (e.g.
  // Cairo, Egypt outranking Cairo, Illinois for a bare "Cairo" search).
  cities.sort((a, b) => b[5] - a[5]);

  fs.mkdirSync(path.dirname(OUT_FILE), { recursive: true });
  fs.writeFileSync(OUT_FILE, JSON.stringify({ countries: countryNames, cities }));

  const sizeKb = (fs.statSync(OUT_FILE).size / 1024).toFixed(0);
  console.log(`Wrote ${cities.length} cities (${Object.keys(countryNames).length} countries) to ${OUT_FILE} (${sizeKb} KB).`);
}

main();
