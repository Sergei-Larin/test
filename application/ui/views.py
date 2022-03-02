import requests
from sqlalchemy import desc
from flask import render_template, redirect, url_for, request, flash, Blueprint
from flask_login import login_user, login_required, logout_user
from werkzeug.security import check_password_hash


from application import db
from application.models import User, Data


ui = Blueprint('ui', __name__)


def insert_data_from_api(search):
    total_count = 0
    record_count = 1
    record_offset = 0
    max_offset = 200
    while record_count > 0:
        response = (requests.get('https://itunes.apple.com/search?term='
         + str(search) + '&offset=' + str(record_offset) + 
         '&limit=' + str(max_offset-1))).json()
        if response:
            record_count = response["resultCount"]
            total_count += record_count
            record_offset = int(record_offset) + max_offset

            dict_list = [
                'kind',
                'b',
                'c',
                'd',
            ]
            out = list()
            for el in dict_list:
                data = record.get("kind", '')
                if not data: 
                    continue
                out.append(data)


            for record in response["results"]:
                session = db.session()

                if "kind" in record:
                    kind = record["kind"]
                else:
                    kind = None

                if "collectionName" in record:
                    collection_name = record["collectionName"]
                else:
                    collection_name = None

                if "trackName" in record:
                    track_name = record["trackName"]
                else:
                    track_name = None

                if "collectionPrice" in record:
                    collection_price = record["collectionPrice"]
                else:
                    collection_price = None

                if "trackPrice" in record:
                    track_price = record["trackPrice"]
                else:
                    track_price = None

                if "primaryGenreName" in record:
                    primary_genre_name = record["primaryGenreName"]
                else:
                    primary_genre_name = None

                if "trackCount" in record:
                    track_count = record["trackCount"]
                else:
                    track_count = None

                if "trackNumber" in record:
                    track_number = record["trackNumber"]
                else:
                    track_number = None

                if "releaseDate" in record:
                    release_date = record["releaseDate"]
                else:
                    release_date = None

                d = Data(
                    kind=kind,
                    collection_name=collection_name,
                    track_name=track_name,
                    collection_price=collection_price,
                    track_price=track_price,
                    primary_genre_name=primary_genre_name,
                    track_count=track_count,
                    track_number=track_number,
                    release_date=release_date,
                )
                session.add(d)
                session.commit()
        else:
            print('Response Failed')
    return total_count


def cleanDatabase(data):
    num_rows_deleted = db.session.query(data).delete()
    db.session.commit()
    return num_rows_deleted


@ui.route('/')
def main():
    try:
        return render_template('index.html')
    except Exception as er:
        print(
            f'ip:{request.remote_addr} - "GET / HTTP/1.1" 400 - failed with errors: {er}')
        return {'Failed with errors': str(er)}, 400


@ui.route('/register', methods=['GET'])
def register():
    try:
        return render_template('register.html')
    except Exception as er:
        print(
            f'ip:{request.remote_addr} - "GET /register HTTP/1.1" 400 - failed with errors: {er}')
        return {'Failed with errors': str(er)}, 400


@ui.route('/register', methods=['POST'])
def register_post():
    login = request.form.get('login')
    password = request.form.get('password')
    password2 = request.form.get('password_retype')
    try:
        user = User.query.filter_by(login=login).first()

        if password != password2:
            flash('Password is not same')
            print(f'ip:{request.remote_addr}:user:{login} - "POST /register HTTP/1.1" 200 - Password is not same')
            return redirect(url_for('ui.register'))
        if user and login is not None:
            flash('User already exists')
            print(f'ip:{request.remote_addr}:user:{login} - "POST /register HTTP/1.1" 200 - user:{login} already exists')
            return redirect(url_for('ui.register'))

        if login and password and password2:
            new_user = User(login=login, password=password)
            db.session.add(new_user)
            db.session.commit()
            print(f'ip:{request.remote_addr}:user:{login} - "POST /register HTTP/1.1" 200 - Register successful')
            return redirect(url_for('ui.login_page'))
        else:
            flash('Fill in all the fields')
            print(f'ip:{request.remote_addr} -"POST /register HTTP/1.1" 400 - not all fields are filled in ')
            return redirect(url_for('ui.register')),400
    except Exception as er:
        print(
            f'ip:{request.remote_addr}:user:{login} - "POST /api/register HTTP/1.1" 400 - failed with errors: {er}')
        return {'Failed with errors': str(er)}, 400


@ui.route('/login', methods=['GET'])
def login_page():
    try:
        return render_template('login.html')
    except Exception as er:
        print(
            f'ip:{request.remote_addr}- "GET /login HTTP/1.1" 400 - failed with errors: {er}')
        return {'Failed with errors': str(er)}, 400


@ui.route('/login', methods=['POST'])
def login_page_post():
    try:
        login = request.form.get('login')
        password = request.form.get('password')
        if login and password:
            user = User.query.filter_by(login=login).first()

            if user and check_password_hash(user.password, password):
                login_user(user)
                return redirect(url_for('ui.main'))
            else:
                flash('Wrong login or password')
        else:
            flash('Fill in all the fields')
        return redirect(url_for('ui.login_page'))
    except Exception as er:
        print(
            f'ip:{request.remote_addr}:user:{login}- "POST /login HTTP/1.1" 400 - failed with errors: {er}')
        return {'Failed with errors': str(er)}, 400


@ui.route('/logout', methods=['GET', 'POST'])
@login_required
def logout():
    try:
        logout_user()
        return redirect(url_for('ui.main'))
    except Exception as er:
        print(
            f'ip:{request.remote_addr} - "{request.method} /logout HTTP/1.1" 400 - failed with errors: {er}')
        return {'Failed with errors': str(er)}, 400


@ui.route('/update', methods=['GET', 'POST'])
@login_required
def update():
    try:
        if request.method == 'POST':
            clean_count = cleanDatabase(Data)
            print("Count clean: "+str(clean_count))
            total_count = insert_data_from_api('Pink+Floyd')
            flash('Total uploaded: '+str(total_count))
            return render_template('update.html')
        else:
            return render_template('update.html')

    except Exception as er:
        print(
            f'ip:{request.remote_addr}- "GET /update HTTP/1.1" 400 - failed with errors: {er}')
        return {'Failed with errors': str(er)}, 400


@ui.route('/get_data_all', methods=['GET'])
@login_required
def get_data():
    try:
        session = db.session()
        data_all = session.query(Data).order_by(desc("track_price")).all()
        return render_template('all_data.html', data_all=data_all)
    except Exception as er:
        print(
            f'ip:{request.remote_addr}- "GET /update HTTP/1.1" 400 - failed with errors: {er}')
        return {'Failed with errors': str(er)}, 400


@ui.route('/get_sort_data', methods=['GET', 'POST'])
@login_required
def get_sort_data():
    try:
        if request.method == 'POST':
            year = request.form.get('release_year')
            session = db.session()
            data_all = session.query(Data).order_by(desc("track_price")).all()
            result = []
            count = 0
            for data in data_all:
                if str(year) in str(data.release_date):
                    result.append(data)
                    count += 1
            flash("Find results: "+str(count))
            return render_template('sort_data.html', data_all=result)
        else:
            return render_template('sort_data.html')
    except Exception as er:
        print(
            f'ip:{request.remote_addr} - "GET /get_sort_data HTTP/1.1" 400 - failed with errors: {er}')
        return {'Failed with errors': str(er)}, 400
