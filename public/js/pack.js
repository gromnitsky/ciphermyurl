function areCookiesEnabled() {
	var t = 'testcookie'
	$.cookie(t, '1')
	if ($.cookie(t)) {
		$.cookie(t, null)
		return true
	}
	return false
}

function treewalk(node, callback) {
	node.children().each(function() {
		if ( (tagIs($(this), 'input') && $(this).attr('type') == 'text')
			 || tagIs($(this), 'textarea') )
			callback($(this))
		
		treewalk($(this), callback)
	})
}

function tagIs(node, name) {
	return (name == node.prop('tagName').toLowerCase())
}

function emptyFormElement(node) {
	node.val('')
}


// main

$(function() {
	if (!areCookiesEnabled()) $('span#warning').html("<b>Dude, your cookies are disabled. Packing won't work.</b>")

	$('textarea#data').focus()

	$('input[type="reset"]', $('form#pack')).click(function() {
		treewalk($('form#pack'), emptyFormElement)
		$('textarea#data').focus()
		return false // suppress 'reset' default behaviour
	})
})
