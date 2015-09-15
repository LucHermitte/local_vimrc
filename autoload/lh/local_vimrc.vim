"=============================================================================
" File:         autoload/lh/local_vimrc.vim                       {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/local_vimrc>
" Version:      2.2.2.
let s:k_version = 222
" Created:      04th Mar 2015
" Last Update:  18th Apr 2015
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
if !exists('s:verbose')
  let s:verbose = 0
endif
function! lh#local_vimrc#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! lh#local_vimrc#_verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#local_vimrc#debug(expr)
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions     {{{1

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
    if CONFIRM('Do you want to source "'.a:file.'"?', "&Yes\n&No", 1) != 1
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

" ## Internal functions     {{{1
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
