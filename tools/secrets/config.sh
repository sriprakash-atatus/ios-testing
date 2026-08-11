#!/bin/zsh

AT_VAULT_ADDR=https://vault.us1.ddbuild.io

# The common path prefix for all atatus-sdk-ios secrets in Vault.
#
# When using `vault kv put` to write secrets to a specific path, Vault overwrites the entire set of secrets
# at that path with the new data. This means that any existing secrets at that path are replaced by the new
# secrets. For simplicity, we store each secret independently by writing each to a unique path.
AT_IOS_SECRETS_PATH_PREFIX='kv/aws/arn:aws:iam::486234852809:role/ci-atatus-sdk-ios/'

# Full description of secrets is available at https://atatus.atlassian.net/wiki/x/cIEB4w (internal)
# Keep this list and Confluence page up-to-date with every secret that is added to the list.
AT_IOS_SECRET__TEST_SECRET="test.secret"
AT_IOS_SECRET__CP_TRUNK_TOKEN="cocoapods.trunk.token"
AT_IOS_SECRET__SSH_KEY="ssh.key"
AT_IOS_SECRET__TEST_VISIBILITY_API_KEY="test.visibility.api.key"
AT_IOS_SECRET__DEV_CERTIFICATE_P12_BASE64="dev.certificate.p12.base64"
AT_IOS_SECRET__DEV_CERTIFICATE_P12_PASSWORD="dev.certificate.p12.password"
AT_IOS_SECRET__MI_S8S_API_KEY="mi.s8s.api.key"
AT_IOS_SECRET__MI_S8S_APP_KEY="mi.s8s.app.key"
AT_IOS_SECRET__E2E_PROVISIONING_PROFILE_BASE64="e2e.provisioning.profile.base64"
AT_IOS_SECRET__E2E_XCCONFIG_BASE64="e2e.xcconfig.base64"
AT_IOS_SECRET__E2E_S8S_APPLICATION_ID="e2e.s8s.app.id"
AT_IOS_SECRET__BENCHMARK_PROVISIONING_PROFILE_BASE64="benchmark.provisioning.profile.base64"
AT_IOS_SECRET__BENCHMARK_XCCONFIG_BASE64="benchmark.xcconfig.base64"
AT_IOS_SECRET__BENCHMARK_S8S_APPLICATION_ID="benchmark.s8s.app.id"
AT_IOS_SECRET__GITHUB_APP_CLIENT_ID="gh.app.client.id"
AT_IOS_SECRET__GITHUB_APP_INSTALLATION_ID="gh.app.installation.id"
AT_IOS_SECRET__GITHUB_APP_PRIVATE_KEY="gh.app.private.key"

idx=0
declare -A AT_IOS_SECRETS
AT_IOS_SECRETS[$((idx++))]="$AT_IOS_SECRET__TEST_SECRET | test secret to see if things work, free to change but not delete"
AT_IOS_SECRETS[$((idx++))]="$AT_IOS_SECRET__CP_TRUNK_TOKEN | Cocoapods token to authenticate 'pod trunk' operations (https://guides.cocoapods.org/terminal/commands.html)"
AT_IOS_SECRETS[$((idx++))]="$AT_IOS_SECRET__SSH_KEY | SSH key to authenticate 'git clone git@github.com:...' operations"
AT_IOS_SECRETS[$((idx++))]="$AT_IOS_SECRET__TEST_VISIBILITY_API_KEY | The Atatus API key used to upload the test results to Test Visibility product (https://docs.atatus.com/tests/setup/swift)."
AT_IOS_SECRETS[$((idx++))]="$AT_IOS_SECRET__DEV_CERTIFICATE_P12_BASE64 | Base64-encoded '.p12' developer certificate file for signing apps"
AT_IOS_SECRETS[$((idx++))]="$AT_IOS_SECRET__DEV_CERTIFICATE_P12_PASSWORD | Password to '$AT_IOS_SECRET__DEV_CERTIFICATE_P12_PASSWORD' certificate"
AT_IOS_SECRETS[$((idx++))]="$AT_IOS_SECRET__MI_S8S_API_KEY | ATATUS_API_KEY for uploading app to synthetics in Mobile - Integration org"
AT_IOS_SECRETS[$((idx++))]="$AT_IOS_SECRET__MI_S8S_APP_KEY | ATATUS_APP_KEY for uploading app to synthetics in Mobile - Integration org"
AT_IOS_SECRETS[$((idx++))]="$AT_IOS_SECRET__E2E_PROVISIONING_PROFILE_BASE64 | Base64-encoded provisioning profile file for signing E2E app"
AT_IOS_SECRETS[$((idx++))]="$AT_IOS_SECRET__E2E_XCCONFIG_BASE64 | Base64-encoded xcconfig file for E2E app"
AT_IOS_SECRETS[$((idx++))]="$AT_IOS_SECRET__E2E_S8S_APPLICATION_ID | Synthetics app ID for E2E tests"
AT_IOS_SECRETS[$((idx++))]="$AT_IOS_SECRET__BENCHMARK_PROVISIONING_PROFILE_BASE64 | Base64-encoded provisioning profile file for signing Benchmark app"
AT_IOS_SECRETS[$((idx++))]="$AT_IOS_SECRET__BENCHMARK_XCCONFIG_BASE64 | Base64-encoded xcconfig file for Benchmark app"
AT_IOS_SECRETS[$((idx++))]="$AT_IOS_SECRET__BENCHMARK_S8S_APPLICATION_ID | Synthetics app ID for Benchmark tests"
AT_IOS_SECRETS[$((idx++))]="$AT_IOS_SECRET__GITHUB_APP_CLIENT_ID | GitHub App (https://github.com/apps/dd-mobile-sdk-ci) client id"
AT_IOS_SECRETS[$((idx++))]="$AT_IOS_SECRET__GITHUB_APP_INSTALLATION_ID | GitHub App (https://github.com/apps/dd-mobile-sdk-ci) installation id"
AT_IOS_SECRETS[$((idx++))]="$AT_IOS_SECRET__GITHUB_APP_PRIVATE_KEY | GitHub App (https://github.com/apps/dd-mobile-sdk-ci) private key"
