# JFrog Pipelines Extensions

* Artifactory Download
* Artifactory Upload
* GoLang 1.15.3 
* NodeJS v15
* AWS CLI v2
* GoReleaser
* NPM/Yarn
* Release to AWS ECR
* PipInstall
* PythonWheelDeploy

## Docker Image

See https://github.com/declarativesystems/jfrog-pipelines-image

## Pipeline Resources

### declarativesystems/ContainerEnv

* Support for OCI containers (podman/buildah)
* Authenticate containerd with artifactory
* Once Artifactory is configured, build the image your way, as you would on a
  workstation. Eg: `podman build` ... `podman push`

**Example**

```yaml
apiVersion: v1.1
resources:
  - name: containerEnvSomeUniqueName
    type: declarativesystems/ContainerEnv
    configuration:
      sourceArtifactory: artifactory # for OCI image push
steps:
  - name: buildAndPushContainerImage
    type: Bash
    configuration:
      # ...
      integrations:
        - name: artifactory
      inputResources:
        - name: containerEnvSomeUniqueName
    execution:
      onExecute:
        - podman build ...
        - podman push ...
```

### declarativesystems/NpmEnv

* Enable NPM/Yarn to use Artifactory for dependency resolution and publishing
* Once Artifactory is configured, build the project your way, as you would on a
  workstation. Eg: `yarn`, `npm`, etc...

**Example**

```yaml
apiVersion: v1.1
resources:
  - name: npmEnvSomeUniqueName
    type: declarativesystems/NpmEnv
    configuration:
      sourceArtifactory: artifactory # for resolving and publishing packages
      repositoryName: npm
steps:
  - name: yarnBuildAndPush
    type: Bash
    configuration:
      # ...
      integrations:
        - name: artifactory
      inputResources:
        - name: npmEnvSomeUniqueName
    execution:
      onExecute:
        - yarn build ...
        - yarn publish ...
```

### declarativesystems/PythonEnv

* Setup `pip` to resolve artifacts from `sourceArtifactory` vi `~/.pip/pip.conf`
* Setup `setuptools` to deploy artifacts to `sourceArtifactory` via `.pypirc`
* Once Artifactory integration is configured build the project your way, as you
  would on a workstation. Eg: `pip install`, 
  `python setup.py bdist_wheel upload -r local`, etc...

**Example**

```yaml
apiVersion: v1.1
resources:
  - name: pythonEnvSomeUniqueName
    type: declarativesystems/PythonEnv
    configuration:
      sourceArtifactory: artifactory # for resolving and publishing packages
      repositoryName: pypi
steps:
  - name: pythonBuildAndPush
    type: Bash
    configuration:
      # ...
      integrations:
        - name: artifactory
      inputResources:
        - name: pythonEnvSomeUniqueName
    execution:
      onExecute:
        - pip install .
        - python setup.py bdist_wheel upload -r local
```


_Steps section_

## Pipeline Steps

### declarativesystems/ArtifactoryDownload

* Download **one** file from Artifactory
* Variables allowed
* Usually you want to use a 
  [FileSpec resource](https://www.jfrog.com/confluence/display/JFROG/FileSpec)
  not this extension step
* A limitation of the `FileSpec` resource is that since resources are available
  to all pipelines, you can't use variables, eg:
  
```yaml
  resources:
    - name: somelibFileSpec
      type: FileSpec
      configuration:
        sourceArtifactory: artifactory

        # impossible, and doesn't make sense either:
        # pattern: somerepo/somelib/${version}/somelib-${version}.jar
        
        # works, but the hardcoded version can be a problem:
        pattern: somerepo/somelib/0.0.1/somelib-0.0.1.jar
```

**Example**

```yaml
      - name: artifactoryDownload
        type: declarativesystems/ArtifactoryDownload
        configuration:
          affinityGroup: somegroup
          sourceArtifactory: artifactory
          # 2 - you can access it here
          path: somerepo/somelib/${somelibVersion}/somelib-${somelibVersion}.js
          integrations:
            - name: artifactory
        execution:
          onStart:        
            - cd /some/source/code
            # 1 - create a variable like this or use an existing one
            - add_pipeline_variables somelibVersion=$(make print_somelib_version)
```

* Use `affinityGroup` to let next step access the downloaded file
* After the step runs, the path to the downloaded file is available in 
  `$res_<resource_name>_resourcePath`
  
### declarativesystems/ArtifactoryUpload

* Same rationale as ArtifactoryDownload

```yaml
      - name: artifactoryUpload
        type: declarativesystems/ArtifactoryUpload
        configuration:
          affinityGroup: somegroup
          sourceArtifactory: artifactory
          # 2 - you can access it here
          target: build/somelib-${somelibVersion.js}
          path: somerepo/somelib/${somelibVersion}/somelib-${somelibVersion}.js
          integrations:
            - name: artifactory
        execution:
          onStart:        
            - cd /some/source/code
            # 1 - create a variable like this or use an existing one
            - add_pipeline_variables somelibVersion=$(make print_somelib_version)
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