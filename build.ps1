$version=0.2.0

docker build -t belstarr/go-web-kv-env-linux:$version -f ./Dockerfile .
docker build -t belstarr/go-web-kv-env-windows:$version -f ./Dockerfile-windows .

docker login docker.io -u belstarr
docker push belstarr/go-web-kv-env-linux:$version
docker push belstarr/go-web-kv-env-windows:$version
