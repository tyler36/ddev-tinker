setup() {
  set -eu -o pipefail
  export DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)/.."
  export TESTDIR=~/tmp/ddev-tinker
  mkdir -p $TESTDIR
  export PROJNAME=ddev-tinker
  export DDEV_NON_INTERACTIVE=true
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1 || true
  cd "${TESTDIR}"
}

health_checks() {
  ddev exec "curl -s https://localhost:443/"
}

validate_tinker() {
  # Output should contain outcome
  ddev tinker 'print "tinker working " . 99+1' | grep 'working 100'
  # Manual should exist
  validate_php_manual
}

validate_php_manual() {
  # Manual should exist
  test -f ${TESTDIR}/.ddev/homeadditions/.local/share/psysh/php_manual.sqlite || (printf "Failed to find manual in ${TESTDIR}\n" && exit 1)
}

teardown() {
  set -eu -o pipefail
  cd ${TESTDIR} || (printf "unable to cd to ${TESTDIR}\n" && exit 1)
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1
  [ "${TESTDIR}" != "" ] && rm -rf ${TESTDIR}
}

@test "install from directory" {
  set -eu -o pipefail
  cd ${TESTDIR}
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev config --project-name=${PROJNAME}
  ddev start -y >/dev/null
  ddev add-on get ${DIR}
  ddev restart
  health_checks
}

@test "Non-English manuals can be installed" {
  set -eu -o pipefail
  cd ${TESTDIR}
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev config --project-name=${PROJNAME}
  ddev add-on get ${DIR}
  ddev restart
  validate_php_manual

  # Grab the size of the file so we can compare it to another the second time.
  EN_SIZE=$(ddev . stat -c%s '~/.local/share/psysh/php_manual.sqlite')

  # Delete the file so we can change the language.
  rm "${TESTDIR}/.ddev/homeadditions/.local/share/psysh/php_manual.sqlite"

  # Change the language and get it again. NOTE: This requires a restart.
  LANG="ja_JP.UTF-8" ddev add-on get-php-manual
  ddev restart
  validate_php_manual

  JA_SIZE=$(ddev . stat -c%s '~/.local/share/psysh/php_manual.sqlite')
  [ $EN_SIZE != $JA_SIZE ]
}

@test "install from release" {
  set -eu -o pipefail
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  echo "# ddev add-on get tyler36/ddev-tinker with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev config --project-name=${PROJNAME}
  ddev start -y >/dev/null
  ddev add-on get tyler36/ddev-tinker
  ddev restart >/dev/null
  health_checks
}

@test "Laravel project type" {
  set -eu -o pipefail
  cd ${TESTDIR}
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  # Setup a Laravel project
  ddev config --project-name=${PROJNAME} --project-type=laravel --docroot=public --create-docroot --php-version=8.1
  ddev composer create --prefer-dist --no-install --no-scripts laravel/laravel:10 -y
  ddev composer install
  ddev exec "php artisan key:generate"
  # Get addon and test
  ddev add-on get ${DIR}
  ddev restart
  ddev exec "curl -s https://localhost:443/ | grep Laravel"
  validate_tinker
}

@test "Drupal 10 project type" {
  set -eu -o pipefail
  cd ${TESTDIR}
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  # Setup a Drupal 10 project
  ddev config --project-type=drupal10 --docroot=web --create-docroot
  ddev composer create drupal/recommended-project:^10 -y
  ddev composer require drush/drush
  ddev drush site:install --account-name=admin --account-pass=admin -y
  # Get addon and test
  ddev add-on get ${DIR}
  ddev restart
  ddev exec "curl -s https://localhost:443/ | grep Welcome"
  validate_tinker
}

@test "CakePHP 5 project type" {
  set -eu -o pipefail
  cd ${TESTDIR}
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  # Setup a CakePHP 5 project
  ddev config --project-type=cakephp --docroot=webroot
  ddev composer create --prefer-dist --no-interaction cakephp/app:~5.0

  # Get addon and test
  ddev add-on get ${DIR}
  ddev restart
  ddev exec "curl -s https://localhost:443/ | grep 'Welcome to CakePHP'"

  # Add REPL. The plugin was shipped with the CakePHP app skeleton before 4.3.
  ddev composer require --dev cakephp/repl
  ddev cake plugin load Cake/Repl

  # CakePHP console does not seem to have a "single" command output.
  # Instead, we'll check that the "help" displays as expected to validate.
  ddev tinker --help | grep 'This command provides a REPL'
}
