import os
from logging import DEBUG, basicConfig
from datetime import date
from unittest.mock import patch

import pytest
from passlib.context import CryptContext
from sqlalchemy.orm import sessionmaker
from sqlalchemy import create_engine

from csvbase import svc, web
from csvbase.db import db, get_db_url
from csvbase.userdata import PGUserdataAdapter
from csvbase.value_objs import Column, ColumnType, DataLicence, ContentType

from .utils import make_user, random_string, create_table


@pytest.fixture(scope="session")
def app():
    # enable the blog (but with a blank table ref!)
    with patch.dict(os.environ, {"CSVBASE_BLOG_REF": ""}):
        a = web.init_app()
    a.config["TESTING"] = True
    # Speeds things up considerably when testing
    a.config["CRYPT_CONTEXT"] = CryptContext(["plaintext"])
    return a


@pytest.fixture(scope="session")
def session_cls():
    return sessionmaker(create_engine(get_db_url()))


@pytest.fixture(scope="session")
def module_sesh(session_cls):
    """A module-level session, used for things that are done once on a session level"""
    with session_cls() as sesh:
        yield sesh


@pytest.fixture(scope="function")
def sesh(session_cls):
    """A function-level session, used for everything else"""
    with session_cls() as sesh_:
        yield sesh_


@pytest.fixture(scope="session")
def test_user(module_sesh, app):
    user = make_user(
        module_sesh,
        app.config["CRYPT_CONTEXT"],
    )
    module_sesh.commit()
    return user


@pytest.fixture(scope="session")
def configure_logging():
    basicConfig(level=DEBUG)


ROMAN_NUMERALS = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]


@pytest.fixture(scope="function")
def ten_rows(test_user, sesh):
    data = [
        (numeral, (index % 2) == 0, date(2018, 1, index), index + 0.5)
        for index, numeral in enumerate(ROMAN_NUMERALS, start=1)
    ]
    columns = [
        Column(name="roman_numeral", type_=ColumnType.TEXT),
        Column(name="is_even", type_=ColumnType.BOOLEAN),
        Column(name="as_date", type_=ColumnType.DATE),
        Column(name="as_float", type_=ColumnType.FLOAT),
    ]

    table = create_table(sesh, test_user, columns, caption="Roman numerals")
    for row in data:
        PGUserdataAdapter.insert_row(sesh, table.table_uuid, dict(zip(columns, row)))
    sesh.commit()
    return table.table_name


@pytest.fixture(scope="module")
def private_table(test_user, module_sesh):
    x_column = Column("x", type_=ColumnType.INTEGER)
    table = create_table(module_sesh, test_user, [x_column], is_public=False)
    PGUserdataAdapter.insert_row(module_sesh, table.table_uuid, {x_column: 1})
    module_sesh.commit()
    return table.table_name


@pytest.fixture(
    scope="module", params=[ContentType.JSON, ContentType.HTML, ContentType.JSON]
)
def content_type(request):
    yield request.param
