import sys
import requests
import base64

def convert_to_filename(string):
	invalid_chars = ["\\", "\n", "/", ":", "*", "?", "\"", "<", ">", "|"]
	for char in invalid_chars:
		string = string.replace(char, "")
	return string.replace(" ", "_").lower()

url = "http://127.0.0.1:5000/v1/chat/completions"

headers = {
	"Content-Type": "application/json"
}

history = []

data = {
	"mode": "chat",
	"character": "Assistant",
	"max_tokens": 1000,
	"messages": ""
}

name = input("Character name: ")
descr = input("Brief description: ")

user_message = f"""create a character card.

description for {name}: {descr}

the format is as follows (fill out words enclosed in angled brackets):

name: <name>
greeting: |-
  <greeting>
context: |
  {{char}}'s Persona: <persona>
  Personality:
  <personality>
  Background:
  <background of {{char}}>
  Likes:
  <likes>
  Dislikes:
  <dislikes>
  Scenario: <scenario>
"""
user_message = user_message.replace("\n", "\\n")

history.append({"role": "user", "content": user_message})
data["messages"] = history
response = requests.post(url, headers=headers, json=data, verify=False)
assistant_message = response.json()['choices'][0]['message']['content']
history.append({"role": "assistant", "content": assistant_message})
data["messages"] = history
chara = assistant_message

filename = convert_to_filename(f"{name}")
with open(f"{filename}.yaml", "w") as file:
	file.write(chara)

history.append({"role": "user", "content": "describe the character's physical appearance with adjectives separated by commas (e.g. pretty, tall, blonde hair, blue eyes)."})
data["messages"] = history
response = requests.post(url, headers=headers, json=data, verify=False)
assistant_message = response.json()['choices'][0]['message']['content']
history.append({"role": "assistant", "content": assistant_message})
data["messages"] = history
appearance = assistant_message

url = "http://127.0.0.1:7861/sdapi/v1/txt2img"
data = {
	"prompt": f"masterpiece, absurdres, 8k, hd, best quality, {appearance}",
	"negative_prompt": "bad_prompt_version2-neg FastNegativeV2 realisticvision-negative-embedding ugly, deformed, bad anotomy, bad lighting,",
	"width": 512,
	"height": 768,
	"restore_faces": True,
	"steps": 15
}
txt = requests.post(url, headers=headers, json=data, verify=False).json()['images'][0]
with open(f"{filename}.png", "wb") as file:
	file.write(base64.b64decode(txt))
# TODO: add examples at the bottom of the YAML file (dialogue between user and the character)
