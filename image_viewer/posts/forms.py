from django import forms
from .models import Post


class CreatePost(forms.ModelForm):
    class Meta:
        model = Post
        fields = ['banner']
        labels = {
            'banner': 'Image',
        }

    def clean_banner(self):
        image = self.cleaned_data.get('banner')
        if not image:
            raise forms.ValidationError("Please upload an image file.")

        # Check the MIME type
        valid_mime_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
        if hasattr(image, 'content_type') and image.content_type not in valid_mime_types:
            raise forms.ValidationError("Unsupported file type. Please upload a JPEG, PNG, GIF, or WEBP image.")

        # Verify it's a real image by trying to open it with Pillow
        try:
            from PIL import Image
            img = Image.open(image)
            img.verify()  # Verifies it's not corrupted
            image.seek(0)  # Reset file pointer after verify
        except Exception:
            raise forms.ValidationError("The uploaded file is not a valid image.")

        # Check file extension
        valid_extensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp']
        import os
        ext = os.path.splitext(image.name)[1].lower()
        if ext not in valid_extensions:
            raise forms.ValidationError("Invalid file extension. Allowed: JPG, PNG, GIF, WEBP.")

        return image