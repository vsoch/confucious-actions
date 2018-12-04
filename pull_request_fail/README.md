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


## Continuous Integration

And don't forget to turn on [CircleCI Github Checks](https://circleci.com/blog/see-the-status-of-your-circleci-workflows-in-github/)
if you use CircleCI, or follow steps to use [TravisCI](https://blog.travis-ci.com/2018-05-07-announcing-support-for-github-checks-api-on-travis-ci-com).


Since Github actions (running) repositories are still private (it's in beta) I'll share with you the CircleCI
configuration that I used to get an "always fail" pull request.

```yaml

# This "test" on Circle will always fail :)

version: 2
jobs:
  build:
    docker:
      - image: circleci/python:3.6.1
    working_directory: ~/repo
    steps:
      - checkout

      # Download and cache dependencies
      - restore_cache:
          keys:
          - v1-dependencies-

      - run:
          name: Always fail
          command: |
            exit 1; 

```

You could change the exit code to 0 for an "always pass" pull request, or
probably just leave it all out together :) This is fun! 
What other bots do you want to see next?
