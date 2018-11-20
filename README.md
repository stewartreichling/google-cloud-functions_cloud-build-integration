# Easy deployments and deletions of groups of functions to Google Cloud Functions

## Overview

This example shows how to easily deploy multiple instances of a group of functions during various development stages without actually changing the `cloudbuild.yaml` file.
This group of functions can be just as easily deleted without changing the `cloudbuild.yaml` file for each stage.
What this example does is:
* modify code locally
* deploy the group of changed functions by either overwriting the previous ones (using the same PREFIX), or creating brand new instances of them (using a new PREFIX)
* delete the previously deployed group of functions (based on their PREFIX)

The example uses the following products:
* Cloud Functions
* Cloud Build

## Walkthrough

### Pre-requisites
* A Google Cloud Platform account with billing enabled

### Create your project and function directories

```console
$ mkdir functions
$ mkdir functions/autodeploy
$ cd functions
```

`functions/autodeploy` will contain the code corresponding to our Cloud Function.
`autodeploy` will contain the function that will be deployed.

Note: you could extend this repository by adding more functions, each in its own
sub-directory. Each function would have its own deployment rules specified in
`cloudbuild.yaml`.

For this example we deploy 2 instances of the same function, but this can be easily remedied by changing the  `dir` value of the second one.

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
  res.send(`Yo, ${req.body.name || 'World'}!`);
};
```

### Write a cloudbuild.yaml file

At the root of your `functions` directory, add a `cloudbuild.yaml` file. You
can use the contents from [cloudbuild.yaml](cloudbuild.yaml) in this repo to get
started.

`cloudbuild.yaml` provides instructions to Cloud Build (more later) regarding
which steps to execute when a build is submitted. In this case, we tell Cloud
Build to use [gcloud](https://cloud.google.com/sdk/gcloud/) to deploy to
Cloud Functions.

When you're done, your `cloudbuild.yaml` should look something like this:

```console
$ cat cloudbuild.yaml
steps:
- name: 'gcr.io/cloud-builders/gcloud'
  args: ['functions', 'deploy', '${_PREFIX}-func1', '--trigger-http', '--entry-point', 'helloHttp', '--runtime', 'nodejs8']
  dir: 'autodeploy'
- name: 'gcr.io/cloud-builders/gcloud'
  args: ['functions', 'deploy', '${_PREFIX}-func2', '--trigger-http', '--entry-point', 'helloHttp', '--runtime', 'nodejs8']
  dir: 'autodeploy'
```

A few notes:

* we use the list style format for `args:` since arguments are delimited by
  spaces, e.g., `--runtime nodejs8`
* we use `dir` to instruct Cloud Build to execute the `gcloud` command from
  within the `autodeploy` directory
* if you want to add more functions, add corresponding build steps in your
  `cloudbuild.yaml`
* ${_PREFIX} stands for the PREFIX used while deploying this group of functions. This _PREFIX gets substituted during build-time. More on custom substitutions here: [Using user-defined substitutions](https://cloud.google.com/cloud-build/docs/configuring-builds/substitute-variable-values#using_user-defined_substitutions)

### Manually trigger a Cloud Build

To submit a command to build and deploy your group of functions can be easily done by executing the following command:

```console
gcloud builds submit --config cloudbuild.yaml --substitutions=_PREFIX="myprefix" .
```

Note:
Notice the flag: `--substitutions=` - this is how we tell the Cloud Build what out _PREFIX is going to be during this build-time.
By using the same PREFIX, one can easily delete the whole group of testing functions from the same stage (deployed using the same _PREFIX) by executing this command:

```console
gcloud builds submit --config cloudbuilddelete.yaml --substitutions=_PREFIX="myprefix" --no-source
```

Note:
Notice the `--no-source` flag.
This flag is used because we aren't compiling/building the app, only deleting the already existing Cloud Functions.
This simply means we have no need for sending any source code, which saves us the time it normally takes to upload the source code archive and verify its content.

Your functions are now online!

To simplify the process, you can also use:
```console
make deploy
make delete
```

Or make a BASH alternative, since it is pretty much the same...

### Set up the required permissions

Cloud Build doesn't, by default, have access to the Cloud Functions API within
your project. Before attempting a deployment, follow the
[Cloud Functions Deploying artifacts](https://cloud.google.com/cloud-build/docs/configuring-builds/build-test-deploy-artifacts#deploying_artifacts) instructions (steps 2 and 3, in particular).

Note that you will need your project number (not your project name/id). When looking
at the IAM page, there will typically only be one entry that matches
`[YOUR-PROJECT-NUMBER]@cloudbuild.gserviceaccount.com`.

### Submit a build request
If all went well, you should see logs similar to:

```console
gcloud builds submit --config cloudbuild.yaml --substitutions=_PREFIX="myprefix" .
Creating temporary tarball archive of 5 file(s) totalling 10.2 KiB before compression.
Some files were not included in the source upload.

Check the gcloud log [<ommitted>.log] to see which files and the contents of the
default gcloudignore file used (see `$ gcloud topic gcloudignore` to learn
more).

Uploading tarball of [.] to [gs://<PROJECT_NAME>_cloudbuild/source/<ommitted>.tgz]
Created [https://cloudbuild.googleapis.com/v1/projects/<PROJECT_NAME>/builds/<ommitted>].
Logs are available at [https://console.cloud.google.com/gcr/builds/<ommitted>].
---------------------------------------------------------------------------- REMOTE BUILD OUTPUT -----------------------------------------------------------------------------
starting build "<ommitted>"

FETCHSOURCE
Fetching storage object: gs://<PROJECT_NAME>_cloudbuild/source/<ommitted>.tgz#<ommitted>
Copying gs://<PROJECT_NAME>_cloudbuild/source/<ommitted>.tgz#<ommitted>...
/ [1 files][  4.0 KiB/  4.0 KiB]
Operation completed over 1 objects/4.0 KiB.
BUILD
Starting Step #0
Step #0: Already have image (with digest): gcr.io/cloud-builders/gcloud
Step #0: Deploying function (may take a while - up to 2 minutes)...
Step #0: ..............done.
Step #0: availableMemoryMb: 256
Step #0: entryPoint: helloHttp
Step #0: httpsTrigger:
Step #0:   url: https://<REGION>-<PROJECT_NAME>.cloudfunctions.net/myprefix-func1
Step #0: labels:
Step #0:   deployment-tool: cli-gcloud
Step #0: name: projects/<PROJECT_NAME>/locations/<REGION>/functions/myprefix-func1
Step #0: runtime: nodejs8
Step #0: serviceAccountEmail: <PROJECT_NAME>@appspot.gserviceaccount.com
Step #0: sourceUploadUrl: <ommitted>
Step #0: status: ACTIVE
Step #0: timeout: 60s
Step #0: updateTime: '2018-11-20T09:49:44Z'
Step #0: versionId: '2'
Finished Step #0
Starting Step #1
Step #1: Already have image (with digest): gcr.io/cloud-builders/gcloud
Step #1: Deploying function (may take a while - up to 2 minutes)...
Step #1: ................done.
Step #1: availableMemoryMb: 256
Step #1: entryPoint: helloHttp
Step #1: httpsTrigger:
Step #1:   url: https://<REGION>-<PROJECT_NAME>.cloudfunctions.net/myprefix-func2
Step #1: labels:
Step #1:   deployment-tool: cli-gcloud
Step #1: name: projects/<PROJECT_NAME>/locations/<REGION>/functions/myprefix-func2
Step #1: runtime: nodejs8
Step #1: serviceAccountEmail: <PROJECT_NAME>@appspot.gserviceaccount.com
Step #1: sourceUploadUrl: <ommitted>
Step #1: status: ACTIVE
Step #1: timeout: 60s
Step #1: updateTime: '2018-11-20T09:50:11Z'
Step #1: versionId: '1'
Finished Step #1
PUSH
DONE
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

ID                                    CREATE_TIME                DURATION  SOURCE                                                                                    IMAGES  STATUS
49b91d6f-9bcc-4665-9a43-35ebdb7d62ea  2018-11-20T09:49:12+00:00  1M1S      gs://<PROJECT_NAME>_cloudbuild/source/1542707346.42-e368b3faa3b2416caf8bc35530152c64.tgz  -       SUCCESS

### Test that the deployment worked

Use `curl` to send a request to your function. You can find the function's
endpoint in the Cloud Build logs.

```console
$ curl https://<REGION>-<PROJECT_NAME>.cloudfunctions.net/myprefix-func1
Yo, World!
```

### Test the full workflow

As a final step, modify the `index.js` file in your local repository.
For example, change the output from "Yo, World!" to "Hey World!",
then submit a Cloud Build request using a new prefix.
After the build, you should see a new group of functions appear in your Cloud Functions console,
following the same naming conventions while having a different prefix.

To delete this group of functions,
submit a Cloud Build request using the `cloudbuilddelete.yaml` file using the same prefix as before.
After the 'build' you should see now see the previous group of functions disappear from your Cloud Functions console.


That's it. Your automated workflow is now set up. Wohoo!
