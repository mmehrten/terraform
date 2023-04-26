
resource "aws_ecs_cluster" "main" {
  name = replace("${var.base-name}.ecs.${var.name}", ".", "_")
}

output "id" {
  value = aws_ecs_cluster.main.id
}

output "arn" {
  value = aws_ecs_cluster.main.arn
}
