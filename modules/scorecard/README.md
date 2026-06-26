# New Relic Scorecard Terraform Module

Provisions a New Relic Scorecard, its rules, and the rule-collection memberships using the
[`sullivtr/graphql`](https://registry.terraform.io/providers/sullivtr/graphql/latest/docs)
provider against NerdGraph. Drop this `modules/scorecard/` directory into any project to manage
scorecards as a module.

## Usage

The module declares the `graphql` provider as required but does **not** configure it — the calling
(root) module must configure the `graphql` provider and it is passed in implicitly:

```hcl
provider "graphql" {
  url = "https://api.newrelic.com/graphql"
  headers = {
    "API-Key" = var.NEW_RELIC_API_KEY
  }
}

module "scorecard" {
  source               = "./modules/scorecard"
  scorecardName        = "My Scorecard"
  organizationId       = "01b81830-fb4e-4ce9-b6af-4dc1908e83a3"
  scorecardDescription = "A scorecard created through terraform and graphql"

  rules = [
    {
      name        = "APM Services Have Alerts Defined"
      description = "Check that APM services have alerts associated with them"
      query       = "SELECT if(latest(alertSeverity) != 'NOT_CONFIGURED', 1, 0) AS 'score' FROM Entity WHERE type = 'APM-APPLICATION' FACET id AS 'entityGuid' LIMIT MAX SINCE 1 day ago"
      accounts    = [6747798]
    },
  ]
}
```

## Inputs

| Name                   | Type                                                                                                                   | Required | Description                                  |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------- | -------- | -------------------------------------------- |
| `scorecardName`        | `string`                                                                                                               | yes      | Scorecard name.                              |
| `organizationId`       | `string`                                                                                                               | yes      | Organization scope id for the scorecard/rules. |
| `scorecardDescription` | `string`                                                                                                               | yes      | Scorecard description.                       |
| `rules`                | `list(object({ name=string, query=string, accounts=list(number), description=optional(string,""), joinAccounts=optional(list(number),[]) }))` | no (`[]`) | Rules to create and attach. `name` must be unique. |

## Outputs

| Name            | Description                                       |
| --------------- | ------------------------------------------------- |
| `scorecard_id`  | The entity id of the created scorecard.           |
| `collection_id` | The scorecard's rule collection id.               |
| `rule_ids`      | Map of rule name => created rule entity id.       |

## Notes & caveats

- **File paths use `${path.module}`.** The `.gql` templates resolve relative to this module
  directory, so the module works regardless of the caller's working directory.
- **Membership is modeled per-rule.** `entityManagementAddCollectionMembers` is not idempotent, so
  each rule gets its own membership resource (keyed by rule name) rather than a single bulk add.
- **State is trusted from create.** Every resource sets `enable_remote_state_verification = false`
  with `compute_from_create = true`; the read queries are not executed during refresh.
- **Membership read pagination.** The membership `readQuery.gql` hits NerdGraph's cursor-paginated
  `collectionElements`, but the provider's `read_query` runs once and does not follow the cursor.
  This has no effect today (remote state verification is off). Before enabling verification on the
  membership resource, account for pagination — a rule collection spanning more than one page would
  read page 2+ memberships as absent, producing false drift and failing re-add attempts. Handle it
  with an external paginating read that walks `cursor` until `nextCursor` is empty.
