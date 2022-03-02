import os

from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager


app = Flask(__name__)
app.config.from_object(os.environ['APP_SETTINGS'])

db = SQLAlchemy(app)

manager = LoginManager(app)


from application.models import *
from application.ui.views import ui


app.register_blueprint(ui)


try:
    db.create_all()
except Exception as er:
    print({'Exception': str(er)})

if __name__ == '__main__':
    app.run()