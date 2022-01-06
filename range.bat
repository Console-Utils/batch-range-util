@echo off
setlocal

call :init

:main_loop
    set "option=%~1"
    set "value=%~2"

    set /a "is_help=%false%"
    if "%option%" == "-h" set /a "is_help=%true%"
    if "%option%" == "--help" set /a "is_help=%true%"

    if "%is_help%" == "%true%" (
        call :help
        exit /b %ec_success%
    )

    set /a "is_version=%false%"
    if "%option%" == "-v" set /a "is_version=%true%"
    if "%option%" == "--version" set /a "is_version=%true%"

    if "%is_version%" == "%true%" (
        call :version
        exit /b %ec_success%
    )

    set /a "is_interactive=%false%"
    if "%option%" == "-i" set /a "is_interactive=%true%"
    if "%option%" == "--interactive" set /a "is_interactive=%true%"

    if "%is_interactive%" == "%true%" (
        call :interactive
        exit /b %ec_success%
    )

    set "range=%option%"
    set "next_argument=%value%"

    if defined next_argument (
        echo %em_too_many_arguments% >&2
        exit /b %ec_too_many_arguments%
    )

    call :try_expand_range range "%range%"
    set /a "temp_errorlevel=%errorlevel%"
    if %temp_errorlevel% equ 0 echo %range%
    exit /b %temp_errorlevel%

:init
    set /a "ec_success=0"

    set /a "ec_too_many_arguments=2"

    set "em_too_many_arguments=Other options or ranges are not allowed after first range construction"

    set /a "true=0"
    set /a "false=1"

    set "delimiter= "
    set "prompt=>>> "

    set "sn_right_range_syntax=low..high[..step]."
exit /b %ec_success%

:help
    echo Tool to generate ranges and print them into stdout.
    echo.
    echo [ Non-interactive mode ]
    echo    range [{ -h ^| --help }] [{ -v ^| --version }] { -i ^| --interactive}
	echo    range ^<from^>..^<to^>..[^<step^>]
    echo.
    echo    * -h^|--help - print help
    echo    * -v^|--version - print version
    echo    * -i^|--interactive - start an interactive session
	echo.
    echo    * 0 - Success
    echo    * 2 - Other options or ranges are not allowed after first range construction
    echo    * 2 - Positive step number expected
    echo    * 2 - Unexpected char found instead of range operator (..)
    echo    * 2 - Unexpected end of string found instead of range operator (..)
    echo    * 2 - Unexpected char found instead of digit or number sign
    echo    * 2 - Unexpected end of string found instead of digit or number sign
    echo.
    echo [ Interactive mode ]
	echo    h^|help - print help
	echo    v^|version - print version
    echo    q^|quit - exit
    echo    c^|clear - clears screen
	echo    !! - print help
	echo.
	echo    ^> Interactive mode prompt is: ^<return_code^>^>^>^>.
exit /b %ec_success%

:version
    echo 1.2 ^(c^) 2021 year
exit /b %ec_success%

:interactive
    set "i_em_no_previous_command=No previous command available to perform history expansion"

    set /a "i_last_errorlevel=0"
    set "i_previous_command="

    :i_interactive_loop
        set "i_command="
        set /p "i_command=%i_last_errorlevel% %prompt%"

        if not defined i_command goto i_interactive_loop

        set i_command=%i_command:"=%
        if not defined i_command goto i_interactive_loop
        if "%i_command: =%" == "" goto i_interactive_loop
        
        set "i_comment_regex=^#.*$"
        echo %i_command%| grep %i_comment_regex% 2> nul > nul
		if %errorlevel% equ 0 goto i_interactive_loop

        set "i_after_remove_exclamation_marks=%i_command:!!=%"

        if defined i_previous_command (
            call set "i_command=%%i_command:!!=%i_previous_command%%%"
        ) else (
            if not "%i_command%" == "%i_after_remove_exclamation_marks%" (
                echo %i_em_no_previous_command%
                goto i_interactive_loop
            )
        )

        set /a "i_is_quit=%false%"
        if "%i_command%" == "q" set /a "i_is_quit=%true%"
        if "%i_command%" == "quit" set /a "i_is_quit=%true%"

        if "%i_is_quit%" == "%true%" exit /b %ec_success%
    
        set /a "i_is_clear=%false%"
        if "%i_command%" == "c" set /a "i_is_clear=%true%"
        if "%i_command%" == "clear" set /a "i_is_clear=%true%"

        if "%i_is_clear%" == "%true%" (
            cls
            goto i_interactive_loop
        )

        set /a "i_is_help=%false%"
        if "%i_command%" == "h" set /a "i_is_help=%true%"
        if "%i_command%" == "help" set /a "i_is_help=%true%"

        if "%i_is_help%" == "%true%" (
            call :help
            goto i_interactive_loop
        )

        set "i_previous_command=%i_command%"
        call :try_expand_range i_command "%i_command%"
        set /a "i_last_errorlevel=%errorlevel%"
        if %i_last_errorlevel% equ 0 echo %i_command%
        goto i_interactive_loop
exit /b %ec_success%

:try_expand_range
    set /a "ter_ec_positive_step_number_expected=2"

    set "ter_em_positive_step_number_expected=Positive step number expected"

    set "ter_variable_name=%~1"
    set "ter_range_expression=%~2"

    set "ter_first_number="
    set "ter_second_number="
    set "ter_step=1"
    set /a "ter_i=0"

    call :skip_spaces ter_i "%ter_range_expression%"
    call :skip_number ter_i ter_first_number "%ter_range_expression%"
    set /a "ter_errorlevel=%errorlevel%"
    if %ter_errorlevel% gtr 0 (
        call :underline_error "%ter_range_expression%" "%ter_i%"
        exit /b %ter_errorlevel%
    )

    call :skip_range_operator ter_i "%ter_range_expression%"
    set /a "ter_errorlevel=%errorlevel%"
    if %ter_errorlevel% gtr 0 (
        call :underline_error "%ter_range_expression%" "%ter_i%"
        exit /b %ter_errorlevel%
    )

    call :skip_number ter_i ter_second_number "%ter_range_expression%"
    set /a "ter_errorlevel=%errorlevel%"
    if %ter_errorlevel% gtr 0 (
        call :underline_error "%ter_range_expression%" "%ter_i%"
        exit /b %ter_errorlevel%
    )

    call set "ter_char=%%ter_range_expression:~%ter_i%,1%%"
    set /a "ter_is_empty_char=%false%"
    if not defined ter_char set /a "ter_is_empty_char=%true%"
    if "%ter_char%" == " " set /a "ter_is_empty_char=%true%"

    if "%ter_is_empty_char%" == "%true%" goto ter_step_evaluation

    call :skip_range_operator ter_i "%ter_range_expression%"
    set /a "ter_errorlevel=%errorlevel%"
    if %ter_errorlevel% gtr 0 (
        call :underline_error "%ter_range_expression%" "%ter_i%"
        exit /b %ter_errorlevel%
    )

    call :skip_number ter_i ter_step "%ter_range_expression%"
    set /a "ter_errorlevel=%errorlevel%"
    if %ter_errorlevel% gtr 0 (
        call :underline_error "%ter_range_expression%" "%ter_i%"
        exit /b %ter_errorlevel%
    )

    :ter_step_evaluation
    if %ter_step% leq 0 (
        echo %ter_em_positive_step_number_expected% >&2
        exit /b %ter_ec_positive_step_number_expected%
    )
    if %ter_first_number% gtr %ter_second_number% set /a "ter_step=-%ter_step%"
    
    set /a "ter_after_first_number=%ter_first_number% + %ter_step%"
    set "ter_range_expression=%ter_first_number%"

    set /a "ter_i=%ter_after_first_number%"
    :ter_range_loop
        if %ter_step% gtr 0 (
            if %ter_i% leq %ter_second_number% (
                set "ter_range_expression=%ter_range_expression%%delimiter%%ter_i%"
                set /a "ter_i+=%ter_step%"
                goto ter_range_loop
            )
        ) else (
            if %ter_i% geq %ter_second_number% (
                set "ter_range_expression=%ter_range_expression%%delimiter%%ter_i%"
                set /a "ter_i+=%ter_step%"
                goto ter_range_loop
            )
        )
    
    set "%ter_variable_name%=%ter_range_expression%"
exit /b %ec_success%

:skip_spaces
    set "ss_index_variable_name=%~1"
    set "ss_string=%~2"

    set /a "ss_i=%ss_index_variable_name%"

    :ss_skip_spaces_loop
        call set "ss_char=%%ss_string:~%ss_i%,1%%"
        if defined ss_char (
            if "%ss_char%" == " " (
                set /a "ss_i+=1"
                goto ss_skip_spaces_loop
            )
        )
    
    set "%ss_index_variable_name%=%ss_i%"
exit /b %ec_success%

:skip_range_operator
    set /a "sro_ec_unexpected_char=2"
    set /a "sro_ec_unexpected_end_of_string=2"

    set "sro_em_unexpected_char=Unexpected char found instead of range operator (..)"
    set "sro_em_unexpected_end_of_string=Unexpected end of string found instead of range operator (..)"

    set "sro_index_variable_name=%~1"
    set "sro_string=%~2"

    set /a "sro_i=%sro_index_variable_name%"
    set /a "sro_skipped_count=0"
    set /a "sro_operator_length=2"

    :sro_skip_range_operator_loop
        call set "sro_char=%%sro_string:~%sro_i%,1%%"
        if %sro_skipped_count% lss %sro_operator_length% (
            if defined sro_char (
                if "%sro_char%" == "." (
                    set /a "sro_skipped_count+=1"
                    set /a "sro_i+=1"
                    goto sro_skip_range_operator_loop
                ) else (
                    setlocal enabledelayedexpansion
                    echo !sro_em_unexpected_char!
                    endlocal
                    set "%sro_index_variable_name%=%sro_i%"
                    exit /b %sro_ec_unexpected_char%
                )
            ) else (
                setlocal enabledelayedexpansion
                echo !sro_em_unexpected_end_of_string!
                endlocal
                set "%sro_index_variable_name%=%sro_i%"
                exit /b %sro_ec_unexpected_end_of_string%
            )
        )
    
    set "%sro_index_variable_name%=%sro_i%"
exit /b %ec_success%

:skip_number
    set /a "sn_ec_unexpected_char=2"
    set /a "sn_ec_unexpected_end_of_string=2"

    set "sn_em_unexpected_char=Unexpected char found instead of digit or number sign"
    set "sn_em_unexpected_end_of_string=Unexpected end of string found instead of digit or number sign"

    set "sn_index_variable_name=%~1"
    set "sn_result_number_variable_name=%~2"
    set "sn_string=%~3"
    
    set "sn_result_number="
    set /a "sn_result_number_digit_count=0"
    set /a "sn_i=%sn_index_variable_name%"

    call set "sn_char=%%sn_string:~%sn_i%,1%%"

    if defined sn_char call :sn_internal_if_defined_sn_char

    :sn_skip_number_digits_loop
        call set "sn_char=%%sn_string:~%sn_i%,1%%"
        set "sn_digit_regex=[0-9]"
        if not "%sn_char%" == ""  (
            echo %sn_char%| grep %sn_digit_regex% 2> nul > nul
			if errorlevel 1 (
                if %sn_result_number_digit_count% equ 0 (
                    set "%sn_index_variable_name%=%sn_i%"
                    echo %sn_em_unexpected_char%
                    exit /b %sn_ec_unexpected_char%
                )
            ) else (
                set /a "sn_i+=1"
                set /a "sn_result_number_digit_count+=1"
                set "sn_result_number=%sn_result_number%%sn_char%"
                goto sn_skip_number_digits_loop
            )
        ) else (
            if %sn_result_number_digit_count% equ 0 (
                set "%sn_index_variable_name%=%sn_i%"
                echo %sn_em_unexpected_end_of_string%
                exit /b %sn_ec_unexpected_end_of_string%
            )
        )

    set "%sn_index_variable_name%=%sn_i%"
    set /a "%sn_result_number_variable_name%=%sn_result_number%"
exit /b %ec_success%

:sn_internal_if_defined_sn_char
    set /a "sn_is_sign=%false%"
    if "%sn_char%" == "-" set /a "sn_is_sign=%true%"
    if "%sn_char%" == "+" set /a "sn_is_sign=%true%"
    
    if "%sn_is_sign%" == "%true%" (
        set /a "sn_i+=1"
        set "sn_result_number=%sn_char%"
    )
exit /b %ec_success%

:dublicate_string
    set "ds_variable_name=%~1"
    set "ds_string=%~2"
    set /a "ds_count=%~3"

    set "ds_original_string=%ds_string%"
    set "ds_string="

    set /a "ds_i=0"
    :ds_duplicate_loop
        if %ds_i% lss %ds_count% (
            set "ds_string=%ds_string%%ds_original_string%"
            set /a "ds_i+=1"
            goto ds_duplicate_loop
        )

    set "%ds_variable_name%=%ds_string%"
exit /b %ec_success%

:underline_error
    set "ue_string=%~1"
    set "ue_error_position=%~2"

    set "ue_placeholder= "
    call :dublicate_string ue_placeholder "%ue_placeholder%" "%ue_error_position%"

    echo %ue_string%
    echo %ue_placeholder%^^
exit /b %ec_success%
