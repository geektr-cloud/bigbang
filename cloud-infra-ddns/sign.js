const crypto = require("crypto");
const fs = require("fs");

const privateKeyPem = fs.readFileSync("../.secret/ddns-private.pem", "utf8");
const publicKeyPem = fs.readFileSync("../.secret/ddns-public.pem", "utf8");

const privateKey = crypto.createPrivateKey({
  key: privateKeyPem,
  format: "pem",
  type: "pkcs8",
});
const publicKey = crypto.createPublicKey({
  key: publicKeyPem,
  format: "pem",
  type: "spki",
});

const data = process.argv[2];
if (!data) {
  console.log("Usage: node sign.js <data>");
  process.exit(1);
}
console.log("Data:", data);

const sign = crypto.createSign("SHA256");
sign.update(data);
const signature = sign.sign(privateKey).toString("base64url");
console.log("Signature:", signature);

const verify = crypto.createVerify("SHA256");
verify.update(data);
const isVerified = verify.verify(publicKey, signature, "base64url");
console.log("Is verified:", isVerified);
