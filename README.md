[![tests](https://github.com/tyler36/ddev-tinker/actions/workflows/tests.yml/badge.svg)](https://github.com/tyler36/ddev-tinker/actions/workflows/tests.yml) ![project is maintained](https://img.shields.io/maintenance/yes/2024.svg)

# ddev-tinker <!-- omit in toc -->

- [What is ddev-tinker?](#what-is-ddev-tinker)
- [What is this developer console?](#what-is-this-developer-console)
- [Supported frameworks](#supported-frameworks)
- [Getting started](#getting-started)
- [Usage](#usage)
   - [Arguments](#arguments)

## What is ddev-tinker?

`ddev-tinker` is an addon for DDEV that providers a single command to access a runtime developer console.

This addon enables a new command, `ddev tinker`, that checks which project you are currently in, and runs the correct REPL command for the project.

If you bounce between projects types, this command is really useful.

## What is this developer console?

Both Laravel and Drupal have an interactive debugger & REPL environment for tinkering in PHP. You can test various php statements, resolve services or even query the database!

Both environment's are customized versions of the excellent [PsySh](https://psysh.org/).

Typically, this console is accessed via:

- Laravel: `php artisan tinker`
- Drupal via a Drush: `drush php`

*[REPL]: Read-Evaluation-Print-Loop

## Supported frameworks

This addon current supports the following frameworks:

- [Laravel](https://laravel.com/)
- [Drupal](https://www.drupal.org/) (via [Drush](https://www.drush.org/))

PRs are welcome to add more frameworks.

## Getting started

1. Install the addon

   ```shell
   ddev get tyler36/ddev-tinker
   ```

The addon installs globally and will be available to supported framework after running `ddev start`.

## Usage

To start your framework's REPL environment, simply type the follow:

   ```shell
   ddev tinker
   ```

### Arguments

- `ddev tinker` can accept simple arguments.

   ```shell
   $ ddev tinker 6+8
   14
   ```

- More complex arguments should be wrapped with <kbd>'</kbd>.

  ```php
   $ ddev tinker 'User::first()'
   [!] Aliasing 'User' to 'App\Models\User' for this Tinker session.
   App\Models\User^ {#4400
   ...

   $ ddev tinker 'node_access_rebuild()'
   [notice] Message: Content permissions have been rebuilt.

   $ ddev tinker '$node = \Drupal\node\Entity\Node::load(1); print $node->getTitle();'
   Who Doesn’t Like a Good Waterfall?
  ```

While this might be helpful for a quick one-off command, it's recommend to run `ddev tinker` for tinkering to avoid any Docker connection delays between multiple commands.

Wrapping may also work with <kbd>"</kbd>, depending on the command used. For more consistent results between frameworks and host OS, it is recommended to use <kbd>'</kbd>. See [ddev/ddev#2547](https://github.com/ddev/ddev/issues/2547)

**Contributed and maintained by [@tyler36](https://github.com/tyler36) based on the original [ddev-contrib recipe](https://github.com/ddev/ddev-contrib/tree/master/docker-compose-services/RECIPE) by [@tyler36](https://github.com/tyler36)**
