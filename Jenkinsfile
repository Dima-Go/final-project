pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID = credentials('aws_access_key_id')
        AWS_SECRET_ACCESS_KEY = credentials('aws_secret_access_key')
        AWS_REGION = 'us-east-1'
        EKS_CLUSTER = "my-terra-cluster" 
        GIT_REPO = "https://github.com/Dima-Go/final-project.git"
        WORKSPACE_DIR = "/var/lib/jenkins/workspace/repo"
    }

    stages {
        stage('Clone Repository') {
            steps {
                script {
                    sh "git clone $GIT_REPO $WORKSPACE_DIR"
                }
            }
        }

        stage('Configure AWS CLI') {
            steps {
                script {
                    sh '''
                    aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
                    aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
                    aws configure set region $AWS_REGION
                    '''
                }
            }
        }

        stage('Update Kubeconfig') {
            steps {
                script {
                    sh '''
                    aws eks update-kubeconfig --name $EKS_CLUSTER --region $AWS_REGION
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    sh 'kubectl get nodes'  
                    sh 'kubectl apply -f $WORKSPACE_DIR/mysql.yaml'
                    sh 'kubectl apply -f $WORKSPACE_DIR/flask-app.yaml'
                    sh 'kubectl get all'

                }
            }
            
        }
        
    }
}
