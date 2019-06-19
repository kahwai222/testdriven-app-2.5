# services/users/project/__init__.py


import os
from flask import Flask
from flask_restful import Resource, Api


# instantiate the app
app = Flask(__name__)

api = Api(app)

# set config
app_settins = os.getenv('APP_SETTINGS')
app.config.from_object(app_settins)


class UsersPing(Resource):
    def get(self):
        return {
            'status': 'success',
            'message': 'pong!'
        }


api.add_resource(UsersPing, '/users/ping')
