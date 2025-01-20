locals {
  projects  = ["build", "deploy"]
}
resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "${var.s3_bucket_namespace}-codepipeline-bucket"
}

/* resource "aws_s3_bucket_acl" "codepipeline_bucket_acl" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  acl    = "private"
} */

resource "aws_codebuild_project" "project" {
    count           = length(local.projects)
    name            = "${var.env_namespace}_${local.projects[count.index]}"
    build_timeout   = "5" 
    service_role    = aws_iam_role.lambda_codebuild_role.arn
    artifacts {
        type = "CODEPIPELINE"
    }
    environment {
      compute_type                = var.codebuild_compute_type
      image                       = var.codebuild_image
      type                        = var.codebuild_type
      #compute_type               = "BUILD_GENERAL1_MEDIUM"
      #image                      = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
      #type                       = "LINUX_CONTAINER"
      image_pull_credentials_type = "CODEBUILD"
      privileged_mode             = true

      dynamic "environment_variable" {
        for_each = var.build_args
        content {
          name  = environment_variable.value.name
          value = environment_variable.value.value
        }
      }
    }
    source {
        type      = "CODEPIPELINE"
        buildspec = file("${path.module}/templates/buildspec_${local.projects[count.index]}.yml")
        #buildspec = file("${path.module}/stage1-buildspec.yml")
    }

    source_version = "main"

    tags = {
        env = var.env_namespace
    }
}

data "aws_codestarconnections_connection" "githubconnection" {
  name          = "sahurtadoconn"
}
resource "aws_codepipeline" "codepipeline" {
  name     = "${var.env_namespace}_pipeline"
  role_arn = aws_iam_role.lambda_codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name     = "Source"
      category = "Source"
      owner    = "AWS"
      provider = "CodeStarSourceConnection"
      version  = "1"
      output_artifacts = [
      "source_output"]

      configuration = {
        BranchName      = var.codecommit_branch
        ConnectionArn    = data.aws_codestarconnections_connection.githubconnection.arn
        FullRepositoryId = "sahurtado88/terraform-containerized-lambda-deployment"
      }
   }
  }

  stage {
    name = "Build"

    action {
      name     = "Docker_Build"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      input_artifacts = [
      "source_output"]
      version = "1"

      configuration = {
        ProjectName = aws_codebuild_project.project[0].name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name     = "Deploy_Docker"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      input_artifacts = [
      "source_output"]
      version = "1"

      configuration = {
        ProjectName = aws_codebuild_project.project[1].name
      }
    }
  }
}