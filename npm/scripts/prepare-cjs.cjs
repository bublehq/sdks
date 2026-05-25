const fs = require('node:fs');
const path = require('node:path');

const dist = path.join(__dirname, '..', 'dist');
const cjsDir = path.join(dist, 'cjs');
const esmEntry = path.join(dist, 'esm', 'index.js');
const cjsEntry = path.join(cjsDir, 'index.js');
const cjsPackage = path.join(cjsDir, 'package.json');

if (!fs.existsSync(esmEntry)) {
  throw new Error('Missing dist/index.js. Run TypeScript build first.');
}

if (!fs.existsSync(cjsEntry)) {
  throw new Error('Missing dist/cjs/index.js. Run CommonJS TypeScript build first.');
}

fs.writeFileSync(cjsPackage, `${JSON.stringify({ type: 'commonjs' }, null, 2)}\n`);
