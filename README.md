local_vimrc : A project management plugin for Vim
===========

The aim of `local_vimrc` is to apply settings on files from a same project.

A project is defined by a root directory: everything under the root directory
belongs to the project. No need to register every single file in the project,
they all belong.

[![Last release](https://img.shields.io/github/tag/LucHermitte/local_vimrc.svg)](https://github.com/LucHermitte/local_vimrc/releases) [![Project Stats](https://www.openhub.net/p/21020/widgets/project_thin_badge.gif)](https://www.openhub.net/p/21020)

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

The latest version of this script requires vim 7.0 and
[lh-vim-lib](http://github.com/LucHermitte/lh-vim-lib) v5.2.1+.
[UT](http://github.com/LucHermitte/vim-UT) v0.1.0 will be required to
execute the unit tests.

The easiest way to install this plugin is with
[vim-addon-manager](https://github.com/MarcWeber/vim-addon-manager), or other
plugin managers based on [vim-pi](https://bitbucket.org/vimcommunity/vim-pi),
that support vim-addon-files -- as this script specifies its
[dependencies](https://github.com/LucHermitte/local_vimrc/blob/master/addon-info.txt)
in vim-addon-file format.

```vim
ActivateAddons local_vimrc
```

Or with [vim-flavor](http://github.com/kana/vim-flavor) which also supports dependencies:

```
flavor 'LucHermitte/local_vimrc'
```


With Vundle

```vim
Plugin 'LucHermitte/lh-vim-lib'
Plugin 'LucHermitte/local_vimrc'
```

Or, with a NeoBundle version that doesn't support vim-pi yet:
```vim
set rtp+=~/.vim/bundle/NeoBundle.vim/
call neobundle#begin(expand('~/.vim/bundle'))
NeoBundleFetch 'Shougo/NeoBundle.vim'
" Line required to force the right plugin name -> lh-vim-lib, and not trunk
NeoBundle 'LucHermitte/lh-vim-lib', {'name': 'lh-vim-lib'}
" Note: I haven't found the syntax to merge the two NeoBundle lines into one...
NeoBundle 'LucHermitte/local_vimrc', {'depends': 'lh-vim-lib'}
call neobundle#end()

NeoBundleCheck
```

## Usage

Drop a `_vimrc_local.vim` file into any project root directory, and write it
exactly as you would have written a ftplugin.

### `_vimrc_local.vim` content

In other words. The _project_ file is expected to be loaded (/sourced)
every time you enter a buffer that corresponds to a file under the project root
directory.

As a consequence, you may want to prevent multiple executions of parts the
sourced file: almost everything shall remain identical and shall not need to
be reset.
However some plugins, like
[_alternate_ (a.vim)](http://www.vim.org/scripts/script.php?script_id=31), rely
on global variables to tune their behaviour. The settings (global variables)
related to those plugins will require you to update their value every time --
if you expect to have settings that differ from a project to another. In
order to support such project-aware setting, `local_vimrc` lets you in charge
of handling anti-reinclusion guards in project configuration files.

For your project settings prefer buffer-local mappings
([`:h :map-<buffer>`](http://vimhelp.appspot.com/map.txt.html#%3amap%2d%3cbuffer%3e)),
abbreviations ([`:h :abbreviate-<buffer>`](http://vimhelp.appspot.com/map.txt.html#%3aabbreviate%2d%3cbuffer%3e)),
commands ([`:h :command-buffer`](http://vimhelp.appspot.com/map.txt.html#%3acommand%2dbuffer)),
menus (see my fork of
[buffer-menu](https://github.com/LucHermitte/lh-misc/blob/master/plugin/buffermenu.vim)),
settings ([`:h :setlocal`](http://vimhelp.appspot.com/options.txt.html#%3asetlocal)),
and variables ([`:h local-variable`](http://vimhelp.appspot.com/eval.txt.html#local%2dvariable)).

N.B.: if you are a plugin writer that want to support configuration variables
that'll dynamically adapt to the current project settings, have a look at my
[`lh#option#get()` and `lh#ft#option#get()`](https://github.com/LucHermitte/lh-vim-lib/blob/master/doc/Options.md#function-list)
functions.

You'll find examples of use in my
[dedicated repository](http://github.com/LucHermitte/config).

## Options

The behaviour of this plugin can be tuned with the following options:

- `g:local_vimrc` variable specifies the filenames and filepaths to be searched. The default
  is `"_vimrc_local.vim"`. It can contain a list ([`:h List`](http://vimhelp.appspot.com/eval.txt.html#List)) of pathnames, or a simple string.
  It's meant to contain something that'll be relative to your current project
  root.  
  This can contain a directory or a list of directories. In that case, in order
  to find any file named `_vimrc_local.vim` in directories named `.config/` at
  the root of current project directory, set the variable to 
  ```vim
  let g:local_vimrc = ['.config', '_vimrc_local.vim']
  ```

- `g:local_vimrc_options` dictionary will hold four lists (`whitelist`,
  `blacklist`, `asklist`, and `sandboxlist`) that define how security issues
  are handled. See [Security concerns](#security-concerns).

## Other Features

### Per-project settings and Template Expander Plugins
Sometimes we want to set variables (like a project source directory, or
specific template files that override the default project file headers) before
other plugins are triggered.  
The typical use case will be from the shell:
```
# There is a _vimrc_local.vim file in /path/to/myproject/
cd /path/to/myproject/submodule42
gvim foobar.h
```

In order to use `myproject` settings (naming styles, header guards naming
policy, ...), the `vimrc_local` file needs to be sourced before any
template-file is expanded.

This plugin provides the `:SourceLocalVimrc` command for this purpose. It's up
to the Template Expander Plugin to exploit this feature -- as this moment, only my
[fork](http://github.com/LucHermitte/mu-template) of mu-template does.

### Automatic increment of `vimrc_local` script version number
When saved, if the `vimrc_local` script has a `s:k_version` variable, it will be
incremented automatically. This variable is meant to avoid multiple inclusions
of the script for a given buffer. New `vimrc_local` scripts created with the
help of the templates provided with my
[mu-template](http://github.com/LucHermitte/mu-template) fork are making
use of this variable.

### Security concerns

Thanks to the option `g:local_vimrc_options`, it's possible to tune which
`_vimrc_local` files are sourced, and how.

#### The lists

The four lists `g:local_vimrc_options.whitelist`,
`g:local_vimrc_options.blacklist`, `g:local_vimrc_options.asklist`, and
`g:local_vimrc_options.sandboxlist`, will hold lists of pathname patterns.
Depending on the kind of the pattern that is the best match for the current
`_vimrc_local` file, the file will be either:

- sourced, if it belongs to the _whitelist_,
- ignored, if it belongs to the _blacklist_,
- sourced, if it belongs to the _asklist_ and if the end user says _"Yes
  please, source this file!"_,
- sourced in the sandbox ([`:h sandbox`](http://vimhelp.appspot.com/eval.txt.html#sandbox)) if it belongs to the _sandboxlist_.
- or sourced if it belongs to no list (and if it's a local file, and not a file
  accessed through scp://, http://, ...).

#### Default settings

- Any `_vimrc_local` file in `$HOME/.vim/` will be sourced.
- However, files in `$HOME/.vim/` subdirectories will be ignored. This way, the
  end-user may specify options to use when editing vim files. See
  [the file I use](http://github.com/LucHermitte/lh-misc/blob/master/_vimrc_local.vim)
  for instance.
- `_vimrc_local` files under `$HOME` are sourced only if the end-user
  interactively says _"yes"_.
- `_vimrc_local` files under `$HOME/..` are ignored.

#### Tuning the lists

In order to blindly accept `_vimrc_local` files from projects your are working
on, you'll have to add this kind of lines into your `.vimrc`, __after__ this
plugin has been loaded:

```vim
" Sourcing the plugin
ActivateAddons local_vimrc
...
" Let's assume you put all projects you are working on in your
" corporation under $HOME/dev/my_corporation/
call lh#local_vimrc#munge('whitelist', $HOME.'/dev/my_corporation')
" But projects from 3rd parties/projects downloaded from the internet go
" into $HOME/dev/3rdparties/
call lh#local_vimrc#munge('blacklist', $HOME.'/dev/3rdparties')
```

If you want to override default settings, change them in your `.vimrc`
__after__ this plugin has been loaded. e.g.:

```vim
ActivateAddons local_vimrc
...
" Remove $HOME from the asklist,
call lh#local_vimrc#filter_list('asklist', 'v:val != $HOME')
" Add it in the sandbox list instead
call lh#local_vimrc#munge('sandboxlist', $HOME)

" Clean the whitelist
let lh#local_vimrc#lists().whitelist = []
```

## Alternatives

To be fair, there exist [alternatives](http://stackoverflow.com/a/456889/15934).

### Modelines
Modelines are particularly limited:
* We can't set variables (that tunes other (ft)plugins, like _"should the braces of the for-snippet be on a newline ?"_),
* nor call functions from modelines (I don't limit myself to coding standards, I also set the makefile to use depending on the current directory)
* Modelines aren't [DRY](http://en.wikipedia.org/wiki/Don%27t_repeat_yourself).
With modelines, a setting needs to be repeated in every file, if there are too many things to set or tunings to change, it will quickly become difficult to maintain, moreover, it will require the use of a [template-expander plugin](http://vim.wikia.com/wiki/Category:Automated_Text_Insertion) (which you should consider if you have several vimmers in your project).
* Not every one uses Vim to develop. I don't want to be bothered by other people editor settings, why should I parasite theirs with modelines ?

### `.exrc`
Vim natively supports `.exrc` files ([`:h .exrc`](http://vimhelp.appspot.com/starting.txt.html#%2eexrc), § d-) when `'exrc'` is on. This solution is very similar to `local_vimrc`. However `.exrc` files are executed (_sourced_ in Vim jargon) only on buffers (corresponding to files) which are in the exact same directory. Files in subdirectories won't trigger the execution of the project `.exrc` file.

### Autocommands
It's possible to add autocommands in our `.vimrc`. Autocommands that will detect files under a certain directory to trigger commands (`:set xxxxx`, `:let b:style='alman'`, `:source path/to/project_config.vim`, ...).

If the autocommand executes simple commands (instead of sourcing a file), the solution won't scale when new commands will need to be added.

Autocommands won't scale either as a project location may vary :
* On several machines a project may not be stored in the same path ;
* When branches are stored in different paths, the `.vimrc` may need to be tuned for each branch ;
* When several people are using Vim, it's easier to ask them to install a same plugin instead of asking them to maintain and adapt their respective `.vimrc`

### Project plugin
There exist a quite old (which does NOT mean bad) plugin dedicated to the management of project configuration. I've never used it, I won't be able to tell you why `local_vimrc` solution is better or not.

### Plugins similar to local_vimrc

There exist many plugins with the same name or even with similar purpose. Just to
name a few, there is for instance:

- Project oriented plugins:

    - Aric Blumer's good old [project.vim plugin #69](http://www.vim.org/scripts/script.php?script_id=69) which addresses other _project_ concerns.
    - Tim Pope's [Projectionist #4989](https://github.com/tpope/vim-projectionist),
    - [Vim plugin](https://github.com/editorconfig/editorconfig-vim) for [EditorConfig](http://editorconfig.org/) -- I plan eventually to provide a
      way to [set project variables for this plugin](https://github.com/LucHermitte/lh-vim-lib/issues/8),
    - My [lh-vim-lib](https://github.com/LucHermitte/lh-vim-lib/blob/master/doc/Project.md) library plugin provides a new way to define _projects_
      and to tune plugins on a per project basis. For more complex plugins, both approaches can be mixed.

- local-vimrc plugins:

    - Marc Weber's [vim-addon-local-vimrc](https://github.com/MarcWeber/vim-addon-local-vimrc)
    - Markus _"embear"_ Braun's [local_vimrc #441](https://github.com/embear/vim-localvimrc),
    - thinca's [localrc.vim #3393](http://www.vim.org/scripts/script.php?script_id=3393),
    - Tye Zdrojewski's [Directory specific settings #1860](http://www.vim.org/scripts/script.php?script_id=1860).

## TO DO

- Document how `local_vimrc` can be used with
  [BuildToolsWrapper](http://github.com/LucHermitte/vim-build-tools-wrapper) to support
  CMake based projects.
- Document how to mix definitions that need to be sourced only once, and `local_vimrc`
- doc&test: Support the definition of the project configuration in files put a separate
  directory (in order to help versioning them).
- doc: Support List of possible names for `vimrc_local` scripts
- Support checksum for project configuration from external sources

## History

- v2.2.11
    - BUG: Use `is_eligible` on the right pathname (PR#12) 
    - ENH: Don't source anything on directories 
    - ENH: Don't source multiple times in a row with a same buffer
    - ENH: Improve logs 
    - DOC: Miscelleanous improvments
    - BUG: Define "Edit Local Vimrc" mapping in buffers with a local vimrc.
- v2.2.10
    - ENH: Add 'edit local vimrc' in menu
    - ENH: Ignore buffer when `! lh#project#is_eligible()`
    - ENH: Abort of quickfix and fugitive paths
    - PERF: Improve vim startup time
- v2.2.9  ENH: Simplify permission list management
- v2.2.8  BUG: Fix regression to support Vim7.3
- v2.2.7  ENH: Listen for BufRead and BufNewFile
- v2.2.6  ENH: Use lhvl 4.0.0 permission lists  
          This implicitly fix asklist management
- v2.2.5  BUG: Fix #7 -- support of config in directory
- v2.2.4  Use new logging framework  
          Fix issue when `g:local_vimrc` is a string.
- v2.2.3  Merge pull requests:
    - Incorrect addon-info extension (txt -> json)  
    - Fix :SourceLocalVimrc path
- v2.2.2  Directory lists were incorrectly sorted (bis) + shellslash isssue
- v2.2.1  Directory lists were incorrectly sorted
- v2.2.0 Plugins functions moved to autoload.  
         Verbose mode is activated by calling `lh#local_vimrc#verbose(1)`
- v2.1.1 Bug fix in support of regex in white/black/... lists.
- v2.1.0 Whitelist, blacklist & co  
         Requires lh-vim-lib 3.2.4
- v2.0.1 Updated to match changes in lh-vim-lib 3.2.2.  
- v2.0   Code refactored.  
           -> Search function deported to lh-vim-lib  
           -> dependencies to vim7 and to lh-vim-lib introduced  
         Support for directory of local_vimrc_files added.
- v1.12  Previous versions of the plugin were hosted on my google-code /
         lh-misc repository.
- v1.11  Less errors are printed when the file loaded contains errors.
- v1.10  `s:k_version` in `vimrc_local` files is automatically incremented on
         saving.
- v1.9   New command `:SourceLocalVimrc` in order to explicitly load the
         local-vimrc file before creating new files from a template (We
         can't just rely on `BufNewFile` as there is no guaranty
         `vimrc_local`'s `BufNewFile` will be called before the one from the
         Template Expander Plugin => it's up to the TEP to call the
         function).  
- v1.8   No more infinite recursion on file in non existent paths.
         + patch from cristiklein to support paths with spaces
- v1.7   Don't search a local vimrc with remote paths (ftp://, http, ... )
- v1.6   Sometimes root path is Z:\\, which is quite odd
- v1.5   The auto-command is moved to the au-group `LocalVimrc`
- v1.4	 Stop the recursion when we get to `//` or `\\` (UNC paths)
- v1.3   More comments.  
         Trace of the directories searched when `'verbose' >= 2`
- v1.2	 Stops at `$HOME` or at root (`/`)
- v1.1	 Uses `_vimrc_local.vim`
- v1.0	 Initial solution
