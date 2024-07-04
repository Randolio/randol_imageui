window.addEventListener('message', function(event) {
    if (event.data.type === 'showImage') {
        document.getElementById('image').src = event.data.image;
        document.body.style.display = 'flex';
    }
});

document.getElementById('closeButton').addEventListener('click', function() {
    fetch(`https://randol_imageui/closeImage`);
    document.body.style.display = 'none';
});

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        fetch(`https://randol_imageui/closeImage`);
        document.body.style.display = 'none';
    }
});