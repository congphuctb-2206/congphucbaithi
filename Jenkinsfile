pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo "Đã lấy code mới nhất"
            }
        }

        stage('Build & Push ECR') {
            steps {
                script {
                    def tag = "${env.BUILD_NUMBER}"
                    def repo = "cp-ecr"
                    def account = "591313757404"
                    def region = "ap-northeast-2"

                    sh "aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${account}.dkr.ecr.${region}.amazonaws.com"
                    sh "docker build -t ${repo}:${tag} ."
                    sh "docker tag ${repo}:${tag} ${account}.dkr.ecr.${region}.amazonaws.com/${repo}:${tag}"
                    sh "docker push ${account}.dkr.ecr.${region}.amazonaws.com/${repo}:${tag}"
                    
                    env.IMAGE_URI = "${account}.dkr.ecr.${region}.amazonaws.com/${repo}:${tag}"
                    echo "Push xong image: ${env.IMAGE_URI}"
                }
            }
        }

        stage('Deploy to ECS') {
            steps {
                script {
                    def family  = "taskcongphuc"     // tên family của bạn
                    def cluster = "cp-cluster"
                    def service = "cp-sv"
                    def region  = "ap-northeast-2"

                    // Lấy task cũ + tạo task mới + thay image (1 lệnh jq duy nhất)
                    sh """
                        aws ecs describe-task-definition --task-definition ${family} --region ${region} --query 'taskDefinition' > old.json

                        cat old.json | jq '{
                            family: .family,
                            networkMode: .networkMode,
                            taskRoleArn: .taskRoleArn,
                            executionRoleArn: .executionRoleArn,
                            containerDefinitions: .containerDefinitions,
                            volumes: (.volumes // []),
                            placementConstraints: (.placementConstraints // []),
                            requiresCompatibilities: (.requiresCompatibilities // ["FARGATE"]),
                            cpu: .cpu,
                            memory: .memory,
                            tags: (.tags // []),
                            runtimePlatform: .runtimePlatform
                        } | .containerDefinitions[0].image = "${env.IMAGE_URI}"' > new-task.json
                    """

                    // Register task mới
                    def taskArn = sh(
                        script: "aws ecs register-task-definition --cli-input-json file://new-task.json --region ${region} --query 'taskDefinition.taskDefinitionArn' --output text",
                        returnStdout: true
                    ).trim()

                    echo "Task Definition mới: ${taskArn}"

                    // Update service
                    sh """
                        aws ecs update-service \
                            --cluster ${cluster} \
                            --service ${service} \
                            --task-definition ${taskArn} \
                            --force-new-deployment \
                            --region ${region}
                    """

                    sh "rm -f old.json new-task.json"
                    echo "DEPLOY XONG 100%! Web sẽ mới trong 1-2 phút"
                }
            }
        }
    }

    post {
        success { echo "CI/CD HOÀN HẢO – BẠN ĐÃ LÀM CHỦ ECS RỒI ĐẤY!" }
        failure { echo "Lỗi gì thì nhắn anh liền nha!" }
    }
}
