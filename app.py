from urllib import response
from flask import Flask, redirect, url_for, request
from py_pathfinding.map import update_map, dijkstra, current_map

app = Flask(__name__)

@app.route('/')
@app.route('/home')
def route_home():
   return "Active NPCS Server"


@app.route('/info_test',methods = ['POST'])
def route_info_test():
   try:
      object_name = request.headers.get('X-SecondLife-Object-Name')
      object_key = request.headers.get('X-SecondLife-Object-Key')
      owner_key = request.headers.get('X-SecondLife-Owner-Key')
      owner_name = request.headers.get('X-SecondLife-Owner-Name')
      region = request.headers.get('X-SecondLife-Region')

      parameter_1 = request.form.get("parameter1")
      parameter_2 = request.form.get("parameter2")

      info = f"""Some Information: \n
         Object: [{object_key}]{object_name}
         Owner: [{owner_key}]{owner_name}
         Region: {region}
         P1: {parameter_1}
         P2: {parameter_2}
      """

      response = {
         "type": "info_test",
         "return": info,
      }
      return response

   except Exception as e:
      print(e)


@app.route('/current_map',methods = ['POST', 'GET'])
def route_current_map():
   try:
      c_map = current_map()
      response = {
         "type": "current_map",
         "return": c_map,
      }
      return response

   except Exception as e:
      print(e)


@app.route('/update_map',methods = ['POST'])
def route_update_map():
   try:
      str_waypoints = request.form.get("waypoints")
      str_links = request.form.get("links")
      waypoints = []
      for waypoint in str_waypoints.split("\n"):
         if waypoint:
            waypoint = list(filter(None, waypoint.split(",")))
            waypoints.append((float(waypoint[0]), float(waypoint[1]), waypoint[2]))

      links = [
         tuple(
            map(int, list(filter(None,link.split(","))))
         )
         for link in str_links.split("\n") 
         if link
      ]
      update_map(waypoints, links)

      response = {
         "type": "update_map",
         "return": "Server Map Update",
      }
      return response

   except Exception as e:
      print(e)


@app.route('/find_path',methods = ['POST'])
def route_find_path():
   try:
      orig = request.form.get("orig")
      dest = request.form.get("dest")
      idx = request.form.get("idx")
      node_distance, node_prev, path = dijkstra(int(orig), int(dest))
      str_path = ":".join([str(p) for p in path])
      str_path = ":" + str_path + ":" if str_path else str_path

      response = {
         "type": "find_path",
         "return": {
            "idx": idx,
            "path": str_path,
         },
      }
      return response

   except Exception as e:
      print(e)


if __name__ == '__main__':
   app.run(debug = True, port=8080)
