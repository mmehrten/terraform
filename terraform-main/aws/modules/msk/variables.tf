
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
allow.everyone.if.no.acl.found=false
EOF
}
