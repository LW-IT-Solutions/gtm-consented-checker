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
  "description": "Checks live category and service consent with property and hostname binding. Boolean output; blocked by default.",
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
    "displayName": "Consented property ID (public UUID)",
    "simpleValueType": true,
    "defaultValue": "",
    "help": "Copy the public property ID from consented.eu. No API key."
  },
  {
    "type": "TEXT",
    "name": "allowedHosts",
    "displayName": "Allowed hostnames (comma separated)",
    "simpleValueType": true,
    "defaultValue": "",
    "help": "Exact hostnames only. www is normalized. No wildcard, path or URL."
  },
  {
    "type": "SELECT",
    "name": "provider",
    "displayName": "Consent provider",
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
        "displayValue": "Explicit LW website provider binding"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "category",
    "displayName": "Optional category key",
    "simpleValueType": true,
    "defaultValue": "analytics",
    "help": "Examples: analytics, marketing, functional. disabled always returns false."
  },
  {
    "type": "TEXT",
    "name": "service",
    "displayName": "Optional exact service ID",
    "simpleValueType": true,
    "defaultValue": "",
    "help": "Requires both the category and the named optional service."
  },
  {
    "type": "CHECKBOX",
    "name": "requireAnalytics",
    "checkboxText": "Also require explicit Analytics consent",
    "simpleValueType": true,
    "defaultValue": false
  },
  {
    "type": "TEXT",
    "name": "expectedContainer",
    "displayName": "Expected GTM ID (website provider only)",
    "simpleValueType": true,
    "defaultValue": "",
    "help": "Only needed with the explicit website bootstrap provider."
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
 for (let i = 0; i < host.length; i++) {
  if ('abcdefghijklmnopqrstuvwxyz0123456789.-'.indexOf(host.charAt(i)) === -1) return '';
 }
 return host;
}
function hostAllowed() {
 if (!permission('get_url', 'host') || getType(data.allowedHosts) !== 'string') return false;
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
function canRead(key) { return permission('access_globals', 'read', key); }
function canCall(key) { return permission('access_globals', 'execute', key); }
function consentContext() {
 if (!uuid(data.propertyId) || !canRead('Consented.loaded') || copy('Consented.loaded') !== true) return false;
 if (!canCall('Consented.config') || !canCall('Consented.getConsent')) return false;
 const config = call('Consented.config');
 const state = call('Consented.getConsent');
 if (!config || config.propertyId !== data.propertyId || getType(config.categories) !== 'array') return false;
 if (!state || getType(state.categories) !== 'object') return false;
 if (getType(config.version) !== 'number' || getType(state.version) !== 'number') return false;
 if ((!config.settings || config.settings.repromptOnChange !== false) && config.version !== state.version) return false;
 return {config: config, state: state};
}
function categoryAllowed(context, category) {
 if (!context || getType(category) !== 'string' || context.state.categories[category] !== true) return false;
 const categories = context.config.categories;
 for (let i = 0; i < categories.length; i++) {
  const item = categories[i];
  if (item && item.key === category && item.required === false) return true;
 }
 return false;
}

if (data.category === 'disabled') return false;
if (!hostAllowed() || getType(data.category) !== 'string' || !data.category) return false;
let provider = data.provider;
if (provider === 'website') {
 const keys = ['__lwSiteTelemetry.loaded', '__lwSiteTelemetry.container', '__lwSiteTelemetry.provider'];
 for (let i = 0; i < keys.length; i++) { if (!canRead(keys[i])) return false; }
 if (getType(data.expectedContainer) !== 'string' || data.expectedContainer.indexOf('GTM-') !== 0) return false;
 if (copy(keys[0]) !== true || copy(keys[1]) !== data.expectedContainer) return false;
 provider = copy(keys[2]);
}
if (provider === 'google') {
 if (!canCall('googlefc.getGoogleConsentModeValues')) return false;
 if (data.category !== 'analytics' && data.category !== 'marketing') return false;
 if (data.service && data.service !== 'google-analytics-4' && data.service !== 'google-ads') return false;
 if (data.service === 'google-analytics-4' && data.category !== 'analytics') return false;
 if (data.service === 'google-ads' && data.category !== 'marketing') return false;
 const state = call('googlefc.getGoogleConsentModeValues');
 if (!state || getType(state) !== 'object') return false;
 if ((data.category === 'analytics' || data.requireAnalytics === true) && state.analyticsStoragePurposeConsentStatus !== 1) return false;
 if (data.category === 'analytics') return true;
 return state.adStoragePurposeConsentStatus === 1 && state.adUserDataPurposeConsentStatus === 1 && state.adPersonalizationPurposeConsentStatus === 1;
}
if (provider !== 'consented') return false;
const context = consentContext();
if (!categoryAllowed(context, data.category)) return false;
if (data.requireAnalytics === true && !categoryAllowed(context, 'analytics')) return false;
if (!data.service) return true;
if (getType(data.service) !== 'string' || !canCall('Consented.hasConsent') || getType(context.config.services) !== 'array') return false;
let found = false;
for (let i = 0; i < context.config.services.length; i++) {
 const item = context.config.services[i];
 if (item && item.id === data.service && item.category === data.category && item.essential === false) found = true;
}
return found && call('Consented.hasConsent', data.service) === true;


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
                    "string": "Consented.hasConsent"
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


___NOTES___

Apache-2.0; Copyright 2026 LW IT Solutions. See README.md for installation, permissions, strict-CSP guidance and test limitations.
