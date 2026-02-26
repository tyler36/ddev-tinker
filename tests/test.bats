#!/usr/bin/env bats

# Bats is a testing framework for Bash
# Documentation https://bats-core.readthedocs.io/en/stable/
# Bats libraries documentation https://github.com/ztombol/bats-docs

# For local tests, install bats-core, bats-assert, bats-file, bats-support
# And run this in the add-on root directory:
#   bats ./tests/test.bats
# To exclude release tests:
#   bats ./tests/test.bats --filter-tags '!release'
# For debugging:
#   bats ./tests/test.bats --show-output-of-passing-tests --verbose-run --print-output-on-failure

setup() {
  set -eu -o pipefail

  # Override this variable for your add-on:
  export GITHUB_REPO=tyler36/ddev-tinker

  TEST_BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  export BATS_LIB_PATH="${BATS_LIB_PATH}:${TEST_BREW_PREFIX}/lib:/usr/lib/bats"
  bats_load_library bats-assert
  bats_load_library bats-file
  bats_load_library bats-support

  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  export PROJNAME="test-$(basename "${GITHUB_REPO}")"
  mkdir -p ~/tmp
  export TESTDIR=$(mktemp -d ~/tmp/${PROJNAME}.XXXXXX)
  export DDEV_NONINTERACTIVE=true
  export DDEV_NO_INSTRUMENTATION=true
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  run ddev config --project-name="${PROJNAME}" --project-tld=ddev.site
  assert_success
  run ddev start -y
  assert_success
  echo "# ddev started at $(date)" >&3
}

health_checks() {
  run ddev exec "curl -s https://localhost:443/"
  assert_success
}

validate_tinker() {
  # Output should contain outcome
  ddev tinker 'print "tinker working " . 99+1' | grep 'working 100'

  # Manual should exist
  validate_php_manual
}

validate_php_manual() {
  # Manual should exist
  run test -f ${TESTDIR}/.ddev/homeadditions/.local/share/psysh/php_manual.sqlite || (printf "Failed to find manual in ${TESTDIR}\n" && exit 1)
  assert_success
}

teardown() {
  set -eu -o pipefail
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1
  # Persist TESTDIR if running inside GitHub Actions. Useful for uploading test result artifacts
  # See example at https://github.com/ddev/github-action-add-on-test#preserving-artifacts
  if [ -n "${GITHUB_ENV:-}" ]; then
    [ -e "${GITHUB_ENV:-}" ] && echo "TESTDIR=${HOME}/tmp/${PROJNAME}" >> "${GITHUB_ENV}"
  else
    [ "${TESTDIR}" != "" ] && rm -rf "${TESTDIR}"
  fi
}

@test "install from directory" {
  set -eu -o pipefail
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success

  run ddev restart -y
  assert_success
  health_checks
}

@test "Non-English manuals can be installed" {
  set -eu -o pipefail
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success

  run ddev restart -y
  assert_success
  validate_php_manual

  # Grab the size of the file so we can compare it to another the second time.
  EN_SIZE=$(ddev . stat -c%s '~/.local/share/psysh/php_manual.sqlite')

  # Delete the file so we can change the language.
  rm "${TESTDIR}/.ddev/homeadditions/.local/share/psysh/php_manual.sqlite"

  # Change the language and get it again. NOTE: This requires a restart.
  LANG="ja_JP.UTF-8" ddev get-php-manual
  ddev restart
  validate_php_manual

  JA_SIZE=$(ddev . stat -c%s '~/.local/share/psysh/php_manual.sqlite')
  [ $EN_SIZE != $JA_SIZE ]
}

# bats test_tags=release
@test "install from release" {
  set -eu -o pipefail
  echo "# ddev add-on get ${GITHUB_REPO} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${GITHUB_REPO}"
  assert_success

  run ddev restart -y
  assert_success
  health_checks
}

@test "Laravel project type" {
  set -eu -o pipefail
  echo "# ddev add-on get ${DIR} with Laravel project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3

  # Setup a Laravel project
  run ddev config --project-type=laravel --docroot=public --create-docroot --php-version=8.4
  assert_success
  run ddev composer create --prefer-dist --no-install --no-scripts laravel/laravel:12 -y
  assert_success
  run ddev composer install
  assert_success
  run ddev exec "php artisan key:generate"
  assert_success

  # Get addon and test
  run ddev add-on get ${DIR}
  assert_success
  run ddev restart
  assert_success
  run ddev exec "curl -s https://web/ | grep Laravel"
  assert_success
  validate_tinker
}

@test "Drupal 10 project type" {
  set -eu -o pipefail
  echo "# ddev add-on get ${DIR} with Drupal project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3

  # Setup a Drupal 10 project
  run ddev config --project-type=drupal10 --docroot=web --create-docroot
  assert_success
  run ddev composer create drupal/recommended-project:^10 -y
  assert_success
  run ddev composer require drush/drush
  assert_success
  run ddev drush site:install --account-name=admin --account-pass=admin -y
  assert_success

  # Get addon and test
  run ddev add-on get ${DIR}
  assert_success
  run ddev restart
  assert_success
  run ddev exec "curl -s https://web/ | grep Welcome"
  assert_success
  validate_tinker
}

@test "CakePHP 5 project type" {
  set -eu -o pipefail
  run echo "# ddev add-on get ${DIR} with CakePHP project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  assert_success

  # Setup a CakePHP 5 project
  run ddev config --project-type=cakephp --docroot=webroot
  assert_success
  run ddev composer create --prefer-dist --no-interaction cakephp/app:~5.0
  assert_success

  # Get addon and test
  run ddev add-on get ${DIR}
  assert_success
  run ddev restart
  assert_success
  run ddev exec "curl -s https://web/ | grep 'Welcome to CakePHP'"
  assert_success

  # Add REPL. The plugin was shipped with the CakePHP app skeleton before 4.3.
  run ddev composer require --dev cakephp/repl
  assert_success
  run ddev cake plugin load Cake/Repl
  assert_success

  # CakePHP console does not seem to have a "single" command output.
  # Instead, we'll check that the "help" displays as expected to validate.
  ddev tinker --help | grep 'This command provides a REPL'
}
