import crypto from "node:crypto";
import {seal} from "./_auth.mjs";

export default async()=>{
  if(!process.env.GITHUB_CLIENT_ID)return new Response("GITHUB_CLIENT_ID belum diatur.",{status:500});
  const state=seal({nonce:crypto.randomBytes(24).toString("hex"),exp:Date.now()+600000});
  const u=new URL("https://github.com/login/oauth/authorize");
  u.searchParams.set("client_id",process.env.GITHUB_CLIENT_ID);
  u.searchParams.set("redirect_uri",`${process.env.URL}/.netlify/functions/auth-callback`);
  u.searchParams.set("scope","repo");
  u.searchParams.set("state",state);
  return Response.redirect(u,302);
};
