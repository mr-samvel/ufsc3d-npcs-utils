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
0,1,
1,2,
2,3,
3,4,
4,5,
5,6,
3,7,
7,8,
2,9,
9,10,
10,11,
11,12,
12,13,
13,14,
14,15,
15,16,
16,17,
14,18,
18,19,
19,20,
12,21,
21,22,
22,23,
23,24,
24,25,
25,26,
24,27,
27,28,
28,29,
29,30,
30,31,
31,32,
1,33,
33,34,
34,4,
33,35,
35,36,
36,37,
37,38,
38,22,
35,39,
39,40,
35,41,
41,42,
42,43,
43,44,
44,45,
45,46,

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