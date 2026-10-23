server {
    server_name app.nosait.com;

    root /var/www/academy-web;
    index index.html;

    # ضغط gzip لهذا الموقع فقط: كان gzip on في nginx.conf بلا gzip_types فكان يضغط
    # HTML فقط، وmain.dart.js (6.1MB) يُرسل خاماً. مضغوطاً ≈ 1.7MB.
    gzip on;
    gzip_vary on;
    gzip_comp_level 6;
    gzip_min_length 1024;
    gzip_types application/javascript application/json application/wasm font/ttf text/css image/svg+xml;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location = /index.html {
        add_header Cache-Control "no-cache";
    }

    # ملفات Flutter أسماؤها ثابتة بين النسخ — "immutable" لمدة 30 يوم كان يُبقي
    # المستخدم على كود قديم بعد النشر. no-cache = يحتفظ بها المتصفح لكن يتحقق
    # منها كل مرة (رد 304 صغير لو لم تتغيّر).
    location ~* ^/(main\.dart\.js|flutter_bootstrap\.js|flutter\.js|flutter_service_worker\.js|manifest\.json|version\.json)$ {
        add_header Cache-Control "no-cache";
        try_files $uri =404;
    }
    location ~* ^/assets/.*\.json$ {
        add_header Cache-Control "no-cache";
        try_files $uri =404;
    }

    # .ttf كان يُرسل كـ application/octet-stream فلا يُضغط — نعطيه نوعه الصحيح.
    location ~* \.ttf$ {
        types { font/ttf ttf; }
        expires 30d;
        add_header Cache-Control "public";
        try_files $uri =404;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|svg|ico|woff|woff2|wasm)$ {
        expires 30d;
        add_header Cache-Control "public";
        try_files $uri =404;
    }


    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/app.nosait.com/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/app.nosait.com/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

}
server {
    if ($host = app.nosait.com) {
        return 301 https://$host$request_uri;
    } # managed by Certbot



    listen 80;
    server_name app.nosait.com;
    return 404; # managed by Certbot


}
