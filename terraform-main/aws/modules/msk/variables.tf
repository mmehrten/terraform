
variable "vpc-id" {
  description = "The VPC to create the cluster in"
  type        = string
}

variable "tls-certificate-arns" {
  description = "ARNs of the ACM certs to use for TLS"
  type        = list(string)
  default     = []
}

variable "msk-configuration" {
  description = "The MSK configuration file to use"
  type        = string
  default     = <<EOF
auto.create.topics.enable=true
log.retention.hours=8
default.replication.factor=3
min.insync.replicas=2
num.io.threads=8
num.network.threads=5
num.partitions=6
num.replica.fetchers=2
replica.lag.time.max.ms=30000
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
socket.send.buffer.bytes=102400
unclean.leader.election.enable=true
zookeeper.session.timeout.ms=18000
allow.everyone.if.no.acl.found=true
EOF
}

variable "kafka-version" {
  default     = "3.5.1"
  type        = string
  description = "Kafka cluster version"
}

variable "enable-vpc-connectivity" {
  type        = bool
  default     = false
  description = "Enable VPC connectivity for the cluster"
}

variable "security-group-ids" {
  type        = list(string)
  default     = []
  description = "Security group(s) to use with the cluster"
}

variable "instance-type" {
  description = "The instance type to use"
  type = string
  default = "kafka.m5.large"
}