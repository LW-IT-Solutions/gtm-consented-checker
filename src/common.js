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
