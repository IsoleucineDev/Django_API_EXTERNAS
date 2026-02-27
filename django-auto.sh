#!/bin/bash
# Uso: ./django.sh <cmd> [args]
# Siempre ejecutar desde la misma carpeta donde esta el script

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV="$SCRIPT_DIR/venv"
PY="python3"
[ -f "$VENV/bin/activate" ] && source "$VENV/bin/activate" && PY="python"

# Detecta proyecto Django (carpeta con manage.py)
PROJ_DIR=$(find "$SCRIPT_DIR" -maxdepth 2 -name manage.py | head -1 | xargs dirname 2>/dev/null)

help() {
cat << EOF
Uso: ./django.sh <comando> [args]
  setup                                    Instala venv y dependencias
  proyecto -c <nombre> <db> <user> <pass>  Crea proyecto y configura MariaDB
  app -c <nombre>                          Crea app y la registra
  template <app> <nombre>                  Crea template HTML base
  run                                      Migra y levanta servidor
  url-list <app> <Modelo>                  Vista+URL+Template listar
  url-new  <app> <Modelo>                  Vista+URL+Form+Template crear
EOF
}

setup() {
    python3 -m venv "$VENV"
    source "$VENV/bin/activate"
    pip install -q django mysqlclient pillow
    echo "Listo. Activa con: source venv/bin/activate"
}

proyecto() {
    [ "$1" != "-c" ] && help && exit 1
    NAME=$2; DB=$3; DBUSER=$4; PASS=$5
    cd "$SCRIPT_DIR"
    django-admin startproject "$NAME"
    $PY - "$SCRIPT_DIR/$NAME" "$NAME" "$DB" "$DBUSER" "$PASS" << 'PY'
import re, sys
base, name, db, user, pw = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5]
path = f"{base}/{name}/settings.py"
s = open(path).read()
new_db = f"""DATABASES = {{
    'default': {{
        'ENGINE': 'django.db.backends.mysql',
        'NAME': '{db}', 'USER': '{user}', 'PASSWORD': '{pw}',
        'HOST': 'localhost', 'PORT': '3306',
    }}
}}"""
s = re.sub(r"DATABASES = \{.*?\n\}", new_db, s, flags=re.DOTALL)
open(path, "w").write(s)
print(f"Proyecto '{name}' creado. DB: {db}")
PY
}

app() {
    [ "$1" != "-c" ] && help && exit 1
    [ -z "$PROJ_DIR" ] && echo "Error: no se encontro manage.py" && exit 1
    APPNAME=$2
    PROJ=$(find "$PROJ_DIR" -maxdepth 1 -name settings.py | xargs dirname | xargs basename 2>/dev/null)
    cd "$PROJ_DIR"
    $PY manage.py startapp "$APPNAME"
    mkdir -p "$APPNAME/templates/$APPNAME"

    $PY - "$PROJ_DIR" "$PROJ" "$APPNAME" << 'PY'
import sys
base, proj, app = sys.argv[1], sys.argv[2], sys.argv[3]

sf = f"{base}/{proj}/settings.py"
s = open(sf).read()
if f"'{app}'" not in s:
    s = s.replace("INSTALLED_APPS = [", f"INSTALLED_APPS = [\n    '{app}',")
    open(sf, "w").write(s)

open(f"{base}/{app}/urls.py", "w").write(
    "from django.urls import path\nfrom . import views\nurlpatterns = []\n"
)

uf = f"{base}/{proj}/urls.py"
s = open(uf).read()
if f"include('{app}" not in s:
    if "include" not in s:
        s = s.replace("from django.urls import path", "from django.urls import path, include")
    s += f"\nurlpatterns += [path('{app}/', include('{app}.urls'))]\n"
    open(uf, "w").write(s)

print(f"App '{app}' creada y registrada.")
PY
}

template() {
    [ -z "$PROJ_DIR" ] && echo "Error: no se encontro manage.py" && exit 1
    APP=$1; TPL=$2
    mkdir -p "$PROJ_DIR/$APP/templates/$APP"
    cat > "$PROJ_DIR/$APP/templates/$APP/$TPL.html" << EOF
<!DOCTYPE html><html><body>
{% block content %}{% endblock %}
</body></html>
EOF
    echo "Template '$TPL.html' creado."
}

run() {
    [ -z "$PROJ_DIR" ] && echo "Error: no se encontro manage.py" && exit 1
    cd "$PROJ_DIR"
    $PY manage.py makemigrations && $PY manage.py migrate
    $PY manage.py runserver
}

url_list() {
    [ -z "$PROJ_DIR" ] && echo "Error: no se encontro manage.py" && exit 1
    APP=$1; MODEL=$2
    LOWER=$(echo "$MODEL" | tr '[:upper:]' '[:lower:]')
    cd "$PROJ_DIR"
    mkdir -p "$APP/templates/$APP"

    cat >> "$APP/views.py" << EOF

from django.shortcuts import render
from .models import $MODEL
def ${LOWER}_lista(request):
    return render(request, '$APP/${LOWER}_lista.html', {'items': ${MODEL}.objects.all()})
EOF

    echo "    path('$LOWER/', views.${LOWER}_lista, name='${LOWER}_lista')," >> "$APP/urls.py"

    cat > "$APP/templates/$APP/${LOWER}_lista.html" << EOF
<!DOCTYPE html><html><body>
<h1>$MODEL</h1>
<ul>{% for i in items %}<li>{{ i }}</li>{% endfor %}</ul>
<a href="{% url '${LOWER}_nuevo' %}">+ Nuevo</a>
</body></html>
EOF
    echo "url-list para '$MODEL' listo."
}

url_new() {
    [ -z "$PROJ_DIR" ] && echo "Error: no se encontro manage.py" && exit 1
    APP=$1; MODEL=$2
    LOWER=$(echo "$MODEL" | tr '[:upper:]' '[:lower:]')
    cd "$PROJ_DIR"
    mkdir -p "$APP/templates/$APP"

    [ ! -f "$APP/forms.py" ] && echo "from django import forms" > "$APP/forms.py"
    cat >> "$APP/forms.py" << EOF

from .models import $MODEL
class ${MODEL}Form(forms.ModelForm):
    class Meta:
        model = $MODEL
        fields = '__all__'
EOF

    cat >> "$APP/views.py" << EOF

from django.shortcuts import redirect
from .forms import ${MODEL}Form
def ${LOWER}_nuevo(request):
    form = ${MODEL}Form(request.POST or None)
    if form.is_valid():
        form.save(); return redirect('${LOWER}_lista')
    return render(request, '$APP/${LOWER}_form.html', {'form': form})
EOF

    echo "    path('$LOWER/nuevo/', views.${LOWER}_nuevo, name='${LOWER}_nuevo')," >> "$APP/urls.py"

    cat > "$APP/templates/$APP/${LOWER}_form.html" << EOF
<!DOCTYPE html><html><body>
<h1>Nuevo $MODEL</h1>
<form method="post">{% csrf_token %}{{ form.as_p }}
<button type="submit">Guardar</button></form>
</body></html>
EOF
    echo "url-new para '$MODEL' listo."
}

case "$1" in
    setup)     setup ;;
    proyecto)  shift; proyecto "$@" ;;
    app)       shift; app "$@" ;;
    template)  shift; template "$@" ;;
    run)       run ;;
    url-list)  shift; url_list "$@" ;;
    url-new)   shift; url_new "$@" ;;
    *)         help ;;
esac
