capture program drop Assert
program define Assert
	* Copied from assert_msg.ado
	* Syntax: assert_msg CONDITION , [MSG(a text message)] [RC(integer return code)]
    syntax anything(everything equalok) [if] [in] [, MSG(string asis) RC(integer 9)]
    cap assert `anything' `if' `in'
    local tmp_rc = _rc
    if (`tmp_rc') {
            if (`"`msg'"'=="") local msg `" "assertion is false: `anything' `if' `in'" "'
            di as error `msg'
            exit `rc'
    }
end
