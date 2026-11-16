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
