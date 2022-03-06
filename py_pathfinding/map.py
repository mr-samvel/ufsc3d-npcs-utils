from cmath import inf


_waypoints = []
_links = []
_edges = {}
_nodes = []
_neighborns = {}


def update_map(waypoints, links):
    global _waypoints, _links, _edges, _nodes, _neighborns

    _waypoints = waypoints
    _links = links
    _edges = {
        (l[0], l[1]): ((((_waypoints[l[1]][0] - _waypoints[l[0]][0])**2) + (_waypoints[l[1]][1] - _waypoints[l[0]][1])**2)**0.5)
        for l in _links
    }
    _nodes = list(range(0, len(_waypoints)))
    _neighborns = {
        n : [l[0] if l[0] != n else l[1] for l in links if n in l]
        for n in _nodes
    }


def current_map():
    help_edges = {
        ','.join([str(x) for x in k]): v
        for k, v in _edges.items()
    }
    return {
        "waypoints":_waypoints,
        "links": _links,
        "edges": help_edges,
        "nodes": _nodes,
        "neighborns": _neighborns,
    }


def dijkstra(orig, dest):
    unvisited_nodes = _nodes.copy()
    node_distance = {n:inf for n in _nodes}
    node_prev = {n:-1 for n in _nodes}
    node_distance[orig] = 0

    while unvisited_nodes != []:
        curr = sorted([(nd[1], nd[0]) for nd in node_distance.items() if nd[0] in unvisited_nodes])[0][1]
        if curr == dest:
            break
        for n in _neighborns[curr]:
            if n in unvisited_nodes:
                new_dist = node_distance[curr] + _edges.get((curr,n),0) + _edges.get((n,curr),0)
                if new_dist < node_distance[n]:
                    node_distance[n] = new_dist
                    node_prev[n] = curr
        unvisited_nodes.remove(curr)

    path = []
    prev_node = dest
    if node_prev[prev_node] != -1 or prev_node == orig:
        while prev_node != -1:
            path.append(prev_node)
            prev_node = node_prev[prev_node]

    return node_distance, node_prev, path
