# Install Flask: pip install Flask

import os
from flask import Flask, request, redirect, url_for, send_from_directory
from werkzeug.utils import secure_filename
import shutil

# --- Configuration ---
UPLOAD_FOLDER = 'uploads'
# Create the uploads folder if it doesn't exist
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# --- HTML Forms ---
UPLOAD_FORM = '''
<!doctype html>
<title>Upload a File</title>
<h1>Upload a File</h1>
<form method=post enctype=multipart/form-data>
  <input type=file name=file>
  <input type=submit value=Upload>
</form>
<br>
<a href="/">Go to Home Page</a> | <a href="/list">View Uploaded Files</a>
'''

# --- Web Server Routes ---
@app.route('/')
def home():
    """Homepage of the web server."""
    return '''
    <h1>Welcome to Our Web Server and Cloud Storage</h1>
    <p>This is a simple combined service.</p>
    <ul>
        <li><a href="/about">About Us</a></li>
        <li><a href="/upload">Upload a File</a></li>
        <li><a href="/list">View Your Cloud Storage</a></li>
    </ul>
    '''

@app.route('/about')
def about():
    """The 'About Us' page."""
    return '''
    <h1>About Us</h1>
    <p>We are a simple demonstration of web hosting and cloud storage.</p>
    <a href="/">Go to Home Page</a>
    '''

# --- Cloud Storage Routes ---
@app.route('/upload', methods=['GET', 'POST'])
def upload_file():
    """Handles file uploads."""
    if request.method == 'POST':
        if 'file' not in request.files:
            return redirect(request.url)
        file = request.files['file']
        if file.filename == '':
            return redirect(request.url)
        if file:
            filename = secure_filename(file.filename)
            file.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))
            return redirect(url_for('uploaded_file', filename=filename))
    return UPLOAD_FORM

@app.route('/uploads/<filename>')
def uploaded_file(filename):
    """Serves the uploaded files for viewing or downloading."""
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

@app.route('/list')
def list_files():
    """Lists all files in the cloud storage folder."""
    files = os.listdir(app.config['UPLOAD_FOLDER'])
    file_list_html = "<h1>Cloud Storage</h1>"
    file_list_html += "<p>Click a link to view or download a file.</p>"
    file_list_html += "<ul>"
    for file in files:
        file_list_html += f"<li><a href='{url_for('uploaded_file', filename=file)}'>{file}</a></li>"
    file_list_html += "</ul>"
    file_list_html += "<a href='/'>Go to Home Page</a> | <a href='/upload'>Upload another file</a>"
    return file_list_html

if __name__ == '__main__':
    # Run the app on the local server
    app.run(debug=True)