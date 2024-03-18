from aws_lambda_powertools import Logger
from kafka.admin import (
    ACL,
    ACLOperation,
    ACLPermissionType,
    KafkaAdminClient,
    ResourcePattern,
    ResourceType,
)
from kafka.admin import KafkaAdminClient, ConfigResourceType, ConfigResource

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

def update_advertised_listeners():
    bs = ",".join((
        "b-1.mskctzwy2useast1mskcl.j0gvut.c19.kafka.us-east-1.amazonaws.com:9001",
        "b-2.mskctzwy2useast1mskcl.j0gvut.c19.kafka.us-east-1.amazonaws.com:9002",
        "b-3.mskctzwy2useast1mskcl.j0gvut.c19.kafka.us-east-1.amazonaws.com:9003"
    ))
    admin = KafkaAdminClient(
        bootstrap_servers=bs,
        security_protocol="SASL_SSL",
        sasl_mechanism="OAUTHBEARER",
        sasl_oauth_token_provider=MSKTokenProvider(os.environ['AWS_REGION']),
        request_timeout_ms=1000,
        ssl_check_hostname=False
    )
    for i in admin.describe_configs(
            [
                ConfigResource(ConfigResourceType.BROKER, 1),
                ConfigResource(ConfigResourceType.BROKER, 2),
                ConfigResource(ConfigResourceType.BROKER, 3)
            ]
    ):
        print(str(i.__dict__)[0:200])
        for j in i.resources:
            for k in j:
                if isinstance(k, list):
                    for l in k: 
                        print(l)
                else:
                    print(k)
    for broker_id in [1, 2, 3]:
        port = f"900{broker_id}"
        listeners = ",".join((
             f"CLIENT_SASL_SCRAM://b-{broker_id}.mskctzwy2useast1mskcl.j0gvut.c19.kafka.us-east-1.amazonaws.com:9096",
             f"CLIENT_SASL_SCRAM_VPCE://b-{broker_id}.scram.mskctzwy2useast1mskcl.j0gvut.c19.kafka.us-east-1.amazonaws.com:14001",
             f"CLIENT_IAM://b-{broker_id}.mskctzwy2useast1mskcl.j0gvut.c19.kafka.us-east-1.amazonaws.com:{port}",
             f"CLIENT_IAM_VPCE://b-{broker_id}.iam.mskctzwy2useast1mskcl.j0gvut.c19.kafka.us-east-1.amazonaws.com:14001",
             f"CLIENT_SECURE://b-{broker_id}.mskctzwy2useast1mskcl.j0gvut.c19.kafka.us-east-1.amazonaws.com:9094",
             f"CLIENT_SECURE_VPCE://b-{broker_id}.tls.mskctzwy2useast1mskcl.j0gvut.c19.kafka.us-east-1.amazonaws.com:14001",
             f"REPLICATION://b-{broker_id}-internal.mskctzwy2useast1mskcl.j0gvut.c19.kafka.us-east-1.amazonaws.com:9093",
             f"REPLICATION_SECURE://b-{broker_id}-internal.mskctzwy2useast1mskcl.j0gvut.c19.kafka.us-east-1.amazonaws.com:9095"
        ))
        res = ConfigResource(
            ConfigResourceType.BROKER, 
            broker_id, 
            {"advertised.listeners":listeners}
        )
        resp = admin.alter_configs([res])
        print(resp)
