const fs=require('node:fs'),cp=require('node:child_process');
const name=JSON.parse(fs.readFileSync('package.json','utf8')).name;
const sha=cp.execFileSync('git',['rev-parse','HEAD'],{encoding:'utf8'}).trim();
if(!/^[a-f0-9]{40}$/.test(sha))throw Error('Real Git commit required');
cp.execFileSync('git',['show',sha+':template.tpl'],{stdio:'ignore'});
fs.writeFileSync('metadata.yaml',['homepage: "https://consented.eu"','documentation: "https://github.com/LW-IT-Solutions/'+name+'#readme"','versions:','  - sha: '+sha,'    changeNotes: Granular service overrides, native GA4 consent and safe Google fallback.',''].join('\n'));
console.log(sha);
