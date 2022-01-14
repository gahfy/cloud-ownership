#!/bin/bash

USERNAME_FOR_SSH="username"
IP_CLIENT="1.2.3.4"
SSH_PUBLIC_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDGRfQTp8D8IEy1w8Do/JnFbAT1zkxIZyTEtmLqVe4QQLEwNPercmj2Pi3ppbzk9fstnU+hOqq29RKms/tWY9f+3yKAI7l79XiWatN9/d5GJ6bO9u5ZNC2cwQMwX6myc5mlj6KrkBX2Fw19sNrzZB31ycdua9GkKSH9J6Pgyo+CvASDngSf+eB1jjVxSkbXu9OcyPvjTtt1gUtGlogVeCk7QSD3zQ52FhsYcUYPcYqZTkoCspmRuiYLvWnkigpyYOCzWg+VXL+S4KHegOgK6qQd60uDYmPqysrs0jHGd9u2mbCOjQxZUciodC5c79XN2Zx410Jn6QZli1lHSclEDFe1BCQiyiyqspNzVWX7k57D7bfDDzlnH1FAQ5FOa/U6LmnFJ+f19jVm1J4easnOj1y6jGXxQubLMasA5nRPtS98L6gUMr+90aBNY36lEUTMLPH+szCue1XmlZBws+Q/RrRW4oWmjqTKFsg0oJerO3Ei4CW/+xn5WxICPZBrOWX9t8c= g.herfray@gahfy.io"
MARIADB_ROOT_PASSWD="root_passwd"
MARIADB_MAIL_PASSWD="mail_passwd"
MAIL_ROOT_LOCALHOST_PASSWD="mail_root_passwd"
MAIL_USER="johndoe@example.com"
# The MAIL_CERTBOT should be a valid existing email address. If the MX record has been set for the domain to this server, it can be the value of $MAIL_USER, otherwise, please enter a valid email address
MAIL_CERTBOT=$MAIL_USER
MAIL_USER_FULL_NAME="John Doe"
MAIL_USER_FOLDER="johndoe"
MAIL_USER_PASSWD="mail_user_passwd"
MAIL_DOMAIN="example.com"
SMTP_DOMAIN_NAME="smtp.example.com"
