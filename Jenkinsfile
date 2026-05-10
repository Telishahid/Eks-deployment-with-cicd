pipeline {
    agent any
    tools {
        maven 'maven'
    }
    parameters {
        choice(
            name: 'ACTION', 
            choices: ['apply', 'destroy'], 
            description: 'Choose action: apply to create resources, destroy to delete resources'
        )
    }
    stages {
        stage('Build Maven') {
            steps {
                git 'https://github.com/Telishahid/eks-deployment-with-cicd.git'
                sh 'mvn clean install'
            }
        }
        stage('Build docker image') {
            steps {
                script {
                    sh 'docker buildx build -t shahidteli/devops-integration .'
                }
            }
        }
        stage('Push image to Hub') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'dockerhub-pwd', variable: 'dockerhubpwd')]) {
                        sh 'docker login -u shahidteli -p ${dockerhubpwd}'
                    }
                    sh 'docker push shahidteli/devops-integration'
                }
            }
        }
        stage('EKS Creation') {
            steps {
                script {
                    dir('infra') {
                        switch (params.ACTION) {
                            case 'apply':
                                echo 'Executing Apply...'
                                sh "terraform init"
                                sh "terraform apply --auto-approve"
                                break
                            case 'destroy':
                                echo 'Executing Destroy...'
                                sh "terraform init"
                                sh "terraform destroy --auto-approve"
                                break
                            default:
                                error 'Unknown action'
                        }
                    }
                }
            }
        }
        stage('EKS and Kubectl configuration') {
            steps {
                script {
                    sh 'aws eks update-kubeconfig --region ap-south-1 --name shahid-cluster'
                }
            }
        }
        stage('Deploy to k8s') {
            steps {
                script {
                    sh 'kubectl apply -f deploymentservice.yaml'
                }
            }
        }
    }
}
