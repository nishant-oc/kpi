pipeline {
    agent any
    environment {
        registry = "837577998611.dkr.ecr.us-west-2.amazonaws.com/kpi"
        clustername = "eks-sbs-dev"
        region = "us-west-2"
        ns = "sbsdev"
    }
    stages {
        stage('Configure EKS Cluster') {
            steps {
                sh '/usr/local/bin/eksctl version'
                sh '/usr/local/bin/eksctl utils write-kubeconfig --cluster=${clustername} --region=${region}'
                sh "ssh -J root@sbs-dev-jump -D 1094 -f root@eks-maintenance-dev -N"
            }
        }
        stage('Helm Checkout') {
            steps {
                cleanWs()
                checkout scmGit(
                    branches: [[name: '*/main']],
                    extensions: [],
                    userRemoteConfigs: [[
                        credentialsId: 'jenkins-github-token-as-password',
                        url: 'https://github.com/OpenClinica/container-ops.git'
                    ]]
                )
            }
        }
        stage('Deploy Helm Chart') {
            steps {
                sh "https_proxy=socks5://127.0.0.1:1094 /usr/local/bin/helm upgrade formdesigner --install apps/kobo_kpi --values apps/kobo_kpi/values-dev.yaml --namespace ${ns} --set kpi.image.repository=${registry} --set kpi.image.tag=latest"
            }
        }
    }
}
