module lsp

import x.json2

pub struct ServerCapabilities {
pub mut:
	text_document_sync            int
	send_open_close_notif         bool = true
	send_save_notif               bool = true
	include_text_in_save_notif    bool
	supports_will_save            bool
	supports_will_save_wait_until bool

	completion_provider                          CompletionOptions
	signature_help_provider                      SignatureHelpOptions
	hover_provider                               bool
	hover_work_done_provider                     bool
	declaration_provider                         bool
	declaration_work_done_provider               bool
	definition_provider                          bool
	definition_work_done_provider                bool
	type_definition_provider                     bool
	type_definition_work_done_provider           bool
	implementation_provider                      bool
	implementation_work_done_provider            bool
	references_provider                          bool
	references_work_done_provider                bool
	document_highlight_provider                  bool
	document_highlight_work_done_provider        bool
	document_symbol_provider                     bool
	document_symbol_work_done_provider           bool
	code_action_provider                         bool
	code_action_resolve_provider                 bool
	code_lens_provider                           bool
	document_link_provider                       bool
	color_provider                               bool
	color_work_done_provider                     bool
	document_formatting_provider                 bool
	document_formatting_work_done_provider       bool
	document_range_formatting_provider           bool
	document_range_formatting_work_done_provider bool
	document_on_type_formatting_provider         bool
	rename_provider                              bool
	rename_work_done_provider                    bool
	folding_range_provider                       bool
	folding_range_work_done_provider             bool
	execute_command_provider                     bool
	execute_command_work_done_provider           bool
	execute_commands                             []string
	selection_range_provider                     bool
	selection_range_work_done_provider           bool
	linked_editing_range_provider                bool
	linked_editing_range_work_done_provider      bool
	call_hierarchy_provider                      bool
	call_hierarchy_prepare_call                  bool
	call_hierarchy_work_done_provider            bool
	semantic_tokens_provider                     bool
	semantic_tokens_work_done_provider           bool
	moniker_provider                             bool
	moniker_work_done_provider                   bool
	workspace_symbol_provider                    bool
	workspace_capabilities                       WorkspaceCapabilities
	supports_workspace_capabilities              bool

	experimental map[string]bool
}

pub fn (mut sc ServerCapabilities) from_json(f json2.Any) {
	obj_map := f.as_map()
	for k, v in obj_map {
		match k {
			'textDocumentSync' {
				if v.str().starts_with('{') {
					mut sync_opt := TextDocumentSyncOptions{}
					sync_opt.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
					sc.text_document_sync = sync_opt.change
					sc.send_open_close_notif = sync_opt.open_close
					sc.send_save_notif = sync_opt.save_options
					sc.include_text_in_save_notif = sync_opt.include_text
					sc.supports_will_save = sync_opt.will_save
					sc.supports_will_save_wait_until = sync_opt.will_save_wait_until
				} else {
					sc.text_document_sync = v.int()
				}
			}
			'hoverProvider' {
				if v.str().starts_with('{') {
					mut ho := HoverOptions{}
					ho.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
					sc.hover_provider = true
					sc.hover_work_done_provider = ho.work_done_progress
				} else {
					sc.hover_provider = v.bool()
				}
			}
			'completionProvider' {
				sc.completion_provider = CompletionOptions{}
				sc.completion_provider.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
			}
			'signatureHelpProvider' {
				sc.signature_help_provider = SignatureHelpOptions{}
				sc.signature_help_provider.from_json(json2.decode[json2.Any](v.str()) or {
					json2.Any{}
				})
			}
			'definitionProvider' {
				if v.str().starts_with('{') {
					mut do := DefinitionOptions{}
					do.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
					sc.definition_provider = true
					sc.definition_work_done_provider = do.work_done_progress
				} else {
					sc.definition_provider = v.bool()
				}
			}
			'typeDefinitionProvider' {
				if v.str().starts_with('{') {
					mut tdo := TypeDefinitionOptions{}
					tdo.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
					sc.type_definition_provider = true
					sc.type_definition_work_done_provider = tdo.work_done_progress
				} else {
					sc.type_definition_provider = v.bool()
				}
			}
			'implementationProvider' {
				if v.str().starts_with('{') {
					mut io := ImplementationOptions{}
					io.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
					sc.implementation_provider = true
					sc.implementation_work_done_provider = io.work_done_progress
				} else {
					sc.implementation_provider = v.bool()
				}
			} // | ImplementationOptions | ImplementationRegistrationOptions
			'referencesProvider' {
				if v.str().starts_with('{') {
					mut ro := ReferenceOptions{}
					ro.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
					sc.references_provider = true
					sc.references_work_done_provider = ro.work_done_progress
				} else {
					sc.references_provider = v.bool()
				}
			} // | ReferenceOptions
			'documentHighlightProvider' {
				if v.str().starts_with('{') {
					mut dho := DocumentHighlightOptions{}
					dho.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
					sc.document_highlight_provider = true
					sc.document_highlight_work_done_provider = dho.work_done_progress
				} else {
					sc.document_highlight_provider = v.bool()
				}
			}
			'documentSymbolProvider' {
				if v.str().starts_with('{') {
					mut dso := DocumentSymbolOptions{}
					dso.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
					sc.document_symbol_provider = true
					sc.document_symbol_work_done_provider = dso.work_done_progress
				} else {
					sc.document_symbol_provider = v.bool()
				}
			}
			'workspaceSymbolProvider' {
				sc.workspace_symbol_provider = v.bool()
			} // | WorkspaceSymbolOptions
			'codeActionProvider' {
				if v.str().starts_with('{') {
					mut cao := CodeActionOptions{}
					cao.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
					sc.code_action_provider = cao.code_action_kinds.len > 0
					sc.code_action_resolve_provider = cao.resolve_provider
				} else {
					sc.code_action_provider = v.bool()
				}
			} // |
			'codeLensProvider' {
				mut clo := CodeLensOptions{}
				clo.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
				sc.code_lens_provider = clo.resolve_provider
			}
			'documentFormattingProvider' {
				if v.str().starts_with('{') {
					mut dfo := DocumentFormattingOptions{}
					dfo.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
					sc.document_formatting_provider = true
					sc.document_formatting_work_done_provider = dfo.work_done_progress
				} else {
					sc.document_formatting_provider = v.bool()
				}
			}
			'documentOnTypeFormattingProvider' {
				mut dotfo := DocumentOnTypeFormattingOptions{}
				dotfo.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
				sc.document_on_type_formatting_provider = dotfo.first_trigger_character.len > 0
			}
			'renameProvider' {
				if v.str().starts_with('{') {
					mut ro := RenameOptions{}
					ro.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
					sc.rename_provider = true
					sc.rename_work_done_provider = ro.work_done_progress
				} else {
					sc.rename_provider = v.bool()
				}
			}
			'documentLinkProvider' {
				mut dlo := DocumentLinkOptions{}
				dlo.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
				sc.document_link_provider = dlo.resolve_provider
			}
			'colorProvider' {
				if v.str().starts_with('{') {
					mut dco := DocumentColorOptions{}
					dco.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
					sc.color_provider = true
					sc.color_work_done_provider = dco.work_done_progress
				} else {
					sc.color_provider = v.bool()
				}
			}
			'declarationProvider' {
				if v.str().starts_with('{') {
					mut do := DeclarationOptions{}
					do.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
					sc.declaration_provider = true
					sc.declaration_work_done_provider = do.work_done_progress
				} else {
					sc.declaration_provider = v.bool()
				}
			}
			'executeCommandProvider' {
				mut eco := ExecuteCommandOptions{}
				eco.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
				sc.execute_command_provider = true
				sc.execute_command_work_done_provider = eco.work_done_progress
				sc.execute_commands = eco.commands
			}
			'foldingRangeProvider' {
				if v.str().starts_with('{') {
					mut fro := FoldingRangeOptions{}
					fro.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
					sc.folding_range_provider = true
					sc.folding_range_work_done_provider = fro.work_done_progress
				} else {
					sc.folding_range_provider = v.bool()
				}
			}
			'semanticTokensProvider' {
				mut sto := SemanticTokensOptions{}
				sto.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
				sc.semantic_tokens_provider = true
				sc.semantic_tokens_work_done_provider = sto.work_done_progress
			}
			'documentRangeFormattingProvider' {
				if v.str().starts_with('{') {
					mut drfo := DocumentRangeFormattingOptions{}
					drfo.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
					sc.document_range_formatting_provider = true
					sc.document_range_formatting_work_done_provider = drfo.work_done_progress
				} else {
					sc.document_range_formatting_provider = v.bool()
				}
			}
			'selectionRangeProvider' {
				if v.str().starts_with('{') {
					mut sro := SelectionRangeOptions{}
					sro.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
					sc.selection_range_provider = true
					sc.selection_range_work_done_provider = sro.work_done_progress
				} else {
					sc.selection_range_provider = v.bool()
				}
			}
			'linkedEditingRangeProvider' {
				if v.str().starts_with('{') {
					mut lero := LinkedEditingRangeOptions{}
					lero.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
					sc.linked_editing_range_provider = true
					sc.linked_editing_range_work_done_provider = lero.work_done_progress
				} else {
					sc.linked_editing_range_provider = v.bool()
				}
			}
			'callHierarchyProvider' {
				if v.str().starts_with('{') {
					mut cho := CallHierarchyOptions{}
					cho.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
					sc.call_hierarchy_provider = true
					sc.call_hierarchy_work_done_provider = cho.work_done_progress
				} else {
					sc.call_hierarchy_provider = v.bool()
				}
			}
			'monikerProvider' {
				if v.str().starts_with('{') {
					mut mo := MonikerOptions{}
					mo.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
					sc.moniker_provider = v.bool()
					sc.moniker_work_done_provider = mo.work_done_progress
				} else {
					sc.moniker_provider = v.bool()
				}
			}
			'workspace' {
				sc.supports_workspace_capabilities = true
				sc.workspace_capabilities = WorkspaceCapabilities{}
				sc.workspace_capabilities.from_json(json2.decode[json2.Any](v.str()) or {
					json2.Any{}
				})
			}
			// 'experimental' { sc.experimental = v.str() }
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
			'resolveProvider' { co.resolve_provider = v.bool() }
			'triggerCharacters' { co.trigger_characters = v.arr().map(it.str()) }
			else {}
		}
	}
}

pub struct TextDocumentSyncOptions {
pub mut:
	// Open and close notifications are sent to the server.
	// If omitted open close notification should not be sent.
	open_close bool
	// Change notifications are sent to the server.
	// TextDocumentSyncKind.None, TextDocumentSyncKind.Full and
	// TextDocumentSyncKind.Incremental.
	// If omitted it defaults to TextDocumentSyncKind.None.
	change int
	// If present will save notifications are sent to the server.
	// If omitted the notification should not be sent.
	will_save bool
	// If present will save wait until requests are sent to the server.
	// If omitted the request should not be sent.
	will_save_wait_until bool
	// If present save notifications are sent to the server.
	// If omitted the notification should not be sent.
	save_options bool
	include_text bool
}

pub fn (mut tdso TextDocumentSyncOptions) from_json(f json2.Any) {
	obj := f.as_map()
	for k, v in obj {
		match k {
			'openClose' {
				tdso.open_close = v.bool()
			}
			'change' {
				tdso.change = v.int()
			}
			'willSave' {
				tdso.will_save = v.bool()
			}
			'willSaveWaitUntil' {
				tdso.will_save_wait_until = v.bool()
			}
			'save' {
				if v.str().starts_with('{') {
					tdso.save_options = true
					mut so := SaveOptions{}
					so.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
					tdso.include_text = so.include_text
				} else {
					tdso.save_options = v.bool()
				}
			}
			else {}
		}
	}
}

pub struct SaveOptions {
pub mut:
	// The client is supposed to include the content on save.
	include_text bool
}

pub fn (mut so SaveOptions) from_json(f json2.Any) {
	so.include_text = f.bool()
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
			'retriggerCharacters' { sho.retrigger_characters = v.arr().map(it.str()) }
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
			'resolveProvider' { clo.resolve_provider = v.bool() }
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
			'firstTriggerCharacter' { dtfo.first_trigger_character = v.str() }
			'moreTriggerCharacter' { dtfo.more_trigger_character = v.arr().map(it.str()) }
			else {}
		}
	}
}

pub struct WorkspaceCapabilities {
pub mut:
	workspace_folders WorkspaceFoldersServerCapabilities
	file_operations   FileOperation
}

pub fn (mut wc WorkspaceCapabilities) from_json(f json2.Any) {
	obj := f.as_map()
	for k, v in obj {
		match k {
			'workspaceFolders' {
				wc.workspace_folders = WorkspaceFoldersServerCapabilities{}
				wc.workspace_folders.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
			}
			'fileOperations' {
				wc.file_operations = FileOperation{}
				wc.file_operations.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
			}
			else {}
		}
	}
}

pub struct WorkspaceFoldersServerCapabilities {
pub mut:
	supported bool
	// If a string is provided, the string is treated as an ID
	// under which the notification is registered on the client
	// side. The ID can be used to unregister for these events
	// using the `client/unregisterCapability` request.
	change_notifications string
	// | boolean
}

pub fn (mut wfsc WorkspaceFoldersServerCapabilities) from_json(f json2.Any) {
	obj := f.as_map()
	for k, v in obj {
		match k {
			'supported' { wfsc.supported = v.bool() }
			'changeNotifications' { wfsc.change_notifications = v.str() }
			else {}
		}
	}
}

pub struct FileOperation {
pub mut:
	did_create            FileOperationRegistrationOptions
	did_create_supported  bool
	will_create           FileOperationRegistrationOptions
	will_create_supported bool
	did_rename            FileOperationRegistrationOptions
	did_rename_supported  bool
	will_rename           FileOperationRegistrationOptions
	will_rename_supported bool
	did_delete            FileOperationRegistrationOptions
	did_delete_supported  bool
	will_delete           FileOperationRegistrationOptions
	will_delete_supported bool
}

pub fn (mut fo FileOperation) from_json(f json2.Any) {
	obj := f.as_map()
	for k, v in obj {
		match k {
			'didCreate' {
				fo.did_create_supported = true
				fo.did_create = FileOperationRegistrationOptions{}
				fo.did_create.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
			}
			'willCreate' {
				fo.will_create_supported = true
				fo.will_create = FileOperationRegistrationOptions{}
				fo.will_create.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
			}
			'didRename' {
				fo.did_rename_supported = true
				fo.did_rename = FileOperationRegistrationOptions{}
				fo.did_rename.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
			}
			'willRename' {
				fo.will_rename_supported = true
				fo.will_rename = FileOperationRegistrationOptions{}
				fo.will_rename.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
			}
			'didDelete' {
				fo.did_delete_supported = true
				fo.did_delete = FileOperationRegistrationOptions{}
				fo.did_delete.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
			}
			'willDelete' {
				fo.will_delete_supported = true
				fo.will_delete = FileOperationRegistrationOptions{}
				fo.will_delete.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
			}
			else {}
		}
	}
}

pub struct FileOperationRegistrationOptions {
pub mut:
	filters []FileOperationFilter
}

pub fn (mut foro FileOperationRegistrationOptions) from_json(f json2.Any) {
	items := f.arr()
	for item in items {
		mut fof := FileOperationFilter{}
		fof.from_json(json2.decode[json2.Any](item.str()) or { json2.Any{} })
		foro.filters << fof
	}
}

pub struct FileOperationFilter {
pub mut:
	// A Uri like `file` or `untitled`.
	scheme  string
	pattern FileOperationPattern
}

pub fn (mut fof FileOperationFilter) from_json(f json2.Any) {
	obj := f.as_map()
	for k, v in obj {
		match k {
			'scheme' {
				fof.scheme = v.str()
			}
			'pattern' {
				fof.pattern = FileOperationPattern{}
				fof.pattern.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
			}
			else {}
		}
	}
}

pub struct FileOperationPattern {
pub mut:
	// The glob pattern to match. Glob patterns can have the following syntax:
	// - `*` to match one or more characters in a path segment
	// - `?` to match on one character in a path segment
	// - `**` to match any number of path segments, including none
	// - `{}` to group sub patterns into an OR expression. (e.g. `**​/*.{ts,js}`
	//	 matches all TypeScript and JavaScript files)
	// - `[]` to declare a range of characters to match in a path segment
	//	 (e.g., `example.[0-9]` to match on `example.0`, `example.1`, …)
	// - `[!...]` to negate a range of characters to match in a path segment
	//	 (e.g., `example.[!0-9]` to match on `example.a`, `example.b`, but
	//	 not `example.0`)
	glob    string
	matches string
	// is either 'file' | 'folder', matches both if undefined.
	// Additional options used during matching
	options FileOperationPatternOptions
}

pub fn (mut fop FileOperationPattern) from_json(f json2.Any) {
	obj := f.as_map()
	for k, v in obj {
		match k {
			'glob' {
				fop.glob = v.str()
			}
			'matches' {
				fop.matches = v.str()
			}
			'options' {
				fop.options = FileOperationPatternOptions{}
				fop.options.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
			}
			else {}
		}
	}
}

pub struct FileOperationPatternOptions {
pub mut:
	ignore_case bool
}

pub fn (mut fopo FileOperationPatternOptions) from_json(f json2.Any) {
	fopo.ignore_case = f.bool()
}

pub struct HoverOptions {
pub mut:
	work_done_progress bool
}

pub fn (mut ho HoverOptions) from_json(f json2.Any) {
	ho.work_done_progress = f.bool()
}

pub struct DefinitionOptions {
pub mut:
	work_done_progress bool
}

pub fn (mut do DefinitionOptions) from_json(f json2.Any) {
	do.work_done_progress = f.bool()
}

pub struct DeclarationOptions {
pub mut:
	work_done_progress bool
}

pub fn (mut do DeclarationOptions) from_json(f json2.Any) {
	do.work_done_progress = f.bool()
}

pub struct TypeDefinitionOptions {
pub mut:
	work_done_progress bool
}

pub fn (mut tdo TypeDefinitionOptions) from_json(f json2.Any) {
	tdo.work_done_progress = f.bool()
}

pub struct ImplementationOptions {
pub mut:
	work_done_progress bool
}

pub fn (mut io ImplementationOptions) from_json(f json2.Any) {
	io.work_done_progress = f.bool()
}

pub struct ReferenceOptions {
pub mut:
	work_done_progress bool
}

pub fn (mut ro ReferenceOptions) from_json(f json2.Any) {
	ro.work_done_progress = f.bool()
}

pub struct DocumentHighlightOptions {
pub mut:
	work_done_progress bool
}

pub fn (mut dho DocumentHighlightOptions) from_json(f json2.Any) {
	dho.work_done_progress = f.bool()
}

pub struct DocumentColorOptions {
pub mut:
	work_done_progress bool
}

pub fn (mut dco DocumentColorOptions) from_json(f json2.Any) {
	dco.work_done_progress = f.bool()
}

pub struct DocumentFormattingOptions {
pub mut:
	work_done_progress bool
}

pub fn (mut dfo DocumentFormattingOptions) from_json(f json2.Any) {
	dfo.work_done_progress = f.bool()
}

pub struct DocumentRangeFormattingOptions {
pub mut:
	work_done_progress bool
}

pub fn (mut drfo DocumentRangeFormattingOptions) from_json(f json2.Any) {
	drfo.work_done_progress = f.bool()
}

pub struct FoldingRangeOptions {
pub mut:
	work_done_progress bool
}

pub fn (mut fro FoldingRangeOptions) from_json(f json2.Any) {
	fro.work_done_progress = f.bool()
}

pub struct SelectionRangeOptions {
pub mut:
	work_done_progress bool
}

pub fn (mut sro SelectionRangeOptions) from_json(f json2.Any) {
	sro.work_done_progress = f.bool()
}

pub struct LinkedEditingRangeOptions {
pub mut:
	work_done_progress bool
}

pub fn (mut lero LinkedEditingRangeOptions) from_json(f json2.Any) {
	lero.work_done_progress = f.bool()
}

pub struct CallHierarchyOptions {
pub mut:
	work_done_progress bool
}

pub fn (mut cho CallHierarchyOptions) from_json(f json2.Any) {
	cho.work_done_progress = f.bool()
}

pub struct MonikerOptions {
pub mut:
	work_done_progress bool
}

pub fn (mut mo MonikerOptions) from_json(f json2.Any) {
	mo.work_done_progress = f.bool()
}

pub struct WorkspaceSymbolOptions {
pub mut:
	work_done_progress bool
}

pub fn (mut wso WorkspaceSymbolOptions) from_json(f json2.Any) {
	wso.work_done_progress = f.bool()
}

pub struct DocumentSymbolOptions {
pub mut:
	work_done_progress bool
	label              string
}

pub fn (mut dso DocumentSymbolOptions) from_json(f json2.Any) {
	obj := f.as_map()
	for k, v in obj {
		match k {
			'workDoneProgress' { dso.work_done_progress = v.bool() }
			'label' { dso.label = v.str() }
			else {}
		}
	}
}

pub struct CodeActionOptions {
pub mut:
	work_done_progress bool
	code_action_kinds  []string
	resolve_provider   bool
}

pub fn (mut cao CodeActionOptions) from_json(f json2.Any) {
	obj := f.as_map()
	for k, v in obj {
		match k {
			'workDoneProgress' { cao.work_done_progress = v.bool() }
			'codeActionKinds' { cao.code_action_kinds << v.arr().map(it.str()) }
			'resolveProvider' { cao.resolve_provider = v.bool() }
			else {}
		}
	}
}

pub struct DocumentLinkOptions {
pub mut:
	work_done_progress bool
	resolve_provider   bool
}

pub fn (mut dlo DocumentLinkOptions) from_json(f json2.Any) {
	obj := f.as_map()
	for k, v in obj {
		match k {
			'workDoneProgress' { dlo.work_done_progress = v.bool() }
			'resolveProvider' { dlo.resolve_provider = v.bool() }
			else {}
		}
	}
}

pub struct RenameOptions {
pub mut:
	work_done_progress bool
	prepare_provider   bool
}

pub fn (mut cao RenameOptions) from_json(f json2.Any) {
	obj := f.as_map()
	for k, v in obj {
		match k {
			'workDoneProgress' { cao.work_done_progress = v.bool() }
			'prepareProvider' { cao.prepare_provider = v.bool() }
			else {}
		}
	}
}

pub struct ExecuteCommandOptions {
pub mut:
	work_done_progress bool
	commands           []string
}

pub fn (mut cao ExecuteCommandOptions) from_json(f json2.Any) {
	obj := f.as_map()
	for k, v in obj {
		match k {
			'workDoneProgress' { cao.work_done_progress = v.bool() }
			'commands' { cao.commands = v.arr().map(it.str()) }
			else {}
		}
	}
}

pub struct SemanticTokensOptions {
pub mut:
	work_done_progress bool
	legend             SemanticTokensLegend
	// TODO: ?? unsure what that means ??
	// // Server supports providing semantic tokens for a specific range of a document.
	// range?: bool | {}
	// // Server supports providing semantic tokens for a full document.
	// full?: bool | {
	// // The server supports deltas for full documents.
	// delta?: bool
	// }
}

pub fn (mut sto SemanticTokensOptions) from_json(f json2.Any) {
	obj := f.as_map()
	for k, v in obj {
		match k {
			'workDoneProgress' {
				sto.work_done_progress = v.bool()
			}
			'legend' {
				sto.legend = SemanticTokensLegend{}
				sto.legend.from_json(json2.decode[json2.Any](v.str()) or { json2.Any{} })
			}
			'range' {}
			'full' {}
			else {}
		}
	}
}

pub struct SemanticTokensLegend {
pub mut:
	token_types     []string
	token_modifiers []string
}

pub fn (mut stl SemanticTokensLegend) from_json(f json2.Any) {
	obj := f.as_map()
	for k, v in obj {
		match k {
			'tokenTypes' { stl.token_types = v.arr().map(it.str()) }
			'tokenModifiers' { stl.token_modifiers = v.arr().map(it.str()) }
			else {}
		}
	}
}
