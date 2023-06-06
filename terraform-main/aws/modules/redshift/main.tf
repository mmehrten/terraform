/*
* Create a Redshift culster.
*/

resource "aws_security_group" "main" {
  name        = "${var.base-name}.sg.redshift"
  description = "Security group for Redshift clusters."
  vpc_id      = var.vpc-id

  ingress {
    description      = "Allow all inbound connections"
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
  }

  egress {
    description      = "Allow all outbound connections"
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
  }

  tags = {
    Name = "${var.base-name}.sg.redshift"
  }
}

data "aws_subnets" "main" {
  filter {
    name   = "vpc-id"
    values = [var.vpc-id]
  }
  filter {
    name   = "map-public-ip-on-launch"
    values = [false]
  }
}

resource "aws_redshift_subnet_group" "main" {
  name       = "redshift-subnet-group"
  subnet_ids = data.aws_subnets.main.ids
}


resource "aws_iam_role" "main" {
  name               = "${var.app-shorthand-name}.iam.role.redshift"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "redshift.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}


resource "aws_iam_role_policy" "main" {
  name   = "${var.app-shorthand-name}.iam.role.redshift"
  role   = aws_iam_role.main.id
  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "glue:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "kms:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "kinesis:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "lambda:InvokeFunction"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:Get*",
                "secretsmanager:List*",
                "secretsmanager:Describe*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action":  [
                "kinesis:DescribeStreamSummary",
                "kinesis:GetShardIterator",
                "kinesis:GetRecords",
                "kinesis:DescribeStream",
                "kinesis:ListStreams",
                "kinesis:ListShards"
            ],
            "Resource": "*"
        }
   ]
}
EOF
}

resource "aws_kms_key" "main" {
  description             = "Redshift KMS key."
  deletion_window_in_days = 30
  enable_key_rotation     = "true"
  tags = {
    "Name" = "${var.base-name}.kms.redshift"
  }
}

resource "aws_kms_alias" "alias" {
  name          = replace("alias/${var.base-name}.kms.redshift", ".", "_")
  target_key_id = aws_kms_key.main.key_id
}

resource "aws_redshift_cluster" "main" {
  cluster_identifier = "redshift-cluster"
  database_name      = var.database-name
  master_username    = "admin"
  master_password    = var.master-password
  node_type          = "ra3.xlplus"
  cluster_type       = "single-node"

  vpc_security_group_ids    = [aws_security_group.main.id]
  cluster_subnet_group_name = aws_redshift_subnet_group.main.id
  skip_final_snapshot       = true
  publicly_accessible       = false
  encrypted                 = true
  enhanced_vpc_routing      = true
  kms_key_id                = aws_kms_key.main.arn
  iam_roles                 = [aws_iam_role.main.arn]
  logging {
    enable               = true
    log_destination_type = "cloudwatch"
    log_exports          = ["connectionlog", "userlog", "useractivitylog"]
  }
}


/*
--drop schema spectrum
create external schema spectrum 
from data catalog 
database 'dev' 
iam_role 'arn:aws-us-gov:iam::053633994311:role/core-zwy2.us-gov-west-1.iam.role.redshift'
create external database if not exists;

--drop table spectrum.ev
create external table spectrum.ev(
  station_name VARCHAR,
  address_1 VARCHAR,
  address_2 VARCHAR,
  city VARCHAR,
  state VARCHAR,
  postal_code VARCHAR,
  num_ports integer,
  pricing_policy VARCHAR,
  usage_access VARCHAR,
  category VARCHAR,
  subcategory VARCHAR,
  port_1_type VARCHAR,
  voltage VARCHAR,
  port_2_type VARCHAR,
  georeference VARCHAR,
  pricing VARCHAR,
  power_select VARCHAR
)
row format delimited
fields terminated by ','
stored as textfile
location 's3://core-zwy2.us-gov-west-1.s3.analytics/bronze/ev/'
--table properties ('numRows'='172000');


--drop table spectrum.ev
create table public.ev(
  station_name VARCHAR,
  address_1 VARCHAR,
  address_2 VARCHAR,
  city VARCHAR,
  state VARCHAR,
  postal_code VARCHAR,
  num_ports integer,
  pricing_policy VARCHAR,
  usage_access VARCHAR,
  category VARCHAR,
  subcategory VARCHAR,
  port_1_type VARCHAR,
  voltage VARCHAR,
  port_2_type VARCHAR,
  georeference VARCHAR,
  pricing VARCHAR,
  power_select VARCHAR
)

--drop schema spectrum
COPY public.ev FROM 's3://core-zwy2.us-gov-west-1.s3.analytics/bronze/ev/'
iam_role 'arn:aws-us-gov:iam::053633994311:role/core-zwy2.us-gov-west-1.iam.role.redshift'
delimiter ',';

CREATE EXTERNAL SCHEMA kds
FROM KINESIS
IAM_ROLE 'arn:aws-us-gov:iam::053633994311:role/core-zwy2.us-gov-west-1.iam.role.redshift' ;


CREATE MATERIALIZED VIEW my_topic_materialized_view DISTKEY(6) sortkey(1) AUTO REFRESH NO AS
SELECT * FROM kds.demo_stream

REFRESH MATERIALIZED VIEW my_topic_materialized_view;

SELECT COUNT(*) FROM my_topic_materialized_view



create table name (rdata SUPER) diststyle AUTO

COPY name FROM 's3://core-zwy2.us-gov-west-1.s3.analytics'
iam_role 'arn:aws-us-gov:iam::053633994311:role/core-zwy2.us-gov-west-1.iam.role.redshift'
FORMAT JSON 'noshred';

insert into name (SELECT * FROM name 
                  UNION ALL select * FROm name 
                  UNION ALL select * FROm name 
                  UNION ALL select * FROm name 
                  UNION ALL select * FROm name 
                  UNION ALL select * FROm name 
                  UNION ALL select * FROm name 
                  UNION ALL select * FROm name 
                  UNION ALL select * FROm name 
                  UNION ALL select * FROm name 
                  UNION ALL select * FROm name 
                  UNION ALL select * FROm name 
                  UNION ALL select * FROm name 
                  UNION ALL select * FROm name 
                  UNION ALL select * FROm name 
                  UNION ALL select * FROm name )
*/
