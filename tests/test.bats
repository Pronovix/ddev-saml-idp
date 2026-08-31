#!/usr/bin/env bats

# Bats is a testing framework for Bash
# Documentation https://bats-core.readthedocs.io/en/stable/
# Bats libraries documentation https://github.com/ztombol/bats-docs

setup() {
  set -eu -o pipefail

  # Override this variable for your add-on:
  export GITHUB_REPO=Pronovix/ddev-saml-idp

  TEST_BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  export BATS_LIB_PATH="${BATS_LIB_PATH}:${TEST_BREW_PREFIX}/lib:/usr/lib/bats"
  bats_load_library bats-assert
  bats_load_library bats-file
  bats_load_library bats-support

  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  export PROJNAME="test-$(basename "${GITHUB_REPO}")"
  mkdir -p "${HOME}/tmp"
  export TESTDIR="$(mktemp -d "${HOME}/tmp/${PROJNAME}.XXXXXX")"
  export DDEV_NONINTERACTIVE=true
  export DDEV_NO_INSTRUMENTATION=true
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  mkdir -p web
  run ddev config --project-name="${PROJNAME}" --project-tld=ddev.site --project-type=drupal11 --docroot=web
  assert_success
  run ddev start -y
  assert_success
}

health_checks() {
  # Verify the service is reachable and returns 200 OK with SimpleSAMLphp content
  run curl -sSfLk "https://idp.${PROJNAME}.ddev.site/simplesaml/"
  assert_success
  assert_output --partial "SimpleSAMLphp"
}

teardown() {
  set -eu -o pipefail
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1
  if [ -n "${GITHUB_ENV:-}" ]; then
    [ -e "${GITHUB_ENV:-}" ] && echo "TESTDIR=${HOME}/tmp/${PROJNAME}" >> "${GITHUB_ENV}"
  else
    [ "${TESTDIR}" != "" ] && rm -rf "${TESTDIR}"
  fi
}

@test "install from directory" {
  set -eu -o pipefail
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3

  # Test case 1: settings.php references project.local.settings.php
  mkdir -p web/sites/default
  echo -e "<?php\ninclude 'project.local.settings.php';" > web/sites/default/settings.php

  run ddev add-on get "${DIR}"
  assert_success

  # Verify project.local.settings.php exists and contains the overrides
  assert_file_exists web/sites/default/project.local.settings.php
  run grep -q "BEGIN DDEV SAML IDP OVERRIDES" web/sites/default/project.local.settings.php
  assert_success

  # Clean up and reset for Test case 2: settings.php is empty/generic (no local settings references)
  rm -f web/sites/default/project.local.settings.php
  echo -e "<?php\n// Plain settings file" > web/sites/default/settings.php

  run ddev add-on get "${DIR}"
  assert_success

  # Verify settings.local.php exists and contains the overrides, and settings.php includes settings.local.php
  assert_file_exists web/sites/default/settings.local.php
  run grep -q "BEGIN DDEV SAML IDP OVERRIDES" web/sites/default/settings.local.php
  assert_success
  run grep -q "include __DIR__ . '/settings.local.php';" web/sites/default/settings.php
  assert_success

  # Test case 3: settings.php has a commented-out settings.local.php reference
  rm -f web/sites/default/settings.local.php
  cat <<EOF > web/sites/default/settings.php
<?php
# if (file_exists(\$app_root . '/' . \$site_path . '/settings.local.php')) {
#   include \$app_root . '/' . \$site_path . '/settings.local.php';
# }
EOF

  run ddev add-on get "${DIR}"
  assert_success

  # Verify that settings.local.php exists and contains the overrides
  assert_file_exists web/sites/default/settings.local.php
  run grep -q "BEGIN DDEV SAML IDP OVERRIDES" web/sites/default/settings.local.php
  assert_success

  # Verify that an uncommented include has been successfully appended to settings.php
  run grep -q "include __DIR__ . '/settings.local.php';" web/sites/default/settings.php
  assert_success

  run ddev restart && ddev start --profiles=saml-idp
  assert_success
  health_checks

  # Initialize git repository to test gitignore behavior
  run git init
  assert_success

  # Verify that .ddev/saml-idp/certs/ is ignored by git (added to .gitignore)
  run git check-ignore .ddev/saml-idp/certs/idp.key
  assert_success

  # Verify that certificates are automatically created on container startup
  assert_file_exists .ddev/saml-idp/certs/idp.key
  assert_file_exists .ddev/saml-idp/certs/idp.crt
  assert_file_exists .ddev/saml-idp/certs/sp.key
  assert_file_exists .ddev/saml-idp/certs/sp.crt

  # Test idempotency (restarting the container should not overwrite existing certificates)
  echo "CUSTOM_KEY" > .ddev/saml-idp/certs/idp.key
  run ddev restart -y
  assert_success
  run grep -q "CUSTOM_KEY" .ddev/saml-idp/certs/idp.key
  assert_success

  # Test manual reset behavior (deleting certs and restarting)
  rm -f .ddev/saml-idp/certs/idp.key
  run ddev restart && ddev start --profiles=saml-idp
  assert_success
  assert_file_exists .ddev/saml-idp/certs/idp.key
  run grep -q "CUSTOM_KEY" .ddev/saml-idp/certs/idp.key
  assert_failure

  # Check metadata XML endpoint response headers and content
  run curl -sSfD - -k "https://idp.${PROJNAME}.ddev.site/simplesaml/module.php/saml/idp/metadata"
  assert_success
  # assert_output --partial "Content-Type: application/xml"
  # assert_output --partial "EntityDescriptor"
  assert_output --partial "entityID=\"https://idp.${PROJNAME}.ddev.site/simplesaml/saml2/idp/metadata\""
  assert_output --partial "Location=\"https://idp.${PROJNAME}.ddev.site/simplesaml/module.php/saml/idp/singleSignOnService\""

  # Test update preservation: Modify config and verify it is preserved on re-install
  # Add a custom marker to authsources.php
  echo "// CUSTOM_MARKER_PRESERVED" >> .ddev/saml-idp/config/authsources.php

  # Re-install the add-on
  run ddev add-on get "${DIR}"
  assert_success

  # Verify the custom marker is still present
  run grep "CUSTOM_MARKER_PRESERVED" .ddev/saml-idp/config/authsources.php
  assert_success
}

@test "version control pinning" {
  set -eu -o pipefail
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success

  # Test 1: Override via environment variables in .ddev/.env
  echo "PHP_IMAGE_TAG=8.3" > .ddev/.env
  echo "SSP_VERSION=2.2.0" >> .ddev/.env

  run ddev restart && ddev start --profiles=saml-idp
  assert_success

  # Verify the PHP version is 8.3
  run ddev exec -s saml-idp php -v
  assert_success
  assert_output --partial "PHP 8.3"

  # Verify the SimpleSAMLphp version is 2.2.0
  run ddev exec -s saml-idp grep version /var/www/simplesamlphp/composer.json
  assert_success
  assert_output --partial "2.2.0"

  # Clean up .ddev/.env
  rm -f .ddev/.env

  # Test 2: Override via docker-compose override file
  cat <<EOF > .ddev/docker-compose.version-pinning.yaml
services:
  saml-idp:
    build:
      args:
        PHP_IMAGE_TAG: "8.2"
        SSP_VERSION: "2.2.1"
EOF

  run ddev debug rebuild -s saml-idp && ddev start --profiles=saml-idp
  assert_success

  # Verify the PHP version is 8.2
  run ddev exec -s saml-idp php -v
  assert_success
  assert_output --partial "PHP 8.2"

  # Verify the SimpleSAMLphp version is 2.2.1
  run ddev exec -s saml-idp grep version /var/www/simplesamlphp/composer.json
  assert_success
  assert_output --partial "2.2.1"

  # Clean up override file
  rm -f .ddev/docker-compose.version-pinning.yaml
}

@test "always start persistent configuration" {
  set -eu -o pipefail
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success

  # Plain restart without profile flags should not start saml-idp by default
  run ddev restart -y
  assert_success
  run ddev exec -s saml-idp echo "running"
  assert_failure

  # Override profile constraint using Docker Compose !reset tag in override file
  # (using underscore ensures the override sorts and loads after docker-compose.saml-idp.yaml)
  cat <<EOF > .ddev/docker-compose.saml-idp_enable.yaml
services:
  saml-idp:
    profiles: !reset []
EOF

  # Plain restart should now automatically start saml-idp without --profiles flag
  run ddev restart -y
  assert_success
  health_checks
  run ddev exec -s saml-idp echo "running"
  assert_success
  assert_output --partial "running"

  # Clean up override file
  rm -f .ddev/docker-compose.saml-idp_enable.yaml
}

# bats test_tags=release
@test "install from release" {
  set -eu -o pipefail
  echo "# ddev add-on get ${GITHUB_REPO} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${GITHUB_REPO}"
  assert_success
  run ddev restart && ddev start --profiles=saml-idp
  assert_success
  health_checks
}
