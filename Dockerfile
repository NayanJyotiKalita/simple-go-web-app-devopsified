FROM golang:1.26 AS base

WORKDIR /app

COPY go.mod .

# Installing dependencies e.g. pip install -r requirements.txt in python
RUN go mod download  

# Copying the entire source code to the docker image
COPY . .

RUN go build -o main .
# The above command will create a artifact/binary called main in the docker image


# Final stage - Distroless image
FROM gcr.io/distroless/base

# Copying the artifact/main from the previous stage 
COPY --from=base /app/main .

# We need the static files also which consists of the HTML, CSS files which are not bundled in the binary
COPY --from=base /app/static ./static

# Exposing the port on which the application will run
EXPOSE 8080

# Command to run the application
CMD [ "./main" ]
