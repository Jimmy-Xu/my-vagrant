Full ssl certificate can be found here: https://trello.com/c/xCfLlQzX/21-ssl-for-hypersh

- Root CA Certificate – AddTrustExternalCARoot.crt
- Intermediate CA Certificate – COMODORSAAddTrustCA.crt
- Intermediate CA Certificate – COMODORSADomainValidationSecureServerCA.crt
- Your PositiveSSL Certificate – hyper.sh.crt

> Generate certificate chain

```
cat hyper.sh.crt COMODORSADomainValidationSecureServerCA.crt COMODORSAAddTrustCA.crt AddTrustExternalCARoot.crt > hyper.sh.chain.crt
```
