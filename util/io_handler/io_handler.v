module io_handler

import io
import net
import notepadpp
import util.winapi { read_file, send_message, write_file }

pub const bufsize = 4096
pub const new_message = 1
pub const pipe_closed = 2
pub const new_err_message = 3
pub const new_message_arrived = notepadpp.CommunicationInfo{
	internal_msg:    new_message
	src_module_name: unsafe { nil }
	info:            unsafe { nil }
}
pub const new_err_message_arrived = notepadpp.CommunicationInfo{
	internal_msg:    new_err_message
	src_module_name: unsafe { nil }
	info:            unsafe { nil }
}
pub const pipe_closed_event = notepadpp.CommunicationInfo{
	internal_msg:    pipe_closed
	src_module_name: unsafe { nil }
	info:            unsafe { nil }
}

// read_from stdout runs on a different thread, using p.console_window.log is not safe !!
pub fn read_from_stdout(pipe voidptr, msg_queue chan string) {
	mut dw_read := u32(0)
	mut buffer := [bufsize]i8{}
	mut success := false
	for {
		success = read_file(pipe, &buffer[0], bufsize, &dw_read, unsafe { nil })
		if !success || dw_read == 0 {
			break
		}
		content := unsafe { tos(&u8(&buffer[0]), int(dw_read)) }

		_ := msg_queue.try_push(content)
		send_message(p.npp_data.npp_handle, notepadpp.nppm_msgtoplugin, usize('${p.name}.dll'.to_wide()),
			isize(&new_message_arrived))
	}
	send_message(p.npp_data.npp_handle, notepadpp.nppm_msgtoplugin, usize('${p.name}.dll'.to_wide()),
		isize(&pipe_closed_event))
}

pub fn read_from_stderr(pipe voidptr, msg_queue chan string) {
	mut dw_read := u32(0)
	mut buffer := [bufsize]i8{}
	mut success := false
	for {
		success = read_file(pipe, &buffer[0], bufsize, &dw_read, unsafe { nil })
		if !success || dw_read == 0 {
			break
		}
		content := unsafe { tos(&u8(&buffer[0]), int(dw_read)) }

		if p.lsp_config.enable_logging {
			_ := msg_queue.try_push(content)
			send_message(p.npp_data.npp_handle, notepadpp.nppm_msgtoplugin, usize('${p.name}.dll'.to_wide()),
				isize(&new_err_message_arrived))
		}
	}
	send_message(p.npp_data.npp_handle, notepadpp.nppm_msgtoplugin, usize('${p.name}.dll'.to_wide()),
		isize(&pipe_closed_event))
}

// write_to stdin - main thread
fn write_to_stdin(message string) bool {
	p.console_window.log_outgoing('write_to_stdin: ${message}')
	mut dw_written := u32(0)
	mut success := false
	success = write_file(p.proc_manager.running_processes[p.current_language].stdin, message.str,
		u32(message.len), &dw_written, unsafe { nil })

	if !success {
		p.console_window.log_error('writing to pipe failed\n ${message}')
		return false
	} else if dw_written != message.len {
		p.console_window.log_error('writing to pipe incomplete!!: written=${dw_written} expected=${message.len}\n ${message}')
		return false
	}
	return true
}

fn write_to_socket(message string) bool {
	p.console_window.log_outgoing('write_to_socket: ${message}')
	mut conn := p.proc_manager.running_processes[p.current_language].socket
	written := conn.write_string(message) or { 0 }
	if written == 0 {
		p.console_window.log_error('writing to socket failed\n ${message}')
		return false
	} else if written != message.len {
		p.console_window.log_error('writing to socket incomplete!!: written=${written} expected=${message.len}\n ${message}')
		return false
	}
	return true
}

pub fn write_to(message string) bool {
	if p.proc_manager.running_processes[p.current_language].stdin == unsafe { nil } {
		p.console_window.log_error('ERROR: attempt to write to non-existent pipe\n: ${message}')
		p.console_window.log_error('ERROR: removing ${p.current_language} from list of running servers')
		p.check_ls(true)
		return false
	}
	if p.lsp_config.lspservers[p.current_language].mode == 'io' {
		return write_to_stdin(message)
	} else {
		return write_to_socket(message)
	}
}

pub fn read_from_socket(socket net.TcpConn, msg_queue chan string) ! {
	// mut conn := &net.TcpConn(socket)
	mut conn := socket
	conn.set_blocking(true)!
	mut r := io.new_buffered_reader(reader: conn)
	for {
		mut buffer := []u8{len: 100_000}
		read := r.read(mut buffer) or { 0 }
		if read > 0 {
			content := unsafe { tos_clone(&u8(buffer.data)) }
			if content.len > 0 {
				_ := msg_queue.try_push(content)
				send_message(p.npp_data.npp_handle, notepadpp.nppm_msgtoplugin, usize('${p.name}.dll'.to_wide()),
					isize(&new_message_arrived))
			}
		} else {
			break
		}
	}
	send_message(p.npp_data.npp_handle, notepadpp.nppm_msgtoplugin, usize('${p.name}.dll'.to_wide()),
		isize(&pipe_closed_event))
}
