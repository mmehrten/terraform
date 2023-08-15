import boto3
import os

# Load the ACM certificates for SSL to use on startup
acm = boto3.client('acm')
certs = acm.export_certificate(
    CertificateArn=os.environ["AWS_ACM_CERT_ARN"],
    Passphrase=os.environ["AWS_ACM_CERT_PASS"]
)
for k in ["Certificate", "PrivateKey", "CertificateChain"]:
    with open(k, "w") as f:
        f.write(certs[k])
