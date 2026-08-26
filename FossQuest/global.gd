extends Node

var logs: Array[String]
func logPrint(msg: String) -> void:
	print(msg)
	logs.append(msg)
