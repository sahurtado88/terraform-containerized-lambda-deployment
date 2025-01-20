# Containerized AWS Lambda Deployments with Terraform

Terraform version: 1.1.6

## Getting started

1. Copy, populate, and source `env.sh`

    ```
    cp env.sh.template env.sh
    nano env.sh
    source env.sh

    cp aws_lambda_functions/profile_faker/env.sh.template aws_lambda_functions/profile_faker/env.sh
    nano aws_lambda_functions/profile_faker/env.sh
    source aws_lambda_functions/profile_faker/env.sh
    ```

2. Build and push docker image

   ```
   cd aws_lambda_functions/profile_faker
   make docker/push TAG=dev
   cd -
   ```

3. Run terraform

   ```
   terraform init
   terraform plan
   terraform apply
   ```

__________________________________________________________________

Pre-requisites
This code is split into two parts,

Infrastructure for Codepipeline Deployment. ie, code under the path terraform/
Uploading the Lambda code to CodeCommit Repository. ie, lambda code on path lambda_bootstrap/
To achieve this, follow the pre-requisites steps below

Install Terraform : link
Install AWS CLI : link
Configure AWS CLI with AWS Account do aws sts get-caller-identity for validation) : link
Create a S3 Bucket in us-east-1. This bucket will be used to store the terraform state file. Note the bucket arn as it will be used in the steps below.
Folder Structure
.
|-- img
|   |-- codepipeline-output.png
|   `-- codepipeline-using-terraform.png
|-- lambda_bootstrap
|   |-- lambda
|   |   |-- Dockerfile
|   |   |-- aws-lambda-url.py
|   |   |-- docker-test.sh
|   |   `-- requirements.txt
|   |-- main.tf
|   |-- outputs.tf
|   |-- providers.tf
|   |-- terraform.tfvars
|   |-- variables.tf
|   `-- versions.tf
|-- terraform
|   |-- modules
|   |   |-- codecommit
|   |   |   |-- main.tf
|   |   |   |-- outputs.tf
|   |   |   `-- variables.tf
|   |   |-- codepipeline
|   |   |   |-- templates
|   |   |   |   |-- buildspec_build.yml
|   |   |   |   `-- buildspec_deploy.yml
|   |   |   |-- main.tf
|   |   |   |-- outputs.tf
|   |   |   |-- roles.tf
|   |   |   `-- variables.tf
|   |   `-- ecr
|   |       |-- main.tf
|   |       |-- outputs.tf
|   |       `-- variables.tf
|   |-- main.tf
|   |-- outputs.tf
|   |-- providers.tf
|   |-- terraform.tfvars
|   |-- variables.tf
|   `-- versions.tf
`-- README.md
Provision Infrastructure
Deploying the Infrastructure:

Navigate to the directory cd create-codepipeline-using-terraform/terraform
Open the file terraform.tfvars and change the ORG_NAME, TEAM_NAME and PROJECT_ID. Example file below,
org_name   = "cloudplatform"
team_name  = "devteam"
project_id = "deployment123"
region     = "us-east-1"
env = {
  "dev" = "dev"
  "qa"  = "qa"
}
codebuild_compute_type = "BUILD_GENERAL1_MEDIUM"
codebuild_image        = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
codebuild_type         = "LINUX_CONTAINER"
codecommit_branch      = "master"

Change the BUCKET_NAME in the file codepipeline-for-lambda-using-terraform/terraform/providers.tf with the bucket you created in pre-requisites. Use the bucket name, not the ARN
Change the BUCKET_NAME in the file codepipeline-for-lambda-using-terraform/lambda_bootstrap/providers.tf with the bucket you created in pre-requisites. Use the bucket name, not the ARN
Change the BUCKET_NAME in the file codepipeline-for-lambda-using-terraform/terraform/modules/codepipeline/roles.tf with the bucket you created in pre-requisites. Use the Bucket ARN here.
You are all set. Let's run the code

Navigate to the directory cd create-codepipeline-using-terraform/terraform

Run terraform init

Run terraform validate

Run terraform plan and review the output in terminal

Run terraform apply and review the output in terminal and when ready, type yes and hit enter

You should be seeing a output similar to this:

Apply complete! Resources: 11 added, 0 changed, 0 destroyed.

Outputs:

codecommit = "https://git-codecommit.us-east-1.amazonaws.com/v1/repos/cloudcomps_devops_tf123_code_repo"

codepipeline = "arn:aws:codepipeline:us-east-1:<account#>:cloudcomps_devops_tf123_dev_pipeline"

ecrrepo = "<account#>.dkr.ecr.us-east-1.amazonaws.com/cloudcomps_devops_tf123_docker_repo"
Great, we have completed provisioning the Infrastructure. Now let's push the Lambda code to codecommit which will trigger codepipeline to deploy the lambda code.

Run cd.. into the Root folder. From the output above, copy the code commit repository link.
Run git clone <codecommit repo link>
If credentials are required, Generate a CodeCommit credentials from aws console for the IAM user that you logged in:
Select Users from IAM (Access Management Tab)
Select the user that you want to provide CodeCommit Access to.
Select Security Credentials from the User information panel.
Scroll down and you should be seeing a subsection HTTPS Git credentials for AWS CodeCommit
Click on Generate Credentials, you should be prompted with Download credentails in cvs file.
Once git clone and git authentication is successful, cd to cloned directory. This directoy will be empty as we haven't pushed the code yet.
Copy Lambda application code from lambda_bootstrap folder to git repo by running cp -R lambda_bootstrap codecommitrepo/ . For simplicity, I am referring the cloned repo as codecommitrepo.
After this cd codecommitrepo and do a ls, the repo should look like below,

(master) $ ls
lambda_bootstrap
Push the changes to git repo by running git add. && git commit -m "Initial Commit" && git push
Thats it!, you can now navigate to AWS Codepipeline from aws console and check the pipeline status.
If everything goes well, you should be seeing an output simillar to this: codepipeline-output