from aws_msk_iam_sasl_signer import MSKAuthTokenProvider


class MSKTokenProvider:
    def __init__(self, region):
        self.region = region

    def token(self):
        token, _ = MSKAuthTokenProvider.generate_auth_token(self.region)
        return token
