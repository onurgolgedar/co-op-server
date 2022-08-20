function _net_receive_packet(code, pureData, socketID_sender, bufferInfo = BUFFER_INFO_DEFAULT, bufferType, asyncMap, coopInfo = BUFFER_INFO_DEFAULT) {
	var isSenderHost, sendersHost, sendersSocketID_inHost
	var row_sender = db_get_row(global.DB_TABLE_clients, socketID_sender)
	if (row_sender[? CLIENTS_IS_HOST] != undefined) {
		isSenderHost = row_sender[? CLIENTS_IS_HOST]
		sendersHost = row_sender[? CLIENTS_HOST]
		sendersSocketID_inHost = row_sender[? CLIENTS_SOCKETID_IN_HOST]
	}
	else {
		isSenderHost = undefined
		sendersHost = undefined
		sendersSocketID_inHost = undefined
	}
	
	var isUDP = false
	var ip = asyncMap[? "ip"]
	
	var data = pureData
	var dataWillBeDeleted = false
	var parameterCount = 1
	if ((code == CODE_AVAILABLE_GAMES_COOP or
		 code == CODE_HOST_COOP or 
		 code == CODE_CONNECT or
		 code == CODE_REQUEST_JOIN_COOP or
		 code == _CODE_SIGNUP) and is_string(pureData)) {
		if (string_char_at(pureData, 0) == "{" or string_char_at(pureData, 0) == "[") {
			dataWillBeDeleted = true
			data = json_parse(data)
		}
	}

	//try {
		switch(code) {
			case CODE_REQUEST_JOIN_COOP:
				var row_host = undefined

				var ds_keys = ds_map_keys_to_array(global.DB_TABLE_clients.rows)
				var ds_size = array_length(ds_keys)
				for (var i = 0; i < ds_size; i++) {
					var _row = global.DB_TABLE_clients.rows[? ds_keys[i]]
	
					if (_row[? CLIENTS_IS_HOST] == true and _row[? CLIENTS_COOPID] == data) {
						row_host = _row
						break
					}
				}
				
				if (row_host != undefined) {
					db_set_row_value(global.DB_TABLE_clients, socketID_sender, CLIENTS_IS_HOST, false)
					db_set_row_value(global.DB_TABLE_clients, socketID_sender, CLIENTS_HOST, _row[? CLIENTS_SOCKETID])
					
					net_server_send(row_host[? CLIENTS_SOCKETID], CODE_JOIN_COOP, json_stringify({ coopID: data, hostsSocketID_inCoop: row_host[? CLIENTS_SOCKETID], participantSocketID_inCoop: socketID_sender }), BUFFER_TYPE_STRING)
				}
				break
			/*-----------------------------------------------------------------------------------------*/
			/*-----------------------------------------------------------------------------------------*/
			case CODE_AVAILABLE_GAMES_COOP:
				var availableGames = ds_list_create()
				
				var ds_keys = ds_map_keys_to_array(global.DB_TABLE_clients.rows)
				var ds_size = array_length(ds_keys)
				for (var i = 0; i < ds_size; i++) {
					var _row = global.DB_TABLE_clients.rows[? ds_keys[i]]
					
					if (_row[? CLIENTS_IS_HOST] == true and _row[? CLIENTS_COOPID] != undefined and _row[? CLIENTS_COOPID] != "" and _row[? CLIENTS_COOPPASSWORD] == "")
						ds_list_add(availableGames, _row[? CLIENTS_COOPID])
				}
	
				net_server_send(socketID_sender, CODE_AVAILABLE_GAMES_COOP, ds_list_write(availableGames), BUFFER_TYPE_STRING)
				ds_list_destroy(availableGames)
				break
			/*-----------------------------------------------------------------------------------------*/
			/*-----------------------------------------------------------------------------------------*/
			case CODE_HOST_COOP:
				var coopID = socketID_sender*10000+0
				row_sender[? CLIENTS_IS_HOST] = true
				row_sender[? CLIENTS_COOPID] = coopID
				row_sender[? CLIENTS_COOPPASSWORD] = ""
				
				net_server_send(socketID_sender, CODE_HOST_COOP, json_stringify({ coopID: coopID, coopPassword: ""} ), BUFFER_TYPE_STRING)
				break
			/*-----------------------------------------------------------------------------------------*/
			/*								    ANALYZE AND REDIRECT        						   */
			/*-----------------------------------------------------------------------------------------*/
			case _CODE_SIGNUP:
				var row_host = undefined

				var ds_keys = ds_map_keys_to_array(global.DB_TABLE_clients.rows)
				var ds_size = array_length(ds_keys)
				for (var i = 0; i < ds_size; i++) {
					var _row = global.DB_TABLE_clients.rows[? ds_keys[i]]
	
					if (_row[? CLIENTS_IS_HOST] == true and _row[? CLIENTS_COOPID] == data.coopID) {
						row_host = _row
						break
					}
				}
				
				// This redirection is tricky because a bypass needed over CODE_SIGNUP_COOP. The code is redirected as its co-op version.
				net_server_send(row_host[? CLIENTS_SOCKETID], CODE_SIGNUP_COOP, json_stringify(data), bufferType, false, BUFFER_INFO_DEFAULT, socketID_sender)
				break
			/*-----------------------------------------------------------------------------------------*/
			/*-----------------------------------------------------------------------------------------*/
			case CODE_CONNECT:
				db_set_row_value(global.DB_TABLE_clients, coopInfo, CLIENTS_SOCKETID_IN_HOST, data)
				net_server_send(coopInfo, code, data, bufferType, false, bufferInfo, coopInfo)
				break
			/*-----------------------------------------------------------------------------------------*/
			/*-----------------------------------------------------------------------------------------*/
			default:
				if (isSenderHost) {
					if (coopInfo != undefined)
						net_server_send(coopInfo, code, data, bufferType, false, bufferInfo, coopInfo)
				}
				else
					net_server_send(sendersHost, code, data, bufferType, isUDP ? ip_sender : false, bufferInfo, sendersSocketID_inHost)
				break
		}
		
		if (dataWillBeDeleted)
			delete data
	/*}
	catch (error) {
		show_debug_message(error)
	}*/
}