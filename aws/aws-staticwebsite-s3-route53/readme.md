# Configuring a static website using a custom Domain registered with Route 53 

Host a static website on Amazon S3. Route requests for domain (e.g. http://example.com and http://example.com) to be served from Amazon S3 content. 

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development/testing purposes.

1. Create a ".tfvars" file with values for the variables.
2. Update the local-backend folder path as indicated below:

```
terraform {
  backend "local" {
    path = "path-to-local-backend-folder/aws-staticwebsite-s3-route53/terraform.tfstate"
  }
}
```
3. Execute the scripts below as needed

```
terraform init
terraform plan -var-file="path-to-tfvar-file"
terraform apply -var-file="path-to-tfvar-file"
terraform destroy -var-file="path-to-tfvar-file"
```

