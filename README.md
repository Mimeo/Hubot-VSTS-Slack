# hubot-vsts-slack

A Hubot script for Visual Studio Team Services integration tailored for Slack

See [`src/vsts-slack.coffee`](src/vsts-slack.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-vsts-slack --save`

Then add **hubot-vsts-slack** to your `external-scripts.json`:

```json
[
  "hubot-vsts-slack"
]
```

## Sample Interaction

```
user1>> hubot vsts projects
hubot>> Retrieving list of VSTS projects...
hubot>> Here's what I found:  `ProjectX`, `Visual Active Gibb++`,...
```

```
user1>> hubot vsts ProjectX pullrequests
hubot>> Hold on, checking for active PRs in `ProjectX` ...
hubot>> Pull Request #1337 in ProjectRepo "This is my pull request title" http://contoso.visualstudio.com/DefaultCollection/projectx/_git/ProjectRepo/pullrequest/1337
```
