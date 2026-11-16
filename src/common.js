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
