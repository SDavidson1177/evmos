FROM golang

RUN apt-get update -y
RUN apt-get install git -y
RUN apt-get update -y
RUN apt-get install ca-certificates jq -y

COPY ./build/evmosd .

EXPOSE 26656 26657 1317 9090 8545 8546

CMD ["tail", "-f", "/dev/null"]
