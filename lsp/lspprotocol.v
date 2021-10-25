module lsp
import x.json2

enum JsonRpcMessageType {
	response
	notification
	request
}

// used for encoding json messages
struct Message {
	msg_type JsonRpcMessageType
	method string
	id int
	params string
}

fn (m Message) encode() string {
	body := match m.msg_type {
		.request {
			'{"jsonrpc": "2.0", "id": $m.id, "method": $m.method, "params": $m.params}'
		}
		.response {
			'{"jsonrpc": "2.0", "id": $m.id}'
		}
		.notification {
			'{"jsonrpc": "2.0", "method": $m.method, "params": $m.params}'
		}
	}
	return 'Content-Length: ${body.len}\r\n\r\n${body}'
}

pub fn initialize_msg(pid int, file_path string) string {
	uri_path := make_uri(file_path)
	m := Message {
		msg_type: JsonRpcMessageType.request
		id: p.lsp_config.lspservers[p.current_language].get_next_id()
		method: '"initialize"'
		params: '{"processId": $pid, "clientInfo":{"name": "NppLspClient", "version": "0.0.1"}, "rootUri": "file:///$uri_path", "initializationOptions": {}, "capabilities": {"workspace": {"applyEdit": false, "workspaceEdit": {"documentChanges": false}, "didChangeConfiguration": {"dynamicRegistration": false}, "didChangeWatchedFiles": {"dynamicRegistration": false}, "symbol": {"dynamicRegistration": false, "symbolKind": {"valueSet": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26]}}, "executeCommand": {"dynamicRegistration": false}, "configuration": false, "workspaceFolders": false}, "textDocument": {"publishDiagnostics": {"relatedInformation": false}, "synchronization": {"dynamicRegistration": false, "willSave": false, "willSaveWaitUntil": false, "didSave": true}, "completion": {"dynamicRegistration": false, "contextSupport": false, "completionItem": {"snippetSupport": false, "commitCharactersSupport": false, "documentationFormat": ["plaintext"], "deprecatedSupport": false}, "completionItemKind": {"valueSet": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25]}}, "hover": {"dynamicRegistration": false, "contentFormat": ["plaintext"]}, "signatureHelp": {"dynamicRegistration": false, "signatureInformation": {"documentationFormat": ["plaintext"]}}, "definition": {"dynamicRegistration": false}, "references": {"dynamicRegistration": false}, "documentHighlight": {"dynamicRegistration": false}, "documentSymbol": {"dynamicRegistration": false, "symbolKind": {"valueSet": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26]}}, "codeAction": {"dynamicRegistration": false}, "codeLens": {"dynamicRegistration": false}, "formatting": {"dynamicRegistration": false}, "rangeFormatting": {"dynamicRegistration": false}, "onTypeFormatting": {"dynamicRegistration": false}, "rename": {"dynamicRegistration": false}, "documentLink": {"dynamicRegistration": false}, "typeDefinition": {"dynamicRegistration": false}, "implementation": {"dynamicRegistration": false}, "colorProvider": {"dynamicRegistration": false}, "foldingRange": {"dynamicRegistration": false, "rangeLimit": 100, "lineFoldingOnly": true}}}, "trace": "off", "workspaceFolders": null}'
	}
	p.open_response_messages[m.id] = initialize_msg_response
	return m.encode()
}

pub fn initialized_msg() string {
	m := Message {
		msg_type: JsonRpcMessageType.notification
		method: '"initialized"'
		params: '{}'
	}
	return m.encode()
}

pub fn exit_msg() string {
	m := Message {
		msg_type: JsonRpcMessageType.notification
		method: '"exit"'
		params: '{}'
	}
	return m.encode()	
}

pub fn shutdown_msg() string {
	m := Message {
		msg_type: JsonRpcMessageType.request
		id: p.lsp_config.lspservers[p.current_language].get_next_id()
		method: '"shutdown"'
		params: '{}'
	}
	p.lsp_config.lspservers[p.current_language].message_id_counter++
	return m.encode()	
}

pub fn did_open(file_path DocumentUri, file_version u32, language_id string, content string) string {
	uri_path := make_uri(file_path)
	m := Message {
		msg_type: JsonRpcMessageType.notification
		method: '"textDocument/didOpen"'
		params: '{"textDocument":{"uri":"file:///$uri_path", "languageId":"$language_id", "version":$file_version, "text":"$content"}}'
	}
	return m.encode()
}

pub fn did_change_incremental(file_path DocumentUri, 
							  file_version u32, 
							  text_changes string, 
							  start_line u32, 
							  start_char u32, 
							  end_line u32, 
							  end_char u32) string {
	uri_path := make_uri(file_path)
	changes := '{"range":{"start":{"line":$start_line,"character":$start_char},"end":{"line":$end_line,"character":$end_char}},"rangeLength":0,"text":"$text_changes"}'

	m := Message {
		msg_type: JsonRpcMessageType.notification
		method: '"textDocument/didChange"'
		params: '{"textDocument":{"uri":"file:///$uri_path","version":$file_version},"contentChanges":[$changes]}'
	}	
	return m.encode()
}

pub fn did_change_full(file_path DocumentUri, file_version u32, changes string) string {
	uri_path := make_uri(file_path)
	m := Message {
		msg_type: JsonRpcMessageType.notification
		method: '"textDocument/didChange"'
		params: '{"textDocument":{"uri":"file:///$uri_path","version":$file_version},"contentChanges":[$changes]}'
	}	
	return m.encode()
}

pub fn did_save(file_path DocumentUri, file_version u32) string {
	uri_path := make_uri(file_path)
	m := Message {
		msg_type: JsonRpcMessageType.notification
		method: '"textDocument/didSave"'
		params: '{"textDocument":{"uri":"file:///$uri_path","version":$file_version}}'
	}	
	return m.encode()
}

pub fn did_close(file_path DocumentUri) string {
	uri_path := make_uri(file_path)
	m := Message {
		msg_type: JsonRpcMessageType.notification
		method: '"textDocument/didClose"'
		params: '{"textDocument":{"uri":"file:///$uri_path"}}'
	}
	return m.encode()
}

pub fn request_completion(file_path DocumentUri, line u32, char_pos u32, trigger_character string) string {
	uri_path := make_uri(file_path)
	m := Message {
		msg_type: JsonRpcMessageType.request
		id: p.lsp_config.lspservers[p.current_language].get_next_id()
		method: '"textDocument/completion"'
		params: '{"textDocument":{"uri":"file:///$uri_path"}, "position":{"line":$line, "character":$char_pos}, "context":{"triggerKind":1, "triggerCharacter":"$trigger_character"}}'
	}
	p.open_response_messages[m.id] = request_completion_response
	return m.encode()
}

pub fn request_signature_help(file_path DocumentUri, line u32, char_pos u32, trigger_character string) string {
	uri_path := make_uri(file_path)
	m := Message {
		msg_type: JsonRpcMessageType.request
		id: p.lsp_config.lspservers[p.current_language].get_next_id()
		method: '"textDocument/signatureHelp"'
		params: '{"textDocument":{"uri":"file:///$uri_path"}, "position":{"line":$line, "character":$char_pos}, "context":{"isRetrigger":false, "triggerCharacter":"$trigger_character", "triggerKind":1}}'
	}
	p.open_response_messages[m.id] = request_signature_help_repsonse
	return m.encode()
}


// ****************************************************************************
// JSON Structures
// ****************************************************************************

// pub fn (mut xx XXX) from_json(f json2.Any) {
    // obj := f.as_map()
    // for k, v in obj {
        // match k {
            // else {}
        // }
    // }
// }


// used for decoding
struct JsonMessage {
pub mut:
	jsonrpc string	// all
	method string	// request and notification
	id string		// request and response
	params string	// request and notification
	result string	// response
	error string	// response
}

pub fn (mut m JsonMessage) from_json(f json2.Any) {
    obj := f.as_map()
    for k, v in obj {
        match k {
            'jsonrpc' { m.jsonrpc =  v.str() }
            'method' { m.method = v.str() }
			'id' { m.id = v.str() }
			'params' { m.params = v.str() }
			'result' { m.result = v.str() }
			'error' { m.error = v.str() }
            else {}
        }
    }
}

type DocumentUri = string

pub fn make_path(uri string) string {
	return uri.all_after('file:///').replace('/', '\\')
}

pub fn make_uri(path string) string {
	return path.replace_each(['\\', '/', ':', '%3A'])
}

pub struct Position {
pub mut:
	line      int
	character int
}

pub fn (mut p Position) from_json(f json2.Any) {
    obj := f.as_map()
    for k, v in obj {
        match k {
			'line' { p.line = v.int() }
			'character' { p.character = v.int() }
            else {}
        }
    }
}

pub struct Range {
pub mut:
	start Position
	end   Position
}

pub fn (mut r Range) from_json(f json2.Any) {
    obj := f.as_map()
    for k, v in obj {
        match k {
			'start' { r.start = json2.decode<Position>(v.str()) or { Position{} } }
			'end' { r.end = json2.decode<Position>(v.str()) or { Position{} } }
            else {}
        }
    }
}

pub struct Location {
pub mut:
	uri   DocumentUri
	range Range
}

pub fn (mut l Location) from_json(f json2.Any) {
    obj := f.as_map()
    for k, v in obj {
        match k {
			'uri' { l.uri = make_path(v.str()) }
			'range' { l.range = json2.decode<Range>(v.str()) or { Range{} } } 
            else {}
        }
    }
}

pub struct CompletionOptions {
pub mut:
	resolve_provider   bool
	trigger_characters []string
}

pub fn (mut co CompletionOptions) from_json(f json2.Any) {
    obj := f.as_map()
    for k, v in obj {
        match k {
            'resolveProvider' { co.resolve_provider =  v.bool() }
            'triggerCharacters' { co.trigger_characters = v.arr().map(it.str()) }
            else {}
        }
    }
}

pub struct SignatureHelpOptions {
pub mut:
	trigger_characters   []string
	retrigger_characters []string
}

pub fn (mut sho SignatureHelpOptions) from_json(f json2.Any) {
    obj := f.as_map()
    for k, v in obj {
        match k {
            'triggerCharacters' { sho.trigger_characters = v.arr().map(it.str()) }
            'retriggerCharacters' { sho.retrigger_characters =  v.arr().map(it.str()) }
            else {}
        }
    }
}

pub struct DocumentOnTypeFormattingOptions {
pub mut:
	first_trigger_character string
	more_trigger_character  []string
}

pub fn (mut dtfo DocumentOnTypeFormattingOptions) from_json(f json2.Any) {
    obj := f.as_map()
    for k, v in obj {
        match k {
            'firstTriggerCharacter' { dtfo.first_trigger_character =  v.str() }
            'moreTriggerCharacter' { dtfo.more_trigger_character = v.arr().map(it.str()) }
            else {}
        }
    }
}

pub struct CodeLensOptions {
pub mut:
	resolve_provider bool
}

pub fn (mut clo CodeLensOptions) from_json(f json2.Any) {
    obj := f.as_map()
    for k, v in obj {
        match k {
            'resolveProvider' { clo.resolve_provider =  v.bool() }
            else {}
        }
    }
}

pub struct SaveOptions {
pub mut:
	/**
	 * The client is supposed to include the content on save.
	 */
	include_text bool
}

pub fn (mut so SaveOptions) from_json(f json2.Any) {
    obj := f.as_map()
    for k, v in obj {
        match k {
            'includeText' { so.include_text = v.bool() }
            else {}
        }
    }
}

pub struct TextDocumentSyncOptions {
pub mut:
	/**
	 * Open and close notifications are sent to the server. If omitted open
	 * close notification should not be sent.
	 */
	open_close bool
	/**
	 * Change notifications are sent to the server. See
	 * TextDocumentSyncKind.None, TextDocumentSyncKind.Full and
	 * TextDocumentSyncKind.Incremental. If omitted it defaults to
	 * TextDocumentSyncKind.None.
	 */
	change int
	/**
	 * If present will save notifications are sent to the server. If omitted
	 * the notification should not be sent.
	 */
	will_save bool
	/**
	 * If present will save wait until requests are sent to the server. If
	 * omitted the request should not be sent.
	 */
	will_save_wait_until bool
	/**
	 * If present save notifications are sent to the server. If omitted the
	 * notification should not be sent.
	 */
	// save bool | SaveOptions
}

pub fn (mut tdso TextDocumentSyncOptions) from_json(f json2.Any) {
    obj := f.as_map()
    for k, v in obj {
        match k {
            'openClose' { tdso.open_close = v.bool() }
			'change' { tdso.change = v.int() }
			'willSave' { tdso.will_save = v.bool() }
			'willSaveWaitUntil' { tdso.will_save_wait_until = v.bool() }
			// 'save'
            else {}
        }
    }
}

pub struct ServerCapabilities {
pub mut:
	text_document_sync                   int // | TextDocumentSyncOptions
	hover_provider                       bool
	completion_provider                  CompletionOptions
	signature_help_provider              SignatureHelpOptions
	definition_provider                  bool
	type_definition_provider             bool
	implementation_provider              bool
	references_provider                  bool
	document_highlight_provider          bool
	document_symbol_provider             bool
	workspace_symbol_provider            bool
	code_action_provider                 bool
	code_lens_provider                   CodeLensOptions
	document_formatting_provider         bool
	document_on_type_formatting_provider DocumentOnTypeFormattingOptions
	rename_provider                      bool
	document_link_provider               bool
	color_provider                       bool
	declaration_provider                 bool
	execute_command_provder              string
	folding_range_provider               bool
	experimental                         map[string]bool
}

pub fn (mut sc ServerCapabilities) from_json(f json2.Any) {
	obj_map := f.as_map()
    for k, v in obj_map {
        match k {
			'textDocumentSync' { 
				sync_opt := json2.decode<TextDocumentSyncOptions>(v.str()) or { TextDocumentSyncOptions{} }
				sync_int := v.int()
				match true {
					sync_opt.change == 0 && sync_int == 0 { sc.text_document_sync = 0 }
					sync_int > sync_opt.change { sc.text_document_sync = sync_int }
					else { sc.text_document_sync = sync_opt.change }
				}
			}
			'hoverProvider' { sc.hover_provider = v.bool() }
			'completionProvider' { 
				sc.completion_provider = json2.decode<CompletionOptions>(v.str()) or { CompletionOptions{} }
			}
			'signatureHelpProvider' { 
				sc.signature_help_provider = json2.decode<SignatureHelpOptions>(v.str()) or { SignatureHelpOptions{} }
			}
			'definitionProvider' { sc.definition_provider = v.bool() }
			'typeDefinitionProvider' { sc.type_definition_provider = v.bool() }
			'implementationProvider' { sc.implementation_provider = v.bool() }
			'referencesProvider' { sc.references_provider = v.bool() }
			'documentHighlightProvider' { sc.document_highlight_provider = v.bool() }
			'documentSymbolProvider' { sc.document_symbol_provider = v.bool() }
			'workspaceSymbolProvider' { sc.workspace_symbol_provider = v.bool() }
			'codeActionProvider' { sc.code_action_provider = v.bool() }
			'codeLensProvider' { 
				sc.code_lens_provider = json2.decode<CodeLensOptions>(v.str()) or { CodeLensOptions{} }
			}
			'documentFormattingProvider' { sc.document_formatting_provider = v.bool() }
			'documentOnTypeFormattingProvider' {
				sc.document_on_type_formatting_provider = json2.decode<DocumentOnTypeFormattingOptions>(v.str()) or { DocumentOnTypeFormattingOptions{} }
			}
			'renameProvider' { sc.rename_provider = v.bool() }
			'documentLinkProvider' { sc.document_link_provider = v.bool() }
			'colorProvider' { sc.color_provider = v.bool() }
			'declarationProvider' { sc.declaration_provider = v.bool() }
			'executeCommandProvider' { sc.execute_command_provder = v.str() }
			'foldingRangeProvider' { sc.folding_range_provider = v.bool() }
			// 'experimental' { sc.experimental = v.str() }
			else {}
        }
    }
}

pub struct Diagnostic {
pub mut:
	range               Range
	severity            int		// DiagnosticSeverity
	code                string
	code_description 	string	// CodeDescription
	source              string
	message             string
	tags				string	// []DiagnosticTag
	related_information string	// []DiagnosticRelatedInformation
	data				string
}

pub fn (mut d Diagnostic) from_json(f json2.Any) {
	obj_map := f.as_map()
    for k, v in obj_map {
        match k {
			'range' { d.range = json2.decode<Range>(v.str()) or { Range{} } }
			'severity' { d.severity = v.int() }
			'code' { d.code = v.str() }
			'code_description' { d.code_description = v.str() }
			'source' { d.source = v.str() }
			'message' { d.message = v.str() }
			'tags' { d.tags = v.str() }
			'related_information' { d.related_information = v.str() }
			'data' { d.data = v.str() }
			else {}
		}
	}
}

pub struct DiagnosticRelatedInformation {
pub mut:
	location Location
	message  string
}

pub fn (mut dri DiagnosticRelatedInformation) from_json(f json2.Any) {
	obj_map := f.as_map()
    for k, v in obj_map {
        match k {
			'location' { dri.location = json2.decode<Location>(v.str()) or { Location{} } }
			'message' { dri.message = v.str() }
			else {}
        }
	}
}

pub struct PublishDiagnosticsParams {
pub mut :
	uri         DocumentUri
	version		u32
	diagnostics []Diagnostic
}

pub fn (mut pd PublishDiagnosticsParams) from_json(f json2.Any) {
	obj_map := f.as_map()
    for k, v in obj_map {
        match k {
			'uri' { pd.uri = make_path(v.str()) }
			'version' { pd.version = u32(v.int()) }
			'diagnostics' { 
				for diag in v.arr() {
					pd.diagnostics << json2.decode<Diagnostic>(diag.str()) or { Diagnostic{} }
				}
			}
			else {}
        }
	}
}

pub struct CompletionList {
pub mut:
	is_incomplete bool
	items         []CompletionItem
}

pub fn (mut cl CompletionList) from_json(f json2.Any) {
    obj := f.as_map()
    for k, v in obj {
        match k {
			'is_incomplete' { cl.is_incomplete = v.bool() }
			'items' { 
				for item in v.arr() {
					cl.items << json2.decode<CompletionItem>(item.str()) or { CompletionItem{} }
				}
			}
            else {}
        }
    }
}

pub struct CompletionItem {
pub mut:
	label					string
	label_details			string
	kind					string
	tags					string
	detail 					string
	documentation			string
	deprecated_				bool
	preselect				bool
	sort_text				string
	filter_text				string
	insert_text				string
	insert_text_format		string
	insert_text_mode		string
	text_edit				string
	additional_text_edits	string
	commit_characters		string
	command					string
	data					string
}

pub fn (mut ci CompletionItem) from_json(f json2.Any) {
    obj := f.as_map()
    for k, v in obj {
        match k {
			'label' { ci.label = v.str() }
			'labelDetails' { ci.label_details = v.str() }
			'kind' { ci.kind = v.str() }
			'tags' { ci.tags = v.str() }
			'detail' { ci.detail = v.str() }
			'documentation' { ci.documentation = v.str() }
			'deprecated' { ci.deprecated_ = v.bool() }
			'preselect' { ci.preselect = v.bool() }
			'sortText' { ci.sort_text = v.str() }
			'filterText' { ci.filter_text = v.str() }
			'insertText' { ci.insert_text = v.str() }
			'insertTextFormat' { ci.insert_text_format = v.str() }
			'insertTextMode' { ci.insert_text_mode = v.str() }
			'textEdit' { ci.text_edit = v.str() }
			'additionalTextEdits' { ci.additional_text_edits = v.str() }
			'commitCharacters' { ci.commit_characters = v.str() }
			'command' { ci.command = v.str() }
			'data' { ci.data = v.str() }
            else {}
        }
    }
}

pub struct CompletionItemArray {
pub mut:
	items []CompletionItem
}

pub fn (mut cla CompletionItemArray) from_json(f json2.Any) {
	for item in f.arr() {
		cla.items << json2.decode<CompletionItem>(item.str()) or { CompletionItem{} }
	}
}

pub struct SignatureHelp {
pub mut:
	signatures []SignatureInformation
	active_signature u32
	active_parameter u32
}

pub fn (mut sh SignatureHelp) from_json(f json2.Any) {
    obj := f.as_map()
    for k, v in obj {
        match k {
			'signatures' { 
				for item in v.arr() {
					sh.signatures << json2.decode<SignatureInformation>(item.str()) or { SignatureInformation{} }
				}
			}
			'activeSignature' { sh.active_signature = u32(v.int()) }
			'activeParameter' { sh.active_parameter = u32(v.int()) }
            else {}
        }
    }
}

pub struct SignatureInformation {
pub mut:
	label string
	documentation string
	parameters []ParameterInformation
	active_parameter u32
}

pub fn (mut si SignatureInformation) from_json(f json2.Any) {
    obj := f.as_map()
    for k, v in obj {
        match k {
			'label' { si.label = v.str() }
			'documentation' { si.documentation = v.str() }
			'parameters' { 
				for item in v.arr() {
					si.parameters << json2.decode<ParameterInformation>(item.str()) or { ParameterInformation{} }
				}			
			}
			'activeParameter' { si.active_parameter = u32(v.int()) }
            else {}
        }
    }
}

pub struct ParameterInformation {
pub mut:
	label string
	documentation string
}

pub fn (mut pi ParameterInformation) from_json(f json2.Any) {
    obj := f.as_map()
    for k, v in obj {
        match k {
			'label' { pi.label = v.str() }
			'documentation' { pi.documentation = v.str() }
            else {}
        }
    }
}
