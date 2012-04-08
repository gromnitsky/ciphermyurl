/*
  Makes a GET request to API and fills a <textarea> with the results.
 */

function Unpack(form, slot, pw) {
    this.form = $(form)
	this.slot = $(slot, this.form)
	this.pw = $(pw, this.form)
}

Unpack.API_VERSION = '0.0.1'
Unpack.HDR_ERROR = 'X-Ciphermyurl-Error'

Unpack.FORM_SUBMIT = 'input[type="submit"]'
Unpack.FORM_RESET = 'input[type="reset"]'
Unpack.TEXTAREA = 'textarea#data'

Unpack.prototype.apiGetDataAndFill = function() {
	$(Unpack.FORM_SUBMIT).attr("disabled", true)
	var url = '/api/'+ Unpack.API_VERSION +'/unpack/' + this.getSlot()
	
	var o = this
	var r = $.get(url, {pw: this.pw.val()}, function(data) {
		o.setTextarea(data)
	})
		.error(function() {
			alert("Error: "+ r.getResponseHeader(Unpack.HDR_ERROR))
			o.setTextarea("")
		})
		.complete(function() {
			o.setupFocus()
			$(Unpack.FORM_SUBMIT).attr("disabled", false)
		});
}

Unpack.prototype.getSlot = function() {
	return this.slot.text() != "" ? this.slot.text() : this.slot.val()
}

Unpack.prototype.setTextarea = function(data) {
	$(Unpack.TEXTAREA).val(data)
}

Unpack.prototype.mybind = function() {
    var o = this
    $(Unpack.FORM_SUBMIT, this.form).click(function() {
        o.apiGetDataAndFill()
        return false
    })

	$(Unpack.FORM_RESET, this.form).click(function() {
		o.setupFocus()
		return true
	})
}

Unpack.prototype.setupFocus = function() {
	this.is_slotInput() ? this.slot.focus() : this.pw.focus()
}

Unpack.prototype.is_slotInput = function() {
	if ('input' == this.slot.prop('tagName').toLowerCase() )
		return true
	return false
}


// main

$(function() {
	// 2 forms do the same job. The 1st form contains a slot in <span>
	// tag, the 2nd form--in <input> field.
	
    var unpack1 = new Unpack('#unpack', '#slot', 'input#pw')
	unpack1.mybind()
	
    var unpack2 = new Unpack('#unpackother', 'input#slot', 'input#pw')
	unpack2.mybind()

	unpack1.getSlot() ? unpack1.setupFocus() : unpack2.setupFocus()
})
