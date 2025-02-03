from flask import Flask, jsonify, request, render_template
import paramiko
import subprocess
import os

app = Flask(__name__)
app.secret_key = os.urandom(24)

# Basic Authentication Middleware (Untuk development saja)
@app.before_request
def basic_auth():
    if request.path.startswith('/api'):
        auth = request.authorization
        if not auth or auth.username != 'admin' or auth.password != 'admin':
            return jsonify({"status": "error", "message": "Unauthorized"}), 401

# API Endpoints
@app.route('/api/server-info')
def server_info():
    try:
        uptime = subprocess.check_output(['uptime']).decode()
        memory = subprocess.check_output(['free', '-h']).decode()
        disk = subprocess.check_output(['df', '-h']).decode()
        return jsonify({
            "status": "success",
            "uptime": uptime,
            "memory": memory,
            "disk": disk
        })
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/execute', methods=['POST'])
def execute_command():
    data = request.json
    try:
        result = subprocess.check_output(
            data['command'], 
            shell=True, 
            stderr=subprocess.STDOUT
        ).decode()
        return jsonify({"status": "success", "output": result})
    except subprocess.CalledProcessError as e:
        return jsonify({"status": "error", "output": e.output.decode()}), 400

# Web Interface
@app.route('/')
def dashboard():
    return render_template('dashboard.html')

@app.route('/ssh-connect', methods=['POST'])
def ssh_connect():
    host = request.form['host']
    username = request.form['username']
    key_path = request.form['key_path']
    
    try:
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        client.connect(hostname=host, username=username, key_filename=key_path)
        
        # Simpan koneksi dalam session (Untuk contoh sederhana)
        session['ssh'] = {
            "client": client,
            "host": host
        }
        return redirect('/')
    except Exception as e:
        return f"SSH Connection Failed: {str(e)}"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
