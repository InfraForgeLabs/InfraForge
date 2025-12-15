FROM {{BASE_IMAGE}}

WORKDIR /var/www/html

COPY . .

RUN docker-php-ext-install mysqli pdo pdo_mysql

USER 1001

EXPOSE {{PORT}}

CMD ["{{RUN_CMD}}"]
