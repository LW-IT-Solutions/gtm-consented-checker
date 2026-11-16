const fs = require('node:fs');
const cp = require('node:child_process');
const sha = cp.execFileSync('git',['rev-parse','HEAD'],{encoding:'utf8'}).trim();
if (!/^[a-f0-9]{40}$/.test(sha)) throw new Error('Real Git commit required');
cp.execFileSync('git',['show',sha+':template.tpl'],{stdio:'ignore'});
fs.writeFileSync('metadata.yaml', ['homepage: "https://consented.eu"','documentation: "https://consented.eu/docs"','versions:','  - sha: '+sha,'    changeNotes: Initial release; strict CSP and live consent checks.',''].join('\n'));
console.log(sha);
