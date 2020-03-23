Workflow for building the Cardano (Haskell) node and related components
=======================================================================

The purpose of this repository is to provide a convenient workflow *for
developers working on Cardano* to (re)build any or all of the components.

This developer workflow is **not intended to provide reprodcible builds** nor
to replace the scheme used for CI. If you want to build the latest released
version of `cardano-node`, then this is not the repository you are looking for.
For that, just build from within that repository, which contain reproducible
snapshots of all dependencies.

The intention of this repository is for developers working on Cardano to gain
some of the benefits of a mono-repo while keeping the multi-repo approach.
It makes it easier and quicker to check if downstream components are affected by
a change in a component being worked on. For example, while working on the
cardano ledger library it is possible to rebuild (and retest) the node, proxy
and explorer to check if they also need adjustments.


Approach
--------

The `cardano-repo-tool` is used to set up and maintain checkouts of all the
required Cardano repositories.

A top level `cabal.project` file is used to allow building any or all
components using `cabal` (version 3.0 or later). All builds must be done from
this top level directory.


Getting started
---------------

Make sure you have `cabal` version 3.0 or later installed
```
$ cabal --version
cabal-install version 3.0.0.0
compiled using version 3.0.0.0 of the Cabal library 
```

Clone this repository, if you have not done so already:
```
$ git clone git@github.com:input-output-hk/cardano-haskell.git
```

Get the submodule (for the cardano-repo-tool)
```
$ cd cardano-haskell/
$ git submodule update --init
```

Now build and install the cardano-repo-tool so it ends up on your $PATH
```
$ cd cardano-repo-tool
$ cabal install
```

Check that your `cabal` and `$PATH` configuration were set up right so that the
tool was installed in an accessible location
```
$ cardano-repo-tool --version
```

If your environment was not set up right, try either:

1. adjusting your `$PATH` (in `~/.bashrc` or equivalent) to include
   `~/.cabal/bin`

2. adjust your `~/.cabal.config` to set the `installdir` to a location that is
   already on your `$PATH` such as `/home/yourusername/bin` or 
   `/home/yourusername/.local/bin`.

And then install again.

Go back to the top level `cardano-haskell` repository
```
cd ..
```

Now that the `cardano-repo-tool` is installed, we can use it to clone all the
other necessary repositories
```
$ cardano-repo-tool clone-repos
```

This will make fresh clones of all the repositories. If you want to reuse any
of your existing checkouts then, before running the
`cardano-repo-tool clone-repos` command, simply `mv` them into this top level
repository under the expected name. Use `cardano-repo-tool list-repos` to see
the full list of repos and their local names. The `clone-repos` sub-command
will skip any that are already present, so it is always safe to run it again.


Repository status
-----------------

The `cardano-repo-tool clone-repos` command checks out the latest version of
the master branch of each repository.

You can see the status of all the repositories using the command
```
$ cardano-repo-tool repo-status
```

There are also commands to update indivdual or all repos (and rebase if there
are local patches)
```
$ cardano-repo-tool update-repos
```
or for a single repo, e.g. cardano-node
```
$ cardano-repo-tool update-repo -r cardano-node
```
This is equivalent to using `git pull --rebase` within the individual
repositories.

Note that this does not change branch. You can change branch via the normal
git commands. You may well want to be on master for most repositories but on a
feature branch for one or more repositories. Use
`cardano-repo-tool repo-status` to help you keep track.


Repository combinations
-----------------------

The combination of the lastest version of master of all repositories is not
guaranteed to build at all times.

Depending on what you are doing you will want to select some appropriate
combination of commits for each repository.

If you are building the top level node for example, you will want to use the
commit hashes from the `cardano-node/cabal.project` file. There is no tool
automation for this, you simply have to `cd` into the directories for the
repositories and use
```
$ git reset --hard $the_right_big_long_git_commit_hash
```

If you are working on a specific component, then checkout the appropriate
feature branch and use the commit hashes from the `cabal.project` file from
that component.

If you are updating dependencies then of course you will want to update to the
latest master branch of the dependencies, and perhaps also the top level
components such as the node, proxy and explorer.


Configuring the build
---------------------

Once you have the appropriate combination of repository commits for your task
then you can build any or all components from the top level.

You must build the components from the top level directroy, since each
repository also has its own local `cabal.project` file.

The recommened workflow is to use multiple terminals (windows or tabs), one
at the top level directory for building (or `cabal repl` or `cabal test`) and
others in the appropriate sub-directories for editing and git operations.

First get a recent copy of the hackage package index
```
$ cabal update
```
If so desired, you can freeze to a specific timestamp of the hackage index.

Next, set up any appropriate local configuration, e.g.
```
$ cabal configure --with-compiler ghc-8.6.5 -O0
```
This selects GHC version 8.6.5, which is expected to be found on the `$PATH`
literally as `ghc-8.6.5`. If you want to try a different GHC version or your GHC is installed not
on the `$PATH` then simply pass the full path to the compiler binary.

It also selects no optimisation, which is often the appropriate choice during
development since it significantly reduces rebuild times. Of course for
benchmarking this would not be the appropriate choice.

If you want a profiled build, select that at this stage
```
$ cabal configure --with-compiler ghc-8.6.5 -O --enable-profiling
```

You can also manually set these local options by editing the
`cabal.project.local` file. The `cabal configure` command is simply a
convenience for overwriting the `cabal.project.local` with new settings.

The `cabal configure` command also runs the solver to select dependencies and
check that the constraints of all components can be satisfied.

At any time you can also run
```
cabal build all --dry-run
```
to see the current build status and what would be built. If necessary this will
re-run the solver if any configuration changed.

For the very first build a lot of dependencies will have to be built and this
will take some time. Later builds will be much faster since cabal is very
careful about caching. For the first build try:
```
$ cabal build all -j4 --keep-going
$ cabal build all --dry-run
```
The `-j4` says build using 4 cores. Adjust as approprite for your system. The
`--keep-going` tells cabal to keep building other components if possible,
rather than stopping as soon as any single package fails to build. The second
command will report any remaining packges that failed to build (or depended
on packages that failed).


System setup
------------

It is possible that `cabal configure` will fail due to missing system
libraries. Cardano depends on numerous system libraries including openssl
and systemd (on Linux).

For example, consider the following output from `cabal configure`:
```
Resolving dependencies...
cabal: Could not resolve dependencies:
[__0] trying: cardano-binary-1.5.0 (user goal)
[__1] trying: base-4.12.0.0/installed-4.1... (dependency of cardano-binary)
[__2] trying: lobemo-scribe-systemd-0.1.0.0 (user goal)
[__3] next goal: libsystemd-journal (dependency of lobemo-scribe-systemd)
[__3] rejecting: libsystemd-journal-1.4.4 (conflict: pkg-config package
libsystemd==209 || >209, not found in the pkg-config database)
```
As the error message says, `libsystemd` is not in the system's pkg-config
database of registered system libraries. This can be resolved by installing
it using your system's package manager. For example on Fedora-based Linux
systems that would be
```
sudo dnf install systemd-devel
```
or the appropriate equivalent command on Debian-based or other systems.

Known packages needed on Fedora-based systems:
 * `libpq-devel`
 * `openssl-devel`
 * `systemd-devel`


Building components
-------------------

From the top level directory (i.e. this repository), you can build individual
components, e.g.
```
$ cabal build cardano-node
```

You can give package names, component names, or directories.

Since the top level `cabal.project` specifies to build tests for all
components then by default asking to build a component will also build
the tests.

You can also build specific components, e.g.
```
$ cabal build exe:cardano-node
```
or categories of component
```
$ cabal build cardano-node:tests
```

You can also build everything
```
cabal build all -j4
```

You can see what would be built by adding `--dry-run`
```
$ cabal build cardano-node --dry-run
```

You can run `ghci` for any component too
```
$ cabal repl ouroboros-network:tests
```

You can also run test suites
```
$ cabal test --test-show-details=direct 
```
