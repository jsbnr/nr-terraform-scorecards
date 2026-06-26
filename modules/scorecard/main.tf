resource "graphql_mutation" "scorecard" {
  mutation_variables = {
    name : var.scorecardName
    organizationId : var.organizationId
    desc : var.scorecardDescription
    tags : jsonencode([for k, v in var.scorecardTags : { key = k, values = v }])
  }
  compute_mutation_keys = {
    "id"           = "entityManagementCreateScorecard.entity.id"       # The id from the create is used for update, read, destroy
    "collectionId" = "entityManagementCreateScorecard.entity.rules.id" # Collection id used to attach rules
  }
  enable_remote_state_verification = false
  compute_from_create              = true
  create_mutation                  = file("${path.module}/graphQL/scorecard/createMutation.gql")
  update_mutation                  = file("${path.module}/graphQL/scorecard/updateMutation.gql")
  delete_mutation                  = file("${path.module}/graphQL/scorecard/deleteMutation.gql")
  read_query                       = file("${path.module}/graphQL/scorecard/readQuery.gql")
}

# Create each rule defined in var.rules. Keyed by rule name (names must be unique).
resource "graphql_mutation" "rule" {
  for_each = { for r in var.rules : r.name => r }

  mutation_variables = {
    name           = each.value.name
    description    = each.value.description
    query          = each.value.query
    accounts       = jsonencode(each.value.accounts)     # interpreted as a JSON array of ints
    joinAccounts   = jsonencode(each.value.joinAccounts) # interpreted as a JSON array of ints
    organizationId = var.organizationId
    tags           = jsonencode([for k, v in each.value.tags : { key = k, values = v }])
  }
  compute_mutation_keys = {
    "id" = "entityManagementCreateScorecardRule.entity.id"
  }
  enable_remote_state_verification = false
  compute_from_create              = true
  create_mutation                  = file("${path.module}/graphQL/rule/createMutation.gql")
  update_mutation                  = file("${path.module}/graphQL/rule/updateMutation.gql")
  delete_mutation                  = file("${path.module}/graphQL/rule/deleteMutation.gql")
  read_query                       = file("${path.module}/graphQL/rule/readQuery.gql")
}

# Attach each created rule to the scorecard's rule collection.
# Modeled per-rule (one membership per rule) because entityManagementAddCollectionMembers is NOT
# idempotent: re-adding a rule that already belongs to the collection fails. A bulk add-all would
# re-add unchanged rules whenever any single rule's id changed (e.g. a rename).
resource "graphql_mutation" "scorecard_rule_membership" {
  for_each = graphql_mutation.rule

  mutation_variables = {
    collectionId = graphql_mutation.scorecard.computed_read_operation_variables.collectionId
    rules        = jsonencode([each.value.computed_read_operation_variables.id])
  }
  # The add response carries no ids, so supply delete vars directly for a clean destroy.
  delete_mutation_variables = {
    collectionId = graphql_mutation.scorecard.computed_read_operation_variables.collectionId
    rules        = jsonencode([each.value.computed_read_operation_variables.id])
  }
  # The read query needs the collection id; supply it explicitly.
  read_query_variables = {
    rulesId = graphql_mutation.scorecard.computed_read_operation_variables.collectionId
  }
  compute_mutation_keys = {
    "result" = "entityManagementAddCollectionMembers"
  }
  enable_remote_state_verification = false
  compute_from_create              = true
  create_mutation                  = file("${path.module}/graphQL/membership/createMutation.gql")
  update_mutation                  = file("${path.module}/graphQL/membership/updateMutation.gql")
  delete_mutation                  = file("${path.module}/graphQL/membership/deleteMutation.gql")
  read_query                       = file("${path.module}/graphQL/membership/readQuery.gql")
}
