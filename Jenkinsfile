pipeline {
    agent any

    environment {
        ANDROID_HOME = '/Users/shaikmohamedimran/Library/Android/sdk'
        PATH = "/Users/shaikmohamedimran/.maestro/bin:/Users/shaikmohamedimran/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/tools:${ANDROID_HOME}/emulator:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        APP_ID = 'org.digitalgreen.farmer.chat'
        DEVICE = 'emulator-5554'
        AVD_NAME = 'Pixel_7_Pro'
    }

    triggers {
        cron('30 18 * * *') // 12:00 AM IST nightly
    }

    options {
        timeout(time: 90, unit: 'MINUTES')
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    stages {
        stage('Start Emulator') {
            steps {
                script {
                    def running = sh(script: "adb devices | grep -q emulator-5554", returnStatus: true)
                    if (running != 0) {
                        echo 'Starting emulator in headless mode...'
                        sh '''
                            nohup $ANDROID_HOME/emulator/emulator -avd $AVD_NAME -no-window -no-audio -no-boot-anim -gpu host &
                            adb wait-for-device
                            adb shell 'while [ -z $(getprop sys.boot_completed) ]; do sleep 2; done;'
                            sleep 10
                        '''
                        echo 'Emulator booted.'
                    } else {
                        echo 'Emulator already running.'
                    }
                }
            }
        }

        stage('Verify Connectivity') {
            steps {
                sh 'adb shell "ping -c 2 -W 3 8.8.8.8"'
                echo 'Internet connectivity verified.'
            }
        }

        stage('Configure Device') {
            steps {
                sh "adb shell pm grant ${APP_ID} android.permission.ACCESS_FINE_LOCATION 2>/dev/null || true"
                sh "adb shell pm grant ${APP_ID} android.permission.ACCESS_COARSE_LOCATION 2>/dev/null || true"
                sh "adb shell pm grant ${APP_ID} android.permission.CAMERA 2>/dev/null || true"
                sh "adb shell pm grant ${APP_ID} android.permission.RECORD_AUDIO 2>/dev/null || true"
                sh 'adb shell settings put global window_animation_scale 0'
                sh 'adb shell settings put global transition_animation_scale 0'
                sh 'adb shell settings put global animator_duration_scale 0'
                sh 'adb shell settings put secure stylus_handwriting_enabled 0 2>/dev/null || true'
                sh 'adb shell settings put secure show_stylus_handwriting_intro 0 2>/dev/null || true'
                sh 'adb forward tcp:7001 tcp:7001'
            }
        }

        stage('Run Test Suite') {
            steps {
                sh 'chmod +x scripts/run_all.sh'
                sh 'bash scripts/run_all.sh'
            }
        }
    }

    post {
        always {
            script {
                def reportDir = sh(script: "ls -td reports/*/ 2>/dev/null | head -1", returnStdout: true).trim()
                if (reportDir) {
                    publishHTML(target: [
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: reportDir,
                        reportFiles: 'report.html',
                        reportName: 'Maestro Test Report',
                        reportTitles: 'FarmerChat Test Report',
                        includes: '**/*'
                    ])

                    archiveArtifacts artifacts: "${reportDir}**/*", allowEmptyArchive: true
                }
            }
        }
        failure {
            script {
                echo 'Tests failed. Check the Maestro Test Report for details.'
            }
        }
    }
}
