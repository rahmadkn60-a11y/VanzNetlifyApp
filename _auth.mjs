import crypto from "node:crypto";
const COOKIE="vanz_session";

function key(){return crypto.createHash("sha256").update(process.env.SESSION_SECRET||"").digest()}
function enc(x){return Buffer.from(x).toString("base64url")}
function dec(x){return Buffer.from(x,"base64url")}
export function seal(payload){
  const iv=crypto.randomBytes(12), c=crypto.createCipheriv("aes-256-gcm",key(),iv);
  const body=Buffer.concat([c.update(JSON.stringify(payload),"utf8"),c.final()]);
  return [iv,c.getAuthTag(),body].map(enc).join(".");
}
export function open(v){
  try{
    const [iv,tag,body]=v.split(".");
    const d=crypto.createDecipheriv("aes-256-gcm",key(),dec(iv));d.setAuthTag(dec(tag));
    return JSON.parse(Buffer.concat([d.update(dec(body)),d.final()]).toString());
  }catch{return null}
}
export function getSession(req){
  const c=req.headers.get("cookie")||"";
  const x=c.split(";").map(v=>v.trim()).find(v=>v.startsWith(COOKIE+"="));
  return x?open(decodeURIComponent(x.slice(COOKIE.length+1))):null;
}
export function setSession(s){
  return `${COOKIE}=${encodeURIComponent(seal(s))}; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=28800`;
}
