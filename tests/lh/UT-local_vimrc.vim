"=============================================================================
" File:         tests/lh/UT-local_vimrc.vim                       {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/local_vimrc>
" Version:      2.2.2
let s:k_version = 222
" Created:      03rd Mar 2015
" Last Update:  18th Apr 2015
"------------------------------------------------------------------------
" Description:
"       Unit Test for LocalVimrc
"       Run it with UTRun from UT
" }}}1
"=============================================================================

UTSuite Testing local_vimrc.vim

let g:local_vimrc_options = {}
Reload plugin/local_vimrc.vim autoload/lh/local_vimrc.vim

let s:cpo_save=&cpo
set cpo&vim

let s:k_silent = lh#local_vimrc#verbose() ? '' : 'silent '

"------------------------------------------------------------------------
" Constants
let s:k_save_config = deepcopy(g:local_vimrc_options)
let s:k_script      = g:lh#UT#crt_file
let s:k_data_path   = fnamemodify(s:k_script, ':p:h').'/data'
let s:k_deep_file   = s:k_data_path.'/lvl1/lvl2/lvl3/lvl4/_vimrc_local.vim'
" let s:k_permissions = ['whitelist', 'blacklist', 'asklist', 'sandboxlist']
let s:k_permissions = ['whitelist', 'blacklist', 'sandboxlist']

"------------------------------------------------------------------------
function! s:Teardown()
  " restore g:local_vimrc_options
  let g:local_vimrc_options = deepcopy(s:k_save_config)
endfunction

"------------------------------------------------------------------------
function! s:_AddLevel(depth, lvl)
  let path = s:k_data_path
  for i in range(1, a:depth)
    let path .= '/lvl'.i
  endfor
  if a:lvl == 'whitelist'
    call lh#path#munge(g:local_vimrc_options.whitelist, path)
  elseif a:lvl == 'blacklist'
    call lh#path#munge(g:local_vimrc_options.blacklist, path)
  elseif a:lvl == 'asklist'
    call lh#path#munge(g:local_vimrc_options.asklist, path)
  elseif a:lvl == 'sandboxlist'
    call lh#path#munge(g:local_vimrc_options.sandboxlist, path)
  endif
endfunction

"------------------------------------------------------------------------
function! s:_Test_oneCase(lvls)
  let g:local_vimrc_options = deepcopy(s:k_save_config)
  let i = 1
  for lvl in a:lvls
    call s:_AddLevel(i, a:lvls[i-1])
    let i += 1
  endfor

  try
    let g:levels = {}
    exe s:k_silent.'sp '.s:k_deep_file
    let i = 1
    " Comment string(g:levels)
    " Comment string(g:local_vimrc_options)
    for lvl in a:lvls
      if lvl == 'blacklist'
        AssertTxt (! has_key(g:levels, 'lvl'.i)
              \, "'lvl".i."' shouldn't have been in ".string(keys(g:levels)))
      else
        AssertTxt! (has_key(g:levels, 'lvl'.i) && 1==g:levels['lvl'.i]
              \ , "'lvl".i."' not in ".string(keys(g:levels)))
      endif
      let i += 1
    endfor
  finally
    silent! exe 'bd '.s:k_deep_file
  endtry
endfunction

"------------------------------------------------------------------------
function! s:TestAll()
  for i1 in range(0, len(s:k_permissions)-1)
    for i2 in range(0, len(s:k_permissions)-1)
      for i3 in range(0, len(s:k_permissions)-1)
        for i4 in range(0, len(s:k_permissions)-1)
          call s:_Test_oneCase([s:k_permissions[i1], s:k_permissions[i2], s:k_permissions[i3], s:k_permissions[i4]])
        endfor
      endfor
    endfor
  endfor
endfunction

function! s:_TestOne()
  call s:_Test_oneCase(['whitelist', 'whitelist', 'blacklist', 'whitelist', ])
endfunction
"------------------------------------------------------------------------
function! s:TestBlackListStart()
  let g:local_vimrc_options = deepcopy(s:k_save_config)
  call lh#path#munge(g:local_vimrc_options.whitelist, s:k_data_path.'/lvl1')
  call lh#path#munge(g:local_vimrc_options.blacklist, s:k_data_path.'/lvl1/.*')
  " Comment string(g:local_vimrc_options)
  try
    let g:levels = {}
    exe s:k_silent.'sp '.s:k_deep_file
    Assert has_key(g:levels, 'lvl1')
    Assert !has_key(g:levels, 'lvl2')
    Assert !has_key(g:levels, 'lvl3')
    Assert !has_key(g:levels, 'lvl4')
  finally
    silent! exe 'bd '.s:k_deep_file
  endtry
endfunction

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
