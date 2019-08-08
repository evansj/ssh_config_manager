# ssh Config Manager

Copyright (c) 2019 Jon Evans

Designed for macOS, this utility will automatically rebuild your `~/.ssh/config` file from a set of `.conf` files in a directory, whenever one of them changes. This means that you can split up your ssh configuration into multiple files (maybe one per project) and potentially share them with other team members.

## Instalation

**Take a backup of your `~/.ssh` directory before you start.**

Copy `build-config.sh` to `~/.ssh` and make sure it's executable.

Edit the file `info.evansweb.ssh-config-manager.plist` and change `USERNAME` in the `ProgramArguments` and `WatchPaths` sections into your username. Then copy the file to `~/Library/LaunchAgents` and run the following command to register it:

    # You did take a backup of your ~/.ssh directory, right?
    launchctl load -w ~/Library/LaunchAgents/info.evansweb.ssh-config-manager.plist

The script will make a backup of `~/.ssh/config` the first time it is run, but you also should have already done this yourself to make sure.

## Usage

Whenever you edit a `.conf` file beneath `~/.ssh/config`, macOS will invoke the `build-config.sh` script. The script will gather all of the `.conf` files and write them into `~/.ssh/config`.

This means that you can split your config files however suits you, for example one per project.

## Tips

The files are added in alphabetical order within each directory. If you want to influence the order you can prefix the filenames with numbers, e.g.

    10-project_x.conf
    20-another_project.conf

`ssh` applies config settings in the order they are presented in the file. You might like to have a `99-default.conf` file with defaults for every host, which will get added to the end of the file.

    Host *
        User YOUR-USUAL-USERNAME
        UseKeychain yes
        Compression yes
        ForwardX11 no
        ServerAliveInterval 10
        ServerAliveCountMax 3
        ControlMaster auto
        ControlPath ~/.ssh/master-%r@%h:%p
        ControlPersist 300
        # etc. etc.

## First Run

The script checks for the existence of the file `~/.ssh/.build-config-first-run`. This is how it determines if it's the first time it has been run.

The first time the script runs, it will do the following:

* Take a backup of `~/.ssh/config` to `~/.ssh/config-CURRENT-TIMESTAMP`
* Create the directory `~/.ssh/config.d` if it doesn't already exist, and add a README file there
* Copy `~/.ssh/config` to `~/.ssh/config.d/00-general.conf` if no existing `.conf` files were found in that directory

## Dependencies

All utilities used in the script are already installed as part of macOS.
