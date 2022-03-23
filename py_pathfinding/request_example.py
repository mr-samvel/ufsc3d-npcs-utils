from urllib import response
import requests

url = "http://localhost:8080/"

waypoints = """
173.506958,80.200691,24.587257,INE_Porta
152.754883,93.658005,24.475264,
146.383163,90.382210,24.475252,
138.046799,90.940102,24.475262,
134.670715,98.181358,24.530107,
142.530411,98.357460,24.478247,Praca_Centro
141.158783,106.669891,24.475254,
150.525055,104.816269,24.475262,
132.523270,104.737968,24.502989,
130.142700,140.361572,24.493687,Lanchonete_Porta
86.298882,87.062401,24.490244,Sala_1_Porta
79.827705,87.758781,24.490265,Sala_1
157.623886,75.101151,24.587133,
161.751709,76.841812,24.587259,


"""
links = """
1,0,
2,3,
4,3,
5,4,
6,5,
7,6,
8,7,
0,8,
1,5,
5,2,
5,3,
9,6,
1,13,
11,10,
10,4,


"""

print("====Update Map====")
response = requests.post(
    url+"update_map",
    data = {
        "waypoints": waypoints,
        "links": links,
    }
)
print(response.text)

print("====Current Map====")
response = requests.post(
    url+"current_map",
)
print(response.text)

print("====Find Path====")
response = requests.post(
    url+"find_path",
    data = {
        "orig": 0,
        "dest": 11,
        "idx": 0,
    }
)
print(response.text)
response = requests.post(
    url+"find_path",
    data = {
        "orig": 0,
        "dest": 12,
        "idx": 0,
    }
)
print(response.text)