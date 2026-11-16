const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname,'..');
const checker = path.basename(root).endsWith('checker');
const tpl = fs.readFileSync(path.join(root,'template.tpl'),'utf8');
function section(name) { const start=tpl.indexOf('___'+name+'___'); if(start<0)throw Error(name); const body=tpl.slice(start+name.length+6); const end=body.search(/\n___[A-Z_]+___/);return (end<0?body:body.slice(0,end)).trim(); }
const code=section('SANDBOXED_JS_FOR_WEB_TEMPLATE');
const permissions=JSON.parse(section('WEB_PERMISSIONS'));
let count=0;
function eq(a,b,label){count++;assert.deepStrictEqual(a,b,label);}
function value(v){if(v.type===1)return v.string;if(v.type===8)return v.boolean;if(v.type===2)return v.listItem.map(value);if(v.type===3)return Object.fromEntries(v.mapKey.map((k,i)=>[value(k),value(v.mapValue[i])]));throw Error('Permission schema');}
const rights=Object.fromEntries(permissions.map(p=>[p.instance.key.publicId,Object.fromEntries(p.instance.param.map(p=>[p.key,value(p.value)]))]));
function fixture(){
 const c={propertyId:'00000000-0000-7000-8000-000000000001',version:1,categories:[{key:'analytics',required:false},{key:'marketing',required:false},{key:'functional',required:false},{key:'essential',required:true}],services:[{id:'google-analytics-4',category:'analytics',essential:false},{id:'google-ads',category:'marketing',essential:false}],settings:{googleConsentMode:true,gcmMapping:{ad_storage:'marketing',ad_user_data:'marketing',ad_personalization:'marketing',analytics_storage:'analytics',functionality_storage:'functional',personalization_storage:'functional'}}};
 const s={version:1,categories:{analytics:false,marketing:false,functional:false,essential:true},services:{'google-analytics-4':true,'google-ads':true}};
 const f={config:c,state:s,host:'example.com',w:{},listeners:{},defaults:[],updates:[],events:[],injected:[],storage:new Map(),success:0,failure:0,missingPermission:null,failInjection:false};
 f.api={loaded:true,config:()=>f.config,getConsent:()=>f.state,hasConsent:id=>f.state.services[id]===true,on:(event,cb)=>(f.listeners[event]||(f.listeners[event]=[])).push(cb)};f.w.Consented=f.api;f.emit=event=>(f.listeners[event]||[]).forEach(cb=>cb());return f;
}
const base={propertyId:'00000000-0000-7000-8000-000000000001',allowedHosts:'example.com',provider:'consented',category:'analytics',service:'',requireAnalytics:false,loadCmp:true,expectedContainer:'GTM-EXAMPLE1'};
function allowed(f,permission,...args){
 if(f.missingPermission===permission)return false;
 const r=rights[permission];if(!r)return false;
 if(permission==='access_globals'){const entry=r.keys.find(k=>k.key===args[1]);return !!entry&&entry[args[0]]===true;}
 if(permission==='access_template_storage')return true;
 if(permission==='get_url')return args[0]==='host'&&r.host===true&&r.urlParts==='specific';
 if(permission==='access_consent'){const entry=r.consentTypes.find(c=>c.consentType===args[1]);return !!entry&&entry[args[0]]===true;}
 if(permission==='inject_script')return r.urls.some(pattern=>new RegExp('^'+pattern.split('*').map(x=>x.replace(/[.*+?^${}()|[\]\\]/g,'\\$&')).join('.*')+'$').test(args[0]));return false;
}
function lookup(f,key){return key.split('.').reduce((o,k)=>o==null?undefined:o[k],f.w);}
function run(f,data={}){
 const input={...base,...data,gtmOnSuccess:()=>f.success++,gtmOnFailure:()=>f.failure++};
 const api={queryPermission:(p,...a)=>allowed(f,p,...a),getType:v=>v===null?'null':Array.isArray(v)?'array':typeof v,
  getUrl:part=>{if(!allowed(f,'get_url',part))throw Error('Denied get_url');return f.host;},
  copyFromWindow:key=>{if(!allowed(f,'access_globals','read',key))throw Error('Denied global read '+key);return lookup(f,key);},
  callInWindow:(key,...args)=>{if(!allowed(f,'access_globals','execute',key))throw Error('Denied global call '+key);const fn=lookup(f,key);return typeof fn==='function'?fn(...args):undefined;},
  setDefaultConsentState:v=>{for(const key of Object.keys(v))if(!allowed(f,'access_consent','write',key))throw Error('Denied consent');f.defaults.push(v);},
  updateConsentState:v=>{for(const key of Object.keys(v))if(!allowed(f,'access_consent','write',key))throw Error('Denied consent');f.updates.push(v);},
  templateStorage:{getItem:k=>{if(!allowed(f,'access_template_storage'))throw Error('Denied template storage');return f.storage.get(k);},setItem:(k,v)=>{if(!allowed(f,'access_template_storage'))throw Error('Denied template storage');return f.storage.set(k,v);},removeItem:k=>{if(!allowed(f,'access_template_storage'))throw Error('Denied template storage');return f.storage.delete(k);}},
  createQueue:key=>{if(!allowed(f,'access_globals','read',key)||!allowed(f,'access_globals','write',key))throw Error('Denied queue');return item=>f.events.push(item);},
  injectScript:(url,success,failure)=>{if(!allowed(f,'inject_script',url))throw Error('Denied injection');f.injected.push(url);if(f.failInjection){failure();return;}if(url.endsWith('stub.js'))f.w.Consented={...f.api,loaded:false};else{f.w.Consented=f.api;f.emit('ready');}success();}
 };
 const context=vm.createContext({data:input,require:key=>{if(!(key in api))throw Error('Unknown API '+key);return api[key];}},{codeGeneration:{strings:false,wasm:false}});
 return new vm.Script('(function(data){'+code+'\n})(data)',{filename:'template.tpl'}).runInContext(context,{timeout:1000});
}
eq(JSON.parse(section('INFO')).type,checker?'MACRO':'TAG','correct template type');
eq(/\b(window|document|eval|Function|new|try|catch)\b/.test(code),false,'no standard globals or dynamic execution');
eq(permissions.every(p=>p.isRequired===true),true,'required permission schema');
eq(rights.get_url,{urlParts:'specific',host:true},'host only URL permission');
eq(rights.access_globals.keys.every(k=>checker?!k.write:(k.key==='dataLayer'?k.read&&k.write:!k.write)),true,'no unintended global writes');
eq(Object.keys(rights).some(k=>/cookie|local_storage|send_pixel|logging/.test(k)),false,'no cookie/storage/network/logging permission');
if(checker){
 for(const provider of ['consented','google','website']){
  for(const a of [false,true,'true',1,null])for(const m of [false,true,'true'])for(const service of ['', 'google-analytics-4']){
   const f=fixture();f.state.categories.analytics=a;f.state.categories.marketing=m;f.w.googlefc={getGoogleConsentModeValues:()=>({analyticsStoragePurposeConsentStatus:a===true?1:a===false?2:a,adStoragePurposeConsentStatus:m===true?1:2,adUserDataPurposeConsentStatus:m===true?1:2,adPersonalizationPurposeConsentStatus:m===true?1:2})};f.w.__lwSiteTelemetry={loaded:true,container:base.expectedContainer,provider:'consented'};
   eq(run(f,{provider,service}),provider==='google' ? (a===true || a===1) : a===true,provider+' analytics strict '+a+'/'+service);
  }
 }
 for(const a of [false,true])for(const m of [false,true])for(const requireAnalytics of [false,true]){
  const f=fixture();f.state.categories.analytics=a;f.state.categories.marketing=m;eq(run(f,{category:'marketing',requireAnalytics}),m&&(!requireAnalytics||a),'independent marketing');
 }
 for(const key of ['propertyId','category','allowedHosts']){const f=fixture();f.state.categories.analytics=true;eq(run(f,{[key]:'unknown'}),false,'unknown '+key);}
 for(const host of ['other.example','example.com.attacker.test','example.com:443','https://example.com']){const f=fixture();f.host=host;f.state.categories.analytics=true;eq(run(f),false,'host denied '+host);}
 for(const hosts of ['*.example.com','example.com/path','example.com,','example.com, *.other.com']){const f=fixture();f.state.categories.analytics=true;eq(run(f,{allowedHosts:hosts}),false,'malformed hosts '+hosts);}
 {const f=fixture();f.host='WWW.Example.com';f.state.categories.analytics=true;eq(run(f),true,'www normalization');}
 {const f=fixture();f.state.categories.analytics=true;f.config.propertyId='00000000-0000-7000-8000-000000000002';eq(run(f),false,'wrong property');}
 {const f=fixture();f.state.categories.analytics=true;f.config.version=2;eq(run(f),false,'stale consent');f.config.settings.repromptOnChange=false;eq(run(f),true,'owner explicitly preserves consent across versions');}
 {const f=fixture();f.state.categories.analytics=true;f.config.categories[0].required=true;eq(run(f),false,'required category cannot authorize optional tracking');}
 {const f=fixture();f.state.categories.analytics=true;f.state.services['google-analytics-4']=false;eq(run(f,{service:'google-analytics-4'}),false,'service refusal');f.state.services['google-analytics-4']=true;f.config.services[0].essential=true;eq(run(f,{service:'google-analytics-4'}),false,'essential service cannot authorize optional tracking');}
 {const f=fixture();f.w={};eq(run(f),false,'missing CMP');}
 for(const denied of ['access_globals','get_url']){const f=fixture();f.state.categories.analytics=true;f.missingPermission=denied;eq(run(f),false,'permission denied '+denied);}
 for(const status of [0,2,3,4,'1',true,undefined]){const f=fixture();f.w.googlefc={getGoogleConsentModeValues:()=>({analyticsStoragePurposeConsentStatus:status})};eq(run(f,{provider:'google'}),false,'Google grant must be numeric 1');}
 for(const missing of ['adStoragePurposeConsentStatus','adUserDataPurposeConsentStatus','adPersonalizationPurposeConsentStatus']){const f=fixture();const state={analyticsStoragePurposeConsentStatus:1,adStoragePurposeConsentStatus:1,adUserDataPurposeConsentStatus:1,adPersonalizationPurposeConsentStatus:1};delete state[missing];f.w.googlefc={getGoogleConsentModeValues:()=>state};eq(run(f,{provider:'google',category:'marketing'}),false,'missing Google ads purpose');}
 {const f=fixture();f.state.categories.analytics=true;f.w.__lwSiteTelemetry={loaded:true,container:base.expectedContainer,provider:'unknown'};eq(run(f,{provider:'website'}),false,'unknown bound provider');f.w.__lwSiteTelemetry.provider='consented';f.w.__lwSiteTelemetry.container='GTM-OTHER';eq(run(f,{provider:'website'}),false,'wrong bound container');}
 {const f=fixture();f.state.categories.analytics=true;eq(run(f),true,'before withdrawal');f.state.categories.analytics=false;eq(run(f),false,'after withdrawal reads live state');eq(run(f,{category:'disabled'}),false,'boolean false utility');}
}else{
 {const f=fixture();run(f);eq(f.defaults.length,1,'defaults once');eq(f.defaults[0].analytics_storage,'denied','deny first');eq(f.updates.at(-1).analytics_storage,'denied','no implicit grant');eq(f.success,1,'existing CMP attached');eq(f.injected.length,0,'no duplicate CMP');f.state.categories.analytics=true;f.emit('change');eq(f.updates.at(-1).analytics_storage,'granted','analytics grant');eq(f.updates.at(-1).ad_storage,'denied','marketing stays denied');f.state.categories.analytics=false;f.emit('change');eq(f.updates.at(-1).analytics_storage,'denied','withdrawal');eq(f.events.at(-1).event,'consented_gtm_update','native update event');}
 {const f=fixture();f.w={};run(f);eq(f.injected,['https://consented.eu/sdk/dist/stub.js','https://consented.eu/p/'+base.propertyId+'/cmp.js'],'fixed loading order');eq(f.success,1,'loaded CMP');}
 {const f=fixture();f.w={};run(f,{loadCmp:false});eq(f.failure,1,'bridge-only missing CMP fails');eq(f.injected.length,0,'bridge never injects');}
 {const f=fixture();f.config.propertyId='other';run(f);eq(f.failure,1,'foreign CMP fails');eq(f.updates.at(-1).analytics_storage,'denied','foreign CMP cannot grant');}
 {const f=fixture();f.w={};f.failInjection=true;run(f);eq(f.failure,1,'injection failure');eq(f.updates.at(-1).analytics_storage,'denied','failure stays denied');}
 {const f=fixture();run(f,{propertyId:'../bad?'});eq(f.failure,1,'invalid property');eq(f.injected.length,0,'no URL injection');}
 {const f=fixture();f.host='wrong.example';run(f);eq(f.failure,1,'wrong domain');eq(f.injected.length,0,'wrong domain never injected');}
 {const f=fixture();f.state.categories.analytics=true;f.config.settings.googleConsentMode=false;run(f);eq(f.updates.at(-1).analytics_storage,'denied','disabled Google mode respected');}
 {const f=fixture();f.state.categories.analytics=true;f.config.version=2;run(f);eq(f.updates.at(-1).analytics_storage,'denied','stale state cannot grant');}
 {const f=fixture();run(f);run(f);eq(f.defaults.length,1,'repeat does not overwrite live consent');eq(f.listeners.change.length,1,'listeners once');}
 {const f=fixture();f.missingPermission='access_consent';run(f);eq(f.failure,1,'missing consent permission fails');eq(f.injected.length,0,'no script without consent API');}
}
const summary={ok:true,template:path.basename(root),checks:count,simulation:'Node VM with declared permission enforcement; no eval and no installed dependencies',realGtmCompiler:false};
fs.writeFileSync(path.join(root,'tests/result.json'),JSON.stringify(summary,null,2)+'\n');console.log(JSON.stringify(summary));
