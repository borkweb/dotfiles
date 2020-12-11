if !exists('g:vdebug_options')
	let g:vdebug_options = {}
endif

let g:vdebug_options.path_maps = {
	\ '/app' : getcwd(),
\ }

let g:vdebug_options.break_on_open = 0
let g:vdebug_options.watch_window_style = 'compact'

if !exists('g:vdebug_features')
	let g:vdebug_features = {}
endif

let g:vdebug_features.max_children = 128
let g:vdebug_options.ide_key = 'PHPSTORM'

""
" Adds a slug and path combo to the list of selectable debugging environments
""
function DebugAddEnvMap(slug, path, mapped_path)
	if !exists('g:debug_envs')
		let g:debug_envs = {}
	endif

	if !exists('g:debug_env_choices')
		let g:debug_env_choices = []
	endif

	let g:debug_env_choices += [a:slug]

	let g:debug_envs[a:slug] = {}
	let g:debug_envs[a:slug].slug = a:slug

	if a:slug == 'current path'
		let g:debug_envs[a:slug].path = getcwd()
	else
		let g:debug_envs[a:slug].path = a:path
	endif

	let g:debug_envs[a:slug].mapped_path = a:mapped_path
endfun

function DebugSelectEnv()
	let choices = ''

	for key in g:debug_env_choices
		if choices != ''
			let choices .= "\n"
		endif

		let choices = choices . "&" . key
	endfor

	let selection = confirm( 'Which dev environment are you debugging?', choices )

	let slug = g:debug_env_choices[ selection - 1 ]
	let path = g:debug_envs[ slug ]['path']
	let mapped_path = g:debug_envs[ slug ]['mapped_path']

	let g:vdebug_options.path_maps = { mapped_path : path, }

	echom 'Your debugging environment has been set to ' . slug . ' (' . path . ')'
endfun

let g:debug_envs        = {}
let g:debug_env_choices = []

call DebugAddEnvMap( 'current path', getcwd(), '/app' )
call DebugAddEnvMap( 'dev', '/home/matt/sites/dev-lando', '/app' )
call DebugAddEnvMap( 'ea', '/home/matt/sites/event-aggregator-site', '/app' )
call DebugAddEnvMap( 'pue', '/home/matt/sites/pue-service', '/app' )
call DebugAddEnvMap( 'tec', '/home/matt/sites/tec-lando', '/app' )
