import requests

response = requests.get("http://10.25.231.190:8000")
print(response.text)