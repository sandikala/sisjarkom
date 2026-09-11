import {esc} from './core.js';
import {renderLearn,bindLearn} from './learn.js';
import {renderResearch,bindResearch,initResearch,researchDirty,clearTimer} from './research.js';
const main=document.getElementById('main');
let modules=[],lastHash=location.hash,renderToken=0,toastTimer;
export function download(name,content,type='text/plain'){const blob=new Blob([content],{type:type+';charset=utf-8'}),url=URL.createObjectURL(blob),a=document.createElement('a');a.href=url;a.download=name;document.body.append(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(url),1500);}
function toast(message){const t=document.getElementById('toast');t.textContent=message;t.classList.add('show');clearTimeout(toastTimer);toastTimer=setTimeout(()=>t.classList.remove('show'),6000);}
function modal(html){document.getElementById('modal-content').innerHTML=html;document.getElementById('modal').showModal();}
document.getElementById('close-modal').onclick=()=>document.getElementById('modal').close();
async function render(){let token=++renderToken,focusId=document.activeElement?.id;clearTimer();const parts=location.hash.slice(1).split('/'),research=parts[0]==='riset';for(const [id,selected] of [['nav-learn',!research],['nav-research',research]]){const el=document.getElementById(id);el.classList.toggle('active',selected);if(selected)el.setAttribute('aria-current','page');else el.removeAttribute('aria-current');}
 if(research){main.innerHTML='<div class="loading" role="status">Menyiapkan dashboard…</div>';await initResearch();if(token!==renderToken)return;main.innerHTML=renderResearch(parts[1]||'ringkasan');bindResearch({rerender:render,download,toast,modal});}
 else{const id=Math.min(16,Math.max(1,parseInt(parts[1])||1)),tab=parts[2]||'ringkasan';main.innerHTML=renderLearn(modules,id,tab);bindLearn(modules,id,tab,{download,toast,modal});}
 document.querySelectorAll('[role=tablist]').forEach(list=>list.onkeydown=e=>{if(!['ArrowLeft','ArrowRight','Home','End'].includes(e.key))return;const tabs=[...list.querySelectorAll('[role=tab]')],index=tabs.indexOf(document.activeElement);if(index<0)return;e.preventDefault();const next=e.key==='Home'?0:e.key==='End'?tabs.length-1:(index+(e.key==='ArrowRight'?1:-1)+tabs.length)%tabs.length;tabs[next].focus();tabs[next].click();});
 if(focusId?.startsWith('tab-')||focusId?.startsWith('research-tab-'))document.querySelector('[role=tab][aria-selected=true]')?.focus();
}
window.addEventListener('hashchange',()=>{if(researchDirty()&&!confirm('Ada isian yang belum disimpan. Tinggalkan form ini?')){history.replaceState(null,'',lastHash||'#belajar');return;}lastHash=location.hash;render();});
window.addEventListener('beforeunload',e=>{if(researchDirty()){e.preventDefault();e.returnValue='';}});
try{const r=await fetch(new URL('./course.json',import.meta.url));if(!r.ok)throw Error('Materi belum dapat dimuat.');modules=await r.json();await render();}catch(e){main.innerHTML=`<div class="workspace"><div class="info warning"><b>Ruang belajar belum dapat dimuat.</b><p>${esc(e.message)}</p><p>Jika membuka berkas langsung, jalankan melalui server lokal atau GitHub Pages. Pastikan folder assets ikut diunggah.</p><button class="button" id="retry-app">Muat ulang</button></div></div>`;document.getElementById('retry-app').onclick=()=>location.reload();}
