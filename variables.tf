# Credentials / provider inputs (supplied via runtf.sh environment variables).
variable "accountId" { type = string }
variable "NEW_RELIC_API_KEY" { type = string }

# Scorecard inputs, fed into the ./modules/scorecard module (see terraform.tfvars).
variable "scorecardName" { type = string }
variable "organizationId" { type = string }
variable "scorecardDescription" { type = string }

variable "scorecardTags" {
  type    = map(list(string))
  default = {}
}

variable "rules" {
  type = list(object({
    name         = string
    query        = string
    accounts     = list(number)
    description  = optional(string, "")
    joinAccounts = optional(list(number), [])
    tags         = optional(map(list(string)), {})
  }))
  default = []
}
