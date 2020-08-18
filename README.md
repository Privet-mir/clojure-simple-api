# clojure-simple-api

Jenkins Pipeline to deploy Clojure code on docker swarm cluster

## Tasks
  - [x] Create CI pipeline on sample clojure code
  - [x] Trigger on check ins, run lint 
  - [x] QA tests
  - [x] if test pass merge in main branch
  - [x] deploy to production
  - [x] publish reports on tests and code quality

## Architecture

* Services are Deployed on Single node docker swarm cluster
* Two service have been created one for staging and one for production each running 3 replica of containers
* Strategy used for deployment of services is rolling and rollback
* If service exists pipeline will perform rolling update of image where each container image will be updated in reverse order (3 2 1) with an interval of 10s. next container is updated only when previous container status is running.
* If service does not exists pipeline will create one.
* In case of FAILURE container getting updated will pause and rollback to its previous version. 
* This will deploy / upgrade service in production with ZERO DOWNTIME 

## Design

1.  Whenever developer check ins into git repo a job (github actions) is trigger to check code linting if job is success then it will trigger pipeline otherwise job will be failed and developer will be notified via email
2.  once pipeline is triggred it will first check out develop branch, then build / complie clojure code binary and create docker image.
3.  After docker image is build image is used to run unit / integration tests
4.  After the success of previous stage image is deployed in staging environment.
5.  Get / Put request are performed to check services are working / QA testing stage.
6.  Code quality / Vulnerabiltiy / Code coverage are generated using sonar qube 
7.  Merge develop branch with platform branch and tag staging image for prod
8.  Deploy service to prod

In code quality stage quality gates are not implemented. quality gates determine stage failure or success. in sonar qube we can set custom quality profiles for now all are set to defaults.

NOTE: If any of the stage failed pipeline will break and notification would be sent to appropriate channels (notification not implemented for now)

## Prerequisites

  1. Ubuntu 18.04 (root permissions i.e sudo user)
  2. Jenkins Server
  3. Open-JDK 8 (JAVA)
  4. lein 2.8.3
  5. Docker (Docker compose, Docker swarm)
  6. Sonarqube server
  7. fork / clone this repo in your git account

## Setup
To install / setup prerequisites on Ubuntu machine, run:

```
$:  chmod +x setup.sh
$:  ./setup.sh

```
Note the initial password for jenkins.

```
## Once the setup is completed run following command
## login as root
$: sudo -s
## login as jenkins user
$: su - jenkins
## run following command
$: pip install robotframework
$: pip install robotframework-httplibrary
```

Now Login into jenkins from browser server_ip:8080
  * paste initial password > install default plugins > setup user for jenkins > start using jenkins
  * manage jenkins > manage plugins > search in available plugins and install following
    1.  Sonar scanner
    2.  Quality Gates
    3.  Copy artifacts
    4.  Robot framework
  * restart jenkins server
  * manage jenkins > configure system > add SonarQube servers (name as sonar, url as http://localhost:9000)
  * manage jenkins > configure system > add quality gate (pass same info as SonarQube servers)
  * manage jenkins > manage credentials > click on Domain global > add credentials > username and pass (enter your git user in username and git personal access token in password) 
  * manage jenkins > Script Console > paste following in text box (hudson.security.csrf.GlobalCrumbIssuerConfiguration.DISABLE_CSRF_PROTECTION = true) > run

Login into sonarqube dashboard from browser server_ip:9000 using creds admin:admin
  * Select Administration tab > select System > click on restart

## Create Pipeline

```
# change this in Jenkinsfile
credentialsId: 'your_global_creds_id',
url: 'https://your_git_user@github.com/your_git_user/clojure-simple-api.git'
```

```
# change this in Jenkinsfile
git config --global credential.username your_git_username
git config --global credential.helper "!echo password=git_token; echo"
```

```
change this in .github/workflows/clojure.yml
http://jenkins_username:jenkins_password@jenkins_server_ip:8080/job/Swym_Pipeline/
```

Create pipeline project

* Click on new item > enter item name as (Swym_Pipeline) > select pipeline > click on create
* configure Swym_Pipeline > in general select discard old builds > then select this project is parameterised > add string parameter BRANCH_NAME (default value develop) > add string parameter PLATFORM_BRANCH (default value swym)
* in build triggers > select generic webhook > enter Token value (swym)
* pipeline > pipeline script > copy pipeline script from Jenkins file and paste it in textbox

Once pipeline is created push change to develop branch it will automatically trigger pipeline

![pipeline jenkins](pipeline.png)

Code Quality / Vulnerability / Code Coverage reports are published on sonarqube

![sonar qube](sonar.png)


