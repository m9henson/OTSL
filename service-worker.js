const CACHE='ostl-supabase-1.3';
const FILES=['./','./index.html','./app-v1.3.js?v=13','./styles.css','./supabase-config.js','./manifest.webmanifest'];
self.addEventListener('install',e=>{self.skipWaiting();e.waitUntil(caches.open(CACHE).then(c=>c.addAll(FILES)))});
self.addEventListener('activate',e=>{e.waitUntil((async()=>{for(const k of await caches.keys()) if(k!==CACHE) await caches.delete(k); await self.clients.claim()})())});
self.addEventListener('fetch',e=>{if(e.request.method!=='GET')return; e.respondWith(fetch(e.request,{cache:'no-store'}).then(r=>{const x=r.clone();caches.open(CACHE).then(c=>c.put(e.request,x));return r}).catch(()=>caches.match(e.request)))});
