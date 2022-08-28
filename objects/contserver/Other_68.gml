var port = async_load[? "port"]
if (port == PORT_TCP_COOP or port == PORT_UDP_COOP or port == PORT_TCP or port == PORT_UDP) {
	var load_buffer = async_load[? "buffer"]
	var load_id = async_load[? "id"]
	var load_type = async_load[? "type"]
	var load_socketID = async_load[? "socket"]
	var load_ip = async_load[? "ip"]
	
	switch(load_type)
	{		
		case network_type_data:
			var data
			buffer_seek(load_buffer, buffer_seek_start, 0)
			while (buffer_tell(load_buffer) < buffer_get_size(load_buffer)) {
				data = net_buffer_read(load_buffer)
				if (data != undefined)
				_net_receive_packet(data[0], data[1], load_id, data[2], net_buffer_get_type_reverse(data[4]), async_load, data[3])
			}
			buffer_delete(load_buffer)	
			break
		
		case network_type_connect:
			server_add_client(load_socketID)
			server_edit_client(load_socketID, CLIENTS_IP, load_ip)
			_net_event_connect(load_buffer, load_id, load_socketID, load_ip)
			
			net_server_send(load_socketID, CODE_CONNECT_COOP, load_socketID, BUFFER_TYPE_INT16)
			break
		
		case network_type_disconnect:
			_net_event_disconnect(load_buffer, load_id, load_socketID, load_ip)
			
			var socketID_host = db_get_value_by_key(global.DB_TABLE_clients, load_socketID, CLIENTS_HOST)
			if (socketID_host != undefined) {
				var socketIDClient_inHost = db_get_value_by_key(global.DB_TABLE_clients, load_socketID, CLIENTS_SOCKETID_IN_HOST)
				net_server_send(socketID_host, _CODE_DISCONNECT, load_socketID, BUFFER_TYPE_INT16, false, BUFFER_INFO_DEFAULT, socketIDClient_inHost)
			}

			server_remove_client(load_socketID)
			
			net_server_send(load_socketID, CODE_DISCONNECT, load_socketID, BUFFER_TYPE_INT16)
			break
		
		case network_type_non_blocking_connect:
			_net_event_non_blocking_connect(load_buffer, load_id, load_socketID, load_ip)
			break
	}
}