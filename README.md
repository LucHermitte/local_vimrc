local_vimrc
===========

Vim plugin that adds the support of per project/tree configuration plugins.

## Purpose

This plugin presents a solution to Yakov Lerner's question on Vim ML.
It searches for `_vimrc_local.vim` files in the parents directories and
sources the one found.

#### The Initial Question was:
> Is it possible, after sourcing ~/.exrc, to traverse from `$HOME` down to cwd,
> and source `.exrc` from every directory if present ?
> (And if cwd is not under `$HOME,` just source `~/.exrc)`.
> What do I put into .vimrc to do this ?
> 
> Example: current dir is `~/a/b/c`. Files are sourced in this order:
> ~/.exrc, then ~/a/.exrc, `~/a/b/.exrc`, `~/a/b/c/.exrc`.
> No messages if some of `.exrc` does not exist.


## Requirements / Installation

Nothing special is required, except vim v6.0 or later.

To install this plugin, either drop the plugin file into your
`$HOME/.vim/plugin` directory (`$HOME/vimfiles/plugin` under Windows), or
install it with your preferred plugin manager.

## Usage

Drop a `_vimrc_local.vim` file into any project root directory, and write it
exactly as you would have written a ftplugin. 

### `_vimrc_local.vim` content

In other words. The _project_ file is expected to be loaded (/sourced)
every time you enter a buffer that corresponds to a file under the project root
directory.

As a consequence, you'll may want to prevent multiple executions of parts the
sourced file: almost everything shall remain identical and shall not need to
be reset. However some plugins, like a.vim, rely on global variables to tune
their behaviour. The settings (global variables) related to those plugins will
require you update their setting every time -- if you expect to have settings
that differ from a project to the other.  

For your project settings prefer buffer-local mappings (`:h :map-<buffer>`),
abbreviations(`:h :abbreviate-<buffer>`), commands (`:h :command-buffer`),
menus (see my fork of buffer-menu), settings (`:h :setlocal`), and variables
(`:h local-variable`).

N.B.: if you are a plugin writer that want to support configuration variables
that'll dynamically adapt to the current project settings, have a look at my
[`lh#option#get()`](http://code.google.com/p/lh-vim/wiki/lhVimLib) and
[`lh#dev#option#get()`](http://code.google.com/p/lh-vim/source/browse/dev/trunk)
functions.

## Options

The behaviour of this plugin can be tuned with the following options:

- `g:local_vimrc` variable specifies the filename to be searched. The default
  is `_vimrc_local.vim`

## Other Features

### Per-project settings and Template Expander Plugins
Sometimes we want to set variables (like a project source directory, or
specific template files that override the default project file headers) before
other plugins are triggered.  
The typical use case will be from the shell:
```
# There is _vimrc_local.vim file in /path/to/myproject/
cd /path/to/myproject/submodule42
gvim foobar.h
```

In order to use `myproject` settings (naming styles, header guards naming
policy, ...), the `vimrc_local` file need to be sourced before any template
file is expanded. 
This plugin provides the `:SourceLocalVimrc` command for this purpose.

### Automatic increment of `vimrc_local` script version number
When saved, if the `vimrc_local` script has a `s:k_version` variable, it will be
incremented automatically. This variable is meant to avoid multiple inclusions 
of the script for a given buffer. New `vimrc_local` scripts created with the
help of the templates provided with my
[mu-template](http://code.google.com/p/lh-vim/wiki/muTemplate) fork are making
use of this variable.


## Elsewhere


There exist many plugins with the same name or even the same purpose. I may add
a link to them ... later. 

## TO DO

- Document how `local_vimrc` can be used with
  [BuildToolsWrapper](http://code.google.com/p/lh-vim/wiki/BTW) to support
  CMake based projects.
- Document how to mix definitions that need to be source once only, and `local_vimrc`
- Support the definition of the project configuration in files put a separate
  directory (in order to help versioning them).
- Add option to stop looking at `$HOME` or elsewhere (`[bg]:lv_stop_at` : string,
  default `$HOME`) 
- Support List of possible names for `vimrc_local` scripts
- Modernize the v6 code to v7 (with lists and related functions)

## History

- v1.12   Previous versions of the plugin were hosted on my google-code /
  lh-misc repository. 

- v1.11   Less errors are printed when the file loaded contains errors
- v1.10   `s:k_version` in `vimrc_local` files is automatically incremented on
          saving
- v1.9    New command `:SourceLocalVimrc` in order to explicitly load the
          local-vimrc file before creating new files from a template (We
          can't just rely on `BufNewFile` as there is no guaranty
          `vimrc_local`'s `BufNewFile` will be called before the one from the
          Template Expander Plugin => it's up to the TEP to call the
          function)
- v1.8    No more infinite recursion on file in non existent paths.
          + patch from cristiklein to support paths with spaces
- v1.7    Don't search a local vimrc with remote paths (ftp://, http, ... )
- v1.6    Sometimes root path is Z:\\, which is quite odd
- v1.5    The auto-command is moved to the au-group `LocalVimrc`
- v1.4	Stop the recursion when we get to `//` or `\\` (UNC paths)
- v1.3    More comments.
          Trace of the directories searched when `'verbose' >= 2`
- v1.2	Stops at `$HOME` or at root (`/`)
- v1.1	Uses `_vimrc_local.vim`
- v1.0	Initial solution
