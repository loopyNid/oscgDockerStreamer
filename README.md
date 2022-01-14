The purpose of this container is to live-stream networked live-coding performances. It runs Supercollider and OscGroupsClient.
## TODO

1. Add`this.enable` to the init function of the OscGroups class in sc-hacks-redux.
2. GUI class of sc-hacks-redux throws error because the supercollider in the container is headless.


## Instructions to run.
### build

```
docker build -t sc .
```

### run

Put your SuperCollider file in a single folder, e.g. `radio` and then run:

```
docker run -v `pwd`/radio:/data -v `pwd`/recordings:/root/.local/share/SuperCollider/Recordings -p 8124:8000 sc
```

you can use this docker image to render SuperCollider files to audio (by recording) or you can listen to as a radio at `localhost:8000/radio.mp3`.


forked from [jpburstrom's fork](https://github.com/jpburstrom/nattradion-docker) of [maxhawkins' sc_radio](https://github.com/maxhawkins/sc_radio)
