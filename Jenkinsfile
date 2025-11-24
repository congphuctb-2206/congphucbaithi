pipeline {
    agent any

    stages {
        // ──────────────────────────────────────────────────────────────
        // 1. LẤY CODE MỚI NHẤT TỪ GITHUB (khi bạn push code lên)
        // ──────────────────────────────────────────────────────────────
        stage('Checkout Source Code') {
            steps {
                checkout scm
                echo "Đã lấy code mới nhất từ GitHub"
            }
        }

        // ──────────────────────────────────────────────────────────────
        // 2. BUILD DOCKER IMAGE + ĐẨY LÊN ECR
        //    → Tạo image mới có tag là số build (ví dụ: 25, 26, 27...)
        //    → Đẩy lên kho ECR tên cp-ecr
        // ──────────────────────────────────────────────────────────────
        stage('Build Docker Image & Push to ECR') {
            steps {
                script {
                    def buildTag   = "${env.BUILD_NUMBER}"                  // tag = số lần build
                    def ecrRepo    = "cp-ecr"                               // tên repo ECR của bạn
                    def region     = "ap-northeast-2"                       // region bạn dùng
                    def accountId  = "591313757404"                         // AWS account ID

                    // Đăng nhập ECR
                    sh "aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${accountId}.dkr.ecr.${region}.amazonaws.com"

                    // Build + tag + push image
                    sh "docker build -t ${ecrRepo}:${buildTag} ."
                    sh "docker tag ${ecrRepo}:${buildTag} ${accountId}.dkr.ecr.${region}.amazonaws.com/${ecrRepo}:${buildTag}"
                    sh "docker push ${accountId}.dkr.ecr.${region}.amazonaws.com/${ecrRepo}:${buildTag}"

                    echo "Đã đẩy image thành công: ${ecrRepo}:${buildTag}"
                    env.IMAGE_URI = "${accountId}.dkr.ecr.${region}.amazonaws.com/${ecrRepo}:${buildTag}"
                }
            }
        }

        // ──────────────────────────────────────────────────────────────
        // 3. TRIỂN KHAI LÊN ECS
        //    → Dùng lệnh force-new-deployment → ECS sẽ tự kéo image mới nhất
        //    → Không cần register task definition, không cần jq → đơn giản nhất
        // ──────────────────────────────────────────────────────────────
        stage('Deploy to ECS') {
            steps {
                script {
                    def clusterName = "cp-cluster"     // tên cluster bạn tạo
                    def serviceName = "cp-sv"          // tên service bạn tạo

                    sh """
                        aws ecs update-service \
                            --cluster ${clusterName} \
                            --service ${serviceName} \
                            --force-new-deployment \
                            --region ap-northeast-2
                    """

                    echo "Đã kích hoạt triển khai mới trên ECS"
                    echo "Chờ 1-2 phút là web tự động cập nhật phiên bản mới"
                }
            }
        }
    }

    // Thông báo kết quả cuối cùng
    post {
        success { echo "CI/CD HOÀN TẤT " }
        failure { echo "Có lỗi xảy ra, xem log để sửa" }
    }
}
