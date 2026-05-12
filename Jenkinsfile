pipeline {
    agent any
    environment {
        registry = "837577998611.dkr.ecr.us-west-2.amazonaws.com/kpi"
        region = "us-west-2"
        ecrauth = "aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 837577998611.dkr.ecr.us-west-2.amazonaws.com"
    }

    stages {
        stage('Checkout') {
            steps {
                cleanWs()
                checkout scmGit(branches: [[name: '*/$release_branch']], extensions: [], userRemoteConfigs: [[credentialsId: 'jenkins-github-token-as-password', url: 'https://github.com/gushil/kpi.git']])
            }
        }

        stage('Fetch ECR Credentials') {
            steps {
                script {
                    sh "${ecrauth}"
                    sh "df -h"
                }
            }
        }

        stage ("Build and Push Image to ECR") {
            steps {
              script {
                if ( env.ENV == "build" || env.ENV == "build & deploy") {
                    sh """
                        # Unset DOCKER_HOST to ensure commands target the local Docker daemon by default
                        unset DOCKER_HOST
                        if docker buildx inspect arm64builder > /dev/null 2>&1; then
                            docker buildx rm arm64builder
                        fi
                        docker buildx create --name arm64builder --node arm64 --platform linux/aarch64
                        docker buildx inspect --bootstrap --builder arm64builder
                       """
                    sh "docker buildx build --builder arm64builder --platform linux/aarch64 -t ${registry}:${tag_version} --push ."
                  }
                else {
                    sh "echo 'Skipping this step'"
                }
             }
           }
        }
    }
}
