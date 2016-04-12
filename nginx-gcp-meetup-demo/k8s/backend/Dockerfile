FROM ubuntu
RUN apt-get update && apt-get install -y golang-go git
ENV GOPATH /
RUN go get github.com/dustin/go-coap
RUN cd src/github.com/dustin/go-coap/example/server/ && go build coap_server.go && mv coap_server /
EXPOSE 5683/udp
CMD /coap_server
