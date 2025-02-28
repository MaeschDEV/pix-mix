extends VBoxContainer

@onready var http_request = $"../../PatreonsHTTP"

const FIREBASE_URL = "https://firestore.googleapis.com/v1/projects/pix-mix-d245f/databases/(default)/documents/patreons"

func _ready() -> void:
	http_request.request(FIREBASE_URL)

func _on_patreons_http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	print("Request Send!")
	if response_code == 200:
		print("Response code IS 200!")
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json.has("documents"):
			for doc in json["documents"]:
				var fields = doc["fields"]
				
				var name = fields["name"]["stringValue"]
				var name_label = Label.new()
				name_label.text = name
				add_child(name_label)
	else:
		print("Response code IS NOT 200! Code: ", response_code)
