from django.shortcuts import render, redirect, get_object_or_404 
from django.http import HttpResponse , JsonResponse 
from django.views import View
from django.views.generic import CreateView, ListView, DetailView, UpdateView
from .models import Article
from .forms import ArticleForm
from django.urls import reverse_lazy

class ArticleView(View):
    def get(self, request):
        my_data = "lol"
        articles = Article.objects.all()
        return render(request, "articles/articles_list.html", {'   ': articles})  

class ArticlesDetailView(DetailView):
    model = Article
    context_object_name = "article"
    template_name = "articles/articles_detail.html"
#HOLA 

class ArticlesListViews(ListView):
    model = Article 
    context_object_name = "Article_list"   
    template_name = "articles/articles_list.html"

class NewArticleForm(View):
    def get(self, request):
        form = ArticleForm()
        # IMPORTANTE: Se agregó 'return'
        return render(request, 'articles/new_article_form.html', {'form': form})
        
    def post(self, request):
        # IMPORTANTE: Hay que pasarle los datos al formulario
        form = ArticleForm(request.POST, request.FILES) 
        if form.is_valid():
            form.save()
            return redirect('all_articles') # Corregido 'redirec'
        
        return render(request, 'articles/new_article_form.html', {'form': form})

class EditArticleView(View): 
    def get(self, request, pk): 
        instance = get_object_or_404(Article, pk=pk)
        form = ArticleForm(instance=instance)
        return render(request, 'articles/article_edit.html', {'form': form, 'article': instance})
        
    def post(self, request, pk):
        instance = get_object_or_404(Article, pk=pk)
        form = ArticleForm(request.POST, request.FILES, instance=instance)
        if form.is_valid():
            form.save()
            return redirect('all_articles')
        return render(request, 'articles/article_edit.html', {'form': form})
