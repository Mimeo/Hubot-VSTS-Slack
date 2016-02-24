# Description
#   A Hubot script for Visual Studio Team Services integration tailored for Slack
#
# Configuration:
#   HUBOT_VSTS_API_TOKEN
#   HUBOT_VSTS_API_URL
#
# Commands:
#   hubot vsts projects - Gets the list of projects available in Visual Studio Team Services
#   hubot vsts <project> pullrequests - Gets the active pull requests for the specified Visual Studio Team Services project
#
# Author:
#   Nithin Shenoy <nshenoy@mimeo.com>

vstsToken = 'Basic ' + new Buffer(":#{process.env.HUBOT_VSTS_API_TOKEN}").toString('base64')
vstsBaseUrl = process.env.HUBOT_VSTS_API_URL

module.exports = (robot) ->
  waitMessages = [
    "Hold on, checking for active PRs ",
    "Wait a sec, let me see if I can find the active PRs ",
    "Mmmmkay, searching for PRs "
  ]

  robot.respond /vsts projects$/i, (res) ->
    res.send "Retrieving list of VSTS projects..."
    retrieveProjects res, "Here's what I found: "

  robot.respond /vsts (.*) (pr|prs|pullrequest|pullrequests)$/i, (res) ->
    project = res.match[1]

    waitMessage = res.random waitMessages
    res.send waitMessage + "in `#{project}` ..."

    # get the list of repositories
    reposUrl = "#{vstsBaseUrl}/git/repositories"
    res.http(reposUrl)
      .header('Authorization', vstsToken)
      .header('Content-type', 'application/json')
      .get() (err, _, body) ->
        if err
          res.send ":fire: An error was thrown in Node.js/CoffeeScript"
          res.send error

        repos = (JSON.parse body).value

        # Get only the repos for the specified project
        projectRepos = repos.filter((x) -> x.project.name.toLowerCase() is project.toLowerCase())
        # res.send "#{relevantRepos.length}"
        if projectRepos.length is 0
          # Most likely a bad project was given. Let's fetch the valid project names as a hint.
          retrieveProjects res, "Sorry, `#{project}` doesn't appear to be a project in VSTS. Here's a list of valid projects: "
          return
        
        repositories = {}
        hasPullRequests = false

        for projectRepo in projectRepos
          repositories[projectRepo.id] = projectRepo.name
          id = projectRepo.id
          repoPrUrl = "#{reposUrl}/#{id}/pullRequests?status=active"

          res.http(repoPrUrl)
           .header('Authorization', vstsToken)
           .header('Content-type', 'application/json')
           .get() (err, _, prbody) ->
             if err
               res.send ":fire: An error was thrown in Node.js/CoffeeScript"
               res.send error

             pullRequests = (JSON.parse prbody).value
             if pullRequests.length > 0
               hasPullRequests = true
               for pr in pullRequests
                 repo = encodeURIComponent repositories[pr.repository.id]
                 repositoryUrl = "https://mimeo.visualstudio.com/DefaultCollection/#{project}/_git/#{repo}"
                 pullRequestUrl = "https://mimeo.visualstudio.com/DefaultCollection/#{project}/_git/#{repo}/pullrequest/#{pr.pullRequestId}"
                 attachment = 
                   fallback: "Pull Request #{pr.pullRequestId} in #{repositories[pr.repository.id]} \"#{pr.title}\" #{pr.pullRequestUrl}"
                   text: "<#{pullRequestUrl}|Pull Request #{pr.pullRequestId}> - \"#{pr.title}\" in <#{repositoryUrl}|#{repositories[pr.repository.id]}>"
                   fields: [
                       {
                               title: "Source"
                               value: "`#{pr.sourceRefName}`"
                               short: true
                       },
                       {
                               title: "Target"
                               value: "`#{pr.targetRefName}`"
                               short: true
                       },
                       {
                               title: "Repository"
                               value: "`#{repositories[pr.repository.id]}`"
                               short: true
                       },
                       {
                               title: "Merge Status"
                               value: "`#{pr.mergeStatus}`"
                               short: true
                       },
                       {
                               title: "Description"
                               value: "#{pr.description}"
                               short: false
                       }
                   ] 
                   color: "#68217A"
                   mrkdwn_in: ["text","fields"]
                   author_name: "Visual Studio Team Services"
                   author_icon: "https://zapier.cachefly.net/storage/services/59152a3a91bfe0ddd2fc9b978448593a.128x128.png"

                 res.robot.adapter.customMessage
                    channel: res.envelope.room
                    username: res.robot.name
                    attachments: [attachment]

        setTimeout () ->
            res.send "No active pull requests for #{project}" unless hasPullRequests
          , 2000


retrieveProjects = (res, messageHeader) -> 
    url = "#{vstsBaseUrl}/projects?stateFilter=WellFormed"
    res.http(url)
      .header('Authorization', vstsToken)
      .header('Content-type', 'application/json')
      .get() (err, _, body) ->
        if err
          res.send ":fire: An error was thrown in Node.js/CoffeeScript"
          res.send error

        projects = JSON.parse body
        projectNames = []
        for project in projects.value
          projectNames.push("`#{project.name}`")

        message = projectNames.join(", ")
        res.send "#{messageHeader} #{message}"
