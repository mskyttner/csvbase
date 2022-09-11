export FLASK_APP = csvbase.web:init_app()
export FLASK_ENV = development

version :=$(file < csvbase/VERSION)

.PHONY: tox serve release default

default: tox

.venv: .venv/touchfile

.venv/touchfile: setup.py
	test -d .venv || virtualenv .venv --python=python3
	. .venv/bin/activate; python -m pip install .[blog]
	touch $@

serve: .venv csvbase/static/bootstrap.min.css
	. .venv/bin/activate; flask run -p 6001

tox:
	tox

bootstrap-5.1.3-dist.zip:
	curl -O -L https://github.com/twbs/bootstrap/releases/download/v5.1.3/bootstrap-5.1.3-dist.zip

csvbase/static/bootstrap.min.css: bootstrap-5.1.3-dist.zip
	unzip -p bootstrap-5.1.3-dist.zip bootstrap-5.1.3-dist/css/bootstrap.min.css > $@

dump-schema:
	pg_dump -d csvbase --schema-only --schema=metadata

release: dist/csvbase-$VERSION-py3-none-any.whl

dist/csvbase-$VERSION-py3-none-any.whl: csvbase/static/bootstrap.min.css
	. .venv/bin/activate; python -m pip install build==0.7.0
	. .venv/bin/activate; python -m build
