import requests

url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=AIzaSyBO6cu3B11tKYttI0BTkAbItbZpzdVzQzc"

data = {
 "contents":[{"parts":[{"text":"Hello"}]}]
}

print(requests.post(url,json=data).json())