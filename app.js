const $=s=>document.querySelector(s);
const source=$("#source"), count=$("#count"), convert=$("#convert"), result=$("#result"), output=$("#output"), raw=$("#raw"), toast=$("#toast");

function msg(t){toast.textContent=t;toast.classList.add("show");clearTimeout(window.__t);window.__t=setTimeout(()=>toast.classList.remove("show"),2500)}
source.addEventListener("input",()=>count.textContent=`${source.value.length.toLocaleString()} chars`);

convert.addEventListener("click",async()=>{
  if(!source.value.trim()) return msg("Paste Lua/Luau dulu.");
  convert.disabled=true;convert.classList.add("loading");
  try{
    const r=await fetch("/.netlify/functions/upload",{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({code:source.value})});
    const d=await r.json();
    if(!r.ok) throw Error(d.error||"Upload gagal.");
    output.textContent=`loadstring(game:HttpGet("${d.rawUrl}"))()`;
    raw.href=d.rawUrl;raw.textContent=d.rawUrl;result.hidden=false;
    msg("Berhasil upload ke GitHub.");
    result.scrollIntoView({behavior:"smooth",block:"center"});
  }catch(e){msg(e.message)}
  finally{convert.disabled=false;convert.classList.remove("loading")}
});

$("#copy").addEventListener("click",async()=>{
  try{await navigator.clipboard.writeText(output.textContent);msg("Loadstring disalin.");}
  catch{msg("Clipboard gagal.")}
});
