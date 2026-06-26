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
