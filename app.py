from flask import Flask, redirect, url_for, request
from py_pathfinding.map import update_map, dijkstra, test_map

app = Flask(__name__)

@app.route('/')
@app.route('/home')
def route_home():
   return "Active NPCS Server"


@app.route('/info_test',methods = ['POST'])
def route_info_test():
   object_name = request.headers.get('X-SecondLife-Object-Name')
   object_key = request.headers.get('X-SecondLife-Object-Key')
   owner_key = request.headers.get('X-SecondLife-Owner-Key')
   owner_name = request.headers.get('X-SecondLife-Owner-Name')
   region = request.headers.get('X-SecondLife-Region')

   parameter_1 = request.form.get("parameter1")
   parameter_2 = request.form.get("parameter2")

   return f"""Some Information: \n
      Object: [{object_key}]{object_name}
      Owner: [{owner_key}]{owner_name}
      Region: {region}
      P1: {parameter_1}
      P2: {parameter_2}
   """


@app.route('/update_map',methods = ['POST'])
def route_update_map():
   str_waypoints = request.form.get("waypoints")
   str_links = request.form.get("links")
   waypoints = []
   for waypoint in str_waypoints.split("\n"):
      if waypoint:
         waypoint = filter(None, waypoint.split(","))
         waypoints.append((float(waypoint[0]), float(waypoint[1]), waypoint[2]))

   links = [
      tuple(
         map(int, filter(None,link.split(",")))
      )
      for link in str_links.split("\n") 
      if link
   ]
   print("TEST BEFORE")
   print(test_map())
   print(waypoints)
   print(links)
   update_map(waypoints, links)
   print("TEST After")
   print(test_map())

   return "Server Map Update"


if __name__ == '__main__':
   app.run(debug = True, port=8080)