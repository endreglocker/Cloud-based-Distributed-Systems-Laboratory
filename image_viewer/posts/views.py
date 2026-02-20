from django.shortcuts import render, redirect, get_object_or_404
from .models import Post
from django.contrib.auth.decorators import login_required
from django.utils.text import slugify
from django.utils import timezone
import os
from . import forms


def post_list(request):
    sort_by = request.GET.get('sort_by', 'date')
    order = request.GET.get('order', 'desc')

    if sort_by == 'title':
        ordering = ('title', '-date') if order == 'asc' else ('-title', '-date')
        next_order = 'desc' if order == 'asc' else 'asc'
    else:  # sort_by == 'date'
        ordering = ('date', 'title') if order == 'asc' else ('-date', 'title')
        next_order = 'desc' if order == 'asc' else 'asc'

    if not request.user.is_authenticated:
        all_posts = Post.objects.none()
    elif request.user.is_staff or request.user.is_superuser:
        all_posts = Post.objects.order_by(*ordering)
    else:
        all_posts = Post.objects.filter(author=request.user).order_by(*ordering)

    return render(
        request,
        'posts/posts_list.html',
        {
            'posts': all_posts,
            'sort_by': sort_by,
            'order': order,
            'next_order': next_order,
        }
    )


def post_page(request, slug):
    post = Post.objects.get(slug=slug)
    return render(request, 'posts/post_page.html', {'post': post})


def post_delete(request, post_id):
    post = get_object_or_404(Post, id=post_id)
    if request.method == 'POST':
        post.delete()
    return redirect('posts:list')


@login_required(login_url="/users/login/")
def post_new(request):
    if request.method == 'POST':
        form = forms.CreatePost(request.POST, request.FILES)
        if form.is_valid():
            newpost = form.save(commit=False)
            newpost.author = request.user

            # Generate title from filename (without extension)
            image = form.cleaned_data['banner']
            filename = os.path.splitext(image.name)[0]
            newpost.title = filename #filename.replace('_', ' ').replace('-', ' ').title()

            # Generate unique slug from filename + upload time
            timestamp = timezone.now().strftime('%Y%m%d%H%M%S')
            newpost.slug = slugify(f"{filename}-{timestamp}")

            newpost.save()
            return redirect('posts:list')
    else:
        form = forms.CreatePost()
    return render(request, 'posts/post_new.html', {'form': form})