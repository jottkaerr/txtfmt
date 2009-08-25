" Txtfmt: Set of Vim plugins (syntax, ftplugin, plugin) for creating and
" displaying formatted text with Vim.
" File: This is the global plugin file, which contains configuration code
" needed by both the ftplugin and the syntax files.
" Creation:	2004 Nov 06
" Last Change: 2008 Dec 12
" Maintainer:	Brett Pershing Stahlman <brettstahlman@comcast.net>
" License:	This file is placed in the public domain.

" Note: The following line is required by a packaging script
let g:Txtfmt_Version = "2.0a"

" Autocommands needed by refresh mechanism <<<
au FileType * call s:Txtfmt_save_filetype()
au Syntax * call s:Txtfmt_save_syntax()
fu! s:Txtfmt_save_filetype()
	let l:filetype = expand("<amatch>")
	if l:filetype =~ '\%(^\|\.\)txtfmt\%(\.\|$\)'
		let b:txtfmt_filetype = l:filetype
	endif
endfu
fu! s:Txtfmt_save_syntax()
	let l:syntax = expand("<amatch>")
	if l:syntax =~ '\%(^\|\.\)txtfmt\%(\.\|$\)'
		let b:txtfmt_syntax = l:syntax
	endif
endfu
" >>>
" Functions needed regardless of whether common config is being performed <<<
" Function: s:Is_txtfmt_modeline() <<<
" Purpose: Return nonzero if and only if the line whose text is input "looks
" like" a txtfmt modeline.
" Note: Option names and values are NOT validated. That function is performed
" by s:Process_txtfmt_modeline.
" Inputs:
" linestr  -A line of text that may or may not represent a txtfmt modeline.
" Note: Format of the modeline is as follows:
" (Based upon 1st Vim modeline format)
"	[text]{white}txtfmt:[white]{options}
"	{options} can be the following:
"	{tokrange|rng}=<hex>|<dec>[sSlL]
"	{escape|esc}={self|bslash|none}
"	{sync}={<hex>|<dec>|fromstart|none}
"	{bgcolor|bg}=<color>
"	{nested|nst}
" Must be no whitespace surrounding the '='
" Also: Since Vim will not choke on a trailing ':' (though it's not
" technically part of the 1st modeline format), neither will I.
" Define regexes used to process modeline
" Also: ' txtfmt:' with no options is not an error, but will not be recognized
" as a modeline. Rationale: If user doesn't define any options in a modeline,
" assume it's just text that looks like the start of a modeline.
let s:re_ml_start = '\%(.\{-}\%(\s\+txtfmt:\s*\)\)'
let s:re_ml_name  = '\%(\I\i*\)'
let s:re_ml_val   = '\%(\%(\\.\|[^:[:space:]]\)\+\)'
let s:re_ml_el    = '\%('.s:re_ml_name.'\%(='.s:re_ml_val.'\)\?\)'
let s:re_ml_elsep = '\%(\s\+\|\s*:\s*\)'
let s:re_ml_end   = '\%(\s*:\?\s*$\)'
" Construct pattern matching entire line, which will capture all leading text
" in \1, all options in \2, and all trailing text in \3
let s:re_modeline = '\('.s:re_ml_start.'\)\('
			\.s:re_ml_el.'\%('.s:re_ml_elsep.s:re_ml_el.'\)*\)'
			\.'\('.s:re_ml_end.'\)'
fu! s:Is_txtfmt_modeline(linestr)
	return a:linestr =~ s:re_modeline
endfu
" >>>
" >>>
" IMPORTANT NOTE: The common configuration code in this file is intended to be
" executed only upon request by either the txtfmt ftplugin or syntax file.
" Since this file resides in the Vim plugin directory, it will be sourced by
" Vim automatically whenever Vim is started; the common configuration code,
" however, will not be executed at Vim startup because the special txtfmt
" variable b:txtfmt_do_common_config will not be set at that time. When either
" the ftplugin or syntax file wishes to execute the code in this script, it
" sets b:txtfmt_do_common_config and uses :runtime to source this file. When
" the common configuration code within this file executes, it makes its output
" available to both ftplugin and syntax files via buffer-local variables.

if exists('b:txtfmt_do_common_config')
" Needed for both ftplugin and syntax
" Command: Refresh <<<
com! -buffer Refresh call s:Txtfmt_refresh()
" >>>
" Autocommands <<<
" Ensure that common configuration will be redone whenever the txtfmt buffer
" is re-read (e.g. after a txtfmt-modeline has been changed).
" Note: This autocmd allows user simply to do ":e" at the Vim command line to
" resource everything, including the option processing in common config.
augroup TxtfmtCommonConfig
	au BufReadPre <buffer> :unlet! b:txtfmt_did_common_config
augroup END
" >>>
" Common constant definitions <<<

" Define first Vim version that supported undercurl
let b:txtfmt_const_vimver_undercurl = 700
" Define several sets of constants needed by the functions used to process
" 'tokrange' option.
" Define tokrange defaults (decomposed into 'starttok' and 'formats' values)
" as a function of encoding class.
" Note: starttok encoded as string to preserve dec or hex display preference
let b:txtfmt_const_starttok_def_{'1'}    = '180'
let b:txtfmt_const_formats_def_{'1'}     = 'X'
let b:txtfmt_const_starttok_def_{'2'}    = '180'
let b:txtfmt_const_formats_def_{'2'}     = 'X'
let b:txtfmt_const_starttok_def_{'u'}    = '0xE000'
let b:txtfmt_const_formats_def_{'u'}     = 'X'
" Define the number of tokens in the txtfmt token range as a function of
" the format variant flags (which determine num_attributes in the equations
" below):
" --no background colors--
" N = 2 ^ {num_attributes} + 9
" --background colors--
" N = 2 ^ {num_attributes} + 9 + 9
" Important Note: The numbers are not dependent upon the number of active fg
" and bg colors, since we always reserve 8 colors.

" The 3 parameters in the following constants represent the following 3 format
" variant flags:
" txtfmt_cfg_bgcolor
" txtfmt_cfg_longformats
" txtfmt_cfg_undercurl
" Note: Value supplied for longformats and undercurl indices must take 'pack'
" option into account.
" TODO: Fix the final 3 elements or get rid of this array altogether. Note
" that it doesn't take 'pack' option into account
let b:txtfmt_const_tokrange_size_{0}{0}{0} = 17 
let b:txtfmt_const_tokrange_size_{0}{1}{0} = 41 
let b:txtfmt_const_tokrange_size_{0}{1}{1} = 73 
let b:txtfmt_const_tokrange_size_{1}{0}{0} = 26 
let b:txtfmt_const_tokrange_size_{1}{1}{0} = 82 
let b:txtfmt_const_tokrange_size_{1}{1}{1} = 82 

" Make sure we can easily deduce the suffix from the format variant flags
let b:txtfmt_const_tokrange_suffix_{0}{0}{0} = 'S'
let b:txtfmt_const_tokrange_suffix_{0}{1}{0} = 'L'
let b:txtfmt_const_tokrange_suffix_{0}{1}{1} = 'L'
let b:txtfmt_const_tokrange_suffix_{1}{0}{0} = 'X'
let b:txtfmt_const_tokrange_suffix_{1}{1}{0} = 'XL'
let b:txtfmt_const_tokrange_suffix_{1}{1}{1} = 'XL'

" Define the maximum character code that may be used as a txtfmt token as a
" function of encoding class. (Encoding class is specified as '1' for single
" byte, '2' for 16-bit and 'u' for unicode.)
" Note: Vim doesn't support unicode chars larger than 16-bit.
let b:txtfmt_const_tokrange_limit_{'1'} = 0xFF
let b:txtfmt_const_tokrange_limit_{'2'} = 0xFFFF
let b:txtfmt_const_tokrange_limit_{'u'} = 0xFFFF
" The following regex describes a {number} that may be used to set a numeric
" option. The txtfmt help specifies that only decimal or hexadecimal formats
" are permitted.
let b:txtfmt_re_number_atom = '\([1-9]\d*\|0x\x\+\)'

" >>>
" General utility functions <<<
" Function: s:Repeat() <<<
" Purpose: Generate a string consisting of the input string repeated the
" requested number of times.
" Note: Vim7 added a repeat() function, but I'm intentionally not using
" anything added post-Vim6.
" Input:
" str       - string to repeat
" cnt       - number of times to repeat it
" Return: The generated string
fu! s:Repeat(str, cnt)
	let ret_str = ''
	let i = 0
	while i < a:cnt
		let ret_str = ret_str . a:str
		let i = i + 1
	endwhile
	return ret_str
endfu
" >>>
" >>>
" Parse_<...> functions <<<
" Function: s:Parse_init()
" Purpose:
" Input:
" text		- string to be parsed
" re_tok	- regex matching a token
" Return: ID that must be passed to the other parse functions (-1 indicates
" error)
" Simulated struct:
" text
" len
" re
" pos
fu! s:Parse_init(text, re_tok)
	let i = 0
	let MAX_PARSE_INSTANCES = 1000
	while i < MAX_PARSE_INSTANCES
		if !exists('s:parsedata_'.i.'_text')
			" Found a free one
			let s:parsedata_{i}_text = a:text
			let s:parsedata_{i}_len = strlen(a:text)	" for speed
			let s:parsedata_{i}_re = a:re_tok
			let s:parsedata_{i}_pos = 0
			return i
		endif
		let i = i + 1
	endwhile
	if i >= MAX_PARSE_INSTANCES
		echoerr "Internal Parse_init error - contact developer"
		return -1
	endif
endfu
" Function: s:Parse_nexttok()
" Purpose:
" Input:
" Return: The next token as a string (or empty string if no more tokens)
" Error: Not possible when used correctly, and since this is an internally
" used function, we will not check for error.
fu! s:Parse_nexttok(parse_id)
	" Note: Structures used and generated internally in controlled manner, so
	" assume parse_id points to valid struct
	let text = s:parsedata_{a:parse_id}_text
	let re = s:parsedata_{a:parse_id}_re
	let pos = s:parsedata_{a:parse_id}_pos
	let len = s:parsedata_{a:parse_id}_len
	let parse_complete = 0	" set if text exhausted
	" Did last call exhaust text?
	if pos >= len
		let parse_complete = 1
		let ret_str = ''
	else
		" text not exhausted yet - get past any whitespace
		" ^\s* will return pos if no whitespace at pos (cannot return -1)
		let pos = matchend(text, '^\s*', pos)
		" Did we move past trailing whitespace?
		if pos >= len
			let parse_complete = 1
			let ret_str = ''
		else
			" We're sitting on first char to be returned.
			" re determines how many more will be part of return str
			" Note: Force re to match at current pos if at all
			let pos2 = matchend(text, '^'.re, pos)
			if pos2 < 0
				" curr char is not part of a token, so just return it by itself
				let ret_str = text[pos]
				let pos = pos + 1
			else
				" Return the token whose end was located
				let ret_str = strpart(text, pos, pos2-pos)
				let pos = pos2
			endif
		endif
	endif
	" Only way out of this function
	if parse_complete
		call s:Parse_free(a:parse_id)
	else
		" Update pos in structure for next call...
		let s:parsedata_{a:parse_id}_pos = pos
	endif
	return ret_str
endfu
" Function: s:Parse_free()
" Purpose: Free the data structures for a particular parse instance (denoted
" by input id)
" Input: parse_id - parse instance whose data is to be freed
" Return: none
" Error: not possible
fu! s:Parse_free(parse_id)
	" Using unlet! ensures that error not possible
	unlet! s:parsedata_{a:parse_id}_text
	unlet! s:parsedata_{a:parse_id}_re
	unlet! s:parsedata_{a:parse_id}_pos
	unlet! s:parsedata_{a:parse_id}_len

endfu
" >>>
" Configuration utility functions (common) <<<
" >>>
" encoding utility functions (common) <<<
let s:re_encs_1 = '^\%('
			\.'latin1\|iso-8859-n\|koi8-r\|koi8-u'
			\.'\|macroman\|cp437\|cp737\|cp775'
			\.'\|cp850\|cp852\|cp855\|cp857'
			\.'\|cp860\|cp861\|cp862\|cp863'
			\.'\|cp865\|cp866\|cp869\|cp874'
			\.'\|cp1250\|cp1251\|cp1253\|cp1254'
			\.'\|cp1255\|cp1256\|cp1257\|cp1258'
			\.'\)$'
let s:re_encs_2 = '^\%('
			\.'cp932\|euc-jp\|sjis\|cp949'
			\.'\|euc-kr\|cp936\|euc-cn\|cp950'
			\.'\|big5\|euc-tw'
			\.'\)'
let s:re_encs_u = '^\%('
			\.'utf-8\|ucs-2\|ucs-2le\|utf-16\|utf-16le\|ucs-4\|ucs-4le'
			\.'\)'
" Function: TxtfmtCommon_Encoding_get_class() <<<
" Purpose: Return single character indicating whether the input encoding name
" represents a 1-byte encoding ('1'), a 2-byte encoding ('2'), or a unicode
" encoding ('u'). If input encoding name is unrecognized, return empty string.
fu! TxtfmtCommon_Encoding_get_class(enc)
	if a:enc  =~ s:re_encs_1
		return '1'
	elseif a:enc =~ s:re_encs_2
		return '2'
	elseif a:enc =~ s:re_encs_u
		return 'u'
	else
		return ''
	endif
endfu
" >>>
" >>>
" 'tokrange' utility functions <<<
" Construct pattern that will capture char code in \1 and optional size
" specification (sSlLxX) in \2.
if exists('g:txtfmtAllowxl') && g:txtfmtAllowxl
	" Note: By default, XL suffix is illegal, but user has overridden the
	" default
	let s:re_tokrange_spec = '^\([1-9]\d*\|0x\x\+\)\(\%([sSlL]\|[xX][lL]\?\)\?\)$'
else
	let s:re_tokrange_spec = '^\([1-9]\d*\|0x\x\+\)\([sSlLxX]\?\)$'
endif

" Function: s:Tokrange_is_valid() <<<
" Purpose: Indicate whether input string is a valid tokrange spec.
fu! s:Tokrange_is_valid(spec)
	return a:spec =~ s:re_tokrange_spec
endfu
" >>>
" Function: s:Tokrange_get_starttok() <<<
" Purpose: Return 'starttok' component of the input tokrange spec.
" Note: Return value will be numeric.
" Assumption: Input string has already been validated by s:Tokrange_is_valid.
" TODO_BG: This is currently unused. Get rid of it if I end up not needing it.
fu! s:Tokrange_get_starttok(spec)
	return 0 + substitute(a:spec, s:re_tokrange_spec, '\1', '')
endfu
" >>>
" Function: s:Tokrange_get_formats() <<<
" Purpose: Return 'formats' component of the input tokrange spec.
" Note: If optional 'formats' component is omitted, empty string will be
" returned.
" Note: formats spec will be returned in canonical form (uppercase).
" Assumption: Input string has already been validated by s:Tokrange_is_valid.
fu! s:Tokrange_get_formats(spec)
	return substitute(a:spec, s:re_tokrange_spec, '\U\2', '')
endfu
" >>>
" Function: s:Tokrange_translate_tokrange() <<<
" Description: Decompose the input tokrange into its constituent parts,
" setting all applicable option variables:
" b:txtfmt_cfg_starttok
" b:txtfmt_cfg_bgcolor
" b:txtfmt_cfg_longformats
" b:txtfmt_cfg_undercurl
" b:txtfmt_cfg_starttok_display
" b:txtfmt_cfg_formats_display
fu! s:Tokrange_translate_tokrange(tokrange)
	" Extract starttok and formats from input tokrange
	let starttok_str = substitute(a:tokrange, s:re_tokrange_spec, '\1', '') 
	let formats_str = substitute(a:tokrange, s:re_tokrange_spec, '\2', '') 

	" Decompose starttok into a numeric and a display portion
	let b:txtfmt_cfg_starttok = 0 + starttok_str
	let b:txtfmt_cfg_starttok_display = starttok_str

	" Decompose formats into constituent flags and a display portion
	" Note: Formats is a bit special. For one thing, it can be omitted from a
	" tokrange spec, in which case we'll choose a default. Also, long formats
	" ('L') can mean either 'all' or 'all_but_undercurl', depending upon Vim
	" version and b:txtfmt_cfg_undercurlpref. (Undercurl was not supported
	" until Vim version 7.0, and we allow user to disable it with the
	" 'undercurl' option even when it is supported.)
	" Note: b:txtfmt_cfg_undercurl is always set explicitly to 0 when it
	" doesn't apply, so that it can be used in parameterized variable names.
	if strlen(formats_str) == 0
		" Format suffix was omitted. Default to 'extended' formats (background
		" colors with short formats)
		let b:txtfmt_cfg_bgcolor = 1
		let b:txtfmt_cfg_longformats = 0
		let b:txtfmt_cfg_undercurl = 0
		let b:txtfmt_cfg_formats_display = 'X'
	elseif formats_str ==? 'L'
		" Long formats with no background colors
		let b:txtfmt_cfg_bgcolor = 0
		let b:txtfmt_cfg_longformats = 1
		if v:version >= b:txtfmt_const_vimver_undercurl && b:txtfmt_cfg_undercurlpref
			let b:txtfmt_cfg_undercurl = 1
		else
			let b:txtfmt_cfg_undercurl = 0
		endif
		let b:txtfmt_cfg_formats_display = 'L'
	elseif formats_str ==? 'X'
		" Background colors with short formats
		let b:txtfmt_cfg_bgcolor = 1
		let b:txtfmt_cfg_longformats = 0
		let b:txtfmt_cfg_undercurl = 0
		let b:txtfmt_cfg_formats_display = 'X'
	elseif formats_str ==? 'XL'
		" Background colors with long formats
		let b:txtfmt_cfg_bgcolor = 1
		let b:txtfmt_cfg_longformats = 1
		if v:version >= b:txtfmt_const_vimver_undercurl && b:txtfmt_cfg_undercurlpref
			let b:txtfmt_cfg_undercurl = 1
		else
			let b:txtfmt_cfg_undercurl = 0
		endif
		" Note: This is no longer legal!!!!
		let b:txtfmt_cfg_formats_display = 'XL'
	else
		" Short formats
		let b:txtfmt_cfg_bgcolor = 0
		let b:txtfmt_cfg_longformats = 0
		let b:txtfmt_cfg_undercurl = 0
		let b:txtfmt_cfg_formats_display = 'S'
	endif
endfu
" >>>
" Function: s:Tokrange_size() <<<
" Note: Now that I'm reserving 8 colors even when numfgcolors and numbgcolors
" are less than 8, this function can probably be removed, or at least renamed
" (e.g., Tokrange_used_size).
fu! s:Tokrange_size(formats)
	return b:txtfmt_const_tokrange_size_{a:formats}
endfu
" >>>
" >>>
" 'sync' utility functions <<<
" Construct pattern that will validate the option value.
let s:re_sync_number_spec = '^\([1-9]\d*\|0x\x\+\)$'
let s:re_sync_name_spec = '^fromstart\|none$'

" Function: s:Sync_is_valid() <<<
" Purpose: Indicate whether input string is a valid sync option value
fu! s:Sync_is_valid(spec)
	return a:spec =~ s:re_sync_number_spec || a:spec =~ s:re_sync_name_spec
endfu
" >>>
" Function: s:Sync_get_method() <<<
" Purpose: Determine the syncmethod represented by the input sync value and
" return its name. Possible values: 'minlines', 'fromstart', 'none'
" Assumption: Input string has already been validated by s:Sync_is_valid.
fu! s:Sync_get_method(spec)
	if a:spec =~ s:re_sync_name_spec
		return a:spec
	else
		return 'minlines'
	endif
endfu
" >>>
" >>>
" 'escape' utility functions <<<
" Construct pattern that will validate the option value.
let s:re_escape_optval = '^\%(none\|bslash\|self\)$'
" Function: s:Escape_is_valid() <<<
" Purpose: Indicate whether input string is a valid escape option value
fu! s:Escape_is_valid(optval)
	return a:optval =~ s:re_escape_optval
endfu
" >>>
" >>>
" Number validation utility functions <<<
" Function: s:Number_is_valid(s)
" Purpose: Indicate whether the input string represents a valid number
fu! s:Number_is_valid(s)
	return a:s =~ '^\s*'.b:txtfmt_re_number_atom.'\s*$'
endfu
" >>>
" Num fg/bg colors validation utility function <<<
let s:re_num_clrs = '^\%(0x\)\?[0-8]$'
fu! s:Numclrs_is_valid(s)
	return a:s =~ s:re_num_clrs
endfu
" >>>
" fg/bg color mask validation utility function <<<
let s:re_clr_mask = '^[01]\{8}$'
fu! s:Clrmask_is_valid(s)
	return a:s =~ s:re_clr_mask
endfu
" >>>
" Function: s:Set_tokrange() <<<
" Purpose: Set b:txtfmt_cfg_starttok, b:txtfmt_cfg_bgcolor,
" b:txtfmt_cfg_longformats and b:txtfmt_cfg_undercurl options, taking into
" account any user-setting of 'tokrange' option, and if necessary, the txtfmt
" defaults, which may take 'encoding' into consideration.
" Note: If set via modeline, tokrange option value must be a literal tokrange
" specification; however, buf-local and global option variables may be set to
" either a valid tokrange spec, or a Vim expression that evaluates to one.
" Permitting arbitrary Vim expressions facilitates the use of complex tokrange
" selection logic, implemented by a user-defined expression or function.
"  Examples:
"      'g:My_tokrange_calculator()'
"      '&enc == "utf-8" ? "1400l" : "130s"' 
fu! s:Set_tokrange()
	" Undef variables that are outputs of this function. Note that these
	" variables are the decomposition of b:txtfmt_cfg_tokrange, which may or
	" may not be set at this point.
	unlet! b:txtfmt_cfg_starttok
		\ b:txtfmt_cfg_bgcolor b:txtfmt_cfg_longformats b:txtfmt_cfg_undercurl
		\ b:txtfmt_cfg_starttok_display b:txtfmt_cfg_formats_display
	" Cache the 'encoding' in effect
	let enc = &encoding
	" Determine the corresponding encoding class
	let enc_class = TxtfmtCommon_Encoding_get_class(enc)
	if !exists('b:txtfmt_cfg_tokrange') || strlen(b:txtfmt_cfg_tokrange) == 0
		" Either option wasn't set within modeline, or it was set to invalid
		" value.
		if exists('b:txtfmt_cfg_tokrange') && strlen(b:txtfmt_cfg_tokrange) == 0
			" Bad modeline set
			let l:warnmsg =
				\"Warning: Ignoring invalid modeline value for txtfmt `tokrange' option"
		elseif exists('b:txtfmtTokrange')
			" User overrode buf-local option. Save the option for validation
			" below...
			let b:txtfmt_cfg_tokrange = b:txtfmtTokrange
			let l:set_by = 'b'
		elseif exists('g:txtfmtTokrange')
			" User overrode global option. Save the option for validation
			" below...
			let b:txtfmt_cfg_tokrange = g:txtfmtTokrange
			let l:set_by = 'g'
		endif
	endif
	if exists('l:set_by') && (l:set_by == 'b' || l:set_by == 'g')
		" Perform special validation for buf-local/global settings, which
		" permits either a tokrange spec or a Vim expression that evaluates to
		" one.
		if !s:Tokrange_is_valid(b:txtfmt_cfg_tokrange)
			" Not a valid tokrange literal. Let's see whether it evaluates to
			" one.
			let v:errmsg = ''
			" Evaluate expression, using silent! to prevent problems in the
			" event that rhs is invalid.
			silent! exe 'let l:tokrange = '.b:txtfmt_cfg_tokrange
			if v:errmsg != ''
				" Bad expression
				let l:warnmsg =
					\"Warning: Ignoring invalid ".(l:set_by == 'b' ? 'buf-local' : 'global')
					\." value for txtfmt 'tokrange' option: ".b:txtfmt_cfg_tokrange
				" Discard the invalid setting
				let b:txtfmt_cfg_tokrange = ''
			else
				" It was a valid Vim expression. Did it produce a valid
				" tokrange spec?
				if !s:Tokrange_is_valid(l:tokrange)
					let l:warnmsg =
						\"Ignoring ".(l:set_by == 'b' ? 'buf-local' : 'global')
						\." set of txtfmt `tokrange' option: `".b:txtfmt_cfg_tokrange
						\."' produced invalid option value: ".l:tokrange
					" Discard the invalid setting
					let b:txtfmt_cfg_tokrange = ''
				else
					" Save the valid setting
					let b:txtfmt_cfg_tokrange = l:tokrange
				endif
			endif
		endif
	endif
	" Warn user if invalid user-setting is about to be overridden
	if exists('l:warnmsg')
		echoerr l:warnmsg
	endif
	" Decompose any valid user setting stored in b:txtfmt_cfg_tokrange.

	" Note: The output from the preceding stage is b:txtfmt_cfg_tokrange,
	" which we must now decompose into b:txtfmt_cfg_starttok,
	" b:txtfmt_cfg_bgcolor, b:txtfmt_cfg_longformats, b:txtfmt_cfg_undercurl,
	" b:txtfmt_cfg_starttok_display and b:txtfmt_cfg_formats_display. If
	" b:txtfmt_cfg_tokrange is nonexistent or null, there is no valid user
	" setting, in which case, we'll supply default.
	if exists('b:txtfmt_cfg_tokrange') && strlen(b:txtfmt_cfg_tokrange)
		" Decompose valid tokrange setting via s:Tokrange_translate_tokrange,
		" which sets all constituent variables.
		call s:Tokrange_translate_tokrange(b:txtfmt_cfg_tokrange)
		" Perform upper-bound validation
		if b:txtfmt_cfg_starttok +
			\ b:txtfmt_const_tokrange_size_{b:txtfmt_cfg_bgcolor}{b:txtfmt_cfg_longformats}{b:txtfmt_cfg_undercurl}
			\ - 1
			\ > b:txtfmt_const_tokrange_limit_{enc_class}
			" Warn user and use default
			echoerr
				\ "Warning: Tokrange value '".b:txtfmt_cfg_tokrange."' causes upper"
				\." bound to be exceeded for encoding ".&enc
			" Make sure we set to default below
			" Note: It suffices to unlet b:txtfmt_cfg_starttok, since its
			" nonexistence will ensure that all constituent vars are set below
			unlet! b:txtfmt_cfg_starttok
		endif
	endif
	" If b:txtfmt_cfg_starttok is still undefined, see whether there's an
	" encoding-specific default.
	" Note: b:txtfmt_cfg_starttok was unlet at the top of this function, so it
	" will be undefined unless it's been set successfully.
	if !exists('b:txtfmt_cfg_starttok')
		" TODO - Put any logic that depends upon specific encoding here...
		" .
		" .

	endif
	" If b:txtfmt_cfg_starttok is still undefined, see whether there's an
	" encoding-class-specific default.
	if !exists('b:txtfmt_cfg_starttok')
		" If encoding class is unrecognized, default to '1'
		if enc_class == ''
			let use_enc_class = '1'
		else
			let use_enc_class = enc_class
		endif
		" Pass default tokrange to function that will decompose it and set all
		" constituent variables.
		call s:Tokrange_translate_tokrange(
			\ b:txtfmt_const_starttok_def_{use_enc_class}
			\ . b:txtfmt_const_formats_def_{use_enc_class}
		\)
	endif
	" Note: If b:txtfmt_cfg_tokrange exists, we are done with it now that it
	" has been completely decomposed
	unlet! b:txtfmt_cfg_tokrange
	" Save the encoding class for later use (will be needed by Define_syntax
	" logic used to determine whether syn match offsets are byte or
	" char-based)
	let b:txtfmt_cfg_enc_class = enc_class
	" Also save encoding itself. If we're using a cached copy of encoding
	" class, we should be able to verify that the encoding upon which it is
	" based is the currently active one.
	let b:txtfmt_cfg_enc = enc
endfu
" >>>
" Function: s:Set_syncing() <<<
" Purpose: Set b:txtfmt_cfg_syncmethod and (if applicable) b:txtfmt_cfg_synclines
" options, according to the following logic:
" 1) If user set sync option via modeline, buffer-local option, or global
" option, attempt to use the setting with the highest priority.
" 2) If step 1 fails to set the option, either because of error or because the
" user made no attempt to set, default to minlines=250
" Note: From a user perspective, there is only the 'sync' option. For
" convenience within the plugin, we break this single option into two options:
" 'syncmethod' and 'synclines'. Currently, 'synclines' is used only when
" syncmethod=minlines.
fu! s:Set_syncing()
	if !exists('b:txtfmt_cfg_sync') || strlen(b:txtfmt_cfg_sync) == 0
		" Either option wasn't set within modeline, or it was set to invalid
		" value.
		if exists('b:txtfmt_cfg_sync') && strlen(b:txtfmt_cfg_sync) == 0
			" Bad modeline set
			let l:bad_set_by = 'm'
		elseif exists('b:txtfmtSync')
			" User overrode buf-local option
			if s:Sync_is_valid(b:txtfmtSync)
				let b:txtfmt_cfg_sync = b:txtfmtSync
			else
				let l:bad_set_by = 'b'
			endif
		elseif exists('g:txtfmtSync')
			" User overrode global option
			if s:Sync_is_valid(g:txtfmtSync)
				let b:txtfmt_cfg_sync = g:txtfmtSync
			else
				let l:bad_set_by = 'g'
			endif
		endif
	endif
	" Warn user if invalid user-setting is about to be overridden
	if exists('l:bad_set_by')
		" Note: Display the offending option value for buf-local or global
		" option, but not for modeline, since modeline processing has already
		" reported the error.
		echoerr "Warning: Ignoring invalid ".(
			\ l:bad_set_by == 'm' ? "modeline" :
			\ l:bad_set_by == 'b' ? "buf-local" :
			\ "global") . " value for txtfmt `sync' option" . (
			\ l:bad_set_by == 'm' ? '' :
			\ l:bad_set_by == 'b' ? (': ' . b:txtfmtSync) :
			\ (': ' . g:txtfmtSync)
	endif
	if !exists('b:txtfmt_cfg_sync') || strlen(b:txtfmt_cfg_sync) == 0
		" Set to default
		let b:txtfmt_cfg_syncmethod = 'minlines'
		let b:txtfmt_cfg_synclines = 250
	else
		" Decompose validated 'sync' option into 'syncmethod' and (if
		" applicable) 'synclines'
		let b:txtfmt_cfg_syncmethod = s:Sync_get_method(b:txtfmt_cfg_sync)
		if b:txtfmt_cfg_syncmethod == 'minlines'
			" Save the number of lines
			let b:txtfmt_cfg_synclines = (0 + b:txtfmt_cfg_sync)
		endif
	endif
	" We're done with b:txtfmt_cfg_sync now that it has been completely
	" decomposed.
	unlet! b:txtfmt_cfg_sync
endfu
" >>>
" Function: s:Translate_color_optstr() <<<
" Purpose: Process the string representing a single element from the array
" txtfmtColor{1..8}, and return the extracted information.
" Return: A comma-separated string containing the extracted information as
" follows:
" <namepat>,<ctermfg_rhs>,<guifg_rhs>
" Note that ctermfg_rhs and/or guifg_rhs may be blank, in the event that user
" specified term patterns and none of them matched. (If no term patterns are
" specified, there is an implied match with current &term value.)
" Note that return string will have commas and backslashes escaped.
" Note that the last color def that matches for each of guifg and ctermfg is
" the one that is returned to caller.
" Error: Set s:err_str and return empty string
" Details:
" Here is the format of a single string in the txtfmtColor{} array:
" <namepat>,<clrdef1>[,<clrdef2>,...,<clrdefN>]
" <clrdef> :=
" 	<c|g>[<termpatlist>]:<clrstr>
" 	<termpatlist> :=
" 		:<termpat1>:<termpat2>:...:<termpatN>
" *** Parse table ***
" st	next_st		can_end?	tok
" 0		1			n			<namepat>
" 1		2			n			,
" 2		3			n			<c|g>
" 3		4			n			:
" 4		5			n			str
" 5		4			y			:
" 5		2			y			,
" Example color optstr:
" red,c:xterm:dosterm:DarkRed,g:builtin_gui:other_gui:#FF0000
"
" Here are the meanings of the fields:
" <namepat>	-regex used to recognize the token used to specify a
" 	certain color; e.g., when prompted by one of the insert token maps. May
" 	not contain spaces or commas.
" 	Example: k\|b\%[lack]
" <c|g>				-specifies whether clrstr will be the rhs of a
" 	"ctermfg=" ('c'), or "guifg=" ('g')
" <termpat>	-pattern used to match against &term option. It is a regex pattern
" 	which will be applied as ^<termpat>$
" <clrstr>	-rhs of a "ctermfg=" or "guifg=" assignment.
" 	:help gui-colors | help cterm-colors
" Additional Note:
" Commas, colons, and backslashes appearing in fields must be
" backslash-escaped.
" Note: Due to the extra backslash escaping, it is recommended to use a
" string-literal, rather than double-quoted string.
fu! s:Translate_color_optstr(optstr)
	" optstr is the string to be parsed
	" Initialize the state machine
	let pst = 0
	" Initialize the parse engine to consider tokens to be broken only at
	" unescaped commas and colons.
	let pid = s:Parse_init(a:optstr, '\%(\\.\|[^,:]\)\+')
	if pid < 0
		let s:err_str = 'Internal error within s:Translate_color_optstr(). Contact developer.'
		echomsg 'Internal error'
		return ''
	endif
	" Extract and handle tokens in a loop
	let parse_complete = 0
	" The following 2 will be set in loop (hopefully at least 1 anyways)
	let ctermfg_rhs = ''
	let guifg_rhs = ''
	while !parse_complete
		let tok = s:Parse_nexttok(pid)
		" Note: Could handle end of string here for states in which end of
		" string is illegal - but that would make it more difficult to
		" formulate meaningful error messages.
		"if tok == '' && pst != 5
		"endif
		" Switch on the current state
		if pst == 0	" Extract non empty namepat
			let namepat = substitute(tok, '\\\(.\)', '\1', 'g')
			if namepat =~ '^[[:space:]]*$'
				let s:err_str = "Color def string must contain at least 1 non-whitespace char"
				return ''
			endif
			let pst = 1
		elseif pst == 1
			if tok == ','
				let pst = 2
			elseif tok == ''
				let s:err_str = "Expected comma, encountered end of color def string"
				return ''
			else
				let s:err_str = "Expected comma, got '".tok."'"
				return ''
			endif
		elseif pst == 2
			if tok == 'c' || tok == 'g'
				let pst = 3
				let c_or_g = tok
				" Do some initializations for this cterm/gui
				let tp_or_cs_cnt = 0
				let got_term_match = 0
			elseif tok == ''
				let s:err_str = "Expected 'c' or 'g', encountered end of color def string"
				return ''
			else
				let s:err_str = "Expected 'c' or 'g', got '".tok."'"
				return ''
			endif
		elseif pst == 3
			if tok == ':'
				let pst = 4
			elseif
				let s:err_str = "Expected ':', encountered end of color def string"
				return ''
			else
				let s:err_str = "Expected ':', got '".tok."'"
				return ''
			endif
		elseif pst == 4
			let pst = 5
			" Do some processing with this and possibly previous termpat or
			" clrstr token. Note that if previous one exists, it is termpat;
			" we can't yet know what current one is.
			let termpat_or_clrstr = substitute(tok, '\\\(.\)', '\1', 'g')
			if termpat_or_clrstr =~ '^[[:space:]]*$'
				let s:err_str = "Term patterns and color strings must contain at least one non-whitespace char"
				return ''
			endif
			" If here, update the count. Note that we won't know whether this
			" is termpat or clrstr until next time here.
			let tp_or_cs_cnt = tp_or_cs_cnt + 1
			if !got_term_match && tp_or_cs_cnt > 1
				" Process saved string as termpat
				" Pattern has implied ^ and $. Also, termpat may contain \c
				if &term =~ '^'.tp_or_cs_str.'$'
					" Found a match!
					let got_term_match = 1
				endif
			endif
			" Save current token for processing next time
			let tp_or_cs_str = termpat_or_clrstr
		elseif pst == 5
			if tok == ':'		" another termpat or clrstr
				let pst = 4
			elseif tok == ',' 	" another cterm/gui
				let pst = 2
			elseif tok == ''	" end of string - legal in state 5
				let parse_complete = 1
			else				" illegal token
				let s:err_str = "Unexpected input in color def string: ".tok
				return ''
			endif
			if tok == ',' || tok == ''
				" Need to process saved data from pst 4, which we now know to
				" be a clrstr.
				if tp_or_cs_cnt == 1 || got_term_match
					" Either no termpats were specified (implied match with
					" &term) or one of the termpats matched.
					" Note that prior ctermfg/guifg rhs strings may be
					" overwritten here, if more than one cterm/gui def exists
					" and has a match.
					if c_or_g == 'c'
						let ctermfg_rhs = tp_or_cs_str
					else
						let guifg_rhs = tp_or_cs_str
					endif
				endif
			endif
		endif
	endwhile
	" Construct the return string:
	" <namepat>,<ctermfg_rhs>,<guifg_rhs>
	let ret_str = escape(namepat, ',\').','
		\.escape(ctermfg_rhs, ',\').','.escape(guifg_rhs, ',\')
	return ret_str
endfu
" >>>
" Function: s:Get_color_uniq_idx() <<<
" Purpose: Convert the rhs of b:txtfmt_clr and b:txtfmt_bgc (if applicable) to
" a single string. Look the string up in global array
" g:txtfmt_color_configs{}. If the color config already exists, return its
" index; otherwise, append the color config to a new element at the end of
" g:txtfmt_color_configs{}, and return the corresponding index.
" Note: The index returned will be used to ensure that the highlight groups
" used for this buffer are specific to the color configuration.
" Input: none
" Return: Uniqueness index corresponding to the color configuration stored in
" b:txtfmt_clr and b:txtfmt_bgc (if applicable). In the unlikely event that no
" colors are active in the current configuration (i.e., numfgcolors and
" numbgcolors both equal 0), we return an empty string.
fu! s:Get_color_uniq_idx()
	" Build the string to be looked up
	let s = ''
	let fgbg_idx = 0
	let clr_or_bgc{0} = 'clr'
	let clr_or_bgc{1} = 'bgc'
	let fg_or_bg{0} = 'fg'
	let fg_or_bg{1} = 'bg'
	while fgbg_idx < (b:txtfmt_cfg_bgcolor ? 2 : 1)
		" Loop over all used colors
		" TODO_BG: Does it make sense to include unused ones? It shouldn't be
		" necessary...
		" Note: Index 1 corresponds to first non-default color
		let i = 1
		while i <= b:txtfmt_cfg_num{fg_or_bg{fgbg_idx}}colors
			let s = s.b:txtfmt_{clr_or_bgc{fgbg_idx}}{i}."\<NL>"
			let i = i + 1
		endwhile
		let fgbg_idx = fgbg_idx + 1
	endwhile
	" In the unlikely event that string is still empty, config is such that no
	" colors are in use, in which case, we return an empty string, since no
	" uniqueness index applies.
	if strlen(s) == 0
		return ''
	endif
	" Look up the newly-generated string in g:txtfmt_color_configs
	if !exists('g:txtfmt_color_configs_len')
		let g:txtfmt_color_configs_len = 0
	endif
	let i = 0
	while i < g:txtfmt_color_configs_len
		if g:txtfmt_color_configs{i} == s
			" Color config exists already - return its index
			return i
		endif
		let i = i + 1
	endwhile
	" If here, color config doesn't exist yet, so append it
	let g:txtfmt_color_configs{i} = s
	let g:txtfmt_color_configs_len = g:txtfmt_color_configs_len + 1
	" Return index of appended element
	return i
endfu
" >>>
" Function: s:Process_color_options() <<<
" Purpose: Process the special color definition arrays to determine the color
" arrays in effect for the current buffer. There are global and buffer-local
" versions of both txtfmtColor and txtfmtBgcolor, as well as a default in
" s:txtfmt_clr. From these, we construct the 8 element buf-local arrays,
" described under 'Return:' below.
" Algorithm: Each color index is considered independently of all others, with
" a buf-local definition taking precedence over a global one. A txtfmtBgcolor
" element is always preferred for background color, but txtfmtColor will be
" used for a background color when no background-color-specific element
" exists. If no other element can be found, defaults from s:txtfmt_clr will be
" used.
" Cterm and gui may be overridden separately, and color definition strings may
" even take into account the value of &term. Note that for each possible
" element in the array, there is a default element (in s:txtfmt_clr{1..8}),
" which will be used if user has not overriden.
" Return: indirect only
" Builds the following buffer-scope arrays: (indexed by 1-based color index)
" b:txtfmt_clr_namepat{}, b:txtfmt_clr{}
" b:txtfmt_bgc_namepat{}, b:txtfmt_bgc{}
" Note: bgc arrays will not be built if background colors are disabled.
" Details: The format of the color array is as follows:
" The array has 8 elements (1..8), each of which represents a color region
" begun with one of the 8 successive color tokens in the token range. Each
" element is a string whose format is described in header of
" s:Translate_color_optstr()
" Rules: In outer loop over fg and bg cases, and inner loop over all color
" indices in range i = 1..8, check all applicable variants of the txtfmtColor
" array (as defined in arrname{}) for an element corresponding to the current
" color index. Set b:txtfmt_clr{} and move to next color index as soon as a
" suitable definition is found. Suitability is determined by checking
" has('gui_running') against the 'g:' or 'c:' in the color definition string,
" and if necessary, by matching the current value of 'term' against a 'term'
" pattern in the color definition string.
" Note: This function was rewritten on 10May2008, and then again on 31Jan2009.
" A corresponding partial rewrite of s:Translate_color_optstr is probably in
" order, but is not necessary, so I've left the latter function completely
" intact for now. (We don't really need both ctermfg and guifg values any
" more, but s:Translate_color_optstr still returns both...)
fu! s:Process_color_options()
	let arrname{0} = 'b:txtfmtBgcolor'
	let arrname{1} = 'g:txtfmtBgcolor'
	let arrname{2} = 'b:txtfmtColor'
	let arrname{3} = 'g:txtfmtColor'
	let arrname{4} = 's:txtfmt_clr'
	" TODO_BG: Decide whether s:txtfmt_bgc should be removed - if so, may get
	" rid of arr_end{}
	" Define strings used to build appropriate var names for both fg and bg
	let clr_or_bgc{0} = 'clr'
	let clr_or_bgc{1} = 'bgc'
	" Frame the array for fg and bg
	" Note: Could use a common value for end.
	let arr_beg{0} = 2
	let arr_end{0} = 4
	let arr_beg{1} = 0
	let arr_end{1} = 4
	" Determine arrays that don't apply to fg color
	let skip{0}_{0} = 1
	let skip{0}_{1} = 1
	let skip{0}_{2} = 0
	let skip{0}_{3} = 0
	let skip{0}_{4} = 0
	if b:txtfmt_cfg_bgcolor
		" Determine arrays that don't apply to bg color
		let skip{1}_{0} = 0
		let skip{1}_{1} = 0
		let skip{1}_{2} = 0
		let skip{1}_{3} = 0
		let skip{1}_{4} = 0
	endif
	" Loop over fg and bg color (if applicable)
	let fgbg_idx = 0
	while fgbg_idx < (b:txtfmt_cfg_bgcolor ? 2 : 1)
		let i = 1
		" Loop over all colors (1st non-default color at index 1)
		while i < b:txtfmt_num_colors
			" Init strings to value signifying not specified or error
			let namepat = '' | let clr_rhs = ''
			" Loop over the possible color arrays
			let j = arr_beg{fgbg_idx}
			while j <= arr_end{fgbg_idx}
				" Skip inapplicable arrays
				if skip{fgbg_idx}_{j}
					let j = j + 1
					continue
				endif
				" Skip nonexistent color definitions
				if exists(arrname{j}.'{'.i.'}')
					exe 'let l:el = '.arrname{j}.'{'.i.'}'
					" If here, color definition exists. Let's see whether it contains
					" a match...
					let s = s:Translate_color_optstr(el)
					if s != ''
						" Extract fields from the escaped return string (which is
						" internally generated, and hence, does not require
						" validation)
						" TODO - Perhaps standardize this in one spot (function or
						" static return variables)
						let re_fld = '\%(\%(\\.\|[^,]\)*\)'
						let re_sfld = '\(\%(\\.\|[^,]\)*\)'
						let namepat = substitute(s, re_sfld.'.*', '\1', '')
						if has('gui_running')
							let clr_rhs = substitute(s, re_fld.','.re_fld.','.re_sfld, '\1', '')
						else
							let clr_rhs = substitute(s, re_fld.','.re_sfld.'.*', '\1', '')
						endif
						" Note: clr_rhs may be null at this point; if so, there
						" was no applicable color definition, though the color def
						" element was valid
						if strlen(clr_rhs)
							" Remove extra level of backslashes
							let namepat = substitute(namepat, '\\\(.\)', '\1', 'g')
							let clr_rhs = substitute(clr_rhs, '\\\(.\)', '\1', 'g')
						endif
					elseif arrname{j}[0] == 'b' || arrname{j}[0] == 'g'
						echomsg "Ignoring invalid user-specified color def ".arrname{j}.i." due to error: "
							\.s:err_str
					else
						" Shouldn't get here! Problem with defaults...
						echomsg "Internal error within Process_color_options - bad default for txtfmtColors"
							\.i." - contact developer."
					endif
					" Are we done yet?
					if strlen(clr_rhs)
						break
					endif
				endif
				let j = j + 1
			endwhile
			" Assumption: Lack of color rhs at this point implies internal error.
			" Build the buffer-specific array used in syntax file...
			" Note: In the following 2 arrays, an index of 1 corresponds to the
			" first non-default color.
			let b:txtfmt_{clr_or_bgc{fgbg_idx}}_namepat{i} = namepat
			let b:txtfmt_{clr_or_bgc{fgbg_idx}}{i} = clr_rhs
			" Advance to next color
			let i = i + 1
		endwhile
		let fgbg_idx = fgbg_idx + 1
	endwhile
	" Now that the color configuration is completely determined (and loaded
	" into b:txtfmt_clr{} (and b:txtfmt_bgc{} if applicable)), determine the
	" 'uniqueness index' for this color configuration. The uniqueness index is
	" used to ensure that each color configuration has its own set of syntax
	" groups.
	" TODO_BG: Is the _cfg_ infix appropriate for such variables? For now, I'm
	" using it only for option vars (with one exception that needs looking at)
	let b:txtfmt_color_uniq_idx = s:Get_color_uniq_idx()
endfu
" >>>
" Function: s:Process_txtfmt_modeline() <<<
" Purpose: Determine whether input line is a valid txtfmt modeline. Process
" options if so. If required by s:txtfmt_ml_new_<...> variables, change
" options in the modeline itself. (Example: change 'tokrange' as requested by
" preceding call to :MoveStartTok command.)
" Note: Input line may be either a valid line number or a string representing
" a valid modeline (which is constructed by the caller)
" Return:
" 0		- no txtfmt modeline found
" -1	- txtfmt modeline containing error (bad option)
" 1		- valid txtfmt modeline found and processed
" Note: Modeline format is described under function s:Is_txtfmt_modeline.
fu! s:Process_txtfmt_modeline(line)
	if a:line =~ '^[1-9][0-9]*$'
		" Obtain the line to be processed
		let l:line = a:line
		let linestr = getline(a:line)
	else
		" The line to be processed is not in the buffer
		let l:line = 0
		let linestr = a:line
	endif
	" Is the line a modeline?
	if !s:Is_txtfmt_modeline(linestr)
		" Note: This is not considered error - the line is simply not a
		" modeline
		return 0
	endif
	" If here, overall format is correct. Are all options valid?
	" Assume valid modeline until we find out otherwise...
	let ret_val = 1
	" Save the leading text, in case we need to create a version of the line
	" with changed options (e.g., starttok change)
	let leading = substitute(linestr, s:re_modeline, '\1', '')
	" The middle (options) part will be built up as we go
	let middle = ''
	" Save the trailing stuff
	let trailing = substitute(linestr, s:re_modeline, '\3', '')
	" Extract the {options} portion (leading/trailing stuff removed) for
	" processing
	let optstr = substitute(linestr, s:re_modeline, '\2', '')
	" Extract pieces from head of optstr as long as unprocessed options exist
	" Note: The following pattern may be used to extract element separators
	" into \1, opt name into \2, opt value (if it exists) into \3, and to
	" strip all three from the head of the string. (The remainder of the
	" modeline will be in \4.)
	" Note: Element separator is optional in the following re, since it won't
	" exist for first option, and we've already verified that it exists
	" between all other options.
	let re_opt = '\('.s:re_ml_elsep.'\)\?\('
				\.s:re_ml_name.'\)\%(=\('.s:re_ml_val.'\)\)\?\(.*\)'
	" If this is a real buffer line, do some special processing required only
	" when modeline options are being changed or added
	if l:line > 0
		" Set this flag if we make a requested change to an option, which needs to
		" be reflected in the actual modeline text in the buffer (e.g., starttok
		" change)
		unlet! line_changed
		" If we haven't done so already, save location at which new options can be
		" added.
		if !exists('s:txtfmt_ml_addline')
			let s:txtfmt_ml_addline = l:line
			" Note: The +1 changes 0-based byte index to 1-based col index
			" Note: Saved value represents the col number of the first char to be
			" added
			let s:txtfmt_ml_addcol = matchend(linestr, s:re_ml_start) + 1
		endif
	endif
	" Loop over all options, exiting loop early if error occurs
	while strlen(optstr) > 0 && ret_val != -1
		" Accumulate the option separator text
		let middle = middle.substitute(optstr, re_opt, '\1', '')
		" Extract option name and value
		let optn = substitute(optstr, re_opt, '\2', '')
		let optv = substitute(optstr, re_opt, '\3', '')
		" Remove the option about to be processed from head of opt str
		let optstr = substitute(optstr, re_opt, '\4', '')
		" Validate the option(s)
		if optn == 'tokrange' || optn == 'rng'
			"format: tokrange=<char_code>[sSlLxX]
			"Examples: '130s' '1500l' '130' '0x2000L'
			if !s:Tokrange_is_valid(optv)
				" 2 cases when option is invalid:
				" 1) We can fix the invalid tokrange by changing to the value
				"    specified by user in call to :MoveStartTok
				" 2) We must display error and use default
				if exists('s:txtfmt_ml_new_starttok')
					" Design Decision: Since option value is not valid, don't
					" attempt to preserve any existing 'formats' specifier
					" Assumption: b:txtfmt_cfg_bgcolor,
					" b:txtfmt_cfg_longformats, and b:txtfmt_cfg_undercurl are
					" unlet *only* at the top of Set_tokrange; thus, we can
					" assume they will be valid here.
					let optv = s:txtfmt_ml_new_starttok
						\.b:txtfmt_const_tokrange_suffix_{b:txtfmt_cfg_bgcolor}{b:txtfmt_cfg_longformats}{b:txtfmt_cfg_undercurl}
					" Record fact that change was made
					unlet s:txtfmt_ml_new_starttok
					let line_changed = 1
				else
					let s:err_str = "Invalid 'tokrange' value - must be hex or dec"
								\." char code value optionally followed by one of [sSlLxX]"
					" Note: 'XL' suffix is currently illegal, but give a special
					" warning if user attempts to use it.
					if optv =~? 'xl$'
						let s:err_str = s:err_str
							\." (The XL suffix is currently illegal, due to a memory resource limitation"
							\." affecting current versions of Vim; this suffix may, however, be supported in"
							\." a future release.)"
					endif
					" Record the attempt to set b:txtfmt_cfg_tokrange from modeline
					let b:txtfmt_cfg_tokrange = ''
					let ret_val = -1
				endif
			else
				if exists('s:txtfmt_ml_new_starttok')
					" Change the starttok value, preserving both the starttok
					" number format (note that s:txtfmt_ml_new_starttok is
					" actually a string) and any existing 'formats'
					" specification
					" Note: Since modeline setting trumps all others, an
					" existing setting should agree with current setting
					" anyway.
					let optv = substitute(optv, b:txtfmt_re_number_atom, s:txtfmt_ml_new_starttok, '')
					" Record fact that change was made
					unlet s:txtfmt_ml_new_starttok
					let line_changed = 1
				endif
				" Save the option value, deferring processing till later...
				let b:txtfmt_cfg_tokrange = optv
			endif
		elseif optn == 'fgcolormask' || optn == 'fcm'
			if !s:Clrmask_is_valid(optv)
				" Invalid number of colors
				let s:err_str = "Invalid foreground color mask - must be string of 8 ones and zeroes"
				let b:txtfmt_cfg_fgcolormask = ''
				let ret_val = -1
			else
				let b:txtfmt_cfg_fgcolormask = optv
			endif
		elseif optn == 'bgcolormask' || optn == 'bcm'
			if !s:Clrmask_is_valid(optv)
				" Invalid number of colors
				let s:err_str = "Invalid background color mask - must be string of 8 ones and zeroes"
				let b:txtfmt_cfg_bgcolormask = ''
				let ret_val = -1
			else
				let b:txtfmt_cfg_bgcolormask = optv
			endif
		elseif optn == 'sync'
			"format: sync={<hex>|<dec>|fromstart|none}
			"Examples: 'sync=300' 'sync=0x1000' 'sync=fromstart' 'sync=none'
			if !s:Sync_is_valid(optv)
				let s:err_str = "Invalid 'sync' value - must be one of the"
							\." following: <numeric literal>, 'fromstart'"
							\.", 'none'"
				" Record the attempt to set b:txtfmt_cfg_sync from modeline
				let b:txtfmt_cfg_sync = ''
				let ret_val = -1
			else
				" Defer processing of sync till later
				let b:txtfmt_cfg_sync = optv
			endif
		elseif optn =~ '^\(no\)\?\(pack\|pck\)$'
			" Make sure no option value was supplied to binary option
			if strlen(optv)
				let s:err_str = "Cannot assign value to binary txtfmt option 'pack'"
				let b:txtfmt_cfg_pack = ''
				let ret_val = -1
			else
				" Option has been explicitly turned on or off
				let b:txtfmt_cfg_pack = optn =~ '^no' ? 0 : 1
			endif
		elseif optn =~ '^\(no\)\?\(undercurl\|uc\)$'
			" Make sure no option value was supplied to binary option
			if strlen(optv)
				let s:err_str = "Cannot assign value to binary txtfmt option 'undercurl'"
				let b:txtfmt_cfg_undercurlpref = ''
				let ret_val = -1
			else
				" Option has been explicitly turned on or off
				let b:txtfmt_cfg_undercurlpref = optn =~ '^no' ? 0 : 1
			endif
		elseif optn =~ '^\(no\)\?\(nested\|nst\)$'
			" Make sure no option value was supplied to binary option
			if strlen(optv)
				let s:err_str = "Cannot assign value to binary txtfmt option 'nested'"
				let b:txtfmt_cfg_nested = ''
				let ret_val = -1
			else
				" Option has been explicitly turned on or off
				let b:txtfmt_cfg_nested = optn =~ '^no' ? 0 : 1
			endif
		elseif optn =~ '^\(no\)\?\(conceal\|cncl\)$'
			" Make sure no option value was supplied to binary option
			if strlen(optv)
				let s:err_str = "Cannot assign value to binary txtfmt option 'conceal'"
				let b:txtfmt_cfg_conceal = ''
				let ret_val = -1
			else
				" Option has been explicitly turned on or off
				let b:txtfmt_cfg_conceal = optn =~ '^no' || !has('conceal') ? 0 : 1
			endif
		elseif optn == 'escape' || optn == 'esc'
			"format: escape=[bslash|self|none]
			if optv == 'bslash'
				let b:txtfmt_cfg_escape = 'bslash'
			elseif optv == 'self'
				let b:txtfmt_cfg_escape = 'self'
			elseif optv == 'none'
				let b:txtfmt_cfg_escape = 'none'
			else
				let s:err_str = "Invalid 'escape' value - must be 'bslash', 'self', or 'none'"
				let b:txtfmt_cfg_escape = ''
				let ret_val = -1
			endif
		else
		   let s:err_str = "Unknown txtfmt modeline option: ".optn
		   let ret_val = -1
		endif
		" Append optn[=optv] to middle
		let middle = middle.optn.(strlen(optv) ? '='.optv : '')
	endwhile
	" Processed txtfmt modeline without error
	if l:line > 0 && exists('line_changed')
		" Alter the line to reflect any option changes
		" Note: If error occurred above, optstr may be non-empty, in which
		" case, we need to append it to the already processed options in
		" middle.
		call setline(l:line, leading.middle.optstr.trailing)
	endif
	return ret_val
endfu
" >>>
" Function: s:Do_txtfmt_modeline() <<<
" Purpose: Look for txtfmt "modelines" of the following form:
" .\{-}<whitespace>txtfmt:<definitions>:
" which appear within the first or last 'modelines' lines in the buffer.
" Note: Function will search a number of lines (at start and end of buffer),
" as determined from 'modelines', provided that this value is nonzero. If
" 'modelines' is 0, default of 5 lines at beginning and end will be searched.
" Return:
" 0     - no txtfmt modeline found
" N     - N valid txtfmt modelines found and processed
" -N    - txtfmt modeline processing error occurred on the Nth modeline
"         processed
" Error_handling: If error is encountered in a modeline, the remainder of
" the offending modeline is discarded, and modeline processing is aborted;
" i.e., no more lines are searched. This is consistent with the way Vim's
" modeline processing works.
" Modeline_modifications: The following buf-local variables are considered to
" be inputs that request changes to existing modelines:
" b:txtfmt_ml_new_starttok
" ...
" If the requested change can't be made, we will attempt to add the requested
" setting to an existing modeline. If there are no existing modelines, we will
" add a new one (warning user if he has modeline processing turned off). If
" modifications are made to the buffer, we will use b:txtfmt_ml_save_modified
" to determine whether the buffer was in a modified state prior to our
" changes, and will save our changes if and only if doing so doesn't commit
" any unsaved user changes.
" Assumption: Another Txtfmt function sets b:txtfmt_ml_save_modified
" appropriately before the Txtfmt-initiated changes begin.
fu! s:Do_txtfmt_modeline()
	" Check for request to change starttok
	if exists('b:txtfmt_ml_new_starttok')
		" Communicate the request to modeline processing function.
		let s:txtfmt_ml_new_starttok = b:txtfmt_ml_new_starttok
		" Unlet the original to ensure that if we abort with error, we don't
		" do this next time
		unlet! b:txtfmt_ml_new_starttok
	else
		" Clean up after any previous failed attempts
		unlet! s:txtfmt_ml_new_starttok
	endif
	" Did someone anticipate that we might be modifying the buffer?
	if exists('b:txtfmt_ml_save_modified')
		let l:save_modified = b:txtfmt_ml_save_modified
		unlet b:txtfmt_ml_save_modified
	endif
	" The following apply to any option change request. They're set within
	" Process_txtfmt_modeline the first time a suitable add location is found
	unlet! s:txtfmt_ml_addline
	unlet! s:txtfmt_ml_addcol

	" Keep up with # of modelines actually encountered
	let l:ml_seen = 0
	" How many lines should we search?
	" Priority is given to txtfmtModelines user option if it exists
	if exists('b:txtfmtModelines') || exists('g:txtfmtModelines')
		" User can disable by setting to 0
		let mls_use = exists('b:txtfmtModelines') ? b:txtfmtModelines : g:txtfmtModelines
	else
		" Use 'modelines' option+1 unless it's not a valid nonzero value, in
		" which case, we use default of 5
		" NOTE: 1 is added to 'modelines' option so that if modeline is at
		" highest or lowest possible line, putting a txtfmt modeline above or
		" below it, respectively, will work.
		let mls_use = &modelines > 0 ? &modelines+1 : 5
	endif
	let nlines = line('$')
	" Check first modelines lines
	" TODO - Combine the 2 loops into one, which can alter the loop counter in
	" a stepwise manner.
	let i = 1
	while i <= mls_use && i <= nlines
		let status = s:Process_txtfmt_modeline(i)
		if status == 1
			 " Successfully extracted options
			 let l:ml_seen = l:ml_seen + 1
		elseif status == -1
			 " Error processing the modeline
			 echoerr "Ignoring txtfmt modeline on line ".i.": ".s:err_str
			 return -(l:ml_seen + 1)
		endif
		" Keep looking...
		let i = i + 1
	endwhile
	" Check last modelines lines
	let i = nlines - mls_use + 1
	" Adjust if necessary to keep from checking already checked lines
	if i <= mls_use
		let i = mls_use + 1
	endif
	while i <= nlines
		let status = s:Process_txtfmt_modeline(i)
		if status == 1
			 " Successfully extracted options
			 let l:ml_seen = l:ml_seen + 1
		elseif status == -1
			 " Error processing the modeline
			 echoerr "Ignoring txtfmt modeline on line ".i.": ".s:err_str
			 return -(l:ml_seen + 1)
		endif
		" Keep looking...
		let i = i + 1
	endwhile
	" Deal with any unprocessed requests for modeline option changes
	" Note: Process_txtfmt_modeline unlets s:txtfmt_ml_new_<...> vars that
	" have been completely handled.
	let l:ml_new_opts = ''
	if exists('s:txtfmt_ml_new_starttok')
		" TODO: Decide whether it matters that this strategy will put a
		" useless space at end of modeline in the unlikely event that the
		" original modeline contained no options
		" Assumption: b:txtfmt_cfg_bgcolor, b:txtfmt_cfg_longformats, and
		" b:txtfmt_cfg_undercurl are unlet *only* at the top of Set_tokrange;
		" thus, we can assume they will be valid here.
		let l:ml_new_opts = l:ml_new_opts
			\.'tokrange='
			\.s:txtfmt_ml_new_starttok
			\.b:txtfmt_const_tokrange_suffix_{b:txtfmt_cfg_bgcolor}{b:txtfmt_cfg_longformats}{b:txtfmt_cfg_undercurl}
			\.' '
	endif
	" Any additional requests would go here
	" ...
	" Do we have any options to add?
	if strlen(l:ml_new_opts)
		" Create the modeline that will be passed to Process_txtfmt_modeline
		let l:ml_process = "\<Tab>txtfmt:".l:ml_new_opts
		" Add what needs to be added to the buffer
		if exists('s:txtfmt_ml_addline')
			" Add new options to existing modeline
			let linestr = getline(s:txtfmt_ml_addline)
			" Recreate the line
			call setline(s:txtfmt_ml_addline,
				\ strpart(linestr, 0, s:txtfmt_ml_addcol - 1)
				\ . l:ml_new_opts
				\ . strpart(linestr, s:txtfmt_ml_addcol - 1))
		else
			" Create a new txtfmt modeline on first line. Note that it's the
			" same as what will be passed to Process_txtfmt_modeline for
			" processing.
			call append(0, l:ml_process)
			if mls_use == 0
				" Warn user that he should change his modelines setting
				" TODO_BG: Figure out how to prevent the warning from
				" disappearing after a second or two.
				echomsg "Warning: Txtfmt has added option settings to a modeline at the beginning"
					\." of the buffer, but your modeline setting is such that this modeline"
					\." will be ignored next time the buffer is opened."
					\." (:help txtfmtModelines)"
			endif
			" Record fact that we've processed another modeline
			let l:ml_seen = l:ml_seen + 1
		endif
		" Process only the options just added
		let status = s:Process_txtfmt_modeline(l:ml_process)
		" Note: Error should be impossible here, but just in case...
		if status < 0
			echoerr "Internal error: Unexpected error while processing txtfmt-generated modeline: ".s:err_str.". Contact the developer"
			return -(l:ml_seen)
		elseif status == 0
			echoerr "Internal error: Failed to extract option(s) while processing txtfmt-generated modeline. Contact the developer"
			return -(l:ml_seen)
		endif
	endif
	" If modeline processing made an unmodified buffer modified, save our
	" changes now. (Rationale: Leave the buffer in the state it was in prior
	" to modeline processing. This avoids making user's unsaved changes
	" permanent.)
	if exists('l:save_modified') && !l:save_modified && &modified
		write
	endif
	" If here, we encountered no error. Return the number of modelines
	" processed (could be zero)
	return l:ml_seen
endfu
" >>>
" Function: s:Process_clr_masks() <<<
" Inputs:
" b:txtfmt_cfg_fgcolormask
" b:txtfmt_cfg_bgcolormask
" Description: Each mask is a string of 8 chars, each of which must be either
" '0' or '1'
" Outputs:
" b:txtfmt_cfg_fgcolor{} b:txtfmt_cfg_numfgcolors
" b:txtfmt_cfg_bgcolor{} b:txtfmt_cfg_numbgcolors
" Description: The <fg|bg>color arrays are 1-based indirection arrays, which
" contain a single element for each of the active colors. The elements of
" these arrays are the 1-based indices of the corresponding color in the
" actual color definition array (which always contains 8 elements).
" Note: num<fg|bg>colors will be 0 and corresponding array will be empty if
" there are no 1's in the <fg|bg>colormask
" Note: If 'tokrange' setting precludes background colors, the bg colormask
" option will be all 0's at this point, regardless of how user has configured
" the option.
fu! s:Process_clr_masks()
	" Loop over fg and bg
	let fgbg_idx = 0
	let fg_or_bg{0} = 'fg'
	let fg_or_bg{1} = 'bg'
	while fgbg_idx < 2
		" Cache the mask to be processed
		let mask = b:txtfmt_cfg_{fg_or_bg{fgbg_idx}}colormask
		" Note: To be on the safe side, I'm going to zero the bg color mask
		" whenever bg colors are disabled, just in case caller forgot.
		if fg_or_bg{fgbg_idx} == 'bg' && !b:txtfmt_cfg_bgcolor && mask =~ '1'
			let mask = '00000000'
		endif
		" Loop over all 8 'bits' in the mask
		" Assumption: The mask length has already been validated
		" Note: All color arrays processed are 1-based (since index 0, if it
		" exists, corresponds to 'no color'), but mask bit 'array' is
		" inherently 0-based (because it's a string)
		let i = 0
		let iadd = 0
		while i < 8
			if mask[i] == '1'
				" Append this color's (1-based) index to active color array
				" (which is also 1-based)
				let iadd = iadd + 1
				let b:txtfmt_cfg_{fg_or_bg{fgbg_idx}}color{iadd} = i + 1
			endif
			let i = i + 1
		endwhile
		" Store number of active colors
		let b:txtfmt_cfg_num{fg_or_bg{fgbg_idx}}colors = iadd
		" Prepare for next iteration
		let fgbg_idx = fgbg_idx + 1
	endwhile
endfu
" >>>
" Function: s:Define_fmtclr_vars() <<<
fu! s:Define_fmtclr_vars()
	" Format definition array <<<
	" NOTE: This array is used for rhs of syntax definitions, but also for display
	" by ShowTokenMap.
	let b:txtfmt_fmt{0}  = 'NONE'
	let b:txtfmt_fmt{1}  = 'underline'
	let b:txtfmt_fmt{2}  = 'bold'
	let b:txtfmt_fmt{3}  = 'underline,bold'
	let b:txtfmt_fmt{4}  = 'italic'
	let b:txtfmt_fmt{5}  = 'underline,italic'
	let b:txtfmt_fmt{6}  = 'bold,italic'
	let b:txtfmt_fmt{7}  = 'underline,bold,italic'
	if !b:txtfmt_cfg_longformats
		" short formats
		let b:txtfmt_num_formats = 8
	else
		" long formats
		let b:txtfmt_fmt{8}  = 'standout'
		let b:txtfmt_fmt{9}  = 'underline,standout'
		let b:txtfmt_fmt{10} = 'bold,standout'
		let b:txtfmt_fmt{11} = 'underline,bold,standout'
		let b:txtfmt_fmt{12} = 'italic,standout'
		let b:txtfmt_fmt{13} = 'underline,italic,standout'
		let b:txtfmt_fmt{14} = 'bold,italic,standout'
		let b:txtfmt_fmt{15} = 'underline,bold,italic,standout'
		let b:txtfmt_fmt{16} = 'reverse'
		let b:txtfmt_fmt{17} = 'underline,reverse'
		let b:txtfmt_fmt{18} = 'bold,reverse'
		let b:txtfmt_fmt{19} = 'underline,bold,reverse'
		let b:txtfmt_fmt{20} = 'italic,reverse'
		let b:txtfmt_fmt{21} = 'underline,italic,reverse'
		let b:txtfmt_fmt{22} = 'bold,italic,reverse'
		let b:txtfmt_fmt{23} = 'underline,bold,italic,reverse'
		let b:txtfmt_fmt{24} = 'standout,reverse'
		let b:txtfmt_fmt{25} = 'underline,standout,reverse'
		let b:txtfmt_fmt{26} = 'bold,standout,reverse'
		let b:txtfmt_fmt{27} = 'underline,bold,standout,reverse'
		let b:txtfmt_fmt{28} = 'italic,standout,reverse'
		let b:txtfmt_fmt{29} = 'underline,italic,standout,reverse'
		let b:txtfmt_fmt{30} = 'bold,italic,standout,reverse'
		let b:txtfmt_fmt{31} = 'underline,bold,italic,standout,reverse'
		" If using undercurl (introduced in Vim 7.0), there will be twice as
		" many formats.
		if !b:txtfmt_cfg_undercurl
			let b:txtfmt_num_formats = 32
		else
			let b:txtfmt_fmt{32} = 'undercurl'
			let b:txtfmt_fmt{33} = 'underline,undercurl'
			let b:txtfmt_fmt{34} = 'bold,undercurl'
			let b:txtfmt_fmt{35} = 'underline,bold,undercurl'
			let b:txtfmt_fmt{36} = 'italic,undercurl'
			let b:txtfmt_fmt{37} = 'underline,italic,undercurl'
			let b:txtfmt_fmt{38} = 'bold,italic,undercurl'
			let b:txtfmt_fmt{39} = 'underline,bold,italic,undercurl'
			let b:txtfmt_fmt{40} = 'standout,undercurl'
			let b:txtfmt_fmt{41} = 'underline,standout,undercurl'
			let b:txtfmt_fmt{42} = 'bold,standout,undercurl'
			let b:txtfmt_fmt{43} = 'underline,bold,standout,undercurl'
			let b:txtfmt_fmt{44} = 'italic,standout,undercurl'
			let b:txtfmt_fmt{45} = 'underline,italic,standout,undercurl'
			let b:txtfmt_fmt{46} = 'bold,italic,standout,undercurl'
			let b:txtfmt_fmt{47} = 'underline,bold,italic,standout,undercurl'
			let b:txtfmt_fmt{48} = 'reverse,undercurl'
			let b:txtfmt_fmt{49} = 'underline,reverse,undercurl'
			let b:txtfmt_fmt{50} = 'bold,reverse,undercurl'
			let b:txtfmt_fmt{51} = 'underline,bold,reverse,undercurl'
			let b:txtfmt_fmt{52} = 'italic,reverse,undercurl'
			let b:txtfmt_fmt{53} = 'underline,italic,reverse,undercurl'
			let b:txtfmt_fmt{54} = 'bold,italic,reverse,undercurl'
			let b:txtfmt_fmt{55} = 'underline,bold,italic,reverse,undercurl'
			let b:txtfmt_fmt{56} = 'standout,reverse,undercurl'
			let b:txtfmt_fmt{57} = 'underline,standout,reverse,undercurl'
			let b:txtfmt_fmt{58} = 'bold,standout,reverse,undercurl'
			let b:txtfmt_fmt{59} = 'underline,bold,standout,reverse,undercurl'
			let b:txtfmt_fmt{60} = 'italic,standout,reverse,undercurl'
			let b:txtfmt_fmt{61} = 'underline,italic,standout,reverse,undercurl'
			let b:txtfmt_fmt{62} = 'bold,italic,standout,reverse,undercurl'
			let b:txtfmt_fmt{63} = 'underline,bold,italic,standout,reverse,undercurl'
			let b:txtfmt_num_formats = 64
		endif
	endif
	" >>>
	" <<< Default color definition array
	" These are the original defaults
	let s:txtfmt_clr{1} = '^\\%(k\\|bla\\%[ck]\\)$,c:Black,g:#000000'
	let s:txtfmt_clr{2} = '^b\\%[lue]$,c:DarkBlue,g:#0000FF'
	let s:txtfmt_clr{3} = '^g\\%[reen]$,c:DarkGreen,g:#00FF00'
	let s:txtfmt_clr{4} = '^t\\%[urquoise]$,c:LightGreen,g:#00FFFF'
	let s:txtfmt_clr{5} = '^r\\%[ed]$,c:DarkRed,g:#FF0000'
	let s:txtfmt_clr{6} = '^v\\%[iolet]$,c:DarkMagenta,g:#FF00FF'
	let s:txtfmt_clr{7} = '^y\\%[ellow]$,c:DarkYellow,g:#FFFF00'
	let s:txtfmt_clr{8} = '^w\\%[hite]$,c:White,g:#FFFFFF'
	" Note: The following variable indicates the total number of colors
	" possible, including 'no color', which is not in the txtfmt_clr array.
	" TODO: See how this is used to see how to use numfgcolors and numbgcolors...
	let b:txtfmt_num_colors = 9
	" >>>
	" Set fmt/clr specific values for convenience
	" txtfmt_<rgn>_first_tok:      1st (default) token
	" txtfmt_<rgn>_last_tok:       last (reserved) token
	" txtfmt_last_tok:             last token that could be used (if
	"                              txtfmt_cfg_numbgcolors is applicable,
	"                              assumes it to be 8)
	" TODO NOTE - If desired, could allow the fmt/clr ranges to be split, in
	" which case, the following 2 would be user-configurable. For now, just
	" base them on txtfmtStarttok.
	" TODO: Decide whether to keep this here or move outside this function
	call s:Process_clr_masks()
	" Save some useful char codes
	let b:txtfmt_clr_first_tok = b:txtfmt_cfg_starttok
	let b:txtfmt_clr_last_tok = b:txtfmt_cfg_starttok + b:txtfmt_num_colors - 1
	let b:txtfmt_fmt_first_tok = b:txtfmt_clr_last_tok + 1
	let b:txtfmt_fmt_last_tok = b:txtfmt_fmt_first_tok + b:txtfmt_num_formats - 1
	if b:txtfmt_cfg_bgcolor
		" Location of bg color range depends upon 'pack' setting as well
		" as well as type of formats in effect
		" Note: Intentionally hardcoding bgcolor index to 0 and undercurl
		" index to 1 (when formats are long) to get desired length
		" TODO: Replace ternaries with normal if block
		let b:txtfmt_bgc_first_tok = b:txtfmt_cfg_starttok +
			\ b:txtfmt_const_tokrange_size_{0}{
				\(b:txtfmt_cfg_longformats || !b:txtfmt_cfg_pack ? 1 : 0)}{
				\(b:txtfmt_cfg_longformats || !b:txtfmt_cfg_pack ? 1 : 0)}
		let b:txtfmt_bgc_last_tok = b:txtfmt_bgc_first_tok + b:txtfmt_num_colors - 1
		let b:txtfmt_last_tok = b:txtfmt_bgc_last_tok
	else
		" nothing after the fmt range
		let b:txtfmt_bgc_first_tok = -1
		let b:txtfmt_bgc_last_tok = -1
		let b:txtfmt_last_tok = b:txtfmt_fmt_last_tok
	endif
endfu
" >>>
" Function: s:Define_fmtclr_regexes() <<<
" Purpose: Define regexes involving the special fmt/clr tokens.
" Assumption: The following variable(s) has been defined for the buffer:
" b:txtfmt_cfg_starttok
" Note: The start tok is user-configurable. Thus, this function should be
" called only after processing options.
fu! s:Define_fmtclr_regexes()
	" Cache bgc enabled flag for subsequent tests
	let bgc = b:txtfmt_cfg_bgcolor && b:txtfmt_cfg_numbgcolors > 0
	let clr = b:txtfmt_cfg_numfgcolors > 0
	" 0 1 3 4 5 7 8
	"   1 3 4 5 7 8
	let fgbg_idx = 0
	let clr_or_bgc{0} = 'clr' | let fg_or_bg{0} = 'fg'
	let clr_or_bgc{1} = 'bgc' | let fg_or_bg{1} = 'bg'
	while fgbg_idx < 2
		if b:txtfmt_cfg_num{fg_or_bg{fgbg_idx}}colors
			" Note: Handle first active color here, outside the loop. To handle it
			" inside the loop, I would need to initialize tok_cnt to 0 and tok_i
			" to -1 and handle tok_i == -1 specially within the loop. (tok_i == -1
			" indicates that we don't have the potential beginning of a range)
			let tok_i = b:txtfmt_cfg_{fg_or_bg{fgbg_idx}}color{1}
			let tok_cnt = 1
			let i = 2 " first active color already accounted for
			" Initialize regex string to be built within loop
			let b:txtfmt_re_{clr_or_bgc{fgbg_idx}}_stok_atom = ''
			" Loop over active colors (and one fictitious element past end of
			" array). Note that first active color was handled in initializations.
			while i <= b:txtfmt_cfg_num{fg_or_bg{fgbg_idx}}colors + 1
				" We know something is ending (atom or range) if any of the
				" following conditions is true:
				" -We're on the non-existent element one past end of active color
				"  array
				" -The current active color index is not 1 greater than the last
				" TODO_BG: Can't compare with tok_i + 1 since tok_i isn't
				" updated through range.
				if i >= b:txtfmt_cfg_num{fg_or_bg{fgbg_idx}}colors + 1 || (b:txtfmt_cfg_{fg_or_bg{fgbg_idx}}color{i} != tok_i + tok_cnt)
					" Something is ending
					if tok_cnt > 1
						" Append range if more than 2 chars; otherwise, make
						" it a double atom.
						let b:txtfmt_re_{clr_or_bgc{fgbg_idx}}_stok_atom = b:txtfmt_re_{clr_or_bgc{fgbg_idx}}_stok_atom
							\.nr2char(b:txtfmt_{clr_or_bgc{fgbg_idx}}_first_tok + tok_i)
							\.(tok_cnt > 2 ? '-' : '')
							\.nr2char(b:txtfmt_{clr_or_bgc{fgbg_idx}}_first_tok + tok_i + tok_cnt - 1)
					else
						" Append atom
						let b:txtfmt_re_{clr_or_bgc{fgbg_idx}}_stok_atom = b:txtfmt_re_{clr_or_bgc{fgbg_idx}}_stok_atom
							\.nr2char(b:txtfmt_{clr_or_bgc{fgbg_idx}}_first_tok + tok_i)
					endif
					" Start something new unless at end
					if i <= b:txtfmt_cfg_num{fg_or_bg{fgbg_idx}}colors
						let tok_cnt = 1
						let tok_i = b:txtfmt_cfg_{fg_or_bg{fgbg_idx}}color{i}
					endif
				else
					" Nothing is ending - record continuation
					let tok_cnt = tok_cnt + 1
				endif
				let i = i + 1
			endwhile
			" Create the _tok_ version from the _stok_ version by prepending
			" default (end) token
			" Decision Needed: Do I want to create tok this way, or would it be
			" better to gain a slight bit of highlighting efficiency in some cases
			" by putting the default tok into a range if possible.
			" Note: I'm leaning against this optimization. Consider that it would
			" be possible only for color configurations in which the first color
			" is active; hence, if there were any speed difference in the
			" highlighting (and a significant one is doubtful in my opinion), it
			" would depend upon the specific color masks, which seems inconsistent
			" and therefore inappropriate.
			let b:txtfmt_re_{clr_or_bgc{fgbg_idx}}_tok_atom =
				\ nr2char(b:txtfmt_{clr_or_bgc{fgbg_idx}}_first_tok)
				\ . b:txtfmt_re_{clr_or_bgc{fgbg_idx}}_stok_atom
			let b:txtfmt_re_{clr_or_bgc{fgbg_idx}}_etok_atom =
				\ nr2char(b:txtfmt_{clr_or_bgc{fgbg_idx}}_first_tok)
		endif
		let fgbg_idx = fgbg_idx + 1
	endwhile
	" Format region tokens
	let b:txtfmt_re_fmt_tok_atom = nr2char(b:txtfmt_fmt_first_tok).'-'.nr2char(b:txtfmt_fmt_last_tok)
	let b:txtfmt_re_fmt_stok_atom = nr2char(b:txtfmt_fmt_first_tok + 1).'-'.nr2char(b:txtfmt_fmt_last_tok)
	let b:txtfmt_re_fmt_etok_atom = nr2char(b:txtfmt_fmt_first_tok)
	" Color regions that include inactive colors
	if clr
		let b:txtfmt_re_CLR_tok_atom = nr2char(b:txtfmt_clr_first_tok).'-'.nr2char(b:txtfmt_clr_last_tok)
		let b:txtfmt_re_CLR_stok_atom = nr2char(b:txtfmt_clr_first_tok + 1).'-'.nr2char(b:txtfmt_clr_last_tok)
		let b:txtfmt_re_CLR_etok_atom = nr2char(b:txtfmt_clr_first_tok)
	endif
	if bgc
		let b:txtfmt_re_BGC_tok_atom = nr2char(b:txtfmt_bgc_first_tok).'-'.nr2char(b:txtfmt_bgc_last_tok)
		let b:txtfmt_re_BGC_stok_atom = nr2char(b:txtfmt_bgc_first_tok + 1).'-'.nr2char(b:txtfmt_bgc_last_tok)
		let b:txtfmt_re_BGC_etok_atom = nr2char(b:txtfmt_bgc_first_tok)
	endif
	" Combined regions
	let b:txtfmt_re_any_tok_atom =
				\(clr ? b:txtfmt_re_clr_tok_atom : '')
				\.nr2char(b:txtfmt_fmt_first_tok).'-'.nr2char(b:txtfmt_fmt_last_tok)
				\.(bgc ? b:txtfmt_re_bgc_tok_atom : '')
	" TODO: Perhaps get rid of dependence upon b:txtfmt_clr_last_tok?
	" TODO: Refactor to use newly-created CLR and BGC atoms
	let b:txtfmt_re_ANY_tok_atom =
				\(clr ? nr2char(b:txtfmt_clr_first_tok).'-'.nr2char(b:txtfmt_clr_last_tok) : '')
				\.nr2char(b:txtfmt_fmt_first_tok).'-'.nr2char(b:txtfmt_fmt_last_tok)
				\.(bgc ? nr2char(b:txtfmt_bgc_first_tok).'-'.nr2char(b:txtfmt_bgc_last_tok) : '')
	let b:txtfmt_re_any_stok_atom =
				\(clr ? b:txtfmt_re_clr_stok_atom : '')
				\.nr2char(b:txtfmt_fmt_first_tok + 1).'-'.nr2char(b:txtfmt_fmt_last_tok)
				\.(bgc ? b:txtfmt_re_bgc_stok_atom : '')
	let b:txtfmt_re_any_etok_atom =
				\(clr ? b:txtfmt_re_clr_etok_atom : '')
				\.b:txtfmt_re_fmt_etok_atom
				\.(bgc ? b:txtfmt_re_bgc_etok_atom : '')

	if b:txtfmt_cfg_escape == 'bslash'
		" The following pattern is a zero-width look-behind assertion, which
		" matches only at a non-backslash-escaped position.
		let noesc = '\%(\%(^\|[^\\]\)\%(\\\\\)*\\\)\@<!'
		" Make this persistent, as it's used elsewhere...
		let b:re_no_bslash_esc = noesc
		" clr
		if clr
			" Active clr only
			let b:txtfmt_re_clr_tok = noesc.'['.b:txtfmt_re_clr_tok_atom.']'
			let b:txtfmt_re_clr_stok = noesc.'['.b:txtfmt_re_clr_stok_atom.']'
			let b:txtfmt_re_clr_etok = noesc.b:txtfmt_re_clr_etok_atom
			let b:txtfmt_re_clr_ntok = '\%('.b:txtfmt_re_clr_tok.'\)\@!.'
			" Active and inactive clr
			let b:txtfmt_re_CLR_tok = noesc.'['.b:txtfmt_re_CLR_tok_atom.']'
			let b:txtfmt_re_CLR_stok = noesc.'['.b:txtfmt_re_CLR_stok_atom.']'
			let b:txtfmt_re_CLR_etok = noesc.b:txtfmt_re_CLR_etok_atom
			let b:txtfmt_re_CLR_ntok = '\%('.b:txtfmt_re_CLR_tok.'\)\@!.'
		endif
		" bgc
		if bgc
			" Active bgc only
			let b:txtfmt_re_bgc_tok = noesc.'['.b:txtfmt_re_bgc_tok_atom.']'
			let b:txtfmt_re_bgc_stok = noesc.'['.b:txtfmt_re_bgc_stok_atom.']'
			let b:txtfmt_re_bgc_etok = noesc.b:txtfmt_re_bgc_etok_atom
			let b:txtfmt_re_bgc_ntok = '\%('.b:txtfmt_re_bgc_tok.'\)\@!.'
			" Active and inactive bgc
			let b:txtfmt_re_BGC_tok = noesc.'['.b:txtfmt_re_BGC_tok_atom.']'
			let b:txtfmt_re_BGC_stok = noesc.'['.b:txtfmt_re_BGC_stok_atom.']'
			let b:txtfmt_re_BGC_etok = noesc.b:txtfmt_re_BGC_etok_atom
			let b:txtfmt_re_BGC_ntok = '\%('.b:txtfmt_re_BGC_tok.'\)\@!.'
		endif
		" fmt
		let b:txtfmt_re_fmt_tok = noesc.'['.b:txtfmt_re_fmt_tok_atom.']'
		let b:txtfmt_re_fmt_stok = noesc.'['.b:txtfmt_re_fmt_stok_atom.']'
		let b:txtfmt_re_fmt_etok = noesc.b:txtfmt_re_fmt_etok_atom
		let b:txtfmt_re_fmt_ntok = '\%('.b:txtfmt_re_fmt_tok.'\)\@!.'
		" clr/bgc/fmt combined
		let b:txtfmt_re_any_tok = noesc.'['.b:txtfmt_re_any_tok_atom.']'
		let b:txtfmt_re_ANY_tok = noesc.'['.b:txtfmt_re_ANY_tok_atom.']'
		let b:txtfmt_re_any_stok = noesc.'['.b:txtfmt_re_any_stok_atom.']'
		let b:txtfmt_re_any_etok =
					\ noesc.'['
						\ . (clr ? b:txtfmt_re_clr_etok_atom : '')
						\ . (bgc ? b:txtfmt_re_bgc_etok_atom : '')
						\ . b:txtfmt_re_fmt_etok_atom
					\ . ']'
		let b:txtfmt_re_any_ntok = '\%('.b:txtfmt_re_any_tok.'\)\@!.'
	elseif b:txtfmt_cfg_escape == 'self'
		" The following pattern serves as the template for finding tokens that
		" are neither escaping nor escaped.
		let tmpl = '\%(\(placeholder\)\%(\1\)\@!\)\@=\%(\%(^\|\%(\1\)\@!.\)\%(\1\1\)*\1\)\@<!.'
		" Make this persistent, as it's used elsewhere...
		let b:re_no_self_esc = tmpl
		" clr
		if clr
			" Active clr only
			let b:txtfmt_re_clr_tok = substitute(tmpl, 'placeholder', '['.b:txtfmt_re_clr_tok_atom.']', '')
			let b:txtfmt_re_clr_stok = substitute(tmpl, 'placeholder', '['.b:txtfmt_re_clr_stok_atom.']', '')
			let b:txtfmt_re_clr_etok = substitute(tmpl, 'placeholder', b:txtfmt_re_clr_etok_atom, '')
			let b:txtfmt_re_clr_ntok = '\%('.b:txtfmt_re_clr_tok.'\)\@!.'
			" Active and inactive clr
			let b:txtfmt_re_CLR_tok = substitute(tmpl, 'placeholder', '['.b:txtfmt_re_CLR_tok_atom.']', '')
			let b:txtfmt_re_CLR_stok = substitute(tmpl, 'placeholder', '['.b:txtfmt_re_CLR_stok_atom.']', '')
			let b:txtfmt_re_CLR_etok = substitute(tmpl, 'placeholder', b:txtfmt_re_CLR_etok_atom, '')
			let b:txtfmt_re_CLR_ntok = '\%('.b:txtfmt_re_CLR_tok.'\)\@!.'
		endif
		" bgc
		if bgc
			" Active bgc only
			let b:txtfmt_re_bgc_tok = substitute(tmpl, 'placeholder', '['.b:txtfmt_re_bgc_tok_atom.']', '')
			let b:txtfmt_re_bgc_stok = substitute(tmpl, 'placeholder', '['.b:txtfmt_re_bgc_stok_atom.']', '')
			let b:txtfmt_re_bgc_etok = substitute(tmpl, 'placeholder', b:txtfmt_re_bgc_etok_atom, '')
			let b:txtfmt_re_bgc_ntok = '\%('.b:txtfmt_re_bgc_tok.'\)\@!.'
			" Active and inactive bgc
			let b:txtfmt_re_BGC_tok = substitute(tmpl, 'placeholder', '['.b:txtfmt_re_BGC_tok_atom.']', '')
			let b:txtfmt_re_BGC_stok = substitute(tmpl, 'placeholder', '['.b:txtfmt_re_BGC_stok_atom.']', '')
			let b:txtfmt_re_BGC_etok = substitute(tmpl, 'placeholder', b:txtfmt_re_BGC_etok_atom, '')
			let b:txtfmt_re_BGC_ntok = '\%('.b:txtfmt_re_BGC_tok.'\)\@!.'
		endif
		" fmt
		let b:txtfmt_re_fmt_tok = substitute(tmpl, 'placeholder', '['.b:txtfmt_re_fmt_tok_atom.']', '')
		let b:txtfmt_re_fmt_stok = substitute(tmpl, 'placeholder', '['.b:txtfmt_re_fmt_stok_atom.']', '')
		let b:txtfmt_re_fmt_etok = substitute(tmpl, 'placeholder', b:txtfmt_re_fmt_etok_atom, '')
		let b:txtfmt_re_fmt_ntok = '\%('.b:txtfmt_re_fmt_tok.'\)\@!.'
		" clr/bgc/fmt combined
		let b:txtfmt_re_any_tok = substitute(tmpl, 'placeholder', '['.b:txtfmt_re_any_tok_atom.']', '')
		let b:txtfmt_re_ANY_tok = substitute(tmpl, 'placeholder', '['.b:txtfmt_re_ANY_tok_atom.']', '')
		let b:txtfmt_re_any_stok = substitute(tmpl, 'placeholder', '['.b:txtfmt_re_any_stok_atom.']', '')
		let b:txtfmt_re_any_etok = substitute(tmpl, 'placeholder',
					\'['
					\.(clr ? nr2char(b:txtfmt_clr_first_tok) : '')
					\.(bgc ? nr2char(b:txtfmt_bgc_first_tok) : '')
					\.nr2char(b:txtfmt_fmt_first_tok)
					\.']', '')
		let b:txtfmt_re_any_ntok = '\%('.b:txtfmt_re_any_tok.'\)\@!.'
	else
		" No escaping of tokens
		" clr
		if clr
			" Active clr only
			let b:txtfmt_re_clr_tok = '['.b:txtfmt_re_clr_tok_atom.']'
			let b:txtfmt_re_clr_stok = '['.b:txtfmt_re_clr_stok_atom.']'
			let b:txtfmt_re_clr_etok = b:txtfmt_re_clr_etok_atom
			let b:txtfmt_re_clr_ntok = '[^'.b:txtfmt_re_clr_tok_atom.']'
			" Active and inactive clr
			let b:txtfmt_re_CLR_tok = '['.b:txtfmt_re_CLR_tok_atom.']'
			let b:txtfmt_re_CLR_stok = '['.b:txtfmt_re_CLR_stok_atom.']'
			let b:txtfmt_re_CLR_etok = b:txtfmt_re_CLR_etok_atom
			let b:txtfmt_re_CLR_ntok = '[^'.b:txtfmt_re_CLR_tok_atom.']'
		endif
		" bgc
		if bgc
			" Active bgc only
			let b:txtfmt_re_bgc_tok = '['.b:txtfmt_re_bgc_tok_atom.']'
			let b:txtfmt_re_bgc_stok = '['.b:txtfmt_re_bgc_stok_atom.']'
			let b:txtfmt_re_bgc_etok = b:txtfmt_re_bgc_etok_atom
			let b:txtfmt_re_bgc_ntok = '[^'.b:txtfmt_re_bgc_tok_atom.']'
			" Active and inactive bgc
			let b:txtfmt_re_BGC_tok = '['.b:txtfmt_re_BGC_tok_atom.']'
			let b:txtfmt_re_BGC_stok = '['.b:txtfmt_re_BGC_stok_atom.']'
			let b:txtfmt_re_BGC_etok = b:txtfmt_re_BGC_etok_atom
			let b:txtfmt_re_BGC_ntok = '[^'.b:txtfmt_re_BGC_tok_atom.']'
		endif
		" fmt
		let b:txtfmt_re_fmt_tok = '['.b:txtfmt_re_fmt_tok_atom.']'
		let b:txtfmt_re_fmt_stok = '['.b:txtfmt_re_fmt_stok_atom.']'
		let b:txtfmt_re_fmt_etok = b:txtfmt_re_fmt_etok_atom
		let b:txtfmt_re_fmt_ntok = '[^'.b:txtfmt_re_fmt_tok_atom.']'
		" clr/bgc/fmt combined
		let b:txtfmt_re_any_tok = '['.b:txtfmt_re_any_tok_atom.']'
		let b:txtfmt_re_ANY_tok = '['.b:txtfmt_re_ANY_tok_atom.']'
		let b:txtfmt_re_any_stok = '['.b:txtfmt_re_any_stok_atom.']'
		let b:txtfmt_re_any_etok =
					\'['
					\.(clr ? b:txtfmt_re_clr_etok_atom : '')
					\.(bgc ? b:txtfmt_re_bgc_etok_atom : '')
					\.b:txtfmt_re_fmt_etok_atom
					\.']'
		let b:txtfmt_re_any_ntok =
					\'[^'
					\.(clr ? b:txtfmt_re_clr_tok_atom : '')
					\.(bgc ? b:txtfmt_re_bgc_tok_atom : '')
					\.b:txtfmt_re_fmt_tok_atom
					\.']'
	endif
endfu
" >>>
" Function: s:Do_config_common() <<<
" Purpose: Set script local variables, taking into account whether user has
" overriden via txtfmt globals.
fu! s:Do_config_common()
	" unlet any buffer-specific options that may be set by txtfmt modeline <<<
	unlet! b:txtfmt_cfg_tokrange
				\ b:txtfmt_cfg_sync b:txtfmt_cfg_escape
				\ b:txtfmt_cfg_pack b:txtfmt_cfg_nested
				\ b:txtfmt_cfg_numfgcolors b:txtfmt_cfg_numbgcolors
				\ b:txtfmt_cfg_fgcolormask b:txtfmt_cfg_bgcolormask
				\ b:txtfmt_cfg_undercurlpref b:txtfmt_cfg_conceal
	" >>>
	" Attempt to process modeline <<<
	let ml_status = s:Do_txtfmt_modeline()
	" >>>
	" 'escape' option <<<
	if !exists('b:txtfmt_cfg_escape') || strlen(b:txtfmt_cfg_escape) == 0
		" Either option wasn't set within modeline, or it was set to invalid
		" value
		unlet! l:bad_set_by
		if exists('b:txtfmt_cfg_escape') && strlen(b:txtfmt_cfg_escape) == 0
			" Bad modeline set
			let l:bad_set_by = 'm'
		elseif exists('b:txtfmtEscape')
			" User overrode buf-local option
			if s:Escape_is_valid(b:txtfmtEscape)
				let b:txtfmt_cfg_escape = b:txtfmtEscape
			else
				let l:bad_set_by = 'b'
			endif
		elseif exists('g:txtfmtEscape')
			" User overrode global option
			if s:Escape_is_valid(g:txtfmtEscape)
				let b:txtfmt_cfg_escape = g:txtfmtEscape
			else
				let l:bad_set_by = 'g'
			endif
		endif
		" Warn user if invalid user-setting is about to be overridden
		if exists('l:bad_set_by')
			" Note: Display the offending option value for buf-local or global
			" option, but not for modeline, since modeline processing has
			" already reported the error.
			echoerr "Warning: Ignoring invalid ".(
				\ l:bad_set_by == 'm' ? "modeline" :
				\ l:bad_set_by == 'b' ? "buf-local" :
				\ "global") . " value for txtfmt `escape' option" . (
				\ l:bad_set_by == 'm' ? '' :
				\ l:bad_set_by == 'b' ? (': ' . b:txtfmtEscape) :
				\ (': ' . g:txtfmtEscape)
		endif
		if !exists('b:txtfmt_cfg_escape') || strlen(b:txtfmt_cfg_escape) == 0
			" Set to default
			let b:txtfmt_cfg_escape = 'none'
		endif
	endif
	" >>>
	" 'pack' option <<<
	if !exists('b:txtfmt_cfg_pack') || strlen(b:txtfmt_cfg_pack) == 0
		" Either option wasn't set within modeline, or it was set to invalid
		" value
		if exists('b:txtfmt_cfg_pack') && strlen(b:txtfmt_cfg_pack) == 0
			" Bad modeline set. Warn user that we're about to override. Note
			" that modeline processing has already reported the specific
			" error.
			echoerr "Warning: Ignoring invalid modeline value for txtfmt `pack' option"
		elseif exists('b:txtfmtPack')
			" User overrode buf-local option
			" Note: Invalid setting impossible for boolean
			let b:txtfmt_cfg_pack = b:txtfmtPack
		elseif exists('g:txtfmtPack')
			" User overrode global option
			" Note: Invalid setting impossible for boolean
			let b:txtfmt_cfg_pack = g:txtfmtPack
		endif
		if !exists('b:txtfmt_cfg_pack') || strlen(b:txtfmt_cfg_pack) == 0
			" Set to default (on)
			let b:txtfmt_cfg_pack = 1
		endif
	endif
	" >>>
	" 'undercurl' option <<<
	if !exists('b:txtfmt_cfg_undercurlpref') || strlen(b:txtfmt_cfg_undercurlpref) == 0
		" Either option wasn't set within modeline, or it was set to invalid
		" value
		if exists('b:txtfmt_cfg_undercurlpref') && strlen(b:txtfmt_cfg_undercurlpref) == 0
			" Bad modeline set. Warn user that we're about to override. Note
			" that modeline processing has already reported the specific
			" error.
			echoerr "Warning: Ignoring invalid modeline value for txtfmt `undercurl' option"
		elseif exists('b:txtfmtUndercurl')
			" User overrode buf-local option
			" Note: Invalid setting impossible for boolean
			let b:txtfmt_cfg_undercurlpref = b:txtfmtUndercurl
		elseif exists('g:txtfmtUndercurl')
			" User overrode global option
			" Note: Invalid setting impossible for boolean
			let b:txtfmt_cfg_undercurlpref = g:txtfmtUndercurl
		endif
		if !exists('b:txtfmt_cfg_undercurlpref') || strlen(b:txtfmt_cfg_undercurlpref) == 0
			" Set to default (on)
			" Note: This is 'preference' only; if Vim version doesn't support
			" undercurl, we won't attempt to enable.
			let b:txtfmt_cfg_undercurlpref = 1
		endif
	endif
	" >>>
	" 'nested' option <<<
	if !exists('b:txtfmt_cfg_nested') || strlen(b:txtfmt_cfg_nested) == 0
		" Either option wasn't set within modeline, or it was set to invalid
		" value
		if exists('b:txtfmt_cfg_nested') && strlen(b:txtfmt_cfg_nested) == 0
			" Bad modeline set. Warn user that we're about to override. Note
			" that modeline processing has already reported the specific
			" error.
			echoerr "Warning: Ignoring invalid modeline value for txtfmt `nested' option"
		elseif exists('b:txtfmtNested')
			" User overrode buf-local option
			" Note: Invalid setting impossible for boolean
			let b:txtfmt_cfg_nested = b:txtfmtNested
		elseif exists('g:txtfmtNested')
			" User overrode global option
			" Note: Invalid setting impossible for boolean
			let b:txtfmt_cfg_nested = g:txtfmtNested
		endif
		if !exists('b:txtfmt_cfg_nested') || strlen(b:txtfmt_cfg_nested) == 0
			" Set to default (on)
			let b:txtfmt_cfg_nested = 1
		endif
	endif
	" >>>
	" 'conceal' option <<<
	if !exists('b:txtfmt_cfg_conceal') || strlen(b:txtfmt_cfg_conceal) == 0
		" Either option wasn't set within modeline, or it was set to invalid
		" value
		if exists('b:txtfmt_cfg_conceal') && strlen(b:txtfmt_cfg_conceal) == 0
			" Bad modeline set. Warn user that we're about to override. Note
			" that modeline processing has already reported the specific
			" error.
			echoerr "Warning: Ignoring invalid modeline value for txtfmt `conceal' option"
		elseif exists('b:txtfmtConceal')
			" User overrode buf-local option
			" Note: Invalid setting impossible for boolean
			let b:txtfmt_cfg_conceal = has('conceal') && b:txtfmtConceal
		elseif exists('g:txtfmtConceal')
			" User overrode global option
			" Note: Invalid setting impossible for boolean
			let b:txtfmt_cfg_conceal = has('conceal') && g:txtfmtConceal
		endif
		if !exists('b:txtfmt_cfg_conceal') || strlen(b:txtfmt_cfg_conceal) == 0
			" For backward-compatibility reasons, default is 'noconceal', even
			" when has('conceal') returns true.
			let b:txtfmt_cfg_conceal = 0
		endif
	endif
	" >>>
	" 'tokrange' option <<<
	" Note: 'starttok' and 'formats' are distinct options internally, but may
	" be set only as a unit by the plugin user. Even if tokrange was set
	" within modeline, there is work yet to be done.
	call s:Set_tokrange()
	" >>>
	" 'fgcolormask' option <<<
	if !exists('b:txtfmt_cfg_fgcolormask') || strlen(b:txtfmt_cfg_fgcolormask) == 0
		" Either option wasn't set within modeline, or it was set to invalid
		" value
		unlet! l:bad_set_by
		if exists('b:txtfmt_cfg_fgcolormask') && strlen(b:txtfmt_cfg_fgcolormask) == 0
			" Bad modeline set
			let l:bad_set_by = 'm'
		elseif exists('b:txtfmtFgcolormask')
			" User overrode buf-local option
			if s:Clrmask_is_valid(b:txtfmtFgcolormask)
				let b:txtfmt_cfg_fgcolormask = b:txtfmtFgcolormask
			else
				let l:bad_set_by = 'b'
			endif
		elseif exists('g:txtfmtFgcolormask')
			" User overrode global option
			if s:Clrmask_is_valid(g:txtfmtFgcolormask)
				let b:txtfmt_cfg_fgcolormask = g:txtfmtFgcolormask
			else
				let l:bad_set_by = 'g'
			endif
		endif
		" Warn user if invalid user-setting is about to be overridden
		if exists('l:bad_set_by')
			" Note: Display the offending option value for buf-local or global
			" option, but not for modeline, since modeline processing has
			" already reported the error.
			echoerr "Warning: Ignoring invalid ".(
				\ l:bad_set_by == 'm' ? "modeline" :
				\ l:bad_set_by == 'b' ? "buf-local" :
				\ "global") . " value for txtfmt `fgcolormask' option" . (
				\ l:bad_set_by == 'm' ? '' :
				\ l:bad_set_by == 'b' ? (': ' . b:txtfmtFgcolormask) :
				\ (': ' . g:txtfmtFgcolormask)
		endif
		if !exists('b:txtfmt_cfg_fgcolormask') || strlen(b:txtfmt_cfg_fgcolormask) == 0
			" Set to default - all foreground colors active (for backward
			" compatibility)
			" TODO: Don't hardcode
			let b:txtfmt_cfg_fgcolormask = '11111111'
		endif
	endif
	" >>>
	" 'bgcolormask' option <<<
	if !exists('b:txtfmt_cfg_bgcolormask') || strlen(b:txtfmt_cfg_bgcolormask) == 0
		" Either option wasn't set within modeline, or it was set to invalid
		" value
		unlet! l:bad_set_by
		if exists('b:txtfmt_cfg_bgcolormask') && strlen(b:txtfmt_cfg_bgcolormask) == 0
			" Bad modeline set
			let l:bad_set_by = 'm'
		elseif exists('b:txtfmtBgcolormask')
			" User overrode buf-local option
			if s:Clrmask_is_valid(b:txtfmtBgcolormask)
				let b:txtfmt_cfg_bgcolormask = b:txtfmtBgcolormask
			else
				let l:bad_set_by = 'b'
			endif
		elseif exists('g:txtfmtBgcolormask')
			" User overrode global option
			if s:Clrmask_is_valid(g:txtfmtBgcolormask)
				let b:txtfmt_cfg_bgcolormask = g:txtfmtBgcolormask
			else
				let l:bad_set_by = 'g'
			endif
		endif
		" Warn user if invalid user-setting is about to be overridden
		if exists('l:bad_set_by')
			" Note: Display the offending option value for buf-local or global
			" option, but not for modeline, since modeline processing has
			" already reported the error.
			echoerr "Warning: Ignoring invalid ".(
				\ l:bad_set_by == 'm' ? "modeline" :
				\ l:bad_set_by == 'b' ? "buf-local" :
				\ "global") . " value for txtfmt `bgcolormask' option" . (
				\ l:bad_set_by == 'm' ? '' :
				\ l:bad_set_by == 'b' ? (': ' . b:txtfmtBgcolormask) :
				\ (': ' . g:txtfmtBgcolormask)
		endif
		if !exists('b:txtfmt_cfg_bgcolormask') || strlen(b:txtfmt_cfg_bgcolormask) == 0
			" Set to default of red, green and blue if background colors are
			" active; otherwise, disable all colors.
			" TODO_BG: Decide whether it makes sense to unlet the variable
			" completely.
			" TODO_BG: b:txtfmt_cfg_bgcolor is probably not set yet!!!! This
			" needs to be moved till after Set_tokrange
			if b:txtfmt_cfg_bgcolor
				" TODO: Don't hardcode
				let b:txtfmt_cfg_bgcolormask = '01101000'
			else
				" No background color supported
				let b:txtfmt_cfg_bgcolormask = '00000000'
			endif
		endif
	endif
	" Force mask to all zeroes if background colors are disabled.
	" Assumption: Set_tokrange has already run; thus, b:txtfmt_cfg_bgcolor has
	" been set.
	if !b:txtfmt_cfg_bgcolor
		let b:txtfmt_cfg_bgcolormask = '00000000'
	endif
	" >>>
	" 'sync' option <<<
	" Note: 'syncmethod' and 'synclines' are distinct options internally, but
	" may be set only as a unit by the plugin user. Even if sync was set
	" within modeline, there is work yet to be done.
	call s:Set_syncing()
	" >>>
	" Define various buffer-specific variables now that fmt/clr ranges are fixed.
	" TODO: Perhaps combine the following 2 functions in some way...
	call s:Define_fmtclr_vars()
	" Define fmt/clr regexes - used in both syntax and ftplugin <<<
	call s:Define_fmtclr_regexes()
	" >>>
	" Process color options <<<
	call s:Process_color_options()
	" >>>
endfu
" >>>
call s:Do_config_common()
" Define buffer-local constants <<<
" For convenience, associate format indices with their respective
" '[u][b][i][s][r][c]' string, in fiducial form. Note that fiducial form may
" be used for display, but is also a valid (but not the only) fmt spec.
let b:ubisrc_fmt0  = '-'
let b:ubisrc_fmt1  = 'u'
let b:ubisrc_fmt2  = 'b'
let b:ubisrc_fmt3  = 'bu'
let b:ubisrc_fmt4  = 'i'
let b:ubisrc_fmt5  = 'iu'
let b:ubisrc_fmt6  = 'ib'
let b:ubisrc_fmt7  = 'ibu'
let b:ubisrc_fmt8  = 's'
let b:ubisrc_fmt9  = 'su'
let b:ubisrc_fmt10 = 'sb'
let b:ubisrc_fmt11 = 'sbu'
let b:ubisrc_fmt12 = 'si'
let b:ubisrc_fmt13 = 'siu'
let b:ubisrc_fmt14 = 'sib'
let b:ubisrc_fmt15 = 'sibu'
let b:ubisrc_fmt16 = 'r'
let b:ubisrc_fmt17 = 'ru'
let b:ubisrc_fmt18 = 'rb'
let b:ubisrc_fmt19 = 'rbu'
let b:ubisrc_fmt20 = 'ri'
let b:ubisrc_fmt21 = 'riu'
let b:ubisrc_fmt22 = 'rib'
let b:ubisrc_fmt23 = 'ribu'
let b:ubisrc_fmt24 = 'rs'
let b:ubisrc_fmt25 = 'rsu'
let b:ubisrc_fmt26 = 'rsb'
let b:ubisrc_fmt27 = 'rsbu'
let b:ubisrc_fmt28 = 'rsi'
let b:ubisrc_fmt29 = 'rsiu'
let b:ubisrc_fmt30 = 'rsib'
let b:ubisrc_fmt31 = 'rsibu'
let b:ubisrc_fmt32 = 'c'
let b:ubisrc_fmt33 = 'cu'
let b:ubisrc_fmt34 = 'cb'
let b:ubisrc_fmt35 = 'cbu'
let b:ubisrc_fmt36 = 'ci'
let b:ubisrc_fmt37 = 'ciu'
let b:ubisrc_fmt38 = 'cib'
let b:ubisrc_fmt39 = 'cibu'
let b:ubisrc_fmt40 = 'cs'
let b:ubisrc_fmt41 = 'csu'
let b:ubisrc_fmt42 = 'csb'
let b:ubisrc_fmt43 = 'csbu'
let b:ubisrc_fmt44 = 'csi'
let b:ubisrc_fmt45 = 'csiu'
let b:ubisrc_fmt46 = 'csib'
let b:ubisrc_fmt47 = 'csibu'
let b:ubisrc_fmt48 = 'cr'
let b:ubisrc_fmt49 = 'cru'
let b:ubisrc_fmt50 = 'crb'
let b:ubisrc_fmt51 = 'crbu'
let b:ubisrc_fmt52 = 'cri'
let b:ubisrc_fmt53 = 'criu'
let b:ubisrc_fmt54 = 'crib'
let b:ubisrc_fmt55 = 'cribu'
let b:ubisrc_fmt56 = 'crs'
let b:ubisrc_fmt57 = 'crsu'
let b:ubisrc_fmt58 = 'crsb'
let b:ubisrc_fmt59 = 'crsbu'
let b:ubisrc_fmt60 = 'crsi'
let b:ubisrc_fmt61 = 'crsiu'
let b:ubisrc_fmt62 = 'crsib'
let b:ubisrc_fmt63 = 'crsibu'
" >>>
else " if exists('b:txtfmt_do_common_config')
" Function: s:Txtfmt_refresh() <<<
" Purpose: Invoked by buffer-local command Refresh when user wishes to
" reload txtfmt plugins safely for the current buffer; e.g., after changing
" option settings.
" Important Note: This function must be within the else of an if
" exists('b:txtfmt_do_common_config'); otherwise, we will get an error when this
" function causes the plugins to be re-sourced, since the re-sourcing of this
" file will result in an attempt to redefine the function while it is running!
fu! s:Txtfmt_refresh()
	" Ensure that common configuration code will not be skipped next time
	unlet! b:txtfmt_did_common_config
	" Determine whether txtfmt ftplugin is loaded
	if exists('b:loaded_txtfmt')
		" b:loaded_txtfmt is set only within ftplugin/txtfmt.vim and unlet by
		" b:undo_ftplugin; hence, its existence indicates that txtfmt ftplugin
		" is currently loaded. Cache the filetype that was cached at load
		" time.
		let l:current_filetype = b:txtfmt_filetype
	endif
	" Determine whether txtfmt syntax plugin is loaded
	let v:errmsg = ''
	silent! syn sync match Tf_existence_test grouphere Tf_fmt_1 /\%^/
	if v:errmsg == ''
		" No error means txtfmt syntax plugin is loaded. Cache the syntax name
		" that was cached at load time.
		let l:current_syntax = b:txtfmt_syntax
	endif
	" Is there anything to refresh?
	if !exists('l:current_filetype') && !exists('l:current_syntax')
		echomsg "Warning: Useless call to Refresh: "
			\."no txtfmt plugins appear to be loaded."
		return
	endif
	" If here, there was a reason for the Txtfmt_refresh call. Cause ftplugin
	" and/or syntax plugin to be reloaded via FileType and Syntax sets, as
	" appropriate.
	if exists('l:current_syntax')
		" We're going to attempt to reload syntax plugin. Unload it now
		" (causing b:current_syntax to be unlet). If we set filetype below,
		" and b:current_syntax exists afterwards, we'll know syntax was loaded
		" via syntaxset autocmd linked to FileType event. Alternatively,
		" could simply unlet b:current_syntax here...
		set syntax=OFF
	endif
	if exists('l:current_filetype')
		" Set filetype to whatever it was before
		exe 'set filetype=' . l:current_filetype
	endif
	if exists('l:current_syntax')
		" Syntax may have been loaded already, but if not, we'll need to do it
		" manually...
		if exists('b:current_syntax')
			" Syntax was loaded as a result of the filetype set. Make sure it
			" appears to be the correct one.
			if b:current_syntax != l:current_syntax
				echomsg "Warning: Txtfmt attempted to restore syntax to `"
				\.l:current_syntax."'. Result was `".b:current_syntax."'"
				echomsg "I'm guessing you have loaded the txtfmt plugins "
				\."in a non-standard manner. See txtfmt help for more information."
			endif
		else
			" Syntax wasn't linked to filetype. Load the desired syntax manually.
			exe 'set syntax=' . l:current_syntax
		endif
	endif	
endfu
" >>>
endif " if exists('b:txtfmt_do_common_config')
" General-purpose utilities <<<
" Note: These utilities are defined globally in the plugin file so that they
" might be used by any of the Txtfmt script files.
" Naming Convention: All of these utilities should begin with 'TxtfmtUtil_'
" and should separate internal 'words' with underscore. Internal words should
" not be capitalized.
" Function: TxtfmtUtil_num_to_hex_str <<<
" Description: Take the input value and convert it to a hex string of the form
" 0xXXXX.
" Format Note: Output string will have '0x' prepended, but will omit leading
" zeroes.
fu! TxtfmtUtil_num_to_hex_str(num)
	" Get writable copy
	let num = a:num
	" Loop until the value has been completely processed
	let str = ''
	let abcdef = "ABCDEF"
	while num > 0
		let dig = num % 16
		" Convert the digit value to a hex digit and prepend to hex str
		if dig <= 9
			let str = dig . str
		else
			let str = strpart(abcdef, dig - 10, 1) . str
		endif
		let num = num / 16
	endwhile
	" Prepend '0x' to hex string built in loop
	" Note: If string is empty, it should be '0'
	return '0x' . (strlen(str) == 0 ? '0' : str)
endfu
" >>>
" >>>
" Function: s:MakeTestPage() <<<
" Purpose: Build a "test-page" in a scratch buffer, to show user how color
" and format regions will look with current definitions and on current
" terminal. (Useful to prevent user from having to insert all the color and
" format regions manually with text such as "Here's a little test...")
" How: Create a scratch buffer whose filetype is set to txtfmt. Add some
" explanation lines at the top, followed by one line for each active color, as
" follows:
" color<num> none i b bi u ui ub ubi ...
" Repeat for each active background color...
" Note: The function is script-local, as it is designed to be invoked from a
" command.
" IMPORTANT NOTE: Special care must be taken when defining this function, as
" it creates a buffer with 'ft' set to txtfmt, which causes the script to be
" re-sourced. This leads to E127 'Cannot redefine function' when fu[!] is
" encountered, since the function is in the process of executing.
if !exists('*s:MakeTestPage')
fu! s:MakeTestPage(...)
	if a:0 == 1
		" User provided optional modeline arguments. Before opening scratch
		" buffer, make sure the modeline constructed from the arguments has at
		" least the overall appearance of being valid. (Option name/value
		" validation is performed only after opening the test page buffer.)
		if !s:Is_txtfmt_modeline("\<Tab>txtfmt:".a:1)
			" Warn of invalid modeline and return without creating the test
			" buffer
			echoerr "Invalid arguments passed to :MakeTestPage command: `".a:1."'"
			return
		endif
	endif
	" Open the buffer
	new
	set buftype=nofile
	set bufhidden=hide
	set noswapfile
	" If user provided modeline, add it to top of file before setting filetype
	" to txtfmt...
	if a:0 == 1
		let modeline = a:1
		if modeline =~ '\S'
			call setline(1, "\<Tab>txtfmt:".modeline)
		endif
	elseif a:0 > 1
		" This should never happen, since this function is called from a
		" mapping.
		echoerr "Too many arguments passed to MakeTestPage."
			\." (Note that this function should not be called directly.)"
	endif
	set filetype=txtfmt
	" Set page formatting options
	" TODO - Decide whether the following are necessary anymore. (I'm
	" formatting things explicitly now...)
	set noai ts=4 sw=4 tw=78
	set nowrap
	" Cache some special tokens that will be used on this page
	let tok_fb = Txtfmt_GetTokStr('fb')
	let tok_fui = Txtfmt_GetTokStr('fui')
	let tok_fu = Txtfmt_GetTokStr('fu')
	let tok_fmt_end = nr2char(b:txtfmt_fmt_first_tok)
	let tok_clr_end = nr2char(b:txtfmt_clr_first_tok)
	" Important Note: Most of the following logic assumes that each token that
	" is hidden by a txtfmt concealment group will appear as a single
	" whitespace. If the 'conceal' patch is in effect, however, such tokens
	" will not appear at all. The problem is that the token width is sometimes
	" used to achieve the desired alignment. To facilitate keeping the
	" alignment constant, I declare a variable that resolves to a single
	" whitespace if and only if the conceal patch is in effect. This variable
	" will be appended to tokens that would affect alignment in the absence of
	" the conceal patch.
	" Note: The space could go before or after the token, but after is best in
	" the case of bg colors.
	let cncl_ws = b:txtfmt_cfg_conceal ? ' ' : ''
	call append(line('$'), tok_fb)
	call append(line('$'),
		\"************************")
	$center
	call append(line('$'),
		\"*** TXTFMT TEST PAGE ***")
	$center
	call append(line('$'),
		\"************************")
	$center
	call append(line('$'),
		\"=============================================================================")
	call append(line('$'),
		\"*** Overview ***")
	$center
	call append(line('$'), tok_fmt_end)
	call append(line('$'), "")
	call append(line('$'),
		\"The purpose of this page is to present an overview of the txtfmt highlighting")
	call append(line('$'),
		\"that results from the global txtfmt options and any txtfmt modeline settings")
	call append(line('$'),
		\"passed to the MakeTestPage command.")
	call append(line('$'), "")
	call append(line('$'),
		\"	:help txtfmt-MakeTestPage")
	call append(line('$'), "")
	call append(line('$'),
		\"The text on the page has been chosen to display all possible combinations of")
	call append(line('$'),
		\"color and format regions, and if applicable, to illustrate the escaping of")
	call append(line('$'),
		\"tokens and the nesting of txtfmt regions.")
	call append(line('$'), tok_fb)
	call append(line('$'),
		\"=============================================================================")
	call append(line('$'),
		\"*** Colors and Formats ***")
	$center
	call append(line('$'), tok_fui)
	" Possible TODO: Use b:txtfmt_cfg_tokrange so that number format specified
	" by user is respected.
	call append(line('$'),
		\'Configuration:'.tok_fb.cncl_ws
		\."tokrange =".tok_fmt_end.cncl_ws
		\.b:txtfmt_cfg_starttok_display.b:txtfmt_cfg_formats_display
		\)
	call append(line('$'), "")
	call append(line('$'),
		\"\<Tab>start token: ".b:txtfmt_cfg_starttok_display)
	call append(line('$'),
		\"\<Tab>background colors: ".(b:txtfmt_cfg_bgcolor
			\? "enabled (".b:txtfmt_cfg_numbgcolors." active)"
			\: "disabled"))
	call append(line('$'),
		\"\<Tab>".(b:txtfmt_cfg_longformats ? "'long'" : "'short'")." formats "
		\.(b:txtfmt_cfg_longformats
		\    ?
		\        (b:txtfmt_cfg_undercurl
		\        ? "with"
		\        : "without")
		\        ." undercurl"
		\    :
		\        ""
		\ ))
	call append(line('$'), '')
	" TODO_BG: Decide whether to attempt to be more discriminating: e.g., what
	" if bgcolor is enabled, but none are active? Same question for fgcolor?
	" Decision: I'm thinking there's no reason to do it. Typically, user won't
	" de-activate all colors, but if he does, perhaps we want him to scratch
	" his head a bit.
	if b:txtfmt_cfg_bgcolor
		call append(line('$'),
			\"Each line in the table below corresponds to a single permutation of foreground")
		call append(line('$'),
			\"and background colors. You may use the special global arrays g:txtfmtColor{}")
		call append(line('$'),
			\"and g:txtfmtBgcolor{} to change these colors.")
	else
		call append(line('$'),
			\"Each line in the table below corresponds to a single foreground color. You may")
		call append(line('$'),
			\"use the special global array g:txtfmtColor{} to change these colors.")
	endif
	call append(line('$'), '')
	call append(line('$'),
		\'    :help txtfmt-defining-colors')
	call append(line('$'), '')
	call append(line('$'),
		\"The ".b:txtfmt_num_formats." permutations of the format attributes ")
	call append(line('$'),
		\'(u=underline, b=bold, i=italic'
		\.(b:txtfmt_cfg_longformats
		\     ? ', s=standout, r=reverse'
		\       .b:txtfmt_cfg_undercurl
		\           ? ', c=undercurl'
		\           : ''
		\     : ''
		\ ).')')
	call append(line('$'), "are shown on each color line for completeness.")
	call append(line('$'), tok_fb)
	call append(line('$'),
		\"IMPORTANT NOTE:".tok_fmt_end."Txtfmt chooses a default range for clr/fmt tokens, which works")
	call append(line('$'),
		\"well on most terminals; however, this range may not be suitable for all")
	call append(line('$'),
		\"terminals. In particular, Vim cannot highlight those characters displayed by")
	call append(line('$'),
		\"the terminal as special 2-character sequences (e.g., ^M, ^B, etc...). Although")
	call append(line('$'),
		\"coloring and formatting of text will work when these characters are used as")
	call append(line('$'),
		\"tokens, their use is discouraged, because txtfmt is unable to conceal them. If")
	call append(line('$'),
		\"any such control sequences are visible in the sample text below, you may wish")
	call append(line('$'),
		\"to try a different range, either by setting global txtfmt option")
	call append(line('$'),
		\"g:txtfmtTokrange to a different value, or by including a different definition")
	call append(line('$'),
		\"in a txtfmt modeline string passed to the MakeTestPage command. Either way, you")
	call append(line('$'),
		\"will need to invoke MakeTestPage again to see whether the changed settings are")
	call append(line('$'),
		\"better.")
	call append(line('$'), "")
	call append(line('$'),
		\"    :help txtfmt-choosing-token-range")
	call append(line('$'), '')
	call append(line('$'), tok_fb)
	call append(line('$'),
		\'--color/format table--')
	call append(line('$'), tok_fmt_end)

	" Determine line on which to start the fmt/clr table
	let iLine = line('.')
	" Before looping over bgc, fgc and fmt, determine the length of the list
	" of format specs (i.e., the number of characters, including start fmt
	" specs, from the hyphen to the end of the line).
	" Assumption: Each format token will take up a single character width. (If
	" conceal patch is in effect, it will be a literal space.)
	" Note: We don't include either the 'no format' token at the end of the
	" line or the following space (used for table framing) in the count, as
	" these characters are beyond the edge of the table proper, and we want
	" them to extend beyond the end of the underscores.
	let post_hyphen_width = 1 " hyphen representing 'no fmt'
	let iFmt = 1 " start just after 'no format' token
	while iFmt < b:txtfmt_num_formats
		" Accumulate width of space and fmt spec
		let post_hyphen_width = post_hyphen_width + 1 + strlen(b:ubisrc_fmt{iFmt})
		let iFmt = iFmt + 1
	endwhile
	" Define width of lines up to the hyphen, *NOT* including potentially
	" multibyte token chars that appear at the beginning of the line. A fixed
	" number of columns will be reserved for such tokens.
	" Note: This width is chosen with the string 'no bg color' in mind
	let pre_hyphen_width = 16
	" Generate a string of underscores that spans the table (but not the
	" framing whitespace/tokens at left and right edges)
	let underscores = s:Repeat('_', pre_hyphen_width + post_hyphen_width)
	" Put the text into the buffer
	" Outer loop is over background colors
	" Note: piBgc in the loop below is a 1-based index into
	" b:txtfmt_cfg_bgcolor{}, the array of active color indices. This array
	" stores the actual color index corresponding to the piBgc'th active
	" color; i.e., it stores the indices that are used for the b:txtfmt_bgc{}
	" array. Both arrays are 1-based. Index 0 represents the default (no)
	" color token in b:txtfmt_bgc{}.
	" Note: Even if bgc is disabled, we'll iterate once for default background
	let piBgc = 0
	while piBgc <= (b:txtfmt_cfg_bgcolor ? b:txtfmt_cfg_numbgcolors : 0)
		" Get the actual color index via one level of indirection
		let iBgc = piBgc == 0 ? 0 : b:txtfmt_cfg_bgcolor{piBgc}
		" Don't output the bg color title if bgcolor is disabled
		if b:txtfmt_cfg_bgcolor
			" Put a line consisting entirely of underscores before the bg
			" color title line
			" Note: If this is not the default bg color, a bg token and
			" possibly a default fg token will need to be prepended.
			if iBgc == 0
				" Default bg color
				let s = '  '
			else
				" Non-default bg color
				let s = nr2char(b:txtfmt_bgc_first_tok + iBgc).cncl_ws
				if b:txtfmt_cfg_numfgcolors
					" We're currently inside a fg clr region, but bg color
					" title line should be default fg color, so end the fg
					" color
					let s = s.nr2char(b:txtfmt_clr_first_tok).cncl_ws
				else
					" No fg clr region to end, but need space for alignment
					let s = s.' '
				endif
			endif
			" Now append the underscores and a 2-space end of line pad
			let s = s . underscores . '  '
			call append(line('$'), s)
			" Insert a description of the current bg color
			if iBgc == 0
				let s = "  no bg color"
			else
				let s = "  Bg color ".iBgc
			endif
			" Append spaces such that background coloration is as wide as it is on
			" subsequent lines.
			" Note: The hardcoded 4 is for the beginning and end of line framing spaces
			" Note: s cannot contain multibyte chars at this point, so the
			" strlen() is safe.
			let s = s . s:Repeat(' ', pre_hyphen_width + post_hyphen_width + 4 - strlen(s))
			call append(line('$'), s)
			" Put a line consisting entirely of underscores after the bg color
			" title line
			call append(line('$'), '  ' . underscores . '  ')
		endif
		" Note: See notes on piBgc and iBgc above for description of piClr and
		" iClr.
		let piClr = 0
		while piClr <= b:txtfmt_cfg_numfgcolors
			" Get the actual color index via one level of indirection
			let iClr = piClr == 0 ? 0 : b:txtfmt_cfg_fgcolor{piClr}
			" Build the string for this line, taking care to ensure there is a
			" margin of 2 space widths
			" Note: Need to keep beginning of line spaces/tokens separate
			" until after the strlen(), since strlen counts characters rather
			" than bytes.
			if iClr == 0
				let ldr = '  '
				let s = "no fg color"
			else
				" Insert the non-default fg clr token, preceded by a space in
				" the column dedicated to bg clr tokens
				let ldr = ' '.nr2char(b:txtfmt_clr_first_tok + iClr).cncl_ws
				let s = 'Fg color '.iClr
			endif
			" Pad with spaces till hyphen
			let s = ldr . s . s:Repeat(' ', pre_hyphen_width - strlen(s))
			" Loop over format attributes
			let iFmt = 0
			while iFmt < b:txtfmt_num_formats
				if iFmt == 0
					let s = s.'-'
				else
					" Conceal patch entails special handling to prevent the
					" space between the specifiers from being underlined or
					" undercurled.
					" Case 1: 'conceal'
					" <SPC> <fmt-tok> <fmt-spec> <no-fmt-tok>
					" Case 2: 'noconceal'
					" <fmt-tok> <fmt-spec>
					" Note: For the 'noconceal' case *only*, a single
					" <no-fmt-tok> goes outside loop.
					let s = s . cncl_ws
						\. nr2char(b:txtfmt_fmt_first_tok + iFmt)
						\. b:ubisrc_fmt{iFmt}
						\. (b:txtfmt_cfg_conceal ? nr2char(b:txtfmt_fmt_first_tok) : '')
				endif
				let iFmt = iFmt + 1
			endwhile
			" If necessary, add default fmt token to prevent formatting from
			" spilling onto next line, and add space(s) for margin
			" Case 1: 'conceal'
			" <SPC> <SPC>
			" Case 2: 'noconceal'
			" <no-fmt-tok> <SPC>
			let s = s . (b:txtfmt_cfg_conceal ? ' ' : nr2char(b:txtfmt_fmt_first_tok)) . ' '
			call append(line('$'), s)
			let piClr = piClr + 1
		endwhile
		let piBgc = piBgc + 1
	endwhile
	" Return to default background and foreground colors (as applicable)
	" TODO: If 'conceal', then this has been done already.
	call append(line('$'),
		\(b:txtfmt_cfg_bgcolor && b:txtfmt_cfg_numbgcolors > 0 ? nr2char(b:txtfmt_bgc_first_tok) : '')
		\.(b:txtfmt_cfg_numfgcolors > 0 ? nr2char(b:txtfmt_clr_first_tok) : ''))

	call append(line('$'), tok_fb)
	call append(line('$'),
		\"=============================================================================")
	call append(line('$'),
		\"*** Escaping txtfmt tokens ***")
	$center
	call append(line('$'), tok_fui)
	call append(line('$'),
		\'Configuration:'.tok_fb.cncl_ws."escape".tok_fmt_end.cncl_ws."= ".b:txtfmt_cfg_escape)
	call append(line('$'), "")
	call append(line('$'),
		\"    :help txtfmt-escape")
	" Now display text specific to the option setting
	if b:txtfmt_cfg_escape != 'none'
		call append(line('$'), tok_fb)
		call append(line('$'),
			\'--Escaping tokens outside a region--'.tok_fmt_end)
		call append(line('$'),
			\"The following shows that all tokens (other than the \"no fmt\" / \"no clr\" tokens)")
		call append(line('$'),
			\"may be escaped to prevent them from beginning a region:")
		" Escaped fg color tokens
		call append(line('$'), '')
		call append(line('$'), tok_fb.cncl_ws
			\.'*'.(b:txtfmt_cfg_bgcolor ? 'fg ' : '').'color tokens*'.tok_fmt_end)
		" Loop over all clr tokens, inserting an escaped version of each.
		let s = ''
		let piClr = 1
		while piClr <= b:txtfmt_cfg_numfgcolors
			let iClr = b:txtfmt_cfg_fgcolor{piClr}
			let tok = nr2char(b:txtfmt_clr_first_tok + iClr)
			let s = s.cncl_ws.(b:txtfmt_cfg_escape == 'self' ? tok : '\').tok
			let piClr = piClr + 1
		endwhile
		if s == ''
			" Indicate that no fg colors are active
			let s = ' --N/A--'
		endif
		call append(line('$'), s)
		" Escaped bg color tokens
		if b:txtfmt_cfg_bgcolor
			call append(line('$'), tok_fb.cncl_ws
				\.'*bg color tokens*'.tok_fmt_end)
			" Loop over all bgc tokens, inserting an escaped version of each.
			let s = ''
			let piBgc = 1
			while piBgc <= b:txtfmt_cfg_numbgcolors
				let iBgc = b:txtfmt_cfg_bgcolor{piBgc}
				let tok = nr2char(b:txtfmt_bgc_first_tok + iBgc)
				let s = s.cncl_ws.(b:txtfmt_cfg_escape == 'self' ? tok : '\').tok
				let piBgc = piBgc + 1
			endwhile
			if s == ''
				" Indicate that no bg colors are active
				let s = ' --N/A--'
			endif
			call append(line('$'), s)
		endif
		" Escaped format tokens
		call append(line('$'), tok_fb.cncl_ws
			\.'*format tokens*'.tok_fmt_end)
		" Loop over all fmt tokens, inserting an escaped version of each.
		let s = ''
		let iFmt = 1
		while iFmt < b:txtfmt_num_formats
			let tok = nr2char(b:txtfmt_fmt_first_tok + iFmt)
			let s = s.cncl_ws.(b:txtfmt_cfg_escape == 'self' ? tok : '\').tok
			let iFmt = iFmt + 1
		endwhile
		call append(line('$'), s)
		call append(line('$'), tok_fb)
		call append(line('$'),
			\'--Escaping tokens inside a region--'.tok_fui)
		call append(line('$'), '')
		call append(line('$'),
			\"Here's a little swatch of \"underline, italic\" text. On the line below are some")
		call append(line('$'),
			\"escaped tokens, which, in their unescaped form, would alter the region's")
		call append(line('$'),
			\"formatting:")
		call append(line('$'),
			\(b:txtfmt_cfg_escape == 'self' ? tok_fb : '\').tok_fb
			\.' (escaped bold token), '
			\.(b:txtfmt_cfg_escape == 'self' ? tok_fmt_end : '\').tok_fmt_end
			\.' (escaped "no fmt" token)')
		call append(line('$'),
			\"As you can see, the escaping characters are concealed, and the formatting is")
		call append(line('$'),
			\"unaffected by the escaped tokens.")
		call append(line('$'),
			\"Note: After you have viewed the rest of this page, you may wish to experiment")
		call append(line('$'),
			\"by removing the escape tokens to see how the formatting is affected.")
	else
		" Inform user that escaping is not configured
		call append(line('$'), '')
		call append(line('$'),
			\"Escaping of txtfmt tokens is currently disabled.")
	endif

	call append(line('$'), tok_fb)
	call append(line('$'),
		\"=============================================================================")
	call append(line('$'),
		\"*** Nesting txtfmt regions ***")
	$center
	call append(line('$'), tok_fui)
	call append(line('$'),
		\'Configuration:'.tok_fb.cncl_ws.(b:txtfmt_cfg_nested ? "nested" : "nonested").tok_fmt_end)
	call append(line('$'), "")
	call append(line('$'),
		\"    :help txtfmt-nesting")
	" Now display text specific to the option setting
	if b:txtfmt_cfg_nested
		call append(line('$'), '')
		call append(line('$'),
			\"/* Here's a sample comment (italicized), intended to illustrate the nesting of")
		call append(line('$'),
			\" * txtfmt regions within non-txtfmt regions.")
		call append(line('$'),
			\" *")
		call append(line('$'),
			\" * The following txtfmt token -->".tok_fu."<-- begins a nested \"underline\" region, which")
		call append(line('$'),
			\" * ends with the following \"no fmt\" token. -->".tok_fmt_end."<--")
		call append(line('$'),
			\" * As you can see, the comment resumes automatically after the nested region")
		call append(line('$'),
			\" * ends. */")
		call append(line('$'), "")
		call append(line('$'),
			\"Non-txtfmt regions may be divided into two categories: those with the")
		call append(line('$'),
			\"'keepend' attribute, and those without it. To demonstrate the effect of the")
		call append(line('$'),
			\"'keepend' attribute on nested txtfmt regions, I have defined two additional")
		call append(line('$'),
			\"regions, enclosed by curly braces and square brackets respectively. The curly")
		call append(line('$'),
			\"brace region does not have the 'keepend' attribute; the square bracket region")
		call append(line('$'),
			\"does. Both regions are highlighted in bold.")
		call append(line('$'),
			\"{ Once again, here's a".tok_fu.cncl_ws."nested \"underline\" txtfmt region, followed by a curly")
		call append(line('$'),
			\"brace. }")
		call append(line('$'),
			\"As you can see, the nested txtfmt region was *not* terminated by the")
		call append(line('$'),
			\"closing curly brace. In fact, the curly brace region was extended by the")
		call append(line('$'),
			\"txtfmt region. Notice how the following txtfmt \"no fmt\" token -->".tok_fmt_end."<--")
		call append(line('$'),
			\"permits the resumption of the curly brace region}, which is finally ended by")
		call append(line('$'),
			\"the unobscured closing curly brace.")
		call append(line('$'),
			\"[ Notice, by contrast, how both the".tok_fu.cncl_ws."nested \"underline\" txtfmt region and the")
		call append(line('$'),
			\"square bracket region itself are terminated by the following square bracket ]")
		call append(line('$'),
			\"because the square bracket region was defined with the 'keepend' attribute.")


		" Define comment, curly brace, and square brace regions...
		syn region Tf_example_comment start=+/\*+ end=+\*/+ keepend
		hi Tf_example_comment cterm=italic gui=italic
		syn region Tf_example_curly start=+{+ end=+}+
		hi Tf_example_curly cterm=bold gui=bold
		syn region Tf_example_square start=+\[+ end=+\]+ keepend
		hi Tf_example_square cterm=bold gui=bold
	else
		" Inform user that nesting is not configured
		call append(line('$'), "")
		call append(line('$'),
			\"Nesting of txtfmt regions is currently disabled.")
	endif

endfu
endif	" if !exists('*s:MakeTestPage')
" >>>
" Public-interface commands <<<
" TODO - Add this command to undo list - Should it redefine (com!)?
com! -nargs=? MakeTestPage call s:MakeTestPage(<f-args>)
" >>>
	" vim: sw=4 ts=4 foldmethod=marker foldmarker=<<<,>>> :
