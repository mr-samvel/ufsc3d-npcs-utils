from urllib import response
import requests

url = "http://localhost:8080/"

waypoints = """
1178,861,28,INE_Porta
1187,872,28,
1186,901,29,
1211,910,29,
1220,886,29,
1237,886,28,
1258,891,28,CTC_Hall
1206,920,29,
1199,930,28,FEESC
1173,902,29,
1169,906,28,
1160,912,29,
1131,912,29,
1090,912,29,
1048,912,29,
1048,926,29,
1048,953,29,
1058,966,28,BU
1026,954,29,
997,956,29,
978,958,29,
1050,881,29,
1050,840,29,
1040,830,29,
1042,798,29,Reitoria
980,797,29,
980,780,29,Feira
1023,713,29,
1015,698,28,Centro_Eventos
970,695,29,
971,670,29,
916,616,28,
882,612,28,RU
1194,847,28,
1222,861,29,
1191,816,29,
1171,818,29,
1100,826,29,
1080,829,29,
1234,812,29,
1300,807,29,INEP
1189,702,28,
1188,684,28,
1213,682,28,
1208,628,28,ARQ
1158,645,28,
1166,526,28,Campo_Futebol

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