"=============================================================================
" File:		plugin/local_vimrc.vim                                     {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://github.com/LucHermitte/local_vimrc>
" Version:	2.2.3
" Created:	09th Apr 2003
" Last Update:	08th Sep 2015
" License:      GPLv3
"------------------------------------------------------------------------
" Description:	Solution to Yakov Lerner's question on Vim ML {{{2
"	Search for a _vimrc_local.vim file in the parents directories and
"	source it if found.
"
"	Initial Question:
"	"Is it possible, after sourcing ~/.exrc, to traverse from $HOME down
"	 to cwd, and source .exrc from every directory if present ?
"	 (And if cwd is not under $HOME, just source ~/.exrc).
"	 What do I put into .vimrc to do this ?
"
"	"Example: current dir is ~/a/b/c. Files are sourced in this order:
"	 ~/.exrc, then ~/a/.exrc, ~/a/b/.exrc, ~/a/b/c/.exrc.
"	 No messages if some of .exrc does not exist."
" }}}2
"------------------------------------------------------------------------
" Installation:	{{{2
" 	0- Set g:local_vimrc in your .vimrc if you wish to use filenames other
" 	   than '_vimrc_local.vim'
" 	a- Drop this plugin into a {rtp}/plugin/ directory, and install
" 	   lh-vim-lib v3.2.1
" 	b- Define _vimrc_local.vim files into your directories
"
" 	   Ideally, each foo/bar/_vimrc_local.vim should be defined the same
" 	   way as a ftplugin, i.e.: {{{3
"		" Global stuff that needs to be updated/override
"		let g:bar = 'bar'  " YES! This is a global variable!
"
"		" Local stuff that needs to be defined once for each buffer
"		if exists('b:foo_bar_local_vimrc') | finish | endif
"		let b:foo_bar_local_vimrc = 1
"		setlocal xxx
"		nnoremap <buffer> foo :call <sid>s:Foo()<cr>
"		let b:foo = 'foo'
"
"		" Global stuff that needs to be defined once only => functions
"		if exists('g:foo_bar_local_vimrc') | finish | endif
"		let g:foo_bar_local_vimrc = 1
"		function s:Foo()
"		  ...
"		endfunction
"	c- In order to load the local variable before a skeleton is read, ask
"	   the maintainer of template-file expander pluin to explicitly execute
"	   :SourceLocalVimrc before doing the actual expansion.
"
" History:	{{{2
"       v2.2.3  Merge pull requests: 
"               - Incorrect addon-info extension (txt -> json)
"               - Fix :SourceLocalVimrc path
"       v2.2.2  Directory lists were incorrectly sorted (bis) + shellslash
"       isssue
"       v2.2.1  Directory lists were incorrectly sorted
"       v2.2.0  Plugins functions moved to autoload.
"               Verbose mode is activated by calling `lh#local_vimrc#verbose(1)`
"       v2.1.0  Whitelist, blacklist & co
"               Requires lh-vim-lib 3.2.4
"       v2.0.1  Updated to match changes in lh-vim-lib 3.2.2.
"       v2.0    Code refactored.
"               -> Search function deported to lh-vim-lib
"               -> dependencies to vim7 and to lh-vim-lib introduced
"               Support for directory of local_vimrc_files added
"	v1.11   Less errors are printed when the file loaded contains errors
"	v1.10   s:k_version in local_vimrc files is automatically incremented
"	        on saving
"	v1.9    New command :SourceLocalVimrc in order to explicitly load the
"	        local-vimrc file before creating new files from a template (We
"	        can't just rely on BufNewFile as there is no guaranty
"	        local_vimrc's BufNewFile will be called before the one from the
"	        Template Expander Plugin => it's up to the TEP to call the
"	        function)
"	v1.8    No more infinite recursion on file in non existent paths.
"	        + patch from cristiklein to support paths with spaces
"	v1.7    Don't search a local vimrc with remote paths (ftp://, http, ... )
"	v1.6    Sometimes root path is Z:\\, which is quite odd
"	v1.5    The auto-command is moved to the au-group LocalVimrc
"	v1.4	Stop the recursion when we get to // or \\ (UNC paths)
"	v1.3    More comments.
"	        Trace of the directories searched when 'verbose' >= 2
"	v1.2	Stops at $HOME or at root (/)
" 	v1.1	Uses _vimrc_local.vim
" 	v1.0	Initial solution
" TODO:		{{{2
" 	(*) Test sandbox -> E48
" 	(*) Test lists with config directories
"       (*) Support checksum for project configuration from external sources
" See also: alternative scripts: #441, #3393, #1860, ...
" }}}1
"=============================================================================

"=============================================================================
" Avoid global reinclusion {{{1
let s:k_version = 223
if exists("g:loaded_local_vimrc")
      \ && (g:loaded_local_vimrc >= s:k_version)
      \ && !exists('g:force_reload_local_vimrc')
  finish
endif
if lh#path#version() < 3204
  call lh#common#error_msg('local_vimrc requires a version of lh-vim-lib >= 3.2.4. Please upgrade it.')
  finish
endif
let g:loaded_local_vimrc = s:k_version
let s:cpo_save=&cpo
set cpo&vim
" Avoid global reinclusion }}}1
"------------------------------------------------------------------------
" Commands {{{1
command! -nargs=0 SourceLocalVimrc call s:Main(expand('%:p:h'))

" Default Options {{{1
runtime plugin/let.vim " from lh-vim-lib
LetIfUndef g:local_vimrc_options             {}
LetIfUndef g:local_vimrc_options.whitelist   []
LetIfUndef g:local_vimrc_options.blacklist   []
LetIfUndef g:local_vimrc_options.asklist     []
LetIfUndef g:local_vimrc_options.sandboxlist []

" Accept user defined ~/.vim/_vimrc_local.vim, but no file from the various addons,
" bundles, ...
call lh#path#munge(g:local_vimrc_options.whitelist, lh#path#vimfiles())
call lh#path#munge(g:local_vimrc_options.blacklist, lh#path#vimfiles().'/.*')

" Accept $HOME, but nothing from parent directories
call lh#path#munge(g:local_vimrc_options.asklist, $HOME)
call lh#path#munge(g:local_vimrc_options.blacklist, fnamemodify($HOME, ':p:h:h'))
" The directories where projects (we trust) are stored shall be added into
" whitelist

" Functions {{{1
" NB: Not all functions are moved into the autoload plugin.
" Indeed, as the plugin main function is executed of each BufEnter, the
" autoload plugin would have been loaded each time. This, way, we try to delay
" its sourcing to the last moment.

" Name of the files used                                              {{{2
" NB: g:local_vimrc shall be set before loading this plugin!
function! s:LocalVimrcName()
  let res = exists('g:local_vimrc') ? g:local_vimrc : ['_vimrc_local.vim']
  if type(res) == type('')
    return [res]
  endif
  return res
endfunction

let s:local_vimrc = s:LocalVimrcName()

" Value of $HOME -- actually a regex.                                 {{{2
let s:home = substitute($HOME, '[/\\]', '[/\\\\]', 'g')

" Regex used to determine when we must stop looking for local-vimrc's {{{2
let s:re_last_path = !empty(s:home) ? ('^'.s:home.'$') : ''

" The main function                                                   {{{2
function! s:IsAForbiddenPath(path)
  let forbidden = a:path =~ '^\(s\=ftp:\|s\=http:\|scp:\|^$\)'
  return forbidden
endfunction

function! s:Main(path) abort
  " echomsg 'Sourcing: '.a:path
  if s:IsAForbiddenPath(a:path) | return | endif

  let config_found = lh#path#find_in_parents(a:path, s:local_vimrc, 'file,dir', s:re_last_path)
  let configs = []
  for config in config_found
    if filereadable(config)
      let configs += [config]
    elseif isdirectory(config)
      let gpat = len(s:local_vimrc) > 1
            \ ? ('{'.join(s:local_vimrc, ',').'}')
            \ : (s:local_vimrc)
      let configs += glob(gpat, 0, 1)
    endif
  endfor

  if !empty(configs)
    let filtered_pathnames = lh#local_vimrc#_prepare_lists()
    let fp_keys = map(copy(filtered_pathnames), '"^".lh#path#to_regex((v:val)[0])')
    for config in configs
      let idx = lh#list#find_if(fp_keys, string(fnamemodify(config, ':h')).'=~ v:1_')
      let permission = (idx != -1)
            \ ? filtered_pathnames[idx][1]
            \ : "default"
      call lh#local_vimrc#_verbose( fnamemodify(config, ':h')." =~ fp_keys[".idx."]=".fp_keys[idx]."   -- ".permission)
      call lh#local_vimrc#_handle_file(config, permission)
    endfor
  endif
endfunction

" Auto-command                                                        {{{2
aug LocalVimrc
  au!
  " => automate the loading of local-vimrc's every time we change buffers
  " Note: BufEnter seems to be triggerred twice on a "vim foo.bar"
  au BufEnter * :call s:Main(expand('<afile>:p:h'))
  " => Update script version every time it is saved.
  for s:_pat in s:local_vimrc
    exe 'au BufWritePre '.s:_pat. ' call lh#local_vimrc#_increment_version_on_save()'
  endfor
aug END

" Functions }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
