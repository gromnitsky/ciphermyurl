// main

function areCookiesEnabled() {
	var t = 'testcookie'
	$.cookie(t, '1')
	if ($.cookie(t)) {
		$.cookie(t, null)
		return true
	}
	return false
}

$(function() {
	if (!areCookiesEnabled()) $('span#warning').html("<b>Dude, your cookies are disabled. Packing won't work.</b>")
	
	$('textarea#data').focus()
})
