pipeline {
    agent any

    stages {
        stage('CheckOut') {
            steps {
                /* CheckOut branch from git, credentials id is picked from 
                Global credentials you can configure it with user:pass for 
                your git repo or use user:token generated from github*/
                cleanWs()
                git branch: '${BRANCH_NAME}',
                credentialsId: 'github',
                url: 'https://Privet-mir@github.com/Privet-mir/clojure-simple-api.git'
                
                sh "ls -lat"
                archiveArtifacts artifacts: '**/*'
            }
        }
        stage('Buld') {
            steps {
                /* Build docker image from Dockerfile for staging*/
                sh "docker build --no-cache -t swym_staging:${BUILD_ID} ."
            }
        }
        stage('Test') {
            steps {
                 /* Run test on staging docker image*/
                sh "docker run swym_staging:${BUILD_ID} bash -c 'lein test'"
            }
        }
        stage('DeployStaging') {
            steps {
                /* If deployment fails it will pause and rollback to
                previous image, next replica is updated after 10s and
                when previous replica status is running.*/
                sh '''
                echo "Deploy docker swym service with 3 replicas"
                    
                echo $BUILD_ID

                    if docker service ls | grep -q 'staging';
	                then
		                echo "update service"
		                docker service update --image swym_staging:${BUILD_ID} staging_swym-api --update-delay 10s --update-failure-action rollback
	                else
		                echo "create service"
		                IMAGE=swym_staging:${BUILD_ID} docker stack deploy -c docker-compose.yaml staging
	                fi

                    sleep 30
                    
                    '''
            }
        }
        stage('QATest') {
                /*Run Robot framwork*/
            steps {
                echo "RUN Get / Post request with robot on staging service"
                sh "robot robot-testcase.robot"
                    script {
                        step(
                            [
                                $class                    : 'RobotPublisher',
                                outputPath                : '/var/lib/jenkins/workspace/Swym_Pipeline',
                                outputFileName            : "*.xml",
                                reportFileName            : "report.html",
                                logFileName               : "log.html",
                                disableArchiveOutput      : false,
                                passThreshold             : 100,
                                unstableThreshold         : 95.0,
                                otherFiles                : "*.png"
                            ]
                            )
                     }
            }
        }
        
        stage('CodeQuality') {
            steps {
                /*Running Sonar, reports will be published on sonar dashboard
                this will perform lint, code coverage, vulnerability analysis
                on code*/
                /*Pass soarqube env name that you have configured in
                global configuration setting*/
                withSonarQubeEnv('sonar') {
                sh 'sonar-scanner'
              }
            }
        }
        
        stage('BuildProd') {
            steps {
                /*this will merge develop branch with platform branch
                and tag staging image as prod only when all previous 
                stages are successfull*/
                sh '''
                echo "Checkout ${PLATFORM_BRANCH}"
                git checkout ${PLATFORM_BRANCH}

                echo "Merge ${PLATFORM_BRANCH}"
                git merge origin/${BRANCH_NAME}
                
                echo "Push to ${PLATFORM_BRANCH}"
                git push origin ${PLATFORM_BRANCH} 

                echo "Tag staging image for prod"
                docker tag swym_staging:${BUILD_ID} swym_prod:${BUILD_ID}

                '''
            }
        }
        
        stage('DeployProd') {
            steps {
                 /* If deployment fails it will pause and rollback to
                previous image, next replica is updated after 10s and
                when previous replica status is running.*/
                
                /*the script does not delete running services, it will 
                check if service exists, if yes then update service with 
                new image, if no the deploy service
                Bringing no/zero downtime to production */
                sh '''
                    echo "Deploy docker prod swym service with 3 replicas"

                    echo $BUILD_ID

                        if docker service ls | grep -q 'prod';
	                    then
	                    	echo "update service"
	                    	docker service update --image swym_prod:${BUILD_ID} prod_swym-api --update-delay 10s --update-failure-action rollback
	                    else
	                    	echo "create service"
	                    	IMAGE=swym_prod:${BUILD_ID} docker stack deploy -c docker-compose-prod.yaml prod
                    	fi
                '''
            }
        }
    }
}


