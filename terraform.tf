terraform {
  cloud {
    organization = "star-destroyers"
    hostname = "app.staging.terraform.io"

    workspaces {
      name = "serverless-api"
    }
  }
}
