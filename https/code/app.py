from flask import Flask, redirect

app = Flask(__name__)

@app.route("/home")
def home():
    return "At /home"


@app.route("/", methods=["GET"])
def redirect_internal():
    return redirect("/home", code=302)
