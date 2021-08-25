# canary

A very simple webserver which returns system statistics, to act as a
"canary in the coal mine".

## Installation

```
$ crystal build --release --progress src/canary.cr
```

## Usage

```
$ ./canary
```

This will start the service on `0.0.0.0:80`.

## Development

```
$ docker build -t canary --file Dockerfile .
$ docker run --rm -ti -p 80:80 canary
```

In this example, `canary` is the docker image name. Feel free to change this.

## Contributing

1. Fork it (<https://github.com/Green-Edge/canary/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request (<https://github.com/Green-Edge/canary/pulls>)

## Contributors

- [Phillip Oldham](https://github.com/OldhamMade) - creator (on behalf of Green Edge)
