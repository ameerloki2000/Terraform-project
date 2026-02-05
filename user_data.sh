cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
  <title>ALB Demo</title>
  <style>
    body {
      font-family: Arial;
      background-color: #f4f4f4;
      text-align: center;
      padding-top: 60px;
    }
    h1 {
      color: #333;
    }
  </style>
</head>
<body>
  <h1>Hello from ameer</h1>
  <p>Welcome to my Apache server</p>
</body>
</html>
EOF

systemctl enable apache2
systemctl start apache2
