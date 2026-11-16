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
