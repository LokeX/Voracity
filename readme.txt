compile with:

nim --app:gui

to prevent the console from opening

and

nim -d:release for faster code

(Install and) run: Resource hacker

open .exe file
choose Action: add an image or other bin resource
select you .ico image
save over .exe file


(install and) run Inno Setup Compiler 6.2.1 (just follow the wizard)


VS-Code run build task script (Configure Tasks):

{
  // See https://go.microsoft.com/fwlink/?LinkId=733558
  // for the documentation about the tasks.json format
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Voracity",
      "type" :"process",
      "command": "nim",
      "args": ["c", "-r", "voracity.nim"],
      "problemMatcher": [],
      "group": {
        "kind": "build",
        "isDefault": true
      }
    }
  ]
}

