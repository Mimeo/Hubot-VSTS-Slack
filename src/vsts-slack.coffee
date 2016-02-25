# Description
#   A Hubot script for Visual Studio Team Services integration tailored for Slack
#
# Configuration:
#   HUBOT_VSTS_API_TOKEN
#   HUBOT_VSTS_API_URL
#
# Commands:
#   hubot vsts projects - Gets the list of projects available in Visual Studio Team Services
#   hubot vsts <project> pullrequests <showDetails>- Gets the active pull requests for the specified Visual Studio Team Services project. <showDetails> is optional 
#
# Author:
#   Nithin Shenoy <nshenoy@mimeo.com>

vstsToken = 'Basic ' + new Buffer(":#{process.env.HUBOT_VSTS_API_TOKEN}").toString('base64')
vstsBaseUrl = process.env.HUBOT_VSTS_DEFAULTCOLLECTION_URL

module.exports = (robot) ->
  waitMessages = [
    "Hold on, checking for active PRs ",
    "Wait a sec, let me see if I can find the active PRs ",
    "Mmmmkay, searching for PRs "
  ]

  robot.respond /vsts projects$/i, (res) ->
    unless (ensureEnvironment res)
      res.send "Retrieving list of VSTS projects..."
      retrieveProjects res, "Here's what I found: "

  robot.respond /vsts (.*) (pr|prs|pullrequest|pullrequests)\s?(details|detailed|showdetails)?$/i, (res) ->
    unless (ensureEnvironment res)
        project = res.match[1]
        showDetails = res.match[3]?

        waitMessage = res.random waitMessages
        res.send waitMessage + "in `#{project}` ..."

        # get the list of repositories
        reposUrl = "#{vstsBaseUrl}/_apis/git/repositories"
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
                                res.send err

                            pullRequests = (JSON.parse prbody).value
                            if pullRequests.length > 0
                                hasPullRequests = true
                                for pr in pullRequests
                                    attachment = createPullRequestAttachment showDetails, pr, repositories[pr.repository.id], project                    
                                    
                                    res.robot.adapter.customMessage
                                        channel: res.envelope.room
                                        username: res.robot.name
                                        attachments: [attachment]

                setTimeout () ->
                    res.send "No active pull requests for #{project}" unless hasPullRequests
                , 2000

#################################################
## Checks the presence of required  env variables
#################################################
ensureEnvironment = (msg) ->
  missingConfig = false

  unless process.env.HUBOT_VSTS_API_TOKEN?
    msg.send "VSTS API Token is missing: Make sure the HUBOT_VSTS_API_TOKEN is set"
    missingConfig |= true

  unless process.env.HUBOT_VSTS_DEFAULTCOLLECTION_URL?
    msg.send "VSTS DefaultCollection URL is missing: Make sure the HUBOT_VSTS_DEFAULTCOLLECTION_URL is set"
    missingConfig |= true
    
  missingConfig

#################################################
## Creates attachment message object for pull request
#################################################
createPullRequestAttachment = (showDetails, pullRequestInfo, repository, project) ->
    repo = encodeURIComponent repository
    repositoryUrl = "#{vstsBaseUrl}/#{project}/_git/#{repo}"
    pullRequestUrl = "#{vstsBaseUrl}/#{project}/_git/#{repo}/pullrequest/#{pullRequestInfo.pullRequestId}"
    attachment = 
        fallback: "Pull Request #{pullRequestInfo.pullRequestId} in #{repository} \"#{pullRequestInfo.title}\" #{pullRequestInfo.pullRequestUrl}"
        text: "<#{pullRequestUrl}|Pull Request #{pullRequestInfo.pullRequestId}> - \"#{pullRequestInfo.title}\" in <#{repositoryUrl}|#{repository}>"
        color: "#68217A"
        mrkdwn_in: ["text","fields"]
        author_name: "Visual Studio Team Services"
        author_icon: "https://zapier.cachefly.net/storage/services/59152a3a91bfe0ddd2fc9b978448593a.128x128.png"
    
    if showDetails
        details = 
            fields: [
                {
                        title: "Source"
                        value: "`#{pullRequestInfo.sourceRefName}`"
                        short: true
                },
                {
                        title: "Target"
                        value: "`#{pullRequestInfo.targetRefName}`"
                        short: true
                },
                {
                        title: "Repository"
                        value: "`#{repository}`"
                        short: true
                },
                {
                        title: "Merge Status"
                        value: "`#{pullRequestInfo.mergeStatus}`"
                        short: true
                },
                {
                        title: "Description"
                        value: "#{pullRequestInfo.description}"
                        short: false
                }
            ]
        attachment.fields = details.fields
    
    return attachment

#################################################
## Retrieves list of projects
#################################################
retrieveProjects = (res, messageHeader) -> 
    url = "#{vstsBaseUrl}/_apis/projects?stateFilter=WellFormed"
    res.http(url)
      .header('Authorization', vstsToken)
      .header('Content-type', 'application/json')
      .get() (err, _, body) ->
        if err
          res.send ":fire: An error was thrown in Node.js/CoffeeScript"
          res.send err

        projects = JSON.parse body
        projectNames = []
        for project in projects.value
          projectNames.push("`#{project.name}`")

        message = projectNames.join(", ")
        res.send "#{messageHeader} #{message}"
