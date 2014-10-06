local_vimrc : A project management plugin for Vim
===========

The aim of `local_vimrc`is to apply settings on files from a same project. 

A project is defined by a root directory: everything under the root diretory belongs to the project. No need to register every single file in the project, they all belong. 


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
[lh-vim-lib](http://code.google.com/p/lh-vim/wiki/lhVimLib) v3.2.2+.

The easiest way to install this plugin is with
[vim-addon-manager](https://github.com/MarcWeber/vim-addon-manager), or other
plugin managers based on [vim-pi](https://bitbucket.org/vimcommunity/vim-pi),
that support vim-addon-files -- as this script specifies its
[dependencies](https://github.com/LucHermitte/local_vimrc/blob/master/local_vimrc-addon-info.txt)
in vim-addon-file format.

```vim
ActivateAddons local_vimrc
```

If you really want to stick with dependencies unware plugins that cannot
support subversion repositories like Vundle, you can install vim-scripts' mirror
of lh-vim-lib on github.

```vim
Bundle 'vim-scripts/lh-vim-lib'                                          
Bundle 'LucHermitte/local_vimrc'
```

Or, with a NeoBundle version that doesn't support vim-pi yet:
```vim
set rtp+=~/.vim/bundle/NeoBundle.vim/
call neobundle#begin(expand('~/.vim/bundle'))
NeoBundleFetch 'Shougo/NeoBundle.vim'
" Line required to force the right plugin name -> lh-vim-lib, and not trunk
NeoBundle 'http://lh-vim.googlecode.com/svn/vim-lib/trunk', {'name': 'lh-vim-lib'}
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
be reset. However some plugins, like a.vim, rely on global variables to tune
their behaviour. The settings (global variables) related to those plugins will
require you to update their value every time -- if you expect to have settings
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

- `g:local_vimrc` variable specifies the filenames and filepaths to be searched. The default
  is `"_vimrc_local.vim"`. It can contain a list (`:h List`) of pathnames, or a simple string.

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
[fork](http://code.google.com/p/lh-vim/wiki/muTemplate) of mu-template does.

### Automatic increment of `vimrc_local` script version number
When saved, if the `vimrc_local` script has a `s:k_version` variable, it will be
incremented automatically. This variable is meant to avoid multiple inclusions 
of the script for a given buffer. New `vimrc_local` scripts created with the
help of the templates provided with my
[mu-template](http://code.google.com/p/lh-vim/wiki/muTemplate) fork are making
use of this variable.


## Alternatives

To be fair, there exist [alternatives](http://stackoverflow.com/a/456889/15934).

### Modelines
Modelines are particularly limited:
* We can't set variables (that tunes other (ft)plugins, like _"should the braces of the for-snippet be on a newline ?"_), 
* nor call function from them (I don't limit myself to coding standards, I also set the makefile to use depending on the current directory)
* Modelines aren't [DRY](http://en.wikipedia.org/wiki/Don%27t_repeat_yourself).
With modelines, a setting needs to be repeated in every file, if there are too many things to set or tunings to change, it will quickly become difficult to maintain, moreover, it will require the use of a [template-expander plugin](http://vim.wikia.com/wiki/Category:Automated_Text_Insertion) (which you should consider if you have several vimmers in your project).
* Not every one uses Vim to develop. I don't want to be bothered by other people editor settings, why should I parasite theirs with modelines ?

### `.exrc`
Vim nativelly supports `.exrc` files (`:h .exrc`, § d-) when `'exrc'` is on. This solution is very similar to `local_vimrc`. However `.exrc` files are executed (_sourced_ in Vim jargon) only on buffers (corresponding to files) which are in the exact same directory. Files in subdirectories won't trigger the execution of the project `.exrc` file.

### Autocommands
It's possible to add autocommands in our `.vimrc`. Autocommands that will detect files under a certain directory to trigger commands (`:set xxxxx`, `:let b:style='alman'`, `:source path/to/project_config.vim`, ...).

If the autocommand executes simple commands (instead of sourcing a file), the solution won't scale when new commands will need to be added.

Autocommands won't scale either as a project location may vary : 
* On several machines a project may not be stored in the same path ;
* When branches are stored in different paths, the `.vimrc` may need to be tuned for each branch ;
* When several people are using Vim, it's easier to ask them to install a same plugin instead of asking them to maintain and adapt their respective `.vimrc`

### Project plugin
There exist a quite old (which does mean bad) plugin dedicated to the management of project configuration. I've never used it, I won't be able to tell you why `local_vimrc` solution is better or not.

### Plugins similar to local_vimrc

There exist many plugins with the same name or even the same purpose. I may add
a link to them ... later. 

## TO DO

- Document how `local_vimrc` can be used with
  [BuildToolsWrapper](http://code.google.com/p/lh-vim/wiki/BTW) to support
  CMake based projects.
- Document how to mix definitions that need to be source once only, and `local_vimrc`
- doc&test: Support the definition of the project configuration in files put a separate
  directory (in order to help versioning them).
- Add option to stop looking at `$HOME` or elsewhere (`[bg]:lv_stop_at` : string,
  default `$HOME`) 
- doc: Support List of possible names for `vimrc_local` scripts

## History

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
