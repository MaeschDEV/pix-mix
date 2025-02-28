extends VBoxContainer

@onready var http_request = $"../../BlogsHTTP"
var news_entry_scene = preload("res://scenes/news_entry.tscn")

const FIREBASE_URL = "https://firestore.googleapis.com/v1/projects/pix-mix-d245f/databases/(default)/documents/news"

func _ready() -> void:
	http_request.request(FIREBASE_URL)

func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	print("Request Send!")
	if response_code == 200:
		print("Response code IS 200!")
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json.has("documents"):
			for doc in json["documents"]:
				var fields = doc["fields"]
				
				var title = fields["title"]["stringValue"]
				var author = fields["author"]["stringValue"]
				
				var timestamp_string = fields["date"]["timestampValue"]
				var date_time_parts = timestamp_string.split("T")
				var date_parts = date_time_parts[0].split("-")
				var time_parts = date_time_parts[1].trim_suffix("Z").split(":")
				var formatted_date_time = "%02d.%02d.%04d %02d:%02d:%02d UTC" % [
					int(date_parts[2]), int(date_parts[1]), int(date_parts[0]),
					int(time_parts[0]), int(time_parts[1]), int(time_parts[2])
				]
				
				var content = fields["content"]["stringValue"]
				
				var news_entry = news_entry_scene.instantiate()
				
				news_entry.get_node("HBoxContainer/Header").text = title
				news_entry.get_node("HBoxContainer/Author").text = author
				news_entry.get_node("HBoxContainer/Date").text = formatted_date_time
				news_entry.get_node("RichTextLabel").text = content
				
				self.add_child(news_entry)
	else:
		print("Response code IS NOT 200! Code: ", response_code)
