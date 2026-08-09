pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = '453456680669'

        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

        FRONTEND_REPOSITORY = 'jenkins-ecs-fullstack-dev-frontend'
        BACKEND_REPOSITORY  = 'jenkins-ecs-fullstack-dev-backend'

        ECS_CLUSTER = 'jenkins-ecs-fullstack-dev-cluster'

        FRONTEND_SERVICE = 'jenkins-ecs-fullstack-dev-frontend-service'
        BACKEND_SERVICE  = 'jenkins-ecs-fullstack-dev-backend-service'

        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    options {
        disableConcurrentBuilds()
        timestamps()
    }

    stages {
        stage('Checkout Source Code') {
            steps {
                checkout scm
            }
        }

        stage('Verify AWS Identity') {
            steps {
                sh '''
                    aws sts get-caller-identity
                '''
            }
        }

        stage('Login to Amazon ECR') {
            steps {
                sh '''
                    aws ecr get-login-password --region ${AWS_REGION} \
                    | docker login \
                    --username AWS \
                    --password-stdin ${ECR_REGISTRY}
                '''
            }
        }

        stage('Build Docker Images') {
            steps {
                sh '''
                    docker build \
                    -t ${FRONTEND_REPOSITORY}:${IMAGE_TAG} \
                    ./frontend

                    docker build \
                    -t ${BACKEND_REPOSITORY}:${IMAGE_TAG} \
                    ./backend
                '''
            }
        }

        stage('Tag Docker Images') {
            steps {
                sh '''
                    docker tag \
                    ${FRONTEND_REPOSITORY}:${IMAGE_TAG} \
                    ${ECR_REGISTRY}/${FRONTEND_REPOSITORY}:${IMAGE_TAG}

                    docker tag \
                    ${FRONTEND_REPOSITORY}:${IMAGE_TAG} \
                    ${ECR_REGISTRY}/${FRONTEND_REPOSITORY}:latest

                    docker tag \
                    ${BACKEND_REPOSITORY}:${IMAGE_TAG} \
                    ${ECR_REGISTRY}/${BACKEND_REPOSITORY}:${IMAGE_TAG}

                    docker tag \
                    ${BACKEND_REPOSITORY}:${IMAGE_TAG} \
                    ${ECR_REGISTRY}/${BACKEND_REPOSITORY}:latest
                '''
            }
        }

        stage('Push Images to Amazon ECR') {
            steps {
                sh '''
                    docker push \
                    ${ECR_REGISTRY}/${FRONTEND_REPOSITORY}:${IMAGE_TAG}

                    docker push \
                    ${ECR_REGISTRY}/${FRONTEND_REPOSITORY}:latest

                    docker push \
                    ${ECR_REGISTRY}/${BACKEND_REPOSITORY}:${IMAGE_TAG}

                    docker push \
                    ${ECR_REGISTRY}/${BACKEND_REPOSITORY}:latest
                '''
            }
        }
stage('Approve Deployment') {
    steps {
        timeout(time: 60, unit: 'MINUTES') {
            input message: "Deploy build ${BUILD_NUMBER} to Amazon ECS?",
                  ok: 'Deploy'
        }
    }
}
        stage('Deploy Frontend to ECS') {
            steps {
                sh '''
                    aws ecs update-service \
                    --cluster ${ECS_CLUSTER} \
                    --service ${FRONTEND_SERVICE} \
                    --force-new-deployment \
                    --region ${AWS_REGION}
                '''
            }
        }

        stage('Deploy Backend to ECS') {
            steps {
                sh '''
                    aws ecs update-service \
                    --cluster ${ECS_CLUSTER} \
                    --service ${BACKEND_SERVICE} \
                    --force-new-deployment \
                    --region ${AWS_REGION}
                '''
            }
        }

        stage('Wait for ECS Deployment') {
            steps {
                sh '''
                    aws ecs wait services-stable \
                    --cluster ${ECS_CLUSTER} \
                    --services ${FRONTEND_SERVICE} ${BACKEND_SERVICE} \
                    --region ${AWS_REGION}
                '''
            }
        }
    }

    post {
        success {
            echo 'Frontend and backend were successfully deployed to Amazon ECS.'
        }

        failure {
            echo 'The Jenkins deployment pipeline failed. Review the console output.'
        }

        always {
            sh '''
                docker image prune -f || true
            '''
            cleanWs()
        }
    }
}