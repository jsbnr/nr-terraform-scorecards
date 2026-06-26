output "scorecard_id" {
  description = "The entity id of the created scorecard."
  value       = graphql_mutation.scorecard.computed_read_operation_variables.id
}

output "collection_id" {
  description = "The rule collection id of the scorecard (rules are attached here)."
  value       = graphql_mutation.scorecard.computed_read_operation_variables.collectionId
}

output "rule_ids" {
  description = "Map of rule name => created rule entity id."
  value       = { for k, r in graphql_mutation.rule : k => r.computed_read_operation_variables.id }
}
