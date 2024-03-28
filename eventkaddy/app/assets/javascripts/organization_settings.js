$(document).ready(function(){
	var fields = {}
	$('.field_list p .keys').each(function(){
		key = this.dataset.value
		fields[key] = true
	})
	$('.add-fields').click(function(){
		org_label = $('#field_label').val()
		label = org_label.trimStart().trim().toLowerCase().replace(' ', '_')
		type = $('#type').val()
		id = new Date().toJSON().replaceAll('-', '').replaceAll(':', '').replaceAll('.','').replaceAll('Z', '')
		if(label.length > 0 && !fields[label]){
			fields[label] = true
			input_el = `<input type="hidden" name="organization_setting[fields][${label}]" id="organization_setting_fields_${label}" value="${type}">`

			remove_el = `<a class="btn btn-outline-danger btn-sm remove-field" data-remove="${id}" style=" position: relative; float: right; font-size: 10px; ">Remove</a>`

			li_el =  `<li class="field_list list-group-item" id="${id}"><p class="mb-0"><span class="keys" data-value="${label}">${org_label}(${type})</span> ${remove_el}</p> ${input_el}</li>`

			$('.fields-lists').append(li_el)  
		}else if(fields[label]){
			alert(`${org_label} field already present`)
		}else{
			alert('No Label Text Found')
		}

		$('#field_label').val('')
	})

	$('body').on('click', '.remove-field', (element) => {
		parent_id = '#' + element.target.dataset.remove;
		el = $(`${parent_id}`)
		key = el.find('span')[0].dataset.value
		fields[key] = false
		el.remove();
	})
})