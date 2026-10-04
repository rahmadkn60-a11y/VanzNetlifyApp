import {getSession} from "./_auth.mjs";
import {TARGET_REPO,TARGET_BRANCH,TARGET_FOLDER} from "./config.mjs";

const out=(x,s=200)=>Response.json(x,{status:s,headers:{"cache-control":"no-store"}});

function randomName(){
  const stamp=Date.now().toString(36);
  const random=crypto.randomUUID().replaceAll("-","").slice(0,12);
  return `vanz_${stamp}_${random}.lua`;
}

export default async(req)=>{
  if(req.method!=="POST")return out({error:"Method not allowed"},405);

  if(!TARGET_REPO||TARGET_REPO.startsWith("GANTI_")||!TARGET_REPO.includes("/"))
    return out({error:'TARGET_REPO belum dikonfigurasi. Buka netlify/functions/config.mjs lalu ganti TARGET_REPO.'},500);

  const session=getSession(req);
  if(!session?.token)return out({error:"GitHub belum terhubung. Klik CONNECT GITHUB."},401);

  let body;try{body=await req.json()}catch{return out({error:"Request JSON invalid."},400)}
  const code=String(body.code||"");
  if(!code.trim())return out({error:"Code kosong."},400);

  const [owner,repo]=TARGET_REPO.split("/");
  const headers={
    authorization:`Bearer ${session.token}`,
    accept:"application/vnd.github+json",
    "content-type":"application/json",
    "X-GitHub-Api-Version":"2026-03-10"
  };

  // Generate a fresh filename and verify it does not already exist.
  // This lets every upload become a new Lua file instead of replacing script.lua.
  let filename, path, api;
  for(let attempt=0;attempt<8;attempt++){
    filename=`${TARGET_FOLDER}/${randomName()}`;
    path=filename.split("/").map(encodeURIComponent).join("/");
    api=`https://api.github.com/repos/${encodeURIComponent(owner)}/${encodeURIComponent(repo)}/contents/${path}`;

    const check=await fetch(`${api}?ref=${encodeURIComponent(TARGET_BRANCH)}`,{headers});
    if(check.status===404)break;
    if(!check.ok){
      let e={};try{e=await check.json()}catch{}
      return out({error:e.message||"Cannot check target repository."},check.status);
    }
    if(attempt===7)return out({error:"Tidak bisa mendapatkan nama file unik. Coba lagi."},409);
  }

  const payload={
    message:`vanz: add ${filename}`,
    content:Buffer.from(code,"utf8").toString("base64"),
    branch:TARGET_BRANCH
  };

  const put=await fetch(api,{method:"PUT",headers,body:JSON.stringify(payload)});
  const result=await put.json();
  if(!put.ok)return out({error:result.message||"GitHub upload failed."},put.status);

  const rawUrl=`https://raw.githubusercontent.com/${owner}/${repo}/${encodeURIComponent(TARGET_BRANCH)}/${path}`;
  return out({ok:true,rawUrl,filename});
};
