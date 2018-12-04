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

And don't forget to turn on [CircleCI Github Checks](https://circleci.com/blog/see-the-status-of-your-circleci-workflows-in-github/)
if you use CircleCI, or follow steps to use [TravisCI](https://blog.travis-ci.com/2018-05-07-announcing-support-for-github-checks-api-on-travis-ci-com).
