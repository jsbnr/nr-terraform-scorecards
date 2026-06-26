# New Relic Terraform Scorecards
This example project demontrates how you can use a [Terraform GraphQL provider](https://registry.terraform.io/providers/sullivtr/graphql/latest/docs) to provision New Relic Scorecards.

## Project layout
The reusable scorecard logic lives in the [`modules/scorecard/`](./modules/scorecard/) module — drop
that directory into any project to manage scorecards. The repo root is a working **example** that
configures the `newrelic`/`graphql` providers, supplies credentials, and calls the module:

```hcl
module "scorecard" {
  source               = "./modules/scorecard"
  scorecardName        = var.scorecardName
  organizationId       = var.organizationId
  scorecardDescription = var.scorecardDescription
  rules                = var.rules
}
```

See [`modules/scorecard/README.md`](./modules/scorecard/README.md) for the module's inputs, outputs,
and caveats. Edit [`terraform.tfvars`](./terraform.tfvars) to change the scorecard and its rules.

## Installation
Make sure terraform is installed. I recommend [tfenv](https://github.com/tfutils/tfenv) for managing your terraform binaries.

Run terraform how you usually do, or use the helper script to run terraform with the correct vars:  Update the `runtf.sh.sample` file with your credentials and account details and rename it `runtf.sh`. 

> **Important do not commit this new file to git!** (It should be ignored in `.gitignore` already)


## Initialisation
Use the `runtf.sh` helper script where ever you would normally run `terraform`. It simply wraps the terraform with some environment variables that make it easier to switch between projects.

First initialise terraform:
```
./runtf.sh init
```

Now apply the changes:
```
./runtf.sh apply
```

## State storage
This demo does not include remote state storage. State will be stored locally.

## A note on collection pagination
The membership read query (`modules/scorecard/graphQL/membership/readQuery.gql`) hits NerdGraph's
`actor.entityManagement.collectionElements`, which is **cursor-paginated**: a
single request returns one page of `items` plus a `nextCursor`, and you only get
subsequent pages by re-issuing the query with `cursor: "<nextCursor>"` until
`nextCursor` comes back empty.

The `sullivtr/graphql` provider's `read_query` (on a `graphql_mutation` resource)
runs **once and does not follow the cursor**, so it would only ever see the first
page. (The provider's `usePagination` option exists only on the `graphql_query`
*data source* and expects Relay-style `pageInfo { hasNextPage endCursor }`, which
does not match NerdGraph's flat `nextCursor`/`cursor` model.) For that reason the
`nextCursor` field has been removed from the query — nothing consumed it.

Today this has **no effect**: every resource sets
`enable_remote_state_verification = false` (with `compute_from_create = true`), so
the membership read query is never executed during refresh — state is trusted
from the create response.

> **Warning:** Before enabling `enable_remote_state_verification` on the
> membership resource, account for pagination. A scorecard whose rule collection
> spans more than one page would have its page 2+ memberships read as *absent*,
> producing false drift and re-add attempts that fail because
> `entityManagementAddCollectionMembers` is not idempotent. Handle this with an
> external paginating read (one that walks `cursor` until `nextCursor` is empty)
> rather than the single-shot `read_query`.


