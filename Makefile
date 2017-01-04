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

nodemcu:
	sudo esptool.py -p /dev/ttyUSB0 write_flash -fm qio 0x00000 nodemcu-master-11-modules-2016-12-30-10-15-09-float.bin
