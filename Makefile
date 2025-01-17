export FLASK_APP = csvbase.web:init_app()
export FLASK_ENV = development

version :=$(file < csvbase/VERSION)

.PHONY: tox serve release default

default: tox

.venv: .venv/touchfile

.venv/touchfile: setup.py
	test -d .venv || python3 -m venv .venv
	. .venv/bin/activate; python -m pip install .
	touch $@

csvbase/static/codehilite.css: .venv/touchfile
	. .venv/bin/activate; pygmentize -S default -f html -a .highlight > $@

serve: .venv csvbase/static/bootstrap.min.css csvbase/static/codehilite.css csvbase/static/bootstrap.bundle.js
	. .venv/bin/activate; flask run -p 6001

serve-gunicorn: .venv csvbase/static/bootstrap.min.css csvbase/static/codehilite.css csvbase/static/bootstrap.bundle.js
	. .venv/bin/activate; gunicorn -w 1 'csvbase.web:init_app()' --access-logfile=- -t 30 -b :6001

tox: tests/test-data/sitemap.xsd
	tox

bootstrap-5.1.3-dist.zip:
	curl -O -L https://github.com/twbs/bootstrap/releases/download/v5.1.3/bootstrap-5.1.3-dist.zip

csvbase/static/bootstrap.min.css : bootstrap-5.1.3-dist.zip
	unzip -p bootstrap-5.1.3-dist.zip bootstrap-5.1.3-dist/css/bootstrap.min.css > $@

csvbase/static/bootstrap.bundle.js: bootstrap-5.1.3-dist.zip
	unzip -p bootstrap-5.1.3-dist.zip bootstrap-5.1.3-dist/js/bootstrap.bundle.js > $@

tests/test-data/sitemap.xsd:
	curl -s -L https://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd > $@

dump-schema:
	pg_dump -d csvbase --schema-only --schema=metadata

release: dist/csvbase-$VERSION-py3-none-any.whl

dist/csvbase-$VERSION-py3-none-any.whl: csvbase/static/bootstrap.min.css csvbase/static/codehilite.css csvbase/static/bootstrap.bundle.js
	. .venv/bin/activate; python -m pip install build==0.7.0
	. .venv/bin/activate; python -m build
