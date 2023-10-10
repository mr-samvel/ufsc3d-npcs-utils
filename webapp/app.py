from flask import Flask
from flasgger import Swagger
from pathfinding.routes import router as pathfinding_router
from chatbot.routes import router as chatbot_router

app = Flask(__name__)
swagger = Swagger(app)

app.register_blueprint(pathfinding_router, url_prefix='/pathfinding')
app.register_blueprint(chatbot_router, url_prefix='/chatbot')

@app.route('/')
@app.route('/home')
def route_home():
   return "UFSC3D NPCs Utils API"
