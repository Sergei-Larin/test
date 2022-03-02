import logging as log
import sys
import unittest
import requests
import urllib3


class SmokeTests(unittest.TestCase):

    def setUp(self) -> None:
        SmokeTests.init()

    def test_End_Points_Exist(self):
        log.info("Ensuring endpoints exist")
        self.assertEqual(SmokeTests.get("http://localhost:5000/").status_code, 200)
        self.assertEqual(SmokeTests.get("http://localhost:5000/update").status_code, 401)
        self.assertEqual(SmokeTests.get("http://localhost:5000/get_sort_data").status_code, 401)
        self.assertEqual(SmokeTests.get("http://localhost:5000/get_data_all").status_code, 401)
        self.assertEqual(SmokeTests.get("http://localhost:5000/login").status_code, 200)
        self.assertEqual(SmokeTests.get("http://localhost:5000/register").status_code, 200)

    def test_Api_Itunes_Exist(self):
        log.info("Testing Itunes api access")
        self.assertEqual(SmokeTests.get("https://itunes.apple.com/search?").status_code, 200)

    @staticmethod
    def get(url):
        return requests.get(url, verify=False)

    @staticmethod
    def init():
        urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
        stdout_handler = log.StreamHandler(sys.stdout)
        log.basicConfig(level=log.INFO,
                        format='[%(asctime)s] {%(filename)s:%(lineno)d} %(levelname)s - %(message)s',
                        handlers=[stdout_handler])


if __name__ == '__main__':
    unittest.main()
