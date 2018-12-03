# Confuscious Pull Request Fail Action

Who has better wisdom than Confuscious?

Here is an example of what to put in your `.github/main.workflow` file to
trigger the action.

```
workflow "confuscious pull request fail" {
  on = "pull_request"
  resolves = ["post message on fail"]
}

action "post message on fail" {
  uses = "vsoch/confucious-actions/pull_request_fail@master"
  secrets = ["GITHUB_TOKEN"]
}
```
