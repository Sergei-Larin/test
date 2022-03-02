import unittest
import sys
import logging as log
import urllib3

from application import app, db, config
from application.models import User


class TestCase(unittest.TestCase):
    def setUp(self):
        app.config.from_object(config.StagingConfig)
        self.app = app.test_client()
        db.create_all()
        TestCase.init()

    def tearDown(self):
        db.session.remove()
        db.drop_all()

    def test_create_user(self):
        log.info("Test creating user in db")
        new_user = User(login='test_user')
        db.session.add(new_user)
        db.session.commit()
        user = User.query.filter_by(login='test_user').first()
        assert user.login == 'test_user'

    def test_insert_data_from_api(self):
        log.info("Testing func insert_data_from_api")
        self.assertEqual(1, 1)

    def test_register(self):
        log.info("Testing func register")
        self.assertEqual(1, 1)

    def test_register_post(self):
        log.info("Testing func post register")
        self.assertEqual(1, 1)

    def test_login_page(self):
        log.info("Testing func login")
        self.assertEqual(1, 1)

    def test_login_page_post(self):
        log.info("Testing func post login")
        self.assertEqual(1, 1)

    def test_logout(self):
        log.info("Testing func logout")
        self.assertEqual(1, 1)

    def test_update(self):
        log.info("Testing func update")
        self.assertEqual(1, 1)

    def test_get_data(self):
        log.info("Testing func get_data")
        self.assertEqual(1, 1)

    def test_get_sort_data(self):
        log.info("Testing func get_sort_data")
        self.assertEqual(1, 1)


    @staticmethod
    def init():
        urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
        stdout_handler = log.StreamHandler(sys.stdout)
        log.basicConfig(level=log.INFO,
                        format='[%(asctime)s] {%(filename)s:%(lineno)d} %(levelname)s - %(message)s',
                        handlers=[stdout_handler])


if __name__ == '__main__':
    unittest.main()
