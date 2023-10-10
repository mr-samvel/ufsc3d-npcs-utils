from flask import Blueprint, request
from flasgger import swag_from
from .map import update_map, dijkstra, current_map

router = Blueprint('pathfinding', __name__,)
docs_path = '../apidocs/pathfinding/'

@router.route('/info', methods=['POST'])
@swag_from(docs_path + 'info.yml')
def info():
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
         "type": "info",
         "return": info,
      }
      return response

   except Exception as e:
      print(e)

@router.route('/current_map', methods=['GET'])
@swag_from(docs_path + 'current_map.yml')
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

@router.route('/update_map', methods=['POST'])
@swag_from(docs_path + 'update_map.yml')
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
         "return": "Server map updated!",
      }
      return response

   except Exception as e:
      print(e)

@router.route('/find_path', methods=['POST'])
@swag_from(docs_path + 'find_path.yml')
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