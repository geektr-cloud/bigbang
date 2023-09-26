const AliPopCore = require("@alicloud/pop-core");
const crypto = require("crypto");

const RegionId = "cn-hangzhou";

const PublicKey = crypto.createPublicKey({
  key: process.env.PUBLIC_KEY,
  format: "pem",
  type: "spki",
});

module.exports.handler = async function (req, resp, context) {
  const Client = new AliPopCore({
    endpoint: "https://alidns.aliyuncs.com",
    apiVersion: "2015-01-09",
    accessKeyId: context.credentials.accessKeyId,
    accessKeySecret: context.credentials.accessKeySecret,
    securityToken: context.credentials.securityToken,
  });

  function AliApiCall(action, params) {
    return Client.request(action, params, { method: "POST" });
  }

  async function GetARecord(domain) {
    const { DomainRecords } = await AliApiCall("DescribeSubDomainRecords", {
      RegionId,
      SubDomain: domain,
    });
    return DomainRecords.Record.filter(
      (r) => r.Status === "ENABLE" && r.Type === "A"
    )[0];
  }

  const [Signature, PrimaryDomain, SubDomain, ClientIP] = req.path
    .split("/")
    .filter((i) => i);

  if (!SubDomain)
    return resp.send(
      "ERROR: Parameters missing, expected: <Signature>/<PrimaryDomain>/<SubDomain>/[ClientIP]"
    );

  const FullDomain = `${SubDomain}.${PrimaryDomain}`;
  const Sign = crypto.createVerify("SHA256");
  Sign.update(FullDomain);
  if (!Sign.verify(PublicKey, Signature, "base64url"))
    return resp.send("ERROR: Signature not match");

  const Record = await GetARecord(FullDomain);

  const CurrentIP = Record && Record.Value;
  const TargetIP = ClientIP || req.clientIP;
  if (TargetIP === CurrentIP) return resp.send("IGNORED: IP not changed");

  if (Record) {
    resp.send(
      JSON.stringify(
        await AliApiCall("UpdateDomainRecord", {
          RegionId,
          RecordId: Record.RecordId,
          DomainName: PrimaryDomain,
          RR: SubDomain,
          Type: "A",
          Value: TargetIP,
        })
      )
    );
  } else {
    resp.send(
      JSON.stringify(
        await AliApiCall("AddDomainRecord", {
          RegionId,
          DomainName: PrimaryDomain,
          RR: SubDomain,
          Type: "A",
          Value: TargetIP,
        })
      )
    );
  }
};
