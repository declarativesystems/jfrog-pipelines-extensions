# JFrog Pipelines Extensions

* GoLang 1.15.3 
* NodeJS v15
* AWS CLI v2
* GoReleaser
* NpmBuild
* NpmPublish
* Release to AWS ECR
* PipInstall
* PythonWheelDeploy

## Docker Images

* Quick and dirty adaptations of the public JFrog images!
* Minimum needed to get up and running
* Not recommended for production use


## Pipeline Steps

### declarativesystems/awscli

* Run an AWS CLI v2 command from your pipeline
* Credentials stored securely in AWS Pipeline integration

**Example**

```yaml
      - name: restartEcs
        type: declarativesystems/AwsCli
        configuration:
          awsKey: "aws" # name of AWS integration
          awsRegion: "us-east-1" # Region
          awsAccountId: "111122223333" # AWS account ID
          commands:
            # array of commands to run in sequence
            - "aws ecs update-service --force-new-deployment --cluster some-cluster --service some-service"
          integrations:
            - name: aws # grant access integration
```

### declarativesystems/GoReleaser

* Build a release snapshot tarball using `goreleaser --snapshot`
* Snapshot releases do not publish git tags, etc
* Project must already be configured with a `.goreleaser.yml` file
* Upload the tarball to Artifactory
* Gotcha/todo: _dependencies_ not sourced from Artifactory

**Example**

```yaml
      - name: goReleaser
        type: declarativesystems/GoReleaser
        configuration:
          sourceArtifactory: artifactory # name of artifactory integration to use
          sourceLocation: $res_someGitRepo_resourcePath # where to find sources to build
          repositoryName: generic-local # where to upload tarballs
          buildName: some-name # Artifactory metadata
          buildNumber: $run_number # Artifactory metadata
          integrations:
            - name: artifactory # grant access to integration
          inputResources:
            - name: someGitRepo # checkout code from git first
```

### declarativesystems/NpmBuild

* Drop-in replacement for native NpmBuild to allow building with NodeJS v15
* Uses `npm install` configured for `sourceArtifactory` vs \
  `jfrog rt npm-install`
* Build using `npm build` (or `buildCommand`)
* Build output saved for next step to use via `add_run_files`

**Example**

```yaml
      - name: build
        type: declarativesystems/NpmBuild
        configuration:
          sourceArtifactory: artifactory # name of artifactory integration to source dependencies from
          sourceLocation: $res_someGitRepo_resourcePath # where to find sources to build
          repositoryName: npm # repository to source dependencies from
          buildCommand: make # optional (default is npm build)
          integrations:
            - name: artifactory # grant access to integration
          inputResources:
            - name: someGitRepo # checkout code from git first
```

### declarativesystems/NpmPublish

* Drop-in replacement for native NpmPublish to easily publish builds created
  with `declarativesystems/NpmBuild`
* Publishes build to Artifactory with `npm publish --registry`

**Example**

```yaml
      - name: publish
        type: declarativesystems/NpmPublish
        configuration:
          sourceArtifactory: artifactory # name of artifactory integration to publish dependencies to
          repositoryName: npm-local # repository to publish dependencies to
          integrations:
            - name: artifactory # grant access to integration
          inputSteps:
            - name: build # checkout code from git first
```

### declarativesystems/PodmanPushAwsEcr

* Push a Docker image from Artifactory to AWS ECR
* Gets around the limitations of attempting to run Docker-in-Docker within
  Pipelines by running [Podman](https://podman.io/)
* Internally, works by doing:
    * `podman pull ...`
    * `podman tag ...`
    * `podman push ....` 

**Example**

```yaml
      - name: ecrPush
        type: declarativesystems/PodmanPushAwsEcr
        configuration:
          sourceArtifactory: artifactory # name of artifactory integration to pull docker image from
          awsKey: "aws" # name of AWS integration
          awsRegion: "us-east-1" # Region
          awsAccountId: "111122223333" # AWS account ID
          artifactoryImage: "yourcompany.jfrog.io/docker-local/someimage:sometag" # image to pull from Artifactory
          ecrImageName: "someimage-ecr" # Image name in ECR 
          ecrImageTag: "sometag" # Image tag in ECR
          integrations:
            - name: artifactory # grant access to integration
            - name: aws # grant access to integration

```

### declarativesystems/PipInstall
* Configure `pip` to use artifactory to resolve dependencies
* Run `pip install .` against source code
* Use affinity to let `PythonWheelDeploy` find files

```yaml
      - name: pipInstall
        type: declarativesystems/PipInstall
        configuration:
          affinityGroup: python_env
          sourceArtifactory: artifactory # name of artifactory integration to resolve dependencies from
          repositoryName: pypi # repository to resolve dependencies from
          sourceLocation: $res_someGitRepo_resourcePath # where to find sources to build
          integrations:
            - name: artifactory # grant access to integration
          inputResources:
            - name: someGitRepo # checkout code from git first
```

### declarativesystems/PythonWheelDeploy
* Configure setuptools to use artifactory to publish build python wheel 
  artefacts
* Run `python setup.py bdist_wheel upload -r local` against source code
* Use affinity to access files from previous `PipInstall` step

```yaml
      - name: pythonWheelDeploy
        type: declarativesystems/PythonWheelDeploy
        configuration:
          affinityGroup: python_env
          sourceArtifactory: artifactory # name of artifactory integration to publish artefacts to
          repositoryName: pypi-local # repository to publish artefacts to
          sourceLocation: $res_someGitRepo_resourcePath # where to find sources to build
          integrations:
            - name: artifactory # grant access to integration
          inputResources:
            - name: someGitRepo # code from git first
```


## Building

Pipeline step scripts need to be self-contained. To avoid duplicated code:

* Common functions are in `lib/common.sh`
* Source code for each step is in 
  `steps/declarativesystems/STEPNAME/src/onExecute.sh`
* `make` concatenates `common.sh` with the step source code to produce
   `steps/declarativesystems/STEPNAME/onExecute.sh`
* Concatenated files checked into git for ease of use

**To build**

```
make clean scripts
```