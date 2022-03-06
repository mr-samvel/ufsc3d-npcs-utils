from flask import Flask, redirect, url_for, request
app = Flask(__name__)

@app.route('/')
@app.route('/home')
def home():
   return "KKK New HOME"

"""
// Only works with PHP compiled as an Apache module
$headers = apache_request_headers();

$objectName = $headers["X-SecondLife-Object-Name"];
$objectKey     = $headers["X-SecondLife-Object-Key"];
$ownerKey     = $headers["X-SecondLife-Owner-Key"];
$ownerName = $headers["X-SecondLife-Owner-Name"];
$region        = $headers["X-SecondLife-Region"];
// and so on for getting all the other variables ...

// get things from $_POST[]
// Naturally enough, if this is empty, you won't get anything
$parameter1    = $_POST["parameter1"];
$parameter2    = $_POST["parameter2"];

echo $ownerName . " just said " . $parameter1 . " " . $parameter2 . "\n";
"""
@app.route('/test',methods = ['POST', 'GET'])
def test():
   object_name = request.headers.get('X-SecondLife-Object-Name')
   object_key = request.headers.get('X-SecondLife-Object-Key')
   owner_key = request.headers.get('X-SecondLife-Owner-Key')
   owner_name = request.headers.get('X-SecondLife-Owner-Name')
   region = request.headers.get('X-SecondLife-Region')

   parameter_1 = request.form.get("parameter1")
   parameter_2 = request.form.get("parameter2")

   print(object_name)
   print(object_key)
   print(owner_name)
   print(owner_key)
   print(region)
   print(parameter_1)
   print(parameter_2)

   return f"""HAHAHAH DEU CERTO: \n
      {object_name}: with owner {owner_name} from {region} pass P1: {parameter_1} and P2: {parameter_2}
   """

if __name__ == '__main__':
   app.run(debug = True, port=8080)