pipeline {
    agent {
        docker { image 'python:3.11-slim' }
    }

    environment {
        DBT_PROFILES_DIR = "${env.WORKSPACE}/profiles"
    }

    options {
        timeout(time: 20, unit: 'MINUTES')
        timestamps()
    }

    stages {
        stage('Install') {
            steps {
                sh 'pip install --upgrade pip'
                sh 'pip install -r requirements-dev.txt'
            }
        }

        stage('Lint') {
            parallel {
                stage('ruff') { steps { sh 'ruff check spark scripts airflow' } }
                stage('yamllint') { steps { sh 'yamllint .' } }
                stage('validate-json') {
                    steps {
                        sh 'python -c "import json,glob; [json.load(open(f)) for f in glob.glob(\'step_functions/*.asl.json\')]"'
                        sh 'python -c "import json,glob; [json.load(open(f)) for f in glob.glob(\'control_m/jobs/*.json\')]"'
                    }
                }
            }
        }

        stage('dbt build') {
            steps {
                sh 'dbt debug --target ci'
                sh 'dbt deps'
                sh 'dbt seed --target ci --full-refresh'
                sh 'dbt run  --target ci'
                sh 'dbt test --target ci'
            }
        }
    }
}
