set -ex
python3 cert.py 
gunicorn "$@"