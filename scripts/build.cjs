const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const checker = path.basename(root).endsWith('checker');
const S = value => ({type:1,string:value});
const B = value => ({type:8,boolean:value});
const L = value => ({type:2,listItem:value});
const M = object => ({type:3,mapKey:Object.keys(object).map(S),mapValue:Object.values(object)});
const grant = (publicId,param) => ({instance:{key:{publicId,versionId:'1'},param:Object.entries(param).map(([key,value])=>({key,value}))},isRequired:true});
const globals = [M({key:S('Consented.loaded'),read:B(true),write:B(false),execute:B(false)}),...['Consented.config','Consented.getConsent',...(checker?['Consented.hasConsent','googlefc.getGoogleConsentModeValues']:['Consented.on'])].map(key=>M({key:S(key),read:B(false),write:B(false),execute:B(true)}))];
if(checker) for(const key of ['__lwSiteTelemetry.loaded','__lwSiteTelemetry.container','__lwSiteTelemetry.provider'])globals.push(M({key:S(key),read:B(true),write:B(false),execute:B(false)}));
if(!checker) globals.push(M({key:S('dataLayer'),read:B(true),write:B(true),execute:B(false)}));
const permissions=[grant('access_globals',{keys:L(globals)}),grant('get_url',{urlParts:S('specific'),host:B(true)})];
if(!checker){permissions.push(grant('inject_script',{urls:L([S('https://consented.eu/sdk/dist/stub.js'),S('https://consented.eu/p/*/cmp.js')])}));permissions.push(grant('access_consent',{consentTypes:L(['ad_storage','analytics_storage','ad_user_data','ad_personalization','functionality_storage','personalization_storage','security_storage','wait_for_update'].map(consentType=>M({consentType:S(consentType),read:B(false),write:B(true)})))}));}
const text=(name,displayName,defaultValue='',help='')=>({type:'TEXT',name,displayName,simpleValueType:true,defaultValue,help});
const fields=[text('propertyId','Consented property ID (public UUID)','','Copy the public property ID from consented.eu. No API key.'),text('allowedHosts','Allowed hostnames (comma separated)','','Exact hostnames only. www is normalized. No wildcard, path or URL.')];
if(checker){fields.push({type:'SELECT',name:'provider',displayName:'Consent provider',simpleValueType:true,macrosInSelect:false,defaultValue:'consented',selectItems:[{value:'consented',displayValue:'consented.eu'},{value:'google',displayValue:'Google Privacy & messaging'},{value:'website',displayValue:'Explicit LW website provider binding'}]},text('category','Optional category key','analytics','Examples: analytics, marketing, functional. disabled always returns false.'),text('service','Optional exact service ID','','Requires both the category and the named optional service.'),{type:'CHECKBOX',name:'requireAnalytics',checkboxText:'Also require explicit Analytics consent',simpleValueType:true,defaultValue:false},text('expectedContainer','Expected GTM ID (website provider only)','','Only needed with the explicit website bootstrap provider.'));}
else fields.push({type:'CHECKBOX',name:'loadCmp',checkboxText:'Load consented.eu if it is not already present',simpleValueType:true,defaultValue:true});
const info={type:checker?'MACRO':'TAG',id:'cvt_temp_public_id',version:1,securityGroups:[],displayName:checker?'consented.eu – Consent Checker':'consented.eu – CMP',description:checker?'Checks live category and service consent with property and hostname binding. Boolean output; blocked by default.':'Loads consented.eu and updates Google Consent Mode through native GTM APIs. Defaults are denied.',containerContexts:['WEB'],categories:['TAG_MANAGEMENT','UTILITY']};
const code=fs.readFileSync(path.join(root,'src/common.js'),'utf8')+'\n'+fs.readFileSync(path.join(root,'src/template.js'),'utf8');
const tos="By creating or modifying this file you agree to Google Tag Manager's Community\nTemplate Gallery Developer Terms of Service available at\nhttps://developers.google.com/tag-manager/gallery-tos (or such other URL as\nGoogle may provide), as modified from time to time.";
const sections={TERMS_OF_SERVICE:tos,INFO:JSON.stringify(info,null,2),TEMPLATE_PARAMETERS:JSON.stringify(fields,null,2),SANDBOXED_JS_FOR_WEB_TEMPLATE:code,WEB_PERMISSIONS:JSON.stringify(permissions,null,2),TESTS:fs.readFileSync(path.join(root,'tests/gtm-scenarios.yaml'),'utf8'),NOTES:'Apache-2.0; Copyright 2026 LW IT Solutions. See README.md for installation, permissions, strict-CSP guidance and test limitations.'};
fs.writeFileSync(path.join(root,'template.tpl'),Object.entries(sections).map(([key,value])=>'___'+key+'___\n\n'+value.trim()+'\n').join('\n\n'));
console.log(path.basename(root)+': template.tpl built');
