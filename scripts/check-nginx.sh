#!/bin/bash

echo "🔍 Checking nginx and moving-frontend connectivity..."

echo ""
echo "1. Checking if go-environment stack is running:"
docker stack services go-environment | grep nginx

echo ""
echo "2. Checking if moving-frontend is accessible internally:"
curl -v http://192.168.0.142:8000 2>&1 | head -20

echo ""
echo "3. Checking nginx config syntax:"
docker exec $(docker ps -q -f name=go-environment_nginx) nginx -t

echo ""
echo "4. Checking nginx access logs:"
docker service logs go-environment_nginx --tail 10

echo ""
echo "5. Testing nginx directly:"
curl -H "Host: moving.mattis.dev" http://192.168.0.142:80 2>&1 | head -20

echo ""
echo "6. DNS resolution check:"
nslookup moving.mattis.dev

echo ""
echo "Done!"
