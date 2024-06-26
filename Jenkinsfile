node {

    stage('Clone Repository') {
        checkout scm
    }

    stage('Checkov Scan') {
       sh '''
            export CHECKOV_OUTPUT_CODE_LINE_LIMIT=100
            SKIPS=$(cat 'tf/.checkovignore.json' | jq -r 'keys[]' | sed 's/$/,/' | tr -d '\n' | sed 's/.$//')
            [ ! -d "checkov_venv" ] && python3 -m venv checkov_venv
            . checkov_venv/bin/activate
            pip install checkov
            checkov -d ./tf --skip-check $SKIPS --skip-path tf/archive
            deactivate
        '''
    }

    stage('Apply Account Terraform') {
        sh '''
            pushd tf/account
            terraform init -backend-config=./env/dev/backend.config -reconfigure
            terraform apply -var-file=./env/dev/dev.tfvars -lock=false -auto-approve
            popd
        '''
    }

    stage('Apply Workspace Terraform') {
        sh '''
            pushd tf/workspace
            terraform init -backend-config=./env/dev/backend.config -reconfigure
            terraform apply -var-file=./env/dev/dev.tfvars -lock=false -auto-approve
            popd
        '''
    }

}