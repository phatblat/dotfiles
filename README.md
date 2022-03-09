# phatblat's dotfiles

Shell setup and customization along with various system and app configuration files.

I regularly switch between four different Macs and use this repo to sync terminal and some GUI app configurations across them. Many Stack Overflow answers (usually reworked a bit) have landed here over the years.

This repo lives at the root of my user `$HOME` dir. This confuses some git apps like Tower because I have lots of git repos in subdirectories. But, I prefer to see the dirty and upstream marker changes in the terminal prompt when I'm sitting in my home dir. Otherwise, I forget to commit, push or pull changes.

I started tracking these dotfiles when I was still using Bash. The `.bash_profile` file sourced all `.dotfiles/**/*.sh` files on login, which were split up into topic folders to make them more manageable. I later converted this to [Z shell](http://zsh.sourceforge.net) but the setup was pretty much the same, but used the `.zsh` file extension since the syntax can differ from Bash.

I've now converted over to [Fish shell](https://fishshell.com), so the `.zsh` files will not be updated. I find Fish syntax to be dramatically easier to remember. I love that it's not compatible with other shells which have let compatibility with ancient de facto standards get in the way of progress. Seriously, Fish is to other shells like Git is to SVN.

## Bootstrap

> This bootstrap has not been updated since to switch to Fish. I plan to greatly simplify the process as installing/updating will be a set of normal functions.

The [`bootstrap.sh`](https://github.com/phatblat/dotfiles/blob/main/.dotfiles/install/bootstrap.sh) script is a half-ass attempt at installing these dotfiles into the `$HOME` directory of a freshly minted OS X user. It kinda works and something usually breaks when it's run. But, it usually does most of the work and with a kick or two things are up and running.

Run at your own peril!

```
curl -fsSL https://raw.githubusercontent.com/phatblat/dotfiles/main/.dotfiles/install/bootstrap.sh | sh
```

Really, you should look at that script and laugh at the mess I've created instead of running it and hosing your `$HOME` directory. _You have been warned._ :boom:

## Git

[`.gitconfig`](https://github.com/phatblat/dotfiles/blob/main/.gitconfig) is checked in but I use different `user.email` values on my work and personal Macs. This is accomplished by setting local-only values in the alternate user-global [`~/.config/git/config`](http://git-scm.com/docs/git-config#FILES), but is overridden on an as-needed basis by explicitly setting `user.email` in some repos.

I've crafted a slew of short [aliases](https://github.com/phatblat/dotfiles/blob/main/.dotfiles/git/alias.zsh) for all the commands I use regularly. There's even a fancy experimental [bundle-pull script](https://github.com/phatblat/dotfiles/blob/main/.dotfiles/git/bundle-pull.rb) for quickly syncing a dirty work tree from one Mac to another.

## iOS

There are some fancy functions for easily inspecting, bumping version and releasing an app with a versioned [xcode project](https://github.com/phatblat/dotfiles/blob/main/.dotfiles/xcode/alias.zsh).

## Credit

Inspired by https://github.com/rtomayko/dotfiles

## License

This repo is licensed under the MIT License. See the [LICENSE](LICENSE.md) file for rights and limitations.
