import {setSession} from "./_auth.mjs";

export default async(req)=>{
  const u=new URL(req.url),code=u.searchParams.get("code");
  if(!code)return new Response("OAuth code tidak ada.",{status:400});
  const r=await fetch("https://github.com/login/oauth/access_token",{
    method:"POST",headers:{"accept":"application/json","content-type":"application/json"},
    body:JSON.stringify({
      client_id:process.env.GITHUB_CLIENT_ID,
      client_secret:process.env.GITHUB_CLIENT_SECRET,
      code,
      redirect_uri:`${process.env.URL}/.netlify/functions/auth-callback`
    })
  });
  const d=await r.json();
  if(!d.access_token)return new Response("GitHub OAuth gagal: "+(d.error_description||d.error||"unknown"),{status:400});
  const me=await fetch("https://api.github.com/user",{
    headers:{authorization:`Bearer ${d.access_token}`,accept:"application/vnd.github+json","X-GitHub-Api-Version":"2026-03-10"}
  });
  const user=await me.json();
  return new Response(null,{status:302,headers:{
    location:"/",
    "set-cookie":setSession({token:d.access_token,user:user.login})
  }});
};
