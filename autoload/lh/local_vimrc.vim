"=============================================================================
" File:         autoload/lh/local_vimrc.vim                       {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/local_vimrc>
" Version:      2.2.11.
let s:k_version = 2211
" Created:      04th Mar 2015
" Last Update:  15th Nov 2019
" License:      GPLv3
"------------------------------------------------------------------------
" Description:
"       Internal functions for local_vimrc
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions         {{{1
" # Version {{{2
function! lh#local_vimrc#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#local_vimrc#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Log(expr, ...)
  call call('lh#log#this',[a:expr]+a:000)
endfunction

function! lh#local_vimrc#_verbose(expr, ...)
  if s:verbose
    call call('s:Log',[a:expr]+a:000)
  endif
endfunction

function! lh#local_vimrc#debug(expr)
  return eval(a:expr)
endfunction

" # Misc    {{{2
" s:getSNR([func_name]) {{{3
function! s:getSNR(...) abort
  if !exists("s:SNR")
    let s:SNR=matchstr(expand('<sfile>'), '<SNR>\d\+_\zegetSNR$')
  endif
  return s:SNR . (a:0>0 ? (a:1) : '')
endfunction

" s:source(file)  {{{3
function! s:source(file) abort
  call lh#local_vimrc#_verbose("Sourcing " . a:file)
  exe 'source '.escape(a:file, ' \$')
endfunction

"------------------------------------------------------------------------
" ## Exported functions     {{{1
" # Lists management        {{{2
" Function: lh#local_vimrc#lists() {{{3
function! lh#local_vimrc#lists() abort
  return g:local_vimrc_options
endfunction

" Function: lh#local_vimrc#munge(listname, path) {{{3
function! lh#local_vimrc#munge(listname, path) abort
  call lh#local_vimrc#_verbose("munge(g:local_vimrc_options.%1, %2)", a:listname, a:path)
  return lh#path#munge(g:local_vimrc_options[a:listname], a:path)
endfunction

" Function: lh#local_vimrc#filter_list(listname, expr) {{{3
function! lh#local_vimrc#filter_list(listname, expr) abort
  return filter(g:local_vimrc_options[a:listname], a:expr)
endfunction

"------------------------------------------------------------------------
" ## Default options {{{1
runtime plugin/let.vim " from lh-vim-lib
LetIfUndef g:local_vimrc_options              = {}
LetIfUndef g:local_vimrc_options.whitelist    = []
LetIfUndef g:local_vimrc_options.blacklist    = []
LetIfUndef g:local_vimrc_options.asklist      = []
LetIfUndef g:local_vimrc_options.sandboxlist  = []
LetIfUndef g:local_vimrc_options._action_name = 'recognize a local vimrc at'
" letifundef g:local_vimrc_options._do_handle  { file -> execute('source '.escape(file, ' \$'))}
call lh#let#if_undef('g:local_vimrc_options._do_handle', function(s:getSNR('source')))

" Accept user defined ~/.vim/_vimrc_local.vim, but no file from the various addons,
" bundles, ...
call lh#local_vimrc#munge('whitelist', lh#path#vimfiles())
call lh#local_vimrc#munge('blacklist', lh#path#vimfiles().'/.*')

" Accept $HOME, but nothing from parent directories
if         index(g:local_vimrc_options.whitelist,   $HOME) < 0
      \ && index(g:local_vimrc_options.blacklist,   $HOME) < 0
      \ && index(g:local_vimrc_options.sandboxlist, $HOME) < 0
  call lh#local_vimrc#munge('asklist', $HOME)
endif
call lh#local_vimrc#munge('blacklist', fnamemodify('/', ':p'))
" The directories where projects (we trust) are stored shall be added into
" whitelist

"------------------------------------------------------------------------
" ## Internal API functions {{{1
" # Prepare Permission lists                                            {{{2
" Function: lh#local_vimrc#_prepare_lists() {{{3
function! lh#local_vimrc#_prepare_lists()
  let options     = lh#option#get('local_vimrc_options', {}, 'g')
  let whitelist   = s:GetList('whitelist'  , options)
  let blacklist   = s:GetList('blacklist'  , options)
  let asklist     = s:GetList('asklist'    , options)
  let sandboxlist = s:GetList('sandboxlist', options)

  let mergedlists = whitelist + blacklist + asklist + sandboxlist
  call reverse(sort(mergedlists, function('s:SortLists')))
  return mergedlists
endfunction

" # Handle a vimrc_local file found                                     {{{2
" Function: lh#local_vimrc#_handle_file(file, permission) {{{3
function! lh#local_vimrc#_handle_file(file, permission) abort
  if a:permission == 'blacklist'
    call lh#local_vimrc#_verbose( "(blacklist) Ignoring " . a:file)
    return
  elseif a:permission == 'sandbox'
    call lh#local_vimrc#_verbose( "(sandbox) Sourcing " . a:file)
    exe 'sandbox source '.escape(a:file, ' \$,')
    return
  elseif a:permission == 'ask'
    if lh#ui#confirm('Do you want to source "'.a:file.'"?', "&Yes\n&No", 1) != 1
      return
    endif
  endif
  call lh#local_vimrc#_verbose("(".a:permission.") Sourcing " . a:file)
  exe 'source '.escape(a:file, ' \$,')
endfunction

" # Update s:k_version in vimrc_local files                             {{{2
" Function: lh#local_vimrc#_increment_version_on_save() {{{3
function! lh#local_vimrc#_increment_version_on_save()
  let l = search('let s:k_version', 'n')
  if l > 0
    let nl = substitute(getline(l),
          \ '\(let\s\+s:k_version\s*=\s*\)\(\d\+\)\s*$',
          \ '\=submatch(1).(1+submatch(2))',
          \ '')
    call setline(l, nl)
  endif
endfunction

" # Open local_vimrc file                                               {{{2
" Function: lh#local_vimrc#_open_local_vimrc() {{{3
function! lh#local_vimrc#_open_local_vimrc() abort
  let configs = lh#option#get('local_vimrc.configs')
  if lh#option#is_unset(configs)
    call lh#common#error_msg('No local_vimrc file associated to current buffer')
    return
  endif
  let lvimrc = lh#path#select_one(configs, 'Which local_vimrc do you wish to open?')
  call lh#buffer#jump(lvimrc, 'sp')
endfunction
" ## Internal functions     {{{1
" # Misc                                                                {{{2
" # Prepare Permission lists                                            {{{2
" Function: s:SortLists(lhs, rhs) {{{3
function! s:SortLists(lhs, rhs)
  return    (a:lhs)[0] <  (a:rhs)[0] ? -1
        \ : (a:lhs)[0] == (a:rhs)[0] ? 0
        \ :                            1
endfunction

" Function: s:GetList(listname, options) {{{3
function! s:GetList(listname, options)
  let list = copy(get(a:options, a:listname, []))
  call map(list, '[substitute(v:val, "[/\\\\]", lh#path#shellslash(), "g"), a:listname]')
  return list
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
