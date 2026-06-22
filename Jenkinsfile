pipeline {
    agent any

    environment {
        PROJECT_DIR = 'C:/Users/Mekin.Jemal/OneDrive - Safaricom Ethiopia/Desktop/Safaricom/DA'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out repository'
            }
        }

        stage('Verify Environment') {
            steps {
                bat "cd /d %PROJECT_DIR% && if exist .env (echo .env found) else (echo .env not found)"
                bat "cd /d %PROJECT_DIR% && if exist .venv\\Scripts\\python.exe (echo venv found) else (echo venv missing)"
            }
        }

        stage('Install Dependencies') {
            steps {
                bat "cd /d %PROJECT_DIR% && .venv\\Scripts\\python -m pip install -r requirements.txt"
            }
        }

        stage('Run Pipeline') {
            steps {
                bat "cd /d %PROJECT_DIR% && .venv\\Scripts\\python run_pipeline.py"
            }
        }

        stage('Archive Outputs') {
            steps {
                archiveArtifacts artifacts: 'outputs/**, DAILY_REGIONAL_REPORT.xlsx', allowEmptyArchive: true
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished.'
        }
        failure {
            echo 'Pipeline failed. Check console output.'
        }
    }
}