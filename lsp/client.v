module lsp

import x.json2
import os
import util.io_handler as io
import common { DiagMessage, Reference, Symbol }

const content_length = 'Content-Length: '
const report_at = 'please report this as an issue at https://github.com/Ekopalypse/NppLspClient/issues'

pub struct Client {
pub mut:
	config                 Configs
	cur_lang_srv_running   bool
	current_hover_position u32
mut:
	current_stdin  voidptr
	chunks         []string = []
	chunks_length  int      = 0
	content_length int      = -1
	// TODO
	current_file_version int
	working_buffer_id    u64
	file_version_map     map[u64]int
}

pub fn (mut c Client) on_message_received(chunk string) {
	c.chunks_length += chunk.len
	c.chunks << chunk

	mut content_length := c.content_length
	mut concatenated := ''
	mut start_position := 0

	// only concat if '\r' is found or content_length is fulfilled
	if (content_length < 0) {
		if idx_CR := chunk.index_after('\r', 0) {
			concatenated = c.chunks.join('')
			content_length = concatenated[16..c.chunks_length - chunk.len + idx_CR].int()
			start_position = c.chunks_length - chunk.len + idx_CR + 1
		}
	} else if (c.chunks_length >= content_length + 3) { // +3 for the remaining "/n/r/n"
		concatenated = c.chunks.join('')
	}

	if concatenated.len == 0 {
		return
	}

	for {
		if (start_position >= concatenated.len) {
			break
		}

		if (content_length < 0) {
			if idx_CR := concatenated.index_after('\r', start_position) {
				content_length = concatenated[start_position + 16..idx_CR].int()
				start_position = idx_CR + 1
				continue
			}
		} else if (concatenated.len >= start_position + content_length + 3) { // +3 for the remaining "/n/r/n"
			mut json_message := JsonMessage{}
			json_message.from_json(json2.decode[json2.Any](concatenated[start_position + 3..
				start_position + 3 + content_length]) or { json2.Any{} })

			match true {
				json_message.method.len > 0 { notification_handler(json_message) }
				json_message.result.len > 0 { response_handler(json_message) }
				json_message.error.len > 0 { error_response_handler(json_message) }
				else { request_handler(json_message) }
			}

			start_position = start_position + 3 + content_length
			content_length = -1
			continue
		}
		break
	}

	c.chunks.clear()
	c.chunks << concatenated[start_position..]
	c.chunks_length = c.chunks[0].len
	c.content_length = content_length
}

pub fn stop_ls() {
	io.write_to(shutdown_msg())
	io.write_to(exit_msg())
}

pub fn on_initialize(npp_pid int, workspace_directory string) {
	p.console_window.log_info('on_initialize: ${npp_pid}')
	io.write_to(initialize(npp_pid, workspace_directory))
}

fn initialize_response(json_message string) {
	result := json2.raw_decode(json_message) or { '' }
	result_map := result.as_map()
	if 'capabilities' in result_map {
		capabilities := result_map['capabilities'] or { '' }
		mut sc := ServerCapabilities{}
		sc.from_json(json2.decode[json2.Any](capabilities.str()) or { json2.Any{} })
		p.console_window.log_info('    initialized response received')

		p.lsp_config.lspservers[p.current_language].features = sc

		io.write_to(initialized())

		p.lsp_config.lspservers[p.current_language].initialized = true
		p.working_buffer_id = u64(p.npp.get_current_buffer_id())
		p.current_file_version = 0
		p.file_version_map[p.working_buffer_id] = p.current_file_version
		on_file_opened(p.npp.get_current_filename())
	} else {
		p.console_window.log_error('  unexpected initialize response received')
	}
}

pub fn on_file_opened(file_name string) {
	if file_name.len == 0 {
		return
	}
	lang_id := if p.current_language == 'vlang' { 'v' } else { p.current_language }
	p.console_window.log_info('on_file_opened:: ${p.current_language}: ${file_name}')
	p.console_window.log_info('on_file_opened: initialized=${p.lsp_config.lspservers[p.current_language].initialized}')
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.send_open_close_notif {
		content := p.editor.get_text()
		io.write_to(did_open(file_name, 0, lang_id, content))
	}
	on_document_symbols(file_name)
}

pub fn on_file_before_saved(file_name string) {
	p.console_window.log_info('on_file_before_saved: ${file_name}')
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.supports_will_save {
		io.write_to(will_save(file_name))
	}
}

pub fn on_file_saved(file_name string) {
	p.console_window.log_info('on_file_saved: ${file_name}')
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.send_save_notif {
		mut content := ''
		if p.lsp_config.lspservers[p.current_language].features.include_text_in_save_notif {
			content = p.editor.get_text()
		}
		io.write_to(did_save(file_name, content))
	}
	on_document_symbols(file_name)
}

pub fn on_will_save_wait_until(file_name string) {
	// TODO: make this an lspclient configuration parameter?
	p.console_window.log_info('on_file_saved: ${file_name}')
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.supports_will_save_wait_until {
		// TextDocumentSaveReason.FocusOut = 3
		io.write_to(will_save_wait_until(file_name, 3))
	}
}

pub fn on_file_closed(file_name string) {
	p.console_window.log_info('on_file_closed: ${file_name}')
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.send_open_close_notif {
		io.write_to(did_close(file_name))
	}
}

pub fn on_buffer_modified(file_name string, start_line u32, start_char_pos u32, end_line u32, end_char_pos u32, text string) {
	if p.lsp_config.lspservers[p.current_language].initialized {
		p.current_file_version++

		match p.lsp_config.lspservers[p.current_language].features.text_document_sync {
			1 { // TextDocumentSyncKind.full
				io.write_to(did_change_full(file_name, p.current_file_version, p.editor.get_text()))
			}
			2 { // TextDocumentSyncKind.incremental
				content := text.replace_each(['\\', '\\\\', '\b', r'\b', '\f', r'\f', '\r', r'\r',
					'\n', r'\n', '\t', r'\t', '"', r'\"'])
				io.write_to(did_change_incremental(file_name, p.current_file_version,
					content, start_line, start_char_pos, end_line, end_char_pos))
			}
			else {}
		}

		// on_completion(file_name, start_line, start_char_pos+1, text)
		// on_signature_help(file_name, start_line, start_char_pos+1, text)
	}
}

pub fn on_completion(file_name string, start_line u32, start_char_pos u32, text string) {
	if p.lsp_config.lspservers[p.current_language].initialized {
		text__ := if text in p.lsp_config.lspservers[p.current_language].features.completion_provider.trigger_characters {
			text
		} else {
			''
		}
		io.write_to(request_completion(file_name, start_line, start_char_pos, text__))
	}
}

fn completion_response(json_message string) {
	mut ci := []CompletionItem{}
	if json_message.contains('"items":') {
		mut cl := CompletionList{}
		cl.from_json(json2.decode[json2.Any](json_message) or { json2.Any{} })
		ci = cl.items.clone()
	} else {
		mut cia := CompletionItemArray{}
		cia.from_json(json2.decode[json2.Any](json_message) or { json2.Any{} })
		ci = cia.items.clone()
	}
	if ci.len > 0 {
		mut ci__ := ci.map(fn (item CompletionItem) string {
			label := if item.insert_text.len > 0 {
				item.insert_text.trim_space()
			} else {
				item.label.trim_space()
			}
			return label
		})
		ci__.sort()
		p.editor.display_completion_list(ci__.join('\n'))
	}
}

pub fn on_signature_help(file_name string, start_line u32, start_char_pos u32, text string) {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& text in p.lsp_config.lspservers[p.current_language].features.signature_help_provider.trigger_characters {
		io.write_to(request_signature_help(file_name, start_line, start_char_pos, text))
	}
}

fn signature_help_response(json_message string) {
	p.console_window.log_info('  signature help response received: ${json_message}')
	mut sh := SignatureHelp{}
	sh.from_json(json2.decode[json2.Any](json_message) or { json2.Any{} })
	if sh.signatures.len > 0 {
		p.editor.display_signature_hints(sh.signatures[0].label)
	}
	p.console_window.log_info('${sh}')
}

pub fn on_format_document(file_name string) {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.document_formatting_provider {
		io.write_to(format_document(file_name, p.editor.get_tab_size(), p.editor.use_spaces(),
			true, true, true))
	}
}

fn format_document_response(json_message string) {
	mut tea := TextEditArray{}
	tea.from_json(json2.decode[json2.Any](json_message) or { json2.Any{} })
	p.editor.format_document(tea)
}

pub fn on_format_selected_range(file_name string) {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.document_range_formatting_provider {
		start_line, end_line, start_char, end_char := p.editor.get_range_from_selection()
		io.write_to(format_selected_range(file_name, start_line, end_line, start_char,
			end_char, p.editor.get_tab_size(), p.editor.use_spaces(), true, true, true))
	}
}

pub fn on_goto_definition(file_name string) {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.definition_provider {
		current_line, char_pos := p.editor.get_lsp_position_info()
		io.write_to(goto_definition(file_name, current_line, char_pos))
	}
}

fn goto_definition_response(json_message string) {
	goto_location_helper(json_message)
}

pub fn on_goto_implementation(file_name string) {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.implementation_provider {
		current_line, char_pos := p.editor.get_lsp_position_info()
		io.write_to(goto_implementation(file_name, current_line, char_pos))
	}
}

fn goto_implementation_response(json_message string) {
	goto_location_helper(json_message)
}

fn goto_location_helper(json_message string) {
	if json_message.starts_with('[') {
		if json_message.contains('originSelectionRange') {
			mut lla := LocationLinkArray{}
			lla.from_json(json2.decode[json2.Any](json_message) or { json2.Any{} })
			if lla.items.len > 0 {
				p.npp.open_document(lla.items[0].target_uri)
				p.editor.goto_position(lla.items[0].target_range.start.line, lla.items[0].target_range.start.character)
			}
		} else {
			mut loca := LocationArray{}
			loca.from_json(json2.decode[json2.Any](json_message) or { json2.Any{} })
			if loca.items.len > 0 {
				p.npp.open_document(loca.items[0].uri)
				p.editor.goto_position(loca.items[0].range.start.line, loca.items[0].range.start.character)
			}
		}
	} else {
		mut loc := Location{}
		loc.from_json(json2.decode[json2.Any](json_message) or { json2.Any{} })
		p.npp.open_document(loc.uri)
		p.editor.goto_position(loc.range.start.line, loc.range.start.character)
	}
}

pub fn on_peek_definition(file_name string) {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.definition_provider {
		current_line, char_pos := p.editor.get_lsp_position_info()
		io.write_to(peek_definition(file_name, current_line, char_pos))
	}
}

fn peek_definition_response(json_message string) {
	peek_helper(json_message)
}

pub fn on_peek_implementation(file_name string) {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.implementation_provider {
		current_line, char_pos := p.editor.get_lsp_position_info()
		io.write_to(peek_implementation(file_name, current_line, char_pos))
	}
}

fn peek_implementation_response(json_message string) {
	peek_helper(json_message)
}

fn peek_helper(json_message string) {
	mut start_line := u32(0)
	mut end_line := u32(0)
	mut source_file := ''
	if json_message.starts_with('[') {
		if json_message.contains('originSelectionRange') {
			mut lla := LocationLinkArray{}
			lla.from_json(json2.decode[json2.Any](json_message) or { json2.Any{} })
			if lla.items.len > 0 {
				source_file = lla.items[0].target_uri
				start_line = lla.items[0].target_range.start.line
				end_line = lla.items[0].target_range.end.line
			}
		} else {
			mut loca := LocationArray{}
			loca.from_json(json2.decode[json2.Any](json_message) or { json2.Any{} })
			if loca.items.len > 0 {
				source_file = loca.items[0].uri
				start_line = loca.items[0].range.start.line
				end_line = loca.items[0].range.end.line
			}
		}
	} else {
		mut loc := Location{}
		loc.from_json(json2.decode[json2.Any](json_message) or { json2.Any{} })
		source_file = loc.uri
		start_line = loc.range.start.line
		end_line = loc.range.end.line
	}

	if source_file.len > 0 {
		if os.exists(source_file) {
			content := os.read_lines(source_file) or { [''] }
			first_line := int(start_line)
			last_line__ := int(end_line)
			if content.len >= last_line__ {
				last_line := if content.len >= last_line__ + 4 {
					last_line__ + 4
				} else {
					content.len
				}
				peeked_code := '\n${content[first_line..last_line].join('\n')}'
				p.editor.show_peeked_info(peeked_code)
			}
		}
	}
}

pub fn on_goto_declaration(file_name string) {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.declaration_provider {
		current_line, char_pos := p.editor.get_lsp_position_info()
		io.write_to(goto_declaration(file_name, current_line, char_pos))
	}
}

fn goto_declaration_response(json_message string) {
	goto_location_helper(json_message)
}

pub fn on_find_references(file_name string) {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.references_provider {
		current_line, char_pos := p.editor.get_lsp_position_info()
		io.write_to(find_references(file_name, current_line, char_pos))
	}
}

fn find_references_response(json_message string) {
	mut references := []Reference{}
	if json_message.starts_with('[') {
		mut loca := LocationArray{}
		loca.from_json(json2.decode[json2.Any](json_message) or { json2.Any{} })
		if loca.items.len > 0 {
			for item in loca.items {
				references << Reference{item.uri, item.range.start.line, item.range.start.character, item.range.end.character}
			}
			p.references_window.update(references)
		}
	}
}

pub fn on_document_highlight(file_name string) {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.document_highlight_provider {
		current_line, char_pos := p.editor.get_lsp_position_info()
		io.write_to(document_highlight(file_name, current_line, char_pos))
	}
}

fn document_highlight_response(json_message string) {
	if json_message.starts_with('[') {
		mut dha := DocumentHighlightArray{}
		dha.from_json(json2.decode[json2.Any](json_message) or { json2.Any{} })
		p.editor.highlight_occurances(dha)
	}
}

pub fn on_document_symbols(file_name string) {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.document_symbol_provider {
		io.write_to(document_symbols(file_name))
	}
}

fn document_symbols_response(json_message string) {
	p.symbols_window.clear()
	mut symbols := []Symbol{}
	if json_message.starts_with('[') {
		if json_message.contains('selectionRange') {
			// TODO: bad hack, json2 decoder has issues with double backslash
			json_message__ := json_message.replace('\\', '/')
			mut dsa := DocumentSymbolArray{}
			dsa.from_json(json2.decode[json2.Any](json_message__) or { json2.Any{} })
			for item in dsa.items {
				for sym in item.children {
					symbols << Symbol{item.name, sym.name, sym.kind, sym.range.start.line, ''}
				}
			}
		} else {
			mut sia := SymbolInformationArray{}
			sia.from_json(json2.decode[json2.Any](json_message) or { json2.Any{} })
			for item in sia.items {
				symbols << Symbol{item.location.uri, item.name, item.kind, item.location.range.start.line, item.container_name}
			}
		}
	}
	p.symbols_window.update(mut symbols)
}

pub fn on_hover(file_name string) {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.hover_provider {
		current_line := p.editor.line_from_position(usize(p.lsp_client.current_hover_position))
		char_pos := p.lsp_client.current_hover_position - p.editor.position_from_line(current_line)
		io.write_to(hover(file_name, current_line, char_pos))
	}
}

fn hover_response(json_message string) {
	mut h := Hover{}
	h.from_json(json2.decode[json2.Any](json_message) or { json2.Any{} })
	p.editor.display_hover_hints(p.lsp_client.current_hover_position, h.contents)
}

pub fn on_rename(file_name string, new_name string) {
	// TODO: really needed ?? - Npp offers replace in files, opened documents etc...
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.rename_provider {
		current_line, char_pos := p.editor.get_lsp_position_info()
		io.write_to(rename(file_name, current_line, char_pos, new_name))
	}
}

fn rename_response(json_message string) {
	p.console_window.log_info('rename response received: ${json_message}')

	// TODO
}

pub fn on_prepare_rename(file_name string) {
	// TODO: really needed ?? - Could be interesting to see if the name given is valid
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.rename_provider {
		current_line, char_pos := p.editor.get_lsp_position_info()
		io.write_to(prepare_rename(file_name, current_line, char_pos))
	}
}

fn prepare_rename_response(json_message string) {
	p.console_window.log_info('prepare rename response received: ${json_message}')

	// TODO
}

pub fn on_folding_range(file_name string) {
	// TODO: really needed ?? Could be interesting to fold the next folding level from a given position ??
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.folding_range_provider {
		io.write_to(folding_range(file_name))
	}
}

fn folding_range_response(json_message string) {
	p.console_window.log_info('folding range response received: ${json_message}')

	// TODO
}

pub fn on_selection_range(file_name string) {
	// TODO: really needed ?? would be another way of selecting text ??
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.selection_range_provider {
		current_line, char_pos := p.editor.get_lsp_position_info()
		io.write_to(selection_range(file_name, current_line, char_pos))
	}
}

fn selection_range_response(json_message string) {
	p.console_window.log_info('selection range response received: ${json_message}')

	// TODO
}

pub fn on_cancel_request(request_id int) {
	// TODO: which requests should be cancellable??
	if p.lsp_config.lspservers[p.current_language].initialized {
		io.write_to(cancel_request(request_id))
	}
}

pub fn on_progress(token int, value string) {
	// TODO: why would a client sent a progress notification to a server ??
	if p.lsp_config.lspservers[p.current_language].initialized {
		io.write_to(progress(token, value))
	}
}

pub fn on_set_trace(trace_value string) {
	// TODO: find out where the valid values come from
	if p.lsp_config.lspservers[p.current_language].initialized
		&& (trace_value == 'off' || trace_value == 'messages' || trace_value == 'verbose') {
		io.write_to(set_trace(trace_value))
	}
}

pub fn on_incoming_calls() {
	// The request doesn’t define its own client and server capabilities.
	// It is only issued if a server registers for the textDocument/prepareCallHierarchy request.
	//  TODO: WorkDoneProgressParams
	token := 0
	value := ''
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.call_hierarchy_prepare_call {
		io.write_to(incoming_calls(token, value))
	}
}

fn incoming_calls_response(json_message string) {
	// TODO:
	p.console_window.log_info('incoming_calls_response: ${json_message}')
}

pub fn on_outgoing_calls() {
	// see on_incoming_calls note
	//  TODO: WorkDoneProgressParams
	token := 0
	value := ''
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.call_hierarchy_prepare_call {
		io.write_to(outgoing_calls(token, value))
	}
}

fn outgoing_calls_response(json_message string) {
	// TODO:
	p.console_window.log_info('outgoing_calls_response: ${json_message}')
}

pub fn on_code_action_resolve() {
	// TODO: how should this get be triggered?
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.code_action_resolve_provider {
		title := ''
		io.write_to(code_action_resolve(title))
	}
}

fn code_action_resolve_response(json_message string) {
	// TODO:
	p.console_window.log_info('resolve_response: ${json_message}')
}

pub fn on_code_lens_resolve(file_name string) {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.code_lens_provider {
		io.write_to(code_lens_resolve(file_name))
	}
}

fn code_lens_resolve_response(json_message string) {
	// TODO:
	p.console_window.log_info('resolve_response: ${json_message}')
}

pub fn on_completion_item_resolve(label string) {
	// TODO: supposed to be a request which gathers additional information about
	// the selected completion item.
	// Either use SCN_AUTOCSELECTION or SCN_USERLISTSELECTION (or both ?)
	// But how to display such additional information?
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.completion_provider.resolve_provider {
		io.write_to(completion_item_resolve(label))
	}
}

fn completion_item_resolve_response(json_message string) {
	// TODO:
	p.console_window.log_info('resolve_response: ${json_message}')
}

pub fn on_document_link_resolve() {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.document_link_provider {
		// TODO:
		start_line, start_char, end_line, end_char := u32(0), u32(0), u32(0), u32(0)
		io.write_to(document_link_resolve(start_line, start_char, end_line, end_char))
	}
}

fn document_link_resolve_response(json_message string) {
	// TODO:
	p.console_window.log_info('resolve_response: ${json_message}')
}

pub fn on_code_action(file_name string) {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.code_action_provider {
		start_line, start_char, end_line, end_char := u32(0), u32(0), u32(0), u32(0)
		io.write_to(code_action(file_name, start_line, start_char, end_line, end_char))
	}
}

fn code_action_response(json_message string) {
	// TODO:
	p.console_window.log_info('code_action_response: ${json_message}')
}

pub fn on_code_lens(file_name string) {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.code_lens_provider {
		io.write_to(code_lens(file_name))
	}
}

fn code_lens_response(json_message string) {
	// TODO:
	p.console_window.log_info('code_lens_response: ${json_message}')
}

pub fn on_color_presentation(file_name string) {
	// TODO:
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.color_provider {
		// io.write_to(
		// p.current_stdin,
		// lsp.color_presentation(file_name,
		// start_line,
		// start_char,
		// end_line,
		// end_char,
		// red,
		// green,
		// blue,
		// alpha)
		// )
	}
}

fn color_presentation_response(json_message string) {
	p.console_window.log_info('color_presentation_response')
	mut cpa := ColorPresentationArray{}
	cpa.from_json(json2.decode[json2.Any](json_message) or { json2.Any{} })
	for item in cpa.items {
		p.console_window.log_info('${item}')
	}
}

pub fn on_document_color(file_name string) {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.color_provider {
		io.write_to(document_color(file_name))
	}
}

fn document_color_response(json_message string) {
	p.console_window.log_info('document_color_response')
	mut cia := ColorInformationArray{}
	cia.from_json(json2.decode[json2.Any](json_message) or { json2.Any{} })
	for item in cia.items {
		p.console_window.log_info('  ${item.range}')
		p.console_window.log_info('  ${item.color}')
	}
}

pub fn on_document_link(file_name string) {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.document_link_provider {
		io.write_to(document_link(file_name))
	}
}

fn document_link_response(json_message string) {
	// TODO:
	p.console_window.log_info('document_link_response: ${json_message}')
}

pub fn on_linked_editing_range(file_name string) {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.linked_editing_range_provider {
		current_line, char_pos := p.editor.get_lsp_position_info()
		io.write_to(linked_editing_range(file_name, current_line, char_pos))
	}
}

fn linked_editing_range_response(json_message string) {
	// TODO:
	p.console_window.log_info('linked_editing_range_response: ${json_message}')
}

pub fn on_moniker(file_name string) {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.moniker_provider {
		current_line, char_pos := p.editor.get_lsp_position_info()
		io.write_to(moniker(file_name, current_line, char_pos))
	}
}

fn moniker_response(json_message string) {
	p.console_window.log_info('moniker_response: ${json_message}')
}

pub fn on_on_type_formatting(file_name string, ch string) {
	// TODO: I assume makes only sense with SCN_CHARADDED notification or
	// buffer modified with inserted text filter
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.document_on_type_formatting_provider {
		current_line, char_pos := p.editor.get_lsp_position_info()
		io.write_to(on_type_formatting(file_name, current_line, char_pos, ch, p.editor.get_tab_size(),
			p.editor.use_spaces()))
	}
}

fn on_type_formatting_response(json_message string) {
	// TODO:
	p.console_window.log_info('on_type_formatting_response: ${json_message}')
}

pub fn on_prepare_call_hierarchy(file_name string) {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.call_hierarchy_provider {
		current_line, char_pos := p.editor.get_lsp_position_info()
		io.write_to(prepare_call_hierarchy(file_name, current_line, char_pos))
	}
}

fn prepare_call_hierarchy_response(json_message string) {
	// TODO:
	p.console_window.log_info('prepare_call_hierarchy_response: ${json_message}')
}

pub fn on_semantic_tokens_full(file_name string) {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.semantic_tokens_provider {
		io.write_to(semantic_tokens_full(file_name))
	}
}

fn semantic_tokens_full_response(json_message string) {
	// TODO:
	p.console_window.log_info('full_response: ${json_message}')
}

pub fn on_semantic_tokens_delta(file_name string) {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.semantic_tokens_provider {
		// TODO:
		// The result id of a previous response.
		// The result Id can either point to a full response or
		// a delta response depending on what was received last.
		previous_result_id := ''
		io.write_to(semantic_tokens_delta(file_name, previous_result_id))
	}
}

fn semantic_tokens_delta_response(json_message string) {
	// TODO:
	p.console_window.log_info('delta_response: ${json_message}')
}

pub fn on_semantic_tokens_range(file_name string) {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.semantic_tokens_provider {
		// TODO:
		start_line, start_char, end_line, end_char := u32(0), u32(0), u32(0), u32(0)
		io.write_to(semantic_tokens_range(file_name, start_line, start_char, end_line,
			end_char))
	}
}

fn semantic_tokens_range_response(json_message string) {
	// TODO:
	p.console_window.log_info('range_response: ${json_message}')
}

pub fn on_type_definition(file_name string) {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.type_definition_provider {
		current_line, char_pos := p.editor.get_lsp_position_info()
		io.write_to(type_definition(file_name, current_line, char_pos))
	}
}

fn type_definition_response(json_message string) {
	p.console_window.log_info('type_definition_response: ${json_message}')
	goto_location_helper(json_message)
}

pub fn on_work_done_progress_cancel(file_name string) {
	// TODO:
	if p.lsp_config.lspservers[p.current_language].initialized {
		// io.write_to(
		// p.current_stdin,
		// lsp.work_done_progress_cancel(token, value)
		// )
	}
}

pub fn on_workspace_did_change_configuration() {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.supports_workspace_capabilities {
		// TODO: How to know what kind of settings are expected??
		// and how to get informed about those changes??
		io.write_to(workspace_did_change_configuration('null'))
	}
}

pub fn on_workspace_did_change_watched_files() {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.supports_workspace_capabilities {
		// TODO: Either Npp's or an own file/folder change monitor needs to be implemented.
		file_event_array := FileEventArray{}
		io.write_to(workspace_did_change_watched_files(file_event_array))
	}
}

pub fn on_workspace_did_change_workspace_folders() {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.supports_workspace_capabilities {
		// TODO: needs support from Npp to retrieve the folders from FAW and Projects
		added_folders := WorkspaceFolderArray{}
		removed_folders := WorkspaceFolderArray{}
		io.write_to(workspace_did_change_workspace_folders(added_folders, removed_folders))
	}
}

pub fn on_workspace_did_create_files() {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.workspace_capabilities.file_operations.did_create_supported {
		// TODO:
		files_created := FileCreateArray{}
		io.write_to(workspace_did_create_files(files_created))
	}
}

pub fn on_workspace_did_delete_files() {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.workspace_capabilities.file_operations.did_delete_supported {
		// TODO:
		files_deleted := FileDeleteArray{}
		io.write_to(workspace_did_delete_files(files_deleted))
	}
}

pub fn on_workspace_did_rename_files() {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.workspace_capabilities.file_operations.did_rename_supported {
		// TODO:
		files_renamed := FileRenameArray{}
		io.write_to(workspace_did_rename_files(files_renamed))
	}
}

pub fn on_workspace_execute_command() {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.supports_workspace_capabilities {
		// TODO:
		command := ''
		args := ['']
		io.write_to(workspace_execute_command(command, args))
	}
}

fn workspace_execute_command_response(json_message string) {
	// TODO:
	p.console_window.log_info('execute_command_response: ${json_message}')
}

pub fn on_workspace_symbol(file_name string) {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.workspace_symbol_provider {
		io.write_to(workspace_symbol(file_name))
	}
}

fn workspace_symbol_response(json_message string) {
	p.console_window.log_info('symbol_response: ${json_message}')
	if json_message.starts_with('[') {
		mut sia := SymbolInformationArray{}
		sia.from_json(json2.decode[json2.Any](json_message) or { json2.Any{} })
		for item in sia.items {
			p.console_window.log_info('  ${item.name}')
		}
	}
}

pub fn on_workspace_will_create_files() {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.workspace_capabilities.file_operations.will_create_supported {
		// TODO:
		files_created := FileCreateArray{}
		io.write_to(workspace_will_create_files(files_created))
	}
}

fn workspace_will_create_files_response(json_message string) {
	// TODO:
	p.console_window.log_info('will_create_files_response: ${json_message}')
}

pub fn on_workspace_will_delete_files() {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.workspace_capabilities.file_operations.will_delete_supported {
		// TODO:
		files_deleted := FileDeleteArray{}
		io.write_to(workspace_will_delete_files(files_deleted))
	}
}

fn workspace_will_delete_files_response(json_message string) {
	// TODO:
	p.console_window.log_info('will_delete_files_response: ${json_message}')
}

pub fn on_workspace_will_rename_files() {
	if p.lsp_config.lspservers[p.current_language].initialized
		&& p.lsp_config.lspservers[p.current_language].features.workspace_capabilities.file_operations.will_rename_supported {
		// TODO:
		files_renamed := FileRenameArray{}
		io.write_to(workspace_will_rename_files(files_renamed))
	}
}

fn workspace_will_rename_files_response(json_message string) {
	// TODO:
	p.console_window.log_info('will_rename_files_response: ${json_message}')
}

fn notification_handler(json_message JsonMessage) {
	match json_message.method {
		'textDocument/publishDiagnostics' {
			publish_diagnostics(json_message.params)
		}
		'window/showMessage' {
			log_message(json_message.params)
		}
		'window/logMessage' {
			log_message(json_message.params)
		}
		// TODO
		'$/cancelRequest' {
			decode_cancel_request_notification(json_message.params)
		}
		'$/progress' {
			decode_progress_notification(json_message.params)
		}
		'window/workDoneProgress/cancel' {
			decode_window_work_done_progress_cancel(json_message.params)
		}
		'telemetry/event' {
			decode_telemetry_event(json_message.params)
		}
		// 'workspace/didCreateFiles' { decode_workspace_did_create_files(json_message.params) }
		// 'workspace/didRenameFiles' { decode_workspace_did_rename_files(json_message.params) }
		// 'workspace/didDeleteFiles' { decode_workspace_did_delete_files(json_message.params) }
		else {
			if !p.lsp_config.lspservers[p.current_language].custom_messages.contains(json_message.method) {
				p.console_window.log_warning('An unexpected notification has been received, ${report_at}.')
			}
		}
	}
}

fn publish_diagnostics(params string) {
	mut diag := PublishDiagnosticsParams{}
	diag.from_json(json2.decode[json2.Any](params) or { json2.Any{} })
	p.editor.clear_diagnostics()
	p.diag_window.clear(p.current_language)
	mut messages := []DiagMessage{}
	for d in diag.diagnostics {
		start := p.editor.position_from_line(d.range.start.line) + d.range.start.character
		end := p.editor.position_from_line(d.range.end.line) + d.range.end.character
		if p.current_file_path == diag.uri {
			p.editor.add_diag_indicator(start, end - start, d.severity)
			if p.npp_version >= 0x80021 {
				p.editor.add_diag_annotation(d.range.start.line, d.severity, d.message.replace_each([
					'\r',
					' ',
					'\n',
					' ',
				]))
			}
		}
		messages << DiagMessage{
			file_name: diag.uri
			line:      d.range.start.line
			column:    d.range.start.character
			message:   d.message
			severity:  u8(d.severity)
		}
	}
	messages.sort(a.severity < b.severity)
	p.diag_window.update(p.current_language, messages)
}

fn log_message(json_message string) {
	mut smp := ShowMessageParams{}
	smp.from_json(json2.decode[json2.Any](json_message) or { json2.Any{} })
	p.console_window.log_styled(smp.message, u8(smp.type_))
}

fn decode_cancel_request_notification(json_message string) {
	// TODO: once supported it needs some kind of stored requests container
	mut cp := CancelParams{}
	cp.from_json(json2.decode[json2.Any](json_message) or { json2.Any{} })
	p.console_window.log_info('cancel_request_notification: ${cp.str()}')
}

fn decode_progress_notification(json_message string) {
	// TODO: is supposed to show any progress - how should this be implemented in Npp?
	mut pp := ProgressParams{}
	pp.from_json(json2.decode[json2.Any](json_message) or { json2.Any{} })
	p.console_window.log_info('progress_notification: ${pp.str()}')
}

fn decode_window_work_done_progress_cancel(json_message string) {
	// TODO: is supposed to end a progress widget(?).
	mut wdpcp := WorkDoneProgressCancelParams{}
	wdpcp.from_json(json2.decode[json2.Any](json_message) or { json2.Any{} })
	p.console_window.log_info('window_work_done_progress_cancel: ${wdpcp.str()}')
}

fn decode_telemetry_event(json_message string) {
	// TODO: to quote from lsp specification
	// The protocol doesn’t specify the payload
	// since no interpretation of the data happens in the protocol.
	// Most clients even don’t handle the event directly but forward
	// them to the extensions owing the corresponding server issuing the event.
	// The open question is: how to forward ??
	p.console_window.log_info('telemetry_event: ${json_message}')
}

fn response_handler(json_message JsonMessage) {
	id := json_message.id
	result := json_message.result
	if result != 'null' {
		// func_ptr := p.open_response_messages[id]
		func_ptr := p.lsp_config.lspservers[p.current_language].open_response_messages[id]
		if func_ptr != unsafe { nil } {
			func_ptr(result.str())
		} else {
			p.console_window.log_warning('An unexpected response message has been received, ${report_at}.')
		}
	}
	p.lsp_config.lspservers[p.current_language].open_response_messages.delete(id)
}

fn error_response_handler(json_message JsonMessage) {
	p.console_window.log_error('  !! ERROR RESPONSE !! received')
	p.lsp_config.lspservers[p.current_language].open_response_messages.delete(json_message.id)
}

fn request_handler(json_message JsonMessage) {
	match json_message.method {
		'window/showMessageRequest' {
			mut smrp := ShowMessageRequestParams{}
			smrp.from_json(json2.decode[json2.Any](json_message.params) or { json2.Any{} })
			p.console_window.log_styled('${smrp.message}\n${smrp.actions.join('\n')}',
				u8(smrp.type_))
			send_null_response(json_message.id)
		}
		'window/showDocument' {
			mut sdp := ShowDocumentParams{}
			sdp.from_json(json2.decode[json2.Any](json_message.params) or { json2.Any{} })

			// TODO: need some examples
			p.console_window.log_info('window/showDocument\n ${sdp}')
			mut m := Message{
				msg_type: JsonRpcMessageType.response
				id:       json_message.id
				response: '"result":{"success": false}'
				// TODO:
			}
			io.write_to(m.encode())
		}
		'client/registerCapability' {
			// TODO:
			//	{
			//		"id": "5fadd9c6-0c75-4499-9dac-19af07962e0f",
			//		"jsonrpc": "2.0",
			//		"method": "client/registerCapability",
			//		"params": {
			//			"registrations": [
			//				{
			//					"id": "profilegc.watchfiles",
			//					"method": "workspace/didChangeWatchedFiles",
			//					"registerOptions": {
			//						"watchers": [
			//							{
			//								"globPattern": "**/profilegc.log",
			//								"kind": null
			// 							}
			// 						]
			// 					}
			// 				}
			// 			]
			// 		}
			//	}
			mut rp := RegistrationParams{}
			rp.from_json(json2.decode[json2.Any](json_message.params) or { json2.Any{} })
			p.console_window.log_info('registerCapability: ${rp}')
			send_null_response(json_message.id)
		}
		'client/unregisterCapability' {
			// TODO: need some examples how this should work and what it is for.
			mut up := UnregistrationParams{}
			up.from_json(json2.decode[json2.Any](json_message.params) or { json2.Any{} })
			p.console_window.log_info('unregisterCapability: ${up.str()}')
			send_null_response(json_message.id)
		}
		'window/workDoneProgress/create' {
			// TODO: is supposed to inform that the progress widget(?) can be closed.
			mut wdpcp := WorkDoneProgressCreateParams{}
			wdpcp.from_json(json2.decode[json2.Any](json_message.params) or { json2.Any{} })
			p.console_window.log_info('window_work_done_progress_create: ${wdpcp.str()}')
			send_null_response(json_message.id)
		}
		'workspace/workspaceFolders' {
			// TODO: once this is supported it needs to respond with WorkspaceFolder[] | null
			/*
			export interface WorkspaceFolder {
					// The associated URI for this workspace folder.
					uri: DocumentUri;

					// The name of the workspace folder. Used to refer to this
					// workspace folder in the user interface.
					name: string
				}
			*/
			p.console_window.log_info('workspace/workspaceFolders')
			send_null_response(json_message.id)
		}
		'workspace/configuration' {
			// TODO: once this is supported it needs to respond with LSPAny[]
			/*
			example request
				{
					"id": "a7ea181c-28ef-4756-a771-3dcfc6c10cbc",
					"jsonrpc": "2.0",
					"method": "workspace/configuration",
					"params": {
						"items": [
							{"section": "d"},
							{"section": "dfmt"},
							{"section": "dscanner"},
							{"section": "editor"},
							{"section": "git"}
						]
					}
				}
			*/
			p.console_window.log_info('workspace/configuration')
			mut cp := ConfigurationParams{}
			cp.from_json(json2.decode[json2.Any](json_message.params) or { json2.Any{} })
			responds := 'null,'.repeat(cp.items.len) // TODO
			mut m := Message{
				msg_type: JsonRpcMessageType.response
				id:       json_message.id
				response: '"result":[${responds[..responds.len - 1]}]'
				// TODO
			}
			io.write_to(m.encode())
		}
		'workspace/applyEdit' {
			mut m := Message{
				msg_type: JsonRpcMessageType.response
				id:       json_message.id
				response: '"result":{"applied": false}'
				// TODO:
			}
			io.write_to(m.encode())
		}
		'workspace/codeLens/refresh' {
			send_null_response(json_message.id)
		}
		'workspace/semanticTokens/refresh' {
			send_null_response(json_message.id)
		}
		else {
			p.console_window.log_warning('An unexpected request has been received, ${report_at}.')
		}
	}
}

fn send_null_response(id int) {
	mut m := Message{
		msg_type: JsonRpcMessageType.response
		id:       id
		response: '"result":null'
	}
	io.write_to(m.encode())
}
