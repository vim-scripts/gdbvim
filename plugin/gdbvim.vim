" Vim global plugin for interface to gdb.
" Last change: 2001 Sep 5
" Maintainer: Tomas Zellerin, <zellerin@volny.cz>

" You may want check http://www.volny.cz/zellerin/gdbvim/ for newer version of
" this and accompanying files, gdbvim and gdbvim.txt
"
" Feedback welcome.
"
" See :help gdbvim.txt for documentation 

let s:BpSet = ""

let s:bpFilename = ""
let s:bpLineNumber = -1

" Prevent multiple loading, allow commenting it out
if exists("loaded_gdbvim")
	finish
endif

" If you dont have signs and clientserver, complain.
function Gdb_interf_init(fifo_name, pwd)
  echo "Can not use gdbvim plugin - your vim must have +signs and +clientserver features"
endfunction

if !(has("clientserver") && has("signs"))
  finish
endif

let loaded_gdbvim = 1
let s:having_partner=0

" This used to be in Gdb_interf_init, but older vims crashed on it
highlight DebugBreak guibg=darkred guifg=white ctermbg=darkred ctermfg=white
highlight DebugStop guibg=lightgreen guifg=white ctermbg=lightgreen ctermfg=white
sign define breakpoint linehl=DebugBreak
sign define current linehl=DebugStop

" Get ready for communication
function! Gdb_interf_init(fifo_name, pwd)
  
  if s:having_partner " sanity check
    echo "Oops, one communication is already running"
    return
  endif
  let s:having_partner=1
  
  let s:fifo_name = a:fifo_name " Make use of parameters
  execute "cd ". a:pwd

  if !exists("g:loaded_gdbvim_mappings")
    call s:Gdb_shortcuts()
  endif
  let g:loaded_gdbvim_mappings=1

  if !exists(":Gdb")
    command -nargs=+ Gdb	:call Gdb_command(<q-args>, v:count)
  endif

endfunction

function Gdb_interf_close()
	sign unplace *
        let s:BpSet = ""
	let s:having_partner=0
endfunction

function Gdb_Bpt(id, file, linenum)
	if !bufexists(a:file)
		execute "bad ".a:file
	endif
	execute "sign unplace ". a:id
	execute "sign place " .  a:id ." name=breakpoint line=".a:linenum." file=".a:file
        let s:BpSet = MvAddElement(s:BpSet, "|", s:bpFilename.":".s:bpLineNumber)
endfunction

function Gdb_NoBpt(id)
	execute "sign unplace ". a:id
        let s:BpSet = MvRemoveElement(s:BpSet, "|", s:bpFilename.":".s:bpLineNumber)
endfunction

function Gdb_CurrFileLine(file, line)
	if !bufexists(a:file)
		if !filereadable(a:file)
			return
		endif
		execute "e ".a:file
	else
	execute "b ".a:file
	endif
	let s:file=a:file
	execute "sign unplace ". 3
	execute "sign place " .  3 ." name=current line=".a:line." file=".a:file
	execute a:line
	:silent! foldopen!
endf

noremap <unique> <script> <Plug>SetBreakpoint :call <SID>SetBreakpoint()<CR>

function Gdb_command(cmd, ...)
  if match (a:cmd, '^\s*$') != -1
    return
  endif
  let suff=""
  if 0<a:0 && a:1!=0
    let suff=" ".a:1
  endif
  silent exec ":redir >>".s:fifo_name ."|echon \"".a:cmd.suff."\n\"|redir END "
endfun

" Toggle breakpoints
function Gdb_togglebreak(name, line)
    if MvIndexOfElement(s:BpSet, "|", a:name.":".a:line) != -1
        silent call Gdb_command("clear ".a:name.":".a:line)
    else
        silent call Gdb_command("break ".a:name.":".a:line)
    endif
    let s:bpFilename = a:name
    let s:bpLineNumber = a:line
endfun

" Mappings are dependant on Leader at time of loading the macro.
function s:Gdb_shortcuts()
    nmap <unique> <F9> :call Gdb_togglebreak(bufname("%"), line("."))<CR>
    nmap <unique> <C-F5> :Gdb run<CR>
    nmap <unique> <F7> :<C-U>Gdb step<CR>
    nmap <unique> <F8> :<C-U>Gdb next<CR>
    nmap <unique> <F6> :Gdb finish<CR>
    nmap <unique> <F5> :<C-U>Gdb continue<CR>
    vmap <unique> <C-P> "gy:Gdb print <C-R>g<CR>
    nmap <unique> <C-P> :call Gdb_command("print ".expand("<cword>"))<CR> 
    nmenu Gdb.Command :<C-U>Gdb 
    nmenu Gdb.Run<tab><C-F5> :Gdb Run<CR>
    nmenu Gdb.Step<tab><F7> :<C-U>Gdb step<CR>
    nmenu Gdb.Next<tab><F8> :<C-U>Gdb next<CR>
    nmenu Gdb.Finish<tab><F6> :Gdb finish<CR>
    nmenu Gdb.Continue<tab><F5> :<C-U>Gdb cont<CR>
    nmenu Gdb.Set\ break<tab><F9> :call Gdb_command("break ".bufname("%").":".line("."))<CR>
endfunction

" vim: set sw=2 ts=8 smarttab : "
