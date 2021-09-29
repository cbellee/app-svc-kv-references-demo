VERSION=0.2.0

docker build -t belstarr/go-web-kv-env-linux:${VERSION} -f ./Dockerfile .
docker build -t belstarr/go-web-kv-env-windows:${VERSION} -f ./Dockerfile-windows .

docker login docker.io -u belstarr
docker push belstarr/go-web-kv-env-linux:${VERSION}
docker push belstarr/go-web-kv-env-windows:${VERSION}