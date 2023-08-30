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
  echo "# ddev get ${DIR} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev config --project-name=${PROJNAME}
  ddev start -y >/dev/null
  ddev get ${DIR}
  ddev restart
  health_checks
}

@test "install from release" {
  set -eu -o pipefail
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  echo "# ddev get tyler36/ddev-tinker with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev config --project-name=${PROJNAME}
  ddev start -y >/dev/null
  ddev get tyler36/ddev-tinker
  ddev restart >/dev/null
  health_checks
}

@test "Laravel project type" {
  set -eu -o pipefail
  cd ${TESTDIR}
  echo "# ddev get ${DIR} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  # Setup a Laravel project
  ddev config --project-name=${PROJNAME} --project-type=laravel --docroot=public --create-docroot --php-version=8.1
  ddev composer create --prefer-dist --no-install --no-scripts laravel/laravel:10 -y
  ddev composer install
  ddev exec "php artisan key:generate"
  # Get addon and test
  ddev get ${DIR}
  ddev restart
  health_checks
  validate_tinker
}

@test "Drupal 10 project type" {
  set -eu -o pipefail
  cd ${TESTDIR}
  echo "# ddev get ${DIR} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  # Setup a Drupal 10 project
  ddev config --project-type=drupal10 --docroot=web --create-docroot
  ddev composer create drupal/recommended-project:^10 -y
  ddev composer require drush/drush
  ddev drush site:install --account-name=admin --account-pass=admin -y
  # Get addon and test
  ddev get ${DIR}
  ddev restart
  health_checks
  validate_tinker
}
