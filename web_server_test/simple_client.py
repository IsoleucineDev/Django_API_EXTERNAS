import requests

msg = requests.get("https://www.tec.mx")

print(msg.text)