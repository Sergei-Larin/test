def tag
def release
def prod

pipeline {
  agent {
    kubernetes {
      yamlFile 'agent.yaml'
    }
  }

  environment {
    CREDENTIALS = 'idyllic-pottery-336614'
    PROJECT_ID = 'idyllic-pottery-336614'
    CLUSTER_NAME = 'devops-cluster-1'
    LOCATION = 'europe-north1-a'
  }


  stages {
    stage('Build') {
      steps {
          script {
            container('docker') {
              docker.withRegistry('https://eu.gcr.io', 'gcr:idyllic-pottery-336614') {
                tag = env.TAG_NAME ?: env.BUILD_ID
                release = env.TAG_NAME ? true : false
                def image = docker.build("idyllic-pottery-336614/cicd_app:${tag}")
                image.push()
                if (env.TAG_NAME) {
                  image.push('latest')
                }
              }
            }
         }
      }
   }
  stage ('deploy') {
     steps {
       container('kubectl') {
          sh "sed -i 's/__TAG__/${tag}/g' manifest.yaml"
          step([
            $class: 'KubernetesEngineBuilder',
            projectId: env.PROJECT_ID,
            clusterName: env.CLUSTER_NAME,
            location: env.LOCATION,
            manifestPattern: 'manifest.yaml',
            namespace:'test',
            credentialsId: env.CREDENTIALS,
            verifyDeployments: true
          ])
       }
      script {
        if (release) {
          prod = input    message: "deploy to prod?",
                  id: 'prodDeploy',
                  parameters: [booleanParam(name: "reviewed", defaultValue: false,
                        description: "prod deploy")]
          println prod
        }
     }
    }
   }
   stage ('deploy prod') {
     when {
                expression { prod == true }
     }
     steps {
       container('kubectl') {
          sh "sed -i 's/__TAG__/${tag}/g' manifest.yaml"
          step([
            $class: 'KubernetesEngineBuilder',
            projectId: env.PROJECT_ID,
            clusterName: env.CLUSTER_NAME,
            location: env.LOCATION,
            manifestPattern: 'manifest.yaml',
            namespace: 'prod',
            credentialsId: env.CREDENTIALS,
            verifyDeployments: true
          ])
       }

     }
   }




  }
}
