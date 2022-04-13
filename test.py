import requests
import json

url = "https://api.github.com/repos/rajesh094780/testGtiAction/actions/workflows/blank.yml/dispatches"

payload = json.dumps({
  "ref": "main",
  "inputs": {
    "id": "1234ssssssssssssssssssssss5sssssssss678"
  }
})
headers = {
  'Accept': 'application/vnd.github.everest-preview+json',
  'Content-Type': 'application/json',
  'Authorization': 'Bearer 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',
  'Cookie': '_octo=GH1.1.1134568056.1649080195; logged_in=no'
}

response = requests.request("POST", url, headers=headers, data=payload)

print(response.text)
