from flask import Flask
from flasgger import Swagger
from pathfinding.routes import router as pathfinding_router

app = Flask(__name__)
swagger = Swagger(app)

app.register_blueprint(pathfinding_router, url_prefix='/pathfinding')

@app.route('/')
@app.route('/home')
def route_home():
   return "UFSC3D NPCs Utils API"

if __name__ == '__main__':
   app.run(debug=False, port=8080)
