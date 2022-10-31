Install and run: Resource hacker

open .exe file
choose Action: add an image or other bin resource
select you .ico image
save over .exe file

compile with:

nim --app:gui

to prevent the console from opening

and

nim -d:release for faster code