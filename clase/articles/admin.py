from django.contrib import admin
#en esta parte pues registro mi modelo article para poder usarlo 
# osea para crear y editr articulos desde /admin pues 
from .models import Article

#esta linea es para que el modelo de Article se pueda ver y editar desde mi panel de admin
admin.site.register(Article)
