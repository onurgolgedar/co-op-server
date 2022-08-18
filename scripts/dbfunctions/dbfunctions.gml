function _db_init() {
	global.DB_columnNames = ds_map_create()
}

function db_add_row(table, row) {
	ds_map_add(table.rows, row[? 0], row)
}

function db_create_row(primaryValue) {
	var row = ds_map_create()
	row[? 0] = primaryValue

	return row
}

function db_create_table(tableName, tableID) {
	return { rows: ds_map_create(), name: tableName, ID: tableID*100 }
}

function db_delete_row(table, primaryValue) {
	var rowIndex = -1
	ds_map_delete(table.rows, primaryValue)
	return primaryValue
}

function db_get_column_name(table, column) {
	return global.DB_columnNames[? table.ID+column]
}

function db_get_row(table, primaryValue) {
	if (ds_map_size(table.rows) == 0)
		return undefined
	
	var row = undefined
	row = ds_map_find_value(table.rows, primaryValue)
	return row
}

function db_get_value_by_key(table, primaryValue, column) {
	if (ds_map_size(table.rows) == 0)
		return undefined
	
	var row = undefined
	row = ds_map_find_value(table.rows, primaryValue)
	return row != undefined ? row[? column] : undefined
}

function db_find_value(table, valueColumn, filterColumn, filterValue) {
	if (ds_map_size(table.rows) == 0)
		return undefined
	
	var row = undefined
	var ds_keys = ds_map_keys_to_array(table.rows)
	var ds_keys_size = array_length(ds_keys)
	for (var i = 0; i < ds_keys_size; i++) {
		var _row = table.rows[? ds_keys[i]]
	
		if (_row[? filterColumn] == filterValue) {
			row = _row
			break
		}
	}

	return row != undefined ? row[? valueColumn] : undefined
}
	
function db_find_row(table, filterColumn, filterValue) {
	if (ds_map_size(table.rows) == 0)
		return undefined
	
	var row = undefined
	var ds_keys = ds_map_keys_to_array(table.rows)
	var ds_keys_size = array_length(ds_keys)
	for (var i = 0; i < ds_keys_size; i++) {
		var _row = table.rows[? ds_keys[i]]
	
		if (_row[? filterColumn] == filterValue) {
			row = _row
			break
		}
	}

	return row
}
	
function db_get_value_by_index(table, index, column) {
	if (ds_map_size(table.rows) <= index)
		return undefined
	
	var ds_keys = ds_map_keys_to_array(table.rows)
	var row = table.rows[? ds_keys[index]]

	return row != undefined ? row[? column] : undefined
}

function db_get_row_by_index(table, index) {
	if (ds_map_size(table.rows) <= index)
		return undefined
	
	var ds_keys = ds_map_keys_to_array(table.rows)
	var row = table.rows[? ds_keys[index]]
	
	return row
}
	
function db_get_table_size(table) {
	return ds_map_size(table.rows)
}
	
function db_set_column_name(table, column, columnName) {
	ds_map_add(global.DB_columnNames, table.ID+column, columnName)
}

function db_set_row_value(table, primaryValue, column, value) {
	if (ds_map_exists(table.rows, primaryValue))
		ds_map_find_value(table.rows, primaryValue)[? column] = value
}

function db_draw_table(table_x, table_y, table, columnCount) {
	var gHeight = ds_map_size(table.rows)

	draw_set_color(c_ltgray)
	//draw_text(table_x, table_y, table.name)
	table_y += 30

	draw_set_color(c_white)
	for (var i = 0; i < columnCount; i++) {
		draw_text(table_x+i*160, table_y, db_get_column_name(table, i))
		draw_line_width(table_x+i*160, table_y+30, table_x+150+i*160, table_y+30, 3)
	}

	if (ds_map_size(table.rows) > 0) {
		var ds_keys = ds_map_keys_to_array(table.rows)
		var ds_keys_size = array_length(ds_keys)
		for (var j = 0; j < ds_keys_size; j++) {
			for (var i = 0; i < columnCount; i++) {
				var row = table.rows[? ds_keys[j]]
			
				draw_text(table_x+i*160, table_y+40+j*30, row[? i])
				draw_line(table_x+i*160, table_y+40+j*30+30, table_x+150+i*160, table_y+40+j*30+30)
			}
		}
	}
	draw_set_color(c_black)
}
	
function db_convert_row_to_parameters(row) {
	var parameters = ""
	var i = 0
	while (true) {
		var value = row[? i]
		if (value != undefined)
			parameters += string(row[? i])+"|"
		else {
			if (string_length(parameters) != 0)
				parameters = string_delete(parameters, string_length(parameters), 1)
				
			break
		}
		
		i++	
	}
	
	return parameters
}

function db_save_table(table) {
	var copy = ds_map_create()
	ds_map_copy(copy, table.rows)
		
	var ds_keys = ds_map_keys_to_array(table.rows)
	var ds_keys_size = array_length(ds_keys)
	for (var i = 0; i < ds_keys_size; i++)
		copy[? ds_keys[i]] = ds_map_write(copy[? ds_keys[i]])
		
	ini_open(table.name+".dbfile")
		ini_write_string(table.name, "Rows", ds_map_write(copy))
	ini_close()
	
	ds_map_destroy(copy)
}

function db_load_table(tableName, tableID) {
	var loadedTable = db_create_table(tableName, tableID)
	ini_open(tableName+".dbfile")
		ds_map_read(loadedTable.rows, ini_read_string(tableName, "Rows", ""))

		var ds_keys = ds_map_keys_to_array(loadedTable.rows)
		var ds_keys_size = array_length(ds_keys)
		for (var i = 0; i < ds_keys_size; i++) {
			var value = loadedTable.rows[? ds_keys[i]]
			loadedTable.rows[? ds_keys[i]] = ds_map_create()
			ds_map_read(loadedTable.rows[? ds_keys[i]], value)
		}
	ini_close()
	
	return loadedTable
}