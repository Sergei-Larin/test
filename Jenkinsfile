def get_image_name(){
  if(env.TAG_NAME){
      image = "${env.DOCKER_REGISTRY_BUILD_URL}" + ":release"
      isStage = false
  } else if(env.BRANCH_NAME ==~ /release-*[0-9].[0-9].[0-9]/) {
      image = "${env.DOCKER_REGISTRY_BUILD_URL}" + ":stage"
      isStage = true
  } else {
      image = "${env.DOCKER_REGISTRY_BUILD_URL}" + ":dev"
      isStage = false
    }
  return image
}

properties([
    parameters([
      string(name: "DOCKER_CREDENTIAL_ID", defaultValue: "ecr:eu-central-1:aws-credentials-id", description: "ECR credentials"),
      string(name: "DOCKER_REGISTRY_BUILD_URL", defaultValue: "diploma", description: "Registry name for images"),
      string(name: "POSTGRES_CREDENTIAL_ID", defaultValue: "postgres-id", description: "ID postgres credential"),
			string(name: "K8S_CREDENTIAL_ID", defaultValue: "k8s-sa-id", description: "ID SA kubernetes"),
      string(name: "SONAR_CREDENTIAL_ID", defaultValue: "sonar-token", description: "ID token SonaQube"),
    ])
])

pipeline {
  agent {
    kubernetes {
      yamlFile 'agent.yaml'
    }
  }
  stages {
    stage('Testing') {
      steps {
        catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
          script {
            container('python') {
              println("=============================== STEP: Testing project ===============================")
              sh 'pip3 install --upgrade pip -r requirements.txt'
              parallel(
                'Lint *.py Tests': {
                  sh 'pylint *.py'
                },
                'Lint */*.py Tests': {
                  sh 'pylint */*.py'
                },
                'Lint */*/*.py Tests': {
                  sh 'pylint */*/*.py'
                },
                'Quality Tests': {
                    def scannerHome = tool 'sonar-scanner'    
                    withSonarQubeEnv(credentialsId: '', installationName: 'SonarQube') {
                      sh  "${scannerHome}/bin/sonar-scanner " +
                        "-Dsonar.projectKey=${env.DOCKER_REGISTRY_BUILD_URL} " +
                        "-Dsonar.projectName=${env.DOCKER_REGISTRY_BUILD_URL} " +
                        "-Dsonar.sources=. " +
                        "-Dsonar.coverage.dtdVerification=false " +
                        "-Dsonar.projectVersion=${env.COMMIT} " +
                        "-Dsonar.python.coverage.reportPaths=/sonar/coverage.xml "+
                        "-Dsonar.python.xunit.reportPath=/sonar/result.xml "
                    }
                  }
              )
            }
          }
        }
      }
    }

    stage('Build image') {
      steps {
        script {
          container("docker-client") {
            println("=============================== STEP: Building project from commit: "+env.GIT_COMMIT.take(7) + " ===============================")		
            IMAGE_NAME = get_image_name()       
            docker.withRegistry("${DOCKER_REGISTRY}", env.DOCKER_CREDENTIAL_ID) {
              dockerImage = docker.build("${IMAGE_NAME}","--no-cache -f Dockerfile .")
              dockerImage.push()
            }
          }
        }
      }
    }

    stage('Deploy to dev') {
      when {
        branch 'develop' 
      }
      steps {
        script {
          container('kubectl') {
            withKubeConfig([credentialsId: 'k8s-sa-id', serverUrl: 'https://1F230DA16B55ADC9155FE9D2A8CBD945.gr7.eu-central-1.eks.amazonaws.com']) {
              println("=============================== STEP: Deploy to dev ===============================")
              sh 'kubectl --namespace=dev get po'
            }
          }
        }
      }
    }

    stage('Deploy to stage') {
      when {
        expression { 
          return isStage 
        }
      }
      steps {
        script {
          container('kubectl') {
            withKubeConfig([credentialsId: 'k8s-sa-id', serverUrl: 'https://1F230DA16B55ADC9155FE9D2A8CBD945.gr7.eu-central-1.eks.amazonaws.com']) {
              println("=============================== STEP: Deploy to stage ===============================")
              sh 'kubectl --namespace=stage get po'
            }
          }
        }
      }
    }

    stage('Deploy to prod') {
      when {
        expression {
          return env.TAG_NAME 
        }
      }
      steps {
        script {
          container('kubectl') {
            withKubeConfig([credentialsId: 'k8s-sa-id', serverUrl: 'https://1F230DA16B55ADC9155FE9D2A8CBD945.gr7.eu-central-1.eks.amazonaws.com']) {
              println("=============================== STEP: Deploy to production ===============================")
              sh 'kubectl --namespace=prod get po'
            }
          }
        }
      }
    }

    post {
      always { 
        cleanWs() 
        script {
          println("=============================== AFTERSTEPS: Cleanup ===============================")
          def IMAGE_NAME = get_image_name()
          sh "docker rmi $IMAGE_NAME $IMAGE_TESTING -f"
          sh "docker image prune -f"    
        }
      }
      success { echo 'I succeeeded' }
      failure { echo 'I failed' }
    }
  }
}
