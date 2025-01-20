resource "aws_ecr_repository" "ecr_repo" {
    name = "${var.general_namespace}_repo"
    image_tag_mutability = "MUTABLE"
    tags = {
        Name = var.env_namespace
    }
  
}