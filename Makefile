all: venv upload

venv:
	virtualenv -p python2 ./venv
	. ./venv/bin/activate
	pip install -r requirements.txt

upload:
	sudo nodemcu-uploader upload *.lua page.tmpl --verify=raw
	sudo nodemcu-uploader node restart

ls:
	sudo nodemcu-uploader file list
