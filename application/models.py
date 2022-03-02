from flask_login import UserMixin

from application import db, manager
from werkzeug.security import check_password_hash, generate_password_hash
from datetime import datetime


class User(db.Model, UserMixin):
    __tablename__ = 'users'
    id = db.Column(db.Integer, primary_key=True)
    login = db.Column(db.String(128), nullable=False, unique=True)
    password = db.Column(db.String(255), nullable=False)

    def __init__(self, **kwargs):
        self.login = kwargs.get('login')
        self.password = generate_password_hash(kwargs.get('password'), "sha256")

    @classmethod
    def authenticated(cls, login, password):
        user = cls.query.filter(cls.login == login).one()
        if not check_password_hash(user.password, password):
            raise Exception('User not found')
        return user


@manager.user_loader
def load_user(user_id):
    return User.query.get(user_id)


class Data(db.Model):
    __tablename__ = 'data'
    id = db.Column(db.Integer, primary_key=True)
    kind = db.Column(db.String(255), nullable=True)
    collection_name = db.Column(db.String(255), nullable=True)
    track_name = db.Column(db.String(255), nullable=True)
    collection_price = db.Column(db.Numeric(5, 2), nullable=True)
    track_price = db.Column(db.Numeric(7, 2), nullable=True)
    primary_genre_name = db.Column(db.String(255), nullable=True)
    track_count = db.Column(db.Numeric(10), nullable=True)
    track_number = db.Column(db.Numeric(10), nullable=True)
    release_date = db.Column(db.String(), nullable=True)
    created_on = db.Column(db.DateTime(35), default=datetime.now, nullable=False)

    def __init__(self, kind, collection_name, track_name, collection_price, track_price, primary_genre_name, track_count, track_number, release_date):
        self.kind = kind
        self.collection_name = collection_name
        self.track_name = track_name
        self.collection_price = collection_price
        self.track_price = track_price
        self.primary_genre_name = primary_genre_name
        self.track_count = track_count
        self.track_number = track_number
        self.release_date = release_date




