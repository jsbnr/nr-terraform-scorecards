scorecardName        = "My TF Scorecard"
organizationId       = "xxxx-xxxx-xxxx-xxxx-xxxx"
scorecardDescription = "A scorecard created through terraform and graphql"

scorecardTags = {
  team           = ["OMM: Instrumentation Coverage"]
  rubric_version = ["v1.0.3"]
}

rules = [
  {
    name        = "APM Services Have Alerts Defined"
    description = "Check that APM services have alerts associated with them"
    query       = "SELECT if(latest(alertSeverity) != 'NOT_CONFIGURED', 1, 0) AS 'score' FROM Entity WHERE type = 'APM-APPLICATION' FACET id AS 'entityGuid' LIMIT MAX SINCE 1 day ago"
    accounts    = [6747798]
    tags = {
      rubric_version = ["v1.0.3"]
      envs           = ["prod", "dev"]
      use_case       = ["detect-and-resolve"]
    }
  },
  {
    name        = "APM Services Are Reporting "
    description = "Check that APM services have reported data recently"
    query       = "SELECT if(latest(reporting) = true, 1, 0) AS 'score' FROM Entity WHERE type = 'APM-APPLICATION' FACET id AS 'entityGuid' LIMIT MAX SINCE 1 day ago"
    accounts    = [6747798]
    tags = {
      rubric_version = ["v1.0.3"]
      envs           = ["prod", "dev"]
      use_case       = ["detect-and-resolve", "improve-quality"]
    }
  }
]