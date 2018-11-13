# Automated deployments to Google Cloud Functions: commit, push, deploy

## Overview

This example shows integrating Cloud Build with Cloud Functions to enable an
automated deployment workflow. At a high level, the goal is to enable you to:
* modify code locally
* commit and push that change to a remote repository
* trigger a deployment to Google Cloud Functions using the updated code

The example uses the following products:
* Cloud Functions
* Cloud Build
* Cloud Source Repositories
* GitHub

## Walkthrough

### Pre-requisites
* `git`
* `curl`
* A Google Cloud Platform account with billing enabled
* A GitHub account

### Create your project and function directories

```console
$ mkdir functions
$ mkdir functions/autodeploy
$ cd functions
```

`functions/autodeploy` will contain the code corresponding to our Cloud Function.
`autodeploy` will contain the function that will be deployed automatically.

Note: you could extend this repository by adding more functions, each in its own
sub-directory. Each function would have its own deployment rules specified in
`cloudbuild.yaml`.

### Initialize a local git repo

```console
$ git init
```

### Write a "Hello, World" function

Create an `index.js` file in `autodeploy`. This file contains your "Hello, World"
code. You can use the contents from [autodeploy/index.js](autodeploy/index.js)
as starter code.

When you're done, your `index.js` should look something like this:

```console
$ cat autodeploy/index.js
/**
 * HTTP Cloud Function.
 *
 * @param {Object} req Cloud Function request context.
 *                     More info: https://expressjs.com/en/api.html#req
 * @param {Object} res Cloud Function response context.
 *                     More info: https://expressjs.com/en/api.html#res
 */
exports.helloHttp = (req, res) => {
  res.send(`Hello ${req.body.name || 'World'}!`);
};
```

### Write a cloudbuild.yaml file

At the root of your `functions` directory, add a `cloudbuild.yaml` file. You
can use the contents from [cloudbuild.yaml](cloudbuild.yaml) in this repo to get
started.

`cloudbuild.yaml` provides instructions to Cloud Build (more later) regarding
which steps to execute when a build is triggered. In this case, we tell Cloud
Build to use [gcloud](https://cloud.google.com/sdk/gcloud/) to deploy to
Cloud Functions.

When you're done, your `cloudbuild.yaml` should look something like this:

```console
$ cat cloudbuild.yaml
steps:
- name: 'gcr.io/cloud-builders/gcloud'
  args: ['functions', 'deploy', 'autodeploy', '--trigger-http', '--entry-point', 'helloHttp', '--runtime', 'nodejs8']
  dir: 'autodeploy'
```

A few notes:

* we use the list style format for `args:` since arguments are delimited by
  spaces, e.g., `--runtime nodejs8`
* we use `dir` to instruct Cloud Build to execute the `gcloud` command from
  within the `autodeploy` directory
* if you want to add more functions, add corresponding build steps in your
  `cloudbuild.yaml`

### Commit changes to your local repository

```console
$ git add *
$ git commit -m "My first commit"
```

### Create a remote repository, sync and push

Create a new repository on GitHub by following [the prompts](https://github.com/new).
You can also use Bitbucket. Get your remote repository from the GitHub user
interface and add it to the command below.

```console
git remote add origin git@github.com:<YOUR_REMOTE_REPOSITORY_ID>
git push -u origin master
```

### Connect GitHub to Cloud Source Repositories

Set up a repository in Cloud Source Repositories and mirror it to your GitHub
repo. [Follow the Setting Up a Repository](https://cloud.google.com/tools/cloud-repositories/docs/cloud-repositories-setup)
instructions and select "Automatically mirror from GitHub or Bitbucket" when
you're in the Google Cloud Console.

### Create a Cloud Build trigger

Create a Cloud Build trigger that will fire automatically when a new commit is
made to the Cloud Source Repository. Note that, since we've mirrored from GitHub,
any push to your GitHub repo will also result in a commit to Cloud Source
Repositories, which will then trigger Cloud Build.

Start by [Creating a build trigger](https://cloud.google.com/source-repositories/docs/integrating-with-cloud-build#creating_a_build_trigger).
Make sure to select the `cloudbuild.yaml` build configuration file and specify
its correct location at the root of your project.

### Set up the required permissions

Cloud Build doesn't, by default, have access to the Cloud Functions API within
your project. Before attempting a deployment, follow the
[Cloud Functions Deploying artifacts](https://cloud.google.com/cloud-build/docs/configuring-builds/build-test-deploy-artifacts#deploying_artifacts) instructions (steps 2 and 3, in particular).

Note that you will need your project number (not your project name/id). When looking
at the IAM page, there will typically only be one entry that matches
`[YOUR-PROJECT-NUMBER]@cloudbuild.gserviceaccount.com`.

### Trigger a build

Now that you're all set up, trigger a build using the [Cloud Build console](https://console.cloud.google.com/cloud-build/triggers).
You should see a small pop-up in the lower left, click "SHOW" to watch your
in-progress build.

If all went well, you should see logs similar to:

```console
starting build "ed8d960c-bdce-486a-af6d-9582b81243d4"

FETCHSOURCE
Initialized empty Git repository in /workspace/.git/
From https://source.developers.google.com/p/<PROJECT_NAME>/r/<CLOUD_SOURCE_REPOSITORY>
* branch 166e96fcd0ad216a6ca31093222ac68758fe62ff -> FETCH_HEAD
HEAD is now at 166e96f My first commit!
BUILD
Already have image (with digest): gcr.io/cloud-builders/gcloud
Deploying function (may take a while - up to 2 minutes)...
......................done.
availableMemoryMb: 256
entryPoint: helloHttp
httpsTrigger:
url: https://<REGION>-<PROJECT_NAME>.cloudfunctions.net/autodeploy
labels:
deployment-tool: cli-gcloud
name: projects/<PROJECT_NAME>/locations/<REGION>/functions/autodeploy
runtime: nodejs8
serviceAccountEmail: <PROJECT_NAME>@appspot.gserviceaccount.com
sourceUploadUrl: <ommitted>
status: ACTIVE
timeout: 60s
updateTime: '2018-11-13T01:42:15Z'
versionId: '1'
PUSH
DONE
```

### Test that the deployment worked

Use `curl` to send a request to your function. You can find the function's
endpoint in the Cloud Build logs.

```console
$ curl https://<REGION>-<PROJECT_NAME>.cloudfunctions.net/autodeploy
Hello, World!
```

### Test the full workflow

As a final step, modify the `index.js` file in your local repository. For
example, change the output from "Hello World!" to "Hey World!". Then stage,
commit and push that file to GitHub. After the push, you should see a new
build in your Cloud Build console.

Wait for the build to complete, then `curl` the function again and you should
see your update reflected in the response. Note that, occasionally, traffic
migration can take a minute or two, even once the function has been deployed.
So take a short break, stretch your legs and then retry.

That's it. Your automated workflow is now set up. Wohoo!
