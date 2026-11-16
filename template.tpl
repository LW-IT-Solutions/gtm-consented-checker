___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.


___INFO___

{
  "type": "MACRO",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "consented.eu – Consent Checker",
  "description": "Live-Prüfung von Kategorien und individuellen Dienstentscheidungen. Explizite Ablehnung hat Vorrang.",
  "containerContexts": [
    "WEB"
  ],
  "categories": [
    "TAG_MANAGEMENT",
    "UTILITY"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "propertyId",
    "displayName": "Öffentliche Consented-Property-ID (UUID)",
    "simpleValueType": true,
    "defaultValue": "",
    "help": ""
  },
  {
    "type": "TEXT",
    "name": "allowedHosts",
    "displayName": "Erlaubte Hostnamen (kommagetrennt)",
    "simpleValueType": true,
    "defaultValue": "",
    "help": "Exakte Hostnamen; www wird normalisiert. Keine URL oder Wildcard."
  },
  {
    "type": "SELECT",
    "name": "provider",
    "displayName": "Consent-Quelle",
    "simpleValueType": true,
    "macrosInSelect": false,
    "defaultValue": "consented",
    "selectItems": [
      {
        "value": "consented",
        "displayValue": "consented.eu"
      },
      {
        "value": "google",
        "displayValue": "Google Privacy & messaging"
      },
      {
        "value": "website",
        "displayValue": "Explizite Website-Providerbindung"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "expectedContainer",
    "displayName": "Erwartete GTM-ID (Website-Modus)",
    "simpleValueType": true,
    "defaultValue": "",
    "help": ""
  },
  {
    "type": "CHECKBOX",
    "name": "allowGoogleFallback",
    "checkboxText": "Ohne Website-Bindung: vorhandene CMP verwenden, sonst ausdrückliches Google-Signal prüfen",
    "simpleValueType": true,
    "defaultValue": false
  },
  {
    "type": "TEXT",
    "name": "category",
    "displayName": "Kategorie-Schlüssel",
    "simpleValueType": true,
    "defaultValue": "analytics",
    "help": ""
  },
  {
    "type": "TEXT",
    "name": "service",
    "displayName": "Exakte Dienst-ID (optional)",
    "simpleValueType": true,
    "defaultValue": "",
    "help": "Explizites Dienst-true/false hat Vorrang vor der Kategorie."
  },
  {
    "type": "TEXT",
    "name": "serviceIds",
    "displayName": "Alternativ: Liste von Dienst-IDs (ODER)",
    "simpleValueType": true,
    "defaultValue": "",
    "help": ""
  },
  {
    "type": "CHECKBOX",
    "name": "allowEssential",
    "checkboxText": "Bekannten notwendigen Dienst ohne optionale Einwilligung erlauben",
    "simpleValueType": true,
    "defaultValue": false
  },
  {
    "type": "CHECKBOX",
    "name": "requireAnalytics",
    "checkboxText": "Zusätzlich mindestens einen erlaubten Analytics-Dienst verlangen",
    "simpleValueType": true,
    "defaultValue": false
  }
]


___SANDBOXED_JS_FOR_WEB_TEMPLATE___

const copy = require('copyFromWindow');
const call = require('callInWindow');
const getType = require('getType');
const getUrl = require('getUrl');
const permission = require('queryPermission');
function uuid(value) {
 if (getType(value) !== 'string' || value.length !== 36) return false;
 const v = value.toLowerCase();
 for (let i = 0; i < 36; i++) {
  if (i === 8 || i === 13 || i === 18 || i === 23) { if (v.charAt(i) !== '-') return false; }
  else if ('0123456789abcdef'.indexOf(v.charAt(i)) === -1) return false;
 }
 return true;
}
function normalizedHost(host) {
 if (getType(host) !== 'string') return '';
 host = host.toLowerCase().trim();
 if (host.indexOf('www.') === 0) host = host.substring(4);
 if (!host || host.length > 253) return '';
 for (let i = 0; i < host.length; i++) if ('abcdefghijklmnopqrstuvwxyz0123456789.-'.indexOf(host.charAt(i)) === -1) return '';
 return host;
}
function hostAllowed() {
 if (!permission('get_url','host') || getType(data.allowedHosts) !== 'string') return false;
 const host = normalizedHost(getUrl('host'));
 const hosts = data.allowedHosts.split(',');
 if (!host || hosts.length > 50) return false;
 let found = false;
 for (let i = 0; i < hosts.length; i++) {
  const allowed = normalizedHost(hosts[i]);
  if (!allowed) return false;
  if (host === allowed) found = true;
 }
 return found;
}
function canRead(key) { return permission('access_globals','read',key); }
function canCall(key) { return permission('access_globals','execute',key); }
function activeProvider() {
 if (data.provider === 'consented' || data.provider === 'google') return data.provider;
 if (data.provider !== 'website') return false;
 const keys = ['__lwSiteTelemetry.loaded','__lwSiteTelemetry.container','__lwSiteTelemetry.provider'];
 for (let i = 0; i < keys.length; i++) if (!canRead(keys[i])) return false;
 const loaded = copy(keys[0]), container = copy(keys[1]), provider = copy(keys[2]);
 if (loaded === undefined && container === undefined && provider === undefined && data.allowGoogleFallback === true) {
  if (!canRead('Consented.loaded')) return false;
  return copy('Consented.loaded') === true ? 'consented' : 'google';
 }
 if (getType(data.expectedContainer) !== 'string' || data.expectedContainer.indexOf('GTM-') !== 0) return false;
 if (loaded !== true || container !== data.expectedContainer) return false;
 return provider === 'consented' || provider === 'google' ? provider : false;
}
function readConfig() {
 if (!uuid(data.propertyId) || !canRead('Consented.loaded') || copy('Consented.loaded') !== true || !canCall('Consented.config')) return false;
 const config = call('Consented.config');
 return config && config.propertyId === data.propertyId && getType(config.categories) === 'array' && getType(config.services) === 'array' ? config : false;
}
function consentContext() {
 const config = readConfig();
 if (!config || !canCall('Consented.getConsent')) return false;
 const state = call('Consented.getConsent');
 if (!state || getType(state.categories) !== 'object' || getType(config.version) !== 'number' || getType(state.version) !== 'number') return false;
 if ((!config.settings || config.settings.repromptOnChange !== false) && config.version !== state.version) return false;
 return {config:config,state:state};
}
function categoryInfo(config,key) {
 let result = false;
 for (let i = 0; i < config.categories.length; i++) {
  const c = config.categories[i];
  if (c && c.key === key) { if (result) return false; result = c; }
 }
 return result;
}
function categoryAllowed(context,key) {
 if (!context || getType(key) !== 'string') return false;
 const c = categoryInfo(context.config,key);
 return c && c.required === false && context.state.categories[key] === true ? true : false;
}
function serviceInfo(config,id) {
 let result = false;
 for (let i = 0; i < config.services.length; i++) {
  const s = config.services[i];
  if (s && s.id === id) { if (result) return false; result = s; }
 }
 return result;
}
function serviceAllowed(context,id,category,allowEssential) {
 if (!context || getType(id) !== 'string' || !id) return false;
 const service = serviceInfo(context.config,id);
 if (!service || (category && service.category !== category)) return false;
 const cat = categoryInfo(context.config,service.category);
 if (!cat) return false;
 if (service.essential === true) return allowEssential === true && cat.required === true && service.category === 'essential';
 if (service.essential !== false || cat.required !== false || !context.state) return false;
 const choices = context.state.services;
 if (choices !== undefined && getType(choices) !== 'object') return false;
 const explicit = choices ? choices[id] : undefined;
 if (explicit !== undefined) return explicit === true;
 return context.state.categories[service.category] === true;
}
function anyCategoryAllowed(context,key) {
 if (!context) return false;
 for (let i = 0; i < context.config.services.length; i++) {
  const s = context.config.services[i];
  if (s && s.category === key && serviceAllowed(context,s.id,key,false)) return true;
 }
 return false;
}
function serviceIds() {
 if (data.service) return getType(data.service) === 'string' ? [data.service] : false;
 if (!data.serviceIds) return [];
 if (getType(data.serviceIds) !== 'string') return false;
 const ids = data.serviceIds.split(',');
 if (ids.length > 100) return false;
 for (let i = 0; i < ids.length; i++) { ids[i] = ids[i].trim(); if (!ids[i]) return false; }
 return ids;
}
function googleState() {
 if (!canCall('googlefc.getGoogleConsentModeValues')) return false;
 const s = call('googlefc.getGoogleConsentModeValues');
 return getType(s) === 'object' ? s : false;
}
function googleAllowed(state,category,service) {
 if (!state) return false;
 if (service) {
  if ((service === 'google-analytics-4' || service === 'google-tag-manager') && category !== 'analytics') return false;
  else if ((service === 'google-ads' || service === 'google-adsense') && category !== 'marketing') return false;
  else if (service !== 'google-analytics-4' && service !== 'google-tag-manager' && service !== 'google-ads' && service !== 'google-adsense') return false;
 }
 if (category === 'analytics') return state.analyticsStoragePurposeConsentStatus === 1;
 if (category !== 'marketing') return false;
 return state.adStoragePurposeConsentStatus === 1 && state.adUserDataPurposeConsentStatus === 1 && state.adPersonalizationPurposeConsentStatus === 1;
}

if (data.category === 'disabled') return false;
if (!hostAllowed() || getType(data.category) !== 'string' || !data.category) return false;
const provider = activeProvider();
const ids = serviceIds();
if (!ids) return false;
if (provider === 'google') {
 const state = googleState();
 if (data.requireAnalytics === true && !googleAllowed(state,'analytics','google-analytics-4')) return false;
 if (!ids.length) return googleAllowed(state,data.category,'');
 for (let i = 0; i < ids.length; i++) if (googleAllowed(state,data.category,ids[i])) return true;
 return false;
}
if (provider !== 'consented') return false;
let context = consentContext();
if (!context && data.allowEssential === true) {
 const config = readConfig();
 if (config) context = {config:config,state:false};
}
if (!context) return false;
if (data.requireAnalytics === true && !anyCategoryAllowed(context,'analytics')) return false;
if (!ids.length) return categoryAllowed(context,data.category);
for (let i = 0; i < ids.length; i++) if (serviceAllowed(context,ids[i],data.category,data.allowEssential === true)) return true;
return false;


___WEB_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "access_globals",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keys",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "Consented.loaded"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "Consented.config"
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": true
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "Consented.getConsent"
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": true
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "googlefc.getGoogleConsentModeValues"
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": true
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "__lwSiteTelemetry.loaded"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "__lwSiteTelemetry.container"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "__lwSiteTelemetry.provider"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              }
            ]
          }
        }
      ]
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "get_url",
        "versionId": "1"
      },
      "param": [
        {
          "key": "urlParts",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "host",
          "value": {
            "type": 8,
            "boolean": true
          }
        }
      ]
    },
    "isRequired": true
  }
]


___TESTS___

scenarios:
- name: Missing CMP stays blocked
  code: |-
    mock('getUrl', function () { return 'example.com'; });
    mock('queryPermission', function () { return true; });
    mock('copyFromWindow', function () { return undefined; });
    mock('callInWindow', function () { return undefined; });
    assertThat(runCode({propertyId:'00000000-0000-7000-8000-000000000001',allowedHosts:'example.com',provider:'consented',category:'analytics'})).isEqualTo(false);
- name: Explicit Google Analytics grant is allowed
  code: |-
    mock('getUrl', function () { return 'example.com'; });
    mock('queryPermission', function () { return true; });
    mock('callInWindow', function () { return {analyticsStoragePurposeConsentStatus:1}; });
    assertThat(runCode({allowedHosts:'example.com',provider:'google',category:'analytics'})).isEqualTo(true);
- name: Google NOT_CONFIGURED is not consent
  code: |-
    mock('getUrl', function () { return 'example.com'; });
    mock('queryPermission', function () { return true; });
    mock('callInWindow', function () { return {analyticsStoragePurposeConsentStatus:4}; });
    assertThat(runCode({allowedHosts:'example.com',provider:'google',category:'analytics'})).isEqualTo(false);

- name: Granular GA4 grant with category disabled
  code: |-
    mock('getUrl', function () { return 'example.com'; });
    mock('queryPermission', function () { return true; });
    mock('copyFromWindow', function () { return true; });
    mock('callInWindow', function (key) {
      if (key === 'Consented.config') return {propertyId:'00000000-0000-7000-8000-000000000001',version:1,categories:[{key:'analytics',required:false}],services:[{id:'google-analytics-4',category:'analytics',essential:false}],settings:{}};
      return {version:1,categories:{analytics:false},services:{'google-analytics-4':true}};
    });
    assertThat(runCode({propertyId:'00000000-0000-7000-8000-000000000001',allowedHosts:'example.com',provider:'consented',category:'analytics',service:'google-analytics-4'})).isEqualTo(true);
- name: Explicit GA4 denial beats category grant
  code: |-
    mock('getUrl', function () { return 'example.com'; });
    mock('queryPermission', function () { return true; });
    mock('copyFromWindow', function () { return true; });
    mock('callInWindow', function (key) {
      if (key === 'Consented.config') return {propertyId:'00000000-0000-7000-8000-000000000001',version:1,categories:[{key:'analytics',required:false}],services:[{id:'google-analytics-4',category:'analytics',essential:false}],settings:{}};
      return {version:1,categories:{analytics:true},services:{'google-analytics-4':false}};
    });
    assertThat(runCode({propertyId:'00000000-0000-7000-8000-000000000001',allowedHosts:'example.com',provider:'consented',category:'analytics',service:'google-analytics-4'})).isEqualTo(false);


___NOTES___

Apache-2.0; Copyright 2026 LW IT Solutions. Read README.md. No eval or Custom JavaScript variables. Native GTM editor/preview validation remains required.
