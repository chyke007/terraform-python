provider "aws" {
    region = vars.aws_region

    default_tags {
        tags = {
            created-by = "terraform"
            author = "chibuike"
        }
    }
}
