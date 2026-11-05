# Story → tests, worked through

Read this before generating specs.

Examples come from the Ether codebase; adapt names to your repo.

## The mapping

| Source artifact                       | Spec construct                                  |
|---------------------------------------|-------------------------------------------------|
| A story (tracker issue or brainstorm) | Tests in the endpoint or module file it exercises |
| An acceptance criterion               | One or more top-level `test` blocks             |
| Each distinct "then …" behaviour      | One `test`, one behaviour asserted              |
| The "given …" state                   | Inline `insert(...)` calls at the top of each test |
| A failure / edge "then"               | A `test` placed after all happy-path tests      |

## Worked example

Story:

> **As an** unpaid Viewer
> **I want** to see which Skill Leaderboard filters are paid
> **So that** I know what upgrading unlocks
>
> - Given an anonymous caller, when they load skill leaderboards, then the
>   Competition and Season filters are unlocked and populated.
> - Given an anonymous caller, then the Team filter is locked with no
>   options and nothing selected.
> - Given an anonymous caller who sends `team_ids`, then the results ignore
>   the team filter.

Goes into the endpoint file `test/ether_web/controllers/skills_leaderboard_controller/list_v3_test.exs`:

1. `test "an unpaid viewer sees the competition filter unlocked and populated"`
2. `test "an unpaid viewer sees the season filter unlocked and populated"`
3. `test "an unpaid viewer sees the team filter locked with no options"`
4. `test "a team filter sent by an unpaid viewer does not narrow the results"` (sad path, last)

Each test inserts its own leagues, teams and rankings, then calls the route
through the router. None is skipped: each stays red until implemented.

## Happy-path checklist

- The nominal case.
- Each boundary the domain allows (none, one, many; first/last page).
- Each distinct success outcome the story's "so that" implies.
- Each access level from the access rules in `.claude/project.md`, where
  the endpoint is access-aware.
- Each derived value the feature exposes.

## Sad-path checklist

- Each validation rule (missing, malformed, out of range params).
- Not found.
- Unauthorized: wrong pipeline, missing token or API key.
- Restricted data requested by a caller the access rules in
  `.claude/project.md` deny.

## Stop point

After writing the files, stop and present them. No implementation until the
user approves.
