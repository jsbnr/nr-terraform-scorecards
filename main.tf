terraform {
  required_version = "~> 1.15.7"
  required_providers {
    newrelic = {
      source  = "newrelic/newrelic"
      version = "3.93.2"
    }
    graphql = {
      source  = "sullivtr/graphql"
      version = "2.6.1"
    }
  }
}

provider "newrelic" {
  region = "US"
}

provider "graphql" {
  url = "https://api.newrelic.com/graphql"
  headers = {
    "API-Key" = var.NEW_RELIC_API_KEY
  }
}

# Provision the scorecard, its rules, and the rule-collection memberships via the
# reusable module. The graphql provider configured above is passed implicitly.
module "scorecard" {
  source               = "./modules/scorecard"
  scorecardName        = var.scorecardName
  organizationId       = var.organizationId
  scorecardDescription = var.scorecardDescription
  scorecardTags        = var.scorecardTags
  rules                = var.rules
}


output "scorecard_id" {
  value = module.scorecard.scorecard_id
}
