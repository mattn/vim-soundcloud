if exists('g:loaded_ctrlp_soundcloud') && g:loaded_ctrlp_soundcloud
  "finish
endif
let g:loaded_ctrlp_soundcloud = 1

let s:config_file = get(g:, 'ctrlp_soundcloud_file', '~/.ctrlp-soundcloud')

let s:soundcloud_var = {
\  'init':   'ctrlp#soundcloud#init()',
\  'exit':   'ctrlp#soundcloud#exit()',
\  'accept': 'ctrlp#soundcloud#accept',
\  'lname':  'soundcloud',
\  'sname':  'soundcloud',
\  'type':   'path',
\  'sort':   0,
\  'nolim':  1,
\}

if exists('g:ctrlp_ext_vars') && !empty(g:ctrlp_ext_vars)
  let g:ctrlp_ext_vars = add(g:ctrlp_ext_vars, s:soundcloud_var)
else
  let g:ctrlp_ext_vars = [s:soundcloud_var]
endif

let s:vim_soundcloud_client_id = 'e58dfd1cec88ed21d2b1329902464cfb'
let s:vim_soundcloud_client_secret = '39b4d7d9404bfbbfcf1b45e5e1f8f021'

function! ctrlp#soundcloud#genres(arglead, cmdline, curpos)
  return filter(copy(['all-music', 'all-audio', 'alternativerock', 'ambient', 'classical', 'country', 'danceedm', 'dancehall', 'deephouse', 'disco', 'drumbass', 'dubstep', 'electronic', 'folksingersongwriter', 'hiphoprap', 'house', 'indie', 'jazzblues', 'latin', 'metal', 'piano', 'pop', 'rbsoul', 'reggae', 'reggaeton', 'rock', 'soundtrack', 'techno', 'trance', 'trap', 'triphop', 'world', 'audiobooks', 'business', 'comedy', 'entertainment', 'learning', 'newspolitics', 'religionspirituality', 'science', 'sports', 'storytelling', 'technology']), 'stridx(v:val, a:arglead) == 0')
endfunction

function! s:authenticate(...)
  let refresh_token = get(a:000, 0, '')

  if !empty(refresh_token)
    let res = webapi#http#post('https://api.soundcloud.com/oauth2/token', {
    \ 'client_id':     s:vim_soundcloud_client_id,
    \ 'client_secret': s:vim_soundcloud_client_secret,
    \ 'grant_type': 'refresh_token',
    \ 'refresh_token': refresh_token,
    \})
    call writefile([res.content], expand('~/.vim-soundcloud'))
    return webapi#json#decode(res.content)
  endif

  if filereadable(expand('~/.vim-soundcloud'))
    return webapi#json#decode(join(readfile(expand('~/.vim-soundcloud')), "\n"))
  endif

  let username = input('username: ')
  let password = inputsecret('password: ')
  let res = webapi#http#post('https://api.soundcloud.com/oauth2/token', {
  \ 'client_id':     s:vim_soundcloud_client_id,
  \ 'client_secret': s:vim_soundcloud_client_secret,
  \ 'grant_type':   'password',
  \ 'username':     username,
  \ 'password':     password,
  \})
  call writefile([res.content], expand('~/.vim-soundcloud'))
  return webapi#json#decode(res.content)
endfunction

function! ctrlp#soundcloud#init()
  let ai = {}
  try
    let ai = s:authenticate()
    let res = webapi#http#get('https://api.soundcloud.com/tracks.json', {
    \ 'oauth_token': ai.access_token,
    \ 'genre': s:genre,
    \})
  catch
    if empty(ai) || !has_key(ai, 'refresh_token')
      echohl ErrorMsg | echon 'failed to authenticate: ' . v:exception | echohl None
      sleep 2
      return
    endif
    let res = webapi#http#get('https://api.soundcloud.com/tracks.json', {
    \ 'oauth_token': ai.access_token,
    \})
  endtry
  let s:list = webapi#json#decode(res.content)
  return map(copy(s:list), 'v:val.title . " - " . v:val.user.username')
endfunc

function! ctrlp#soundcloud#accept(mode, str)
  let lines = filter(copy(s:list), 'a:str == v:val.title . " - " . v:val.user.username')
  call ctrlp#exit()
  redraw!
  if len(lines) > 0 && len(lines[0]) > 1
    if exists('s:job') && job_status(s:job) != 'stop'
      call job_stop(s:job)
    endif
    let ai = s:authenticate()
    if executable('ffplay')
      let s:job = job_start(['ffplay', '-autoexit', '-nodisp', lines[0].stream_url . '?oauth_token=' . ai.access_token])
    elseif executable('avplay')
      let s:job = job_start(['avplay', '-autoexit', '-nodisp', lines[0].stream_url . '?oauth_token=' . ai.access_token])
    elseif executable('avplay')
      let s:job = job_start(['mplayer', lines[0].stream_url . '?oauth_token=' . ai.access_token])
    endif
  endif
endfunction

function! ctrlp#soundcloud#exit()
  if exists('s:list')
    unlet! s:list
  endif
endfunction

function! ctrlp#soundcloud#start(...)
  call ctrlp#init(ctrlp#soundcloud#id())
  let s:genre = get(a:000, 0, '')
endfunction

let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)
function! ctrlp#soundcloud#id()
  return s:id
endfunction
