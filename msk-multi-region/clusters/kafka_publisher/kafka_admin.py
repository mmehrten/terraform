from aws_lambda_powertools import Logger
from kafka.admin import (
    ACL,
    ACLOperation,
    ACLPermissionType,
    KafkaAdminClient,
    ResourcePattern,
    ResourceType,
)

from token_provider import MSKTokenProvider

logger = Logger()


def create_acl(
    bootstrap_servers,
    principal,
    region,
    resource="*",
    operation="READ",
    permission="ALLOW",
    resource_type="TOPIC",
    **kwargs,
):
    admin = KafkaAdminClient(
        bootstrap_servers=bootstrap_servers,
        security_protocol="SASL_SSL",
        sasl_mechanism="OAUTHBEARER",
        sasl_oauth_token_provider=MSKTokenProvider(region),
        request_timeout_ms=1000,
    )
    acl = ACL(
        principal=principal,
        host="*",
        operation=getattr(ACLOperation, operation, "READ"),
        permission_type=getattr(ACLPermissionType, permission, "ALLOW"),
        resource_pattern=ResourcePattern(
            getattr(ResourceType, resource_type, "TOPIC"), resource
        ),
    )
    acls_result = admin.create_acls([acl])
    print(acls_result)


def create_admin_principal(bootstrap_servers, principal, region):
    admin = KafkaAdminClient(
        bootstrap_servers=bootstrap_servers,
        security_protocol="SASL_SSL",
        sasl_mechanism="OAUTHBEARER",
        sasl_oauth_token_provider=MSKTokenProvider(region),
        request_timeout_ms=1000,
    )
    acls = [
        ACL(
            principal=principal,
            host="*",
            operation=ACLOperation.READ,
            permission_type=ACLPermissionType.ALLOW,
            resource_pattern=ResourcePattern(ResourceType.TOPIC, "*"),
        ),
        ACL(
            principal=principal,
            host="*",
            operation=ACLOperation.WRITE,
            permission_type=ACLPermissionType.ALLOW,
            resource_pattern=ResourcePattern(ResourceType.TOPIC, "*"),
        ),
        ACL(
            principal=principal,
            host="*",
            operation=ACLOperation.CREATE,
            permission_type=ACLPermissionType.ALLOW,
            resource_pattern=ResourcePattern(ResourceType.TOPIC, "*"),
        ),
        ACL(
            principal=principal,
            host="*",
            operation=ACLOperation.WRITE,
            permission_type=ACLPermissionType.ALLOW,
            resource_pattern=ResourcePattern(ResourceType.GROUP, "*"),
        ),
        ACL(
            principal=principal,
            host="*",
            operation=ACLOperation.READ,
            permission_type=ACLPermissionType.ALLOW,
            resource_pattern=ResourcePattern(ResourceType.GROUP, "*"),
        ),
    ]
    acls_result = admin.create_acls(acls)
    logger.info(acls_result)
    return acls_result


def create_east_west_tls_principals():
    create_admin_principal(
        "b-1.mskzwy2usgoveast1m.7nitq1.c2.kafka.us-gov-east-1.amazonaws.com:9098,b-2.mskzwy2usgoveast1m.7nitq1.c2.kafka.us-gov-east-1.amazonaws.com:9098,b-3.mskzwy2usgoveast1m.7nitq1.c2.kafka.us-gov-east-1.amazonaws.com:9098",
        "User:CN=msk-zwy2.us-gov-east-1.client",
        "us-gov-east-1",
    )
    create_admin_principal(
        "b-1.mskzwy2usgovwest1m.tntl4g.c2.kafka.us-gov-west-1.amazonaws.com:9098,b-2.mskzwy2usgovwest1m.tntl4g.c2.kafka.us-gov-west-1.amazonaws.com:9098,b-3.mskzwy2usgovwest1m.tntl4g.c2.kafka.us-gov-west-1.amazonaws.com:9098",
        "User:CN=msk-zwy2.us-gov-west-1.client",
        "us-gov-west-1",
    )
