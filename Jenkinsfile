pipeline {
    agent any

    environment {
        AWS_REGION   = 'us-east-1'
        ECR_REPO     = '586794450782.dkr.ecr.us-east-1.amazonaws.com/my-webapp'
        ECR_IMAGE    = "${ECR_REPO}:latest"
        CLUSTER_NAME = 'capstone-eks'
    }

    triggers {
        githubPush()
    }

    stages {
        stage('Build and Push to ECR') {
            steps {
                withAWS(credentials: 'aws-cred', region: "${AWS_REGION}") {
                    sh '''
                        echo "Checking AWS identity..."
                        aws sts get-caller-identity

                        echo "Logging into Amazon ECR..."
                        aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO

                        echo "Building Docker image..."
                        docker build -t $ECR_IMAGE .

                        echo "Pushing Docker image to ECR..."
                        docker push $ECR_IMAGE

                        echo "Cleaning up local images..."
                        docker rmi $ECR_IMAGE || true
                    '''
                }
            }
        }

        stage('Deploy with Helm to EKS') {
            steps {
                withAWS(credentials: 'aws-cred', region: "${AWS_REGION}") {
                    sh '''
                        echo "Checking AWS identity..."
                        aws sts get-caller-identity

                        echo "Updating kubeconfig for EKS..."
                        aws eks --region $AWS_REGION update-kubeconfig --name $CLUSTER_NAME

                        echo "Deploying with Helm..."
                        helm upgrade --install web-app . --namespace default \
                            --set image.repository=586794450782.dkr.ecr.us-east-1.amazonaws.com/my-webapp \
                            --set image.tag=latest \
                            --storage configmap
                    '''
                }
            }
        }
    }
}
