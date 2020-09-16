"=============================================================================
" File:		plugin/local_vimrc.vim                                     {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://github.com/LucHermitte/local_vimrc>
" Version:	2.2.11
let s:k_version = 2211
" Created:	09th Apr 2003
" Last Update:	16th Sep 2020
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
"       v2.2.11 BUG: Use `is_eligible` on the right pathname (PR#12)
"               ENH: Don't source anything on directories
"               ENH: Don't source multiple times in a row with a same buffer
"               ENH: Improve logs
"               BUG: Define "Edit Local Vimrc" mapping in buffers with a
"                    local vimrc.
"       v2.2.10 ENH: Add 'edit local vimrc' in menu
"               ENH: Ignore buffer when `! lh#project#is_eligible()`
"       v2.2.9  ENH: Simplify permission list management
"       v2.2.8  BUG: Fix regression to support Vim7.3
"       v2.2.7  ENH: Listen for BufRead and BufNewFile
"       v2.2.6  ENH: Use lhvl 4.0.0 permission lists
"       v2.2.5  BUG: Fix #7 -- support of config in directory
"       v2.2.4  Use new logging framework
"               Fix issue when g:local_vimrc is a string.
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
let s:cpo_save=&cpo
set cpo&vim
if &cp || (exists("g:loaded_local_vimrc")
      \ && (g:loaded_local_vimrc >= s:k_version)
      \ && !exists('g:force_reload_local_vimrc'))
  let &cpo=s:cpo_save
  finish
endif
if lh#path#version() < 40000
  call lh#common#error_msg('local_vimrc requires a version of lh-vim-lib >= 4.0.0. Please upgrade it.')
  finish
endif
let g:loaded_local_vimrc = s:k_version
" Avoid global reinclusion }}}1
"------------------------------------------------------------------------
" Commands {{{1
command! -nargs=0 SourceLocalVimrc call s:SourceLocalVimrc(expand('%:p'), 'Explicit')

" Default Options {{{1
function! s:get_permission_lists()
  if ! exists('s:permission_lists')
    let s:permission_lists = lh#path#new_permission_lists(lh#local_vimrc#lists())
  endif
  return s:permission_lists
endfunction

" Functions {{{1
" NB: Not all functions are moved into the autoload plugin.
" Indeed, as the plugin main function is executed of each BufEnter, the
" autoload plugin would have been loaded each time. This, way, we try to delay
" its sourcing to the last moment.

" # Name of the files used                                            {{{2
" NB: g:local_vimrc shall be set before loading this plugin!
function! s:LocalVimrcName()
  let res = get(g:, 'local_vimrc', ['_vimrc_local.vim'])
  return type(res) == type('') ? [res] : res
endfunction

let s:local_vimrc = s:LocalVimrcName()

" # Value of $HOME -- actually a regex.                               {{{2
let s:home = substitute($HOME, '[/\\]', '[/\\\\]', 'g')

" # Regex used to know when we must stop looking for local-vimrc's    {{{2
let s:re_last_path = !empty(s:home) ? ('^'.s:home.'$') : ''

" # The main function                                                 {{{2
function! s:IsAForbiddenPath(path) abort
  " Ignore qf buffers, distant buffers, and scratch buffers
  let is_forbidden = ! lh#project#is_eligible(a:path)
  if is_forbidden
    call s:verbose('  -> Ø <- Ignore `%1`: buffer is either of qf filetype, or distant, or scratch', a:path)
  endif
  return is_forbidden
endfunction

function! s:verbose(...)
  if exists('*lh#local_vimrc#_verbose')
    call call('lh#local_vimrc#_verbose', a:000)
  endif
endfunction

let s:last_buffer = -1
function! s:SourceLocalVimrc(path, origin) abort
  call s:verbose("* Searching local_vimrc for `%1` w/ %=`%2` (nr: %3, ft: `%4`) on %5", a:path, expand('%'), bufnr('%'), lh#option#getbufvar(bufnr('%'), '&ft'), a:origin)
  " If a:path is a directory, it's bufnr may be completly messed up with the
  " one from another buffer
  " Question shall we have local vimrc applied on directories edited through
  " `:sp %:h`? Let's say no.
  if isdirectory(a:path)
    call s:verbose("  -> Ø <- Ignore `%1`: this is a directory", a:path)
    " Reset s:last_buffer in case a plugin took over and changed global
    " variables
    let s:last_buffer = -1
    return
  endif
  let bid = bufnr(a:path)
  if bid == s:last_buffer
    call s:verbose("  -> Ø <- Ignore `%1`: current buffer (%2) hasn't changed since last time (%3)", a:path, bid, s:last_buffer)
    return
  endif
  if s:IsAForbiddenPath(a:path) | return | endif
  let s:last_buffer = bid

  let config_found = lh#path#find_in_parents(a:path, s:local_vimrc, 'file,dir', s:re_last_path)
  let configs = []
  for config in config_found
    if filereadable(config)
      call s:verbose(" - File config found -> %1", config)
      let configs += [config]
    elseif isdirectory(config)
      let gpat = type(s:local_vimrc) == type([])
            \ ? ('{'.join(s:local_vimrc, ',').'}')
            \ : (s:local_vimrc)
      " let new_conf = globpath(config, gpat, 0, 1) " This version ignores suffixes and wildignore
      let new_conf = lh#path#glob_as_list(config, gpat) " This version doesn't
      let configs += new_conf
      call s:verbose(" - dir config found %1 -> %2", config, new_conf)
    endif
  endfor

  if !empty(configs)
    let configs = lh#list#uniq(configs)
    let some_found = s:get_permission_lists().handle_paths(configs)
    call s:verbose("%1 local vimrc found and sourced", some_found)
    call lh#let#if_undef('p:local_vimrc.configs', configs)
    if some_found && has('gui_running') && has ('menu') && a:origin =~ 'BufRead\|BufNewFile'
      call lh#project#menu#make('nic', '76', 'Edit local &vimrc', '<localleader>le', '<buffer>', ':call lh#local_vimrc#_open_local_vimrc()<cr>' )
    endif
  endif
endfunction

" # Auto-command                                                      {{{2
aug LocalVimrc
  au!
  " => automate the loading of local-vimrc's:
  " - BufRead: before things using BufReadPost, and lhvl-project
  "   Note: BufRead is used by filetype detection, which should be triggered
  "   first.
  " - BufNewFile:
  "   Note: BufNewFile is also used by template expanders like mu-template
  " - BufEnter: every time we change buffers
  "   As some plugins use global option, we need to load local vimrcs on
  "   BufEnter, even if they've been already loaded on BufEnter and BufNewFile.
  "   TODO: Register that BufLeave hasn't been triggered => no need to reload
  au BufEnter   * :call s:SourceLocalVimrc(expand('<afile>:p'), 'BufEnter')
  au BufRead    * :call s:SourceLocalVimrc(expand('<afile>:p'), 'BufRead')
  au BufNewFile * :call s:SourceLocalVimrc(expand('<afile>:p'), 'BufNewFile')
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
